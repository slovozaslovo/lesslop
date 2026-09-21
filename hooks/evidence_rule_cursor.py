#!/usr/bin/env python3
"""Cursor sessionStart hook: injects the evidence rule once per session. Untested.

Cursor's envelope is a flat {"additional_context": ...}. beforeSubmitPrompt cannot
inject text, so the rule lands once per session rather than on every prompt.
"""
import json
import sys

# The script's own directory is on sys.path. No os import: tests/run.sh forbids it.
from rule import RULE

json.dump({"additional_context": RULE}, sys.stdout)
