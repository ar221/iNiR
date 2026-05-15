# iNiR Design Ops

This directory holds iNiR's reference-to-design workflow: how outside inspiration becomes project-safe design direction without pulling the shell off-brand.

## Current Direction Lock — Courier Console

**Courier Console** is the forward design language for iNiR command surfaces: warm-terminal dispatch board, square hardware geometry, semantic color, receipt-backed status, and Agentic OS-style observability only when backed by real local state.

Canonical specs:

- Vault design vocabulary: `~/Documents/Ayaz OS/03 Projects/iNiR/™ Design Vocabulary.md`
- Cross-stack source spec: `~/Documents/Ayaz OS/03 Projects/System/01 Specs/™ Courier Console Design Language.md`
- Agentic OS reference intake: `~/Documents/Ayaz OS/03 Projects/iNiR/00 Inspiration & Research/™ Agentic OS Dashboard Reference 2026-04-26.md`

Rollout rule: wedge, verify, then expand. Bar first; cockpit/dashboard next; sidebars only where the command grammar helps. Narrow/mobile surfaces follow the Courier translation rule: **desktop = command board; mobile = dispatch packet**. Rails collapse into strips/drawers, ledgers summarize before expanding, touch targets stay real, and a narrow-width check is part of done.

## Core Workflow

```text
Reference -> Inspect -> Extract Motifs -> Reject Costume -> Translate To iNiR -> Score -> Pick Pilot -> Document -> Implement
```

## Files

- `inspiration-intake-sop.md`: the main SOP for processing outside references.
- `reference-extraction-template.md`: copyable template for saving reference analysis.
- `direction-matrix-template.md`: comparison matrix for multiple iNiR-native visual directions.
- `motion-grammar.md`: named shell motion beats and motion rules.
- `surface-calibration.md`: first pilot spec for an internal calibration deck.
- `huashu-extraction-notes.md`: worked example from Huashu Design.
- `frontend-architect-adapter.md`: adapts a general anti-slop frontend prompt into iNiR-safe web/design rules.

## Skill

The companion skill lives at:

```text
~/.claude/skills/reference-to-inir/SKILL.md
```

It may require a fresh agent/session before it appears in the skill registry.

## Rule

Do not let references become costumes. Extract, translate, gate, pilot.
