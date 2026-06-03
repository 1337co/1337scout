#!/usr/bin/env bash
# config-protection.sh — PreToolUse hook (Write|Edit|MultiEdit).
# Blocks edits to linter / formatter / CI-verification gate configs so the agent FIXES THE CODE
# rather than WEAKENING THE GATE to make a failing check pass.
#
# DISCIPLINE class, NOT safety → FAIL-OPEN: on any parse failure, missing parser, or uncertainty,
# ALLOW (exit 0). A discipline-nudge hook must never fail-CLOSED and block legitimate work the way a
# safety hook (boundary-guard) deliberately does. Only blocks on a POSITIVE gate-config-path match.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER="${SCRIPT_DIR}/lib/json-parser.py"

# Fail-OPEN on any precondition (discipline nudge, not a safety gate).
[ -r "$PARSER" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
# Windows/Git-Bash: convert to a mixed path Windows python can open (same fix as boundary-guard #111).
PARSER_PY="$PARSER"
command -v cygpath >/dev/null 2>&1 && PARSER_PY="$(cygpath -m "$PARSER" 2>/dev/null || printf '%s' "$PARSER")"

INPUT="$(cat)"

TOOL="$(printf '%s' "$INPUT" | python3 "$PARSER_PY" tool_name 2>/dev/null)" || exit 0
case "$TOOL" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac

FP="$(printf '%s' "$INPUT" | python3 "$PARSER_PY" tool_input.file_path 2>/dev/null)" || exit 0
[ -n "$FP" ] || exit 0
# Windows paths use backslashes — normalize to POSIX so basename + the path regex match
# (else C:\repo\.eslintrc and C:\repo\.github\workflows\ci.yml bypass the /-only matchers).
# tr is used, not bash ${//}, because the parameter-expansion backslash replacement is unreliable
# across the MSYS bash builds this kit targets.
FP_NORM="$(printf '%s' "$FP" | tr '\\' '/')"
BASE="$(basename "$FP_NORM")"

# Gate-config basenames — linters, formatters, lint-staged/pre-commit, CI-gate configs. Editing these
# to make a failing check pass is weakening the gate, not fixing the code. tsconfig.json / package.json
# are EXCLUDED — they are real build config, not verification gates (over-blocking them would annoy).
if printf '%s' "$BASE" | grep -qiE '^(\.eslintrc([.].*)?|eslint[.]config[.][a-z]+|[.]eslintignore|[.]prettierrc([.].*)?|prettier[.]config[.][a-z]+|[.]prettierignore|[.]ruff[.]toml|ruff[.]toml|[.]flake8|[.]pylintrc|biome[.]jsonc?|[.]pre-commit-config[.]ya?ml|[.]golangci[.]ya?ml|[.]rubocop[.]ya?ml|[.]stylelintrc([.].*)?|[.]stylelintignore|[.]lintstagedrc([.].*)?|lint-staged[.]config[.][a-z]+|lefthook[.]ya?ml)$'; then
    echo "config-protection: blocked editing gate config '${BASE}' — fix the code that fails the check, do not weaken the gate to make it pass. If this is a deliberate gate-config change, edit it yourself or disable this hook." >&2
    exit 2
fi

# Path-based gate configs: CI workflows (.github/workflows/*) + git-hook managers (.husky/* / lefthook).
if printf '%s' "$FP_NORM" | grep -qiE '([.]github/workflows/[^/]+[.]ya?ml|[.]husky/[^/]+)$'; then
    echo "config-protection: blocked editing CI/hook gate '${FP}' — fix the code, do not weaken the gate to make it pass. Deliberate gate changes: edit it yourself or disable this hook." >&2
    exit 2
fi

# Residual gaps (discipline-nudge, not exhaustive): pyproject.toml / setup.cfg / tox.ini / pytest.ini
# / mypy.ini (hybrid real-config, excluded to avoid over-block, like tsconfig/package.json), and
# non-GitHub CI configs, are NOT gated. A determined gate-weakening via those is out of scope here.
exit 0
