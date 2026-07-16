# App-Forge — Changelog

## 0.5.0 — 2026-07-16

Hardening wave — every finding from a 3-lens adversarial review (independent design critic + code reviewer + author pass) implemented.

Criticals:
- review-gate: hard 5-round cap + structural dedup key (`file:line:severity` — prose summaries rephrase every round and never deduped) — the termination path can no longer loop unbounded.
- plan-forge: judges zip-with-proposals BEFORE filtering (a dead judge no longer crowns the wrong architecture); empty-proposals/empty-judges guards (no more `reduce([])` crash).

Majors:
- Shared-tree safety: implementer/verifier agents run FILE-SCOPED checks only; the global build/suite is orchestrator-only, once per batch, post-landing (was: 4 agents compiling each other's half-written code → false reds → breaker trips healthy projects).
- Scaffold contradiction resolved: `agent: orchestrator` sentinel — manifest-creating/shared-config tasks run inline, never fan out.
- `stop` now TaskStops the in-flight workflow before writing stopped state.
- NEW mid-run message protocol: question → status; small steer → `[gap]` task; scope change → pause + SPEC/PLAN update + re-gate; never hand-edit files while a workflow is in flight.
- Crash ≠ red: results partitioned green/red/agent-errored; errored tasks requeue without fix passes or breaker pollution; green subsets of partial batches commit.
- review-gate quorum: majority-of-survivors + minimum quorum 2; quorum failures surface as `unjudged` (re-refuted once, then disclosed) — dead skeptics can no longer silently clear or vanish findings.
- Dependency deadlock detection: needs-chains ending at `[blocked:]`/cycles stop immediately with a real diagnosis; batch-of-1 fallback restricted to file-overlap (never runs tasks with unmet needs).
- Prose fix: passing check is `verdict.verdict === 'pass'` (was `verdict.pass` — always falsy if read literally).

Gate + robustness:
- Bootstrap gate: ACs presented FIRST with an explicit challenge invitation (self-written-bars defense), cost estimate (`tasks × ~3 calls ≈ N invocations`), toolchain preflight.
- `git tag forge-shipped-<date>` (re-run collision fix); journal-preserving reset (bare `reset --hard` destroyed post-checkpoint JOURNAL entries); iteration reconstruction counts `[green]` commits only; error-signature normalization defined; PLAN parsing rules (` · <keyword>:` boundaries, backticked `[phase-verify:]`); STATE template gains `agents:{}`; BRAIN contradiction check on merge; model policy — judge/refute/goal stages may pin the strongest tier (e.g. `fable`).
- NEW `/app-forge rollback <dir> [sha]` mode · NEW scripts/validate.sh (shipped validator) · NEW examples/EXAMPLE-RUN.md · watch-mode wording aligned with background-workflow reality.

## 0.4.0 — 2026-07-16

Cross-run self-learning: the skill gets smarter with every use.

- NEW references/self-learning.md + templates/BRAIN.template.md — two-tier memory: project `.forge/LESSONS.md` + global `~/.claude/app-forge/` (BRAIN.md deduped transferable rules with scope tags + hits counters; runs.jsonl telemetry; PROPOSALS.md human-reviewed skill-edit queue — the skill never edits itself mid-run).
- **Retro at every stop** (termination AND breaker stops — failed runs teach the most): generalize-or-drop promotion, dedup/merge with rule-sharpening on repeat violations, 100-rule cap with hits-based pruning, learning delta in the final summary.
- **Injection**: BRAIN filtered by stack feeds plan-forge (`args.brain`) and merges with project lessons into every implementer/verifier prompt; fix passes check the BRAIN for known failure modes first.
- SKILL.md: Hard rule 6 → two tiers; BRAIN load at bootstrap; retro steps in termination; +2 Common mistakes. README: self-learning section.

## 0.3.0 — 2026-07-16

Loop-engineering hardening (the five-beats discipline) + MIT license.

- **Goal check (new beat)** — after every green cycle the orchestrator steps back from tasks to the SPEC: "at goal yet? biggest gap?" → `goalGap` in STATE.json; uncovered gaps become `[gap]` tasks (selected first). Termination now requires tasks done AND goal gap empty — finishing the checklist while missing the goal no longer counts as done.
- **The bar rule** — bootstrap must give every goal a measurable bar (verification.md §1); vague ideas are sharpened or declined, never looped.
- **Watch mode** — `/app-forge "<idea>" in <dir> watch`: cycle 1 runs foreground-narrated for trust-building; autonomous from cycle 2.
- **When-not-to-loop intake honesty** — one-off jobs, vague goals, cost sensitivity (SKILL.md section).
- LICENSE: MIT. README: five-beats section, watch-mode row, license line.

## 0.2.0 — 2026-07-16

Agent-ecosystem routing: fan-outs go to the best available **specialist** agents instead of generic subagents.

- NEW references/agent-routing.md — registry discovery (per-session, capability-gated, absence never blocks), task-kind→agent routing table (designer, test-engineer, code-reviewer, security-reviewer, debugger, executor, ruflo/gaia, …), Workflow `agentType` / Agent `subagent_type` mechanism, skill-owned commands (e.g. /gaia, /vercel:deploy) as PLAN phases with cost-gate handling.
- PLAN task grammar: optional `agent:` annotation (assigned by plan-forge synthesis, validated against the discovered registry). STATE.json: `agents` routing map.
- workflows.md: plan-forge takes `agentTypes` + emits `agent` hints; build-iteration routes per-task `agentType` + `verifyAgent`; review-gate lenses route to code-reviewer/security-reviewer/critic. Conditional-spread pattern keeps scripts safe when no specialist exists.
- SKILL.md: discovery step in bootstrap, routing in run step 5, degraded-mode routing, reference-index row, 2 new Common mistakes (unknown agent types; implement tasks routed to read-only advisors).

## 0.1.0 — 2026-07-15

Initial release. Design spec: `docs/superpowers/specs/2026-07-15-app-forge-design.md` (monorepo).

- SKILL.md — modes (bootstrap/run/status/stop), 7 hard rules, bootstrap flow with single plan gate, run-cycle shape, evidence-based termination, circuit breaker, capability-gated hooks (design skills, deploy).
- references/state-contract.md — `.forge/` layout, PLAN task grammar (`files:`/`needs:`/`verify:`), STATE.json schema, git checkpoint conventions, recovery matrix.
- references/iteration-engine.md — full wake cycle: in-flight workflow handling, file-disjoint batch selection, orchestrator pre-fan-out (manifest lockdown), bounded fix passes, breaker math, degraded no-Workflow mode.
- references/workflows.md — plan-forge (judge panel), build-iteration (implement→adversarial verify pipeline), review-gate (loop-until-dry + majority-refute), budget guard, script constraints.
- references/verification.md — AC authoring rules, proof matrix, browser-smoke recipe, evidence format, termination checklist.
- templates/ — SPEC, PLAN, RESUME, STATE.
