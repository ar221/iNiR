#!/usr/bin/env python3
"""iid_niri_config — Pragmatic KDL config reader/writer for niri.

NOT a full KDL parser. Line-based approach that handles the specific
patterns found in niri's config.kdl (output blocks, input blocks,
nested sub-blocks, key-value pairs, flags).
"""

import logging
import os
import re
import shutil
import subprocess
from pathlib import Path

log = logging.getLogger(__name__)


def get_config_path() -> Path:
    """Get the path to niri config.kdl."""
    xdg_config = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    return Path(xdg_config) / "niri" / "config.kdl"


def read_config(config_path: Path | None = None) -> str:
    """Read config file content."""
    path = config_path or get_config_path()
    return path.read_text(encoding="utf-8")


def find_block(
    content: str, block_name: str, block_arg: str | None = None
) -> tuple[int, int, str] | None:
    """Find a named top-level block. Returns (start_offset, end_offset, block_content).

    block_name: e.g. 'output', 'input'
    block_arg: e.g. '"DP-2"' for output blocks (None for blocks without args).
               Must include the quotes if the config has them.
    """
    # Build pattern: block_name [block_arg] {
    if block_arg is not None:
        pattern = re.compile(
            rf'^(\s*){re.escape(block_name)}\s+{re.escape(block_arg)}\s*\{{',
            re.MULTILINE,
        )
    else:
        # Block without argument — match "input {" but not "input-something {"
        pattern = re.compile(
            rf'^(\s*){re.escape(block_name)}\s*\{{',
            re.MULTILINE,
        )

    m = pattern.search(content)
    if m is None:
        return None

    start = m.start()
    # Find matching closing brace (respecting nesting)
    brace_start = m.end() - 1  # position of the opening {
    depth = 1
    pos = brace_start + 1
    while pos < len(content) and depth > 0:
        ch = content[pos]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        elif ch == "/" and pos + 1 < len(content) and content[pos + 1] == "/":
            # Skip line comments
            nl = content.find("\n", pos)
            pos = nl if nl != -1 else len(content)
            continue
        elif ch == '"':
            # Skip quoted strings
            pos += 1
            while pos < len(content) and content[pos] != '"':
                if content[pos] == "\\":
                    pos += 1  # skip escaped char
                pos += 1
        pos += 1

    if depth != 0:
        log.warning("Unbalanced braces for block %s", block_name)
        return None

    end = pos  # one past the closing }
    # block_content is everything between the outer braces (exclusive)
    block_content = content[brace_start + 1 : end - 1]
    return (start, end, block_content)


def find_nested_block(
    block_content: str, sub_block_name: str
) -> tuple[int, int, str] | None:
    """Find a nested block within a parent block's content.

    Returns (start_offset, end_offset, sub_block_content) relative to block_content.
    """
    pattern = re.compile(
        rf'^(\s*){re.escape(sub_block_name)}\s*\{{',
        re.MULTILINE,
    )
    m = pattern.search(block_content)
    if m is None:
        return None

    start = m.start()
    brace_start = m.end() - 1
    depth = 1
    pos = brace_start + 1
    while pos < len(block_content) and depth > 0:
        ch = block_content[pos]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        elif ch == "/" and pos + 1 < len(block_content) and block_content[pos + 1] == "/":
            nl = block_content.find("\n", pos)
            pos = nl if nl != -1 else len(block_content)
            continue
        elif ch == '"':
            pos += 1
            while pos < len(block_content) and block_content[pos] != '"':
                if block_content[pos] == "\\":
                    pos += 1
                pos += 1
        pos += 1

    if depth != 0:
        return None

    end = pos
    sub_content = block_content[brace_start + 1 : end - 1]
    return (start, end, sub_content)


def get_value(block_content: str, key: str) -> str | None:
    """Get a simple value from a block.

    Handles patterns like:
        scale 1
        mode "2560x1440@144.000"
        repeat-delay 250
        accel-profile "flat"
        position x=0 y=0
    """
    # Match: key followed by value(s) on the same line
    pattern = re.compile(
        rf'^\s*{re.escape(key)}\s+(.+?)(?:\s*//.*)?$',
        re.MULTILINE,
    )
    m = pattern.search(block_content)
    if m is None:
        return None
    return m.group(1).strip()


def has_flag(block_content: str, flag: str) -> bool:
    """Check if a flag (value-less keyword) exists in a block.

    Flags are lines like: tap, numlock, variable-refresh-rate
    They appear alone on a line (possibly with leading whitespace and trailing comment).
    """
    pattern = re.compile(
        rf'^\s*{re.escape(flag)}\s*(?://.*)?$',
        re.MULTILINE,
    )
    return pattern.search(block_content) is not None


def _detect_indent(block_content: str) -> str:
    """Detect the indentation used inside a block."""
    for line in block_content.split("\n"):
        stripped = line.lstrip()
        if stripped and not stripped.startswith("//"):
            indent = line[: len(line) - len(stripped)]
            return indent
    return "    "


def set_value(
    content: str,
    block_start: int,
    block_end: int,
    block_content: str,
    key: str,
    value: str,
) -> str:
    """Set/update a value in a block. If key exists, update in-place. If not, add it.

    Returns the full modified config content.
    """
    # Try to find existing key line within block_content
    pattern = re.compile(
        rf'^(\s*){re.escape(key)}\s+.+$',
        re.MULTILINE,
    )
    m = pattern.search(block_content)

    # The block_content starts right after the opening {
    content_start = content.index(block_content, block_start)

    if m is not None:
        # Replace existing line
        indent = m.group(1)
        old_line = m.group(0)
        new_line = f"{indent}{key} {value}"
        abs_start = content_start + m.start()
        abs_end = content_start + m.end()
        return content[:abs_start] + new_line + content[abs_end:]
    else:
        # Add new line before the closing brace
        indent = _detect_indent(block_content)
        new_line = f"{indent}{key} {value}\n"
        # Insert before closing }
        closing_brace = block_end - 1
        return content[:closing_brace] + new_line + content[closing_brace:]


def set_flag(
    content: str,
    block_start: int,
    block_end: int,
    block_content: str,
    flag: str,
    enabled: bool,
) -> str:
    """Set or remove a flag (value-less keyword like 'tap', 'numlock', 'variable-refresh-rate').

    Returns the full modified config content.
    """
    pattern = re.compile(
        rf'^(\s*){re.escape(flag)}\s*(?://.*)?$',
        re.MULTILINE,
    )
    m = pattern.search(block_content)
    content_start = content.index(block_content, block_start)

    if enabled and m is not None:
        # Already present, nothing to do
        return content
    elif enabled and m is None:
        # Add the flag
        indent = _detect_indent(block_content)
        new_line = f"{indent}{flag}\n"
        closing_brace = block_end - 1
        return content[:closing_brace] + new_line + content[closing_brace:]
    elif not enabled and m is not None:
        # Remove the flag line (including newline)
        abs_start = content_start + m.start()
        abs_end = content_start + m.end()
        # Also consume the trailing newline
        if abs_end < len(content) and content[abs_end] == "\n":
            abs_end += 1
        return content[:abs_start] + content[abs_end:]
    else:
        # Not enabled and not present — nothing to do
        return content


def set_nested_value(
    content: str,
    parent_block_start: int,
    parent_block_content: str,
    sub_block_name: str,
    key: str,
    value: str,
) -> str:
    """Set a value inside a nested block (e.g. keyboard > repeat-delay).

    Creates the sub-block if it doesn't exist.
    """
    parent_content_start = content.index(parent_block_content, parent_block_start)
    nested = find_nested_block(parent_block_content, sub_block_name)

    if nested is None:
        # Create the sub-block at the end of parent block content
        indent = _detect_indent(parent_block_content)
        sub_indent = indent + "    "
        new_block = f"{indent}{sub_block_name} {{\n{sub_indent}{key} {value}\n{indent}}}\n"
        # Insert before parent closing brace
        insert_pos = parent_content_start + len(parent_block_content)
        return content[:insert_pos] + new_block + content[insert_pos:]

    sub_start, sub_end, sub_content = nested
    # Convert to absolute positions
    abs_sub_start = parent_content_start + sub_start
    abs_sub_end = parent_content_start + sub_end

    return set_value(content, abs_sub_start, abs_sub_end, sub_content, key, value)


def set_nested_flag(
    content: str,
    parent_block_start: int,
    parent_block_content: str,
    sub_block_name: str,
    flag: str,
    enabled: bool,
) -> str:
    """Set or remove a flag inside a nested block."""
    parent_content_start = content.index(parent_block_content, parent_block_start)
    nested = find_nested_block(parent_block_content, sub_block_name)

    if nested is None:
        if not enabled:
            return content  # Nothing to remove
        indent = _detect_indent(parent_block_content)
        sub_indent = indent + "    "
        new_block = f"{indent}{sub_block_name} {{\n{sub_indent}{flag}\n{indent}}}\n"
        insert_pos = parent_content_start + len(parent_block_content)
        return content[:insert_pos] + new_block + content[insert_pos:]

    sub_start, sub_end, sub_content = nested
    abs_sub_start = parent_content_start + sub_start
    abs_sub_end = parent_content_start + sub_end

    return set_flag(content, abs_sub_start, abs_sub_end, sub_content, flag, enabled)


def create_output_block(content: str, output_name: str) -> str:
    """Create a new output block at the end of existing output blocks or after hotkey-overlay."""
    indent = ""
    new_block = f'\n{indent}output "{output_name}" {{\n}}\n'

    # Try to insert after existing output blocks
    last_output = None
    for m in re.finditer(r'^output\s+"[^"]+"\s*\{', content, re.MULTILINE):
        last_output = m

    if last_output:
        # Find end of this output block
        result = find_block(content, "output", f'"{output_name}"')
        if result:
            return content  # Already exists
        # Find end of the last output block
        brace_pos = last_output.end() - 1
        depth = 1
        pos = brace_pos + 1
        while pos < len(content) and depth > 0:
            if content[pos] == "{":
                depth += 1
            elif content[pos] == "}":
                depth -= 1
            pos += 1
        return content[:pos] + new_block + content[pos:]
    else:
        # Insert after hotkey-overlay block or at top
        hk = find_block(content, "hotkey-overlay")
        if hk:
            _, end, _ = hk
            return content[:end] + new_block + content[end:]
        # Fallback: prepend
        return new_block + content


def write_config(config_path: Path | None, content: str) -> None:
    """Write config, creating backup first (.bak)."""
    path = config_path or get_config_path()
    if path.exists():
        bak = path.with_suffix(".kdl.bak")
        shutil.copy2(path, bak)
        log.info("Backup: %s", bak)
    path.write_text(content, encoding="utf-8")
    log.info("Written: %s", path)


async def reload_niri_config() -> bool:
    """Trigger a smooth screen transition and config reload.

    Returns True on success.
    """
    import asyncio

    try:
        proc = await asyncio.create_subprocess_exec(
            "niri", "msg", "action", "do-screen-transition",
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.PIPE,
        )
        _, stderr = await proc.communicate()
        if proc.returncode != 0:
            log.warning("do-screen-transition failed: %s", stderr.decode().strip())
    except FileNotFoundError:
        log.debug("niri not found, skipping screen transition")

    # Niri auto-reloads config on file change (inotify), so writing
    # the config file is sufficient. No explicit reload command needed.
    return True
