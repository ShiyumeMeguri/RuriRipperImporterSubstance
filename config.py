"""Persisted, per-machine plugin settings.

The Blender addon keeps the one genuinely machine-specific path (the built
Ruri.RipperHook bin dir) in Blender's AddonPreferences so it never has to be
hardcoded. Painter has no equivalent preference store for plugins, so this is
the same idea backed by a small JSON file living beside the plugin's runtime
folder in the user's Painter resources directory -- never inside the plugin
package itself, which is a checkout that gets replaced wholesale.

Everything the plugin needs to find on disk is either derived from
``__file__`` (the bundled shader, the texture cache) or stored here (the
RipperHook bin dir, the game root, the cabmap path, the hook selection). There
are no hardcoded absolute paths anywhere in this package.
"""

from __future__ import annotations

import json
import os
import threading

_DEFAULTS = {
    # Folder that directly contains Ruri.RipperHook.dll AND
    # Ruri.RipperHook.CLI.runtimeconfig.json, e.g.
    # <Ruri-RipperHook checkout>/AssetRipper/Source/0Bins/AssetRipper/Debug
    "ripperhook_bin": "",
    # Game install root scanned when building a cabmap.
    "game_root": "",
    # Cabmap file built/loaded from that root.
    "cabmap_path": "",
    # Hook ids compiled into Ruri.RipperHook.dll that should be active
    # (e.g. ["EndField_1.3.3"]).
    "hook_ids": [],
    # Last on-disk YAML prefab imported through the fallback path.
    "last_yaml_path": "",
    # Import options, mirroring the Blender addon's own option set.
    "lod0_only": True,
    "import_shadow_proxies": False,
    "import_inactive": True,
    "import_normals": True,
    "import_colors": True,
    "import_tangents": True,
    # Escape hatch: the Unity -> glTF V flip is REQUIRED (Unity's texture
    # origin is bottom-left, glTF's is top-left), so this is off, and turning
    # it on mirrors every texture vertically. Kept only for a source that is
    # already top-left-origin.
    "keep_unity_uv_origin": False,
    # Painter project defaults.
    "texture_resolution": 2048,
    # Rebuild the model/texture cache even when it already looks current.
    "force_rebuild": False,
    # Display settings the ported shader documents as requirements: the
    # matching reflection cubemap ([H6]) and the Linear display tone mapping
    # ([H9], the HG tonemap is inside the shader and must not be applied
    # twice). The colour LUT is the companion grading strip shipped next to
    # them in the shader folder.
    "apply_environment": True,
    "apply_color_lut": True,
    "force_linear_tonemap": True,
    # Panel layout. dock_placed records that the dock has been put into the
    # right-hand strip once; after that Painter's own saved layout wins.
    "source_expanded": True,
    "options_expanded": True,
    "dock_placed": False,
    # Bumped when a stored file has to be repaired rather than trusted; see
    # _migrate.
    "settings_version": 3,
}

# Keys whose stored value is only meaningful once the panel has actually
# written it deliberately. Everything the user types (paths, hook selection)
# is preserved across a migration; these are reset to their defaults.
_OPTION_KEYS = (
    "lod0_only", "import_shadow_proxies", "import_inactive", "import_normals",
    "import_colors", "import_tangents", "keep_unity_uv_origin", "force_rebuild",
    "texture_resolution", "apply_environment", "apply_color_lut",
    "force_linear_tonemap",
)

_lock = threading.Lock()
_cache = None


def plugin_dir():
    return os.path.dirname(os.path.abspath(__file__))


def shader_dir():
    """The shader assets bundled INSIDE this package -- EndField_Uber.glsl and
    its companion environment/LUT files."""
    return os.path.join(plugin_dir(), "shader")


def user_resources_dir():
    """<Painter user resources>/python -- the parent of the plugins folder this
    package was loaded from."""
    return os.path.dirname(os.path.dirname(plugin_dir()))


def workspace_dir():
    """Everything this plugin generates (settings, installed runtime, model and
    texture cache) lives under one folder outside the package."""
    path = os.path.join(user_resources_dir(), "RuriRipperWorkspace")
    os.makedirs(path, exist_ok=True)
    return path


def cache_dir():
    path = os.path.join(workspace_dir(), "cache")
    os.makedirs(path, exist_ok=True)
    return path


def _settings_path():
    return os.path.join(workspace_dir(), "settings.json")


def _migrate(data, stored):
    """Repair a settings file written by a panel that saved mid-load.

    Version 1 connected each widget's change signal before populating the
    widgets FROM the settings, so the first setChecked() during load fired a
    save of the still-empty widget row -- persisting every option as off and
    the resolution as the combo box's first entry, right over the real
    defaults. Reset the option block once (the typed paths and hook selection
    are the user's own input and are kept), then stamp the new version so this
    never runs again. Version 2 predates the mandatory Unity -> glTF UV V flip,
    whose option key changed shape entirely."""
    if stored.get("settings_version", 1) >= _DEFAULTS["settings_version"]:
        return False
    for key in _OPTION_KEYS:
        data[key] = _DEFAULTS[key]
    data["settings_version"] = _DEFAULTS["settings_version"]
    return True


def load():
    global _cache
    with _lock:
        if _cache is not None:
            return _cache
        data = dict(_DEFAULTS)
        repaired = False
        try:
            with open(_settings_path(), "r", encoding="utf-8") as handle:
                stored = json.load(handle)
            if isinstance(stored, dict):
                for key, value in stored.items():
                    if key in _DEFAULTS:
                        data[key] = value
                repaired = _migrate(data, stored)
        except (OSError, ValueError):
            pass
        _cache = data
    if repaired:
        save()
    return _cache


def get(key, default=None):
    return load().get(key, _DEFAULTS.get(key, default))


def set_many(**values):
    data = load()
    changed = False
    for key, value in values.items():
        if key not in _DEFAULTS:
            continue
        if data.get(key) != value:
            data[key] = value
            changed = True
    if changed:
        save()
    return changed


def save():
    data = load()
    try:
        with open(_settings_path(), "w", encoding="utf-8") as handle:
            json.dump(data, handle, indent=2, ensure_ascii=False)
    except OSError:
        pass


def import_options():
    """The option dict the model builder consumes -- same keys/meanings as the
    Blender addon's ``_ImportOptionsMixin.as_options``."""
    data = load()
    return {
        "lod0_only": bool(data.get("lod0_only", True)),
        "import_shadow_proxies": bool(data.get("import_shadow_proxies", False)),
        "import_inactive": bool(data.get("import_inactive", True)),
        "import_normals": bool(data.get("import_normals", True)),
        "import_colors": bool(data.get("import_colors", True)),
        "import_tangents": bool(data.get("import_tangents", True)),
        "keep_unity_uv_origin": bool(data.get("keep_unity_uv_origin", False)),
    }
