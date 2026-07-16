# Example run — "a pomodoro timer web app"

*Illustrative walkthrough (condensed from a representative run) showing what App-Forge produces at each stage. Your files will differ.*

## 1 · Invocation

```
/app-forge "a pomodoro timer web app with task labels and a daily focus report" in ~/dev/pomo
```

## 2 · SPEC.md (excerpt — note every AC is a bar, not a vibe)

```markdown
## Acceptance criteria (ALL proven at termination)
- AC1 · `npm run build` → exit 0
- AC2 · `npm test` → 0 failures; suites cover timer engine + report math
- AC3 · Browser smoke: start 25:00 timer → counts down → break prompt appears;
        label a session "writing" → daily report shows 1 session under "writing"
- AC4 · fresh clone: `npm ci && npm run build` → exit 0
```

## 3 · PLAN.md (excerpt — file-scoped verifies, orchestrator scaffold, routed agents)

```markdown
## P1 — Scaffold   [phase-verify: `npm run build`]
- [x] P1.1 Vite+React+TS init, vitest wired · files: / · agent: orchestrator · verify: `npm run build`

## P2 — Core   [phase-verify: `npm test`]
- [x] P2.1 Timer engine (start/pause/break cycles) · files: src/engine/** · verify: `npm test -- engine`
- [x] P2.2 Task labels store · files: src/labels/** · needs: P2.1 · verify: `npm test -- labels`
- [ ] P2.3 Daily report math · files: src/report/** · needs: P2.2 · verify: `npm test -- report`

## P3 — Complete the loop   [phase-verify: `npm test`]
- [ ] P3.1 Wire UI end-to-end · files: src/app/** · needs: P2.3 · agent: designer · verify: `npm test -- app`
```

## 4 · The gate (the one approval)

App-Forge presents: ACs first ("challenge these — I wrote bars I know I can pass"), then the plan, then
`14 tasks × ~3 agent calls + verification ≈ 50–60 invocations · toolchain preflight: node 22 ✓ git ✓`.
You approve once. It never asks again.

## 5 · JOURNAL.md (three real beats)

```markdown
## i3 · P2.1 P2.2 · GREEN · commit 4e91c02
- verify: `npm test -- engine labels` → 11 passed · `npm run build` → exit 0
- goal check: gap = "report math not started — covered by P2.3" (no [gap] task needed)

## i4 · P2.3 · RED
- `npm test -- report` → 2 failed: DST boundary puts 11pm session in next day's report
- fix pass: date math moved to UTC day-keys → re-verify green → commit 7ab1d33
- LESSONS += "report bucketing: always key by UTC day, symptom = DST off-by-one"

## i5 · P3.1 · GREEN · commit 91d04fe · phase P3 closed
- phase-verify: `npm test` → 23 passed · smoke: timer counts down, break prompt OK,
  report shows labeled session; console clean (screenshot logged)
```

## 6 · Termination

Every AC re-executed with evidence → review-gate (1 confirmed minor: report empty-state copy — fixed;
0 unjudged) → `git tag forge-shipped-2026-07-16` → summary + how-to-run → loop stops itself.

**Retro:** 1 rule promoted to the global BRAIN (`scope:general` — UTC day-keys), telemetry appended,
0 skill proposals. Run #2 of anything with dates starts already knowing this.
