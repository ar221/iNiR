# Agent Cockpit (ASP-01)

Compact operator surfaces for AI workflows in iNiR.

## Surfaces

- **Provider Profile chip (bar)**
  - Presets: `local-only`, `balanced`, `quality-max`, `budget`
  - Left-click cycles forward, right-click cycles backward.
  - Shows `PROFILE · PROVIDER` route.
  - Bar context menu includes **Interrupt Agent Request** while running.

- **Context Staging card (dashboard)**
  - Live staged facts: current model route, provider, tool mode, pending attachment.
  - Add note, reorder, remove.
  - Power keymap (when enabled):
    - `Ctrl+Shift+A` add note
    - `Ctrl+Shift+J/K` select next/prev
    - `Alt+Up/Down` move selected
    - `Delete` remove selected

- **Agent Loop card (dashboard)**
  - Displays loop phase: Context → Prompt → Execution → Review → Iterate.
  - Live run state + current model + proxy statuses.
  - Controls: **Interrupt Current Request**, **Stop Proxies**.

- **Session Review card (dashboard)**
  - Reads `~/.local/state/inir/activity-feed.jsonl`.
  - Shows latest events with risk and reversibility hints.
  - Quick actions: open feed, open revert path.

- **Trust Policy card (dashboard)**
  - Modes: `strict`, `balanced`, `open`.
  - `strict`: command tool calls always require approval.
  - `balanced`: auto-approve commands matching safe prefixes.
  - `open`: auto-approve command tool calls.

- **Mobile Companion card (dashboard)**
  - Read-only status and approval visibility.
  - Writes snapshot to `~/.local/state/inir/agent-companion.json`.
  - `Send to Hermes Now` appends queue entries to `~/.local/state/inir/hermes-telegram-handoff.jsonl`.
  - Queue drain helper: `scripts/ai/drain-hermes-handoff-queue.py` (consume + clear consumed entries).

## Config keys

```json
{
  "bar": {
    "agentProfile": {
      "enabled": true,
      "current": "balanced"
    }
  },
  "dashboard": {
    "agentCockpit": {
      "enable": true,
      "mobileCompanion": true,
      "powerKeymap": true,
      "trustPanel": true
    },
    "agentTrust": {
      "mode": "balanced",
      "allowSafeInBalanced": true,
      "safeCommandPrefixes": ["pwd", "ls", "whoami", "uname", "date", "uptime", "git status", "git diff"]
    },
    "sections": {
      "agentContext": true,
      "agentLoop": true,
      "sessionReview": true,
      "agentTrust": true,
      "agentCompanion": true
    }
  }
}
```
