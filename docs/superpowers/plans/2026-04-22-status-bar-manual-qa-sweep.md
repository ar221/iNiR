# iNiR Status Bar — Manual QA Sweep (Matrix Review)

Date: 2026-04-22  
Scope: Review of 81-capture matrix (`stylePreset × density × laneSeparator × ambientVisibility`)

## Artifacts reviewed
- `docs/superpowers/assets/status-bar-matrix/2026-04-22/qa-sheets/qa-summary-style-density.png`
- `docs/superpowers/assets/status-bar-matrix/2026-04-22/qa-sheets/qa-style_<style>-density_<density>.png` (9 sheets)
- Targeted single-frame spot checks for candidate presets and lane policies.

## Core findings

### 1) Style×Density ranking (best → worst)
From visual ranking pass at canonical lane policy (`sep=subtle`, `ambient=auto`):
1. `dusky-compact`
2. `glass-compact`
3. `clean-compact`
4. `dusky-default`
5. `glass-default`
6. `clean-default`
7. `dusky-airy`
8. `glass-airy`
9. `clean-airy`

**Conclusion:** density has the strongest visual impact. `compact` is consistently best for the intended horizontal block rhythm.

### 2) Lane policy trend
Across style-density sheets, best picks repeatedly favored **subtle separators** and avoided heavy separators.

- Most stable lane policy: `sep=subtle` + `ambient=auto|hidden`
- Commonly weak: `sep=strong` in combination with high ambient visibility (`always`) due to visual heaviness.

### 3) Candidate spot-check scores (top panel only)
- `dusky + compact + subtle + auto` → keep
- `dusky + compact + subtle + hidden` → keep
- `glass + compact + subtle + hidden` → keep
- `clean + compact + subtle + hidden` → tweak
- `dusky + default + subtle + auto` → tweak
- `dusky + airy + subtle + auto` → tweak/reject boundary

## Keep / Tweak / Reject shortlist

## KEEP (ship-safe)
- `stylePreset=dusky`, `density=compact`, `laneSeparator=subtle`, `ambientVisibility=auto`  **(recommended default)**
- `stylePreset=dusky`, `density=compact`, `laneSeparator=subtle`, `ambientVisibility=hidden`
- `stylePreset=glass`, `density=compact`, `laneSeparator=subtle`, `ambientVisibility=hidden`

## TWEAK (valid, but not final)
- Any `density=default` variant with `laneSeparator=subtle`
- `stylePreset=clean`, `density=compact`, `laneSeparator=subtle`, `ambientVisibility=hidden|auto`
- `laneSeparator=off` variants (need clearer group boundaries)

## REJECT (for primary preset)
- Most `density=airy` variants for this design target
- Any `laneSeparator=strong` with `ambientVisibility=always`

## Implementation pass for Elsa
1. Keep `dusky+compact` as baseline visual language.
2. Set default to `subtle + auto` (current best balance).
3. Micro-tweak only:
   - Slightly reduce perceived heaviness of strong separator mode (if retained as option).
   - Preserve compact clock prominence and right-cluster icon clarity.
   - Keep ambient lane collapsed behavior in short form.
4. Optional: expose a “recommended” badge in settings for the default tuple.

## Final recommendation
Proceed with **Dusky Compact / Subtle / Auto** as the production default, keep Glass Compact as alternate, and treat airy modes as non-default experimental profiles.
