#!/usr/bin/env bash
# fs-helper.sh — shared filesystem primitives for hooks.
# Sourced by other hook scripts. Cross-platform (bash 3.2+, MSYS / Git Bash compatible).

# Returns 0 if file exists and is readable, 1 otherwise.
fs_file_readable() {
    local path="$1"
    [ -r "$path" ] && [ -f "$path" ]
}

# Creates a directory if it does not exist. Fails loud if creation fails.
fs_ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            echo "fs-helper: failed to create dir: $dir" >&2
            return 1
        }
    fi
    return 0
}

# Writes content to a path atomically (via temp file + mv).
fs_atomic_write() {
    local path="$1"
    local content="$2"
    local tmp="${path}.tmp.$$"
    printf '%s' "$content" > "$tmp" || return 1
    mv "$tmp" "$path" || return 1
}

