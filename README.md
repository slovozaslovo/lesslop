# lesslop

Every claim the agent writes carries a tag. Checked, or from memory.

```
[proof: src/auth.py:42]     checked this session
{unverified}                from memory
```

Claude Code, OpenAI Codex, Cursor.

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

## The rule

1. **Tag every claim.** Any statement about a file, command, output, tool,
   service, test, number, date, name, or how an external library behaves must
   carry `[proof: ...]` or `{unverified}` in the same sentence. No tag, no sentence.

2. **No exceptions.** "Basic", "textbook", "well-known", "obvious", "standard",
   "from training" are not verification. Anything recalled from memory is
   `{unverified}` by definition — definitional facts and round numbers included.

3. **Verify, don't defer.** "Want me to check?" is not a substitute for
   checking. If verification is cheap, do it before answering.

4. **When corrected.** Told you stated something unverified? Don't defend, don't
   re-explain. Verify or tag, then re-answer.

Two syntax rules. Markdown eats the tag otherwise:

- Curly braces. `<unverified>` reads as an unknown HTML tag and the browser
  drops it, so the warning disappears.
- A space after the closing `]`. `]` touching `(` is link syntax:
  `[proof: wc -l a.py](that is 44)` renders as a link.

## Install

### Claude Code

```
/plugin marketplace add slovozaslovo/lesslop
/plugin install lesslop
```

### Codex

```
codex plugin marketplace add slovozaslovo/lesslop
codex plugin add lesslop@lesslop
```

### Cursor

Untested. Cursor reads hooks from `~/.cursor/hooks.json` (global) or
`<project>/.cursor/hooks.json`; this repo ships `.cursor-plugin/plugin.json` and
`hooks/hooks-cursor.json`.

### Claude desktop / web chat, without a terminal

**Customize** → **Plugins** → **Browse plugins** → add `slovozaslovo/lesslop` as a
marketplace → **Install**. A `.plugin` file (a zip of this repo) can also be
uploaded directly.

Plugins are not available on mobile.

## How it works on each host

| Host | Mechanism | Fires | Tested |
|---|---|---|---|
| Claude Code | `UserPromptSubmit` hook | every prompt | yes |
| Codex | skill (`skills/lesslop/SKILL.md`) | every turn | yes |
| Cursor | `sessionStart` hook | once per session | no |

Codex gets a skill because it removed plugin-shipped hooks. `codex features list`
reports `plugin_hooks  removed  false` while `hooks` stays stable. A skill is
instructions the model follows, so the guarantee is weaker than the hook.

Cursor fires once per session. Its per-prompt event `beforeSubmitPrompt` cannot
inject text. Only `sessionStart`, `postToolUse` and `postToolUseFailure` carry
`additional_context`, so the rule can decay over a long session.

## Requirements

`python3` on `PATH`. Stdlib only. No install step, no network.

Missing `python3` = the hook exits 127 and the session carries on without the
rule. It fails loudly rather than emitting empty output.

## Layout

| Path | Role |
|---|---|
| `.claude-plugin/plugin.json` | Claude Code manifest |
| `.claude-plugin/marketplace.json` | lets others `marketplace add` this repo |
| `.codex-plugin/plugin.json` | Codex manifest, points at `skills/` |
| `.cursor-plugin/plugin.json` | Cursor manifest (untested) |
| `hooks/rule.py` | the rule text, single source for every host |
| `hooks/hooks.json` | binds `UserPromptSubmit` (Claude Code) |
| `hooks/evidence_rule.py` | Claude Code envelope |
| `hooks/hooks-cursor.json` | binds `sessionStart` (Cursor) |
| `hooks/evidence_rule_cursor.py` | Cursor envelope |
| `skills/lesslop/SKILL.md` | the same rule, as a Codex skill |
| `tests/run.sh` | contract tests |

## Tests

```
bash tests/run.sh
```

Nine checks: exit status, JSON validity, each host's envelope, both tags present,
no `](` sequence inside the rule, and imports restricted to `json`, `sys` and
`rule`. Imports are read off the parsed AST, not the source text. One check
compares hosts byte for byte, so the wording cannot drift between them.

## Off switch

```
claude plugin disable lesslop
```

## Licence

MIT.
