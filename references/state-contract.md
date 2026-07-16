# State contract — `.forge/` is the truth

Everything the loop knows lives on disk in the target project. Any fresh context — a resumed session, a brand-new chat, a different harness — must be able to continue from these files alone. Never store loop state only in conversation.

## Layout

```
<project>/.forge/
├── SPEC.md        what we're building + runnable acceptance criteria   (written once, edited only at the gate)
├── PLAN.md        phases → atomic tasks with checkboxes                (backlog truth; checked off as proven)
├── STATE.json     machine cursor (small, overwritten every cycle)
├── JOURNAL.md     append-only per-cycle log with evidence
├── LESSONS.md     append-only self-learning; injected into every agent prompt
└── RESUME.md      standing instructions for any fresh context
```

## PLAN.md task grammar

```markdown
## P2 — Core data layer   [phase-verify: npm test]
- [ ] P2.1 SQLite schema + migrations · files: src/db/** · verify: `npm test -- db`
- [ ] P2.2 CRUD API routes · files: src/api/** · needs: P2.1 · verify: `npm test -- api`
- [x] P2.3 Seed script · files: scripts/seed.ts · needs: P2.1 · verify: `npm run seed && npm test -- seed`
- [ ] P2.4 Auth middleware · files: src/auth/** · needs: P2.2 · verify: `npm test -- auth` [blocked: jwt-lib-esm-error]
```

Rules:
- Every task has a stable id (`P<phase>.<n>`), a `files:` glob (drives disjoint batching), optional `needs:` (task ids), optional `agent:` (specialist routing hint, see agent-routing.md §4), and a **runnable** `verify:` command. A task without `verify:` is invalid — fix the plan before executing it.
- `[blocked: <signature>]` suffix marks circuit-broken tasks. Blocked ≠ checked.
- `[gap]` prefix in the task text marks tasks inserted by the goal check (iteration-engine.md §5a) — same grammar, selected first.
- Checking off a task is done ONLY by the orchestrator after ITS OWN verification passes (Hard rule 2).
- Phases carry a `[phase-verify: <command>]` run when the last task of the phase goes green, plus browser smoke for web apps.

## STATE.json schema

```json
{
  "version": 1,
  "project": "invoice-tracker",
  "createdAt": "2026-07-15T22:00:00Z",
  "status": "running",
  "phase": "P2",
  "iteration": 7,
  "batchSize": 4,
  "iterationCap": 50,
  "heartbeatSeconds": 1800,
  "consecutiveNoProgress": 0,
  "errorSignatures": { "jwt-lib-esm-error": 3 },
  "agents": { "ui": "designer", "tests": "test-engineer", "verify": "code-reviewer", "security": "security-reviewer" },
  "goalGap": null,
  "activeWorkflowRunId": null,
  "lastCheckpoint": "a1b2c3d",
  "stopReason": null
}
```

- `status`: `bootstrapping | running | stopped | done`.
- `activeWorkflowRunId`: set when a build-iteration Workflow is launched; cleared after its results are processed. This is how a wake knows whether work is already in flight — never launch a second workflow while one is set (check it first; see iteration-engine.md §2).
- `errorSignatures`: short slugs of repeated failures (first line of the error, normalized). Used for the same-error-3× breaker.
- `agents`: the routing map discovered from this session's agent registry (agent-routing.md §1) — kinds → available specialist types. Re-validate on a fresh session; registries differ.
- `goalGap`: the goal check's current answer to "what's the single biggest gap between the app and the SPEC?" (`null` = at goal so far). Steers the next cycle's batch; termination requires it empty.
- Overwrite the whole file atomically each cycle (write temp + `mv`). It must always parse.

## JOURNAL.md entry format

```markdown
## i7 · 2026-07-15T23:41Z · P2.1 P2.2 · GREEN · commit a1b2c3d
- verify: `npm run build` → exit 0 · `npm test -- db api` → 14 passed
- notes: verifier flagged missing FK index on invoices.user_id — added.
```

One entry per cycle, appended, never edited. RED entries record the failing command + first error lines — that text is the error signature source.

## LESSONS.md

Same discipline as a project lessons file: after any failure or correction, append *what went wrong + the rule that prevents a repeat*. The full file is injected into every implementer and verifier prompt, so keep entries short and rule-shaped. Prune duplicates when appending.

This is the **project tier** only. The **global tier** — `~/.claude/app-forge/` (BRAIN.md rules, runs.jsonl telemetry, PROPOSALS.md skill-edit queue) — lives outside both the project and the skill install; the retro promotes transferable lessons there at every stop (references/self-learning.md).

## RESUME.md

Written at bootstrap, updated at every stop. Contents: project path, current status one-liner, and the exact continuation command (`/app-forge <dir>`), plus anything a fresh context must know that isn't derivable from the other files (e.g. "dev server needs Node 22", "user wants no deploy"). Keep under a screen.

## Git conventions

- Checkpoint per green cycle: `forge: i<N> — <task ids> [green]`.
- Bootstrap commit: `forge: bootstrap — spec + plan`.
- Termination: `git tag forge-shipped`.
- Never commit red (Hard rule 4). Never rewrite history; the checkpoint chain is the recovery ladder — a broken tree recovers with `git reset --hard <lastCheckpoint>` and a journal note.

## Recovery matrix

| Situation | Recovery |
|---|---|
| Fresh session / session died | `/app-forge <dir>` → run mode reads disk; RESUME.md orients |
| Context was summarized mid-run | Hard rule 1 — every turn re-reads `.forge/`; trust files over memory |
| Workflow hung (heartbeat fired, runId still active) | Check task status → TaskStop → relaunch batch, or `resumeFromRunId` |
| Workflow finished but results lost | Re-read its journal (`<transcriptDir>/journal.jsonl`) before assuming; else relaunch the batch — verification makes relaunch idempotent |
| Working tree broken / red beyond fixing | `git reset --hard <lastCheckpoint>`, journal it, `consecutiveNoProgress++` |
| STATE.json corrupt | Rebuild from PLAN.md checkboxes + `git log` (iteration = checkpoint count); journal the rebuild |
