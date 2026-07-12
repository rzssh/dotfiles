# AI workflow

## Goal

Provider-agnostic agent workflow with visible terminals, local memory, cheap defaults, and cloud power only when worth it.

## Roles

Human: owns goals, taste, architecture, final merge.

Herdr: visible terminal runtime. Panes, state, reads, sends.

Fleetpit: fleet control plane. Workspaces, profiles, role routing, starts, swaps, handoffs, output, and audit log.

Pi: main coding harness. Provider switchboard, lead sessions, worker sessions, subagents later.

Hermes: phone gateway and recurring personal automation. Telegram, cron, reminders, daily reports.

agentmemory: local working memory. Pi and Hermes may read/write. Cloud agents do not connect directly.

Obsidian/wiki: human-readable canonical notes. Slower, curated, editable outside agents.

Codex/GPT: strong planner or hard-code agent. Gets scoped files, diffs, logs, memory slices.

Claude Code: reviewer/specialist. Gets plans, diffs, failing tests, no full memory.

OpenCode/cheap models/local models: optional Pi-backed builders, scouts, repetitive edits, mechanical checks.

Crit: feedback/review surface. Useful for human-in-loop review, not replacement for tests.

## Rules

Local sees memory. Cloud sees packets.

Default to one lead and one worker. Add more agents only for parallel search, review, or urgent race.

Planning needs strongest model when architecture/risk is high. Cheap model is fine for scouts and mechanical edits.

Verifier means executable check: `nix build`, tests, typecheck, lint, app smoke, screenshot check. Crit is feedback, not verifier.

Hermes cron prompts must be self-contained. Cron starts fresh, so include repo, command, format, delivery target.

No autonomous infinite loop on main machine. Long-running agents need sandbox or worktree and budget.

## Default Flows

Small bug:
1. Pi in Herdr reads issue and repo.
2. Pi asks scout/cheap model for file map if needed.
3. Pi or cheap worker edits.
4. Verifier runs.
5. Optional Claude/Codex reviews diff.
6. Pi saves one durable lesson if useful.

Hard bug:
1. Pi recalls scoped memory.
2. Codex plans with files, logs, failing test only.
3. Claude reviews plan if risky.
4. Pi worker with cheap model implements one phase.
5. Verifier runs after each phase.
6. Strong reviewer checks final diff.

Research:
1. Hermes or Pi asks researcher model.
2. Agent writes short result to wiki.
3. Only stable facts or preferences go into agentmemory.

Phone automation:
1. Telegram -> Hermes.
2. Hermes handles task if personal/local.
3. Hermes launches Herdr/Pi only for coding work.
4. Hermes sends summary back.

Daily briefing:
1. Hermes cron runs script/search.
2. Agent summarizes only changed/important items.
3. Telegram delivery.
4. Feedback updates skill/wiki, not giant chat memory.

## Model Defaults

Lead/planner: Codex/GPT high or Claude when architecture matters.

Controller: Pi harness, local or cheap model for context gathering.

Scout: cheap fast model.

Builder: Pi worker using cheapest model that passes verifier on this repo.

Reviewer: Claude/Codex strong model.

Memory curator: cheap local/cloud model, but only local input unless explicitly approved.

## MVP

1. Nix-install Pi.
2. Keep agentmemory service local.
3. Use Fleetpit team launcher with Pi lead, Pi worker, Claude reviewer.
4. Use Hermes only for Telegram + cron at first.
5. Add Pi subagents after plain Pi workflow feels stable.

## Fleetpit

`fleetpit` opens live TUI from any directory. It shows Herdr workspaces, assigned profiles, scoped roles, detected agents, recent output, and action history.

`fleetpit team start FOCUS` starts and registers:
- `lead` -> Pi lead
- `build` -> Pi worker
- `review` -> Claude

`fleetpit role list` shows active role targets.

`fleetpit send lead "message"` sends to current lead pane.

`fleetpit swap lead claude` starts a new Claude pane, asks old lead for a handoff packet, sends packet to new lead, and updates `lead` routing only after successful handoff.

Same Pi session can switch model with Pi UI. Cross-harness swap cannot preserve raw hidden context; it preserves a compact handoff packet.

Role state is scoped by Herdr socket and workspace ID. Different Herdr workspaces can each have their own `lead`, `build`, and `review`.

Preferred employer isolation:

```bash
fleetpit workspace create acme ~/work/acme/repo
fleetpit workspace create globex ~/work/globex/repo
```

Herdr docs say to use workspaces first. Named sessions are only for completely separate panes, sockets, and persisted runtime state.

Use one normal Herdr session as runtime. Use one workspace per employer/project/task. `fleetpit workspace create PROFILE [cwd]` creates workspace with `AI_PROFILE=PROFILE`.

If a workspace was created manually in Herdr, focus it and assign a profile:

```bash
fleetpit profile set acme
```

Unassigned workspaces default to `personal`.

Check current workspace profile:

```bash
fleetpit profile get
```

Use Fleetpit TUI for normal operation:

```bash
fleetpit
```

`fp` is Fish abbreviation. `ai-*` commands remain compatibility symlinks to Fleetpit.

Nix links `~/.local/share/ai/profiles` to ignored `config/ai/profiles` in this repo. Use real names: company slug, client slug, or `personal`.

Fish shells inside the session also source `~/.local/share/ai/profiles/PROFILE/env.fish` when present.

Agents launched by Fleetpit load `~/.local/share/ai/profiles/PROFILE/env` inside new pane before starting Pi, Claude, Codex, or another tool. Secret values never enter Herdr arguments or Fleetpit logs.

`fleetpit herdr PROFILE` remains available for hard isolation when client needs separate Herdr server/socket.

Role config may still include per-role env for exceptions:

```json
{
  "review-job-a": {
    "command": "claude --settings /home/razen/.config/ai/claude-job-a.json",
    "env": {
      "ANTHROPIC_API_KEY": "$JOB_A_ANTHROPIC_API_KEY"
    }
  }
}
```

API-key auth can be isolated per pane. Subscription/OAuth auth may need separate Claude/Pi profiles, setup tokens, containers, or separate OS users if provider stores credentials globally.

## Benchmarks

Daily selector: use your repos, not public leaderboard.

Track per task:
- pass/fail
- command used
- cost
- tokens
- time
- human correction count
- diff size

Task set:
- scout: find files and explain call graph
- bugfix: one failing test
- refactor: small API rename
- review: find real issue in diff
- docs/research: summarize source into wiki note

Run each candidate model through Pi with same prompt and same verifier.

DeepSWE: use as periodic external calibration. Run 5-10 task subset when choosing serious defaults. Do not use as daily benchmark; long-horizon tasks cost too much and may not match dotfiles/workflow work.
