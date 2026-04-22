#!/usr/bin/env python3
"""iid_display — Display/output management module for iid."""

import asyncio
import json
import logging
from typing import Any

from iid_niri_config import (
    create_output_block,
    find_block,
    get_config_path,
    get_value,
    has_flag,
    read_config,
    reload_niri_config,
    set_flag,
    set_value,
    write_config,
)

log = logging.getLogger(__name__)


async def _niri_outputs() -> dict[str, Any]:
    """Get current outputs from niri msg -j outputs."""
    proc = await asyncio.create_subprocess_exec(
        "niri", "msg", "-j", "outputs",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await proc.communicate()
    if proc.returncode != 0:
        raise RuntimeError(f"niri msg outputs failed: {stderr.decode().strip()}")
    return json.loads(stdout.decode())


def _ensure_output_block(content: str, output: str) -> tuple[str, int, int, str]:
    """Find or create the output block. Returns (content, start, end, block_content)."""
    arg = f'"{output}"'
    result = find_block(content, "output", arg)
    if result is None:
        content = create_output_block(content, output)
        result = find_block(content, "output", arg)
        if result is None:
            raise RuntimeError(f"Failed to create output block for {output}")
    start, end, block_content = result
    return content, start, end, block_content


async def _apply_config(content: str, output: str, server: Any) -> dict:
    """Write config, reload niri, broadcast event, return updated output info."""
    write_config(None, content)
    await reload_niri_config()
    # Small delay for niri to pick up the change
    await asyncio.sleep(0.3)
    server.broadcast({"event": "display.changed", "data": {"output": output}})
    try:
        outputs = await _niri_outputs()
        return outputs.get(output, {"name": output, "status": "updated"})
    except Exception as e:
        log.warning("Could not fetch updated output info: %s", e)
        return {"name": output, "status": "updated"}


# ── Method handlers ──────────────────────────────────────────────────


async def display_list(params: dict, server: Any) -> dict:
    """List all outputs from niri."""
    return await _niri_outputs()


async def display_set_mode(params: dict, server: Any) -> dict:
    """Set output mode (resolution + refresh rate)."""
    output = params.get("output")
    if not output:
        raise ValueError("Missing 'output' parameter")

    width = params.get("width")
    height = params.get("height")
    refresh = params.get("refresh")  # millihertz, e.g. 144000

    if not (width and height):
        raise ValueError("Missing 'width' and/or 'height'")

    # Build mode string: "2560x1440@144.000" or "2560x1440"
    mode = f"{width}x{height}"
    if refresh is not None:
        hz = refresh / 1000.0
        mode += f"@{hz:.3f}"
    mode_value = f'"{mode}"'

    config_path = get_config_path()
    content = read_config(config_path)
    content, start, end, block = _ensure_output_block(content, output)
    content = set_value(content, start, end, block, "mode", mode_value)
    return await _apply_config(content, output, server)


async def display_set_scale(params: dict, server: Any) -> dict:
    """Set output scale."""
    output = params.get("output")
    if not output:
        raise ValueError("Missing 'output' parameter")
    scale = params.get("scale")
    if scale is None:
        raise ValueError("Missing 'scale' parameter")

    content = read_config()
    content, start, end, block = _ensure_output_block(content, output)
    # Scale can be int or float — niri accepts both
    scale_str = str(int(scale)) if float(scale) == int(float(scale)) else str(scale)
    content = set_value(content, start, end, block, "scale", scale_str)
    return await _apply_config(content, output, server)


async def display_set_transform(params: dict, server: Any) -> dict:
    """Set output transform (rotation)."""
    output = params.get("output")
    if not output:
        raise ValueError("Missing 'output' parameter")
    transform = params.get("transform")
    if transform is None:
        raise ValueError("Missing 'transform' parameter")

    valid = {"normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"}
    if str(transform) not in valid:
        raise ValueError(f"Invalid transform '{transform}'. Valid: {', '.join(sorted(valid))}")

    content = read_config()
    content, start, end, block = _ensure_output_block(content, output)
    content = set_value(content, start, end, block, "transform", f'"{transform}"')
    return await _apply_config(content, output, server)


async def display_set_vrr(params: dict, server: Any) -> dict:
    """Toggle variable refresh rate."""
    output = params.get("output")
    if not output:
        raise ValueError("Missing 'output' parameter")
    enabled = params.get("enabled")
    if enabled is None:
        raise ValueError("Missing 'enabled' parameter")

    content = read_config()
    content, start, end, block = _ensure_output_block(content, output)
    content = set_flag(content, start, end, block, "variable-refresh-rate", bool(enabled))
    return await _apply_config(content, output, server)


async def display_set_position(params: dict, server: Any) -> dict:
    """Set output position."""
    output = params.get("output")
    if not output:
        raise ValueError("Missing 'output' parameter")
    x = params.get("x")
    y = params.get("y")
    if x is None or y is None:
        raise ValueError("Missing 'x' and/or 'y' parameter")

    content = read_config()
    content, start, end, block = _ensure_output_block(content, output)
    content = set_value(content, start, end, block, "position", f"x={x} y={y}")
    return await _apply_config(content, output, server)


# ── Module registration ──────────────────────────────────────────────


def register(registry: dict[str, Any]) -> None:
    """Register display methods with the server."""
    registry["display.list"] = display_list
    registry["display.set_mode"] = display_set_mode
    registry["display.set_scale"] = display_set_scale
    registry["display.set_transform"] = display_set_transform
    registry["display.set_vrr"] = display_set_vrr
    registry["display.set_position"] = display_set_position
    log.info("Display module registered (%d methods)", 6)
