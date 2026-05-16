# Frontend Architect Adapter

This document adapts the provided Frontend Architect prompt into iNiR's design ops system. Use it for web-facing pages, docs sites, demos, and HTML/CSS artifacts. For core Quickshell surfaces, use it as supporting discipline, not as the primary aesthetic rulebook.

## Verdict

Use the prompt as a structure and quality checklist. Do not import its archetypes, fonts, color defaults, or component recipes wholesale.

The prompt is strongest at preventing unplanned frontend output. It is weaker when treated as a visual identity source, because several recommendations are broad web-design defaults rather than iNiR-specific choices.

## What To Keep

- Pre-code design analysis.
- Job-to-be-done classification.
- Explicit layout strategy before implementation.
- Strong typography contrast.
- Intentional palette selection.
- Accessibility requirements.
- Button, card, form, and responsive-state completeness.
- Pitfall list for common generic AI web patterns.

## What To Modify

### Archetypes

The provided archetypes are useful for web work, but iNiR needs its own default archetype.

Use this iNiR archetype first:

| Archetype | Characteristics | Type Direction | Color Direction |
|---|---|---|---|
| Mission Shell | Dense but breathable, operational, temporal, glass/blur with terminal hints | restrained UI sans plus purposeful mono metadata | Material You-derived neutrals, warm/cool accent tension, tinted dark surfaces |

Use the original archetypes only when the output is explicitly web/marketing/editorial:

- SaaS/Tech: useful for docs or project landing pages, risky for core shell.
- Luxury/Editorial: useful for showcase pages, risky for daily utility.
- Brutalist/Dev: useful for diagnostics, risky if it becomes fake terminal cosplay.
- Playful/Consumer: rarely appropriate for iNiR core surfaces.
- Corporate/Enterprise: useful for accessibility discipline, not brand direction.
- Creative/Portfolio: useful for showcase artifacts, not persistent shell UI.

### Fonts

The prompt's font list is not safe as a default. Some recommendations overlap with common AI-design monoculture.

Rules:

- Do not use font lists as automatic picks.
- Choose fonts from the actual surface context.
- For iNiR shell work, preserve existing project typography unless a design task explicitly changes it.
- For web artifacts, perform a font-selection pass instead of reaching for Space Grotesk, Plus Jakarta Sans, Geist, Playfair, Cormorant, Fraunces, Syne, or IBM Plex by reflex.

### Color

Keep the rejection of pure white, generic blue, and default purple. Upgrade palette work to iNiR's token logic.

Rules:

- Prefer tokenized colors over one-off hex values.
- Prefer OKLCH or project tokens where supported.
- Tint neutrals toward the active iNiR palette.
- Use accent rarely enough that it still has signal value.
- Avoid cyan-on-dark and purple-blue gradients unless explicitly justified.

### Motion

Translate generic frontend motion into iNiR motion beats.

Use:

- `wake`: surface enters.
- `scan`: metadata resolves.
- `lock`: primary content settles.
- `pulse`: rare live-state emphasis.
- `retire`: surface exits.

Do not default every hover to lift plus shadow. That works for marketing cards, but it can make shell surfaces feel floaty and cheap. For app/shell UI, motion should communicate state and focus.

### Icons

Lucide is fine for standalone web artifacts. It is not a global iNiR requirement.

Rules:

- Use existing icon systems inside iNiR.
- Use Lucide only for standalone web prototypes or docs pages when no project icon system exists.
- Do not use emoji as structural UI icons.

## iNiR Pre-Code Checklist

Before writing frontend or design code, answer these briefly:

1. Surface type: shell, web docs, landing page, dashboard, demo, or internal tool?
2. Job to be done: conversion, utility, delight/brand, calibration, or operations?
3. Archetype: Mission Shell by default, or a justified web archetype?
4. Primary action: what should the user understand or do first?
5. Density target: sparse, balanced, dense, or cockpit?
6. Motion role: state, hierarchy, causality, attention, or none?
7. Drift risk: does this look like SaaS, Apple editorial, crypto dashboard, or generic AI web?

## Adapted Job-To-Be-Done Model

### Conversion

Use for project pages, docs landing pages, and showcase surfaces.

- Hero -> value -> proof -> CTA.
- Strong hierarchy.
- More negative space.
- Motion can be cinematic if the page is not daily-use UI.

### Utility / Dashboard

Use for iNiR shell surfaces.

- Information density.
- Scannability.
- Minimal chrome.
- Fast feedback.
- Motion is short and functional.

### Delight / Brand

Use for demos, reveal moments, and showcase artifacts.

- Stronger art direction.
- Fewer competing controls.
- More atmospheric pacing.
- Must not leak into daily-use shell surfaces without passing gates.

### Calibration / Operations

Use for internal iNiR tools such as the Calibration Deck.

- Dense controls.
- Clear current values.
- Reset paths.
- Minimal ceremony.
- Preview surfaces over decorative presentation.

## Required Build Baseline

For web/frontend artifacts:

- Semantic HTML or equivalent framework semantics.
- Visible focus states.
- 4.5:1 contrast minimum for body text.
- Responsive behavior across mobile and desktop.
- Hover, focus, active, disabled, loading, empty, and error states where relevant.
- No pure `#fff`/`#000` unless inherited by a fixed external design system.
- No gradient text as a default impact move.
- No floating blobs/orbs unless the concept specifically requires them.
- No generic laptop hero unless the product context actually needs it.
- No identical card grids without hierarchy.

## Output Format For iNiR Work

When using this adapter, output or document:

1. Surface type and job to be done.
2. Archetype and why.
3. Typography direction, not just font names.
4. Palette/token direction.
5. Layout strategy in one sentence.
6. Motion role and named beats.
7. Accessibility and responsive obligations.
8. Drift risks and explicit non-goals.

## Final Rule

The Frontend Architect prompt is a useful guardrail against generic web output. iNiR still wins all tie-breaks. If a recommendation conflicts with iNiR's retrofuturism x modern flair, shell utility, or daily-use survivability, adapt it or reject it.
