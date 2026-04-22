# iNiR Status Bar — Post-Lock Stress Sweep

Date: 2026-04-22  
Owner: Elsa + Hermes

## Scope
Targeted sanity sweep after **Iteration G (hard Dusky-horizontal lock)**.

Captured variants:
1. `baseline-off-hidden` (`laneSeparator=off`, `ambientVisibility=hidden`)
2. `stress-subtle-auto` (`laneSeparator=subtle`, `ambientVisibility=auto`)
3. `stress-strong-always` (`laneSeparator=strong`, `ambientVisibility=always`)
4. `stress-off-always` (`laneSeparator=off`, `ambientVisibility=always`)

All captures were taken at 2560x1440 and runtime config was restored to:
- `stylePreset=dusky`
- `density=compact`
- `laneSeparator=off`
- `ambientVisibility=hidden`

## Artifacts
- Folder: `docs/superpowers/assets/status-bar-matrix/2026-04-22/post-lock-stress/`
- Manifest: `docs/superpowers/assets/status-bar-matrix/2026-04-22/post-lock-stress/manifest.csv`
- Overview sheet: `docs/superpowers/assets/status-bar-matrix/2026-04-22/post-lock-stress/post-lock-stress-overview.png`

## Readout (top bar only)
- `baseline-off-hidden`: `clip=no`, `crowd=high`, `hierarchy=weak`, `verdict=fail`
- `stress-subtle-auto`: `clip=no`, `crowd=high`, `hierarchy=mid`, `verdict=pass`
- `stress-strong-always`: `clip=no`, `crowd=high`, `hierarchy=weak`, `verdict=fail`
- `stress-off-always`: `clip=no`, `crowd=med`, `hierarchy=clear`, `verdict=pass`

## Outcome
- No clipping detected in this sweep.
- Heavy separator + always-ambient combinations continue to overload hierarchy.
- The hard-lock direction (`off + hidden`) remains the correct shipped baseline for silhouette and noise control.

## Ship Recommendation
Keep production default at:
- `stylePreset=dusky`
- `density=compact`
- `laneSeparator=off`
- `ambientVisibility=hidden`

Optional future micro-pass:
- reduce non-critical status badges during high-load states for even cleaner hierarchy.
