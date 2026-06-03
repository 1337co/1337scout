#!/usr/bin/env python3
"""json-parser.py — safe JSON field extraction for hooks.

Replaces the fragile sed regex in json-helper.sh which fails on escaped quotes,
multi-line content, and nested objects.

Usage:
    cat event.json | python3 lib/json-parser.py <field>
    cat event.json | python3 lib/json-parser.py <field.subfield.subfield>

Returns the field value to stdout. Exit 0 on success or field-not-found.
Exit 1 on malformed JSON or invocation error. Never raises.

The hook decides what to do with empty output (treat as field-absent).
"""
import json
import sys


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(1)

    field_path = sys.argv[1]

    try:
        raw = sys.stdin.read()
        if not raw.strip():
            # Empty input — distinct from malformed; field-absent semantics, exit 0.
            sys.exit(0)
        data = json.loads(raw)
    except (json.JSONDecodeError, ValueError):
        # Malformed JSON — exit 1 so caller can distinguish from field-absent (exit 0).
        # Safety hooks must fail-closed (exit 2) on parser exit 1.
        # Adherence hooks may fail-open (exit 0) on parser exit 1 with annotation.
        sys.exit(1)
    except Exception:
        sys.exit(1)

    # --strings <path>: collect ALL string leaf values under <path>, newline-joined.
    # Generic extraction for safety scanning — sees every string a write tool carries
    # (content, new_string, new_source, edits[].new_string, ...) without per-tool field
    # enumeration, so a new write tool's payload is covered with no parser change.
    if field_path == "--strings":
        target = sys.argv[2] if len(sys.argv) > 2 else ""
        value = data
        if target:
            for part in target.split('.'):
                if isinstance(value, dict) and part in value:
                    value = value[part]
                else:
                    sys.exit(0)
        acc = []

        def _walk(v):
            # In-document-order (not a LIFO stack) so adjacent split values stay adjacent —
            # a credential split across edits[0]/edits[1].new_string must reconstitute in order.
            if isinstance(v, str):
                acc.append(v)
            elif isinstance(v, dict):
                for x in v.values():
                    _walk(x)
            elif isinstance(v, list):
                for x in v:
                    _walk(x)

        _walk(value)
        sys.stdout.write("\n".join(acc))
        sys.exit(0)

    # Support nested field access via dot notation.
    parts = field_path.split('.')
    value = data
    for part in parts:
        if isinstance(value, dict) and part in value:
            value = value[part]
        else:
            # Field not present — emit nothing.
            sys.exit(0)

    # Emit value. Strings emitted directly; non-strings JSON-serialized.
    if value is None:
        sys.exit(0)
    if isinstance(value, str):
        sys.stdout.write(value)
    elif isinstance(value, (int, float, bool)):
        sys.stdout.write(str(value))
    else:
        # dict / list / nested — emit JSON.
        sys.stdout.write(json.dumps(value, ensure_ascii=False))

    sys.exit(0)


if __name__ == "__main__":
    main()
