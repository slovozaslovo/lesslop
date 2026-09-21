# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning is [Semantic Versioning](https://semver.org/spec/v2.0.0.html) — while
the major version is `0`, breaking changes ship in minor bumps.

Every released version has a git tag of the form `lesslop--vX.Y.Z`.

## [0.6.0] — 2026-09-19

### Added
- Cursor support. `.cursor-plugin/plugin.json` and `hooks/hooks-cursor.json`,
  bound to `sessionStart`. Untested.
- `hooks/rule.py`, the rule text as a single source for every host. A test
  compares hosts byte for byte.
- `.github/workflows/test.yml`. Runs the contract tests, parses every manifest,
  fails when the three manifests disagree on version.

### Notes
- Cursor fires once per session. Its `beforeSubmitPrompt` event cannot inject
  text; only `sessionStart`, `postToolUse` and `postToolUseFailure` carry
  `additional_context`. Its envelope is a flat `{"additional_context": "..."}`.

[0.6.0]: https://github.com/slovozaslovo/lesslop/releases/tag/lesslop--v0.6.0
