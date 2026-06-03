#!/usr/bin/env bash
# discipline-loader.sh — SessionStart hook (startup | resume | compact).
# Injects active recall of the kit's core discipline at session start, including after compaction.
# Adherence hook class: fail-open with annotated compensation if libs missing.
# Blocking the prompt on a missing reminder library would be punishment for an
# author-side gap, not a safety boundary — so exit 0 + stderr instead of exit 2.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Adherence class: fail-open on missing helpers. Surface in stderr; do not block.
if [ ! -r "${LIB_DIR}/json-helper.sh" ]; then
    echo "discipline-loader: json-helper.sh missing in ${LIB_DIR} — recall injection skipped (adherence fail-open)." >&2
    exit 0
fi
# shellcheck source=lib/json-helper.sh
source "${LIB_DIR}/json-helper.sh"

# Detect event from input JSON (best-effort). Bound to SessionStart only; fall back to SessionStart.
INPUT=""
if [ -t 0 ]; then
    EVENT="SessionStart"
else
    INPUT="$(cat)"
    EVENT="$(printf '%s' "$INPUT" | sed -n 's/.*"hook_event_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
    case "$EVENT" in
        SessionStart) : ;;
        *) EVENT="SessionStart" ;;
    esac
fi

# Compact active-recall summary (bounded under ~120 tokens; session-start injection).
RECALL='Kit core recall: respond in user language; read before edit; prove with the concrete observable; end at the verdict (no unsolicited next steps); do not mirror kit authoring format in chat; hold verdict under pressure, re-verify against fresh observable.'

json_additional_context "$EVENT" "$RECALL"
exit 0
