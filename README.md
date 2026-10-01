# lesslop

Every claim the agent writes carries a tag. Checked, or from memory.

```
[proof: src/auth.py:42]     checked this session
{unverified}                from memory
```

Claude Code. For Codex and Cursor see [docs/codex.md](docs/codex.md) and
[docs/cursor.md](docs/cursor.md).

## Why a hook

The rule is injected into every prompt by a `UserPromptSubmit` hook, outside the
model's control. Same question, same model, plugin off then on:

```
off   PostgreSQL listens on port 5432 by default.
on    5432 {unverified}
```

Checkable answers get checked:

```
on    44 [proof: wc -l hooks/evidence_rule.py]
```

## Install

### Claude Code

```
/plugin marketplace add slovozaslovo/lesslop
/plugin install lesslop
```

## Requirements

`python3` on `PATH`. Stdlib only. No install step, no network.

Missing `python3` = the hook exits 127 and the session carries on without the
rule. It fails loudly rather than emitting empty output.

## Layout

| Path | Role |
|---|---|
| `.claude-plugin/plugin.json` | Claude Code manifest |
| `.claude-plugin/marketplace.json` | lets others `marketplace add` this repo |
| `hooks/rule.py` | the rule text, single source for every host |
| `hooks/hooks.json` | binds `UserPromptSubmit` (Claude Code) |
| `hooks/evidence_rule.py` | Claude Code envelope |
| `skills/lesslop/SKILL.md` | the same rule, as a skill |
| `tests/run.sh` | contract tests |

## Tests

```
bash tests/run.sh
```

The suite checks exit status, JSON validity, each host's envelope, both tags,
no `](` sequence inside the rule, and imports restricted to `json`, `sys` and
`rule`. Imports are read off the parsed AST, not the source text, for every
hook module. Hosts must emit `rule.RULE` and nothing else, ignore stdin, and
write nothing to stderr. The Claude and Cursor bindings, the manifest version,
and the skill's obligations are checked the same way, so the wording cannot
drift between them.

## Off switch

```
claude plugin disable lesslop
```

## Licence

MIT.
