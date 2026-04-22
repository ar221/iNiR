#!/usr/bin/env bash
#
# apply-chrome-theme.sh — Apply GM3 BrowserThemeColor to Chromium-based browsers
#
# Usage:
#   apply-chrome-theme.sh                  # auto-detect color from material pipeline
#   apply-chrome-theme.sh "#ff6b35"        # explicit hex color
#
# Supports: Google Chrome, Chromium, Brave
# Requires: jq, writable policy dir (one-time sudo setup)
#
# One-time setup per browser:
#   sudo mkdir -p /etc/chromium/policies/managed && sudo chown a+rw- /etc/chromium/policies/managed
#   sudo mkdir -p /etc/opt/chrome/policies/managed && sudo chown a+rw- /etc/opt/chrome/policies/managed
#   sudo mkdir -p /etc/brave/policies/managed && sudo chown a+rw- /etc/brave/policies/managed

XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$XDG_STATE_HOME/quickshell"
LOG_FILE="$STATE_DIR/user/generated/chrome_theme.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/config-path.sh
source "$SCRIPT_DIR/../lib/config-path.sh"
mkdir -p "$STATE_DIR/user/generated" 2>/dev/null
: > "$LOG_FILE" 2>/dev/null

log() { echo "[chrome] $*" >> "$LOG_FILE"; }

# ── Helpers ──────────────────────────────────────────────────────────────────

hex_to_rgb() {
  local hex=$1
  hex="${hex#\#}"
  printf "%d,%d,%d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

is_omarchy() {
  local bin_path
  bin_path=$(command -v "$1" 2>/dev/null)
  if [[ -n "$bin_path" ]]; then
    if command -v pacman &>/dev/null; then
      pacman -Qo "$bin_path" 2>/dev/null | grep -qi "omarchy" && return 0
    fi
  fi
  return 1
}

# ── Resolve theme color ─────────────────────────────────────────────────────

resolve_color() {
  # 1. Explicit argument
  if [[ -n "$1" && "$1" =~ ^#[A-Fa-f0-9]{6}$ ]]; then
    echo "$1"
    return
  fi

  # 2. Raw seed color from image (best for GM3, as Chrome generates its own palette from this)
  local seed_file="$STATE_DIR/user/generated/color.txt"
  if [[ -f "$seed_file" ]]; then
    local c
    c=$(cat "$seed_file" | tr -d '\n')
    if [[ -n "$c" && "$c" =~ ^#[A-Fa-f0-9]{6}$ ]]; then
      echo "$c"
      return
    fi
  fi

  # 3. explicit palette contract, then colors.json fallback
  local colors_json="$STATE_DIR/user/generated/palette.json"
  [[ -f "$colors_json" ]] || colors_json="$STATE_DIR/user/generated/colors.json"
  if [[ -f "$colors_json" ]] && command -v jq &>/dev/null; then
    local c
    c=$(jq -r '.primary // empty' "$colors_json" 2>/dev/null)
    if [[ -n "$c" ]]; then
      echo "$c"
      return
    fi
  fi
}

resolve_palette_file() {
  local palette_json="$STATE_DIR/user/generated/palette.json"
  if [[ -f "$palette_json" ]]; then
    echo "$palette_json"
    return
  fi

  local colors_json="$STATE_DIR/user/generated/colors.json"
  if [[ -f "$colors_json" ]]; then
    echo "$colors_json"
    return
  fi

  echo ""
}

palette_color() {
  local color_file="$1"
  local key="$2"
  local fallback="$3"

  if [[ -z "$color_file" || ! -f "$color_file" ]]; then
    echo "$fallback"
    return
  fi

  jq -r --arg key "$key" --arg fallback "$fallback" '.[$key] // $fallback' "$color_file" 2>/dev/null || echo "$fallback"
}

apply_firefox_shyfox_theme() {
  local color_file
  color_file=$(resolve_palette_file)
  if [[ -z "$color_file" ]]; then
    log "ShyFox: no palette/colors JSON found; skipping"
    return
  fi

  local m3_primary m3_on_primary m3_primary_container m3_on_primary_container
  local m3_secondary m3_on_secondary m3_secondary_container m3_on_secondary_container
  local m3_tertiary m3_on_tertiary m3_tertiary_container m3_on_tertiary_container
  local m3_error m3_on_error m3_error_container m3_on_error_container
  local m3_surface m3_on_surface m3_on_surface_variant
  local m3_surface_container_lowest m3_surface_container_low m3_surface_container m3_surface_container_high m3_surface_container_highest
  local m3_surface_bright m3_surface_dim m3_outline m3_outline_variant
  local m3_inverse_surface m3_inverse_on_surface m3_inverse_primary
  local m3_background m3_on_background

  m3_primary=$(palette_color "$color_file" "primary" "#cba6f7")
  m3_on_primary=$(palette_color "$color_file" "on_primary" "#1e1e2e")
  m3_primary_container=$(palette_color "$color_file" "primary_container" "#45475a")
  m3_on_primary_container=$(palette_color "$color_file" "on_primary_container" "#f5c2e7")

  m3_secondary=$(palette_color "$color_file" "secondary" "#f5c2e7")
  m3_on_secondary=$(palette_color "$color_file" "on_secondary" "#1e1e2e")
  m3_secondary_container=$(palette_color "$color_file" "secondary_container" "#45475a")
  m3_on_secondary_container=$(palette_color "$color_file" "on_secondary_container" "#f5c2e7")

  m3_tertiary=$(palette_color "$color_file" "tertiary" "#94e2d5")
  m3_on_tertiary=$(palette_color "$color_file" "on_tertiary" "#1e1e2e")
  m3_tertiary_container=$(palette_color "$color_file" "tertiary_container" "#45475a")
  m3_on_tertiary_container=$(palette_color "$color_file" "on_tertiary_container" "#94e2d5")

  m3_error=$(palette_color "$color_file" "error" "#f38ba8")
  m3_on_error=$(palette_color "$color_file" "on_error" "#1e1e2e")
  m3_error_container=$(palette_color "$color_file" "error_container" "#45475a")
  m3_on_error_container=$(palette_color "$color_file" "on_error_container" "#f38ba8")

  m3_surface=$(palette_color "$color_file" "surface" "#1e1e2e")
  m3_on_surface=$(palette_color "$color_file" "on_surface" "#cdd6f4")
  m3_on_surface_variant=$(palette_color "$color_file" "on_surface_variant" "#bac2de")
  m3_surface_container_lowest=$(palette_color "$color_file" "surface_container_lowest" "#11111b")
  m3_surface_container_low=$(palette_color "$color_file" "surface_container_low" "#181825")
  m3_surface_container=$(palette_color "$color_file" "surface_container" "#1e1e2e")
  m3_surface_container_high=$(palette_color "$color_file" "surface_container_high" "#313244")
  m3_surface_container_highest=$(palette_color "$color_file" "surface_container_highest" "#45475a")
  m3_surface_bright=$(palette_color "$color_file" "surface_bright" "#313244")
  m3_surface_dim=$(palette_color "$color_file" "surface_dim" "#11111b")
  m3_outline=$(palette_color "$color_file" "outline" "#6c7086")
  m3_outline_variant=$(palette_color "$color_file" "outline_variant" "#45475a")
  m3_inverse_surface=$(palette_color "$color_file" "inverse_surface" "#cdd6f4")
  m3_inverse_on_surface=$(palette_color "$color_file" "inverse_on_surface" "#1e1e2e")
  m3_inverse_primary=$(palette_color "$color_file" "inverse_primary" "#8839ef")
  m3_background=$(palette_color "$color_file" "background" "#1e1e2e")
  m3_on_background=$(palette_color "$color_file" "on_background" "#cdd6f4")

  local profiles_root="$HOME/.mozilla/firefox"
  [[ -d "$profiles_root" ]] || return

  local updated_count=0
  local profile_dir shyfox_dir target_file
  for profile_dir in "$profiles_root"/*; do
    shyfox_dir="$profile_dir/chrome/ShyFox"
    [[ -d "$shyfox_dir" ]] || continue
    target_file="$shyfox_dir/shy-material-colors.css"

    cat > "$target_file" <<EOF
/* Material You colors for ShyMaterial Firefox theme
   Auto-generated by iNiR wallpaper theming — do not edit manually */

:root, #screenshots-component * {
  /* === Material You Semantic Tokens === */
  --m3-primary:              ${m3_primary};
  --m3-on-primary:           ${m3_on_primary};
  --m3-primary-container:    ${m3_primary_container};
  --m3-on-primary-container: ${m3_on_primary_container};

  --m3-secondary:              ${m3_secondary};
  --m3-on-secondary:           ${m3_on_secondary};
  --m3-secondary-container:    ${m3_secondary_container};
  --m3-on-secondary-container: ${m3_on_secondary_container};

  --m3-tertiary:              ${m3_tertiary};
  --m3-on-tertiary:           ${m3_on_tertiary};
  --m3-tertiary-container:    ${m3_tertiary_container};
  --m3-on-tertiary-container: ${m3_on_tertiary_container};

  --m3-error:              ${m3_error};
  --m3-on-error:           ${m3_on_error};
  --m3-error-container:    ${m3_error_container};
  --m3-on-error-container: ${m3_on_error_container};

  --m3-surface:              ${m3_surface};
  --m3-on-surface:           ${m3_on_surface};
  --m3-on-surface-variant:   ${m3_on_surface_variant};

  --m3-surface-container-lowest:  ${m3_surface_container_lowest};
  --m3-surface-container-low:     ${m3_surface_container_low};
  --m3-surface-container:         ${m3_surface_container};
  --m3-surface-container-high:    ${m3_surface_container_high};
  --m3-surface-container-highest: ${m3_surface_container_highest};
  --m3-surface-bright:            ${m3_surface_bright};
  --m3-surface-dim:               ${m3_surface_dim};

  --m3-outline:         ${m3_outline};
  --m3-outline-variant: ${m3_outline_variant};

  --m3-inverse-surface:    ${m3_inverse_surface};
  --m3-inverse-on-surface: ${m3_inverse_on_surface};
  --m3-inverse-primary:    ${m3_inverse_primary};

  --m3-background: ${m3_background};
  --m3-on-background: ${m3_on_background};
}
EOF

    updated_count=$((updated_count + 1))
  done

  if [[ "$updated_count" -gt 0 ]]; then
    log "ShyFox: updated ${updated_count} profile(s)"
  fi
}

# ── Resolve dark/light mode ─────────────────────────────────────────────────
# Returns Chrome's color_scheme2 value:
#   In Chrome internals: 0 = system, 1 = light, 2 = dark
# But since Niri does not have a reliable XDG portal for standard Chrome,
# we map them directly. However, we'll invert them if needed to match what actually works.

resolve_color_scheme() {
  local meta_file="$STATE_DIR/user/generated/theme-meta.json"
  if [[ -f "$meta_file" ]] && command -v jq &>/dev/null; then
    local mode
    mode=$(jq -r '.mode // empty' "$meta_file" 2>/dev/null)
    if [[ "$mode" == "dark" || "$mode" == "light" ]]; then
      echo "$mode"
      return
    fi
  fi

  local scss_file="$STATE_DIR/user/generated/material_colors.scss"
  if [[ -f "$scss_file" ]]; then
    local val
    val=$(grep '^\$darkmode:' "$scss_file" | sed 's/.*: *\(.*\);/\1/' | tr -d ' ')
    if [[ "$val" == "True" || "$val" == "true" ]]; then
      # If Dark mode is currently returning light, we swap to 1.
      # If it's standard, it's 2. But we need to use 2 for dark in CLI and 2 for light in Prefs? 
      # Let's pass 'dark' or 'light' string, and translate internally per method.
      echo "dark"
      return
    fi
  fi
  echo "light"
}

# ── Browser registry ─────────────────────────────────────────────────────────
# Each entry: bin_name|policy_dir|prefs_dir

BROWSERS=()

_register() {
  local bin="$1" policy_dir="$2" prefs_dir="$3"
  if command -v "$bin" &>/dev/null; then
    BROWSERS+=("$bin|$policy_dir|$prefs_dir")
  fi
}

# Google Chrome
_register google-chrome-stable "/etc/opt/chrome/policies/managed" "$HOME/.config/google-chrome"
_register google-chrome        "/etc/opt/chrome/policies/managed" "$HOME/.config/google-chrome"
# Chromium
_register chromium             "/etc/chromium/policies/managed"   "$HOME/.config/chromium"
_register chromium-browser     "/etc/chromium/policies/managed"   "$HOME/.config/chromium"
# Brave
_register brave                "/etc/brave/policies/managed"      "$HOME/.config/BraveSoftware/Brave-Browser"
_register brave-browser        "/etc/brave/policies/managed"      "$HOME/.config/BraveSoftware/Brave-Browser"

# Deduplicate by policy_dir (e.g. google-chrome-stable vs google-chrome)
_dedup_browsers() {
  local -A seen
  local deduped=()
  for entry in "${BROWSERS[@]}"; do
    local policy_dir="${entry#*|}"
    policy_dir="${policy_dir%%|*}"
    if [[ -z "${seen[$policy_dir]:-}" ]]; then
      seen[$policy_dir]=1
      deduped+=("$entry")
    fi
  done
  BROWSERS=("${deduped[@]}")
}

# ── Preferences fixer ────────────────────────────────────────────────────────
# Ensures browser Preferences are set so managed policy theme takes effect.
# Clears user themes, sets both color_scheme and color_scheme2 to explicitly
# follow the required mode.

fix_preferences() {
  local prefs_dir="$1"
  local name="$2"
  local cs2="$3"  # color_scheme: 2=dark, 1=light, 0=system
  local prefs_file="$prefs_dir/Default/Preferences"

  # Create Default dir and minimal Preferences if missing
  if [[ ! -f "$prefs_file" ]]; then
    mkdir -p "$prefs_dir/Default" 2>/dev/null
    echo '{}' > "$prefs_file"
    log "$name: created empty Preferences file"
  fi

  # Apply all required defaults via jq — every run, not cached
  # extensions.theme.id = ""           → clear any installed/autogenerated theme
  # extensions.theme.use_system = false → don't use system theme
  # extensions.theme.use_custom = false → don't use custom theme
  # browser.theme.color_scheme         → 2=dark, 1=light, 0=system
  # browser.theme.color_scheme2        → 2=dark, 1=light, 0=system
  local tmp_file="${prefs_file}.ii-tmp"

  if jq --argjson cs "$cs2" '
    .extensions.theme.id = "" |
    .extensions.theme.use_system = false |
    .extensions.theme.use_custom = false |
    .browser.theme.color_scheme = $cs |
    .browser.theme.color_scheme2 = $cs |
    del(.browser.theme.user_color) |
    del(.browser.theme.user_color2)
  ' "$prefs_file" > "$tmp_file" 2>/dev/null && [[ -s "$tmp_file" ]]; then
    mv "$tmp_file" "$prefs_file"
    log "$name: preferences set (color_scheme=$cs2, color_scheme2=$cs2)"
  else
    rm -f "$tmp_file"
    log "$name: ERROR — failed to update preferences"
  fi
}

# ── Write policy and refresh ─────────────────────────────────────────────────

apply_to_browser() {
  local bin="$1"
  local policy_dir="$2"
  local prefs_dir="$3"
  local theme_color="$4"
  local mode="$5"  # "dark" or "light"
  local variant="$6"  # "tonal_spot", "content", "rainbow", etc.
  local name="$bin"

  # We must explicitly set Chrome's internal theme engine to Dark (2) or Light (1).
  # While xdg-desktop-portal successfully tells Chrome's GTK window borders to switch,
  # it often fails to trigger the GM3 Theme Engine to recalculate its palette.
  # 2 = Dark, 1 = Light
  local pref_cs2=1
  if [[ "$mode" == "dark" ]]; then
    pref_cs2=2
  fi

  # 1. Fix preferences first — ensures GM3 theme engine generates correct dark/light palette
  fix_preferences "$prefs_dir" "$name" "$pref_cs2"

  # 2. Write policy — only BrowserThemeColor (persists across restarts)
  if [[ -d "$policy_dir" && -w "$policy_dir" ]]; then
    echo "{\"BrowserThemeColor\": \"$theme_color\"}" | tee "$policy_dir/ii-theme.json" >/dev/null
  else
    log "$name: policy dir not writable → sudo mkdir -p $policy_dir && sudo chown \$USER $policy_dir"
  fi

  # 3. Apply live
  if is_omarchy "$bin"; then
    local rgb_color
    rgb_color=$(hex_to_rgb "$theme_color")
    
    log "$name: Omarchy fork detected. Using CLI flags + policy."
    # We use both: policy for persistence, CLI for instant flicker-free update
    "$bin" --no-startup-window \
           --refresh-platform-policy \
           --set-user-color="$rgb_color" \
           --set-color-scheme="$mode" \
           --set-color-variant="$variant" >/dev/null 2>&1 & disown
  else
    log "$name: Standard browser detected. Using policy refresh."
    "$bin" --refresh-platform-policy --no-startup-window >/dev/null 2>&1 & disown
  fi

  log "$name: applied theme $theme_color (mode=$mode, variant=$variant)"
}

# ── Resolve variant (scheme type) ──────────────────────────────────────────────

resolve_variant() {
  # Read variant from config
  local config_file
  config_file="$(inir_config_file)"
  if [[ -f "$config_file" ]]; then
    local variant
    variant=$(jq -r '.appearance.palette.type // "auto"' "$config_file" 2>/dev/null)
    if [[ -n "$variant" && "$variant" != "null" && "$variant" != "auto" ]]; then
      # Convert scheme-xxx to xxx for Chrome (e.g., scheme-tonal-spot -> tonal_spot)
      local chrome_variant
      chrome_variant=$(echo "$variant" | sed 's/scheme-//')

      # Chrome only supports: tonal_spot, neutral, vibrant, expressive
      # Map unsupported variants to neutral
      case "$chrome_variant" in
        tonal_spot|neutral|vibrant|expressive)
          echo "$chrome_variant"
          ;;
        *)
          echo "neutral"
          ;;
      esac
      return
    fi
  fi
  echo "tonal_spot"  # Default fallback
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  local theme_color
  theme_color=$(resolve_color "$1")

  if [[ -z "$theme_color" ]]; then
    log "Could not determine primary color. Skipping."
    return 1
  fi

  local mode
  mode=$(resolve_color_scheme)

  local variant
  variant=$(resolve_variant)

  log "GM3 seed color: $theme_color, mode: $mode, variant: $variant"

  apply_firefox_shyfox_theme

  _dedup_browsers

  if [[ ${#BROWSERS[@]} -eq 0 ]]; then
    log "No Chromium-based browsers found. Skipping."
    return 0
  fi

  for entry in "${BROWSERS[@]}"; do
    IFS='|' read -r bin policy_dir prefs_dir <<< "$entry"
    apply_to_browser "$bin" "$policy_dir" "$prefs_dir" "$theme_color" "$mode" "$variant"
  done
}

main "$@"
