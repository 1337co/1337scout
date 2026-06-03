#!/usr/bin/env bash
# secret-patterns.sh — single-source credential regexes, sourced by BOTH secret-scanner.sh (scans
# Write/Edit/MultiEdit content) and boundary-guard.sh (scans Bash write-redirect content). Single
# source so the two hooks cannot drift apart (the audit flagged hand-synced duplicate patterns).
#
# Anchored to real key FORMAT (leading non-word boundary + charset + minimum length) so benign text
# that merely contains a prefix (hf_hub_download, AKIArmadillo, a password-policy sentence) does not
# false-positive. NOT airtight (base64/encoded/novel-vendor secrets escape) — one layer of three.
#
# VENDOR / DSN / PK / AWS are high-confidence (used by both hooks, incl. the Bash write backstop).
# GENERIC is label=value heuristic (secret-scanner content scan only; would over-fire on shell args).

# shellcheck disable=SC2034
SECRET_VENDOR='(^|[^A-Za-z0-9_])(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|gh[opsur]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,}|sk-(ant|proj|or)-[A-Za-z0-9_-]{16,}|[sr]k_live_[A-Za-z0-9]{16,}|xox[bpasr]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|glpat-[A-Za-z0-9_-]{20}|hf_[A-Za-z0-9]{34}|eyJ[A-Za-z0-9_=-]{8,}\.eyJ[A-Za-z0-9_=-]{8,}\.[A-Za-z0-9_=-]{6,})'

# Connection string with an embedded password (N-14: {2,} so 2-char passwords no longer escape).
SECRET_DSN='[a-z][a-z0-9+.-]*://[^:@/[:space:]]+:[^@/[:space:]]{2,}@'

SECRET_PK='-----BEGIN [A-Z ]*PRIVATE KEY-----'

SECRET_AWS='aws_secret_access_key[[:space:]"'\''=:]{0,4}[A-Za-z0-9/+]{20,}'

# Generic credential-labeled assignment. Bare labels (secret|token|credential|pwd|passphrase) added
# (M-11); value class now includes . and : (N-13) so dotted/JWT-ish secrets do not escape. camelCase
# (secretToken=) is caught via the embedded lowercase label + the case-insensitive scan in the caller.
SECRET_GENERIC='(password|passwd|passphrase|api[_-]?key|secret[_-]?key|access[_-]?token|client[_-]?secret|auth[_-]?token|bearer[_-]?token|private[_-]?key|secret|token|credential|pwd)['\''"]?[[:space:]]*[=:][[:space:]]*['\''"]?[A-Za-z0-9/+=:._-]{16,}'
