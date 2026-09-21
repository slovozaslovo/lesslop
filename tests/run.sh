#!/usr/bin/env bash
# Contract tests for the evidence-rule hook. No framework, no deps beyond python3.
# Run: bash tests/run.sh
set -u
HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/evidence_rule.py"
pass=0; fail=0

check() { # check <name> <condition-exit-code>
  if [ "$2" -eq 0 ]; then echo "  ok    $1"; pass=$((pass+1));
  else echo "  FAIL  $1"; fail=$((fail+1)); fi
}

echo "== evidence_rule ($HOOK)"

OUT="$(echo '{}' | python3 "$HOOK")"; rc=$?
check "exits 0" $rc

echo "$OUT" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null
check "emits valid JSON" $?

echo "$OUT" | python3 -c '
import json,sys
d=json.load(sys.stdin)
h=d["hookSpecificOutput"]
assert h["hookEventName"]=="UserPromptSubmit", h["hookEventName"]
assert d["suppressOutput"] is True
assert isinstance(h["additionalContext"], str) and h["additionalContext"]
' 2>/dev/null
check "correct hook contract shape" $?

echo "$OUT" | python3 -c '
import json,sys
c=json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"]
for needle in ("[proof: ", "{unverified}", "NO EXCEPTIONS", "VERIFY, DON'"'"'T DEFER"):
    assert needle in c, needle
assert "[verified:" not in c, "stale [verified:] tag still in rule"
import re
assert not re.search(r"\]\(", c), "rule contains ](  -- Markdown link collision"
' 2>/dev/null
check "rule carries [proof: ] and {unverified}, no ]( collision" $?

# The jq-free guarantee: stdlib only, and nothing that can shell out.
# Checked against the parsed AST, not the source text -- an earlier version of
# this test grepped for "jq" and tripped on the word in a comment.
python3 -c '
import ast, sys
tree = ast.parse(open(sys.argv[1]).read())
mods = set()
for n in ast.walk(tree):
    if isinstance(n, ast.Import):
        mods.update(a.name.split(".")[0] for a in n.names)
    elif isinstance(n, ast.ImportFrom) and n.module:
        mods.add(n.module.split(".")[0])
banned = mods & {"subprocess", "os", "shutil", "commands", "pty"}
assert not banned, "shells out via: %s" % banned
allowed = {"json", "sys", "rule"}
assert mods <= allowed, "unexpected imports: %s" % (mods - allowed)
' "$HOOK" 2>/dev/null
check "stdlib only, cannot shell out" $?

echo
echo "== evidence_rule_cursor (UNTESTED against a real Cursor install)"

CUR="$(cd "$(dirname "$0")/.." && pwd)/hooks/evidence_rule_cursor.py"
COUT="$(echo '{}' | python3 "$CUR")"; rc=$?
check "cursor hook exits 0" $rc

echo "$COUT" | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert set(d) <= {"additional_context","env"}, d.keys()
assert isinstance(d["additional_context"], str) and d["additional_context"]
' 2>/dev/null
check "cursor envelope is flat additional_context" $?

python3 -c '
import json,subprocess,sys
h=sys.argv[1]; c=sys.argv[2]
a=json.loads(subprocess.run(["python3",h],capture_output=True,text=True).stdout)["hookSpecificOutput"]["additionalContext"]
b=json.loads(subprocess.run(["python3",c],capture_output=True,text=True).stdout)["additional_context"]
assert a==b, "hosts emit different rule text"
' "$HOOK" "$CUR" 2>/dev/null
check "every host emits byte-identical rule text" $?

python3 -c '
import json,sys
m=json.load(open(sys.argv[1]))
assert m.get("version")==1, m.get("version")
assert "sessionStart" in m["hooks"], list(m["hooks"])
e=m["hooks"]["sessionStart"][0]
assert set(e)=={"command"}, e
' "$(cd "$(dirname "$0")/.." && pwd)/hooks/hooks-cursor.json" 2>/dev/null
check "hooks-cursor.json matches Cursor schema" $?

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || { echo "RESULT: FAIL"; exit 1; }
echo "RESULT: PASS"
