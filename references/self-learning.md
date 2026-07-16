# Self-learning — better with every use

Two memory tiers. The project tier makes *this build* converge; the global tier makes *the next build* start smarter. The goal is a **falling mistake rate**, not a long list.

## §1 The tiers

| Tier | Lives at | Holds | Lifetime |
|---|---|---|---|
| Project | `<project>/.forge/LESSONS.md` | specifics of this build ("this repo's jest needs --runInBand") | dies with the project |
| Global | `~/.claude/app-forge/` | transferable rules, run telemetry, skill-edit proposals | forever, across all runs |

Global dir contents (created on first retro; survives skill upgrades because it lives OUTSIDE the skill install):

```
~/.claude/app-forge/
├── BRAIN.md        deduped transferable rules (templates/BRAIN.template.md seeds it)
├── runs.jsonl      one JSON line per run: telemetry for trend-reading
└── PROPOSALS.md    suggested edits to the SKILL ITSELF — pending human review
```

## §2 BRAIN.md rule format

One line per rule — grep-able, dedupable, countable:

```markdown
- R017 · scope:stack-nextjs · hits:3 · 2026-07-16 — Route handlers that read request state need a per-route dynamic flag or prod builds serve stale data. Rule: set it whenever a handler reads the request.
- R018 · scope:batching · hits:1 · 2026-07-16 — Two tasks sharing a barrel-export file are NOT disjoint even when their dirs differ. Rule: treat index.ts re-export files as shared → orchestrator pre-fan-out.
```

- `scope:` one of `stack-<name>` | `batching` | `verify` | `spec` | `workflow` | `general`. Drives injection filtering.
- `hits:` how many runs have observed this failure mode (see §4 merge).
- Rule text = symptom + the rule that prevents a repeat. One or two sentences, imperative.

## §3 Inject (where learning enters the loop)

1. **Bootstrap** — read BRAIN.md, filter to `scope:general|spec|batching|verify|workflow` + `stack-<chosen stack>`; pass as `args.brain` to plan-forge (shapes task granularity and verify commands before any code exists).
2. **Every cycle** — engine §1 reads BRAIN.md along with project state; `args.lessons` for build-iteration = **filtered global rules + full project LESSONS.md**, so every implementer and verifier sees both tiers.
3. **Fix passes** — when diagnosing a red, check BRAIN for a matching rule first; a known failure mode skips straight to its known fix.

## §4 Harvest — the retro step

Runs at EVERY termination **and every breaker stop** (failed runs teach the most). Orchestrator-inline, ~2 minutes:

1. Read `.forge/JOURNAL.md`, `LESSONS.md`, `STATE.json`.
2. Append one line to `runs.jsonl`:
   `{"date":"<ISO>","project":"<name>","stack":"<stack>","iterations":N,"greens":N,"reds":N,"blocked":[ids],"stopReason":null|"...","topCauses":["<sig>",...]}`
3. For each project lesson and red-cause: **generalize or drop.** Would this bite a DIFFERENT project? No → stays project-tier. Yes → normalize to §2 format and merge into BRAIN.md:
   - Same failure mode already in BRAIN (same scope + same symptom) → `hits++`. **A rule that was injected and STILL got violated is a badly written rule** — rewrite it sharper on the spot (the violation shows what it failed to prevent).
   - New → append with the next `R###` id.
4. Skill-defect lessons (a hard rule that misfired, a workflow shape that hangs, a template gap) → dated entry in `PROPOSALS.md` (what happened · why the skill is at fault · the suggested edit). **Never edit the installed skill mid-run** — it's versioned and mirrored; humans apply proposals.
5. **Contradiction check** before appending: scan same-scope rules for direct conflicts with the new one (opposite imperatives about the same situation). Keep the sharper/newer rule; if genuinely irreconcilable (both true in different contexts), split the scopes or narrow the wording — and if the conflict implicates the skill's own doctrine, log it in PROPOSALS.md. Two contradictory rules injected into one prompt are worse than none.
6. Prune while writing: BRAIN.md hard cap 100 rules — drop lowest-hits oldest first; a stale low-hit rule is noise that dilutes every future injection.
7. Final summary reports the learning delta: "N rules added, M sharpened, K proposals pending review."

## §5 Honesty rules

- Generalize-or-drop is strict: project trivia in BRAIN.md poisons every future run's prompt budget.
- Rules must be *falsifiable* — "be careful with async" is banned; "await inside array.map silently drops rejections — use for..of or Promise.all" is a rule.
- PROPOSALS.md is the only path by which the skill itself changes. Applying proposals = a human-reviewed version bump (update CHANGELOG, re-mirror, re-export).
- Telemetry stays local. `runs.jsonl` is for reading trends ("median iterations per app is falling"), never uploaded anywhere.
