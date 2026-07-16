# App-Forge

**The loop that ships applications.** An autonomous zero→shipped app builder for Claude Code: one invocation distills your idea into a spec and phased plan, gets **one** approval from you, then loops unattended — every iteration runs multi-agent orchestration, verifies with real checks, and commits green checkpoints — until every acceptance criterion is **proven** (or a circuit breaker stops it cleanly and tells you exactly why).

```
/app-forge "an invoice tracker for freelancers" in ~/dev/invoices
```

## How it works

```
idea ──▶ BOOTSTRAP: SPEC.md (runnable acceptance criteria)
              └▶ plan-forge workflow: 3 architecture proposals → judge panel → PLAN.md
              └▶ ★ the one human gate: you approve the plan ★
loop ──▶ each cycle: read .forge/ state
              └▶ batch file-disjoint tasks → parallel specialist agents
                 (designer, test-engineer, code-reviewer, security-reviewer, …)
              └▶ adversarial verify per task → ORCHESTRATOR re-runs every check itself
              └▶ green → git checkpoint · red → bounded fix → breaker counters
done ──▶ TERMINATION: every acceptance criterion executed with logged evidence
              └▶ review-gate workflow (adversarial, loop-until-dry) → git tag forge-shipped
```

The engine is a self-pacing loop: background-workflow completion re-invokes the session (primary wake signal); a ScheduleWakeup heartbeat is the fallback. No polling, no busy-waiting.

## The five beats

Every real loop has the same anatomy, and App-Forge implements all five — with a decision-maker inside:

1. **Find the work** — the next file-disjoint batch from `PLAN.md`.
2. **Do it** — specialist agents, one task each, in parallel.
3. **Check itself** — adversarial verifiers, then the orchestrator re-runs every check; plus a **goal check** each cycle that asks "are we at the SPEC yet — what's the biggest gap?" and feeds the answer into the next batch.
4. **Remember** — `.forge/` state + journal + git checkpoints; no run ever starts from zero or repeats finished work.
5. **Go again** — until every acceptance criterion is proven and the goal gap is empty; then it stops and tells you.

And the honest inverse — **when not to loop**: one-off tasks (a prompt is faster), vague goals ("make it better" has no bar to measure), and budget-tight work (self-checking loops run agents several times per item).

## Why it's reliable

- **The disk is the truth.** All loop state lives in `.forge/` + git checkpoints in your project. Sessions can die, contexts can be summarized — any fresh session resumes with `/app-forge <dir>`.
- **Done = proven.** Subagent reports are treated as claims. The orchestrator re-runs every build, test, and browser smoke check itself before anything is checked off. Acceptance criteria must be runnable commands or observable browser checks — "works well" is banned at spec time.
- **Green checkpoints only.** It never commits a red tree "to save progress".
- **Safe parallelism.** Tasks are batched by file-disjointness; subagents are locked out of manifests and shared config (the orchestrator pre-installs dependencies).
- **Circuit breaker.** 3 cycles without progress, the same error 3×, an iteration cap, and an optional token budget all stop the loop gracefully — with a `RESUME.md` explaining exactly where it stands.
- **One gate, then autonomy.** After plan approval it never blocks on you; if genuinely stuck it stops cleanly instead of waiting. Deploys only happen if you explicitly asked.

## Self-learning: better with every use

App-Forge keeps two memories. Inside a project, `.forge/LESSONS.md` captures every failure → cause → rule and injects it into every agent. Across projects, a global **BRAIN** (`~/.claude/app-forge/BRAIN.md`) holds only the *transferable* rules — stack gotchas, batching traps, verification blind spots — each tagged by scope and scored by how often it recurs. Every run ends with a retro (including failed runs — they teach the most): telemetry to `runs.jsonl`, transferable lessons promoted or sharpened in the BRAIN, and defects in the skill itself queued as human-reviewed proposals rather than silent self-edits. The BRAIN is capped and pruned — the goal is a falling mistake rate, not a growing list — and run #10 plans, batches, and verifies measurably smarter than run #1.

## Agent-ecosystem routing (v0.2.0)

App-Forge discovers the specialist agents available in *your* session (designer, test-engineer, code-reviewer, security-reviewer, debugger, executor, plugin agents…) and routes each task to the best fit — UI to designers, tests to test engineers, review lenses to reviewers. Missing specialists degrade gracefully to default agents; nothing hard-depends on a specific registry. Skill-owned commands (deploys, eval harnesses) can run as plan phases with their output as verify evidence.

## Install

```bash
git clone https://github.com/Eskapeum/App-Forge ~/.claude/skills/app-forge
```

Restart Claude Code (or start a new session) — `/app-forge` appears in your skills.

## Usage

| Command | What it does |
|---|---|
| `/app-forge "<idea>" in <dir>` | Bootstrap: spec → plan → your approval → loop starts |
| `/app-forge "<idea>" in <dir> watch` | Same, but cycle 1 runs narrated in front of you — trust it first, then it goes autonomous |
| `/app-forge <dir>` | Continue/resume the loop (any session, any time) |
| `/app-forge status <dir>` | Where it stands — no work performed |
| `/app-forge stop <dir>` | Graceful stop (halts the in-flight orchestration too) with resume instructions |
| `/app-forge rollback <dir> [sha]` | Journal-preserving reset to the last (or a given) green checkpoint |

You can also just *talk* to a running loop: questions get a status answer, small steers become plan tasks, scope changes pause + re-gate. See a full worked run in [examples/EXAMPLE-RUN.md](examples/EXAMPLE-RUN.md).

## Requirements

Claude Code with the `Workflow` and `ScheduleWakeup` tools (current desktop/CLI builds). Without `Workflow` it degrades to parallel `Agent` fan-out; without `ScheduleWakeup` it runs cycles back-to-back in-turn. Verification never degrades.

## Anatomy

```
SKILL.md                       modes · hard rules · bootstrap · run cycle · termination
references/state-contract.md   .forge/ layout · PLAN grammar · STATE schema · recovery matrix
references/iteration-engine.md the wake cycle · batching · fix bounds · degraded mode
references/workflows.md        plan-forge · build-iteration · review-gate (+ schemas)
references/agent-routing.md    registry discovery · routing table · fallbacks
references/verification.md     acceptance-criteria rules · proof matrix · browser smoke
templates/                     SPEC · PLAN · RESUME · STATE
```

---
Built by [Eskapeum](https://github.com/Eskapeum). MIT licensed — see [LICENSE](LICENSE). Current version: see [CHANGELOG.md](CHANGELOG.md).
