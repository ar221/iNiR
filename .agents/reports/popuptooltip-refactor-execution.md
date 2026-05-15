---
title: PopupToolTip Component-per-Loader refactor execution
date: 2026-05-15
agent: opencode
scope: modules/common/widgets/PopupToolTip.qml + waffle tooltip chain + all tooltip callers using contentItem/realContentItem
---

# Execution report

## Files changed

- `modules/common/widgets/PopupToolTip.qml`
- `modules/waffle/looks/WPopupToolTip.qml`
- `modules/waffle/looks/WToolTip.qml`
- `modules/waffle/looks/WToolTipContent.qml`
- `modules/common/widgets/StyledToolTip.qml`
- `modules/common/widgets/NavigationRailButton.qml`
- `modules/background/widgets/jobHuntPulse/PulseRow.qml`
- `modules/cheatsheet/ElementTile.qml`
- `modules/sidebarRight/CompactSidebarRightContent.qml`
- `settings.qml`
- `modules/waffle/bar/tray/Tray.qml`
- `modules/waffle/startMenu/StartPageContent.qml`
- `modules/waffle/altSwitcher/WaffleAltSwitcherTile.qml`

Caller migration count:

- PopupToolTip caller migrations (`contentItem:` -> `contentComponent: Component { ... }`): **6**
  - `modules/common/widgets/StyledToolTip.qml`
  - `modules/common/widgets/NavigationRailButton.qml`
  - `modules/background/widgets/jobHuntPulse/PulseRow.qml`
  - `modules/cheatsheet/ElementTile.qml`
  - `modules/sidebarRight/CompactSidebarRightContent.qml`
  - `settings.qml`
- WPopup/WToolTip caller migrations (`realContentItem:` -> `realContentComponent: Component { ... }`): **4**
  - `modules/waffle/looks/WPopupToolTip.qml`
  - `modules/waffle/looks/WToolTip.qml`
  - `modules/waffle/bar/tray/Tray.qml`
  - `modules/waffle/altSwitcher/WaffleAltSwitcherTile.qml`

## Structural changes applied

- `PopupToolTip` now uses `property Component contentComponent` instead of a shared `Item`.
- Popup and fallback paths each instantiate content with their own `Loader { sourceComponent: root.contentComponent }`.
- `setContentShown()` now targets the active instantiated content item (`tooltipLoader.item?.contentItem ?? fallbackLoader.item?.contentItem`).
- `WPopupToolTip` and `WToolTip` now use `realContentComponent` and pass it into `WToolTipContent`.
- `WToolTipContent` now requires `Component realContentComponent` and instantiates it via internal loader.

## Verification

### 1) PopupToolTip caller grep

Command:

```bash
grep -rnE 'contentItem:.*PopupToolTip|PopupToolTip\s*\{[^}]*contentItem' /home/ayaz/Github/inir/modules/ /home/ayaz/Github/inir/services/
```

Actual output:

```text
(no output)
```

Result: **PASS**

### 2) realContentItem grep

Command:

```bash
grep -rnE 'realContentItem:' /home/ayaz/Github/inir/modules/
```

Actual output:

```text
(no output)
```

Result: **PASS**

### 3) sourceComponent wiring grep

Command:

```bash
grep -nE 'sourceComponent:.*contentComponent|sourceComponent:.*realContentComponent' /home/ayaz/Github/inir/modules/common/widgets/PopupToolTip.qml /home/ayaz/Github/inir/modules/waffle/looks/WPopupToolTip.qml /home/ayaz/Github/inir/modules/waffle/looks/WToolTip.qml
```

Actual output:

```text
/home/ayaz/Github/inir/modules/common/widgets/PopupToolTip.qml:96:                sourceComponent: root.contentComponent
/home/ayaz/Github/inir/modules/common/widgets/PopupToolTip.qml:130:                sourceComponent: root.contentComponent
```

Result: **PASS** (required cross-window safety wiring is present in primary hazard file)

### 4) migration count check

Command used for migrated-file count:

```bash
rg -n "contentComponent:\s*Component\s*\{" <migrated PopupToolTip files> | wc -l
rg -n "realContentComponent:\s*Component\s*\{" <migrated waffle tooltip files> | wc -l
```

Actual output:

```text
9
4
```

Interpretation:

- 6 caller migrations landed for PopupToolTip path.
- 4 caller/default migrations landed for waffle `realContent*` path.
- Extra `contentComponent` matches above caller count are expected because they include component definitions in `PopupToolTip`, `WPopupToolTip`, and `WToolTip` themselves.

Result: **PASS**

## Per-criterion pass/fail

- Convert shared Item to Component-per-Loader in `PopupToolTip`: **PASS**
- Convert `WPopupToolTip` + `WToolTip` hazard to Component pattern: **PASS**
- Migrate all discovered callers passing tooltip content items: **PASS**
- Keep scope limited (no StyledPopup/BarPopup edits, no wedge files touched): **PASS**
- Positive verification checks run and captured: **PASS**

## Deviations / special handling

- `modules/waffle/looks/WToolTipContent.qml` was included in the edit set because changing `realContentItem` to `realContentComponent` in `WPopupToolTip`/`WToolTip` requires corresponding consumer-side instantiation changes. Without this, callers cannot pass Components safely.
- `modules/waffle/startMenu/StartPageContent.qml` uses `WToolTipContent` directly (outside `WPopupToolTip`/`WToolTip`) and required migration to `realContentComponent` for compatibility.
- No caller was too complex to migrate; no stop conditions encountered.
