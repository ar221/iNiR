#!/usr/bin/env python3
"""Analyze wallpaper colors and cache dominant hue per file.

Scans a directory for image/video files, extracts the dominant color,
and buckets each into one of 12 hue categories. Results are cached
incrementally in a JSON file.

Usage:
    analyze-wallpaper-colors.py <directory> [--cache <path>] [--force]

Output JSON format:
    {
        "/path/to/file.jpg": {"hue": 210, "sat": 0.72, "lum": 0.45, "bucket": "blue"},
        ...
    }
"""

import argparse
import colorsys
import json
import logging
import os
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger(__name__)

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".avif", ".bmp", ".svg", ".gif"}
VIDEO_EXTS = {".mp4", ".webm", ".mkv", ".avi", ".mov"}
ALL_EXTS = IMAGE_EXTS | VIDEO_EXTS

# 12 hue buckets — ranges are [start, end) in degrees
HUE_BUCKETS = [
    ("red",     0,   15),
    ("orange",  15,  45),
    ("yellow",  45,  70),
    ("lime",    70,  100),
    ("green",   100, 140),
    ("teal",    140, 170),
    ("cyan",    170, 200),
    ("blue",    200, 245),
    ("indigo",  245, 270),
    ("violet",  270, 310),
    ("pink",    310, 345),
    ("red2",    345, 361),  # wraps around
]

# Representative colors for each bucket (used by QML for the dot display)
BUCKET_COLORS = {
    "red":    "#E53935",
    "orange": "#FB8C00",
    "yellow": "#FDD835",
    "lime":   "#7CB342",
    "green":  "#43A047",
    "teal":   "#00897B",
    "cyan":   "#00ACC1",
    "blue":   "#1E88E5",
    "indigo": "#5E35B1",
    "violet": "#8E24AA",
    "pink":   "#D81B60",
    "neutral":"#78909C",
}


def hue_to_bucket(hue_deg: float, saturation: float) -> str:
    """Map a hue degree (0-360) and saturation to a bucket name."""
    if saturation < 0.12:
        return "neutral"
    for name, start, end in HUE_BUCKETS:
        if start <= hue_deg < end:
            return name.rstrip("2")  # red2 -> red
    return "neutral"


def dominant_color(image_path: str, sample_size: int = 150) -> tuple[float, float, float]:
    """Extract dominant color from an image. Returns (hue_deg, saturation, luminance)."""
    try:
        with Image.open(image_path) as img:
            # Resize for speed
            img = img.convert("RGB").resize((sample_size, sample_size), Image.LANCZOS)
            pixels = list(img.getdata())
    except Exception:
        return (0.0, 0.0, 0.0)

    if not pixels:
        return (0.0, 0.0, 0.0)

    # Quantize to reduce noise — use 5-bit color (32 levels per channel)
    quantized = [(r >> 3, g >> 3, b >> 3) for r, g, b in pixels]
    counter = Counter(quantized)

    # Weight by frequency, skip very dark and very light pixels
    weighted_h = 0.0
    weighted_s = 0.0
    weighted_l = 0.0
    total_weight = 0

    for (rq, gq, bq), count in counter.most_common(20):
        r, g, b = rq * 8, gq * 8, bq * 8
        h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        # Skip near-black and near-white
        if l < 0.08 or l > 0.92:
            continue
        # Weight saturated colors more
        weight = count * (0.5 + s)
        weighted_h += h * weight
        weighted_s += s * weight
        weighted_l += l * weight
        total_weight += weight

    if total_weight == 0:
        return (0.0, 0.0, 0.5)

    avg_h = weighted_h / total_weight
    avg_s = weighted_s / total_weight
    avg_l = weighted_l / total_weight

    return (avg_h * 360, avg_s, avg_l)


def get_video_thumbnail(video_path: str) -> str | None:
    """Find cached video thumbnail (same path as iNiR's video first-frame system)."""
    import hashlib
    xdg_config = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    thumb_dir = os.path.join(xdg_config, "hypr/custom/scripts/mpvpaper_thumbnails")
    md5 = hashlib.md5(video_path.encode()).hexdigest()
    thumb_path = os.path.join(thumb_dir, f"{md5}.jpg")
    if os.path.isfile(thumb_path):
        return thumb_path
    return None


def analyze_file(file_path: str) -> dict | None:
    """Analyze a single file and return color data."""
    ext = Path(file_path).suffix.lower()

    if ext in VIDEO_EXTS:
        thumb = get_video_thumbnail(file_path)
        if not thumb:
            return None  # Skip videos without thumbnails
        analyze_path = thumb
    elif ext in IMAGE_EXTS:
        analyze_path = file_path
    else:
        return None

    hue, sat, lum = dominant_color(analyze_path)
    bucket = hue_to_bucket(hue, sat)

    return {
        "hue": round(hue, 1),
        "sat": round(sat, 3),
        "lum": round(lum, 3),
        "bucket": bucket,
    }


def main():
    parser = argparse.ArgumentParser(description="Analyze wallpaper colors")
    parser.add_argument("directory", help="Directory to scan")
    parser.add_argument("--cache", default=None,
                        help="Cache JSON path (default: ~/.cache/quickshell/wallpaper-colors.json)")
    parser.add_argument("--force", action="store_true", help="Re-analyze all files")
    parser.add_argument("--json-output", action="store_true",
                        help="Print results to stdout as JSON (for QML Process consumption)")
    args = parser.parse_args()

    directory = os.path.expanduser(args.directory)
    if not os.path.isdir(directory):
        log.error(f"Not a directory: {directory}")
        sys.exit(1)

    cache_path = args.cache or os.path.join(
        os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
        "quickshell", "wallpaper-colors.json"
    )

    # Load existing cache
    cache = {}
    if not args.force and os.path.isfile(cache_path):
        try:
            with open(cache_path) as f:
                cache = json.load(f)
        except (json.JSONDecodeError, OSError):
            cache = {}

    # Scan directory
    files = []
    for entry in os.scandir(directory):
        if entry.is_file() and Path(entry.name).suffix.lower() in ALL_EXTS:
            files.append(entry.path)

    # Determine which files need analysis
    to_analyze = []
    for fp in files:
        if fp not in cache:
            to_analyze.append(fp)

    # Remove deleted files from cache
    existing = set(files)
    removed = [k for k in cache if k.startswith(directory + "/") and k not in existing]
    for k in removed:
        del cache[k]

    total = len(to_analyze)
    if total == 0:
        log.info("All files already analyzed")
        if args.json_output:
            # Output only entries for this directory
            dir_cache = {k: v for k, v in cache.items() if k.startswith(directory + "/")}
            print(json.dumps(dir_cache))
        _save_cache(cache, cache_path)
        sys.exit(0)

    log.info(f"Analyzing {total} files...")
    for i, fp in enumerate(to_analyze, 1):
        result = analyze_file(fp)
        if result:
            cache[fp] = result
        print(f"PROGRESS {i}/{total}", flush=True)

    _save_cache(cache, cache_path)

    if args.json_output:
        dir_cache = {k: v for k, v in cache.items() if k.startswith(directory + "/")}
        print(json.dumps(dir_cache))

    log.info(f"Done. Analyzed {total} new files, {len(cache)} total cached.")


def _save_cache(cache: dict, path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(cache, f, separators=(",", ":"))


if __name__ == "__main__":
    main()
