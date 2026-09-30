# lesslop on Codex

## Install

```
codex plugin marketplace add slovozaslovo/lesslop
codex plugin add lesslop@lesslop
```

## How it works

Codex gets a skill because it removed plugin-shipped hooks. `codex features list`
reports `plugin_hooks  removed  false` while `hooks` stays stable. A skill is
instructions the model follows, so the guarantee is weaker than the hook.

| Path | Role |
|---|---|
| `.codex-plugin/plugin.json` | Codex manifest, points at `skills/` |
| `skills/lesslop/SKILL.md` | the same rule, as a Codex skill |
