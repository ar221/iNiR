# Inspiration Intake SOP

This SOP turns outside references into iNiR-safe design inputs. It exists to prevent vibe drift: references should sharpen iNiR, not replace its identity.

## North Star

iNiR is retrofuturism x modern flair: mission-clock pressure, terminal-hint metadata, Material You glass, dense utility, and enough polish to feel worth showing another nerd.

Every reference moves through this pipeline:

```text
Reference -> Inspect -> Extract Motifs -> Reject Costume -> Translate To iNiR -> Score -> Pick Pilot -> Document -> Implement
```

## Intake Steps

### 1. Capture

Record the reference before interpretation.

- Source link, screenshot, repo, video, or app name.
- Date captured.
- Why it caught attention.
- Primary value: layout, motion, typography, interaction, tooling, density, color, mood, or process.

### 2. Inspect

Describe what the reference actually does.

- What is the medium?
- What is the user context?
- What is the strongest visual or interaction idea?
- What is structural versus decorative?
- What implementation model, if visible, makes it work?

### 3. Separate Motif From Costume

A motif is reusable design logic. A costume is surface styling that belongs to the source.

Examples:

- Motif: small mono metadata creates flight-deck hierarchy.
- Costume: black editorial void with product-mockup framing.
- Motif: timeline-based animation with named beats.
- Costume: promo-site swagger and AI-tool launch language.

If a reference cannot produce named motifs, archive it as mood only.

### 4. Reject Costume

Explicitly name what should not be copied.

Common rejection categories:

- SaaS launch-page posture.
- Apple-editorial emptiness.
- Lifestyle device mockups.
- Crypto dashboard glow.
- Pure retro cosplay.
- Generic Linux rice decoration.
- AI-generated gradient/glass clichés.

### 5. Translate To iNiR

Every usable idea must become an iNiR-native design move.

Each move needs:

- Name.
- Source observation.
- iNiR translation.
- Best surfaces.
- Risk.
- Implementation note.

Good move names are short and operational: `Mission Metadata`, `Timeline Reveal`, `Calibration Deck`, `Artifact From Command`.

### 6. Score Compatibility

Score from 1 to 5.

- Retrofuturism: Does it strengthen the mission-system / terminal / temporal feel?
- Modern flair: Does it add polish without becoming generic SaaS?
- Shell utility: Does it improve daily shell use?
- Daily-use survivability: Will it still feel good after repeated use?
- Nerd-pride factor: Would this make iNiR more impressive to another nerd?
- Drift risk: How likely is it to pull iNiR off-brand? Higher means riskier.

### 7. Generate A Direction Matrix

For strong references, generate 2-3 iNiR-native variants before implementation.

Default variants:

- `Mission Glass`: modern glass, precise metadata, restrained atmospheric depth.
- `CRT Console`: denser, more terminal-forward, operational but not cosplay.
- `Material Flight Deck`: closest to current iNiR, with targeted reference borrowings.

### 8. Pick A Pilot

Choose the smallest surface that can test the idea without redesigning the whole shell.

Good pilots:

- Internal calibration panel.
- Launcher section.
- Notification stack behavior.
- Dashboard module.
- Workspace overview detail.
- Agent activity surface.

Avoid whole-shell redesigns from a single reference.

### 9. Document The Result

Use `reference-extraction-template.md` for references worth keeping.

Keep the output practical. The goal is a buildable design brief, not a museum label.

## Gates Before Build

Pass all relevant gates before implementation.

- Shell Utility Gate: improves glanceability, orientation, control, or daily use.
- Retrofuturism Gate: retro element is operational, not decorative cosplay.
- Modern Flair Gate: polish feels intentional, not SaaS-default.
- Density Gate: information density is readable and purposeful.
- Motion Gate: motion explains state, hierarchy, or causality.
- Pride Gate: passes the "show another nerd" test.
- Drift Gate: does not make iNiR look like an AI launch page, Apple deck, crypto dashboard, or generic rice.
- Screenshot Archive Gate: known mistakes from `/home/ayaz/Pictures/Screenshots` have been checked, especially narrow packet behavior, amber fog, dead middle space, empty/failure states, and long-text overflow.
- Watchtower Translation Gate: if using Watchtower/Courier references, verify the implementation preserves semantic region order across desktop and mobile rather than merely changing grid columns.
- Token Audit Gate: if introducing or changing palette, type, icon, or semantic state tokens, provide a preview state with pass/fail notes similar to the AgenticOS token references.

For web-facing pages, demos, or HTML/CSS artifacts, also run `frontend-architect-adapter.md` before build. It adds archetype, job-to-be-done, accessibility, responsive, and interaction checks while preserving iNiR's taste gates.

For Courier/iNiR command surfaces, also run `screenshot-archive-regression.md` before build. It defines the fixture set and required width checks that turn prior visual mistakes into regression coverage.

## When To Stop

Stop at documentation if:

- The reference is mostly costume.
- The strongest idea is already covered by existing iNiR patterns.
- The pilot would require broad architecture changes.
- The reference scores high on drift risk and low on shell utility.

Proceed to implementation only when the extracted move has a clear surface, clear value, and low enough risk.
