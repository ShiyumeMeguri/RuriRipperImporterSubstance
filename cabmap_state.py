"""Plain-Python backing store for the cabmap browser: the columnar row table,
the pythonnet bridge session, the virtual-folder-tree navigation state, and
search/sort/selection bookkeeping.

Port of the Blender addon's module of the same name with the bpy dependencies
removed (the debounce timer lives in the Qt panel now, since Qt has its own).
Deliberately not a Qt model of its own: at real-world cabmap scale (~260k rows
for Endfield 1.3.3) materializing every row into widget items is itself the
bottleneck -- the panel materializes only a capped, already-filtered window,
exactly as the WinForms original this browser mirrors used VirtualMode for.
"""

from __future__ import annotations

import re

import numpy as np

try:
    from . import pythonnet_bridge
except ImportError:  # standalone (non-package) testing
    import pythonnet_bridge

DISPLAY_CAP = 500  # max rows ever materialized into the UI at once

ROWS = []       # row_table.RowTable -- the full cabmap, set by load_rows()
VISIBLE = []    # list[int] -- indices into ROWS after the current filter+sort
BRIDGE = None   # pythonnet_bridge.RipperBridge | None -- the active session

# Folder-browser navigation (see "Virtual folder tree" below).
CURRENT_DIR = ()          # tuple[str, ...] -- () is the virtual root
CURRENT_SUBFOLDERS = []   # list[(name, recursive_file_count)], alpha-sorted

# Multi-selection lives here (plain Python), keyed by cab (the row identity),
# so a selection survives re-sorting and stays attached to the same assets
# when the visible window scrolls or narrows.
SELECTED_CABS = set()
SELECT_ANCHOR = None      # ROWS index of the last plainly-clicked row

_sort_column = "name"
_sort_dir = 0             # 0 = load order, 1 = ascending, 2 = descending
_active_rules = ()
_ROWS_BY_CAB = None


def clear_selection():
    global SELECT_ANCHOR
    SELECTED_CABS.clear()
    SELECT_ANCHOR = None


def selected_row_indices():
    """Selected rows in master ROWS order -- the deterministic order a batch
    import runs in (not click order, which nobody can reproduce)."""
    if not SELECTED_CABS or not len(ROWS):
        return []
    index_of = ROWS.cab_to_index()
    return sorted(index_of[cab] for cab in SELECTED_CABS if cab in index_of)


def selected_cabs():
    return [ROWS.cab(i) for i in selected_row_indices()]


def reset():
    global ROWS, VISIBLE, BRIDGE, _sort_dir, _ROWS_BY_CAB
    global CURRENT_DIR, CURRENT_SUBFOLDERS, _ROOT
    ROWS = []
    VISIBLE = []
    BRIDGE = None
    _sort_dir = 0
    _ROWS_BY_CAB = None
    CURRENT_DIR = ()
    CURRENT_SUBFOLDERS = []
    _ROOT = _Node()
    clear_selection()


def ensure_bridge(hook_ids):
    """Get (or lazily create) the session's one active bridge, with its hook
    selection kept in sync with hook_ids on EVERY call -- not just on first
    construction. A cabmap built or loaded before the right hook was ticked
    would otherwise poison the session permanently, with no way to recover
    short of restarting the application; re-applying the selection through
    RipperBridge.reinitialize() is cheap (the C# side diffs the hook set and
    only toggles the delta) and preserves the already-loaded cabmap."""
    global BRIDGE
    hook_ids = tuple(hook_ids)
    if BRIDGE is None:
        BRIDGE = pythonnet_bridge.RipperBridge(hook_ids)
    elif BRIDGE.hook_ids != hook_ids:
        BRIDGE.reinitialize(hook_ids)
    return BRIDGE


def load_rows():
    """Pull every row from the currently-loaded cabmap into ROWS and reset the
    browser to the virtual root folder."""
    global ROWS, _ROWS_BY_CAB
    if BRIDGE is None:
        raise RuntimeError("No bridge session -- call ensure_bridge() first.")
    ROWS = BRIDGE.enumerate_table()
    _ROWS_BY_CAB = None
    clear_selection()   # cab keys from a previous map mean nothing in this one
    _build_tree()       # also resets CURRENT_DIR/VISIBLE/CURRENT_SUBFOLDERS


class _RowsByCab:
    """cab -> row-view mapping over a columnar RowTable: the cab->index dict is
    the table's own lazy index; row views materialize per lookup only."""

    __slots__ = ("_table",)

    def __init__(self, table):
        self._table = table

    def get(self, cab, default=None):
        index = self._table.cab_to_index().get(cab)
        return self._table[index] if index is not None else default

    def __getitem__(self, cab):
        return self._table[self._table.cab_to_index()[cab]]

    def __contains__(self, cab):
        return cab in self._table.cab_to_index()


def rows_by_cab():
    global _ROWS_BY_CAB
    if _ROWS_BY_CAB is None:
        _ROWS_BY_CAB = _RowsByCab(ROWS)
    return _ROWS_BY_CAB


# ---------------------------------------------------------------------------
# Include/Exclude rule engine (ported from the WinForms browser's Filter.cs)
# ---------------------------------------------------------------------------
FILTER_FIELDS = ("name", "container", "type_names", "source", "deps")
FIELD_LABELS = {"name": "Name", "container": "Container", "type_names": "Type",
                "source": "Source", "deps": "Deps"}
RELATIONS = ("is", "is_not", "contains", "excludes", "begins_with", "ends_with",
             "less_than", "more_than", "matches_regex", "not_matches_regex")
RELATION_LABELS = {
    "is": "is", "is_not": "is not", "contains": "contains", "excludes": "excludes",
    "begins_with": "begins with", "ends_with": "ends with",
    "less_than": "less than", "more_than": "more than",
    "matches_regex": "matches regex", "not_matches_regex": "not matches regex",
}
ACTIONS = ("include", "exclude")


class Rule:
    __slots__ = ("field", "relation", "value", "action", "enabled")

    def __init__(self, field, relation, value, action, enabled=True):
        self.field = field
        self.relation = relation
        self.value = value
        self.action = action
        self.enabled = enabled


def _relation_matches(relation, cell_value, rule_value):
    if relation in ("less_than", "more_than"):
        try:
            lhs, rhs = float(cell_value), float(rule_value)
        except (TypeError, ValueError):
            return False
        return lhs < rhs if relation == "less_than" else lhs > rhs

    text = str(cell_value).lower()
    needle = str(rule_value).lower()
    if relation == "is":
        return text == needle
    if relation == "is_not":
        return text != needle
    if relation == "contains":
        return needle in text
    if relation == "excludes":
        return needle not in text
    if relation == "begins_with":
        return text.startswith(needle)
    if relation == "ends_with":
        return text.endswith(needle)
    if relation in ("matches_regex", "not_matches_regex"):
        try:
            found = re.search(str(rule_value), str(cell_value), re.IGNORECASE) is not None
        except re.error:
            return False
        return found if relation == "matches_regex" else not found
    return False


def row_passes_rules(row, rules):
    """Every ENABLED rule is a required constraint -- Include(X) requires a
    match, Exclude(X) requires a non-match. A row passes only if it satisfies
    all of them (no rules => show everything)."""
    for rule in rules:
        if not rule.enabled:
            continue
        matched = _relation_matches(rule.relation, row.get(rule.field, ""), rule.value)
        if rule.action == "exclude":
            if matched:
                return False
        elif not matched:
            return False
    return True


# ---------------------------------------------------------------------------
# Virtual folder tree
# ---------------------------------------------------------------------------
# The browser's default view: a real file-browser-style drill-down over each
# row's container path(s) (Unity's own AssetBundle container keys, already
# lowercase and "/"-separated -- exactly a virtual filesystem path) instead of
# dumping ~260k rows flat. Built once per load_rows() in O(total path
# segments); browse_dir() then reads it in O(children of that folder).

_NO_PATH_BUCKET = "(no virtual path)"


class _Node:
    __slots__ = ("children", "files", "file_count")

    def __init__(self):
        self.children = {}
        self.files = []
        self.file_count = 0


_ROOT = _Node()


def _add_leaf(segments, row_index):
    node = _ROOT
    for segment in segments:
        child = node.children.get(segment)
        if child is None:
            child = _Node()
            node.children[segment] = child
        node = child
        node.file_count += 1
    node.files.append(row_index)


def _build_tree():
    """Rebuild the folder tree from ROWS and reset browsing to the root. A row
    exported under more than one container path appears under every one of
    them; a row that lands nowhere falls back to a folder under
    _NO_PATH_BUCKET keyed by its own cab, so it stays reachable."""
    global _ROOT
    _ROOT = _Node()
    path_count_of = ROWS.container_path_count
    path_of = ROWS.container_path
    cab_of = ROWS.cab
    for index in range(len(ROWS)):
        placed = False
        for p in range(path_count_of(index)):
            segments = [s for s in path_of(index, p).split("/") if s]
            if segments:
                _add_leaf(segments, index)
                placed = True
        if not placed:
            _add_leaf((_NO_PATH_BUCKET, cab_of(index)), index)
    browse_dir(())


def folder_of(row_index, path_index=0):
    """The folder-tree path (segments, excluding the row's own leaf name) a
    row's container path lives under -- mirrors _build_tree's placement exactly
    so "jump to this row's folder" lands where browse_dir would show it."""
    path_count = ROWS.container_path_count(row_index)
    if path_count == 0:
        return (_NO_PATH_BUCKET,)
    path = ROWS.container_path(row_index, min(max(path_index, 0), path_count - 1))
    segments = [s for s in path.split("/") if s]
    return tuple(segments[:-1])


def best_path_index_for_jump(row_index, query):
    """Which of a multi-path row's container paths folder_of() should target:
    in the folder view, the one matching CURRENT_DIR (the identity the row is
    already displayed under); in a flat search view, the first one containing
    the search text (the path it actually matched on)."""
    path_count = ROWS.container_path_count(row_index)
    if path_count <= 1:
        return 0
    needle = (query or "").strip().lower()
    if not needle:
        depth = len(CURRENT_DIR)
        for p in range(path_count):
            segments = tuple(s for s in ROWS.container_path(row_index, p).split("/") if s)
            if len(segments) == depth + 1 and segments[:depth] == CURRENT_DIR:
                return p
        return 0
    for p in range(path_count):
        if needle in ROWS.container_path(row_index, p).lower():
            return p
    return 0


def _node_at(path):
    node = _ROOT
    for segment in path:
        node = node.children.get(segment)
        if node is None:
            return None
    return node


def browse_dir(path):
    """Point the browser at a virtual folder and recompute VISIBLE /
    CURRENT_SUBFOLDERS for exactly that folder's own children -- O(children),
    never O(len(ROWS)). An unreachable path falls back to root."""
    global CURRENT_DIR, VISIBLE, CURRENT_SUBFOLDERS
    node = _node_at(path)
    if node is None:
        path, node = (), _ROOT
    CURRENT_DIR = tuple(path)
    subfolders = []
    files = []
    for name, child in node.children.items():
        if child.children:   # has descendants -> browsable folder
            subfolders.append((name, child.file_count))
        if child.files:      # a container path ends exactly here -> also a file
            files.extend(child.files)
    subfolders.sort(key=lambda pair: pair[0].lower())
    CURRENT_SUBFOLDERS = subfolders
    VISIBLE = files
    _apply_sort()


def has_active_query(query, rules):
    if (query or "").strip():
        return True
    return any(r.enabled for r in rules)


def refresh_visible(query, rules=()):
    """The single dispatch point between the two views: flat global search/rule
    results, or the folder listing for CURRENT_DIR."""
    global _active_rules
    _active_rules = tuple(rules)
    if has_active_query(query, _active_rules):
        apply_filter(query, _active_rules)
    else:
        browse_dir(CURRENT_DIR)


def leaf_name_in_current_dir(index):
    """The display name for a row AS BROWSED under CURRENT_DIR. Matters only
    for the rare row with several container paths, whose default name (always
    path[0]'s leaf) can belong to a different folder than the one it is being
    shown in."""
    depth = len(CURRENT_DIR)
    for p in range(ROWS.container_path_count(index)):
        segments = tuple(s for s in ROWS.container_path(index, p).split("/") if s)
        if len(segments) == depth + 1 and segments[:depth] == CURRENT_DIR:
            return segments[-1]
    return ROWS.name(index)


def apply_filter(query, rules=()):
    """Quick search across Name/Container/Source/Type AND the Include/Exclude
    rule set, both of which must pass. The search runs vectorized over the
    RowTable's column blobs; the rule engine only evaluates the rows the search
    already narrowed to. Always a FLAT result set over the whole cabmap."""
    global VISIBLE, _active_rules, CURRENT_SUBFOLDERS
    query = (query or "").strip().lower()
    rules = tuple(rules)
    _active_rules = rules
    CURRENT_SUBFOLDERS = []
    enabled = [r for r in rules if r.enabled]
    candidates = np.flatnonzero(ROWS.search_mask(query))
    if enabled:
        VISIBLE = [int(i) for i in candidates if row_passes_rules(ROWS[int(i)], enabled)]
    else:
        VISIBLE = candidates.tolist()
    _apply_sort()


def active_rules():
    return _active_rules


def _apply_sort():
    global VISIBLE
    if _sort_dir == 0:
        VISIBLE.sort()  # back to load order
        return
    values = ROWS.sort_values(_sort_column)
    VISIBLE.sort(key=values.__getitem__, reverse=(_sort_dir == 2))


def cycle_sort(column):
    """Tri-state per column: ascending -> descending -> unsorted, mirroring the
    WinForms browser's column-header click behaviour."""
    global _sort_column, _sort_dir
    if _sort_column != column:
        _sort_column, _sort_dir = column, 1
    else:
        _sort_dir = (_sort_dir + 1) % 3
    _apply_sort()


def sort_state():
    return _sort_column, _sort_dir


def display_window():
    """Up to DISPLAY_CAP filtered/sorted rows, ready for the UI. Returns
    (total_visible_count, [(rows_index, row_view), ...])."""
    capped = VISIBLE[:DISPLAY_CAP]
    return len(VISIBLE), [(i, ROWS[i]) for i in capped]
