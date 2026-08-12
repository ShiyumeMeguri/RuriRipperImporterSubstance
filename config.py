"""This plugin's settings: WHICH keys exist and what they mean.

The store itself (defaults, unknown-key rejection, versioned repair, atomic
writes) is ``RuriRipperPyBridge.runtime.settings`` -- none of that is
Painter-specific. What is Painter-specific is everything below: the key set, and
where the workspace lives (the user's Painter resources directory, never inside
this package, which is a checkout that gets replaced wholesale).

The Blender add-on keeps its one genuinely machine-specific path in Blender's
own AddonPreferences; Painter has no equivalent for plugins, hence the file.

Everything the plugin needs to find on disk is either derived from ``__file__``
(the bundled shader) or stored here (the RipperHook bin dir, the game root, the
cabmap path, the hook selection). There are no hardcoded absolute paths
anywhere in this package.
"""

from __future__ import annotations

import os

try:
    from .RuriRipperPyBridge.runtime import settings as _settings
    from .RuriRipperPyBridge.runtime import workspace as _workspace
except ImportError:  # standalone (non-package) testing
    from RuriRipperPyBridge.runtime import settings as _settings
    from RuriRipperPyBridge.runtime import workspace as _workspace

_DEFAULTS = {
    # Folder that directly contains Ruri.RipperHook.dll AND
    # Ruri.RipperHook.CLI.runtimeconfig.json, e.g.
    # <Ruri-RipperHook checkout>/AssetRipper/Source/0Bins/AssetRipper/Release
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

_IMPORT_OPTION_KEYS = (
    "lod0_only", "import_shadow_proxies", "import_inactive", "import_normals",
    "import_colors", "import_tangents", "keep_unity_uv_origin",
)


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
    texture cache) lives under one folder outside the package.

    Registered with the shared workspace resolver at plugin start, so
    ``bootstrap``'s ABI-keyed runtime folder lands in the same place it always
    has: <Painter user resources>/python/RuriRipperWorkspace/runtime/<abi>."""
    path = os.path.join(user_resources_dir(), "RuriRipperWorkspace")
    os.makedirs(path, exist_ok=True)
    return path


def cache_dir():
    path = os.path.join(workspace_dir(), "cache")
    os.makedirs(path, exist_ok=True)
    return path


def activate_workspace():
    """Point the shared workspace resolver at this plugin's own folder. Call
    once, before anything reads settings or touches the bootstrap."""
    _workspace.configure(workspace_dir())


# Version 1 of this file was written by a panel that connected each widget's
# change signal BEFORE populating the widgets from the settings, so the first
# setChecked() during load fired a save of the still-empty widget row --
# persisting every option as off and the resolution as the combo box's first
# entry, right over the real defaults. Version 2 predates the mandatory
# Unity -> glTF UV V flip, whose option key changed shape entirely. Bumping
# settings_version resets exactly the option block; typed paths and the hook
# selection are the user's own input and survive.
_STORE = _settings.JsonSettings(
    os.path.join(workspace_dir(), "settings.json"), _DEFAULTS, _OPTION_KEYS)


def load():
    return _STORE.load()


def get(key, default=None):
    return _STORE.get(key, default)


def set_many(**values):
    return _STORE.set_many(**values)


def save():
    return _STORE.save()


def import_options():
    """The option dict the model builder consumes -- same keys/meanings as the
    Blender addon's ``_ImportOptionsMixin.as_options``."""
    return _STORE.subset(_IMPORT_OPTION_KEYS, bool)
