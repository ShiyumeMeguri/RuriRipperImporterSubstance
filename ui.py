# -*- coding: utf-8 -*-
"""The RuriRipper dock: cabmap browser + one-click import.

Layout mirrors the Blender addon's N-panel so the two tools are the same tool:
a setup block (RipperHook bin dir / game root / cabmap / hook selection), then
a virtual-folder browser over the cabmap with a quick-search box, then the
import buttons.

Everything that does not touch Painter's API -- resolving a dependency closure
through the CLR bridge, decoding meshes, baking textures -- runs on a worker
thread so the application stays responsive; the project creation and the
layer/shader wiring hop back to the main thread, which is the only place
Painter's API may be called.
"""

from __future__ import annotations

import os
import re
import traceback

try:
    from PySide6 import QtCore, QtGui, QtWidgets
    from PySide6.QtCore import Qt, Signal
except ImportError:  # older Painter builds
    from PySide2 import QtCore, QtGui, QtWidgets
    from PySide2.QtCore import Qt
    from PySide2.QtCore import Signal

try:
    from . import bootstrap, config, sp_apply
except ImportError:  # standalone (non-package) testing
    import bootstrap
    import config
    import sp_apply

# Three columns only: a docked side panel has no room for the Container path,
# which lives in each row's tooltip instead.
_COLUMNS = (("name", "Name", 220), ("type_names", "Type", 120),
            ("deps", "Deps", 48))

_FILENAME_UNSAFE = re.compile(r'[\\/:*?"<>|]')

# The numpy-backed half of the plugin is imported LAZILY, not at plugin load:
# on a first-ever run numpy has not been pip-installed yet, and a module-level
# import of it here would make the whole plugin fail to load -- forcing a
# restart after the very install that was supposed to fix it. Everything that
# touches these is gated behind _require_runtime().
cabmap_state = None
importer = None


def _load_deps():
    global cabmap_state, importer
    if cabmap_state is not None:
        return True
    try:
        try:
            from . import cabmap_state as _state, importer as _importer
        except ImportError:  # standalone (non-package) testing
            import cabmap_state as _state
            import importer as _importer
    except ImportError:
        return False
    cabmap_state, importer = _state, _importer
    return True


def _rows():
    """Row count of the loaded cabmap, or 0 when nothing is loaded (or the
    runtime is not installed yet)."""
    return len(cabmap_state.ROWS) if cabmap_state is not None else 0


# ---------------------------------------------------------------------------
# Worker plumbing
# ---------------------------------------------------------------------------
class _Worker(QtCore.QObject):
    """Runs one callable off the main thread and reports back by signal.

    ``progress`` is passed into the callable so long stages can narrate
    themselves; ``finished`` carries (result, error_text)."""

    progress = Signal(str)
    finished = Signal(object, object)

    def __init__(self, fn):
        super().__init__()
        self._fn = fn

    @QtCore.Slot()
    def run(self):
        try:
            result = self._fn(self.progress.emit)
        except Exception:
            self.finished.emit(None, traceback.format_exc())
            return
        self.finished.emit(result, None)


class _Task(QtCore.QObject):
    """Owns a QThread + worker for the lifetime of one background operation.

    A QObject (created on the main thread) with explicitly QUEUED connections,
    not a plain Python receiver: a plain callable is invoked directly on the
    emitting thread, which would run the completion handler -- widget updates
    and, worse, Painter API calls -- on the worker thread. Painter's API is
    main-thread only."""

    def __init__(self, panel, fn, on_done, label):
        super().__init__(panel)
        self.panel = panel
        self.on_done = on_done
        self.label = label
        self.thread = QtCore.QThread()
        self.worker = _Worker(fn)
        self.worker.moveToThread(self.thread)
        self.thread.started.connect(self.worker.run)
        self.worker.progress.connect(self._progress, Qt.QueuedConnection)
        self.worker.finished.connect(self._finished, Qt.QueuedConnection)

    def start(self):
        self.panel.set_busy(True, self.label)
        self.thread.start()

    @QtCore.Slot(str)
    def _progress(self, message):
        self.panel.set_status(message)

    @QtCore.Slot(object, object)
    def _finished(self, result, error):
        self.thread.quit()
        self.thread.wait()
        self.panel.set_busy(False, "")
        self.panel.forget_task(self)
        if error:
            self.panel.report_error(self.label, error)
            return
        try:
            self.on_done(result)
        except Exception:
            self.panel.report_error(self.label, traceback.format_exc())


# ---------------------------------------------------------------------------
# Report dialog
# ---------------------------------------------------------------------------
def show_report(parent, title, lines):
    dialog = QtWidgets.QDialog(parent)
    dialog.setWindowTitle(title)
    dialog.resize(860, 640)
    layout = QtWidgets.QVBoxLayout(dialog)
    box = QtWidgets.QPlainTextEdit()
    box.setPlainText("\n".join(lines))
    box.setReadOnly(True)
    box.setLineWrapMode(QtWidgets.QPlainTextEdit.NoWrap)
    layout.addWidget(box)
    button = QtWidgets.QPushButton("Close")
    button.clicked.connect(dialog.accept)
    layout.addWidget(button)
    dialog.exec_() if hasattr(dialog, "exec_") else dialog.exec()


# ---------------------------------------------------------------------------
# The dock
# ---------------------------------------------------------------------------
class RuriRipperPanel(QtWidgets.QWidget):

    #: Below this width the dock is treated as a narrow side panel.
    NARROW_WIDTH = 420

    def __init__(self):
        super().__init__()
        self.setWindowTitle("RuriRipper")
        # Painter keys the dock's saved position/geometry off objectName, and
        # turns windowIcon into the side-strip quick-access button.
        self.setObjectName("RuriRipperImporterSubstance")
        self.setWindowIcon(panel_icon())
        self.setMinimumWidth(240)
        self._tasks = []
        self._hook_boxes = []
        # The last cabmap path this panel auto-derived; anything else in that
        # field is the user's own choice and is never rewritten.
        self._auto_cabmap = ""
        # Guards the settings writer while the widgets are being populated FROM
        # the settings: every setChecked/setText below fires its own change
        # signal, and a save triggered halfway through would persist the
        # not-yet-loaded widgets' construction defaults over the real values.
        self._loading = True
        self._build_ui()
        self._load_settings()
        self._loading = False
        self._refresh_runtime_status()

    # -- construction ------------------------------------------------------

    def _build_ui(self):
        root = QtWidgets.QVBoxLayout(self)
        root.setContentsMargins(6, 6, 6, 6)
        root.setSpacing(6)

        # --- setup -------------------------------------------------------
        setup_inner = QtWidgets.QWidget()
        form = QtWidgets.QFormLayout(setup_inner)
        form.setContentsMargins(0, 0, 0, 0)
        form.setLabelAlignment(Qt.AlignRight)
        form.setFieldGrowthPolicy(QtWidgets.QFormLayout.AllNonFixedFieldsGrow)

        self.bin_dir = QtWidgets.QLineEdit()
        self.bin_dir.setPlaceholderText(
            "folder containing Ruri.RipperHook.dll + Ruri.RipperHook.CLI.runtimeconfig.json")
        form.addRow("RipperHook bin", _with_browse(self.bin_dir, self._pick_dir))

        self.game_root = QtWidgets.QLineEdit()
        self.game_root.setPlaceholderText("game install root to scan")
        form.addRow("Game root", _with_browse(self.game_root, self._pick_dir))

        self.cabmap_path = QtWidgets.QLineEdit()
        self.cabmap_path.setPlaceholderText(
            "cabmap file to build / load -- defaults to <game root>/<hook>.cabmap")
        form.addRow("Cabmap", _with_browse(self.cabmap_path, self._pick_cabmap))

        self.hooks_box = QtWidgets.QWidget()
        self.hooks_layout = QtWidgets.QVBoxLayout(self.hooks_box)
        self.hooks_layout.setContentsMargins(0, 0, 0, 0)
        self.hooks_layout.setSpacing(1)
        # Two dozen hooks would otherwise push the whole browser off the bottom
        # of the dock -- give the list its own bounded scroll area.
        hooks_scroll = QtWidgets.QScrollArea()
        hooks_scroll.setWidgetResizable(True)
        hooks_scroll.setWidget(self.hooks_box)
        hooks_scroll.setMinimumHeight(64)
        hooks_scroll.setMaximumHeight(150)
        hooks_column = QtWidgets.QVBoxLayout()
        hooks_column.setContentsMargins(0, 0, 0, 0)
        refresh_hooks = QtWidgets.QPushButton("Refresh hook list")
        refresh_hooks.clicked.connect(self._refresh_hooks)
        hooks_column.addWidget(refresh_hooks)
        hooks_column.addWidget(hooks_scroll)
        form.addRow("Hooks", _wrap(hooks_column))

        buttons = QtWidgets.QHBoxLayout()
        self.build_button = QtWidgets.QPushButton("Build cabmap")
        self.build_button.clicked.connect(self._build_cabmap)
        self.load_button = QtWidgets.QPushButton("Load cabmap")
        self.load_button.clicked.connect(self._load_cabmap)
        buttons.addWidget(self.build_button)
        buttons.addWidget(self.load_button)
        form.addRow("", _wrap(buttons))
        self.setup_group = _collapsible("Source", setup_inner, on_toggle=self._on_section_toggled)

        # --- options -----------------------------------------------------
        options_inner = QtWidgets.QWidget()
        options_outer = QtWidgets.QVBoxLayout(options_inner)
        options_outer.setContentsMargins(0, 0, 0, 0)
        options_outer.setSpacing(4)
        options_layout = QtWidgets.QGridLayout()
        options_layout.setContentsMargins(0, 0, 0, 0)
        options_layout.setHorizontalSpacing(10)
        options_outer.addLayout(options_layout)
        self._options_grid = options_layout
        self.opt_lod0 = QtWidgets.QCheckBox("LOD0 only")
        self.opt_shadow = QtWidgets.QCheckBox("Keep shadow proxies")
        self.opt_inactive = QtWidgets.QCheckBox("Import inactive renderers")
        self.opt_inactive.setToolTip(
            "Renderers that are disabled, or sit on a deactivated GameObject, draw nothing "
            "in Unity -- but they are usually runtime-toggled variants. Untick to import "
            "exactly what the game draws.")
        self.opt_normals = QtWidgets.QCheckBox("Use stored normals")
        self.opt_normals.setToolTip(
            "Write Unity's own per-vertex normals. Untick only to let Painter regenerate "
            "them, which loses every custom/split normal the model was authored with.")
        self.opt_colors = QtWidgets.QCheckBox("Vertex colours")
        self.opt_tangents = QtWidgets.QCheckBox("Stored tangents")
        self.opt_tangents.setToolTip(
            "Painter computes its own tangent basis regardless; this only affects other "
            "tools reading the generated .glb.")
        self.opt_keep_uv = QtWidgets.QCheckBox("Keep Unity UV origin")
        self.opt_keep_uv.setToolTip(
            "Unity's texture origin is bottom-left, glTF's is top-left, so the V flip is "
            "part of the conversion and is always applied. Tick this ONLY for a source "
            "that is already top-left -- it mirrors every texture vertically.")
        self.opt_force = QtWidgets.QCheckBox("Rebuild cache")
        self.opt_env = QtWidgets.QCheckBox("Set environment (CharCubemap)")
        self.opt_lut = QtWidgets.QCheckBox("Set colour LUT (CharShowLut3D)")
        self.opt_linear = QtWidgets.QCheckBox("Force Linear tone mapping")
        self.opt_linear.setToolTip(
            "EndField_Uber applies the HG tonemap itself ([H9]); leaving Painter's display "
            "tone mapping on anything but Linear applies it twice.")
        self.resolution = QtWidgets.QComboBox()
        for value in (512, 1024, 2048, 4096):
            self.resolution.addItem(str(value), value)
        widgets = [self.opt_lod0, self.opt_shadow, self.opt_inactive,
                   self.opt_normals, self.opt_colors, self.opt_tangents,
                   self.opt_force, self.opt_keep_uv,
                   self.opt_env, self.opt_lut, self.opt_linear]
        self._option_widgets = widgets
        self._layout_options(2)
        resolution_row = QtWidgets.QHBoxLayout()
        resolution_row.setContentsMargins(0, 0, 0, 0)
        resolution_row.addWidget(QtWidgets.QLabel("Resolution"))
        resolution_row.addWidget(self.resolution, 1)
        options_outer.addLayout(resolution_row)
        for widget in widgets:
            widget.toggled.connect(self._save_settings)
        self.resolution.currentIndexChanged.connect(self._save_settings)
        self.options_group = _collapsible("Options", options_inner,
                                          on_toggle=self._on_section_toggled)

        # --- browser -----------------------------------------------------
        browser = QtWidgets.QWidget()
        browser.setMinimumHeight(240)
        browser_layout = QtWidgets.QVBoxLayout(browser)
        browser_layout.setContentsMargins(0, 0, 0, 0)
        browser_layout.setSpacing(3)
        assets_label = QtWidgets.QLabel("Assets")
        assets_font = assets_label.font()
        assets_font.setBold(True)
        assets_label.setFont(assets_font)
        browser_layout.addWidget(assets_label)

        nav = QtWidgets.QHBoxLayout()
        self.up_button = QtWidgets.QToolButton()
        self.up_button.setText("Up")
        self.up_button.clicked.connect(self._go_up)
        self.breadcrumb = QtWidgets.QLabel("/")
        self.breadcrumb.setTextInteractionFlags(Qt.TextSelectableByMouse)
        self.breadcrumb.setSizePolicy(QtWidgets.QSizePolicy.Ignored,
                                      QtWidgets.QSizePolicy.Preferred)
        nav.addWidget(self.up_button)
        nav.addWidget(self.breadcrumb, 1)
        browser_layout.addLayout(nav)

        self.search = QtWidgets.QLineEdit()
        self.search.setPlaceholderText("search name / container / type / source")
        self.search.setClearButtonEnabled(True)
        self.search.textChanged.connect(self._schedule_filter)
        browser_layout.addWidget(self.search)

        # Folders and assets share ONE list. A docked side panel is narrow --
        # a side-by-side folder pane plus a four-column table needs width that
        # simply is not there, and the wide Container column is unreadable at
        # dock size (it moves to the row's tooltip instead).
        self.table = QtWidgets.QTableWidget(0, len(_COLUMNS))
        self.table.setHorizontalHeaderLabels([c[1] for c in _COLUMNS])
        self.table.setSelectionBehavior(QtWidgets.QAbstractItemView.SelectRows)
        self.table.setSelectionMode(QtWidgets.QAbstractItemView.ExtendedSelection)
        self.table.setEditTriggers(QtWidgets.QAbstractItemView.NoEditTriggers)
        self.table.verticalHeader().setVisible(False)
        self.table.verticalHeader().setDefaultSectionSize(20)
        self.table.setAlternatingRowColors(False)
        self.table.setShowGrid(False)
        self.table.setFrameShape(QtWidgets.QFrame.NoFrame)
        self.table.setWordWrap(False)
        self.table.setMinimumHeight(160)
        header = self.table.horizontalHeader()
        header.setStretchLastSection(False)
        header.setHighlightSections(False)
        header.setSectionResizeMode(0, QtWidgets.QHeaderView.Stretch)
        for index in range(1, len(_COLUMNS)):
            header.setSectionResizeMode(index, QtWidgets.QHeaderView.ResizeToContents)
        header.sectionClicked.connect(self._sort_by_section)
        self.table.itemDoubleClicked.connect(self._activate_item)
        browser_layout.addWidget(self.table, 1)

        # --- settings scroll, then the browser taking everything else ----
        # ONLY the settings scroll. The asset list must NOT live inside a scroll
        # area: a scrollable list nested in a scrollable parent has no height to
        # negotiate with -- the parent hands it its (tiny) size hint and the list
        # collapses to two visible rows, which is exactly what it did. Outside
        # it, the list gets a stretch factor and every pixel the settings do not
        # use.
        settings_host = QtWidgets.QWidget()
        settings_layout = QtWidgets.QVBoxLayout(settings_host)
        settings_layout.setContentsMargins(0, 0, 0, 0)
        settings_layout.setSpacing(6)
        settings_layout.addWidget(self.setup_group)
        settings_layout.addWidget(self.options_group)
        settings_layout.addStretch(1)
        self.scroll = QtWidgets.QScrollArea()
        self.scroll.setWidgetResizable(True)
        self.scroll.setFrameShape(QtWidgets.QFrame.NoFrame)
        self.scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.scroll.setWidget(settings_host)
        # Takes only the height it needs, capped in _apply_density to half the
        # dock so the asset list is never squeezed out again.
        self.scroll.setSizePolicy(QtWidgets.QSizePolicy.Preferred,
                                  QtWidgets.QSizePolicy.Maximum)
        root.addWidget(self.scroll, 0)
        root.addWidget(browser, 1)

        # --- actions -----------------------------------------------------
        actions = QtWidgets.QVBoxLayout()
        actions.setSpacing(3)
        self.import_button = QtWidgets.QPushButton("Import selected -> new project")
        self.import_button.clicked.connect(lambda: self._import(new_project=True))
        self.wire_button = QtWidgets.QPushButton("Wire open project")
        self.wire_button.setToolTip(
            "Rebuild materials/textures/shader parameters for the project that is already "
            "open, leaving its mesh alone.")
        self.wire_button.clicked.connect(lambda: self._import(new_project=False))
        self.disk_button = QtWidgets.QPushButton("Import YAML file...")
        self.disk_button.setToolTip(
            "Fallback: import an already-extracted Unity YAML prefab or Mesh asset from disk.")
        self.disk_button.clicked.connect(self._import_from_disk)
        actions.addWidget(self.import_button)
        secondary = QtWidgets.QHBoxLayout()
        secondary.setSpacing(3)
        secondary.addWidget(self.wire_button)
        secondary.addWidget(self.disk_button)
        actions.addLayout(secondary)
        # Deliberately OUTSIDE the scroll area: the import buttons and the
        # status line have to stay reachable no matter how far the settings
        # above are scrolled.
        root.addLayout(actions)

        self.status = QtWidgets.QLabel("")
        self.status.setWordWrap(True)
        self.status.setSizePolicy(QtWidgets.QSizePolicy.Ignored,
                                  QtWidgets.QSizePolicy.Preferred)
        root.addWidget(self.status)

        self._filter_timer = QtCore.QTimer(self)
        self._filter_timer.setSingleShot(True)
        self._filter_timer.setInterval(250)
        self._filter_timer.timeout.connect(self._apply_filter)

        self._apply_style()

    def _apply_style(self):
        """Flatten the leftover Qt-default chrome.

        The dated look came from Qt's defaults that Painter's own stylesheet does
        not cover for plugin widgets: sunken/etched frames around the list and
        the scroll areas, a bevelled header, and grid lines. Colours are taken
        from the widget's OWN palette rather than written in, so this follows
        whatever theme Painter is running instead of fighting it."""
        palette = self.palette()
        mid = palette.color(QtGui.QPalette.Mid).name()
        text = palette.color(QtGui.QPalette.WindowText).name()
        base = palette.color(QtGui.QPalette.Window).name()
        self.setStyleSheet("""
            QToolButton {{ border: none; padding: 3px 2px; text-align: left; }}
            QHeaderView::section {{
                background: {base}; color: {text};
                border: none; border-bottom: 1px solid {mid};
                padding: 3px 4px;
            }}
            QTableWidget {{ border: none; }}
            QTableWidget::item {{ padding: 1px 4px; }}
            QScrollArea {{ border: none; }}
        """.format(base=base, text=text, mid=mid))

    # -- responsive density ------------------------------------------------

    def _layout_options(self, columns):
        grid = self._options_grid
        for widget in self._option_widgets:
            grid.removeWidget(widget)
        for index, widget in enumerate(self._option_widgets):
            grid.addWidget(widget, index // columns, index % columns)
        self._option_columns = columns

    def resizeEvent(self, event):
        super().resizeEvent(event)
        self._apply_density()

    def _apply_density(self):
        """Adapt to the dock's size. Docked into the side strip this panel is
        often ~300px wide, where a two-column option grid clips its labels and
        the Type/Deps columns starve the asset name of room."""
        width = self.width()
        columns = 1 if width < self.NARROW_WIDTH else 2
        if columns != getattr(self, "_option_columns", None):
            self._layout_options(columns)
        self.table.setColumnHidden(2, width < self.NARROW_WIDTH)   # Deps
        self.table.setColumnHidden(1, width < 320)                 # Type
        self._sync_settings_height()

    def _sync_settings_height(self):
        """Pin the settings scroll to exactly what its content wants, capped at
        half the dock.

        A QScrollArea does not shrink to its widget on its own -- its own size
        hint stays put -- so collapsing a section freed nothing and the asset
        list never grew. Driving maximumHeight from the content's size hint is
        what actually hands the space back, and the cap is what stops a fully
        expanded settings block from squeezing the list out again."""
        cap = max(120, int(self.height() * 0.5))
        host = self.scroll.widget()
        layout = host.layout() if host is not None else None
        if layout is not None:
            # Hiding a child only marks the layout dirty; Qt recomputes on the
            # next event loop pass. Reading the hint now would return the
            # PRE-collapse height and the space would never come back, so force
            # the recalculation before asking.
            layout.invalidate()
            layout.activate()
            wanted = layout.sizeHint().height()
        else:
            wanted = host.sizeHint().height() if host is not None else cap
        self.scroll.setMaximumHeight(min(cap, max(wanted, 24)))

    def _on_section_toggled(self, _expanded=False):
        self._sync_settings_height()
        self._save_settings()

    # -- settings ----------------------------------------------------------

    def _load_settings(self):
        self.bin_dir.setText(config.get("ripperhook_bin", ""))
        self.game_root.setText(config.get("game_root", ""))
        self.cabmap_path.setText(config.get("cabmap_path", ""))
        self.opt_lod0.setChecked(bool(config.get("lod0_only", True)))
        self.opt_shadow.setChecked(bool(config.get("import_shadow_proxies", False)))
        self.opt_normals.setChecked(bool(config.get("import_normals", True)))
        self.opt_colors.setChecked(bool(config.get("import_colors", True)))
        self.opt_inactive.setChecked(bool(config.get("import_inactive", True)))
        self.opt_tangents.setChecked(bool(config.get("import_tangents", True)))
        self.opt_keep_uv.setChecked(bool(config.get("keep_unity_uv_origin", False)))
        self.opt_force.setChecked(bool(config.get("force_rebuild", False)))
        self.opt_env.setChecked(bool(config.get("apply_environment", True)))
        self.opt_lut.setChecked(bool(config.get("apply_color_lut", True)))
        self.opt_linear.setChecked(bool(config.get("force_linear_tonemap", True)))
        index = self.resolution.findData(int(config.get("texture_resolution", 2048)))
        self.resolution.setCurrentIndex(index if index >= 0 else 2)
        self.setup_group.setChecked(bool(config.get("source_expanded", True)))
        self.options_group.setChecked(bool(config.get("options_expanded", True)))
        for edit in (self.bin_dir, self.cabmap_path):
            edit.editingFinished.connect(self._save_settings)
        self.game_root.editingFinished.connect(self._on_game_root_changed)
        self._rebuild_hook_checkboxes(config.get("hook_ids", []), config.get("hook_ids", []))

    def _save_settings(self, *_args):
        if self._loading:
            return
        config.set_many(
            source_expanded=self.setup_group.isChecked(),
            options_expanded=self.options_group.isChecked(),
            ripperhook_bin=self.bin_dir.text().strip(),
            game_root=self.game_root.text().strip(),
            cabmap_path=self.cabmap_path.text().strip(),
            hook_ids=self._selected_hooks(),
            lod0_only=self.opt_lod0.isChecked(),
            import_shadow_proxies=self.opt_shadow.isChecked(),
            import_normals=self.opt_normals.isChecked(),
            import_colors=self.opt_colors.isChecked(),
            import_inactive=self.opt_inactive.isChecked(),
            import_tangents=self.opt_tangents.isChecked(),
            keep_unity_uv_origin=self.opt_keep_uv.isChecked(),
            force_rebuild=self.opt_force.isChecked(),
            apply_environment=self.opt_env.isChecked(),
            apply_color_lut=self.opt_lut.isChecked(),
            force_linear_tonemap=self.opt_linear.isChecked(),
            texture_resolution=int(self.resolution.currentData() or 2048),
        )

    # -- cabmap path defaulting --------------------------------------------

    def _default_cabmap_name(self):
        """A cabmap filename built from the ticked hook id(s) -- e.g.
        "EndField_1.4.4.cabmap", or "A+B.cabmap" for more than one. Same rule
        the Blender addon uses, so both tools land on the same file for the
        same game."""
        hooks = self._selected_hooks()
        stem = "+".join(hooks) if hooks else "output"
        return _FILENAME_UNSAFE.sub("_", stem) + ".cabmap"

    @staticmethod
    def _names_a_folder(raw):
        """Whether the Cabmap field is pointing at a DIRECTORY to write into
        rather than naming the file itself. ``isdir`` alone is not enough: a
        game root typed by hand (or one on a drive that is not mounted right
        now) does not exist as far as this process is concerned, and a path
        with no extension was never a filename."""
        if not raw:
            return True
        if raw.endswith(("\\", "/")) or os.path.isdir(raw):
            return True
        return not os.path.splitext(raw)[1]

    def _resolved_cabmap_path(self):
        """What the Cabmap field means right now: the field verbatim when it
        names a file, the default filename inside it when it names a folder,
        and <game root>/<default> when it is empty."""
        raw = self.cabmap_path.text().strip()
        if not raw:
            root = self.game_root.text().strip()
            return os.path.normpath(
                os.path.join(root, self._default_cabmap_name())) if root else ""
        if self._names_a_folder(raw):
            return os.path.normpath(os.path.join(raw, self._default_cabmap_name()))
        return raw

    def _autofill_cabmap(self):
        """Keep the field showing a concrete file path as the game root and the
        hook selection become known.

        A filename the USER typed or picked is never touched. One this method
        wrote itself is regenerated in place (in its own folder) -- otherwise
        the first autofill would freeze the name against the hook selection it
        happened to be derived from, and ticking a different hook afterwards
        would silently keep building into the previous hook's cabmap."""
        raw = self.cabmap_path.text().strip()
        if raw and not self._names_a_folder(raw):
            if raw != self._auto_cabmap:
                return                        # the user's own filename
            folder = os.path.dirname(raw)     # ours: rebuild beside it
        else:
            folder = raw or self.game_root.text().strip()
        if not folder:
            return
        resolved = os.path.normpath(os.path.join(folder, self._default_cabmap_name()))
        if resolved != raw:
            self.cabmap_path.setText(resolved)
            self._auto_cabmap = resolved
            self._save_settings()

    def _on_game_root_changed(self):
        self._autofill_cabmap()
        self._save_settings()

    # -- status ------------------------------------------------------------

    def set_status(self, message):
        self.status.setText(message)

    def set_busy(self, busy, label):
        for widget in (self.build_button, self.load_button, self.import_button,
                       self.wire_button, self.disk_button):
            widget.setEnabled(not busy)
        if busy:
            self.set_status(label + "...")

    def forget_task(self, task):
        if task in self._tasks:
            self._tasks.remove(task)

    def report_error(self, label, text):
        self.set_status(label + " failed.")
        show_report(self, "RuriRipper -- " + label + " failed", text.splitlines())

    def _run(self, fn, on_done, label):
        task = _Task(self, fn, on_done, label)
        self._tasks.append(task)
        task.start()

    def _refresh_runtime_status(self):
        if bootstrap.is_ready():
            self.set_status("Runtime ready.")
            return
        error = bootstrap.last_error()
        if error:
            self.set_status("Runtime install failed: {0}".format(error))
        else:
            self.set_status("Installing the pythonnet/numpy runtime in the background...")
            QtCore.QTimer.singleShot(2000, self._refresh_runtime_status)

    def _require_runtime(self):
        if not (bootstrap.is_ready() or bootstrap.probe()):
            self.set_status("Installing the pythonnet/numpy runtime...")
            QtWidgets.QApplication.processEvents()
            if not bootstrap.ensure_blocking(sp_apply.log):
                self.report_error("Runtime install",
                                  bootstrap.last_error() or "unknown pip failure")
                return False
            self.set_status("Runtime ready.")
        if not _load_deps():
            self.report_error("Runtime install",
                              "The runtime installed but numpy is still not importable.")
            return False
        return True

    # -- browsing ----------------------------------------------------------

    def _pick_dir(self, edit):
        path = QtWidgets.QFileDialog.getExistingDirectory(self, "Select folder", edit.text())
        if path:
            edit.setText(path)
            if edit is self.game_root:
                self._autofill_cabmap()
            self._save_settings()

    def _pick_cabmap(self, edit):
        """Where the cabmap gets written (or read from). Seeded with
        <game root>/<hook ids>.cabmap so the common case is one click."""
        start = self._resolved_cabmap_path() or config.get("game_root", "")
        path, _filter = QtWidgets.QFileDialog.getSaveFileName(
            self, "Cabmap file", start, "Cabmap (*.cabmap);;All files (*)")
        if path:
            edit.setText(path)
            self._auto_cabmap = ""   # an explicit pick is the user's, keep it
            self._save_settings()

    def _selected_hooks(self):
        return [box.text() for box in self._hook_boxes if box.isChecked()]

    def _on_hook_toggled(self):
        # The default cabmap filename is built from the hook selection, so it
        # has to follow a change of that selection -- but only while the field
        # is still a folder/unset (_autofill_cabmap never overwrites a real
        # filename).
        self._autofill_cabmap()
        self._save_settings()

    def _rebuild_hook_checkboxes(self, hook_ids, checked):
        while self.hooks_layout.count():
            item = self.hooks_layout.takeAt(0)
            widget = item.widget()
            if widget is not None:
                widget.deleteLater()
        self._hook_boxes = []
        checked = set(checked or [])
        for hook_id in hook_ids:
            box = QtWidgets.QCheckBox(hook_id)
            box.setChecked(hook_id in checked)
            box.toggled.connect(self._on_hook_toggled)
            self.hooks_layout.addWidget(box)
            self._hook_boxes.append(box)
        self.hooks_layout.addStretch(1)

    def _refresh_hooks(self):
        if not self._require_runtime():
            return
        self._save_settings()
        try:
            from . import pythonnet_bridge
        except ImportError:
            import pythonnet_bridge

        def work(_progress):
            pythonnet_bridge.set_bin_dir(config.get("ripperhook_bin", ""))
            return pythonnet_bridge.list_available_hooks()

        def done(hook_ids):
            self._rebuild_hook_checkboxes(hook_ids, config.get("hook_ids", []))
            self._autofill_cabmap()
            self.set_status("{0} hook(s) compiled into Ruri.RipperHook.dll.".format(len(hook_ids)))

        self._run(work, done, "Listing hooks")

    def _build_cabmap(self):
        if not self._require_runtime():
            return
        self._save_settings()
        game_root = self.game_root.text().strip()
        if not game_root or not os.path.isdir(game_root):
            self.set_status("Set a valid game root first.")
            return
        out_path = self._resolved_cabmap_path()
        if not out_path:
            self.set_status("Set where the cabmap should be written.")
            return
        if out_path != self.cabmap_path.text().strip():
            self.cabmap_path.setText(out_path)
            self._save_settings()
        hooks = self._selected_hooks()

        def work(progress):
            progress("Scanning {0}...".format(game_root))
            bridge = cabmap_state.ensure_bridge(hooks)
            code = bridge.build_cab_map(game_root, out_path)
            if code != 0:
                raise RuntimeError("BuildCabMap returned {0}".format(code))
            progress("Loading the fresh cabmap...")
            bridge.load_cab_map(out_path)
            cabmap_state.load_rows()
            return len(cabmap_state.ROWS)

        self._run(work, self._after_rows_loaded, "Building cabmap")

    def _load_cabmap(self):
        if not self._require_runtime():
            return
        self._save_settings()
        path = self._resolved_cabmap_path()
        if not path or not os.path.isfile(path):
            self.set_status("No cabmap at {0} -- pick one, or press Build cabmap.".format(
                path or "(unset)"))
            return
        hooks = self._selected_hooks()

        def work(progress):
            progress("Loading {0}...".format(os.path.basename(path)))
            bridge = cabmap_state.ensure_bridge(hooks)
            bridge.load_cab_map(path)
            cabmap_state.load_rows()
            return len(cabmap_state.ROWS)

        self._run(work, self._after_rows_loaded, "Loading cabmap")

    def _after_rows_loaded(self, count):
        self.search.clear()
        self._refresh_view()
        self.set_status("{0} row(s) loaded.".format(count))

    def _schedule_filter(self, _text):
        self._filter_timer.start()

    def _apply_filter(self):
        if not _rows():
            return
        cabmap_state.refresh_visible(self.search.text(), cabmap_state.active_rules())
        self._refresh_view()

    def _go_up(self):
        if not _rows():
            return
        self.search.clear()
        cabmap_state.browse_dir(cabmap_state.CURRENT_DIR[:-1])
        self._refresh_view()

    def _enter_folder(self, name):
        if not _rows() or not name:
            return
        self.search.clear()
        cabmap_state.browse_dir(cabmap_state.CURRENT_DIR + (name,))
        self._refresh_view()

    def _activate_item(self, item):
        """Double-click: a folder navigates, an asset imports.

        ``item`` can legitimately be None -- a view emits activated() with an
        invalid index when the double-click lands on empty space below the last
        row -- so this must not assume there is one."""
        if item is None or not _rows():
            return
        payload = self.table.item(item.row(), 0)
        if payload is None:
            return
        kind, value = payload.data(Qt.UserRole) or (None, None)
        if kind == "up":
            self._go_up()
        elif kind == "dir":
            self._enter_folder(value)
        elif kind == "row":
            self._import(new_project=True)

    def _sort_by_section(self, section):
        if not _rows():
            return
        cabmap_state.cycle_sort(_COLUMNS[section][0])
        self._refresh_view()

    def _add_row(self, row, name, type_text, deps_text, payload, tooltip=None):
        for column, value in enumerate((name, type_text, deps_text)):
            item = QtWidgets.QTableWidgetItem(value)
            if tooltip:
                item.setToolTip(tooltip)
            if column == 0:
                item.setData(Qt.UserRole, payload)
            self.table.setItem(row, column, item)

    def _refresh_view(self):
        if cabmap_state is None:
            return
        searching = bool(self.search.text().strip())
        path = "/" + "/".join(cabmap_state.CURRENT_DIR)
        self.breadcrumb.setText("search results" if searching else path)
        self.breadcrumb.setToolTip("" if searching else path)
        self.up_button.setEnabled(not searching and bool(cabmap_state.CURRENT_DIR))

        folders = [] if searching else list(cabmap_state.CURRENT_SUBFOLDERS)
        show_up = not searching and bool(cabmap_state.CURRENT_DIR)
        total, window = cabmap_state.display_window()

        self.table.setUpdatesEnabled(False)
        self.table.setSortingEnabled(False)
        self.table.setRowCount(len(folders) + len(window) + (1 if show_up else 0))
        row = 0
        if show_up:
            self._add_row(row, "..", "", "", ("up", None))
            row += 1
        for name, count in folders:
            self._add_row(row, "[+] " + name, "folder", str(count), ("dir", name))
            row += 1
        for index, view in window:
            display = (view["name"] if searching
                       else cabmap_state.leaf_name_in_current_dir(index))
            self._add_row(row, display, view["type_names"], str(view["deps"]),
                          ("row", index), tooltip=view["container"])
            row += 1
        self.table.setUpdatesEnabled(True)

        if total > len(window):
            self.set_status("{0} match(es); showing the first {1}. Narrow the search to "
                            "see the rest.".format(total, len(window)))

    def _selected_row_indices(self):
        indices = []
        for item in self.table.selectedItems():
            if item.column() != 0:
                continue
            payload = item.data(Qt.UserRole)
            if not payload or payload[0] != "row":
                continue
            if payload[1] not in indices:
                indices.append(payload[1])
        return sorted(indices)

    # -- import ------------------------------------------------------------

    def _import(self, new_project):
        if not self._require_runtime():
            return
        if not _rows():
            self.set_status("Load a cabmap first, or use 'Import YAML file...'.")
            return
        if cabmap_state.BRIDGE is None:
            self.set_status("No bridge session -- load a cabmap first.")
            return
        indices = self._selected_row_indices()
        if not indices:
            self.set_status("Select at least one asset row.")
            return
        if not new_project and not _project_is_open():
            self.set_status("No project is open to wire.")
            return
        if new_project and not self._confirm_replace_project():
            return

        cabs = [cabmap_state.ROWS.cab(i) for i in indices]
        bridge = cabmap_state.BRIDGE

        def work(progress):
            jobs = importer.jobs_from_cabs(bridge, cabs, progress)
            for job in jobs:
                progress("{0}: preparing...".format(job.name))
                importer.prepare(job, progress)
            return jobs

        self._run(work, lambda jobs: self._launch(jobs, new_project), "Import")

    def _import_from_disk(self):
        start = config.get("last_yaml_path", "") or config.get("game_root", "")
        path, _filter = QtWidgets.QFileDialog.getOpenFileName(
            self, "Unity YAML asset", start, "Unity asset (*.prefab *.asset);;All files (*)")
        if not path:
            return
        if not self._require_runtime():
            return
        config.set_many(last_yaml_path=path)
        if not self._confirm_replace_project():
            return

        def work(progress):
            job = importer.job_from_disk(path, progress)
            importer.prepare(job, progress)
            return [job]

        self._run(work, lambda jobs: self._launch(jobs, True), "Import from disk")

    def _confirm_replace_project(self):
        if not _project_is_open():
            return True
        needs_saving = False
        try:
            import substance_painter.project
            needs_saving = bool(substance_painter.project.needs_saving())
        except Exception:
            pass
        message = ("A project is already open and will be closed.\n\n"
                   + ("It has unsaved changes -- they will be LOST.\n\n" if needs_saving else "")
                   + "Continue?")
        answer = QtWidgets.QMessageBox.question(
            self, "RuriRipper", message,
            QtWidgets.QMessageBox.Yes | QtWidgets.QMessageBox.No,
            QtWidgets.QMessageBox.No)
        return answer == QtWidgets.QMessageBox.Yes

    def _launch(self, jobs, new_project):
        usable = [job for job in jobs if job.build is not None and job.build.glb_path]
        if not usable:
            lines = ["Nothing importable was produced.", ""]
            for job in jobs:
                lines.append("== {0} ==".format(job.name))
                lines.extend(job.report)
            show_report(self, "RuriRipper -- import", lines)
            self.set_status("Nothing importable was produced.")
            return
        if len(usable) > 1:
            usable[0].report.append(
                "note: the selection resolved to {0} root assets; Painter holds one model per "
                "project, so '{1}' was imported. Select the others individually for their "
                "own projects.".format(len(usable), usable[0].name))

        job = usable[0]
        self.set_status("Creating the Painter project...")
        try:
            importer.launch(job,
                            on_finished=self._import_finished,
                            on_error=lambda text: self.report_error("Import", text),
                            reuse_open_project=not new_project)
        except Exception:
            self.report_error("Import", traceback.format_exc())

    def _import_finished(self, job):
        lines = ["model: {0}".format(job.name),
                 "prepared in {0:.1f}s".format(job.seconds), ""] + job.report
        self.set_status("Imported {0} ({1}).".format(job.name, job.build.summary()))
        show_report(self, "RuriRipper -- import report", lines)


def _wrap(layout):
    holder = QtWidgets.QWidget()
    holder.setLayout(layout)
    return holder


def panel_icon():
    """The dock's window icon.

    Painter turns a dock widget's ``windowIcon`` into the quick-access button in
    the right-hand side strip -- the same strip the stock panels live in -- and
    without one the dock has no way back once it is closed. Drawn here rather
    than shipped as a bitmap so it stays crisp at every strip size and needs no
    binary asset in the package."""
    icon = QtGui.QIcon()
    for size in (16, 20, 24, 32, 48, 64):
        pixmap = QtGui.QPixmap(size, size)
        pixmap.fill(Qt.transparent)
        painter = QtGui.QPainter(pixmap)
        painter.setRenderHint(QtGui.QPainter.Antialiasing, True)
        painter.setRenderHint(QtGui.QPainter.TextAntialiasing, True)
        inset = max(1.0, size * 0.09)
        stroke = max(1.0, size / 14.0)
        # Monochrome outline + glyph, matching Painter's own strip icons.
        pen = QtGui.QPen(QtGui.QColor(226, 226, 226))
        pen.setWidthF(stroke)
        painter.setPen(pen)
        painter.setBrush(Qt.NoBrush)
        radius = size * 0.22
        painter.drawRoundedRect(
            QtCore.QRectF(inset, inset, size - 2 * inset, size - 2 * inset), radius, radius)
        font = painter.font()
        font.setPixelSize(max(7, int(size * 0.56)))
        font.setBold(True)
        painter.setFont(font)
        painter.drawText(QtCore.QRectF(0, 0, size, size), Qt.AlignCenter, "R")
        painter.end()
        icon.addPixmap(pixmap)
    return icon


class _Section(QtWidgets.QWidget):
    """A flat collapsible section: a borderless disclosure header plus content.

    Deliberately NOT a checkable QGroupBox. That draws an etched frame with a
    checkbox in the title -- the look Painter's own panels abandoned years ago --
    and its checkbox only *disables* the children, so collapsing never actually
    returned the space. This hides the content outright and draws nothing but a
    header row, matching the stock docks.

    Keeps ``setChecked``/``isChecked``/``toggled`` so it is a drop-in for the
    QGroupBox it replaced.
    """

    toggled = Signal(bool)

    def __init__(self, title, inner, expanded=True):
        super().__init__()
        self._inner = inner
        layout = QtWidgets.QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(2)

        self._header = QtWidgets.QToolButton()
        self._header.setText(title)
        self._header.setCheckable(True)
        self._header.setAutoRaise(True)
        self._header.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
        self._header.setSizePolicy(QtWidgets.QSizePolicy.Expanding,
                                   QtWidgets.QSizePolicy.Fixed)
        font = self._header.font()
        font.setBold(True)
        self._header.setFont(font)
        layout.addWidget(self._header)
        layout.addWidget(inner)

        self._header.toggled.connect(self._on_toggled)
        self.setChecked(expanded)

    def _on_toggled(self, expanded):
        self._inner.setVisible(expanded)
        self._header.setArrowType(Qt.DownArrow if expanded else Qt.RightArrow)
        # Hiding a child invalidates THIS layout's cached hint, but the parent
        # asks *this widget* for its sizeHint, which is served from that cache
        # until it is dropped. Without these two lines a listener reacting to
        # the signal below still measures the pre-collapse height.
        own_layout = self.layout()
        if own_layout is not None:
            own_layout.invalidate()
            own_layout.activate()
        self.updateGeometry()
        self.toggled.emit(expanded)

    def setChecked(self, expanded):
        self._header.setChecked(bool(expanded))
        # setChecked does not emit when the state is unchanged, so mirror the
        # visual state directly too.
        self._inner.setVisible(bool(expanded))
        self._header.setArrowType(Qt.DownArrow if expanded else Qt.RightArrow)

    def isChecked(self):
        return self._header.isChecked()


def _collapsible(title, inner, expanded=True, on_toggle=None):
    section = _Section(title, inner, expanded)
    if on_toggle is not None:
        section.toggled.connect(on_toggle)
    return section


def _with_browse(edit, handler):
    row = QtWidgets.QHBoxLayout()
    row.setContentsMargins(0, 0, 0, 0)
    row.addWidget(edit, 1)
    button = QtWidgets.QToolButton()
    button.setText("...")
    button.clicked.connect(lambda: handler(edit))
    row.addWidget(button)
    return _wrap(row)


def _project_is_open():
    try:
        import substance_painter.project
        return bool(substance_painter.project.is_open())
    except Exception:
        return False
