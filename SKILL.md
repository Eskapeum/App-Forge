---
name: app-forge
description: Autonomous zero→shipped application builder — a self-pacing loop where every iteration runs multi-agent Workflow orchestration (parallel implementers, adversarial verifiers), commits green checkpoints, and stops only when every acceptance criterion is proven. Triggers on - app-forge, "build this app autonomously", "overnight build", "loop-build an application", "keep building until it ships". DO NOT trigger on - single features in an existing repo, one-shot scripts, production debugging, or tasks needing continuous human judgment.
---

# App-Forge — the loop that ships applications

One invocation → SPEC → PLAN → **one approval** → autonomous iterations until every acceptance criterion is **proven**. The session is the engine; **the disk is the truth**.

## Requirements & capability gates

- Needs: `Workflow`, `ScheduleWakeup`, `Bash`, git. **This skill's instructions are the standing opt-in to call Workflow.**
- No `Workflow` tool? Degrade to parallel `Agent` calls — same batching, same schemas, same verification, same specialist routing via `subagent_type` (references/iteration-engine.md §7). Never skip verification because a tool is missing.
- No `ScheduleWakeup` (one-shot context)? Run cycles back-to-back in-turn; at context/budget limits stop cleanly with RESUME.md.
- Load deferred tools via ToolSearch in ONE call when entering run mode: `select:ScheduleWakeup,TaskStop,TaskList,PushNotification` (plus `EnterWorktree` only if escalating to worktree isolation).

## Modes (one skill, arg-dispatched)

| Invocation | Mode |
|---|---|
| `/app-forge "<idea or spec path>" [in <dir>]` | **Bootstrap** — no `.forge/` at target |
| `/app-forge "<idea>" in <dir> watch` | Bootstrap, then run **cycle 1 foreground-narrated** (trust-building); autonomous from cycle 2 |
| `/app-forge <dir>` | **Run** — continue the loop (`.forge/STATE.json` exists) |
| `/app-forge status <dir>` | Report state + journal tail; do no work |
| `/app-forge stop <dir>` | Graceful stop: **TaskStop the active workflow** (if `activeWorkflowRunId` set) → clear it → STATE `status:"stopped"` + `stopReason:"user stop"` → update RESUME.md → `ScheduleWakeup {stop:true}` |
| `/app-forge rollback <dir> [sha]` | Journal-preserving reset to `lastCheckpoint` (or the given checkpoint) — PLAN checkboxes restore atomically with the tree (state-contract.md recovery matrix) |

Detection rule: target has `.forge/STATE.json` → run mode; else bootstrap. Read references/state-contract.md before any read/write of `.forge/`.

## When not to loop (be honest at intake)

- **One-off, single-answer job** → a plain prompt/agent is faster; loops earn their setup cost on many-piece work.
- **No measurable finish line** ("make something better") → vague work doesn't loop. Sharpen it into bars at bootstrap or decline — never start the loop on a vague SPEC.
- **Cost sensitivity** → a self-checking loop runs agents several times per item. Say so up front; set `iterationCap`/budget to match.

## Hard rules (non-negotiable)

1. **Disk is truth.** Every turn begins by reading `.forge/` — never act from remembered context; it may be a summary.
2. **Done = proven.** The orchestrator (you, main context) runs builds/tests/smoke itself. Subagent reports are claims, not evidence.
3. **One human gate.** Plan approval at bootstrap. After it, never block on the user — if genuinely stuck, STOP cleanly (RESUME.md + summary). Stopping well beats waiting.
4. **Green checkpoints only.** Commit only when the batch verifies green. Never commit red "to save progress".
5. **Manifest lockdown.** Subagents never touch package.json / lockfiles / shared config / generated files. The orchestrator pre-installs deps and makes shared edits before fan-out.
6. **Lessons loop — two tiers.** Every failure → cause → rule in `.forge/LESSONS.md` (project tier), injected into every agent prompt together with the filtered global BRAIN (`~/.claude/app-forge/BRAIN.md`). Every run ends with a retro that promotes transferable rules into the BRAIN — the skill gets smarter with every use (references/self-learning.md).
7. **Stop conditions win.** Circuit breaker / iteration cap / budget → graceful stop. Never a runaway loop.

## Bootstrap (iteration 0)

1. Distill the idea (or read the given spec file) → write `.forge/SPEC.md` from templates/SPEC.template.md — goals, non-goals, stack (one-line justification), and **acceptance criteria: each one a runnable command or observable browser check** (references/verification.md §1). **The bar rule:** every goal gets a bar the loop can measure; a vague idea is sharpened here (or asked about at the gate) — never looped as-is. Then **preflight the toolchain** (node/git/package manager versions for the chosen stack) so missing pieces surface at the gate, not in cycle 1.
2. **Discover the agent registry** (references/agent-routing.md §1): map task kinds → the specialist agent types actually available this session; store in STATE.json `agents`. **Load the BRAIN**: read `~/.claude/app-forge/BRAIN.md` (if present), filter rules for this stack (references/self-learning.md §3).
3. Run the **plan-forge Workflow** (references/workflows.md §1) with the discovered `agentTypes` + filtered `brain` rules: 3 independent architecture+phasing proposals → judge panel → synthesis (tasks come back with `agent:` hints).
4. Write `.forge/PLAN.md` from templates/PLAN.template.md: phases → atomic tasks, each annotated `files:` `needs:` `verify:` (+ optional `agent:`, validated against the registry).
5. **THE GATE:** present, in this order: (a) the **acceptance criteria first, with an explicit invitation to challenge them** — the model wrote bars it knows it can pass, and this gate is the only defense; (b) the plan; (c) a **cost estimate** (`tasks × ~3 agent calls + verification ≈ N invocations`) and the preflight results. Then AskUserQuestion (approve / tweak / re-plan). If the dialog is unavailable or dismissed, end the turn asking for approval in chat — bootstrap is the one place waiting is correct.
6. On approval: `git init` if needed → commit `forge: bootstrap — spec + plan` → write STATE.json (templates/STATE.template.json), RESUME.md, empty JOURNAL.md + LESSONS.md → enter run mode immediately. (**watch mode:** launch cycle 1, narrate each step as its notifications arrive, and do not schedule cycle 2 until the user has seen the green checkpoint.)

## Run mode — one wake = one cycle

Full mechanics: references/iteration-engine.md. The shape:

1. **Read state**: STATE.json, PLAN.md unchecked tasks, LESSONS.md, JOURNAL.md tail. Breaker/cap check first — may go straight to stop. Fresh session? Re-validate STATE `agents` against the current registry (agent-routing.md §1).
2. **Workflow already out** (`activeWorkflowRunId` set)? Running → reschedule heartbeat, end turn. Finished → process results (step 7). Hung/dead → TaskStop, then resume via `resumeFromRunId` or relaunch the batch.
3. **Select batch**: next ≤ `batchSize` unchecked tasks in the current phase with `needs:` satisfied and pairwise-disjoint `files:`.
4. **Pre-fan-out (orchestrator, inline)**: new deps, schema/config/shared-file edits. Commit if changed.
5. **Launch build-iteration Workflow in background** (references/workflows.md §2) with the batch + SPEC excerpt + LESSONS content, each task routed to its specialist agent (`agent:` hint or the routing table — references/agent-routing.md §2–3). Record `activeWorkflowRunId` in STATE.json.
6. **ScheduleWakeup** — fallback heartbeat `heartbeatSeconds` (default 1800), prompt `/app-forge <dir>`, reason `"app-forge heartbeat — iteration N of <project>"`. End the turn. Workflow completion re-invokes you sooner; do NOT schedule short wakeups to poll.
7. **Process completion**: verify YOURSELF — build + affected tests; at phase end add full suite + browser smoke (references/verification.md §3).
   - **Green** → check off tasks in PLAN.md, commit `forge: i<N> — <task ids> [green]`, journal with evidence, `iteration++`, reset `consecutiveNoProgress`, clear runId.
   - **Red** → ONE bounded fix pass (inline if small; fix workflow if not). Still red → journal the failure, `consecutiveNoProgress++`, track the error signature; 3× same signature → mark the task `[blocked: <sig>]` in PLAN.md and move on.
8. **Goal check — the second look**: after a green cycle, step back from tasks to the SPEC: *are we at the goal yet? What's the single biggest gap?* Record it as `goalGap` in STATE.json + the journal. A real gap no remaining task covers becomes a new `[gap]` task in PLAN.md (same grammar, needs a `verify:`). This beat steers the loop — checking tasks proves work; checking the goal aims it.
9. **Loop or terminate**: unchecked tasks remain and breaker is clear → step 3 in the SAME turn (gap tasks first). All tasks done (or only blocked ones left) and `goalGap` empty → termination sequence.

## Mid-run messages (the user WILL talk to a running loop)

A user message that isn't an `/app-forge` command, arriving while `status:"running"`, gets ROUTED — never treated as a normal coding request against files a workflow may be editing:

- **Question** ("what's happening?") → answer as `/app-forge status`: state, current batch, last checkpoint. No work.
- **Small steer** ("make the header blue") → append a `[gap]` task to PLAN.md (full grammar, `verify:` required), acknowledge, let the loop pick it up next cycle.
- **Scope change** ("switch to Postgres", "also add auth") → pause: TaskStop the active workflow → update SPEC.md + PLAN.md (rerun plan-forge if structural) → **re-gate** (one new approval) → resume.
- **Never** hand-edit project files in direct response to a mid-run message while a workflow is in flight — two writers, one tree.

## Termination — the proof, not the vibe

1. Execute EVERY acceptance criterion in SPEC.md; log command + result as evidence in JOURNAL.md. Any failure → back to run mode with fix tasks (still bounded by the breaker).
2. **review-gate Workflow** (references/workflows.md §3): adversarial finders loop-until-dry; majority-refute verification; surviving findings become one final fix batch.
3. **Retro — harvest the learning** (references/self-learning.md §4): run record → `runs.jsonl`; transferable lessons promoted/merged into the global BRAIN (generalize-or-drop, dedup, hits, prune); skill-defect findings → `PROPOSALS.md` (never edit the skill itself mid-run).
4. All green → final commit + `git tag forge-shipped-<YYYY-MM-DD>` (date-suffixed — re-runs on the same project don't collide; same-day re-ship appends `-2`) → STATE `status: "done"` → update RESUME.md → `ScheduleWakeup {stop: true}` → final summary (what shipped, evidence table, how to run it, learning delta, any unverified review-gate flags) + PushNotification if available.
5. Blocked stop instead: **retro still runs** (failed runs teach the most) → STATE `status: "stopped"` + `stopReason`; RESUME.md tells the next context exactly where it stands and how to continue.

## Circuit breaker

- 3 consecutive cycles without a green commit → stop with diagnosis.
- Same error signature 3× on one task → block that task; ALL remaining tasks blocked → stop.
- `iteration ≥ iterationCap` (default 50) → stop.
- Token target given at launch (e.g. "+500k") → guard workflows with `budget.remaining()` (references/workflows.md §4).

## Skill hooks (optional, capability-gated)

- **Design**: for UI-heavy phases, invoke available design skills (e.g. design-forge, frontend-design) as an in-iteration step — they inform the build; they never replace verification.
- **Ship**: only if the user asked for deployment and a deploy path exists (e.g. vercel) — final phase; its verify = the deployed URL responds.

## Reference index

| File | Read when |
|---|---|
| references/state-contract.md | Any read/write of `.forge/`; any recovery |
| references/iteration-engine.md | Run mode — every cycle |
| references/workflows.md | Launching any Workflow |
| references/agent-routing.md | Bootstrap discovery; resolving who does each task |
| references/self-learning.md | Bootstrap BRAIN load; every retro (termination AND breaker stop) |
| references/verification.md | Writing acceptance criteria; verifying; terminating |

## Common mistakes

| Mistake | Rule |
|---|---|
| Trusting an implementer's "done" | Orchestrator re-runs every check (Hard rule 2) |
| Scheduling 60s wakeups to poll the workflow | Completion re-invokes you; heartbeat is a 1800s fallback |
| Parallel agents editing package.json | Manifest lockdown (Hard rule 5) |
| Committing red "to save progress" | Green checkpoints only (Hard rule 4) |
| Asking the user anything mid-run | One gate; stop cleanly instead (Hard rule 3) |
| Rebuilding the plan from memory after summarization | Disk is truth (Hard rule 1) |
| A task with no `verify:` command | Unverifiable = unplannable; fix the PLAN first |
| Hardcoding an agent type the session doesn't have | Discover + fall back (agent-routing.md §1) |
| Routing an implement task to a read-only advisor agent | Check tool grants; advisors judge, executors build (agent-routing.md §3) |
| Skipping the retro on a breaker stop | Failed runs teach the most — retro runs on EVERY stop (self-learning.md §4) |
| Promoting project trivia to the BRAIN | Generalize-or-drop; falsifiable rules only (self-learning.md §5) |
| Global build/suite inside a parallel implementer | File-scoped checks only; the orchestrator builds once, post-batch (iteration-engine §5) |
| Treating a crashed agent as a red implementation | Partition results; requeue agent-errored, commit the green subset (iteration-engine §5) |
