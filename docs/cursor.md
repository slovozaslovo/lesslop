# lesslop on Cursor

## Install

Untested. Cursor reads hooks from `~/.cursor/hooks.json` (global) or
`<project>/.cursor/hooks.json`; this repo ships `.cursor-plugin/plugin.json` and
`hooks/hooks-cursor.json`.

## How it works

Cursor fires once per session. Its per-prompt event `beforeSubmitPrompt` cannot
inject text. Only `sessionStart`, `postToolUse` and `postToolUseFailure` carry
`additional_context`, so the rule can decay over a long session.

| Path | Role |
|---|---|
| `.cursor-plugin/plugin.json` | Cursor manifest (untested) |
| `hooks/hooks-cursor.json` | binds `sessionStart` (Cursor) |
| `hooks/evidence_rule_cursor.py` | Cursor envelope |
