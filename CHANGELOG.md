# App-Forge — Changelog

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
