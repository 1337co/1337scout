#!/usr/bin/env bash
# secret-scanner.sh — PreToolUse hook (Write / Edit / MultiEdit / NotebookEdit).
# Heuristic, defense-in-depth credential scanner: exits 2 to block when written content matches a
# credential pattern. Safety hook class: fail-closed on parse failure or cannot-determine-safety.
#
# NOT airtight — one layer among three (settings.json deny-globs + the model's own credential
# discipline are the others). Documented heuristic limits it does NOT catch: base64/otherwise
# encoded secrets, keys obfuscated beyond a single whole-input concatenation, and novel vendor
# formats with no signature here. Patterns are anchored to the real key FORMAT (charset + length +
# a leading token boundary) so benign text that merely contains a prefix (hf_hub_download,
# AKIArmadillo, desk-ant-farm, AIzaModel, a password-policy line) does NOT false-positive.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

PARSER="${LIB_DIR}/json-parser.py"
if [ ! -r "$PARSER" ]; then
    echo "secret-scanner: missing required JSON parser at ${PARSER}. Blocking — fail-closed." >&2
    exit 2
fi
# Windows/Git-Bash: convert parser path so a Windows-native python3 can open it (MSYS /c/... mangles to C:\c\...). No-op without cygpath (Linux/macOS).
PARSER_PY="$PARSER"
command -v cygpath >/dev/null 2>&1 && PARSER_PY="$(cygpath -m "$PARSER" 2>/dev/null || printf '%s' "$PARSER")"
if ! command -v python3 >/dev/null 2>&1; then
    echo "secret-scanner: python3 not available — cannot safely parse hook input. Blocking — fail-closed." >&2
    exit 2
fi

# Single-source credential patterns (shared with boundary-guard). FAIL-CLOSED — secret-scanner is
# the PRIMARY content scanner; without the lib it cannot do its job, so it blocks (unlike
# boundary-guard's best-effort backstop). This makes the lib's "sourced by BOTH" claim true.
PATTERNS="${LIB_DIR}/secret-patterns.sh"
if [ ! -r "$PATTERNS" ]; then
    echo "secret-scanner: missing required pattern lib at ${PATTERNS}. Blocking — fail-closed." >&2
    exit 2
fi
. "$PATTERNS"

INPUT="$(cat)"

TOOL="$(printf '%s' "$INPUT" | python3 "$PARSER_PY" tool_name)"
PARSE_STATUS=$?
if [ $PARSE_STATUS -ne 0 ]; then
    echo "secret-scanner: malformed hook input (parser exit ${PARSE_STATUS}). Blocking — fail-closed for safety." >&2
    exit 2
fi
case "$TOOL" in
    Write|Edit|MultiEdit|NotebookEdit) : ;;
    *) exit 0 ;;
esac

# All string leaves under tool_input, newline-joined (generic across write-tool shapes).
CONTENT="$(printf '%s' "$INPUT" | python3 "$PARSER_PY" --strings tool_input)"
PARSE_STATUS=$?
if [ $PARSE_STATUS -ne 0 ]; then
    echo "secret-scanner: cannot parse tool_input. Blocking — fail-closed." >&2
    exit 2
fi
[ -z "$CONTENT" ] && exit 0

# CAT = the same leaves with separators removed, so a credential split across two MultiEdit
# edits[].new_string entries (or a newline injected mid-token) reconstitutes for the high-confidence
# prefix patterns. Generic label-value runs on CONTENT only (structure-preserving; concatenation
# would manufacture false label=value adjacencies).
CAT="$(printf '%s' "$CONTENT" | tr -d '\n\r\t ')"
BOTH="$CONTENT
$CAT"

# Axiom-13 fast benign-exit (perf, NOT a safety decision). Content containing none of the five
# credential-pattern signatures cannot match any rule below — exit 0 after ONE combined grep instead
# of five separate spawns. The union is a SUPERSET of all five matchers (case-insensitive on the full
# BOTH stream is broader than the per-pattern -qE/-qiE on BOTH/CONTENT), so it can only fall THROUGH;
# a missed signature would skip a real check, so mechanical-regression's secret-write cases gate it.
if ! grep -qiE -- "$SECRET_VENDOR|$SECRET_DSN|$SECRET_PK|$SECRET_AWS|$SECRET_GENERIC" <<<"$BOTH"; then
    exit 0
fi

block() {
    echo "secret-scanner: blocked — content matches credential pattern (${1}). Replace inline secret with an environment variable, secret-manager reference, or .env file (gitignored) before write. If a false positive, surface to the user for explicit override." >&2
    exit 2
}

# Vendor keys — anchored format, from the shared single-source lib (SECRET_VENDOR).
if printf '%s' "$BOTH" | grep -qE -- "$SECRET_VENDOR"; then
    block "vendor API key / token / JWT (anchored format)"
fi

# Connection string with an embedded password (shared lib; {2,} catches 2-char passwords).
if printf '%s' "$BOTH" | grep -qiE -- "$SECRET_DSN"; then
    block "connection string with embedded credential (scheme://user:pass@host)"
fi

# Private-key blocks + the AWS secret label (shared lib).
if printf '%s' "$BOTH" | grep -qE -- "$SECRET_PK"; then
    block "private key block"
fi
if printf '%s' "$BOTH" | grep -qiE -- "$SECRET_AWS"; then
    block "AWS secret access key"
fi

# Generic credential-labeled assignment (shared lib: bare labels secret|token|credential|pwd +
# dotted/colon value class). Run on CONTENT (structure-preserving — concatenation would manufacture
# false label=value adjacencies).
if printf '%s' "$CONTENT" | grep -qiE -- "$SECRET_GENERIC"; then
    block "credential-labeled assignment with long value"
fi

exit 0
