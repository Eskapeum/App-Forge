# Iteration engine — one wake, one cycle

The loop has two wake sources: **background-Workflow completion** (primary — the harness re-invokes you when it finishes) and the **ScheduleWakeup heartbeat** (fallback — fires only if nothing else woke you). Every wake runs this engine top to bottom. Steps are ordered; do not skip the reads.

## 1 · Read state (always, first)

Read `.forge/STATE.json`, PLAN.md (parse unchecked + blocked tasks), LESSONS.md, last ~3 JOURNAL.md entries, and the global BRAIN (`~/.claude/app-forge/BRAIN.md`, filtered by stack — self-learning.md §3). Then gate:

- `status` is `done` or `stopped` → report and end (no wakeup).
- Breaker tripped (see §6) → termination-by-stop: write stopReason, RESUME.md, summary, `ScheduleWakeup {stop:true}`.
- Otherwise continue.

## 2 · In-flight workflow check

If `activeWorkflowRunId` is set, the previous cycle's orchestration may still be out:

- **Still running** (TaskList/notifications say so) → do nothing else: reschedule the heartbeat (`heartbeatSeconds`), end turn.
- **Completed** → process its results (§5).
- **Hung/dead** (no progress since last heartbeat, or task errored) → `TaskStop` it, journal the event, then either `Workflow {scriptPath, resumeFromRunId}` (cached prefix re-used) or relaunch the batch fresh. Count a hang as `consecutiveNoProgress++`.

## 3 · Select the batch

From the current phase's unchecked, unblocked tasks (`[gap]` tasks first — they exist because the goal check found the plan short):

1. Filter to tasks whose `needs:` are all checked.
2. Greedily take up to `batchSize` tasks whose `files:` globs are **pairwise disjoint** (string-prefix comparison on the glob roots is enough — `src/db/**` vs `src/api/**` is disjoint; anything ambiguous is NOT disjoint).
3. Nothing selectable but unchecked tasks remain → the plan has a dependency knot or everything overlaps: take the single next task alone (batch of 1 is always legal).
4. No unchecked tasks at all → termination sequence (SKILL.md).

Batch size 1 is normal near phase ends. Parallelism is a bonus, not a goal — correctness of the disjointness rule is what keeps a shared working tree safe. If two tasks genuinely must touch the same files concurrently, don't parallelize them; serialize across cycles. Escalate to worktree isolation (`isolation: 'worktree'` per agent) only when a batch is large AND overlap is unavoidable — merging worktrees is the orchestrator's job and costs more than serializing in most cases.

## 4 · Pre-fan-out (orchestrator-only work)

Subagents are locked out of shared files (Hard rule 5), so do their shared groundwork now, inline:

- Install any dependencies the batch's tasks name (`npm i <pkg>` etc.).
- Create/modify shared config, schema files, route registries, barrel exports the tasks will need.
- Commit if anything changed: `forge: i<N> pre — deps/config for <task ids>`.

Then launch the **build-iteration Workflow in the background** with: the batch (id, text, files, verify per task), a SPEC excerpt (goals + relevant ACs), the merged lesson payload (filtered global BRAIN rules + full project LESSONS.md), and the stack facts agents need (run commands, test runner). Write `activeWorkflowRunId` to STATE.json. Schedule the fallback heartbeat (prompt `/app-forge <dir>`, delay `heartbeatSeconds`, reason names the project + iteration). **End the turn.** Do not busy-wait, do not schedule short polls — completion re-invokes you.

## 5 · Process results (the orchestrator verifies)

Workflow results are **claims**. Verify in this order, yourself, via Bash:

1. Per-task `verify:` commands for the batch.
2. Project build (`npm run build` or stack equivalent).
3. Phase boundary crossed? → `[phase-verify:]` command + full test suite + browser smoke for web apps (verification.md §3).

**All green:**
- Check off the batch's tasks in PLAN.md; advance `phase` if its last task closed.
- Commit `forge: i<N> — <task ids> [green]`; update `lastCheckpoint`.
- Append the JOURNAL entry with evidence lines; `iteration++`; `consecutiveNoProgress = 0`; clear `activeWorkflowRunId`.
- Any workflow-reported insight worth keeping → LESSONS.md.

### 5a · Goal check (after a green cycle)

Tasks proving green tells you the work is *correct*; it doesn't tell you the loop is *aimed right*. After processing a green cycle, take the second look: re-read SPEC goals + ACs against the app as it now stands and answer two questions — *at goal yet? what's the single biggest gap?* (Inline for the orchestrator, or one cheap agent call if the judgment is large.)

- Write the answer to STATE.json `goalGap` (`null` when nothing's missing) and note it in the journal entry.
- A real gap that **no remaining task covers** → append a `[gap]` task to PLAN.md (same grammar — it still needs `files:` and a runnable `verify:`), and journal why it was added.
- Gap tasks are selected FIRST next cycle (§3). Termination requires `goalGap` empty as well as tasks done — a loop that finishes its checklist while missing the goal isn't done.
- Keep it honest: the goal check compares against the SPEC as approved, not against new scope. Ideas beyond the SPEC go in the final summary, not into PLAN.

**Red:**
- ONE bounded fix pass: small/obvious → fix inline; multi-file → a fix workflow (build-iteration with a single synthesized fix task). Re-verify.
- Still red → journal RED with the failing output head; normalize it to an error signature; `errorSignatures[sig]++`; `consecutiveNoProgress++`; signature at 3 → mark the offending task `[blocked: <sig>]` in PLAN.md and append a LESSONS entry. Reset the working tree to `lastCheckpoint` if the failure left it broken.

## 6 · Continue, stop, or finish

- Breaker math (checked at §1 and after every red): `consecutiveNoProgress >= 3` → stop. All remaining tasks blocked → stop. `iteration >= iterationCap` → stop.
- Unchecked tasks remain, breaker clear → **loop to §3 in this same turn** (launch the next batch now; don't wait for the heartbeat).
- No unchecked tasks AND `goalGap` empty → termination sequence (SKILL.md): prove all ACs → review-gate → ship → stop. (A non-empty `goalGap` means §5a just added a `[gap]` task — keep looping.)

A **stop** is always graceful: STATE `status:"stopped"` + `stopReason`, RESUME.md updated with exactly where it stands and what to do next, `ScheduleWakeup {stop:true}`, and a user-facing summary that leads with the blocker.

## 7 · Degraded mode (no Workflow tool)

Same engine, different muscle: fan the batch out as parallel `Agent` calls (one implementer per task, `run_in_background: true`, `subagent_type` from the routing map — agent-routing.md), collect completions as they notify, then run a verifier `Agent` per changed task (or verify directly yourself for small batches). All other rules — disjoint batching, manifest lockdown, orchestrator verification, checkpoints, breaker — unchanged.

## Timing defaults

| Knob | Default | Meaning |
|---|---|---|
| `batchSize` | 4 | max parallel tasks per cycle |
| `heartbeatSeconds` | 1800 | fallback wakeup; completion usually re-invokes sooner |
| `iterationCap` | 50 | hard ceiling per run |
| fix passes per cycle | 1 | then journal red + breaker counters |
