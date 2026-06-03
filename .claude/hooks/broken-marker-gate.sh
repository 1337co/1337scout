#!/usr/bin/env bash
# broken-marker-gate.sh — PostToolUse hook (Write / Edit / MultiEdit).
# NON-safety ADVISORY lint: surfaces incomplete-deliverable markers (NotImplementedError / throw-not-
# implemented / todo!() / unfilled [bracket]/"replace this" / lorem ipsum) the model leaves in WRITTEN
# code while reporting complete — the mechanical teeth for the kit's "prove it's done" axiom. It NEVER
# hard-blocks and is FAIL-OPEN (any missing-dep / parse / unknown-tool condition exits 0 silently).
# Opposite stance from the fail-CLOSED safety hooks (secret-scanner / boundary-guard) — do not conflate.
#
# Precision guard: it scans the ADDED content from THIS write (the tool_input
# string leaves: Write.content / Edit.new_string / MultiEdit.edits[].new_string), NOT the whole file —
# so a pre-existing legitimate TODO does not re-surface on every unrelated edit.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
PARSER="${LIB_DIR}/json-parser.py"
GATE="${LIB_DIR}/broken_marker_gate.py"

[ -r "$PARSER" ] || exit 0
[ -r "$GATE" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

PARSER_PY="$PARSER"; GATE_PY="$GATE"
if command -v cygpath >/dev/null 2>&1; then
    PARSER_PY="$(cygpath -m "$PARSER" 2>/dev/null || printf '%s' "$PARSER")"
    GATE_PY="$(cygpath -m "$GATE" 2>/dev/null || printf '%s' "$GATE")"
fi

INPUT="$(cat)"

TOOL="$(printf '%s' "$INPUT" | python3 "$PARSER_PY" tool_name 2>/dev/null)" || exit 0
case "$TOOL" in
    Write|Edit|MultiEdit) : ;;
    *) exit 0 ;;
esac

FILE="$(printf '%s' "$INPUT" | python3 "$PARSER_PY" tool_input.file_path 2>/dev/null)" || exit 0
[ -n "$FILE" ] || exit 0
FILE_PY="$FILE"
command -v cygpath >/dev/null 2>&1 && FILE_PY="$(cygpath -m "$FILE" 2>/dev/null || printf '%s' "$FILE")"

# ADDED = all string leaves under tool_input (content / new_string / edits[].new_string) = what this
# write introduced. Scan THAT (not the file); pass file_path so the detector applies ext/path/generated
# guards. fail-open: swallow stderr, exit 0 on any failure.
ADDED="$(printf '%s' "$INPUT" | python3 "$PARSER_PY" --strings tool_input 2>/dev/null)" || exit 0
[ -n "$ADDED" ] || exit 0
OUT="$(printf '%s' "$ADDED" | python3 "$GATE_PY" --hook "$FILE_PY" 2>/dev/null)" || exit 0
[ -n "$OUT" ] && printf '%s' "$OUT"
exit 0
