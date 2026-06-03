#!/usr/bin/env bash
# json-helper.sh — shared JSON primitives for hooks.
# Sourced by other hook scripts. Cross-platform (bash 3.2+, MSYS / Git Bash compatible).
# Does not require jq; basic operations only.

# Escapes a string for safe embedding in JSON (backslash / quote / newline / control).
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

# Emits Anthropic-documented hookSpecificOutput.additionalContext schema.
# Per Claude Code hooks docs: JSON stdout with hookSpecificOutput.additionalContext
# is the documented context-injection mechanism for UserPromptSubmit + SessionStart events.
# Usage: json_additional_context "<EventName>" "your message"
# Example: json_additional_context "UserPromptSubmit" "$RECALL"
json_additional_context() {
    local event="$1"
    local msg
    msg="$(json_escape "$2")"
    printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$event" "$msg"
}

# Wraps untrusted content in semantic markers (data, not instructions). Per kit-authoring hook
# rule 6. Neutralizes marker-injection (a planted </untrusted-content> in the value would close the
# wrapper early — a breakout) and control bytes (which would break the JSON the caller emits) by
# stripping angle brackets + control chars from the value first; disk-sourced data (cwd/timestamp)
# has no legitimate use for them. Does NOT json-escape the result: the caller's emit path
# (json_additional_context) escapes the composed message once.
json_wrap_untrusted() {
    local c="$1"
    c="${c//<}"
    c="${c//>}"
    c="$(printf '%s' "$c" | tr -d '\000-\037')"
    printf '<untrusted-content>%s</untrusted-content>' "$c"
}
