# PLAN — <project name>

<Task grammar: `- [ ] P<phase>.<n> <text> · files: <glob> [· needs: <ids>] [· agent: <registry type>] · verify: \`<runnable command>\``.
Every task MUST have files: and verify:. `agent:` is optional specialist routing (agent-routing.md) — only types that exist this session. Orchestrator checks boxes only after ITS OWN verification (Hard rule 2).>

## P1 — Scaffold   [phase-verify: <build command>]
- [ ] P1.1 <init app skeleton, tooling, test runner> · files: / · verify: `<build>`
- [ ] P1.2 <base layout/entrypoint> · files: src/app/** · needs: P1.1 · verify: `<build>`

## P2 — Core   [phase-verify: <test command>]
- [ ] P2.1 <data model> · files: src/db/** · needs: P1.1 · verify: `<test -- db>`
- [ ] P2.2 <core feature A> · files: src/<a>/** · needs: P2.1 · verify: `<test -- a>`
- [ ] P2.3 <core feature B> · files: src/<b>/** · needs: P2.1 · verify: `<test -- b>`

## P3 — Complete the loop   [phase-verify: <full test command>]
- [ ] P3.1 <wire flows end-to-end> · files: src/** (single task — broad glob, runs alone) · needs: P2.2, P2.3 · verify: `<e2e/full test>`
- [ ] P3.2 <error/empty states + UI polish> · files: src/app/** · needs: P3.1 · agent: designer · verify: `<test>`

## P4 — Ship   [phase-verify: <full suite>]
- [ ] P4.1 <polish pass / README + run docs> · files: README.md docs/** · verify: `<build && test>`
- [ ] P4.2 <deploy — ONLY if SPEC says so> · files: <infra> · needs: P4.1 · verify: `<url responds>`
