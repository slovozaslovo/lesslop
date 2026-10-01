# lesslop on Codex

## Install

```
codex plugin marketplace add slovozaslovo/lesslop
codex plugin add lesslop@lesslop
```

Then trust the hook. Codex skips a plugin's hooks until you review them: run
`/hooks` in the Codex CLI and trust the `UserPromptSubmit` hook from lesslop.
After a plugin update that changes the hook, Codex asks again.

## How it works

Codex loads the same `UserPromptSubmit` hook as Claude Code, from
`hooks/hooks.json`, and injects the rule on every prompt. Tested on Codex CLI
0.155.1. The plugin also ships the rule as a skill.

| Path | Role |
|---|---|
| `.codex-plugin/plugin.json` | Codex manifest, points at `skills/` |
| `hooks/hooks.json` | binds `UserPromptSubmit` |
| `hooks/evidence_rule.py` | prints the rule |
| `skills/lesslop/SKILL.md` | the same rule, as a skill |
