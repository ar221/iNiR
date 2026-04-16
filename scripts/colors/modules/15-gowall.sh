#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/module-runtime.sh"
COLOR_MODULE_ID="gowall"

COLORS_FILE="$STATE_DIR/user/generated/colors.json"
GOWALL_CONFIG="${XDG_CONFIG_HOME}/gowall/config.yml"
THEME_NAME="material-you"

# Check if gowall is installed
if ! command -v gowall >/dev/null 2>&1; then
  log_module "gowall not installed, skipping"
  exit 0
fi

# Check if gowall theming is enabled in config (default: true if gowall exists)
enabled="$(config_bool '.appearance.wallpaperTheming.gowall.enabled' 'true')"
if [[ "$enabled" != "true" ]]; then
  log_module "gowall theming disabled in config"
  exit 0
fi

if [[ ! -f "$COLORS_FILE" ]]; then
  log_module "no colors.json found, skipping"
  exit 0
fi

log_module "syncing Material You palette to gowall theme"

# Extract curated palette from matugen colors
palette=$(python3 -c "
import json

with open('$COLORS_FILE') as f:
    c = json.load(f)

keys = [
    'background', 'surface_container_low', 'surface_container',
    'surface_container_high', 'surface_container_highest', 'surface_bright',
    'on_background', 'primary', 'primary_container', 'on_primary',
    'secondary_container', 'tertiary', 'tertiary_container', 'on_tertiary',
    'outline', 'outline_variant', 'inverse_primary', 'error', 'success',
    'term1', 'term2', 'term3', 'term4', 'term5', 'term6',
    'term9', 'term10', 'term11', 'term12', 'term13', 'term14', 'term15',
]

seen = set()
for k in keys:
    v = c.get(k, '')
    if v and v.upper() not in seen:
        seen.add(v.upper())
        print(v)
")

# Write gowall config
mkdir -p "$(dirname "$GOWALL_CONFIG")"
{
  echo "themes:"
  echo "  - name: \"$THEME_NAME\""
  echo "    colors:"
  while IFS= read -r color; do
    echo "      - \"$color\""
  done <<< "$palette"
} > "$GOWALL_CONFIG"

count=$(echo "$palette" | wc -l)
log_module "wrote $count colors to gowall theme '$THEME_NAME'"
