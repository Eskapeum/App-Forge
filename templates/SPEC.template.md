# SPEC — <project name>

## One-liner
<what it is, for whom, in one sentence>

## Goals
- <3–6 bullets: the user-visible capabilities that define v1>

## Non-goals (v1)
- <explicitly out: auth providers, mobile, multi-tenant, etc.>

## Stack
<stack choice> — <one-line justification (why this is the lazy-correct pick)>

Run commands: dev `<cmd>` · build `<cmd>` · test `<cmd>`

## Acceptance criteria (ALL proven at termination — runnable or observable only, see verification.md §1)
- AC1 · `<command>` → <pass condition>
- AC2 · `<command>` → <pass condition>
- AC3 · <core flow> (browser smoke, evidence: page text + screenshot)
- AC4 · fresh clone: install + build from scratch → exit 0

## Deploy
<none | "user asked: deploy to <target>; verify = URL responds">
