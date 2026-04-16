# Bar & Command Center Dashboard Redesign

**Date:** 2026-04-16
**Status:** Approved
**Scope:** Bar visual overhaul + new Command Center Dashboard

---

## Overview

A two-part redesign of iNiR's primary status surface. The bar gets a visual overhaul adopting the "Organic Flow" aesthetic — gradient arc rings, warm color palette, instrument-cluster energy. A new Command Center Dashboard replaces the monogram's left-sidebar trigger, providing a full-screen overlay with profile identity, system performance, activity console, and quick controls.

### Design Principles

1. **Organic Flow aesthetic** — gradient arcs, warm sunset-to-pink tones, glowing indicators, translucent layered glass. The bar should feel alive, not clinical.
2. **Warmth over sterility** — every element should evoke comfort. Color temperature skews warm (amber, orange, pink), with cool accents (blue, cyan, green) reserved for specific metrics.
3. **Everything configurable** — every bar element and dashboard section can be toggled on/off via `config.json` settings. This is non-negotiable and applies to all design choices.
4. **Scanability first** — information communicates through shape, color, and position, not just text. A glance should tell you what's happening without reading labels.
5. **Graceful overflow** — text never clips, pushes, or overflows into adjacent elements. Long content fades out via CSS/QML mask gradients.

---

## Part 1: Bar Overhaul

### Layout Structure

The bar uses a three-section layout with flexible spacers ensuring the center section stays centered regardless of left/right content width.

```
[LEFT]              [SPACER]  [CENTER]  [SPACER]              [RIGHT]
Monogram | Title              WS | Clock              Rings | Notif
```

### Height

Increase from current ~44px to **52-56px**. The taller bar gives mini-rings vertical breathing room, makes the monogram feel substantial, and allows comfortable text line-height for the active window title.

### Left Section

| Element | Behavior |
|---------|----------|
| **Monogram** | 30px circular avatar with `linear-gradient(135deg, #fb923c, #f472b6)` background. Glow shadow on idle (`0 0 12px rgba(251,146,60,0.25)`), intensifies on hover. **Left-click opens Command Center Dashboard.** |
| **Separator** | 1px vertical line, `rgba(255,255,255,0.06)`, 18px tall. |
| **Active window title** | Current focused window's app name + title. Font: 11px, weight 400, color `rgba(255,255,255,0.45)`. |

**Active window overflow handling:**
- The left section has a bounded max-width (~280px, configurable) so it can never push into the center.
- Long titles fade out via a gradient mask: `mask-image: linear-gradient(to right, black 80%, transparent 100%)`. No hard ellipsis, no clipping.
- The section uses `min-width: 0` and `overflow: hidden` with `white-space: nowrap`.

### Center Section

| Element | Behavior |
|---------|----------|
| **Workspaces** | Pill container (`rgba(255,255,255,0.03)` background, 12px border-radius) with individual workspace indicators. Active workspace gets a warm gradient background (`rgba(251,146,60,0.2)` to `rgba(244,114,182,0.2)`) and golden text (#fbbf24). Occupied workspaces are brighter than empty ones. |
| **Separator** | Same as left section separator. |
| **Clock + Date** | Time in 13px weight 500 white. Date in 10px weight 400 `rgba(255,255,255,0.35)` to the right of time. Both on one line: `3:42 Wed, Apr 16`. |

### Right Section

| Element | Behavior |
|---------|----------|
| **Mini-rings** | Four gradient-arc ring indicators for CPU, GPU, Temp, RAM (see Ring Spec below). Arranged in a row with 12px gap. |
| **Separator** | Same style. |
| **Notification bell** | Bell icon, `rgba(255,255,255,0.45)`, brightens on hover. Unread badge: 12px pink circle (#f472b6) with count, positioned top-right, with glow shadow. |

### Mini-Ring Specification

Each mini-ring is a 28px SVG circle:
- **Track:** `rgba(255,255,255,0.06)`, stroke-width 3
- **Fill arc:** Gradient stroke, stroke-width 3, `stroke-linecap: round`, dash-array proportional to value
- **Center value:** 8px bold text showing the numeric value
- **Label:** 7px uppercase text below the ring (e.g., "CPU", "GPU", "TMP", "RAM")

**Color assignments (gradient start → end):**
| Metric | Gradient | Glow |
|--------|----------|------|
| CPU | `#fb923c` → `#f472b6` (orange → pink) | `rgba(251,146,60,0.25)` |
| GPU | `#38bdf8` → `#818cf8` (sky → indigo) | `rgba(56,189,248,0.25)` |
| Temp | `#4ade80` → `#22d3ee` (green → cyan) | `rgba(74,222,128,0.25)` |
| RAM | `#c084fc` → `#f472b6` (purple → pink) | `rgba(192,132,252,0.25)` |

These colors shift dynamically with warning thresholds (existing `tempCautionThreshold`, `cpuWarningThreshold`, etc.) — rings shift toward red/hot gradients when values are critical.

### Bar Background & Chrome

- Background: `rgba(16,16,28,0.92)` with `backdrop-filter: blur(20px)`
- Border: 1px `rgba(255,255,255,0.05)`
- Border-radius: 22px (floating style)
- Shadow: `0 8px 32px rgba(0,0,0,0.4)`
- Existing corner style config (`bar.cornerStyle`) continues to work — the above values are for the default Float style.

### Left Sidebar Re-homing

The monogram no longer triggers the left sidebar. New interaction model:

| Trigger | Action |
|---------|--------|
| **Monogram left-click** | Opens Command Center Dashboard |
| **Screen edge hover/pull** | Left sidebar slides out with a smooth animation. An invisible hover zone (~4px wide) at the left screen edge triggers a subtle pull-tab indicator; continuing to move the mouse inward (or clicking the zone) opens the sidebar fully. The hover zone width should be configurable (`sidebar.left.edgeZoneWidth`). |
| **Keyboard shortcut** | Left sidebar toggle (unchanged from current binding) |
| **Monogram right-click** | Available for context menu or freed up entirely (TBD during implementation) |

The edge pull interaction should feel tactile — the sidebar is spatially "over there" at the edge, and the user physically goes to get it. Animation: sidebar slides in from left with an eased curve (200-300ms).

### Config Keys (New/Modified)

All under `bar.*` namespace:

```json
{
  "bar.height": 54,
  "bar.modules.activeWindow": true,
  "bar.modules.monogram": true,
  "bar.activeWindow.maxWidth": 280,
  "bar.activeWindow.fadeOverflow": true,
  "bar.rings.showLabels": true,
  "bar.rings.cpu": true,
  "bar.rings.gpu": true,
  "bar.rings.temp": true,
  "bar.rings.ram": true
}
```

Existing config keys (`bar.modules.workspaces`, `bar.modules.clock`, `bar.indicators.notifications.showUnreadCount`, etc.) remain unchanged.

### Elements Removed from Bar (Moved or Opt-In)

These are no longer shown by default. They move to the dashboard, remain in sidebars, or become opt-in via settings:

- Media controls → Dashboard (Now Playing card)
- Util buttons (screenshot, record, color picker, notepad, keyboard, dark mode, performance profile) → Dashboard quick toggles or sidebar
- Weather → Dashboard
- System tray → Stays in bar as opt-in (`bar.modules.sysTray: false` by default)
- Timer indicator → Stays in bar as opt-in
- Shell update indicator → Dashboard or bar opt-in
- Focus mode indicator → Bar opt-in
- Keyboard layout indicator → Removed from bar, available in dashboard system info
- Calendar event preview → Dashboard calendar section

---

## Part 2: Command Center Dashboard

### Behavior

| Property | Value |
|----------|-------|
| **Trigger** | Monogram left-click (toggle) |
| **Entry animation** | Flies in from the top of the screen with an eased deceleration curve (~300-400ms) |
| **Exit animation** | Flies back up or fades out (~200-250ms) |
| **Size** | ~60-70% of screen width, tall enough to show all content without scrolling (~70-80% of screen height) |
| **Position** | Center-screen, vertically offset slightly toward top (closer to the bar it came from) |
| **Backdrop** | Rest of screen dims (`rgba(0,0,0,0.4-0.5)`) with blur |
| **Dismiss** | Click backdrop, press Escape, or click monogram again |
| **Keyboard shortcut** | Should have a dedicated keybind for power users (configurable) |

### Layout: Three-Column Grid

```
grid-template-columns: 260px 1fr 240px
gap: 20px
```

### Left Column (260px) — Identity & Controls

#### Profile Card
- Large avatar (72px circle) with the same gradient as the bar monogram, plus an outer glow
- Display name: "Lord Rashid" (18px, weight 600)
- Subtitle: `ayaz@cachyos · niri · fish` (11px, `rgba(255,255,255,0.35)`)
- Configurable: name, subtitle format, avatar image (falls back to monogram initial)

#### System Info Card
Neofetch-style key-value pairs:
- Uptime
- Kernel
- Packages (count)
- Shell
- GPU
- WM

Each row: label left-aligned (uppercase, 11px, dim), value right-aligned (11px, brighter). Separated by subtle 1px borders.

#### Quick Toggles Card
3-column grid of toggle buttons:
- DND (Do Not Disturb)
- Dark Mode
- WiFi
- Performance Profile
- Bluetooth
- Screen Cast

Each toggle: rounded card (12px radius), icon + label. Active state gets the warm gradient background with golden label text. Toggles map to existing iNiR service calls (NotificationService, NetworkService, etc.).

Configurable: which toggles appear, grid columns.

#### Media Player Card
- Album art thumbnail (52px, rounded)
- Track title + artist
- Playback controls (previous, play/pause, next)
- Only visible when a media player is active (contextual, same as existing `bar.modules.mediaContextual` behavior)

### Center Column (flex) — Performance & Activity

#### Performance Bar Charts Card
Five vertical bar chart columns:

| Metric | Gradient (bottom → top) | Glow |
|--------|------------------------|------|
| CPU | `rgba(251,146,60,0.15)` → `rgba(251,146,60,0.4)` | `rgba(251,146,60,0.15)` |
| GPU | `rgba(56,189,248,0.15)` → `rgba(56,189,248,0.4)` | `rgba(56,189,248,0.15)` |
| RAM | `rgba(192,132,252,0.15)` → `rgba(192,132,252,0.4)` | `rgba(192,132,252,0.15)` |
| Temp | `rgba(74,222,128,0.15)` → `rgba(74,222,128,0.4)` | `rgba(74,222,128,0.15)` |
| Disk | `rgba(251,191,36,0.15)` → `rgba(251,191,36,0.4)` | `rgba(251,191,36,0.15)` |

Each bar:
- Track: full-height rounded rectangle (`rgba(255,255,255,0.02)` fill, 1px `rgba(255,255,255,0.03)` border, 12px radius)
- Fill: anchored to bottom, height proportional to value, gradient fill with inner glow and subtle border
- Value label: positioned just above the fill, showing number + unit (e.g., "42%", "38°")
- Name label: below the track, 9px uppercase

Bar height: ~160-200px. Bars animate on value change with a smooth easing (~600ms cubic-bezier).

Configurable: which metrics to show, warning thresholds (reuse existing config keys).

#### Network & I/O Sparklines Card
Three sparkline rows:
- Download speed (blue: `rgba(56,189,248,0.5)`)
- Upload speed (pink: `rgba(244,114,182,0.5)`)
- Disk I/O (gold: `rgba(251,191,36,0.5)`)

Each row: label (left), SVG sparkline graph (center, filled area below line), current value (right). Sparklines show last ~60 seconds of data.

#### Activity Console Card
Terminal-styled activity feed occupying the remaining vertical space in the center column, below performance bars (or below sparklines if both are shown).

**Visual style:**
- Monospace font (system monospace or configured terminal font)
- Dark background matching the card style, slightly darker than other cards for contrast
- Warm dim text, color-coded by source
- Scrollable with a fade-out mask at the top edge

**Entry format:**
```
 HH:MM  source  summary                            context
 14:32  claude  Finished bar redesign spec          ~/Documents/Ayaz OS
 14:15  git     3 commits pushed                    ~/Github/inir
 13:48  claude  Crash triage on sidebar flicker      ~/Github/inir
 13:20  pacman  mesa 25.1.2 → 25.1.3 (+2 others)
 12:55  claude  Compiled 5 clippings to wiki         ~/Documents/Ayaz OS
 12:30  system  dictation-server restarted
```

**Data sources:**
| Source | Feed | Color |
|--------|------|-------|
| `claude` | `~/.claude/breadcrumbs/*.jsonl` — session summaries, task descriptions | Orange/amber (`#fbbf24`) |
| `git` | Git logs from registered repos (`~/Github/inir/`, etc.) | Pink (`#f472b6`) |
| `pacman` | `/var/log/pacman.log` — install/upgrade/remove events | Green (`#4ade80`) |
| `system` | `journalctl --user` — service events, errors | Cyan (`#22d3ee`) |

**Behavior:**
- Shows last **15 visible entries** in the viewport
- Smooth scroll to see more (up to 24 hours of history)
- Fade-out gradient mask at the top of the scroll area
- Entries are clickable: Claude entries open the project, git entries show the diff, package entries show details
- New entries slide in from the bottom with a subtle animation
- A small daemon/script tails the data sources and writes to a unified feed file (JSON lines) that the QML component watches

**Config keys:**
```json
{
  "dashboard.activityConsole.enable": true,
  "dashboard.activityConsole.maxAge": 86400,
  "dashboard.activityConsole.sources.claude": true,
  "dashboard.activityConsole.sources.git": true,
  "dashboard.activityConsole.sources.pacman": true,
  "dashboard.activityConsole.sources.system": true,
  "dashboard.activityConsole.repos": ["~/Github/inir", "~/Github/dotfiles"]
}
```

### Right Column (240px) — Calendar, Weather, Notifications

#### Calendar Card
- Hero date: large day number (32px, gradient text matching the warm palette) with month/year below (11px, dim, uppercase)
- Upcoming events: list of next 2-3 events with colored dots, title, and time
- Sources: existing iNiR calendar integration

#### Weather Card
- Current conditions: weather icon (36px with warm drop-shadow) + temperature (28px, bold) + description (11px, dim)
- Detail row: wind speed, humidity, UV index
- Sources: existing iNiR weather service

#### Notifications Card
- Scrollable list of recent notifications
- Each entry: app icon (20px rounded square) + notification text + relative timestamp
- Matches existing notification service data
- Fills remaining vertical space in the column

### Dashboard Card Styling (Shared)

All cards in the dashboard share:
- Background: `rgba(255,255,255,0.025)`
- Border: 1px `rgba(255,255,255,0.04)`, brightens to `0.08` on hover
- Border-radius: 16px
- Padding: 18px
- Section header: 10px uppercase, letter-spacing 1.5px, `rgba(255,255,255,0.3)`

### Dashboard Container Styling

- Background: `rgba(14,14,26,0.96)` with `backdrop-filter: blur(30px)`
- Border: 1px `rgba(255,255,255,0.06)`
- Border-radius: 24px
- Shadow: `0 24px 80px rgba(0,0,0,0.6), 0 0 60px rgba(251,146,60,0.03)` (subtle warm glow)
- Padding: 28px

### Dashboard Config Keys

```json
{
  "dashboard.enable": true,
  "dashboard.keybind": "",
  "dashboard.animation.duration": 350,
  "dashboard.animation.type": "flyFromTop",
  "dashboard.backdrop.blur": true,
  "dashboard.backdrop.dimOpacity": 0.45,
  "dashboard.sections.profile": true,
  "dashboard.sections.systemInfo": true,
  "dashboard.sections.quickToggles": true,
  "dashboard.sections.media": true,
  "dashboard.sections.performance": true,
  "dashboard.sections.sparklines": true,
  "dashboard.sections.activityConsole": true,
  "dashboard.sections.calendar": true,
  "dashboard.sections.weather": true,
  "dashboard.sections.notifications": true,
  "dashboard.profile.displayName": "Lord Rashid",
  "dashboard.profile.subtitle": "{user}@{hostname} · {wm} · {shell}",
  "dashboard.profile.avatarPath": ""
}
```

---

## Material You Integration

All hardcoded colors in this spec are defaults. In production, colors derive from the Material You theming pipeline:

- Gradient accent colors map to `colPrimary`, `colSecondary`, `colTertiary` from the active theme
- The warm orange/pink palette is the default when no wallpaper theme is active
- Ring colors for different metrics should use distinct palette slots to maintain visual separation across any theme
- Card backgrounds, borders, and text opacities follow the existing Appearance.qml opacity system

---

## Files Affected

### New Files
- `modules/bar/MiniRing.qml` — Reusable gradient arc ring component
- `modules/bar/ActivityConsole.qml` — Terminal-styled activity feed component
- `modules/dashboard/Dashboard.qml` — Main dashboard overlay window
- `modules/dashboard/DashboardContent.qml` — Three-column layout container
- `modules/dashboard/ProfileCard.qml` — Profile/identity card
- `modules/dashboard/SystemInfoCard.qml` — Neofetch-style system info
- `modules/dashboard/QuickToggles.qml` — Toggle grid
- `modules/dashboard/PerformanceBars.qml` — Bar chart performance display
- `modules/dashboard/ActivityFeed.qml` — Activity console content/data
- `scripts/activity-feed-daemon.py` — Python daemon that tails data sources (breadcrumbs, git logs, pacman log, journalctl) and writes a unified JSON lines feed file watched by the QML component

### Modified Files
- `modules/bar/BarContent.qml` — Restructured layout, new elements, removed defaults
- `modules/bar/Bar.qml` — Height adjustment, monogram click target change
- `modules/bar/Resources.qml` — Replaced with MiniRing components
- `modules/common/Config.qml` — New config key registrations
- `defaults/config.json` — New default values for all config keys above
- `shell.qml` — Dashboard initialization
- `GlobalStates.qml` — Dashboard open/close state toggle

### Removed/Deprecated
- `modules/bar/dashboard/` — Old dashboard tab system (DashboardTab, MediaTab, PerformanceTab, NiriTab, NetworkSparkline) superseded by new Command Center

---

## Mockups

Visual mockups created during brainstorming are preserved at:
- `.superpowers/brainstorm/284669-1776368031/content/aesthetic-direction.html` — Aesthetic direction exploration
- `.superpowers/brainstorm/284669-1776368031/content/card-trigger.html` — Dashboard trigger options
- `.superpowers/brainstorm/284669-1776368031/content/full-concept.html` — v1 concept (rings in dashboard)
- `.superpowers/brainstorm/284669-1776368031/content/full-concept-v2.html` — v2 concept (bar charts in dashboard, overflow handling)
