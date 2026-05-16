# Screenshot Archive Regression

This note turns `/home/ayaz/Pictures/Screenshots` into usable design memory for iNiR. The folder name is case-sensitive: `Screenshots`, not `screenshots`.

The archive is not just inspiration. It is a regression source for the mistakes already paid for: cramped narrow panels, brown-fog Courier attempts, blank failure states, terminal overflow, and command boards with too many equal-weight boxes.

## What To Learn

- **Desktop = command board.** Wide surfaces can hold board, rail, card, log, command strip, and receipt patterns.
- **Narrow = dispatch packet.** Compact surfaces need one dominant task, one status strip, one action stack, and expandable detail. Do not compress a desktop board into a column.
- **Amber is signal.** Warm orange/coral should mark rails, active state, hot numbers, and command affordances. It should not flood every surface.
- **Every panel needs a job.** Valid jobs are status, queue, route, log, command, artifact, and alert. If a panel cannot name its job, remove or merge it.
- **Failure states are designed states.** Empty, stale, missing-source, plugin-dead, and error surfaces must show cause, source, and recovery action as Courier receipts.
- **Borders must earn their keep.** A border should establish hierarchy, grouping, or interaction target. Equal-weight boxes everywhere create hardware noise.
- **Tall panels need owned middles.** Header plus footer with dead center space is a layout failure. The body should be content, empty-state, or collapsed.
- **Responsive means re-sequencing, not squeezing.** Watchtower mobile references preserve semantic order: title/mission, resident or source, command controls, primary viewport, then detail receipts. QML breakpoints should reorder named regions, not only reduce columns.
- **Command controls need a wrap contract.** Board selectors, zoom controls, command buttons, refresh/reset/plugin actions must wrap as grouped touch targets at `390`-`520` widths. Raw `RowLayout` overflow is a regression.
- **Spatial boards need inspectors.** Canvas/board surfaces should pair a clipped grid viewport with source receipts and a selected-card inspector. Selection state must survive scroll and partial card visibility.
- **Master-detail is the memory pattern.** Memory, log, vault, and history surfaces should prefer shelf/category rail + receipt list + source preview over equal-weight card grids.

## Regression Fixture Set

Use this set when building or changing Courier/iNiR command surfaces.

- Narrow media playing.
- Narrow media idle or missing album art.
- Dashboard left stack.
- Compact calendar/weather panel.
- Full-width command board.
- Agent/service board with active, stale, and error states.
- Empty feed or missing-source state.
- Long-title and long-path overflow state.
- Chip/filter row with too many items.
- Footer or command strip with content above it.
- Spatial board with selected card, source rail, and inspector.
- Mobile command controls with 8+ actions wrapping at `390`, `460`, and `520` widths.
- Memory rack master-detail with long titles and long source paths.
- Selected board card partially offscreen while detail rail remains populated.
- Token audit card with pass/fail validation labels.

## Required Width Checks

Capture or inspect the relevant surface at these widths before calling a Courier surface done:

- `460`: phone-like dispatch packet stress width.
- `520`: narrow panel width seen repeatedly in the archive.
- `720`: tablet or widened packet.
- `960`: small board.
- `1280`: normal command board.

If a surface only exists at one width in production, still test one narrower and one wider width while developing. It exposes text, spacing, and dead-zone failures early.

## QML Implementation Rules

- Define breakpoint modes from surface width: `compact`, `packet`, `board`.
- Never let long text decide layout alone. Set `elide`, `wrapMode`, `maximumLineCount`, and provide a tooltip/detail path where needed.
- Use a scaffold that owns header, body, and footer space. Do not overlay command/footer rails unless the content area explicitly reserves that height.
- Reorder named regions at breakpoints instead of only shrinking columns. A packet order should be explicit in QML, not accidental from layout compression.
- Wrap command controls in grouped touch targets. Unknown action counts need wrapping or overflow behavior by design.
- Keep board selection state separate from viewport visibility so inspectors remain populated when selected cards scroll partly out of view.
- Give hero/media regions `maximumHeight` and aspect constraints so they cannot swallow the panel.
- Use `Flickable` intentionally: `clip: true`, bounded scrolling, and visible continuation affordance when content continues.
- Normalize state before styling it: `idle`, `running`, `warning`, `error`, `stale`, `success`.
- Prefer reusable Courier components over one-off layout fixes: card, receipt row, status pill, chip flow, responsive rail, bounded mono text.

## Review Checklist

Before merging a Courier surface or major visual pass, answer:

1. What job does each panel perform?
2. What is the source of truth for each state shown?
3. Where does the user act, and where is the receipt?
4. Does narrow mode read as a dispatch packet?
5. Is amber/coral signal instead of atmosphere?
6. Are error, stale, empty, and missing-source states designed?
7. Are all long labels, paths, titles, and statuses bounded?
8. Does the center of each tall panel have owned content or deliberate collapse?
9. Are borders creating hierarchy rather than visual noise?
10. Were `460`, `520`, `720`, `960`, and `1280` checked for the changed surface?

## Candidate Components

- `CourierCard`: square-ish card with header rail, receipt label, border, and status stripe.
- `CourierReceiptRow`: fixed-height row for feed, task, calendar, inbox, service, or route receipts.
- `CourierStatusPill`: normalized state/severity rendering.
- `CourierChipFlow`: wrapping or horizontally-scrollable filter/tag row.
- `BoundedMonoText`: mono label wrapper with safe truncation defaults.
- `ResponsivePanelScaffold`: header/body/footer owner that prevents dead middle space.
- `CompactMediaBlock`: narrow music/media layout with no unowned vertical gap.
- `AgentRouteCard`: agent, lane, current task, trust/state, and last receipt.
- `CourierCommandWrap`: grouped, wrapping command controls with real touch targets.
- `CourierBoardCanvas`: grid-backed `Flickable` board with selectable cards and viewport clipping.
- `CourierInspectorRail`: selected object detail rail for board/canvas surfaces.
- `CourierSourceRail`: read-only source/evidence cards with normalized state.
- `CourierMemoryRack`: shelf tabs, receipt list, and source preview.
- `DesignTokenAuditCard`: token preview with looks-good/needs-work validation state.

## How To Use The Archive

When a screenshot shows a failure, do not only fix that instance. Extract the rule:

- What content state broke it?
- What width exposed it?
- Which component contract was missing?
- Which token drifted?
- What fixture should prevent it from coming back?

Then update this file, the component contract, or the relevant fixture. The mistake becomes worthwhile only when it turns into a repeatable guard.
