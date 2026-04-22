# Status Bar Regression Matrix — Run Report

**Date:** 2026-04-22
**Runner:** Hermes

## Scope executed

Matrix generated for:
- `stylePreset`: `dusky`, `clean`, `glass`
- `density`: `compact`, `default`, `airy`
- `laneSeparator`: `off`, `subtle`, `strong`
- `ambientVisibility`: `auto`, `always`, `hidden`

Total combinations: **81**

## Output location

`docs/superpowers/assets/status-bar-matrix/2026-04-22/`

Key files:
- `matrix-manifest.csv` (all combinations with filenames)
- `style-density-overview.png` (3×3 visual quick scan)
- `lane-policy-overview-dusky-compact.png` (3×3 lane policy behavior quick scan)

## Automated validation checks

- Count check: **81 / 81** captured
- Resolution check: all captures are **2560×1440**
- File size range: **341,993 → 1,066,316 bytes**
- Hash uniqueness: **81 unique hashes / 81 files**
  - No accidental duplicate outputs across different setting combinations.

## Notes

- Capture was executed through `niri msg action screenshot-screen` with explicit `NIRI_SOCKET` binding.
- Live config was temporarily mutated per combination and then restored to original file content at the end of the run.

## Recommended follow-up

1. Visual QA pass over the two overview sheets and selected edge combos.
2. If any problematic combos are found, patch + regenerate only affected subset.
3. Once approved, keep this matrix as baseline for future status-bar changes.
