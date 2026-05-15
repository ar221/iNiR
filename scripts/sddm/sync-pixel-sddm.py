#!/usr/bin/env python3
"""Sync ii-pixel SDDM theme colors with current Material You palette.

Reads generated colors from iNiR's colors.json and updates
the ii-pixel theme.conf with matching colors.
Reads wallpaper path from iNiR state and updates background image.

Note: install-pixel-sddm.sh transfers ownership of the theme directory to
the current user at install time, so no sudo/polkit is required here.
"""

import json
import os
import shutil
import subprocess
import sys

THEME_NAME = "ii-pixel"
THEME_DIR = f"/usr/share/sddm/themes/{THEME_NAME}"
THEME_CONF = os.path.join(THEME_DIR, "theme.conf")
ASSETS_DIR = os.path.join(THEME_DIR, "assets")

# Canonical template structure — restored when theme.conf is corrupted.
# Only the structural/metadata lines; color keys are appended by update_theme_conf().
THEME_CONF_TEMPLATE = """\
[SddmTheme]
Name=ii-pixel
Description=iNiR SDDM login screen — Material You dynamic colors
Type=sddm-theme
Author=iNiR project
Version=1.0
Website=https://github.com/snowarch/iNiR
Screenshot=
MainScript=Main.qml
ConfigFile=theme.conf

[General]
background=assets/background.png
defaultBackground=assets/background.png
blurRadius=50

# iNiR Material You colors — updated automatically by sync-pixel-sddm.py on wallpaper change"""

# When invoked via `sudo`, resolve paths against the real user's home,
# not root's home — SUDO_USER contains the original username.
_sudo_user = os.environ.get("SUDO_USER", "")
if _sudo_user:
    import pwd

    _real_home = pwd.getpwnam(_sudo_user).pw_dir
else:
    _real_home = os.path.expanduser("~")

STATE_DIR = os.path.join(
    os.environ.get("XDG_STATE_HOME") or os.path.join(_real_home, ".local", "state"),
    "quickshell",
)
COLORS_JSON = os.path.join(STATE_DIR, "user", "generated", "colors.json")

CONFIG_JSON = os.path.join(
    os.environ.get("XDG_CONFIG_HOME") or os.path.join(_real_home, ".config"),
    "inir",
    "config.json",
)


def read_colors():
    """Read Material You colors from iNiR's generated colors.json.

    Handles both output formats:
    - Flat:   { "primary": "#...", "on_primary": "#...", ... }   (current contract)
    - Nested: { "colors": { "dark": { "primary": "#...", ... } } }
    """
    if not os.path.isfile(COLORS_JSON):
        print(f"[sddm-pixel] colors.json not found: {COLORS_JSON}")
        return None
    with open(COLORS_JSON) as f:
        data = json.load(f)

    # Try nested format first, then fall back to flat
    dark = data.get("colors", {}).get("dark", {})
    if not dark:
        # Flat format: keys are directly on the root object
        if "primary" in data or "on_surface" in data:
            dark = data
        else:
            print("[sddm-pixel] No dark colors in colors.json")
            return None

    return {
        # Material schema (back-compat) — preserved for any DM swap that still
        # reads the original 8 keys.
        "primaryColor": dark.get("primary", "#cba6f7"),
        "onPrimaryColor": dark.get("on_primary", "#1e1e2e"),
        "surfaceColor": dark.get("surface", "#1e1e2e"),
        "surfaceContainerColor": dark.get("surface_container", "#181825"),
        "onSurfaceColor": dark.get("on_surface", "#cdd6f4"),
        "onSurfaceVariantColor": dark.get("on_surface_variant", "#9399b2"),
        "backgroundColor": dark.get("background", "#1e1e2e"),
        "errorColor": dark.get("error", "#f38ba8"),
        # Courier extended schema (wedge C) — 9 additive color keys consumed
        # by Main.qml's Courier dispatch-board composition. When globalStyle is
        # Material, the same source keys read Material values — Courier QML
        # renders structurally but in Material colors (clean fallback).
        "colCanvas": dark.get("background", "#0E0B06"),
        "colSurfaceHover": dark.get("surface_container", "#21170A"),
        "colSurfaceActive": dark.get("surface_container_high", "#2A1C08"),
        "colBorder": dark.get("primary", "#C98A2E"),
        "colBorderDim": dark.get("outline", "#5E7A48"),
        "colText": dark.get("on_surface", "#D7B56D"),
        "colTextStrong": dark.get("on_primary_container", "#E8B54A"),
        "colTextDim": dark.get("on_surface_variant", "#8A9A72"),
        "colDivider": dark.get("secondary", "#74A39A"),
    }


def read_hostname_and_last_session():
    """Return (hostname, last_session_str) for the Courier session strip.

    Hostname: socket.gethostname() — always available.
    Last session: parsed from `last -F -n 2 <user>` line 2 (the most recent
    completed session — line 1 is typically still-logged-in). Falls back to
    "—" on any parse failure. No utmp library dependency.

    Brief §5.3 pseudocode had off-by-one slice indices (parts[4:9]); verified
    against live `last -F` output, the date tokens land at parts[3:8] when
    SOURCE is non-empty (the typical case). Corrected here.
    """
    import socket

    try:
        hostname = socket.gethostname()
    except Exception:
        hostname = "host"

    last_session = "—"
    try:
        username = _sudo_user or os.environ.get("USER", "")
        if not username:
            return hostname, last_session
        proc = subprocess.run(
            ["last", "-F", "-n", "2", username],
            capture_output=True,
            text=True,
            timeout=5,
        )
        # Filter to lines mentioning the user (skips "wtmp begins ..." footer).
        user_lines = [
            l for l in proc.stdout.splitlines() if l.strip() and username in l.split()[:1]
        ]
        if len(user_lines) >= 2:
            from datetime import datetime

            parts = user_lines[1].split()
            # Format: "ayaz  pts/4  tmux(...)  Fri May 15 15:07:29 2026 - ..."
            # tokens: [0]=user [1]=tty [2]=source [3..8]=date5 [8]=- [9..]=end+dur
            # Slice [3:8] = ["Fri","May","15","15:07:29","2026"]
            if len(parts) >= 8:
                try:
                    dt = datetime.strptime(
                        " ".join(parts[3:8]), "%a %b %d %H:%M:%S %Y"
                    )
                    last_session = dt.strftime("%Y-%m-%d %H:%M")
                except ValueError:
                    pass
    except Exception:
        pass

    return hostname, last_session


def write_receipts():
    """Stage last 5 session events as JSON for SDDM Main.qml receipt rows.

    Output: ``$ASSETS_DIR/receipts.json`` — a JSON array of dicts with keys
    ``time``, ``event``, ``actor``, ``verb`` (column order locked by brief
    §3.2 receipts strip + §6.2 vocabulary-parity divergence note).

    Contract for the QML side: Main.qml loads this with XMLHttpRequest at
    Component.onCompleted, populates `root.receipts` (array of objects).
    If the file is missing, malformed, or empty, the QML side renders an
    empty strip — no hardcoded fallback.

    Data source: `last -n 10 <user>` (non-`-F` short form). Filters out
    the trailing "wtmp begins ..." line and any line not led by the user.
    Soft-fails on any subprocess / parse / IO error.

    Time parsing intentionally avoids ``datetime.strptime`` on year-less
    short-form date tokens — that path emits a DeprecationWarning under
    Python 3.13+ and is slated to become an error in 3.15. The HH:MM
    token is at a stable index in the short-form output, so a direct
    structural read is both deprecation-safe and cheaper.
    """
    import re

    _hhmm_re = re.compile(r"^\d{2}:\d{2}$")

    receipts = []
    try:
        username = _sudo_user or os.environ.get("USER", "")
        if not username:
            return _write_receipts_file(receipts)
        proc = subprocess.run(
            ["last", "-n", "10", username],
            capture_output=True,
            text=True,
            timeout=5,
        )
        for line in proc.stdout.splitlines():
            parts = line.split()
            # Guard: skip "wtmp begins ..." (parts[0] = "wtmp") and short rows.
            if len(parts) < 7 or parts[0] != username:
                continue
            tty_or_src = parts[1]
            # Short-form date tokens: parts[3..7] = ["Fri","May","15","15:07"]
            # parts[6] is the HH:MM token — pick it directly, no strptime.
            time_str = parts[6] if _hhmm_re.match(parts[6]) else "—"
            receipts.append(
                {
                    "time": time_str,
                    "event": "session." + (
                        tty_or_src if tty_or_src.startswith("tty") else "remote"
                    ),
                    "actor": username,
                    "verb": "login",
                }
            )
            if len(receipts) >= 5:
                break
    except Exception as e:
        print(f"[sddm-pixel] receipts parse failed: {e}")

    return _write_receipts_file(receipts)


def _write_receipts_file(receipts):
    """Write receipts list to assets/receipts.json. Returns True on success."""
    if not os.path.isdir(ASSETS_DIR):
        try:
            os.makedirs(ASSETS_DIR, exist_ok=True)
        except Exception as e:
            print(f"[sddm-pixel] receipts dir create failed: {e}")
            return False
    out_path = os.path.join(ASSETS_DIR, "receipts.json")
    try:
        with open(out_path, "w") as f:
            json.dump(receipts, f)
        try:
            os.chmod(out_path, 0o644)
        except Exception:
            pass
        print(f"[sddm-pixel] Receipts staged: {len(receipts)} rows")
        return True
    except PermissionError:
        print(f"[sddm-pixel] Permission denied writing {out_path}.")
        print("[sddm-pixel] Re-run install-pixel-sddm.sh to fix ownership.")
        return False
    except Exception as e:
        print(f"[sddm-pixel] Receipts write failed: {e}")
        return False


def read_wallpaper():
    """Read current wallpaper path from iNiR config.json."""
    if not os.path.isfile(CONFIG_JSON):
        return None
    try:
        with open(CONFIG_JSON) as f:
            config = json.load(f)

        panel_family = config.get("panelFamily", "ii")
        background = config.get("background", {}) or {}
        waffles = config.get("waffles", {}) or {}
        waffles_background = waffles.get("background", {}) or {}

        main_path = background.get("wallpaperPath", "")
        if panel_family == "waffle":
            use_main = waffles_background.get("useMainWallpaper", True)
            waffle_path = waffles_background.get("wallpaperPath", "")
            path = main_path if use_main else (waffle_path or main_path)
        else:
            path = main_path

        if path and path.startswith("file://"):
            path = path[7:]
        return path if path and os.path.isfile(path) else None
    except Exception:
        return None


def read_material_shape_chars():
    """Mirror lockscreen password behavior flag into SDDM theme config."""
    if not os.path.isfile(CONFIG_JSON):
        return "false"
    try:
        with open(CONFIG_JSON) as f:
            config = json.load(f)
        val = (config.get("lock", {}) or {}).get("materialShapeChars", False)
        return "true" if bool(val) else "false"
    except Exception:
        return "false"


def update_theme_conf(colors):
    """Update ii-pixel theme.conf [General] section with new colors.

    Self-heals corrupted files: if the [General] section or
    ``background=`` key are missing, the canonical template structure
    is restored before applying color values.
    """
    if not os.path.isfile(THEME_CONF):
        print(f"[sddm-pixel] theme.conf not found: {THEME_CONF}")
        return False

    with open(THEME_CONF) as f:
        lines = f.read().split("\n")

    # Detect corruption: [General] or the background= directive missing.
    has_general = any("[General]" in l for l in lines)
    has_background = any(l.strip().startswith("background=") for l in lines)
    if not has_general or not has_background:
        print(
            "[sddm-pixel] theme.conf missing structural elements — restoring template"
        )
        lines = THEME_CONF_TEMPLATE.split("\n")

    remaining = dict(colors)
    remaining["materialShapeChars"] = read_material_shape_chars()
    new_lines = []
    for line in lines:
        stripped = line.strip()
        matched = False
        for key, value in remaining.items():
            if stripped.startswith(f"{key}="):
                new_lines.append(f"{key}={value}")
                remaining.pop(key)
                matched = True
                break
        if not matched:
            new_lines.append(line)
    for key, value in remaining.items():
        new_lines.append(f"{key}={value}")
    content = "\n".join(new_lines)

    try:
        with open(THEME_CONF, "w") as f:
            f.write(content)
        return True
    except PermissionError:
        print(f"[sddm-pixel] Permission denied writing {THEME_CONF}.")
        print(f"[sddm-pixel] Re-run install-pixel-sddm.sh to fix ownership.")
        return False
    except OSError as e:
        print(f"[sddm-pixel] Error writing theme.conf: {e}")
        return False


def update_avatar():
    """Copy user avatar to a world-readable theme asset for SDDM.

    This avoids permission issues when reading ~/.face from the sddm user.
    Source order matches lockscreen intent:
      1) ~/.face
      2) ~/.face.icon
      3) /var/lib/AccountsService/icons/<user>
    """
    if not os.path.isdir(ASSETS_DIR):
        try:
            os.makedirs(ASSETS_DIR, exist_ok=True)
        except Exception:
            return False

    username = _sudo_user or os.environ.get("USER", "")
    candidates = [
        os.path.join(_real_home, ".face"),
        os.path.join(_real_home, ".face.icon"),
    ]
    if username:
        candidates.append(f"/var/lib/AccountsService/icons/{username}")

    src = next((p for p in candidates if p and os.path.isfile(p)), None)
    if not src:
        return False

    dst = os.path.join(ASSETS_DIR, "user-face.png")
    try:
        shutil.copy2(src, dst)
        os.chmod(dst, 0o644)
        print(f"[sddm-pixel] Avatar updated: {os.path.basename(src)}")
        return True
    except Exception as e:
        print(f"[sddm-pixel] Avatar sync failed: {e}")
        return False


VIDEO_EXTENSIONS = {".mp4", ".mkv", ".webm", ".avi", ".mov", ".gif", ".webp"}


def extract_video_frame(video_path, dest_png):
    """Use ffmpeg to extract the first frame of a video as PNG. Returns tmp path on success, None on failure."""
    if not shutil.which("ffmpeg"):
        print("[sddm-pixel] ffmpeg not found — cannot extract video frame")
        return None
    tmp = os.path.join("/tmp", "sddm-pixel-frame.tmp.png")
    try:
        proc = subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-i",
                video_path,
                "-vframes",
                "1",
                "-update",
                "1",
                "-f",
                "image2",
                tmp,
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=15,
        )
        if proc.returncode == 0 and os.path.isfile(tmp):
            return tmp
        print(
            f"[sddm-pixel] ffmpeg frame extraction failed for {os.path.basename(video_path)}"
        )
        return None
    except Exception as e:
        print(f"[sddm-pixel] ffmpeg error: {e}")
        return None


def update_background(wallpaper_path):
    """Copy current wallpaper (or its first video frame) to theme assets/background.png."""
    if not wallpaper_path:
        return False
    if not os.path.isdir(ASSETS_DIR):
        try:
            os.makedirs(ASSETS_DIR, exist_ok=True)
        except PermissionError:
            print(f"[sddm-pixel] Permission denied creating {ASSETS_DIR}.")
            print(f"[sddm-pixel] Re-run install-pixel-sddm.sh to fix ownership.")
            return False

    bg_dest = os.path.join(ASSETS_DIR, "background.png")
    ext = os.path.splitext(wallpaper_path)[1].lower()
    src = wallpaper_path

    if ext in VIDEO_EXTENSIONS:
        tmp_frame = extract_video_frame(wallpaper_path, bg_dest)
        if tmp_frame is None:
            print("[sddm-pixel] Keeping existing background (video, no ffmpeg)")
            return False
        src = tmp_frame

    try:
        shutil.copy2(src, bg_dest)
        if ext in VIDEO_EXTENSIONS and os.path.isfile(src):
            os.unlink(src)
        print(f"[sddm-pixel] Background updated: {os.path.basename(wallpaper_path)}")
        return True
    except PermissionError:
        print(f"[sddm-pixel] Permission denied writing to {ASSETS_DIR}.")
        print(f"[sddm-pixel] Re-run install-pixel-sddm.sh to fix ownership.")
        if ext in VIDEO_EXTENSIONS and os.path.isfile(src):
            os.unlink(src)
        return False
    except Exception as e:
        print(f"[sddm-pixel] Error updating background: {e}")
        if ext in VIDEO_EXTENSIONS and os.path.isfile(src):
            os.unlink(src)
        return False


def main():
    if not os.path.isdir(THEME_DIR):
        print(
            f"[sddm-pixel] Theme not installed at {THEME_DIR}. Run install-pixel-sddm.sh first."
        )
        return

    colors = read_colors()
    if colors:
        # Wedge C: enrich colors dict with Courier session-strip metadata
        # before update_theme_conf fans out the keys.
        hostname, last_session = read_hostname_and_last_session()
        colors["hostname"] = hostname
        colors["lastSession"] = last_session
        if update_theme_conf(colors):
            print(f"[sddm-pixel] Colors synced (primary: {colors['primaryColor']})")
        else:
            print("[sddm-pixel] Color sync failed")
    else:
        print("[sddm-pixel] No colors available, skipping color sync")

    wallpaper = read_wallpaper()
    if wallpaper:
        update_background(wallpaper)
    else:
        print("[sddm-pixel] No wallpaper path found, keeping existing background")

    update_avatar()

    # Wedge C: stage real session events for the Courier receipts strip.
    # Runs unconditionally — the assets dir is guaranteed to exist after
    # install-pixel-sddm.sh, and receipts.json is a no-op if `last` is empty.
    write_receipts()


if __name__ == "__main__":
    main()
