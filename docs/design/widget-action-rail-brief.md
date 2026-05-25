---
type: design-brief
project: iNiR
surface: CommandRoom widget
status: active
created: "2026-05-24"
updated: "2026-05-24"
tags: [design-brief, command-room, action-rail, session-log, courier-console]
---

# CommandRoom Widget — Pipeline Layer + Action Rail + Session Log

> **Design language:** Courier Console. Square-edged, receipt-driven, warm-terminal dispatch board. Mission tiers, not Kanban columns. Every action leaves a receipt.

---

## 1. Pipeline-Layer Layout

### Organizing Principle

Stages are **mission tiers**, not swim lanes. The precedent is a dispatch board where the board header carries tier identity (a label + count badge) and the cards below it are ledger rows, not floaty SaaS cards.

**Layout approach:** vertical section headers as hard separators — a full-width 1px `Appearance.colors.colLayer0Border` rule preceded by an uppercase micro-label and a count badge.

```
┌─────────────────────────────────────────────┐
│ COMMAND ROOM           ● FRESH / 2m ago      │
├─────────────────────────────────────────────┤
│ IN PROGRESS  [2]                            │
├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
│  card…                                      │
│  card…                                      │
├─────────────────────────────────────────────┤
│ PENDING  [4]                                │
├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
│  card…                                      │
│  + ADD TASK                                 │
├─────────────────────────────────────────────┤
│ STALE  [1]                 ▲ amber rail     │
├─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
│  card…                                      │
├─────────────────────────────────────────────┤
│ ANOMALY  [2]               ▲ error rail     │
└─────────────────────────────────────────────┘
```

### Section Headers

Each tier header is a `RowLayout`:
- Left: uppercase micro-label (`font.family: Appearance.font.family.monospace`, `font.pixelSize: Appearance.font.pixelSize.smallest`, `font.letterSpacing: 1.4`)
- Right: count badge — a small rect with `radius: 2`, filled with the tier color at 14% opacity, bordered at 55% opacity

**Tier color mapping:**
| Stage | Color token | Role |
|-------|------------|------|
| `in_progress` | `Appearance.colors.colPrimary` | amber/active |
| `pending` | `Appearance.colors.colOnLayer0` | neutral/cream |
| `stale` | `Appearance.colors.colTertiary` | warning |
| `anomaly` | `Appearance.colors.colError` | alarm |
| `done` | `Appearance.colors.colSubtext` | quiet/resolved |

The tier header full-width separator uses `Appearance.colors.colLayer0Border` at 60% opacity — thin enough to not fight the card borders.

### Visible Stages

Show: `in_progress`, `pending`, `stale`, `anomaly`. In that order — priority from top.

**`done` items:** collapsed by default behind a `RESOLVED [N]` section footer at the bottom of the widget, shown only as a count. Single tap/click expands to a compact ledger of the last 5 completed tasks. Done items do not get action rails — they are read-only receipts.

Stale and anomaly sections are hidden entirely when count = 0. In_progress and pending sections always render (they show the empty state when count = 0).

### Column Headers vs. Dividers

No column headers. This is a single-column ledger, not a multi-column table. Section identity comes from tier headers. Cards in each tier share the same anatomy — the tier header is all the orientation needed.

---

## 2. Action Rail Anatomy

### Reveal Pattern

**Hover reveal.** The rail is hidden at rest; appears on `MouseArea` enter with a 150ms fade-in (`--motion-xs`). At rest, card height is compact — 2-line ledger row. On hover, rail slots into the bottom of the card body without reflowing the card height — use an `implicitHeight` expansion or a fixed footer slot that fades in with `opacity`.

Why hover-reveal: the widget lives on the desktop background (read: at-a-glance surface). Always-visible rails add visual weight that fights the board's scanning rhythm. Hover-reveal keeps cards clean at a distance; they become operational on approach.

### Promote

**Fire-and-forget.** One tap moves task `pending → in_progress`. No confirmation required.

Visual confirmation: a brief inline flash — card border briefly intensifies to `Appearance.colors.colPrimary` at 100% opacity for 300ms then returns to normal, paired with the tier section instantly relocating the card to IN PROGRESS. The relocation IS the confirmation — Courier Console proof through observation, not dialog.

Icon: `"chevron_right"` or `"play_arrow"` from Material Symbols. Monochrome (`Appearance.colors.colPrimary`).

### Cancel

**Requires confirmation.** Pattern: inline expand, not modal dialog.

On cancel press: the action rail slot expands to show a confirmation strip — a narrow full-width rect (`Appearance.colors.colError` at 10% fill, `colError` 1px border) with two inline options:
- `CONFIRM CANCEL` (destructive, `colError`)
- `KEEP` (neutral, `colSubtext`)

Both are monospace text labels, not icon buttons. Strip appears with a 200ms slide-down (`--motion-sm`). Clicking outside or pressing `KEEP` collapses it. The strip lives inside the card boundary — zero overlay, zero modal, zero z-fight.

### Add Task

**Inline input at bottom of PENDING section.** A persistent `+ ADD TASK` affordance sits as the last row of the pending section — styled as a dashed 1px rect using `Appearance.colors.colOnLayer0` at 30% opacity, full card width, 32px height, monospace text `"+ ADD TASK"` centered in `colSubtext`.

On activation: the dashed row expands to a single-line text input (monospace font, `colOnLayer0` text on `colLayer1` background, 1px `colPrimary` border on focus). Enter submits, Escape cancels. No secondary fields on this surface — title only; the agent or vault pipeline fills the rest.

No dedicated "add card" at the end of any other section.

---

## 3. Session Log View

### Scope

In-progress cards only. The log panel is an **expandable footer** below the card body — collapsed by default, expandable via a log-toggle in the card's action rail (or a dedicated expand control on the card bottom edge).

### Visible Lines at Rest

**Collapsed:** 0 lines — log is invisible. The card shows a `LOG ▸` affordance at the bottom edge in `colSubtext` monospace micro-text.

**Expanded default:** 5 lines. Fixed height: `5 × lineHeight + 8px top/bottom padding`. The panel does not auto-expand to fit — it is a scrollable bounded rectangle.

**Scroll behavior:** `Flickable` with a vertical scrollbar that appears on hover. Scroll is internal to the log panel — it does not propagate to the card list.

### Log Text Treatment

Terminal output → monospace, `Appearance.font.family.monospace`, `font.pixelSize: Appearance.font.pixelSize.smallest`, `color: Appearance.colors.colOnLayer0`.

**Background:** `Appearance.colors.colLayer0` (deepest surface) — the log panel is visually recessed relative to the card body. This distinguishes "card metadata" from "live telemetry output."

**Border:** left rail only — 2px `Appearance.colors.colPrimary` at 70% opacity on the left edge of the log panel. This is the Courier Console inset-ledger signal: "this content lives inside this panel."

### Mission Telemetry Treatment

This is mission telemetry. It changes three things:

1. **Timestamp column.** Each log line has a leading `HH:MM:SS` or relative `+0.3s` timestamp in `colSubtext` at fixed width (tabular alignment using monospace). The timestamp reads like a mission clock, not a console dump.

2. **Semantic line coloring.** Lines beginning with `ERROR`/`FAIL`/`✗` get `colError`. Lines with `WARN`/`⚠` get `colTertiary`. Lines with `OK`/`DONE`/`✓` get `colPrimary` (amber/green). All other lines: `colOnLayer0`.

3. **Scanline texture.** Subtle 3-on/4-off horizontal line-grid at 4% opacity behind the log panel only — gives it the instrument-cluster texture without affecting readability. Applied as a `Rectangle` overlay with a `repeating-linear-gradient`, not a shader.

---

## 4. Action Button Visual Grammar

### Icon Style

**Material Symbols, outlined weight.** Not filled, not rounded. Outlined weight reads as tool/instrument rather than decorative icon.

Allowed actions per rail slot:
| Action | Icon name | Color |
|--------|-----------|-------|
| Promote | `play_arrow` | `Appearance.colors.colPrimary` |
| Cancel | `cancel` | `Appearance.colors.colError` |
| Add (log expand) | `terminal` | `Appearance.colors.colSubtext` |
| Collapse log | `expand_less` | `Appearance.colors.colSubtext` |

**No mixed icon + text labels in the rail.** Pick one. For this widget: icon-only in the action rail, text-only in the cancel confirmation strip. The register distinction matters — icons are affordances, text is operational language.

### Size

Icon buttons: `24px` icon inside a `32×32` hit target. Rail height: `32px`. Compact enough to not shift card height perceptibly when it appears.

### States

| State | Treatment |
|-------|-----------|
| Rest | `opacity: 0` (hidden) |
| Rail visible (hover) | `opacity: 1`, 150ms fade |
| Button hover | `colLayer2` background fill, `border-radius: 2px` |
| Button pressed | `colLayer3Active` fill, scale `0.95` for 100ms |
| Disabled | `opacity: 0.38`, no hover |

### Color Token Mapping (minimum 3 named)

1. **`Appearance.colors.colPrimary`** — promote action, tier accent for IN PROGRESS header, active card border flash confirmation, log-panel left rail
2. **`Appearance.colors.colError`** — cancel action, ANOMALY tier header + badge, cancel confirmation strip border + text
3. **`Appearance.colors.colTertiary`** — STALE tier header + badge, stale count in MetricPill, timestamp/warning log lines
4. **`Appearance.colors.colLayer0`** — log panel recessed background (deepest surface)
5. **`Appearance.colors.colSubtext`** — ADD TASK placeholder text, LOG toggle affordance, inactive/quiet icon states

---

## 5. Courier Console Consistency Check

### Anti-Pattern: Rounded Pill Buttons in the Action Rail

**Named violation:** using `radius: 12px+` button containers in the action rail — e.g. a soft pill-shaped "Promote" or "Cancel" button.

**Why it breaks the brand:** pill shapes signal SaaS/Material-You touch affordances. The Courier Console rule is square by default, `0–4px` radius maximum for structural elements. A pill button in a terminal dispatch board reads as decorative interface, not command hardware. It collapses the tension between retrofuturism and modern flair by importing the modern lane's friendly rounding into a surface that should feel operational and square.

**What to do instead:** action rail buttons are borderless `32×32` square hit targets. On hover they receive a `colLayer2` background fill with `radius: 2px` — just enough to prevent hard-corner pixel artifacts on small controls, not enough to read as a pill. The visual language is: crosshair bracket, not capsule.

---

## 6. Compact / Narrow Fallback

### Collapse Priority (width reduction order)

| Width threshold | What collapses |
|----------------|----------------|
| `< 380px` | Session log panel hidden entirely; LOG toggle removed from action rail |
| `< 320px` | Action rail collapses to single icon (most urgent: promote for in_progress, cancel for stale/anomaly); ADD TASK text truncates to `+` |
| `< 280px` | Tier section headers lose count badge; tier label shortens (`IN PROGRESS → RUNNING`, `PENDING → QUEUE`, `ANOMALY → ALERT`) |
| `< 240px` | Card body collapses to title + status dot only; summary/owner hidden; action rail hidden entirely |

### What Must Survive at All Widths

- Task title (elided with `Text.ElideRight`, never wrapped)
- Status dot (the colored circle that encodes tier state)
- Section tier label
- Widget header (`COMMAND ROOM` + freshness badge)

### Narrow as Dispatch Packet

At `< 320px`, the widget reads as a status strip: title list + tier dots. No board layout ceremony. The packet communicates state at a glance; action requires expanding to full width. This follows the Courier Console mobile rule: **desktop = command board, narrow = dispatch packet**.

---

## Implementation Notes for Artemis

- Tier section headers: `ColumnLayout` wrapping `[separator rect][RowLayout tier label + count badge][card repeater]`
- Action rail: a `RowLayout` anchored to `card.bottom` with `opacity: hoverArea.containsMouse ? 1 : 0` and `Behavior on opacity { NumberAnimation { duration: 150 } }`
- Cancel confirmation strip: a `ColumnLayout` child of the card with `visible: cancelPending`, `clip: true`, height animated with `Behavior on implicitHeight`
- Session log panel: a `Rectangle` with `Appearance.colors.colLayer0` fill, `clip: true`, fixed `implicitHeight: 5 * logLineHeight + 16`, containing a `Flickable` → `ColumnLayout` of log line rows
- Log line row: `RowLayout` of `[timestamp StyledText][message StyledText]`
- Scanline texture: `Rectangle { anchors.fill: parent; opacity: 0.04; gradient: repeating-linear-gradient(...) }` layered above log background, below log text

**Do not implement.** This brief is the spec. Route to artemis for QML execution.

---

## Courier Console Self-Test (Before Shipping)

1. What state does this surface show? → pipeline tier + task identity + log telemetry
2. Who owns the lane? → CommandRoom service, read from projection JSONL
3. What is the source of truth? → `CommandRoom.cards`, `CommandRoom.openTasks`, `CommandRoom.anomalies`
4. What action can Ayaz take? → promote, cancel, add, expand log
5. Where does that action leave a receipt? → task state change visible immediately in tier relocation; cancel requires JSONL writeback
6. Does the geometry read as command hardware? → yes: square cards, tier ledger headers, recessed log panel, 2px left rail
