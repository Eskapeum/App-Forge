# Canned workflows

Three scripts. Adapt prompts/fields to the project; keep the shapes. Invoking them is authorized by the skill itself (user opt-in via /app-forge).

Agent routing: every `agent()` call may carry `agentType` (resolved per agent-routing.md; validated against the session's registry before launch — pass only types that exist). The conditional-spread pattern used below (`...(x ? { agentType: x } : {})`) keeps scripts safe when no specialist is available.

Script constraints (hard): plain JS, no TypeScript syntax; `meta` is a pure literal; NO `Date.now()` / `Math.random()` / argless `new Date()` (breaks resume — pass timestamps via `args`); pass args as real JSON, never stringified; `parallel()` thunks resolve to `null` on error → `.filter(Boolean)`; prefer `pipeline()` — barriers only where a stage truly needs ALL prior results.

## §1 plan-forge (bootstrap)

Judge panel: independent proposals → scored → synthesis. Barrier is justified: judging needs every proposal.

```js
export const meta = {
  name: 'plan-forge',
  description: 'Architecture judge panel → phased build plan',
  phases: [{ title: 'Propose' }, { title: 'Judge' }, { title: 'Synthesize' }],
}
// args: { spec: "<full SPEC.md text>", agentTypes: ["designer", ...], brain: "<BRAIN rules filtered for this stack>" }
// agentTypes = discovered registry (agent-routing.md §1) · brain = global learned rules (self-learning.md §3)
const ANGLES = ['simplest-thing-that-ships', 'data-model-first', 'user-flow-first']
const PROPOSAL = { type: 'object', required: ['stack', 'phases', 'risks'], properties: {
  stack: { type: 'string' }, risks: { type: 'array', items: { type: 'string' } },
  phases: { type: 'array', items: { type: 'object', required: ['title', 'tasks'], properties: {
    title: { type: 'string' },
    tasks: { type: 'array', items: { type: 'object', required: ['text', 'files', 'verify'], properties: {
      text: { type: 'string' }, files: { type: 'string' }, needs: { type: 'string' }, verify: { type: 'string' },
      agent: { type: 'string' } } } } } } } } }
phase('Propose')
const proposals = (await parallel(ANGLES.map(a => () =>
  agent(`Propose an architecture + phased task plan for this spec, optimizing for "${a}".
Every task MUST have a files: glob and a RUNNABLE verify: command. Small atomic tasks (≤1 file area each).
Learned rules from past runs (honor them):\n${args.brain || 'none yet'}
SPEC:\n${args.spec}`, { label: `propose:${a}`, phase: 'Propose', schema: PROPOSAL })))).filter(Boolean)
phase('Judge')
const scores = (await parallel(proposals.map((p, i) => () =>
  agent(`Score this plan 0-10 on: shippability, verifiability of tasks, risk. Return JSON.
PLAN ${i}: ${JSON.stringify(p)}`, { label: `judge:${i}`, phase: 'Judge',
    schema: { type: 'object', required: ['score', 'critique'], properties: { score: { type: 'number' }, critique: { type: 'string' } } } })))).filter(Boolean)
phase('Synthesize')
const winner = proposals[scores.indexOf(scores.reduce((a, b) => (b.score > a.score ? b : a)))]
return await agent(`Synthesize the FINAL plan from the winner, grafting the best ideas and critiques from the others.
For each task, optionally set "agent" to the best-fit specialist from this registry (omit if none fits): ${JSON.stringify(args.agentTypes)}
WINNER: ${JSON.stringify(winner)}\nOTHERS+CRITIQUES: ${JSON.stringify({ proposals, scores })}`,
  { label: 'synthesize', phase: 'Synthesize', schema: PROPOSAL })
```

The orchestrator turns the returned object into PLAN.md (state-contract grammar) — ids assigned there, not in the workflow; `agent:` hints validated against the discovered registry (unknown types dropped).

## §2 build-iteration (every cycle)

Pipeline per task: implement → adversarially verify. No barrier — a verified task never waits on a slower sibling.

```js
export const meta = {
  name: 'build-iteration',
  description: 'Implement a file-disjoint task batch, adversarially verify each',
  phases: [{ title: 'Implement' }, { title: 'Verify' }],
}
// args: { projectDir, tasks: [{id, text, files, verify, agent}], spec, lessons, runNotes, verifyAgent }
// task.agent / verifyAgent = registry types resolved by the orchestrator (agent-routing.md §2-3); absent → default subagent
// lessons = MERGED payload: global BRAIN rules (filtered by stack) + full project LESSONS.md (self-learning.md §3)
const IMPL = { type: 'object', required: ['taskId', 'status', 'filesTouched', 'summary'], properties: {
  taskId: { type: 'string' }, status: { type: 'string', enum: ['done', 'failed'] },
  filesTouched: { type: 'array', items: { type: 'string' } }, summary: { type: 'string' },
  testsAdded: { type: 'string' }, insight: { type: 'string' } } }
const VERDICT = { type: 'object', required: ['taskId', 'verdict', 'evidence'], properties: {
  taskId: { type: 'string' }, verdict: { type: 'string', enum: ['pass', 'fail'] },
  evidence: { type: 'string' }, failures: { type: 'array', items: { type: 'string' } } } }
const results = await pipeline(args.tasks,
  t => agent(`Implement ONE task in ${args.projectDir}. Task ${t.id}: ${t.text}
Touch ONLY paths matching: ${t.files}. NEVER touch package.json/lockfiles/shared config (pre-installed for you). ${args.runNotes}
Write real tests where the task implies them. Run \`${t.verify}\` yourself until it passes.
LESSONS (obey):\n${args.lessons}\nSPEC context:\n${args.spec}
Return JSON only.`, { label: `impl:${t.id}`, phase: 'Implement', schema: IMPL, ...(t.agent ? { agentType: t.agent } : {}) }),
  (impl, t) => impl && impl.status === 'done'
    ? agent(`Adversarially verify task ${t.id} in ${args.projectDir} — try to REFUTE completion.
Read the changed files (${JSON.stringify(impl.filesTouched)}), run \`${t.verify}\`, probe edge cases the tests miss.
Claimed: ${impl.summary}. Return JSON only.`, { label: `verify:${t.id}`, phase: 'Verify', schema: VERDICT, ...(args.verifyAgent ? { agentType: args.verifyAgent } : {}) })
        .then(v => ({ impl, verdict: v }))
    : { impl, verdict: null })
return { results: results.filter(Boolean) }
```

Orchestrator treatment of results: `verdict.pass` is still only a claim — re-run every `verify:` + build yourself (iteration-engine §5). `insight` fields worth keeping go to LESSONS.md.

## §3 review-gate (termination)

Loop-until-dry finders + majority-refute verification. Runs once, before "shipped".

```js
export const meta = {
  name: 'review-gate',
  description: 'Adversarial final review: find → refute-verify → confirmed findings',
  phases: [{ title: 'Find' }, { title: 'Refute' }],
}
// args: { projectDir, spec, lensAgents }
// lensAgents = specialist routing, only types that exist (agent-routing.md §2), e.g.
// { correctness: 'code-reviewer', security: 'security-reviewer', gaps: 'critic' }
const BUGS = { type: 'object', required: ['findings'], properties: { findings: { type: 'array', items: {
  type: 'object', required: ['file', 'summary', 'severity'], properties: {
    file: { type: 'string' }, line: { type: 'number' }, summary: { type: 'string' },
    severity: { type: 'string', enum: ['critical', 'major', 'minor'] } } } } } }
const VERDICT = { type: 'object', required: ['refuted'], properties: { refuted: { type: 'boolean' }, why: { type: 'string' } } }
const LA = args.lensAgents || {}
const LENSES = [
  { key: 'correctness', hint: 'broken flows, data loss', agent: LA.correctness },
  { key: 'security', hint: 'injection, authz, secrets', agent: LA.security },
  { key: 'gaps', hint: 'acceptance-criteria gaps vs the SPEC', agent: LA.gaps },
]
const seen = new Set(), confirmed = []
let dry = 0
while (dry < 2) {
  const found = (await parallel(LENSES.map(l => () =>
    agent(`Review the app at ${args.projectDir} through the lens: ${l.key} (${l.hint}). SPEC:\n${args.spec}\nReport real defects only.`,
      { label: `find:${l.key}`, phase: 'Find', schema: BUGS, ...(l.agent ? { agentType: l.agent } : {}) })))).filter(Boolean).flatMap(r => r.findings)
  const fresh = found.filter(f => !seen.has(`${f.file}:${f.summary}`))
  if (!fresh.length) { dry++; continue }
  dry = 0; fresh.forEach(f => seen.add(`${f.file}:${f.summary}`))
  const judged = await parallel(fresh.map(f => () =>
    parallel([0, 1, 2].map(k => () =>
      agent(`Try to REFUTE this finding (default refuted=true if uncertain). ${JSON.stringify(f)} — project ${args.projectDir}, skeptic #${k}.`,
        { label: `refute:${f.file}`, phase: 'Refute', schema: VERDICT })))
      .then(vs => ({ f, real: vs.filter(Boolean).filter(v => !v.refuted).length >= 2 }))))
  confirmed.push(...judged.filter(Boolean).filter(j => j.real).map(j => j.f))
}
return { confirmed }
```

Confirmed criticals/majors become ONE final fix batch through build-iteration; minors go to the summary as known nits.

## §4 Budget guard

If the run was launched with a token target, wrap discovery loops: `while (budget.total && budget.remaining() > 50_000) …`, and before launching any workflow check `budget.remaining()` — under ~100k, prefer finishing the current phase over starting a new one, and say so in the journal. No target set → `budget.remaining()` is Infinity; rely on `iterationCap`.

## Iterating on a script

Every invocation persists its script to a file (path in the tool result). To fix a script mid-run: edit that file, relaunch with `{scriptPath, resumeFromRunId}` — the unchanged prefix of agent calls returns cached instantly. Before diagnosing a weird empty result, read the run's `journal.jsonl`.
