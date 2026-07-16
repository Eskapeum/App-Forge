# App-Forge — Changelog

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
