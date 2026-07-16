# Agent routing — use the ecosystem, not anonymous labor

Every fan-out should go to the **best available specialist**, not a generic subagent. The environment ships a registry of agent types (and skills ship their own — ruflo's `gaia-*`, `gsd-*`, `feature-dev:*`, `brand-voice:*`, …); app-forge treats that registry as its workforce.

## §1 Discovery (bootstrap + first run-mode wake)

Agent availability **varies per session** — never hardcode a dependency on a type existing.

1. Read the "Available agent types" listing from the session environment. That listing is the truth.
2. Build the routing map (§2) from what actually exists; record it in `.forge/STATE.json` under `"agents": { "<kind>": "<type>" }` so later wakes (and fresh sessions) reuse it without re-deriving.
3. A kind with no matching specialist routes to the default: omit `agentType` (Workflow) / use `general-purpose` (Agent tool). **Absence degrades routing, never blocks work.**

## §2 Routing table (task kind → preferred agent types, first match wins)

| Task kind (from PLAN task text/files) | Preferred types (in order) |
|---|---|
| Scaffold / general implementation | `executor`, `general-purpose` |
| Frontend / UI / components / styling | `designer`, `frontend-expert`, `feature-dev:code-architect` |
| Backend / API / data layer | `python-backend-expert` or `nextjs-expert` (stack match), `executor` |
| Tests / coverage / flaky hardening | `test-engineer`, `qa-tester` |
| Verify (adversarial, in build-iteration) | `code-reviewer`, `feature-dev:code-reviewer`, `verifier` |
| review-gate: correctness lens | `code-reviewer` |
| review-gate: security lens | `security-reviewer` |
| review-gate: AC-gap lens | `critic`, `verifier` |
| Debug a red cycle (fix pass) | `debugger`, `tracer` |
| Docs / README | `writer`, `technical-documentation-writer` |
| Architecture consult (bootstrap proposals) | `architect`, `analyst`, `Plan` |
| Simplify / cleanup phase | `code-simplifier` |
| Deploy (explicit ask only) | `vercel:deployment-expert` or stack equivalent |
| Benchmark / eval phase (if SPEC asks) | `ruflo-workflows:gaia-benchmark-runner`, `scientist` |

Classification is by task annotation first (`agent:` in PLAN, §4), then by `files:` glob + task text. When unsure, `executor`/default — a wrong specialist is worse than a generalist.

## §3 Mechanism

- **Workflow scripts**: pass `agentType` per `agent()` call — `agent(prompt, { agentType: t.agent, schema: IMPL })`. Composes with schemas (structured output still enforced). Read-only advisors (`architect`, `critic`, `code-reviewer`) are legal for propose/judge/verify stages but never for implement stages — check the type's tool grants in the listing before routing an implementation task to it.
- **Degraded mode (Agent tool)**: same map via `subagent_type`.
- **Model overrides**: leave `model` unset (inherit) unless the agent definition already pins one. Routing picks *who*, not *how expensive*. **One sanctioned exception** — the highest-judgment stages (plan-forge judges/synthesis, review-gate refuters, the goal check when delegated) MAY pin `model` to the strongest available tier (e.g. `'fable'`) when the session model is weaker or a routed agent definition pins lower; the loop's judgment should never be its cheapest component.
- **`agent: orchestrator` sentinel**: not a registry type — it means the orchestrator executes the task inline, never fanning out (scaffold, manifest-creating, shared-config tasks). Validated separately from registry discovery.

## §4 PLAN grammar extension

Tasks may carry an optional `agent:` hint, assigned at bootstrap by plan-forge synthesis (the orchestrator validates it against §1 discovery and drops unknown types):

```markdown
- [ ] P3.2 Invoice list UI + empty states · files: src/app/invoices/** · needs: P2.2 · agent: designer · verify: `npm test -- invoices`
```

No `agent:` → orchestrator classifies per §2 at batch time. Either way the resolved type is what goes into the workflow args.

## §5 Skill-owned commands as phases

Some ecosystems expose *commands*, not just agent types (e.g. `/gaia validate`, `/gaia run` for benchmark runs; `/vercel:deploy`). When the SPEC calls for such a capability, model it as a **PLAN task the orchestrator executes inline** (invoke the skill/command, capture its output as the verify evidence) — not as a subagent fan-out. Rules:

- Only when the SPEC asks for it (e.g. "include an eval harness", "deploy to vercel").
- The task still needs a `verify:` with a pass condition (e.g. `/gaia validate` → exits clean; deploy → URL responds).
- Cost-gated commands (benchmark runs) respect their own confirmation gates — a cost prompt from the tool is one of the few legitimate mid-run stops: stop cleanly with RESUME.md noting the pending confirmation (Hard rule 3 applies; don't silently auto-confirm spend).

## §6 Non-negotiables unchanged

Routing changes WHO does the work, nothing else: manifest lockdown, file-disjoint batching, orchestrator re-verification, green-only checkpoints, LESSONS injection all apply identically to specialist agents. A `designer`'s "done" is still a claim.
