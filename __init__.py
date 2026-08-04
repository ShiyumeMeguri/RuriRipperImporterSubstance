# -*- coding: utf-8 -*-
"""RuriRipperImporterSubstance -- load Endfield models straight into Substance
Painter, with the EndField_Uber shader wired up exactly as the game had it.

The Painter-side twin of the Blender RuriRipperImporter add-on, reading from
the same source of truth by the same route: an in-process pythonnet bridge into
Ruri.RipperHook.dll boots CoreCLR inside Painter, resolves a cabmap selection's
dependency closure straight out of the game install, and hands back Unity YAML
documents and texture bytes IN MEMORY. From there this plugin

  * decodes the Unity meshes itself (bind-pose baked, LOD0 only, shadow
    proxies dropped) and writes a single self-contained .glb, which is the one
    file Painter needs because ``project.create`` takes a mesh path and there
    is no in-memory geometry API;
  * reads every material's real properties out of the same YAML and turns them
    into the exact EndField_Uber uniform table, part inference included;
  * splits the source textures into Painter's engine channels (BaseMap ->
    basecolor+opacity, packed RMOS -> metallic/specular/AO/roughness, Unity
    RG/AG normals rebuilt to OpenGL, hair split normals, parallax height) and
    imports the remaining data maps as shader samplers;
  * creates the project, builds one same-named shader instance per Texture Set,
    writes all of it, and sets the display environment/tone mapping the ported
    shader documents as requirements.

No intermediate export step, no folder of pre-split PNGs to build first, no
hardcoded paths: the shader and its companion environment/LUT ship inside this
package, and the only machine-specific value (where Ruri.RipperHook.dll was
built) lives in the plugin's own settings file.

An already-extracted Unity YAML folder on disk works too, as a fallback.
"""

from __future__ import annotations

import importlib
import os
import sys

import substance_painter.logging
import substance_painter.ui

# The private runtime folder has to be on sys.path BEFORE anything that imports
# numpy, and this package's own directory has to be importable for the
# non-package standalone fallbacks in the submodules.
_HERE = os.path.dirname(os.path.abspath(__file__))
if _HERE not in sys.path:
    sys.path.append(_HERE)

# config is stdlib-only, and the bootstrap must know where the workspace is
# before it can find (or install) the private runtime folder.
from . import config  # noqa: E402
from .ruri_pybridge.runtime import bootstrap, pythonnet_bridge  # noqa: E402

config.activate_workspace()
bootstrap.activate()  # must precede the numpy-dependent imports

from . import ui  # noqa: E402

# Reloadable, in dependency order. The shared package is handled separately
# (see reload_plugin) because part of it must never be reloaded.
_SUBMODULES = (
    "config", "gltf_writer", "model_builder", "unity_material",
    "texture_pipeline", "sp_apply", "importer", "ui",
)

# Shared modules whose globals track real process state that a reload would
# desync from reality: the claimed CoreCLR runtime and loaded DLL type, the
# installed runtime folder, a multi-second cabmap load, discovered placements.
_STATEFUL_SHARED = ("runtime.bootstrap", "runtime.pythonnet_bridge",
                    "session.cabmap_state", "session.scene_state")

plugin_widgets = []
_panel = None


def _log(message):
    substance_painter.logging.info("[RuriRipper] {0}".format(message))


def start_plugin():
    global _panel

    # Push the stored bin dir into the bridge BEFORE the early CoreCLR claim:
    # the claim needs it to find Ruri.RipperHook.CLI.runtimeconfig.json at all.
    # The hint travels with it -- the shared bridge has no idea where THIS host
    # keeps that setting, and its error message says so.
    pythonnet_bridge.set_bin_dir(config.get("ripperhook_bin", ""))
    pythonnet_bridge.set_bin_dir_hint(
        "Set it in the RuriRipper panel's 'RipperHook bin' field, or set the "
        "RURI_RIPPERHOOK_BIN environment variable.")
    # THIS host's image capability: Painter decodes through Qt, which ships no
    # tga/exr codec. Declaring it here makes the bridge convert exactly the
    # textures Qt cannot read and hand every other one over byte-identical to
    # the game's own container. Blender declares nothing and gets raw tga/exr.
    pythonnet_bridge.set_texture_formats(("png", "jpeg", "bmp"))

    # Claim the process-wide CLR runtime (CoreCLR) as early as possible, before
    # any other plugin in python/plugins gets a chance to trigger its own lazy
    # `import clr` (which defaults to .NET Framework on Windows and would
    # permanently lock out the net10.0 DLL for the rest of this session --
    # pythonnet allows exactly one runtime per process). Cheap and synchronous
    # (it only registers a config; the runtime spins up lazily on first real
    # CLR use), and a no-op if pythonnet isn't installed yet or the bin dir
    # isn't configured yet.
    try:
        pythonnet_bridge.claim_runtime_early()
    except Exception as exc:  # best effort -- _ensure_runtime retries for real later
        _log("early CoreCLR claim skipped: {0}".format(exc))

    # Non-blocking: a first-time pip install can take 10-60s and must not
    # freeze Painter's UI. The panel gates its bridge actions on this. on_ready
    # closes the window the synchronous claim above cannot cover: pythonnet only
    # becoming importable partway through the session, after that claim
    # already no-opped.
    bootstrap.ensure_async(_log, on_ready=pythonnet_bridge.claim_runtime_early)

    _panel = ui.RuriRipperPanel()
    dock = substance_painter.ui.add_dock_widget(_panel)
    plugin_widgets.append(_panel)
    _dock_into_side_strip(dock)
    _log("RuriRipperImporterSubstance loaded -- the RuriRipper dock is in the right-hand "
         "panel strip (its 'R' button reopens it if closed).")


def _dock_into_side_strip(dock):
    """Put the dock where the stock panels live: tabbed into the right-hand
    strip, next to Shader Settings and friends.

    Only on the FIRST run. Painter persists each dock's area and geometry by
    objectName, so forcing the position on every start would undo the user's own
    arrangement every time they restart."""
    if dock is None or config.get("dock_placed", False):
        return
    try:
        from PySide6.QtCore import Qt
        from PySide6.QtWidgets import QDockWidget
    except ImportError:
        from PySide2.QtCore import Qt
        from PySide2.QtWidgets import QDockWidget
    try:
        main_window = substance_painter.ui.get_main_window()
        neighbours = [d for d in main_window.findChildren(QDockWidget)
                      if d is not dock and not d.isFloating() and d.isVisible()
                      and main_window.dockWidgetArea(d) == Qt.RightDockWidgetArea]
        main_window.addDockWidget(Qt.RightDockWidgetArea, dock)
        if neighbours:
            # Tabify onto the existing right-hand group rather than stealing
            # vertical space from it.
            main_window.tabifyDockWidget(neighbours[-1], dock)
        dock.show()
        dock.raise_()
        config.set_many(dock_placed=True)
    except Exception as exc:
        _log("could not place the dock automatically ({0}) -- drag it where you want it "
             "and Painter will remember.".format(exc))


def close_plugin():
    global _panel
    for widget in plugin_widgets:
        substance_painter.ui.delete_ui_element(widget)
    plugin_widgets.clear()
    _panel = None


def reload_plugin():
    """Painter calls this between close_plugin() and start_plugin() on a
    reload. Every stateless submodule is re-imported so an edit takes effect
    without restarting the application; the ones holding real, expensive or
    unrepeatable process state are deliberately left alone -- reloading them
    would reset their globals to source defaults while the state they track
    (a CoreCLR runtime that can never be re-claimed once set, an installed
    runtime folder, a multi-second cabmap load) is still very much alive."""
    # Shared package first (sys.modules order puts parents before children), so
    # the plugin modules reloaded after it pick up the new objects rather than
    # holding references to the previous generation.
    shared_prefix = __name__ + ".ruri_pybridge."
    for name, module in list(sys.modules.items()):
        if name.startswith(shared_prefix) and not name.endswith(_STATEFUL_SHARED):
            importlib.reload(module)
    for name in _SUBMODULES:
        module = sys.modules.get(__name__ + "." + name)
        if module is not None:
            importlib.reload(module)


if __name__ == "__main__":
    start_plugin()
