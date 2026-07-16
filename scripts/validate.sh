#!/usr/bin/env bash
# App-Forge skill validator — run from the skill root (or pass the skill dir as $1).
# Checks: required files · workflow JS blocks parse · templates valid · no placeholders · cross-refs resolve.
set -u
DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$DIR" || { echo "FAIL cannot cd $DIR"; exit 1; }
fail=0

req=(SKILL.md README.md CHANGELOG.md LICENSE
  references/state-contract.md references/iteration-engine.md references/workflows.md
  references/agent-routing.md references/verification.md references/self-learning.md
  templates/SPEC.template.md templates/PLAN.template.md templates/RESUME.template.md
  templates/STATE.template.json templates/BRAIN.template.md)
for f in "${req[@]}"; do [ -f "$f" ] || { echo "FAIL missing $f"; fail=1; }; done

python3 - <<'EOF' || fail=1
import re, subprocess, tempfile, os, json, sys
src = open('references/workflows.md').read()
blocks = re.findall(r'```js\n(.*?)```', src, re.S)
ok = True
if len(blocks) < 3:
    print(f"FAIL expected >=3 js blocks, found {len(blocks)}"); ok = False
for i, b in enumerate(blocks):
    body = b.replace('export const meta', 'const meta')
    wrapped = ("async function _c(agent, parallel, pipeline, phase, log, args, budget, workflow) {\n" + body + "\n}\n")
    with tempfile.NamedTemporaryFile('w', suffix='.mjs', delete=False) as f:
        f.write(wrapped); p = f.name
    r = subprocess.run(['node', '--check', p], capture_output=True, text=True)
    os.unlink(p)
    if r.returncode != 0:
        print(f"FAIL js block {i}: {r.stderr.splitlines()[0] if r.stderr else 'parse error'}"); ok = False
json.load(open('templates/STATE.template.json'))
tpl = json.load(open('templates/STATE.template.json'))
for k in ('agents', 'goalGap', 'activeWorkflowRunId', 'iterationCap'):
    if k not in tpl: print(f"FAIL STATE.template.json missing {k}"); ok = False
sys.exit(0 if ok else 1)
EOF

if grep -rn "TBD\|TODO\b" --include="*.md" . | grep -v "EXAMPLE-RUN" | grep -q .; then
  echo "FAIL placeholder (TBD/TODO) found:"; grep -rn "TBD\|TODO\b" --include="*.md" . | grep -v "EXAMPLE-RUN"; fail=1
fi

for ref in state-contract iteration-engine workflows agent-routing verification self-learning; do
  grep -q "references/$ref.md" SKILL.md || { echo "FAIL SKILL.md does not reference $ref"; fail=1; }
done

[ $fail -eq 0 ] && echo "VALIDATE PASS ($DIR)" || echo "VALIDATE FAIL"
exit $fail
