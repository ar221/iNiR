#!/usr/bin/env python3
"""Drain iNiR Hermes handoff queue entries from JSONL.

Default queue path: ~/.local/state/inir/hermes-telegram-handoff.jsonl

Usage examples:
  drain-hermes-handoff-queue.py
  drain-hermes-handoff-queue.py --max 10
  drain-hermes-handoff-queue.py --keep
  drain-hermes-handoff-queue.py --out /tmp/hermes-batch.json
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Drain Hermes handoff queue JSONL")
    p.add_argument(
        "--queue",
        default="~/.local/state/inir/hermes-telegram-handoff.jsonl",
        help="Queue JSONL file path",
    )
    p.add_argument(
        "--max",
        type=int,
        default=0,
        help="Max entries to consume (0 = all)",
    )
    p.add_argument(
        "--keep",
        action="store_true",
        help="Do not mutate queue file (read-only mode)",
    )
    p.add_argument(
        "--out",
        default="",
        help="Optional file path to write output JSON payload",
    )
    return p.parse_args()


def load_lines(queue_path: Path) -> list[str]:
    if not queue_path.exists():
        return []
    text = queue_path.read_text(encoding="utf-8")
    if not text.strip():
        return []
    return [ln for ln in text.splitlines() if ln.strip()]


def decode_entries(lines: list[str]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    valid: list[dict[str, Any]] = []
    invalid: list[dict[str, Any]] = []
    for idx, line in enumerate(lines, start=1):
        try:
            obj = json.loads(line)
            if isinstance(obj, dict):
                valid.append(obj)
            else:
                invalid.append({"line": idx, "error": "not-object", "raw": line})
        except Exception as exc:  # noqa: BLE001
            invalid.append({"line": idx, "error": str(exc), "raw": line})
    return valid, invalid


def main() -> int:
    args = parse_args()
    queue_path = Path(args.queue).expanduser()
    queue_path.parent.mkdir(parents=True, exist_ok=True)

    lines = load_lines(queue_path)
    if not lines:
        payload = {
            "ok": True,
            "queue": str(queue_path),
            "drained": 0,
            "remaining": 0,
            "entries": [],
            "invalid": [],
        }
        print(json.dumps(payload, ensure_ascii=False))
        return 0

    valid, invalid = decode_entries(lines)

    limit = args.max if args.max and args.max > 0 else len(valid)
    drained = valid[:limit]
    remaining_valid = valid[limit:]

    # Keep invalid lines in queue for manual inspection by default.
    remaining_lines: list[str] = [json.dumps(e, ensure_ascii=False) for e in remaining_valid]
    for bad in invalid:
        remaining_lines.append(bad["raw"])

    if not args.keep:
        new_text = "\n".join(remaining_lines)
        if new_text:
            new_text += "\n"
        queue_path.write_text(new_text, encoding="utf-8")

    payload = {
        "ok": True,
        "queue": str(queue_path),
        "drained": len(drained),
        "remaining": len(remaining_valid) + len(invalid),
        "entries": drained,
        "invalid": invalid,
    }

    output = json.dumps(payload, ensure_ascii=False)
    if args.out:
        out_path = Path(args.out).expanduser()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(output + "\n", encoding="utf-8")

    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
