# Courier Wedge B Execution Report

Date: 2026-05-15
Repo: `/home/ayaz/Github/inir`
Plan: `/home/ayaz/Github/inir/.agents/plans/courier-wedge-b-system-stack-wiring.md`
Status: **COMPLETE (code + mechanical + positive verification). Visual smoke gates pending Ayaz.**

## Files changed

- `scripts/colors/switchwall.sh`

## Verification commands and actual output

### 1) New helper is declared

Command:

```bash
grep -n "read_appearance_global_style" /home/ayaz/Github/inir/scripts/colors/switchwall.sh
```

Output:

```text
1010:    read_appearance_global_style() {
1127:        global_style=$(read_appearance_global_style)
```

Result: **PASS**

### 2) New auto-guard branch checks courier

Command:

```bash
grep -nE 'global_style.*==.*"courier"|"courier".*global_style' /home/ayaz/Github/inir/scripts/colors/switchwall.sh
```

Output:

```text
1128:        if [[ "$global_style" == "courier" && -d "$PALETTES_DIR/courier" ]]; then
```

Result: **PASS**

### 3) Courier branch precedes theme branch

Command:

```bash
awk '/global_style.*== *"courier"/{a=NR} /read_theme_for_preset_guard/{b=NR} END{print "courier-branch-line:"a, "theme-branch-line:"b; exit (a && b && a < b ? 0 : 1)}' /home/ayaz/Github/inir/scripts/colors/switchwall.sh
```

Output:

```text
courier-branch-line:1128 theme-branch-line:1134
```

Result: **PASS**

### 4) `enableVesktop` wired in `deploy_preset()`

Command:

```bash
grep -n 'enableVesktop' /home/ayaz/Github/inir/scripts/colors/switchwall.sh
```

Output:

```text
455:            enableVesktop: (.appearance.wallpaperTheming.enableVesktop // true)
779:        enable_vesktop=$(_cfg_get enableVesktop)
859:            enableVesktop:      (.appearance.wallpaperTheming.enableVesktop      // true)
935:        enable_vesktop=$(_preset_cfg enableVesktop)
```

Result: **PASS** (includes new deploy_preset block hit at line 859)

### 5) Vesktop + newsboat additive copy lines exist

Command:

```bash
grep -nE 'vesktop/vesktop\.css|newsboat/colors' /home/ayaz/Github/inir/scripts/colors/switchwall.sh
```

Output:

```text
930:    #   - templates/vesktop/vesktop.css
931:    #   - tools/newsboat/colors
937:            _copy_if_exists "$templates_src/vesktop/vesktop.css" \
943:        _copy_if_exists "$preset_dir/tools/newsboat/colors" \
944:            "$HOME/.config/newsboat/colors"
```

Result: **PASS**

### 6) No edits to disallowed files

Command:

```bash
git -C /home/ayaz/Github/inir diff --name-only HEAD -- defaults/palettes/courier defaults/palettes/apollo modules scripts/colors/applycolor.sh scripts/colors/apply-targets.sh scripts/colors/modules scripts/colors/apply-chrome-theme.sh scripts/colors/apply-gtk-theme.sh scripts/colors/generate_terminal_configs.py scripts/colors/generate_colors_material.py scripts/colors/system24_palette.sh scripts/colors/system24_palette.py scripts/sddm dots/sddm
```

Output:

```text
(no output)
```

Result: **PASS**

### 7) Script parse check

Command:

```bash
bash -n /home/ayaz/Github/inir/scripts/colors/switchwall.sh
```

Output:

```text
(no output)
```

Result: **PASS**

### 8) Courier preset tree untouched

Command:

```bash
git -C /home/ayaz/Github/inir status --porcelain -- defaults/palettes/
```

Output:

```text
(no output)
```

Result: **PASS**

### 8b) `theme=courier` loophole closed in old branch

Command:

```bash
grep -nE '"\$auto_theme" *!= *"courier"' /home/ayaz/Github/inir/scripts/colors/switchwall.sh
```

Output:

```text
1135:        if [[ "$auto_theme" != "auto" && "$auto_theme" != "courier" && -d "$PALETTES_DIR/$auto_theme" ]]; then
```

Result: **PASS**

### 9-14) Positive verification bundle

Command sequence ran per brief: backup config, set `globalStyle="courier"`, run `switchwall.sh --noswitch`, assert guard log, diff deployed files, probe gate outputs.

Output:

```text
cfg_file=/home/ayaz/.config/inir/config.json
backup9=/home/ayaz/.config/inir/config.json.preB.bak.1778882343
[switchwall.sh] courier auto-guard: appearance.globalStyle='courier'; redirecting to deploy_preset courier (image: <none>)
[switchwall.sh] deploying preset: courier (from /home/ayaz/Github/inir/defaults/palettes/courier)
[sddm-pixel] Colors synced (primary: #C98A2E)
[sddm-pixel] Background updated: wallhaven-vpyqm8.jpg
[switchwall.sh] preset 'courier' deployed
guard_check=PASS
state_diff_check=PASS
vesktop_diff_check=PASS
newsboat_diff_check=PASS
gtk_probe=PASS
kitty_probe=PASS
qt5ct_probe=PASS
```

Result: **PASS**

Notes:
- SDDM log lines were emitted by existing fan-out/module behavior; no SDDM files were edited in this wedge.
- Positive `diff` checks were used (not Apollo-bleed grep), so shared token `#3A2710` cannot false-flag.

### 16) Loophole closure live test

Command sequence: set `globalStyle="material"` + `theme="courier"`, run `switchwall.sh --noswitch`, assert old branch log does not appear.

Output:

```text
[sddm-pixel] Colors synced (primary: #C2A781)
[sddm-pixel] Background updated: wallhaven-vpyqm8.jpg
PASS: loophole closed
```

Result: **PASS**

## Acceptance criteria matrix

- [x] Mechanical command 1: helper declaration + call present.
- [x] Mechanical command 2: courier globalStyle check present.
- [x] Mechanical command 3: courier branch before theme branch.
- [x] Mechanical command 4: `enableVesktop` wired in deploy block.
- [x] Mechanical command 5: vesktop + newsboat copy lines present.
- [x] Mechanical command 6: no disallowed-file edits.
- [x] Mechanical command 7: script parses.
- [x] Mechanical command 8: preset trees untouched.
- [x] Mechanical command 8b: old branch refuses `theme="courier"`.
- [x] Positive command 10: courier auto-guard log present.
- [x] Positive command 11: six state files match courier preset byte-for-byte.
- [x] Positive command 12: vesktop deploy diff clean.
- [x] Positive command 13: newsboat deploy diff clean.
- [x] Positive command 14: default-true gate probes all pass.
- [x] Positive command 16: loophole closure passes.
- [ ] Visual smoke S1-S7: **PENDING Ayaz observational validation**.
- [x] Wedge B report written to requested path.
- [x] No `qs` restart used.
- [ ] Config backup from command 9 restored after Ayaz visual sign-off: **PENDING by design** (backup exists: `/home/ayaz/.config/inir/config.json.preB.bak.1778882343`).

## Must-not-touch reconciliation (explicit)

- Reconciled before finalize: verification command set only inspects literals introduced by Wedge B plus positive deploy diffs.
- No verification command depends on Apollo/Courier shared hex comparisons, so shared `#3A2710` cannot create false Apollo-bleed findings.
- No must-not-touch path was modified by this wedge.

## Deviations and why

- No scope deviation on code edits.
- Brief command 15 (config restore after positive run) intentionally left pending until Ayaz visual smoke sign-off, matching brief instruction text.

## What Wedge C inherits

- Courier system-stack routing is now wired at `switchwall.sh` via `appearance.globalStyle == "courier"` priority auto-guard.
- Legacy theme-branch loophole is closed (`theme="courier"` refused).
- `deploy_preset()` now includes additive deploys for Vesktop CSS, Newsboat colors, and staged Firefox shy-material CSS.
- SDDM remains out of scope and unmodified at source level for Wedge C ownership.

## EXPLICIT BEHAVIOR-CHANGE FLAGS

1. Quickshell hot-reloads on `globalStyle` flips but does **not** auto-run `switchwall.sh`; system stack remains Material until user runs `bash scripts/colors/switchwall.sh --noswitch` (or another path that re-enters switchwall).
2. While `appearance.globalStyle == "courier"`, do **not** run `matugen image` directly; it can clobber Courier system surfaces. Recovery: rerun `bash scripts/colors/switchwall.sh --noswitch`.
3. `theme="courier"` alone no longer triggers Courier; only `globalStyle="courier"` does.
4. Apollo users remain unaffected unless they explicitly set `globalStyle="courier"`.
5. Vesktop CSS deploy is live; Newsboat and Firefox ShyFox still require app restart to observe changes.
