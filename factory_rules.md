# Factory Rules — iNiR

Created: 2026-05-19  
Coordinator: Elsa  
Vault mirror: `/home/ayaz/Documents/Ayaz OS/03 Projects/iNiR`

## Default workflow

1. Read `mission.md`.
2. Read this file.
3. Read `AGENTS.md` / `CLAUDE.md`.
4. Inspect `git status --short` before editing.
5. Make the smallest reversible change.
6. Run nearest relevant checks.
7. Report changed files, checks, failures/skips, and next decision.

## Repo-specific rules

- Read vault `™ Mission.md` and `™ Factory Rules.md` before non-trivial work.
- Use small scoped changes; avoid broad feature-pile edits.
- Do not restart/kill Quickshell unless explicitly approved by active runtime protocol.
- Verify QML by checking syntax/runtime-relevant paths and visual behavior when possible.
- Respect live-config sync: repo is source of truth; do not claim runtime state without reading it.

## Validation gates

- Inspect `git status --short` before/after.
- Run nearest available QML/lint/smoke checks when present.
- For UI changes, capture screenshot/visual receipt and narrow-width behavior when relevant.

- Search/read back created governance files when changing context.

## Stop rules

Stop and report if:

- two fix attempts fail
- secrets/credentials are needed
- destructive cleanup or live service mutation is required
- scope expands beyond the vault mission
- cost/runaway loop risk appears
