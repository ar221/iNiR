#!/usr/bin/env python3
"""iid_keybinds — Keybind management module for iid.

Provides methods to list, add, modify, and remove keybinds in niri's
config.kdl.  Uses the parse_niri_keybinds.py script for reading and
iid_niri_config utilities for writing.
"""

import json
import logging
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

from iid_niri_config import (
    find_block,
    read_config,
    write_config,
)

log = logging.getLogger(__name__)

# Path to the keybind parser script (lives one level up from daemon/)
_PARSER_SCRIPT = Path(__file__).parent.parent / "parse_niri_keybinds.py"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _build_key_combo(mods: list[str], key: str) -> str:
    """Build niri key combo string from mods and key."""
    parts = []
    for m in mods:
        if m == "Super":
            parts.append("Mod")
        else:
            parts.append(m)
    parts.append(key)
    return "+".join(parts)


def _build_options_string(options: dict) -> str:
    """Build options string from options dict."""
    parts: list[str] = []
    if options.get("repeat") is False:
        parts.append("repeat=false")
    if options.get("allowWhenLocked"):
        parts.append("allow-when-locked=true")
    if "cooldownMs" in options:
        parts.append(f'cooldown-ms={options["cooldownMs"]}')
    return " ".join(parts)


def _build_keybind_line(
    mods: list[str],
    key: str,
    action: str,
    options: dict | None = None,
    comment: str | None = None,
) -> str:
    """Build a complete keybind line for config.kdl."""
    combo = _build_key_combo(mods, key)
    opts = _build_options_string(options or {})
    title = f'hotkey-overlay-title="{comment}" ' if comment else ""
    opts_str = f"{opts} " if opts else ""
    return f"    {combo} {opts_str}{title}{{ {action}; }}"


def _find_keybind_lines(
    binds_content: str, key_combo: str
) -> tuple[int, int] | None:
    """Find a keybind's line range within the binds block content.

    Returns (start_offset, end_offset) relative to binds_content,
    covering the full keybind including multi-line actions.
    Returns None if not found.
    """
    # Escape + for regex
    combo_pattern = re.escape(key_combo)
    # Match: optional whitespace, key combo, then options/brace
    pattern = re.compile(
        rf"^([ \t]*){combo_pattern}\s",
        re.MULTILINE,
    )

    m = pattern.search(binds_content)
    if m is None:
        return None

    line_start = m.start()

    # Check if single-line (has closing } on same line)
    line_end_pos = binds_content.find("\n", line_start)
    if line_end_pos == -1:
        line_end_pos = len(binds_content)

    line_text = binds_content[line_start:line_end_pos]

    if "}" in line_text:
        # Single-line keybind — include the newline
        end = line_end_pos
        if end < len(binds_content) and binds_content[end] == "\n":
            end += 1
        return (line_start, end)

    # Multi-line keybind — find closing brace
    depth = 0
    pos = line_start
    while pos < len(binds_content):
        ch = binds_content[pos]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                # Include the } and trailing newline
                end = pos + 1
                if end < len(binds_content) and binds_content[end] == "\n":
                    end += 1
                return (line_start, end)
        pos += 1

    # Malformed — return to end of first line
    end = line_end_pos
    if end < len(binds_content) and binds_content[end] == "\n":
        end += 1
    return (line_start, end)


# ---------------------------------------------------------------------------
# Method handlers
# ---------------------------------------------------------------------------

async def keybinds_list(params: dict, server: Any) -> Any:
    """Return parsed keybinds by running the parser script."""
    try:
        proc = subprocess.run(
            [sys.executable, str(_PARSER_SCRIPT)],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if proc.returncode != 0:
            raise RuntimeError(f"Parser failed: {proc.stderr.strip()}")
        return json.loads(proc.stdout)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Parser returned invalid JSON: {e}") from e
    except subprocess.TimeoutExpired:
        raise RuntimeError("Parser timed out")


async def keybinds_set(params: dict, server: Any) -> Any:
    """Modify an existing keybind.

    Params:
        originalKey: full original key combo (e.g. "Mod+Shift+E")
        mods: list of modifier strings
        key: new key string
        action: new action string
        options: options dict
    """
    original_key = params.get("originalKey")
    mods = params.get("mods", [])
    key = params.get("key", "")
    action = params.get("action", "")
    options = params.get("options", {})

    if not original_key:
        raise ValueError("originalKey is required")
    if not key:
        raise ValueError("key is required")
    if not action:
        raise ValueError("action is required")

    content = read_config()
    block = find_block(content, "binds")
    if block is None:
        raise RuntimeError("No binds block found in config.kdl")

    block_start, block_end, binds_content = block
    # binds_content is between the { and } of the binds block
    content_offset = content.index(binds_content, block_start)

    span = _find_keybind_lines(binds_content, original_key)
    if span is None:
        raise ValueError(f"Keybind not found: {original_key}")

    kb_start, kb_end = span

    # Preserve any existing comment from the old line
    old_line = binds_content[kb_start:kb_end]
    title_match = re.search(r'hotkey-overlay-title="([^"]+)"', old_line)
    comment = title_match.group(1) if title_match else None

    new_line = _build_keybind_line(mods, key, action, options, comment) + "\n"

    abs_start = content_offset + kb_start
    abs_end = content_offset + kb_end
    new_content = content[:abs_start] + new_line + content[abs_end:]

    write_config(None, new_content)
    server.broadcast({"event": "keybinds.changed"})
    log.info("Updated keybind: %s -> %s", original_key, _build_key_combo(mods, key))
    return {"ok": True}


async def keybinds_add(params: dict, server: Any) -> Any:
    """Add a new keybind to the binds block.

    Params:
        mods: list of modifier strings
        key: key string
        action: action string
        options: options dict
        comment: optional overlay title
    """
    mods = params.get("mods", [])
    key = params.get("key", "")
    action = params.get("action", "")
    options = params.get("options", {})
    comment = params.get("comment", "") or None

    if not key:
        raise ValueError("key is required")
    if not action:
        raise ValueError("action is required")

    content = read_config()
    block = find_block(content, "binds")
    if block is None:
        raise RuntimeError("No binds block found in config.kdl")

    block_start, block_end, binds_content = block

    new_line = _build_keybind_line(mods, key, action, options, comment) + "\n"

    # Insert before the closing } of the binds block
    insert_pos = block_end - 1
    new_content = content[:insert_pos] + new_line + content[insert_pos:]

    write_config(None, new_content)
    server.broadcast({"event": "keybinds.changed"})
    log.info("Added keybind: %s", _build_key_combo(mods, key))
    return {"ok": True}


async def keybinds_remove(params: dict, server: Any) -> Any:
    """Remove a keybind by its full key combo string.

    Params:
        keyCombo: full key combo (e.g. "Mod+Shift+E")
    """
    key_combo = params.get("keyCombo")
    if not key_combo:
        raise ValueError("keyCombo is required")

    content = read_config()
    block = find_block(content, "binds")
    if block is None:
        raise RuntimeError("No binds block found in config.kdl")

    block_start, block_end, binds_content = block
    content_offset = content.index(binds_content, block_start)

    span = _find_keybind_lines(binds_content, key_combo)
    if span is None:
        raise ValueError(f"Keybind not found: {key_combo}")

    kb_start, kb_end = span
    abs_start = content_offset + kb_start
    abs_end = content_offset + kb_end

    new_content = content[:abs_start] + content[abs_end:]

    write_config(None, new_content)
    server.broadcast({"event": "keybinds.changed"})
    log.info("Removed keybind: %s", key_combo)
    return {"ok": True}


# ---------------------------------------------------------------------------
# Module registration
# ---------------------------------------------------------------------------

def register(registry: dict) -> None:
    registry["keybinds.list"] = keybinds_list
    registry["keybinds.set"] = keybinds_set
    registry["keybinds.add"] = keybinds_add
    registry["keybinds.remove"] = keybinds_remove
    log.info("Keybinds module registered (%d methods)", 4)
