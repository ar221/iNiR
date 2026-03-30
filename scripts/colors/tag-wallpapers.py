#!/usr/bin/env python3
"""Auto-tag wallpapers using a vision LLM (Gemini or Ollama).

Scans a directory, sends each untagged wallpaper to a vision model,
and caches the resulting tags in a JSON file.

Usage:
    tag-wallpapers.py <directory> [--provider gemini|ollama] [--model <name>]
                      [--cache <path>] [--force] [--json-output]

Providers:
    gemini  — Uses Gemini API via secret-tool (default, no local GPU needed)
    ollama  — Uses local Ollama instance (gemma3:4b or similar)

Output JSON format:
    {
        "/path/to/file.jpg": ["anime", "dark", "cityscape", "neon", "blue"],
        ...
    }
"""

import argparse
import base64
import json
import logging
import os
import subprocess
import sys
import time
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger(__name__)

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".avif", ".bmp", ".gif"}
VIDEO_EXTS = {".mp4", ".webm", ".mkv", ".avi", ".mov"}
ALL_EXTS = IMAGE_EXTS | VIDEO_EXTS

TAG_PROMPT = (
    "List 5-8 single-word tags describing this wallpaper image. "
    "Include tags for: subject matter, art style, mood/atmosphere, "
    "dominant colors, and setting/environment. "
    "Return ONLY a JSON array of lowercase strings, nothing else. "
    'Example: ["anime", "dark", "cityscape", "neon", "blue", "night"]'
)


def get_gemini_api_key() -> str | None:
    """Retrieve Gemini API key from system keyring via secret-tool."""
    try:
        result = subprocess.run(
            ["secret-tool", "lookup", "application", "illogical-impulse"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            data = json.loads(result.stdout.strip())
            return data.get("apiKeys", {}).get("gemini")
    except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
        pass
    return os.environ.get("GEMINI_API_KEY")


def resize_image(image_path: str, max_dim: int = 256) -> bytes:
    """Resize image and return JPEG bytes. Uses Pillow."""
    from PIL import Image
    with Image.open(image_path) as img:
        img = img.convert("RGB")
        img.thumbnail((max_dim, max_dim))
        import io
        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=60)
        return buf.getvalue()


def get_video_thumbnail(video_path: str) -> str | None:
    """Find cached video thumbnail."""
    import hashlib
    xdg_config = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    thumb_dir = os.path.join(xdg_config, "hypr/custom/scripts/mpvpaper_thumbnails")
    md5 = hashlib.md5(video_path.encode()).hexdigest()
    thumb_path = os.path.join(thumb_dir, f"{md5}.jpg")
    return thumb_path if os.path.isfile(thumb_path) else None


def tag_with_gemini(image_path: str, api_key: str, model: str = "gemini-2.0-flash") -> list[str]:
    """Tag a single image using Gemini API."""
    import urllib.request

    image_bytes = resize_image(image_path)
    b64_data = base64.b64encode(image_bytes).decode("ascii")

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    payload = {
        "contents": [{
            "parts": [
                {"text": TAG_PROMPT},
                {"inline_data": {"mime_type": "image/jpeg", "data": b64_data}}
            ]
        }],
        "generationConfig": {
            "temperature": 0.3,
            "maxOutputTokens": 200,
        }
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            result = json.loads(resp.read().decode())
            text = result["candidates"][0]["content"]["parts"][0]["text"]
            # Extract JSON array from response (may have markdown fences)
            text = text.strip()
            if text.startswith("```"):
                text = text.split("\n", 1)[1].rsplit("```", 1)[0].strip()
            tags = json.loads(text)
            return [t.lower().strip() for t in tags if isinstance(t, str)]
    except Exception as e:
        log.warning(f"Gemini error for {os.path.basename(image_path)}: {e}")
        return []


def tag_with_ollama(image_path: str, model: str = "gemma3:4b",
                    base_url: str = "http://localhost:11434") -> list[str]:
    """Tag a single image using local Ollama."""
    import urllib.request

    image_bytes = resize_image(image_path)
    b64_data = base64.b64encode(image_bytes).decode("ascii")

    url = f"{base_url}/api/generate"
    payload = {
        "model": model,
        "prompt": TAG_PROMPT,
        "images": [b64_data],
        "stream": False,
        "options": {"temperature": 0.3}
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode())
            text = result.get("response", "").strip()
            if text.startswith("```"):
                text = text.split("\n", 1)[1].rsplit("```", 1)[0].strip()
            tags = json.loads(text)
            return [t.lower().strip() for t in tags if isinstance(t, str)]
    except Exception as e:
        log.warning(f"Ollama error for {os.path.basename(image_path)}: {e}")
        return []


def main():
    parser = argparse.ArgumentParser(description="Auto-tag wallpapers with AI")
    parser.add_argument("directory", help="Directory to scan")
    parser.add_argument("--provider", choices=["gemini", "ollama"], default="gemini",
                        help="AI provider (default: gemini)")
    parser.add_argument("--model", default=None,
                        help="Model name (default: gemini-2.0-flash or gemma3:4b)")
    parser.add_argument("--cache", default=None,
                        help="Cache JSON path (default: ~/.cache/quickshell/wallpaper-tags.json)")
    parser.add_argument("--force", action="store_true", help="Re-tag all files")
    parser.add_argument("--limit", type=int, default=0,
                        help="Max files to tag in this run (0 = all)")
    parser.add_argument("--json-output", action="store_true",
                        help="Print results to stdout as JSON")
    args = parser.parse_args()

    directory = os.path.expanduser(args.directory)
    if not os.path.isdir(directory):
        log.error(f"Not a directory: {directory}")
        sys.exit(1)

    cache_path = args.cache or os.path.join(
        os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
        "quickshell", "wallpaper-tags.json"
    )

    # Determine provider config
    provider = args.provider
    if provider == "gemini":
        api_key = get_gemini_api_key()
        if not api_key:
            log.error("No Gemini API key found (checked secret-tool and $GEMINI_API_KEY)")
            sys.exit(1)
        model = args.model or "gemini-2.0-flash"
        tag_fn = lambda path: tag_with_gemini(path, api_key, model)
    else:
        model = args.model or "gemma3:4b"
        base_url = os.environ.get("OLLAMA_URL", "http://localhost:11434")
        tag_fn = lambda path: tag_with_ollama(path, model, base_url)

    # Load cache
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

    to_tag = [fp for fp in files if fp not in cache]

    # Remove deleted files from cache
    existing = set(files)
    removed = [k for k in cache if k.startswith(directory + "/") and k not in existing]
    for k in removed:
        del cache[k]

    if args.limit > 0:
        to_tag = to_tag[:args.limit]

    total = len(to_tag)
    if total == 0:
        log.info("All files already tagged")
        if args.json_output:
            dir_cache = {k: v for k, v in cache.items() if k.startswith(directory + "/")}
            print(json.dumps(dir_cache))
        _save_cache(cache, cache_path)
        sys.exit(0)

    log.info(f"Tagging {total} files with {provider} ({model})...")
    for i, fp in enumerate(to_tag, 1):
        ext = Path(fp).suffix.lower()
        if ext in VIDEO_EXTS:
            thumb = get_video_thumbnail(fp)
            if not thumb:
                log.info(f"  [{i}/{total}] Skipping video without thumbnail: {os.path.basename(fp)}")
                print(f"PROGRESS {i}/{total}", flush=True)
                continue
            analyze_path = thumb
        else:
            analyze_path = fp

        tags = tag_fn(analyze_path)
        if tags:
            cache[fp] = tags
            log.info(f"  [{i}/{total}] {os.path.basename(fp)}: {tags}")
        else:
            log.info(f"  [{i}/{total}] {os.path.basename(fp)}: (no tags)")

        print(f"PROGRESS {i}/{total}", flush=True)

        # Rate limiting for Gemini (free tier: 15 RPM)
        if provider == "gemini" and i < total:
            time.sleep(4.5)

    _save_cache(cache, cache_path)

    if args.json_output:
        dir_cache = {k: v for k, v in cache.items() if k.startswith(directory + "/")}
        print(json.dumps(dir_cache))

    log.info(f"Done. Tagged {total} files, {len(cache)} total cached.")


def _save_cache(cache: dict, path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(cache, f, separators=(",", ":"))


if __name__ == "__main__":
    main()
