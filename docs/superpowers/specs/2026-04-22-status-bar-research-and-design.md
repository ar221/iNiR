# iNiR Status Bar — Cross-Ecosystem Research + Design Spec

**Date:** 2026-04-22  
**Owner:** Elsa + Hermes (implementation lead)  
**Status:** Drafted and implemented as Iteration A + Iteration B + Iteration C + Iteration D + Iteration E + Iteration F (ship polish live)

---

## 1) Research Goal

Find status bar patterns from **Quickshell**, **niri ecosystem**, and **Hyprland ecosystem** that fit iNiR's design language and naming.

Target fit criteria:
- cockpit-like clarity (scan in <1s)
- dense but legible telemetry
- modular grouping (urgent/system/ambient)
- token-driven spacing (no literal-sprawl)
- works in both niri and hyprland compositor paths

---

## 2) Reference Set (with visuals)

## A. Quickshell-first references

### 1) Noctalia Shell
- Repo: https://github.com/noctalia-dev/noctalia-shell
- Example images:
  - https://raw.githubusercontent.com/noctalia-dev/noctalia-shell/main/Assets/Screenshots/noctalia-dark-1.png
  - https://raw.githubusercontent.com/noctalia-dev/noctalia-shell/main/Assets/Screenshots/noctalia-dark-2.png
- Why relevant:
  - segmented bar composition (left/center/right discipline)
  - restrained iconography + strong spacing rhythm
  - clean pill abstractions and stable module boundaries

### 2) DankMaterialShell (niri + hyprland aware)
- Repo: https://github.com/AvengeMedia/DankMaterialShell
- Example preview links from README/user attachments:
  - https://github.com/user-attachments/assets/203a9678-c3b7-4720-bb97-853a511ac5c8
  - https://github.com/user-attachments/assets/a937cf35-a43b-4558-8c39-5694ff5fcac4
- Why relevant:
  - explicit left/center/right section architecture
  - strong module composability
  - compositor-conditional logic (Niri + Hyprland)

### 3) Chris Titus Quickshell bar (hyprland-focused minimal)
- Repo: https://github.com/ChrisTitusTech/quickshell
- Why relevant:
  - straightforward block model (`Blocks.*`) with predictable grouping
  - practical left-center-right assignment and active window centering constraints

## B. Hyprland / Waybar reference family

### 4) Dusky (multiple waybar compositions)
- Repo: https://github.com/dusklinux/dusky
- Example images:
  - https://raw.githubusercontent.com/dusklinux/dusky/main/Pictures/readme_assets/waybar_horizontal.webp
  - https://raw.githubusercontent.com/dusklinux/dusky/main/Pictures/readme_assets/waybar_minimal.webp
- Why relevant:
  - demonstrates information density presets (minimal vs full)
  - clear module lane conventions in `modules-left/center/right`

### 5) JaKooLit Hyprland dots
- Repo: https://github.com/JaKooLit/Hyprland-Dots
- Why relevant:
  - broad operational bar module set and script wiring
  - practical production behavior patterns for tray/network/updates

## C. niri ecosystem routing references

### 6) awesome-niri index (routing map)
- Repo: https://github.com/niri-wm/awesome-niri
- Why relevant:
  - confirms active ecosystem patterns for bars/widgets
  - links niri-native + waybar-adjacent module patterns

### 7) iNiR upstream lineage
- Repo: https://github.com/snowarch/iNiR
- Example images:
  - https://github.com/user-attachments/assets/1fe258bc-8aec-4fd9-8574-d9d7472c3cc8
  - https://github.com/user-attachments/assets/3ce2055b-648c-45a1-9d09-705c1b4a03b7
- Why relevant:
  - confirms naming and architectural continuity expectations for our fork

---

## 3) Pattern Synthesis (What we adopt)

## Adopt
1. **Segment discipline** (Noctalia + DMS): left/center/right must stay semantically distinct.
2. **Utility vs Ambient split** (Dusky pattern): urgent/system modules visually grouped before ambient extras.
3. **Composable bar groups** (DMS + iNiR): clusters should be grouped through reusable wrappers (`BarGroup`).
4. **Tokenized spacing**: one place for cluster rhythm, not ad-hoc margins.

## Avoid
1. Flat monolithic rows with no hierarchy.
2. Dense metric noise where all items look equally important.
3. Per-module literal spacing hardcodes.

---

## 4) Chosen Direction — "Mission Spine v1"

A compact mission-control bar with three visual lanes:

1. **Primary lane (interaction):** left monogram/active window + center workspaces/clock + right sidebar trigger.
2. **Utility lane (high priority):** timer, shell updates, tray in tight clustered chips.
3. **Ambient lane (low priority):** weather + mini-rings in subdued grouped cards.

Information priority order (right side):
1) action/state warnings, 2) utility/system controls, 3) ambient context.

---

## 5) iNiR Nomenclature Mapping

No rename churn. We keep iNiR language:
- `BarContent.qml` remains orchestrator
- `BarGroup.qml` remains grouping primitive
- `ClockWidget.qml` remains mission time primitive
- `TimerIndicator`, `ShellUpdateIndicator`, `SysTray`, `WeatherBar`, `MiniRings` remain feature modules

New naming inside spec only (for design reasoning):
- **Utility Cluster** = timer + updates + tray
- **Ambient Cluster** = weather + mini-rings
- **Mission Cluster** = clock + util buttons + battery center stack

---

## 6) Implementation Spec (Iteration A)

### File targets
- `modules/bar/BarContent.qml`
- `modules/bar/ClockWidget.qml`

### Token pass
- `sideClusterGap: 10` (was 8)
- `centerSegmentGap: 8` (was 6)
- `missionClusterPadding: 6` (was 4)
- add `utilityClusterPadding: 4`
- add `ambientClusterPadding: 4`

### Cluster pass
- Wrap `TimerIndicator`, `ShellUpdateIndicator`, and `SysTray` each inside `BarGroup` with `utilityClusterPadding`.
- Keep weather + mini-rings grouped, but switch them to tokenized ambient padding.

### Clock hierarchy pass
- Increase `ClockWidget` horizontal breathing (`spacing: 6`).
- Promote time line hierarchy:
  - size `large -> larger`
  - weight `DemiBold -> Bold`
  - letter spacing `0.8 -> 0.9`

---

## 7) Acceptance Criteria

1. Right-side modules read as three tiers: trigger/alerts -> utility cluster -> ambient cluster.
2. Clock time line is visibly dominant over date line.
3. Spacing is tokenized and tunable from one location.
4. No QML syntax regressions.

---

## 8) Validation

- `qmllint` on touched files must pass.
- Runtime launch test in this terminal environment is limited by display availability (headless xcb plugin failure expected); syntax is still validated.

---

## 9) Iteration B (User-selected): Dusky Horizontal Preference

Applied after user selected **Dusky waybar horizontal** as preferred direction.

Changes implemented:
- tightened bar rhythm to compact/block profile:
  - `sideClusterGap: 6`
  - `centerSegmentGap: 4`
  - `missionClusterPadding: 4`
  - `utilityClusterPadding: 3`
  - `ambientClusterPadding: 3`
- tightened `BarGroup` geometry for block-like modules:
  - default `padding: 4` (from 5)
  - horizontal margins `3px` (from 4)

Effect:
- denser, cleaner horizontal scan path
- reduced visual floatiness
- better alignment with Dusky horizontal block aesthetic while preserving iNiR architecture and names

## 10) Iteration C (Implemented): Density Presets

Implemented `bar.density` presets with runtime-safe fallbacks:
- `compact`
- `default`
- `airy`

### Config wiring
- Added `bar.density` in `modules/common/Config.qml`.
- Set default profile in `defaults/config.json` to `"compact"` (matching user's Dusky-horizontal preference).

### Runtime behavior
- `BarContent.qml` now computes spacing tokens from `bar.density`:
  - `sideClusterGap`
  - `centerSegmentGap`
  - `missionClusterPadding`
  - `utilityClusterPadding`
  - `ambientClusterPadding`
- `BarGroup.qml` now scales group geometry by density:
  - `padding`
  - block margins
  - `columnSpacing`
- `ClockWidget.qml` now scales:
  - row spacing
  - date divider height

### Effective values
- **compact:** tighter, Dusky-like horizontal blocks
- **default:** balanced daily-driver rhythm
- **airy:** more breathing room for larger displays

## 11) Iteration D (Implemented): Visual Presets

Implemented `bar.stylePreset` presets with runtime-safe fallbacks:
- `dusky` (default)
- `clean`
- `glass`

### Config wiring
- Added `bar.stylePreset` in `modules/common/Config.qml`.
- Set default scaffold preset in `defaults/config.json` to `"dusky"`.
- Set active user profile in `~/.config/illogical-impulse/config.json` to `"dusky"`.

### Runtime behavior
- `BarGroup.qml` now applies visual-language tokens from `bar.stylePreset`:
  - background opacity
  - border weight/color strategy
  - corner radius attitude (crisper clean, softer glass)
- `ClockWidget.qml` now adjusts typography feel by preset:
  - time line weight/letter-spacing
  - date separator weight/opacity
  - date line weight/letter-spacing
- `BarContent.qml` now applies style tokens to right trigger chip:
  - chip interior padding
  - indicator run spacing
  - hover background alpha

### Effective character
- **dusky:** grounded, opaque, compact command-strip feel.
- **clean:** crisper separators and flatter typography for legibility-first UI.
- **glass:** softer, translucent grouping with lighter dividers and a more atmospheric feel.

## 12) Iteration E (Implemented): Lane Finalization

Completed the finishing pass for right-side architecture and narrow-screen behavior.

### What was added
- `bar.laneSeparator`: `off | subtle | strong`
- `bar.ambientVisibility`: `auto | always | hidden`

### Runtime behavior
- Added a dedicated `AmbientLaneSeparator` component in `BarContent.qml`.
- Separator now sits between utility lane and ambient tail (instead of only between weather/rings).
- Ambient lane now has overflow policy:
  - `auto` → hide ambient tail on shortened layouts
  - `always` → keep ambient tail visible
  - `hidden` → suppress ambient tail regardless of width
- Right sidebar indicator chip now has explicit alert/status sub-cluster break via divider reveal when alert indicators are active.
- SysTray utility cluster now collapses cleanly when hidden to avoid dead spacing.

### Settings exposure
- Added controls in both:
  - `modules/settings/BarConfig.qml`
  - `modules/settings/QuickConfig.qml`
- New selectors:
  - Lane separator
  - Ambient lane

### Outcome
- More deterministic right-lane hierarchy under width pressure.
- Better visual separation between utility vs ambient telemetry.
- Cleaner indicator information architecture without losing existing module semantics.

## 13) Iteration F (Implemented): Ship Polish

Completed final readability polish for the right sidebar indicator chip.

### What was added
- Per-preset icon sizing profile in `BarContent.qml`:
  - `rightIndicatorIconSize` mapped by `bar.stylePreset`
- Calendar chip compact behavior tokens:
  - `calendarTextPixelSize`
  - `calendarTitleMaxChars` (aware of shortened form + density)

### Runtime behavior
- Right-chip alert/status icons now scale with visual preset:
  - **clean**: slightly tighter icon footprint
  - **dusky**: baseline dense profile
  - **glass**: slightly larger icon footprint for airy read
- Calendar title truncation now adapts to width pressure:
  - stronger truncation in hella-shortened/shortened layouts
  - moderate truncation in compact density
  - fuller title retention in default/airy full-width states
- Calendar title + delta text sizing now adapts to compact/narrow contexts.

### Outcome
- Better preset identity at a glance (not just spacing/opacity differences).
- More stable indicator readability under narrow-width stress.
- Cleaner calendar chip behavior without overflow noise.

## 14) Iteration G (Implemented): Hard Dusky Horizontal Lock

Applied to align more directly with the Dusky horizontal reference posture (feature-light visual read, dense horizontal blocks first).

### Defaults shifted
- `bar.laneSeparator`: `off`
- `bar.ambientVisibility`: `hidden`
- Kept `bar.stylePreset: dusky` and `bar.density: compact`

### Rhythm tightening
- Compact token pass in `BarContent.qml`:
  - `sideClusterGap: 5`
  - `centerSegmentGap: 3`
  - `missionClusterPadding: 3`
  - `utilityClusterPadding: 2`
  - `ambientClusterPadding: 2`
- Right chip compacted for dusky profile:
  - tighter chip interior padding
  - reduced indicator spacing (`rightIndicatorSpacing` dusky branch tightened)
- Calendar title truncation tightened in compact mode for cleaner right-edge scan.

### Settings guidance shift
- Lane separator now labels **Off** as recommended.
- Ambient lane now labels **Hidden** as recommended.

### Outcome
- Cleaner, flatter horizontal read.
- Lower right-tail noise and less visual float.
- Closer aesthetic match to Dusky horizontal while keeping iNiR module architecture.

## 15) Next Pass (Optional)

- Add user-facing one-line preview description per visual preset in settings.
- Add optional icon-weight profile (filled vs outlined emphasis) for accessibility variants.
- Run targeted stress snapshots (shortened/hella-shortened + heavy indicator states) against the hard-lock default.
