#!/usr/bin/env python3
"""iid_input — Input device settings module for iid."""

import logging
from typing import Any

from iid_niri_config import (
    find_block,
    find_nested_block,
    get_value,
    has_flag,
    read_config,
    reload_niri_config,
    set_nested_flag,
    set_nested_value,
    set_flag,
    set_value,
    write_config,
)

log = logging.getLogger(__name__)


def _parse_input_settings(content: str) -> dict:
    """Parse the input block from config into a structured dict."""
    result = {
        "keyboard": {
            "layout": None,
            "repeat_delay": None,
            "repeat_rate": None,
            "numlock": False,
        },
        "touchpad": {
            "tap": False,
            "natural_scroll": False,
            "dwt": False,
            "speed": None,
            "tap_button_map": None,
        },
        "mouse": {
            "accel_profile": None,
            "speed": None,
        },
    }

    input_block = find_block(content, "input")
    if input_block is None:
        return result

    _, _, block_content = input_block

    # ── Keyboard ──
    kb = find_nested_block(block_content, "keyboard")
    if kb:
        _, _, kb_content = kb
        # Layout lives inside xkb { layout "us" }
        xkb = find_nested_block(kb_content, "xkb")
        if xkb:
            _, _, xkb_content = xkb
            layout = get_value(xkb_content, "layout")
            if layout:
                result["keyboard"]["layout"] = layout.strip('"')

        delay = get_value(kb_content, "repeat-delay")
        if delay:
            result["keyboard"]["repeat_delay"] = int(delay)
        rate = get_value(kb_content, "repeat-rate")
        if rate:
            result["keyboard"]["repeat_rate"] = int(rate)
        result["keyboard"]["numlock"] = has_flag(kb_content, "numlock")

    # ── Touchpad ──
    tp = find_nested_block(block_content, "touchpad")
    if tp:
        _, _, tp_content = tp
        result["touchpad"]["tap"] = has_flag(tp_content, "tap")
        result["touchpad"]["natural_scroll"] = has_flag(tp_content, "natural-scroll")
        result["touchpad"]["dwt"] = has_flag(tp_content, "dwt")
        speed = get_value(tp_content, "accel-speed")
        if speed:
            result["touchpad"]["speed"] = float(speed)
        tbm = get_value(tp_content, "tap-button-map")
        if tbm:
            result["touchpad"]["tap_button_map"] = tbm.strip('"')

    # ── Mouse ──
    mouse = find_nested_block(block_content, "mouse")
    if mouse:
        _, _, mouse_content = mouse
        profile = get_value(mouse_content, "accel-profile")
        if profile:
            result["mouse"]["accel_profile"] = profile.strip('"')
        speed = get_value(mouse_content, "accel-speed")
        if speed:
            result["mouse"]["speed"] = float(speed)

    return result


# ── Method handlers ──────────────────────────────────────────────────


async def input_get(params: dict, server: Any) -> dict:
    """Get current input settings parsed from config.kdl."""
    content = read_config()
    return _parse_input_settings(content)


async def input_set_keyboard(params: dict, server: Any) -> dict:
    """Set keyboard settings. Only updates provided fields."""
    content = read_config()

    input_result = find_block(content, "input")
    if input_result is None:
        raise RuntimeError("No 'input' block found in niri config")

    inp_start, inp_end, inp_content = input_result

    # Layout goes inside keyboard > xkb
    if "layout" in params:
        # First ensure keyboard block exists, then xkb inside it
        kb = find_nested_block(inp_content, "keyboard")
        if kb is None:
            # set_nested_value will create it
            content = set_nested_value(
                content, inp_start, inp_content, "keyboard", "placeholder", "0"
            )
            # Re-read after modification
            inp_result2 = find_block(content, "input")
            if inp_result2:
                inp_start, inp_end, inp_content = inp_result2

        # Now handle xkb inside keyboard
        kb = find_nested_block(inp_content, "keyboard")
        if kb:
            kb_start_rel, kb_end_rel, kb_content = kb
            inp_content_start = content.index(inp_content, inp_start)
            abs_kb_start = inp_content_start + kb_start_rel
            abs_kb_end = inp_content_start + kb_end_rel

            xkb = find_nested_block(kb_content, "xkb")
            if xkb:
                xkb_start_rel, xkb_end_rel, xkb_content = xkb
                abs_xkb_start = abs_kb_start + content[abs_kb_start:].index(kb_content) + xkb_start_rel
                abs_xkb_end = abs_xkb_start + (xkb_end_rel - xkb_start_rel)
                content = set_value(
                    content, abs_xkb_start, abs_xkb_end, xkb_content,
                    "layout", f'"{params["layout"]}"'
                )
            else:
                content = set_nested_value(
                    content, abs_kb_start, kb_content,
                    "xkb", "layout", f'"{params["layout"]}"'
                )
            # Re-read
            inp_result2 = find_block(content, "input")
            if inp_result2:
                inp_start, inp_end, inp_content = inp_result2

    if "repeat_delay" in params:
        content = set_nested_value(
            content, inp_start, inp_content,
            "keyboard", "repeat-delay", str(params["repeat_delay"])
        )
        inp_result2 = find_block(content, "input")
        if inp_result2:
            inp_start, inp_end, inp_content = inp_result2

    if "repeat_rate" in params:
        content = set_nested_value(
            content, inp_start, inp_content,
            "keyboard", "repeat-rate", str(params["repeat_rate"])
        )
        inp_result2 = find_block(content, "input")
        if inp_result2:
            inp_start, inp_end, inp_content = inp_result2

    if "numlock" in params:
        content = set_nested_flag(
            content, inp_start, inp_content,
            "keyboard", "numlock", bool(params["numlock"])
        )
        inp_result2 = find_block(content, "input")
        if inp_result2:
            inp_start, inp_end, inp_content = inp_result2

    write_config(None, content)
    await reload_niri_config()
    server.broadcast({"event": "input.changed", "data": {"device": "keyboard"}})
    return _parse_input_settings(read_config())


async def input_set_touchpad(params: dict, server: Any) -> dict:
    """Set touchpad settings. Only updates provided fields."""
    content = read_config()

    input_result = find_block(content, "input")
    if input_result is None:
        raise RuntimeError("No 'input' block found in niri config")

    inp_start, inp_end, inp_content = input_result

    flag_fields = {
        "tap": "tap",
        "natural_scroll": "natural-scroll",
        "dwt": "dwt",
    }
    value_fields = {
        "speed": ("accel-speed", lambda v: str(v)),
        "tap_button_map": ("tap-button-map", lambda v: f'"{v}"'),
    }

    for param_key, kdl_flag in flag_fields.items():
        if param_key in params:
            content = set_nested_flag(
                content, inp_start, inp_content,
                "touchpad", kdl_flag, bool(params[param_key])
            )
            inp_result2 = find_block(content, "input")
            if inp_result2:
                inp_start, inp_end, inp_content = inp_result2

    for param_key, (kdl_key, fmt) in value_fields.items():
        if param_key in params:
            content = set_nested_value(
                content, inp_start, inp_content,
                "touchpad", kdl_key, fmt(params[param_key])
            )
            inp_result2 = find_block(content, "input")
            if inp_result2:
                inp_start, inp_end, inp_content = inp_result2

    write_config(None, content)
    await reload_niri_config()
    server.broadcast({"event": "input.changed", "data": {"device": "touchpad"}})
    return _parse_input_settings(read_config())


async def input_set_mouse(params: dict, server: Any) -> dict:
    """Set mouse settings. Only updates provided fields."""
    content = read_config()

    input_result = find_block(content, "input")
    if input_result is None:
        raise RuntimeError("No 'input' block found in niri config")

    inp_start, inp_end, inp_content = input_result

    if "accel_profile" in params:
        content = set_nested_value(
            content, inp_start, inp_content,
            "mouse", "accel-profile", f'"{params["accel_profile"]}"'
        )
        inp_result2 = find_block(content, "input")
        if inp_result2:
            inp_start, inp_end, inp_content = inp_result2

    if "speed" in params:
        content = set_nested_value(
            content, inp_start, inp_content,
            "mouse", "accel-speed", str(params["speed"])
        )
        inp_result2 = find_block(content, "input")
        if inp_result2:
            inp_start, inp_end, inp_content = inp_result2

    write_config(None, content)
    await reload_niri_config()
    server.broadcast({"event": "input.changed", "data": {"device": "mouse"}})
    return _parse_input_settings(read_config())


# ── Module registration ──────────────────────────────────────────────


def register(registry: dict[str, Any]) -> None:
    """Register input methods with the server."""
    registry["input.get"] = input_get
    registry["input.set_keyboard"] = input_set_keyboard
    registry["input.set_touchpad"] = input_set_touchpad
    registry["input.set_mouse"] = input_set_mouse
    log.info("Input module registered (%d methods)", 4)
