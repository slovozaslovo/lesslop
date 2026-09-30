#!/usr/bin/env bash
# Contract tests for the evidence-rule hook. No framework, no deps beyond python3.
# Run: bash tests/run.sh
set -u
HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/evidence_rule.py"
ok=0; bad=0

check() { # check <name> <condition-exit-code>
  if [ "$2" -eq 0 ]; then echo "  ok    $1"; ok=$((ok+1));
  else echo "  FAIL  $1"; bad=$((bad+1)); fi
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

# The two envelopes above only compare hosts to each other. Both could wrap the
# rule the same wrong way and still match. Pin each one to hooks/rule.py.
python3 -c '
import json, sys
sys.path.insert(0, sys.argv[1])
from rule import RULE
def one(raw, context):
    dec = json.JSONDecoder()
    obj, idx = dec.raw_decode(raw)
    assert raw[idx:].strip() == "", "trailing data after JSON"
    assert context(obj) == RULE, "envelope is not rule.RULE"
one(sys.argv[2], lambda o: o["hookSpecificOutput"]["additionalContext"])
one(sys.argv[3], lambda o: o["additional_context"])
assert set(json.loads(sys.argv[3])) == {"additional_context"}
' "$(cd "$(dirname "$0")/.." && pwd)/hooks" "$OUT" "$COUT" 2>/dev/null
check "each host injects rule.RULE and nothing else" $?

# A prompt-shaped payload must not change the injection. The product is one
# rule every turn, including when the prompt itself contains the tags.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
claude_payload='{"hook_event_name":"UserPromptSubmit","cwd":"/tmp/lesslop","prompt":"PostgreSQL port? [proof: x](no space) {unverified} порт 5432"}'
cursor_payload='{"hook_event_name":"sessionStart","workspace_roots":["/tmp/lesslop"],"prompt":"PostgreSQL port? [proof: x](no space) {unverified} порт 5432"}'
ignores_stdin() { # <script> <payload>
  local script="$1" payload="$2" empty braced prompted
  empty="$(python3 "$script" </dev/null)" || return 1
  braced="$(printf '%s' '{}' | python3 "$script")" || return 1
  prompted="$(printf '%s' "$payload" | python3 "$script")" || return 1
  [ "$empty" = "$braced" ] && [ "$empty" = "$prompted" ]
}
ignores_stdin "$HOOK" "$claude_payload"
check "claude hook ignores stdin" $?
ignores_stdin "$CUR" "$cursor_payload"
check "cursor hook ignores stdin" $?

quiet_stderr() {
  local err
  err="$(python3 "$1" </dev/null 2>&1 1>/dev/null)" || return 1
  [ -z "$err" ]
}
quiet_stderr "$HOOK"
check "claude hook writes nothing to stderr" $?
quiet_stderr "$CUR"
check "cursor hook writes nothing to stderr" $?

# Same import allowlist as the Claude hook, applied to the other two modules.
# rule.py is the shared text and must not grow a runtime dependency.
import_ok() { # <path> <space-separated allowed modules, or empty>
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
allowed = set(sys.argv[2].split()) if len(sys.argv) > 2 and sys.argv[2] else set()
assert mods <= allowed, "unexpected imports: %s" % (mods - allowed)
' "$1" "${2-}" 2>/dev/null
}
import_ok "$CUR" "json sys rule"
check "cursor hook is stdlib only, cannot shell out" $?
import_ok "$ROOT/hooks/rule.py" ""
check "rule.py has no imports" $?

# sys.path[0] is the script directory, so the import must survive an unrelated cwd.
python3 -c '
import subprocess, sys, tempfile
cwd = tempfile.gettempdir()
for script in sys.argv[1:]:
    p = subprocess.run(["python3", script], cwd=cwd, input="", capture_output=True, text=True)
    assert p.returncode == 0, (script, p.stderr)
    assert p.stdout.startswith("{"), script
' "$HOOK" "$CUR" 2>/dev/null
check "hooks import rule.py from any working directory" $?

python3 -c '
import json, sys
m = json.load(open(sys.argv[1]))
assert list(m["hooks"]) == ["UserPromptSubmit"], list(m["hooks"])
entry = m["hooks"]["UserPromptSubmit"][0]["hooks"][0]
assert entry["type"] == "command", entry
cmd = entry["command"]
assert cmd.startswith("python3 "), cmd
assert "${CLAUDE_PLUGIN_ROOT}" in cmd, cmd
assert cmd.endswith("/hooks/evidence_rule.py\""), cmd
assert "evidence_rule_cursor.py" not in cmd
' "$ROOT/hooks/hooks.json" 2>/dev/null
check "hooks.json binds UserPromptSubmit to the claude hook" $?

python3 -c '
import json, os, sys
root = sys.argv[1]
plugin = json.load(open(os.path.join(root, ".cursor-plugin/plugin.json")))
assert plugin["hooks"] == "./hooks/hooks-cursor.json", plugin["hooks"]
assert plugin["skills"] == "./skills/", plugin["skills"]
hooks = json.load(open(os.path.join(root, "hooks/hooks-cursor.json")))
cmd = hooks["hooks"]["sessionStart"][0]["command"]
assert cmd == "python3 ./hooks/evidence_rule_cursor.py", cmd
assert os.path.isfile(os.path.join(root, "hooks/evidence_rule_cursor.py"))
' "$ROOT" 2>/dev/null
check "cursor manifest points at the cursor hook" $?

python3 -c '
import json, os, sys
root = sys.argv[1]
paths = (
    ".claude-plugin/plugin.json",
    ".codex-plugin/plugin.json",
    ".cursor-plugin/plugin.json",
)
vs = {}
for rel in paths:
    m = json.load(open(os.path.join(root, rel)))
    assert m["name"] == "lesslop", (rel, m.get("name"))
    vs[rel] = m["version"]
assert len(set(vs.values())) == 1, vs
' "$ROOT" 2>/dev/null
check "plugin manifests agree on name and version" $?

# Codex has no hook. The skill is the only copy of the rule it receives, and it
# is markdown rather than the hook string, so compare obligations, not bytes.
python3 -c '
import sys
sys.path.insert(0, sys.argv[1])
from rule import RULE
skill = open(sys.argv[2]).read()
parts = skill.split("---")
assert len(parts) >= 3 and parts[0] == "", "skill is missing frontmatter"
assert "name: \"lesslop\"" in parts[1], parts[1]
needles = (
    "[proof: ",
    "{unverified}",
    "TAG EVERY CLAIM",
    "NO EXCEPTIONS",
    "VERIFY, DON'"'"'T DEFER",
    "WHEN CORRECTED",
    "from training",
    "Want me to check?",
    "do not defend",
)
for needle in needles:
    assert needle in RULE, needle
    assert needle in skill, "skill dropped: %s" % needle
for needle in ("5432", "wc -l hooks/evidence_rule.py"):
    assert needle in skill, "skill dropped example: %s" % needle
assert "](" not in skill, "skill contains ](  -- Markdown link collision"
' "$ROOT/hooks" "$ROOT/skills/lesslop/SKILL.md" 2>/dev/null
check "skill states the same obligations as rule.RULE" $?

echo
echo "ok=$ok bad=$bad"
[ "$bad" -eq 0 ] || { echo "RESULT: FAIL"; exit 1; }
echo "RESULT: PASS"
