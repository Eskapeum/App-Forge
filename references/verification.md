# Verification — the proof bar

app-forge's entire credibility is this file. A loop that "finishes" without proof is a slop generator with a scheduler.

## §1 Authoring acceptance criteria (bootstrap)

Each AC in SPEC.md must be one of exactly two kinds:

1. **Runnable** — a command with an unambiguous pass condition.
   `AC1 · npm run build → exit 0` · `AC2 · npm test → 0 failures, suites cover invoices + auth`
2. **Observable** — a browser/CLI behavior a machine can walk through and see.
   `AC3 · create invoice → appears in list → total updates (browser smoke, evidence: page text + screenshot)`

Ban list: "works well", "clean code", "good UX", "handles errors gracefully" — rewrite as a runnable/observable check or delete. 4–8 ACs is the sweet spot; if you need more, the SPEC is two apps.

**The bar rule.** A loop only self-corrects on what it can measure — so give every goal a bar. The canonical non-code example: "write a brief" loops forever on vibes, but "every claim needs ≥3 sources and every link must open to a real page that backs the claim" makes the loop open each link, throw out fakes, and stop only when true. App-forge equivalents: not "auth works" but "`npm test -- auth` green + smoke: wrong password rejected, session persists across reload". If a goal has no bar, the bootstrap hasn't finished its job.

## §2 Who verifies

| Layer | What it's worth |
|---|---|
| Implementer ran `verify:` | A claim |
| Adversarial verifier agent passed it | A stronger claim |
| **Orchestrator ran it in the main context** | **Evidence** |

The orchestrator re-runs everything that matters (Hard rule 2). Subagent layers exist to make the orchestrator's run *likely to pass*, not to replace it.

## §3 The proof matrix

| Moment | Checks (orchestrator, via Bash / preview pane) |
|---|---|
| Every cycle | batch `verify:` commands + project build — the FIRST global check; agents ran file-scoped only |
| Phase boundary | + `[phase-verify:]` + full test suite + browser smoke (web) |
| Termination | + EVERY AC executed, evidence journaled + review-gate workflow |

Agents inside a batch never run the global build or full suite — they share one working tree and would compile each other's half-written code. File-scoped checks in agents; global checks here, once, post-batch.

**Browser smoke recipe (web apps):** `preview_start` (dev server from `.claude/launch.json` — create it if missing) → `navigate` to the app → `read_page` asserts core text/controls exist → drive ONE core flow (the SPEC's main verb: create the thing, see the thing) → `read_console_messages {onlyErrors:true}` must be empty of new errors → screenshot for the journal. Kill the server after. CLI apps: run the binary against a golden input; APIs: curl the health + one core endpoint.

## §4 Evidence format (JOURNAL.md)

Every green claim carries the command and its observed result, compressed:

```
- verify: `npm test` → 42 passed, 0 failed (3.1s)
- smoke: / renders "Invoices"; create-flow OK; console clean
- AC2 → PASS (evidence above)
```

If you can't paste what a check printed, you didn't run it.

## §5 Termination checklist (all YES before "shipped")

1. Every PLAN task checked or explicitly `[blocked:]` (blocked list appears in the summary — never silently dropped).
2. Every AC executed in the terminating session with journaled evidence — no "passed earlier". STATE `goalGap` is empty (the goal check agrees the SPEC is met, not just the checklist).
3. review-gate confirmed criticals/majors: zero open. Unjudged findings (skeptic quorum failures): re-refuted once, and anything still unjudged is listed in the summary as an unverified flag — never silently dropped. `converged: false` (round cap hit) is disclosed.
4. Fresh clone sanity: `git status` clean; install + build from scratch succeeds (catches "works on my tree" artifacts: missing files, uncommitted deps).
5. Summary tells the user how to run it in ≤3 commands.

Any NO → not done. Either loop continues (breaker permitting) or stop with `stopReason` telling the truth.
