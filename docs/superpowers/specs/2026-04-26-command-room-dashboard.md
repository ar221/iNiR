# Command Room Dashboard — Design Spec

**Date:** 2026-04-26
**Status:** Draft
**Extends:** `2026-04-16-bar-dashboard-redesign.md` (the current dashboard shipped from that spec remains the `"default"` preset; this spec adds the `"command"` preset as an alternative)
**Reference:** `~/Documents/Ayaz OS/03 Projects/iNiR/00 Inspiration & Research/™ Agentic OS Dashboard Reference 2026-04-26.md`

## Summary

Add a "Command Room" style preset to the dashboard and bar, inspired by the AgenticOS dashboard aesthetic. Dark, monospace-dominant, barcode progress meters, opaque angular cards, and a hero idle state. Delivered as a config-driven preset — the existing glass/organic dashboard remains as `"default"` and is not modified.

## Design Decisions (locked)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Scope | Full — dashboard reskin + palette layer + new primitives + bar barcode meters | Maximum expressiveness without breaking existing look |
| Typography | Monospace for instrumentation (headers, readouts, labels, timestamps); proportional for prose (activity messages, notification bodies, event descriptions) | Terminal feel without flattening hierarchy — selective monospace reads as mission control, wall-to-wall reads as SaaS |
| Performance viz | Barcode meters everywhere (dashboard + bar) | Cohesive visual language; bar mini-rings replaced |
| Palette | Warm blacks + bright amber; add opaque card surface tokens | Apollo keeps its identity; cards get real hierarchy |
| Card shape | 6-8px radius, opaque fills, 1px hairline borders | Technical/angular, not brutalist |
| Hero zone | Idle state hero, collapses to status strip when active | Gives the dashboard personality; gets out of the way when working |
| Layout | Activity + widget stack side-by-side below hero; right column beefed up | Dense center, clean ambient right |
| Implementation | Style preset system (Approach 2) | Config-driven, reversible, fits existing architecture |

---

## 1. Palette — Warm Apollo Surface Tokens

### Source of truth

`ThemePresets.qml` is the runtime authority. The file at `defaults/palettes/apollo/state/palette.json` may be referenced by the matugen pipeline for non-Apollo themes but is not wired into the Apollo preset itself — Apollo bypasses wallpaper theming entirely.

### Current Apollo background values (ThemePresets.qml line 683+)

These are currently cool-neutral. The Command Room shifts them warm:

| Token | Current (cool) | Command Room (warm) | Role |
|-------|----------------|---------------------|------|
| m3background | `#101113` | `#0E0B08` | Dashboard canvas |
| m3surface | `#101113` | `#0E0B08` | Base surface |
| m3surfaceDim | `#090A0C` | `#060503` | Deepest shadow |
| m3surfaceBright | `#2A2D32` | `#2A2420` | Brightest surface |
| m3surfaceContainerLowest | `#0B0C0E` | `#080604` | Meter track background |
| m3surfaceContainerLow | `#17191D` | `#161210` | Card fill (default) |
| m3surfaceContainer | `#1E2126` | `#1E1A16` | Card fill (elevated) |
| m3surfaceContainerHigh | `#272B31` | `#2A2420` | Card border / highest surface |
| m3surfaceContainerHighest | `#333841` | `#3A3430` | Card border hover |

**Implementation — intentional global change:** These values replace the current cool values in the `apolloColors` object unconditionally. This is NOT scoped to the command preset — Apollo itself shifts warm everywhere (bar, sidebar, dashboard, all surfaces).

**Why global, not preset-scoped:** Maintaining two parallel Apollo color sets (cool for default, warm for command) doubles the palette surface and creates a jarring temperature jump when toggling presets. The warm shift is subtle on transparent surfaces — the `"default"` dashboard preset renders cards with `rgba(1,1,1,0.03)` overlays, so the underlying warmth is barely perceptible there. The `"command"` preset makes surfaces opaque, which is where the warmth visually registers. Net effect: warm palette everywhere, only opaque command cards reveal it.

### New semantic aliases (Command preset only)

These are derived from the M3 tokens above, not new palette entries. The Command preset maps them at the QML layer:

| Alias | Resolves to | Usage |
|-------|-------------|-------|
| `cardFill` | `m3surfaceContainerLow` | Default card background |
| `cardElevated` | `m3surfaceContainer` | Hovered / active card |
| `cardBorder` | `m3surfaceContainerHigh` | Hairline border default |
| `cardBorderHover` | `m3surfaceContainerHighest` | Hairline border on hover |
| `meterTrack` | `m3surfaceContainerLowest` | Barcode meter background |

### Non-Apollo theme fallback

When a non-Apollo theme is active (Catppuccin, Material You auto, etc.) and `stylePreset: "command"` is on, the same M3 token mapping applies. `cardFill` resolves to whatever that theme defines as `m3surfaceContainerLow`. The Command Room visual identity will look different per-theme (cooler on Catppuccin, warmer on Apollo) but the structural grammar (opaque fills, tight radius, barcode meters) stays consistent.

---

## 2. Typography

Dashboard-scoped. The bar and sidebar keep their current font stack.

| Level | Size | Weight | Spacing | Color | Usage |
|-------|------|--------|---------|-------|-------|
| Hero | 32px | Bold (700) | 0 | `m3onBackground` + accent keyword in `m3primary` | HeroZone idle text |
| Metric | 24px | Bold (700) | 0 | `m3onBackground` | Large stat readouts |
| Card header | 11px | DemiBold (600) | 1.5px | `rgba(onBg, 0.4)` | Section labels, uppercase |
| Body | 12px | Regular (400) | 0 | `rgba(onBg, 0.7)` | Activity messages, descriptions |
| Label | 10px | DemiBold (600) | 1.0px | `rgba(onBg, 0.3)` | Sub-labels, metadata, uppercase |
| Timestamp | 10px | Regular (400) | 0 | `rgba(onBg, 0.2)` | Times, tertiary info |

**Font assignment by level:**

| Levels | Font | Rationale |
|--------|------|-----------|
| Hero, Metric, Card header, Label, Timestamp | `appearance.typography.monospaceFont` (JetBrainsMono NF) | Instrumentation surfaces — readouts, headers, status text |
| Body | `appearance.typography.fontFamily` (Roboto Flex / system proportional) | Prose surfaces — activity messages, notification bodies, event descriptions |

Monospace on instrumentation reads as mission control. Wall-to-wall monospace flattens hierarchy into dark SaaS dashboard. The split is the brand.

---

## 3. Component Primitives

New reusable widgets in `modules/common/widgets/`. Available to any panel, not dashboard-specific.

### 3.1 BarcodeMeter

Horizontal striped progress bar. Two variants:

**Block variant (dashboard cards):**
- Height: 16-18px
- Track: Rectangle, `meterTrack` fill, 2px radius, `clip: true`
- Fill: Row of thin Rectangles inside a clipped Item, width proportional to value (0.0–1.0). Each stripe is 2px wide with 2px spacing (4px pitch). Stripe color = accent. Generated via a `Repeater { model: Math.ceil(trackWidth / 4) }` producing 2px-wide Rectangles at `x: index * 4`.
- Label left, value right
- Optional header row above (title + metadata)

**Inline variant (status bar):**
- Height: 10px
- Track: Rectangle, `rgba(onBg, 0.04)`, 2px radius, `clip: true`
- Fill: Same Repeater-stripe approach, 1.5px bar width, 1.5px spacing (3px pitch)
- Compact: label (8px) + meter (48px width) + value (9px)

**Why Repeater, not Canvas or ShaderEffect:** Repeater + Rectangles is pure Scene Graph — no texture uploads, no JS paint callbacks, minimal overhead for a simple stripe pattern. Canvas would work but costs a texture and repaints on resize. ShaderEffect is overkill for axis-aligned stripes.

**Color assignment (same as current ring mapping):**
- CPU: `m3primary` (amber)
- GPU: `m3secondary` (teal)
- Temp: `m3error` (red-orange)
- RAM: `m3tertiary` (warm-brown)
- VRAM: `m3tertiary` variant (violet, for distinction in dashboard)

**Warning thresholds:** Same config values as current rings. When threshold is exceeded, fill color shifts to error palette.

**QML interface:**
```
BarcodeMeter {
    value: 0.47          // 0.0–1.0
    label: "CPU"
    color: colPrimary
    variant: "block"     // "block" | "inline"
    showLabel: true
    showValue: true
}
```

### 3.2 StatusPill

Compact status indicator chip.

- Dot: 6px circle, filled with status color
- Label: 10px uppercase, DemiBold, 1px letter-spacing
- Background: `rgba(statusColor, 0.08)`
- Border: `1px solid rgba(statusColor, 0.2)`
- Radius: 4px
- Padding: 4px 10px

**Statuses** (property name is `status`, not `state` — avoids collision with QML's built-in `Item.state`):
| Status | Color | Label |
|-------|-------|-------|
| active | `m3primary` | ACTIVE |
| idle | `rgba(onBg, 0.3)` | IDLE |
| running | `m3success` | RUNNING |
| error | `m3error` | ERROR |
| waiting | `m3secondary` | WAITING |
| scheduled | `m3secondary` | SCHEDULED |

**QML interface:**
```
StatusPill {
    status: "active"   // active | idle | running | error | waiting | scheduled
}
```

### 3.3 AgentTile

Agent status row for the cockpit panel.

- Avatar: 28px square, 4px radius, `rgba(onBg, 0.06)` fill, stamped initial letter in `rgba(onBg, 0.5)` — monochrome, not gradient. Gradient agent avatars read as generic AI-dashboard; the monochrome badge keeps the Command Room's utilitarian identity.
- Name: 12px DemiBold, `m3onBackground`
- Route: 10px, `rgba(onBg, 0.25)` — shows domain + last activity time
- Status: StatusPill, right-aligned
- Row separator: `1px solid rgba(onBg, 0.04)`
- Row padding: 10px 8px

**QML interface:**
```
AgentTile {
    name: "ALFRED"
    initial: "A"
    route: "system ops"
    lastActive: "2m ago"
    status: "active"
}
```

### 3.4 RoutineTile

Compact row for recent runs, scheduled routines, or queued tasks.

- Timestamp: 10px, `rgba(onBg, 0.2)`, 40px width
- Label: 11px DemiBold, `m3onBackground`
- Action: 10px, `rgba(onBg, 0.2)`, "OPEN ↗" or similar
- Row separator: `1px solid rgba(onBg, 0.04)`
- Row padding: 7px 0

**QML interface:**
```
RoutineTile {
    timestamp: "20:10"
    label: "VAULT CLEANUP"
    actionText: "OPEN"
    onActionClicked: { /* IPC to open run details */ }
}
```

### 3.5 CommandCard (DashboardCard preset variant)

Not a new component. `DashboardCard` reads `dashboard.stylePreset` and switches its styling:

| Property | `"default"` | `"command"` |
|----------|-------------|-------------|
| Background | `rgba(1,1,1,0.03)` | `cardFill` (opaque) |
| Border | `rgba(1,1,1,0.06)` | `cardBorder` (opaque) |
| Border hover | `rgba(1,1,1,0.12)` | `cardBorderHover` (opaque) |
| Radius | 18px | 6px |
| Header font | System monospace | `monospaceFont` (same, but guaranteed) |
| Padding | 20px | 16px (slightly tighter) |

---

## 4. Dashboard Layout — Command Preset

### Three-column structure (same grid as default)

```
LEFT (260px)            CENTER (flexible)                    RIGHT (300px)
┌──────────┐           ┌──────────────────────────────────┐ ┌──────────┐
│ Profile  │           │ Performance (barcode meters)      │ │ Calendar │
├──────────┤           ├──────────────────────────────────┤ │ (today + │
│ System   │           │ HeroZone (idle) / StatusStrip     │ │ upcoming)│
│ Info     │           │ (active)                          │ ├──────────┤
├──────────┤           ├────────────────┬─────────────────┤ │ Weather  │
│ Quick    │           │ Activity       │ Widget Stack:   │ │ (7-day   │
│ Toggles  │           │ Console        │ ┌─────────────┐ │ │ forecast)│
├──────────┤           │                │ │ ServiceGrid │ │ ├──────────┤
│ Agent    │           │                │ ├─────────────┤ │ │ Notifs   │
│ Status   │           │                │ │ DiskGauges  │ │ │ (richer) │
│          │           │                │ ├─────────────┤ │ │          │
│          │           │                │ │ VaultPulse  │ │ │          │
│          │           │                │ ├─────────────┤ │ │          │
│          │           │                │ │ RecentRuns  │ │ │          │
│          │           │                │ └─────────────┘ │ │          │
│          │           ├────────────────┴─────────────────┤ │          │
│          │           │ IntegrationStatus (full-width bar)│ │          │
└──────────┘           └──────────────────────────────────┘ └──────────┘
```

### Left column changes

- Profile, SystemInfo, QuickToggles: restyled via CommandCard, no structural changes
- **AgentStatus card (new):** Uses AgentTile primitives. Shows 4-6 agent tiles (Alfred, Oracle, Hermes, Elsa, plus any active specialists). Configurable via `dashboard.agentStatus.agents` array.

### Center column changes

- **PerformanceBarsCard → PerformanceBarcodeCard:** Replaces vertical gradient bars with horizontal BarcodeMeter rows. CPU, GPU, RAM, VRAM. Temperature shown as a fifth meter or as inline text below.
- **HeroZone (new):**
  - **Idle state:** Full-width card. "READY" label (9px), hero text "COMMAND ROOM STANDING BY" (28-32px bold, accent keyword), action hints below (10px dim).
  - **Active state:** Collapses to a compact status strip — pulsing amber dot, "SESSION ACTIVE" label, agent name + domain, elapsed time. Border tints to `rgba(primary, 0.15)`.
  - **Transition:** `Behavior on height` with `emphasizedDecel` easing, ~300ms.
  - **Visibility:** Only rendered when `dashboard.stylePreset === "command"`. Hidden in default preset.
- **Activity + Widget Stack (side-by-side):** Activity console takes the left majority width. Widget stack (280px) on the right contains ServiceGrid, DiskGauges, VaultPulse, RecentRuns stacked vertically.
- **IntegrationStatus bar (new):** Full-width strip at bottom of center column. Accent-colored "INTEGRATIONS" label, vertical divider, then a row of service dots with labels.
- **NetworkSparklinesCard:** Removed from default view in Command preset. Accessible via a "More" expand gesture on the performance card, or re-enabled via config toggle.

### Right column changes

- **CalendarCard:** Expanded — hero date, today's events with colored sidebar bars, upcoming events for the next 3-5 days.
- **WeatherCard:** 7-day forecast. Current conditions hero (temp + description + wind/humidity/UV), then daily rows (day, icon, hi/lo).
- **NotificationsCard:** Richer — source dots with per-source color, relative timestamps, notification body text.

---

## 5. Bar Changes

### BarcodeMiniMeter (inline variant)

Replaces MiniRing when `bar.rings.variant === "barcode"`.

- Same data sources as current rings (ResourceUsage service)
- Same warning thresholds from config
- Layout: `label (8px) + meter (48px × 10px) + value (9px)` per metric
- Arranged in a row matching current ring layout position
- Total width: ~4 × 80px = 320px (vs current ~4 × 28px = 112px for rings) — nearly 3× the footprint.
- **Adaptive sizing (required from day one):** The component must bind to parent width and degrade:

  | Available width | Behavior |
  |-----------------|----------|
  | ≥ 320px | Full: `label (8px) + meter (48px) + value (9px)` × 4 in a row |
  | 200–319px | Compact: labels hidden, meter shrinks to 32px, values stay |
  | < 200px | Stacked: 2×2 grid, each cell = `meter (32px) + value (9px)` |

  Implementation: BarcodeMiniMeters reads `width` and picks a layout state. Not a polish follow-up — shipping at 320px fixed would break narrow bars immediately.

**Implementation:** New `BarcodeMiniMeters.qml` component (parallel to `MiniRings.qml`). `BarContent.qml` loads one or the other based on `bar.rings.variant`. Both components expose the same data interface.

### Existing bar elements unchanged

Monogram, workspace pills, clock, active window title, notification bell — all untouched. The bar's overall `stylePreset` (dusky/clean/glass) remains independent.

---

## 6. Data Sources

### Existing (already wired)

| Widget | Source | Notes |
|--------|--------|-------|
| Performance meters | `ResourceUsage` service | CPU, GPU, RAM, VRAM, temperatures. Already polled. |
| ActivityConsole | `~/.local/state/inir/activity-feed.jsonl` | Already implemented in current dashboard. |
| Calendar | Google Calendar MCP | Already integrated via `CalendarCard`. Expand to show more days. |
| Weather | Weather service | Already integrated. Expand to 7-day (requires API support check). |
| Notifications | Notification daemon IPC | Already integrated. Enrich display format. |

### New (needs implementation)

| Widget | Source | Implementation |
|--------|--------|----------------|
| **ServiceGrid** | systemd D-Bus / `systemctl --user` polling | Configurable service list in `dashboard.serviceGrid.services` (array of unit names). Polled every 30s via a new `ServiceStatus` service or folded into existing `SystemInfo` polling. |
| **DiskGauges** | `statvfs` / QML `Qt.resolvedUrl` + C++ helper | Configurable mount paths in `dashboard.diskGauges.mounts` (array: `["/", "/home", "/mnt/hdd"]`). Polled every 60s. |
| **VaultPulse** | Shell commands via `Process` | `find ~/Documents/Ayaz\ OS/ -name '*.md' \| wc -l` for total notes. `find ... -mtime 0` for edited today. Inbox = count of files in `00 Inbox/`. Orphans = count of files with no backlinks (expensive — cache result, refresh on dashboard open). Polled on dashboard open, not continuously. |
| **RecentRuns** | `~/.local/state/inir/recent-runs.jsonl` (new) | New state file. Each line: `{"timestamp":"ISO","label":"VAULT CLEANUP","source":"hermes\|claude\|cron","status":"done\|running\|failed"}`. Writers: Hermes gateway (via inbox file pickup), Claude Code hooks (post-session), cron routines. Initially populated by Claude Code session hooks only — Hermes integration is a follow-up. |
| **IntegrationStatus** | Configurable static entries + optional live ping | `dashboard.integrations` array: `[{"name":"GITHUB","check":"none"},{"name":"GMAIL","check":"none"}]`. `check: "none"` = neutral "CONFIGURED" label (muted dot, not green). Static entries must never imply live health — green dot is reserved for `check: "mcp"` with a real health ping. Future: `check: "mcp"` pings MCP server health. Initially static — live status is a follow-up. |
| **AgentStatus** | `~/.local/state/inir/agent-status.jsonl` (new) | New state file. Each line: `{"agent":"alfred","status":"active\|idle\|scheduled","lastActive":"ISO","domain":"system ops"}`. Writers: Claude Code session hooks (on session start/end), Hermes gateway (on routine dispatch). Initially populated by Claude Code hooks only. |
| **HeroZone active state** | `~/.local/state/inir/active-session.json` (new) | Single JSON file, overwritten per session: `{"active":true,"agent":"alfred","domain":"system ops","startedAt":"ISO","updatedAt":"ISO"}`. `updatedAt` refreshed every 60s by the session hook (heartbeat). Cleared on session end. **Stale protection:** HeroZone reads `updatedAt` on each poll — if older than 5 minutes, treats session as stale and falls back to idle state. This handles crash/disconnect where the hook never clears the file. Writer: Claude Code hook. |

### State file location

All new state files live under `~/.local/state/inir/` (XDG state directory), consistent with the existing `activity-feed.jsonl`.

### Stub behavior

Widgets with no data source configured or no state file present show a contextual dormant message in muted text (`rgba(onBg, 0.15)`), not a generic "NO DATA" or an error. Each widget owns its copy:

| Widget | Dormant message |
|--------|-----------------|
| ServiceGrid | "CONFIGURE SERVICES IN CONFIG" |
| DiskGauges | "CONFIGURE MOUNTS IN CONFIG" |
| VaultPulse | "VAULT PATH NOT SET" |
| RecentRuns | "NO RUNS RECORDED" |
| IntegrationStatus | "NO INTEGRATIONS CONFIGURED" |
| AgentStatus | "AWAITING AGENT ACTIVITY" |
| HeroZone (stale session) | Falls back to idle state (not a separate message) |

This prevents first-run breakage while telling the user what to do about it.

---

## 7. Config Schema

### New keys under `dashboard`

```jsonc
{
  "dashboard": {
    "stylePreset": "command",     // "default" | "command"

    "sections": {
      // ... existing toggles unchanged ...
      "serviceGrid": false,       // default false — needs config
      "diskGauges": false,        // default false — needs config
      "vaultPulse": false,        // default false — needs config
      "recentRuns": false,        // default false — needs state file
      "integrationStatus": false, // default false — needs config
      "heroZone": true            // default true when command preset
    },

    "serviceGrid": {
      "services": [
        "syncthing.service",
        "claude-proxy.service",
        "dictation-server.service",
        "pipewire.service",
        "bluetooth.service"
      ],
      "pollIntervalSec": 30
    },

    "diskGauges": {
      "mounts": ["/", "/home", "/mnt/hdd"],
      "pollIntervalSec": 60
    },

    "vaultPulse": {
      "vaultPath": "~/Documents/Ayaz OS/",
      "inboxPath": "00 Inbox/",
      "countOrphans": true
    },

    "integrations": [
      { "name": "GITHUB", "check": "none" },
      { "name": "GMAIL", "check": "none" },
      { "name": "GOOGLE CALENDAR", "check": "none" },
      { "name": "SYNCTHING", "check": "none" },
      { "name": "TELEGRAM", "check": "none" }
    ],

    "agentStatus": {
      "agents": [
        { "name": "ALFRED", "initial": "A", "domain": "system ops", "color": "primary" },
        { "name": "ORACLE", "initial": "O", "domain": "portfolio", "color": "secondary" },
        { "name": "HERMES", "initial": "H", "domain": "messenger", "color": "tertiary" },
        { "name": "ELSA", "initial": "E", "domain": "inir ux", "color": "tertiaryAlt" }
      ]
    }
  }
}
```

### New keys under `bar`

```jsonc
{
  "bar": {
    "rings": {
      "variant": "arc",           // "arc" (current) | "barcode" (new)
      // ... existing ring config unchanged ...
    }
  }
}
```

### Default enablement

The `"command"` preset switches the card style, typography, and HeroZone on automatically. Data-dependent widgets (ServiceGrid, DiskGauges, VaultPulse, RecentRuns, IntegrationStatus) default to `false` and require the user to configure their data sources before enabling. This prevents broken-looking widgets on first run.

When the user sets `stylePreset: "command"`, iNiR could show a one-time toast: "Command Room active. Configure service grid, disk mounts, and integrations in config.json to unlock all widgets."

---

## 8. Animation & Transitions

All animations respect `Appearance.animationsEnabled` and `Appearance.metrics.durationScale`.

| Element | Animation | Duration | Easing |
|---------|-----------|----------|--------|
| HeroZone idle → active | Height collapse + opacity | 300ms | emphasizedDecel |
| HeroZone active → idle | Height expand + opacity | 350ms | emphasizedDecel |
| BarcodeMeter value change | Fill width | 600ms | standardDecel |
| Card border hover | Color transition | 150ms | linear |
| StatusPill dot (active) | Pulse glow | 2s loop | ease-in-out |
| Dashboard entry/exit | Same as current (fly Y + scale + opacity) | 350ms / 210ms | Unchanged |

---

## 9. File Inventory

### New files

| File | Type | Description |
|------|------|-------------|
| `modules/common/widgets/BarcodeMeter.qml` | Primitive | Block + inline barcode progress bar |
| `modules/common/widgets/StatusPill.qml` | Primitive | Status indicator chip |
| `modules/common/widgets/AgentTile.qml` | Primitive | Agent status row |
| `modules/common/widgets/RoutineTile.qml` | Primitive | Timestamped run/task row |
| `modules/dashboard/HeroZone.qml` | Dashboard | Idle/active hero state |
| `modules/dashboard/PerformanceBarcodeCard.qml` | Dashboard | Barcode meter performance card |
| `modules/dashboard/ServiceGridCard.qml` | Dashboard | Systemd service health grid |
| `modules/dashboard/DiskGaugesCard.qml` | Dashboard | Storage barcode meters |
| `modules/dashboard/VaultPulseCard.qml` | Dashboard | Vault statistics grid |
| `modules/dashboard/RecentRunsCard.qml` | Dashboard | RoutineTile list |
| `modules/dashboard/IntegrationStatusBar.qml` | Dashboard | Full-width integration dots |
| `modules/dashboard/AgentStatusCard.qml` | Dashboard | AgentTile list for left column |
| `modules/bar/BarcodeMiniMeters.qml` | Bar | Inline barcode meters (replaces MiniRings) |
| `services/ServiceStatus.qml` | Service | Systemd service polling (or fold into SystemInfo) |

### Modified files

| File | Change |
|------|--------|
| `modules/common/ThemePresets.qml` | Warm-shift Apollo background values |
| `modules/dashboard/DashboardCard.qml` | Add preset-aware styling (radius, fill, border) |
| `modules/dashboard/DashboardContent.qml` | Add new cards, hero zone, widget stack layout |
| `modules/bar/BarContent.qml` | Conditional load of BarcodeMiniMeters vs MiniRings |
| `defaults/config.json` | Add new config keys |

### Unchanged files

MiniRing.qml, MiniRings.qml — preserved for `"arc"` variant. Not deleted.
PerformanceBarsCard.qml, PerformanceBar.qml — preserved for `"default"` preset.
NetworkSparklinesCard.qml — hidden in command preset, not deleted.

---

## 10. Implementation Phasing Guidance

The spec describes the full Command Room. Implementation should prove the visual language before piling on every subsystem:

**Phase 1 — Visual grammar (ship first):**
- Warm Apollo palette shift in ThemePresets.qml
- `dashboard.stylePreset` toggle in DashboardCard (opaque fills, tight radius)
- BarcodeMeter.qml (block + inline variants) — the signature primitive
- StatusPill.qml — needed by HeroZone active state
- PerformanceBarcodeCard (replaces gradient bars)
- HeroZone (idle + active states)
- Core layout restructure (activity + widget stack column). In Phase 1 the widget stack column exists structurally but is empty — it shows a single muted "SUBSYSTEMS OFFLINE" placeholder until Phase 2 widgets populate it. Activity console stretches to fill if no widgets are enabled.
- Bar BarcodeMiniMeters with adaptive sizing

**Phase 2 — Operational widgets (after Phase 1 lands):**
- AgentStatusCard + AgentTile
- RecentRunsCard + RoutineTile
- ServiceGridCard
- DiskGaugesCard
- VaultPulseCard
- IntegrationStatusBar

**Phase 3 — Data plumbing (after Phase 2 shells exist):**
- State file writers (Claude Code hooks, cron routines)
- Hermes gateway integration
- MCP live health pings for IntegrationStatus

---

## 11. Out of Scope

- Hermes gateway integration (writing to recent-runs.jsonl from Hermes). Follow-up.
- MCP live health checks for IntegrationStatus. Follow-up — static entries first.
- Obsidian orphan detection optimization (backlink index). Initial implementation uses simple find commands.
- Sidebar reskin. The sidebar is not part of this spec.
- New wallpaper / matugen integration. Apollo bypasses wallpaper theming; this doesn't change.
- Mobile companion widget. Exists as a concept but is not part of Command Room.
