#!/usr/bin/env python3
"""Claude Code UserPromptSubmit hook: injects the evidence rule on every prompt.

Standard library only.
"""
import json
import sys

# The script's own directory is on sys.path. No os import: tests/run.sh forbids it.
from rule import RULE

json.dump({
    "suppressOutput": True,
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": RULE,
    },
}, sys.stdout)
