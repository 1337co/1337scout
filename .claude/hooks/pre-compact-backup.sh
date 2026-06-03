#!/usr/bin/env bash
# pre-compact-backup.sh — PreCompact event hook.
# Captures conversation state before context compaction so it can be restored at next SessionStart.
# Pairs with compaction-recovery.sh.
# State hook class: failure is debug-visible (exit 1 + stderr), not silent (exit 0).

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

PARSER="${LIB_DIR}/json-parser.py"
if [ ! -r "$PARSER" ]; then
    echo "pre-compact-backup: missing required JSON parser at ${PARSER}" >&2
    exit 1
fi
# Windows/Git-Bash: convert parser path so a Windows-native python3 can open it (MSYS /c/... mangles to C:\c\...). No-op without cygpath (Linux/macOS).
PARSER_PY="$PARSER"
command -v cygpath >/dev/null 2>&1 && PARSER_PY="$(cygpath -m "$PARSER" 2>/dev/null || printf '%s' "$PARSER")"

if ! command -v python3 >/dev/null 2>&1; then
    echo "pre-compact-backup: python3 not available; state will not be backed up." >&2
    exit 1
fi

# fs-helper sourced for ensure_dir / atomic_write primitives.
if [ ! -r "${LIB_DIR}/fs-helper.sh" ]; then
    echo "pre-compact-backup: missing required helper lib ${LIB_DIR}/fs-helper.sh" >&2
    exit 1
fi
# shellcheck source=lib/fs-helper.sh
source "${LIB_DIR}/fs-helper.sh"

STATE_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/.kit-state"
if ! fs_ensure_dir "$STATE_DIR"; then
    echo "pre-compact-backup: cannot create state dir ${STATE_DIR}" >&2
    exit 1
fi

INPUT="$(cat)"

TIMESTAMP="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
SESSION_ID="$(printf '%s' "$INPUT" | python3 "$PARSER_PY" session_id 2>/dev/null)"
[ -z "$SESSION_ID" ] && SESSION_ID="unknown"

STATE_FILE="${STATE_DIR}/state-${SESSION_ID}.json"

# Write Python script to temp file so heredoc and here-string do not collide on stdin.
# (Prior bug: `python3 - ... <<'PYEOF' <<<"$INPUT"` — bash honors only the last
# stdin redirect; the heredoc was dropped and $INPUT was parsed as Python source.)
PY_SCRIPT="$(mktemp -t precompact-backup-XXXXXX.py 2>/dev/null || mktemp)"
trap 'rm -f "$PY_SCRIPT"' EXIT
# Same Windows/Git-Bash conversion for the temp script a Windows-native python3 must open.
PY_SCRIPT_PY="$PY_SCRIPT"
command -v cygpath >/dev/null 2>&1 && PY_SCRIPT_PY="$(cygpath -m "$PY_SCRIPT" 2>/dev/null || printf '%s' "$PY_SCRIPT")"

cat > "$PY_SCRIPT" <<'PYEOF'
import json
import sys

timestamp = sys.argv[1]
session_id = sys.argv[2]
cwd = sys.argv[3]

raw = sys.stdin.read()
try:
    event = json.loads(raw) if raw.strip() else {}
except json.JSONDecodeError:
    # Preserve raw input prefix for debug; cap at 8KB.
    event = {"_raw_unparsed_prefix": raw[:8192]}

state = {
    "timestamp": timestamp,
    "session_id": session_id,
    "cwd": cwd,
    "pre_compact_event": event,
}

# Emit to stdout; the bash caller writes it atomically (fs_atomic_write = temp + mv) so a crash
# mid-write cannot truncate the prior good state file.
json.dump(state, sys.stdout, ensure_ascii=False, indent=2)
PYEOF

STATE_JSON="$(printf '%s' "$INPUT" | python3 "$PY_SCRIPT_PY" "$TIMESTAMP" "$SESSION_ID" "$(pwd)")"
if [ $? -ne 0 ] || [ -z "$STATE_JSON" ]; then
    echo "pre-compact-backup: state serialization failed for session ${SESSION_ID}; recovery hook will see no prior state." >&2
    exit 1
fi
if ! fs_atomic_write "$STATE_FILE" "$STATE_JSON"; then
    echo "pre-compact-backup: atomic state write failed for session ${SESSION_ID}." >&2
    exit 1
fi

# State-hook contract (line 5): a degraded backup is debug-VISIBLE, not silent. If the PreCompact
# input was not parseable JSON, the Python preserved only the raw prefix; the file is still written
# (for debug + so recovery sees *something*), but signal exit 1 + stderr so the failure surfaces and
# recovery treats it as incomplete rather than a clean restore.
case "$STATE_JSON" in
    *'"_raw_unparsed_prefix"'*)
        echo "pre-compact-backup: PreCompact input was not parseable JSON; wrote a DEGRADED state file (raw prefix only) for session ${SESSION_ID}. Recovery will be incomplete." >&2
        exit 1
        ;;
esac

exit 0
