"""Auto-install this plugin's binary dependencies into a private, ABI-keyed
site-packages folder on first use.

Substance Painter ships pip and PySide6 but nothing else; the bridge needs
pythonnet (the `clr` CoreCLR host, whose clr_loader -> cffi dependency is a
compiled extension) and numpy (mesh decode / image math). Two things make this
different from the Blender addon's equivalent bootstrap:

  * ``sys.executable`` inside Painter is the APPLICATION exe, not a Python
    interpreter, so ``sys.executable -m pip`` can't work. The interpreter is
    found next to ``sys.prefix``/``sys.base_prefix`` (Painter points PYTHONHOME
    at ``resources/pythonsdk``), with an in-process ``runpy`` pip run as the
    last resort.
  * The interpreter shipped in that folder is NOT guaranteed to be the same
    minor version as the one actually embedded in the running application (this
    install ships both python311.dll and python313.dll while pythonsdk/
    python.exe reports 3.13). Installing with that exe's own defaults would
    fetch wheels for the WRONG ABI, and a cp313 cffi/numpy is simply not
    loadable by a live cp311 interpreter. Every install therefore passes the
    LIVE interpreter's ``--python-version``/``--abi``/``--platform`` explicitly
    together with ``--only-binary=:all: --target``, which makes the resolution
    independent of whichever interpreter happens to run pip.

The target folder is keyed by that same ABI tag, so a Painter upgrade that
changes the embedded interpreter simply starts a fresh, correct folder next to
the old one instead of silently loading incompatible binaries.
"""

from __future__ import annotations

import importlib.util
import os
import subprocess
import sys
import sysconfig
import threading

# clr-loader < 0.2.10 mis-parses .NET 10.x version strings ("10.0" -> "10..0"),
# throwing FrameworkMissingFailure when booting CoreCLR (fixed upstream by
# pythonnet/clr-loader#104) -- pin past that fix rather than trusting a stale
# cached "latest". pythonnet>=3.1.0 is the first line with clean CPython 3.13
# wheels.
_REQUIREMENTS = ("pythonnet>=3.1.0", "clr-loader>=0.3.1", "numpy>=1.24")
_MODULES = ("clr", "pythonnet", "clr_loader", "numpy")

_state_lock = threading.Lock()
_ready = False
_error = None
_install_thread = None
_log = [print]


def set_reporter(report_fn):
    _log[0] = report_fn


def _report(message):
    try:
        _log[0](message)
    except Exception:
        pass


# --------------------------------------------------------------------------
# Private site-packages
# --------------------------------------------------------------------------
def abi_tag():
    """cp<major><minor>-<platform> for the LIVE interpreter -- the identity the
    installed wheels have to match."""
    major, minor = sys.version_info[:2]
    platform = sysconfig.get_platform().replace("-", "_").replace(".", "_")
    return "cp{0}{1}-{2}".format(major, minor, platform)


def runtime_dir():
    """<Painter user resources>/python/RuriRipperWorkspace/runtime/<abi tag>.

    Derived from this file's own location (``.../python/plugins/<pkg>/``) so
    nothing here is hardcoded and the folder travels with the user profile
    rather than the (upgrade-replaced, possibly read-only) app install. It
    deliberately sits OUTSIDE ``plugins/`` -- Painter enumerates that folder
    looking for plugins -- and beside the settings file, so everything this
    plugin generates lives under one workspace root. (config.py derives the
    same root; this module keeps its own copy so it stays importable with zero
    dependencies, which is the point of a bootstrap.)"""
    python_dir = os.path.dirname(  # .../python
        os.path.dirname(          # .../python/plugins
            os.path.dirname(os.path.abspath(__file__))))
    return os.path.join(python_dir, "RuriRipperWorkspace", "runtime", abi_tag())


def activate():
    """Put the private folder on sys.path (idempotent). Safe to call before the
    install has happened -- a missing folder is simply not added."""
    target = runtime_dir()
    if os.path.isdir(target) and target not in sys.path:
        sys.path.insert(0, target)
    return target


# --------------------------------------------------------------------------
# Probing
# --------------------------------------------------------------------------
def _findable(name):
    """importlib.util.find_spec(name) without the crash: a module already
    sitting in sys.modules -- however it got there, which for pythonnet's `clr`
    can be outside normal import machinery -- counts as present, and find_spec
    raises ValueError rather than returning cleanly for those."""
    if name in sys.modules:
        return True
    try:
        return importlib.util.find_spec(name) is not None
    except (ValueError, ModuleNotFoundError, ImportError):
        return False


def probe():
    """Whether every dependency is importable, WITHOUT importing `clr` for the
    first time -- a bare `import clr` has the side effect of implicitly picking
    (and permanently locking in) a default CLR runtime, which on Windows means
    .NET Framework. pythonnet_bridge has to be the one to set CoreCLR
    explicitly before `clr` is ever imported anywhere."""
    activate()
    return all(_findable(name) for name in _MODULES)


def is_ready():
    with _state_lock:
        return _ready


def last_error():
    with _state_lock:
        return _error


# --------------------------------------------------------------------------
# Install
# --------------------------------------------------------------------------
def _interpreter_candidates():
    """Real python.exe candidates, most-likely first. Painter's own
    ``sys.executable`` is the application, so it is only accepted when it
    genuinely looks like an interpreter (headless/CLI runs of this module)."""
    exe = "python.exe" if os.name == "nt" else "python3"
    bases = [sys.prefix, sys.base_prefix, sys.exec_prefix]
    # Painter's sys.executable is the application; its bundled interpreter sits
    # in resources/pythonsdk next to it. Derived, never hardcoded -- and only a
    # fallback for the case where PYTHONHOME did not make sys.prefix point there
    # already.
    app_dir = os.path.dirname(os.path.abspath(sys.executable or ""))
    if app_dir:
        bases.append(os.path.join(app_dir, "resources", "pythonsdk"))
    seen = []
    for base in bases:
        for candidate in (os.path.join(base, exe),
                          os.path.join(base, "bin", exe),
                          os.path.join(base, "Scripts", exe)):
            if os.path.isfile(candidate) and candidate not in seen:
                seen.append(candidate)
    own = os.path.basename(sys.executable or "").lower()
    if own.startswith("python") and os.path.isfile(sys.executable):
        if sys.executable not in seen:
            seen.insert(0, sys.executable)
    return seen


def _pip_arguments(target):
    """Explicit-ABI, wheels-only, into-target install -- see the module
    docstring for why the ABI can never be left to the running interpreter."""
    major, minor = sys.version_info[:2]
    platform = sysconfig.get_platform().replace("-", "_").replace(".", "_")
    return [
        "install", "--no-cache-dir", "--no-warn-script-location", "--upgrade",
        "--target", target,
        "--only-binary=:all:",
        "--python-version", "{0}.{1}".format(major, minor),
        "--implementation", "cp",
        "--abi", "cp{0}{1}".format(major, minor),
        "--platform", platform,
    ] + list(_REQUIREMENTS)


def _run_external_pip(target):
    last = None
    for interpreter in _interpreter_candidates():
        try:
            result = subprocess.run(
                [interpreter, "-m", "pip"] + _pip_arguments(target),
                check=False, capture_output=True, text=True,
                creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        except OSError as exc:
            last = "{0}: {1}".format(interpreter, exc)
            continue
        if result.returncode == 0:
            _report(result.stdout[-2000:])
            return True, None
        last = "{0} exited {1}: {2}".format(interpreter, result.returncode,
                                            (result.stderr or result.stdout)[-2000:])
    return False, last or "no python interpreter found next to sys.prefix"


def _run_inprocess_pip(target):
    """Last resort when no interpreter executable exists: run the pip that
    Painter already ships, inside this very interpreter. Only ever a --target
    install (never a self-upgrade), which is the shape that does not disturb
    the running pip's own state."""
    import runpy

    argv = sys.argv
    sys.argv = ["pip"] + _pip_arguments(target)
    try:
        runpy.run_module("pip", run_name="__main__")
    except SystemExit as exc:
        code = exc.code or 0
        if code:
            return False, "in-process pip exited {0}".format(code)
    except Exception as exc:  # pragma: no cover - pip internals
        return False, "in-process pip failed: {0}".format(exc)
    finally:
        sys.argv = argv
    return True, None


def _install():
    target = runtime_dir()
    try:
        os.makedirs(target, exist_ok=True)
    except OSError as exc:
        return False, "cannot create {0}: {1}".format(target, exc)
    ok, err = _run_external_pip(target)
    if not ok:
        _report("[RuriRipper] external pip unavailable ({0}) -- trying in-process pip.".format(err))
        ok, err = _run_inprocess_pip(target)
    if ok:
        activate()
        importlib.invalidate_caches()
    return ok, err


def ensure_async(report_fn=None):
    """Kick the install (if needed) off onto a daemon worker so a first-time
    ~10-60s pip run never freezes Painter's UI. Idempotent: a call while one is
    already running, or after one has succeeded, is a no-op."""
    global _install_thread
    if report_fn is not None:
        set_reporter(report_fn)
    with _state_lock:
        if _ready or _install_thread is not None:
            return

    def _worker():
        global _ready, _error, _install_thread
        try:
            if probe():
                with _state_lock:
                    _ready = True
                return
            _report("[RuriRipper] installing {0} into {1} ...".format(
                ", ".join(_REQUIREMENTS), runtime_dir()))
            ok, err = _install()
            ready_now = ok and probe()
            with _state_lock:
                _ready = ready_now
                _error = None if ready_now else (
                    err or "dependencies still not importable after install.")
            _report("[RuriRipper] runtime ready." if ready_now
                    else "[RuriRipper] runtime install failed: {0}".format(_error))
        finally:
            with _state_lock:
                _install_thread = None

    _install_thread = threading.Thread(
        target=_worker, name="RuriRipperRuntimeInstall", daemon=True)
    _install_thread.start()


def ensure_blocking(report_fn=None):
    """Synchronous variant, for the moment the user actually presses a button
    that needs the bridge and wants a definite yes/no."""
    global _ready, _error
    if report_fn is not None:
        set_reporter(report_fn)
    if probe():
        with _state_lock:
            _ready = True
        return True
    _report("[RuriRipper] installing {0} ...".format(", ".join(_REQUIREMENTS)))
    ok, err = _install()
    ready_now = ok and probe()
    with _state_lock:
        _ready = ready_now
        _error = None if ready_now else (err or "dependencies still not importable after install.")
    if not ready_now:
        _report("[RuriRipper] runtime install failed: {0}".format(_error))
    return ready_now
