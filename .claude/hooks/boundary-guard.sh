#!/usr/bin/env bash
# boundary-guard.sh — PreToolUse hook.
# Inspects bash commands for hard-to-reverse patterns; exits 2 to block when detected.
# Safety hook class: fail-closed on parse failure or cannot-determine-safety.
# Uses Python parser for JSON extraction — sed regex is fragile on escaped quotes.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

PARSER="${LIB_DIR}/json-parser.py"
if [ ! -r "$PARSER" ]; then
    echo "boundary-guard: missing required JSON parser at ${PARSER}. Blocking — fail-closed." >&2
    exit 2
fi
# Windows/Git-Bash: python3 may resolve to the Windows-native interpreter, which cannot open an
# MSYS (/c/...) path arg — it mangles to a bogus C:\c\... and the parser fail-closes every command.
# Convert to a mixed (C:/...) form both bash and Windows python accept; no-op fallback where cygpath
# is absent (Linux/macOS native python3 reads the POSIX path directly). Fail-closed checks unchanged.
PARSER_PY="$PARSER"
command -v cygpath >/dev/null 2>&1 && PARSER_PY="$(cygpath -m "$PARSER" 2>/dev/null || printf '%s' "$PARSER")"

# Fail-closed if python3 unavailable (cannot safely parse — block).
if ! command -v python3 >/dev/null 2>&1; then
    echo "boundary-guard: python3 not available — cannot safely parse hook input. Blocking — fail-closed." >&2
    exit 2
fi

# Single-source credential patterns (shared with secret-scanner). Best-effort: the Bash
# write-redirect secret backstop below is skipped if absent; the destructive matchers don't need it.
PATTERNS="${LIB_DIR}/secret-patterns.sh"
[ -r "$PATTERNS" ] && . "$PATTERNS"

INPUT="$(cat)"

# Parse tool_name — distinguish parser-failure (malformed JSON, exit 1)
# from field-absent (empty output, exit 0). Safety class: fail-closed on parser exit 1.
TOOL="$(printf '%s' "$INPUT" | python3 "$PARSER_PY" tool_name)"
PARSE_STATUS=$?
if [ $PARSE_STATUS -ne 0 ]; then
    echo "boundary-guard: malformed hook input (parser exit ${PARSE_STATUS}). Blocking — fail-closed for safety." >&2
    exit 2
fi
[ "$TOOL" != "Bash" ] && exit 0

# Bash command is at tool_input.command in PreToolUse event JSON.
CMD="$(printf '%s' "$INPUT" | python3 "$PARSER_PY" tool_input.command)"
PARSE_STATUS=$?
if [ $PARSE_STATUS -ne 0 ]; then
    echo "boundary-guard: cannot parse Bash command field. Blocking — fail-closed for safety." >&2
    exit 2
fi
# Bash tool invocation with missing/empty command is malformed; safety class fails closed.
if [ -z "$CMD" ]; then
    echo "boundary-guard: Bash tool invoked with empty command. Blocking — fail-closed for safety." >&2
    exit 2
fi

# Axiom-13 fast benign-exit (perf, NOT a safety decision). A command containing NONE of the tokens any
# matcher below keys on cannot match any rule — so exit 0 after ONE grep instead of ~30 spawns (Windows
# fork/exec is ~60ms each; the full walk measured ~2.4s on the common benign case). The alternation is a
# deliberate SUPERSET: over-broad only ever falls THROUGH to the full matchers (no safety loss); a MISSED
# token would skip a real check, so mechanical-regression covers every matcher class to prove it complete.
# A literal '>' / 'tee' keeps every redirect on the full path (the Bash credential-write backstop).
if ! grep -qiE 'git|mkfs|wipefs|shred|blkdiscard|sgdisk|remove-item|rmdir|clear-disk|clear-content|format|filter-branch|filter-repo|reflog|stash|worktree|update-ref|powershell|pwsh|get-content|curl|wget|iwr|invoke-webrequest|invoke-restmethod|truncate|xargs|/dev/|secrets|credential|id_rsa|id_dsa|id_ecdsa|id_ed25519|\.env|\.pem|\.key|\.p12|\.pfx|\.ssh|\.netrc|\.aws|\.git-cred|\.docker|\.kube|gh/hosts|tee|>|:[[:space:]]*\(\)|(^|[^a-z])(rm|rd|ri|dd|del|drop|delete|erase|find)([^a-z]|$)' <<<"$CMD"; then
    exit 0
fi

block() {
    local reason="$1"
    echo "boundary-guard: blocked — ${reason}. Hard-to-reverse action requires explicit user confirmation. If intentional, re-invoke with scope-matching authorization." >&2
    exit 2
}

# Hard-to-reverse pattern matching against the command string.
# Patterns are heuristics; user can confirm intent by re-invoking with explicit auth.

# Hard-to-reverse git/rm patterns — whitespace / flag-order-agnostic grep -iE, anchored on the
# destructive SEMANTIC rather than a literal flag spelling. Mirrors the disciplined SQL/secret
# matchers below. Literal-substring case-globs were evadable by extra spaces, flag reordering
# (-fr vs -rf), interleaved flags (git -c x push), fused clusters (-xdf), and +refspec.

# git push force: --force / --force-with-lease / a short-flag cluster containing f, after push.
if printf '%s' "$CMD" | grep -qiE 'git[[:space:]][^|;&]*push[^|;&]*(--force(-with-lease)?|-[a-z]*f[a-z]*([[:space:]]|=|$))'; then
    block "git push force-variant (remote history overwrite)"
fi
# git push +refspec force (no --force token), e.g. 'git push origin +main'.
if printf '%s' "$CMD" | grep -qiE 'git[[:space:]][^|;&]*push[^|;&]*[[:space:]]\+[A-Za-z0-9_./-]+(:|[[:space:]]|$)'; then
    block "git push +refspec (force overwrite of remote ref)"
fi
# git push delete remote ref — '--delete'/'-d', or a colon-refspec ' :branch' (empty source = remote delete).
if printf '%s' "$CMD" | grep -qiE 'git[[:space:]][^|;&]*push[^|;&]*(--delete|[[:space:]]-d([[:space:]]|$)|[[:space:]]:[A-Za-z0-9_./-]+)'; then
    block "git push delete (remote branch/tag deletion on shared infra)"
fi
# git reset --hard (uncommitted state may be destroyed).
if printf '%s' "$CMD" | grep -qiE 'git[[:space:]][^|;&]*reset[^|;&]*--hard'; then
    block "git reset --hard (uncommitted state may be destroyed)"
fi
# git clean with a force/dir/ignored flag (-f/-d/-x in ANY cluster, or --force): destroys
# untracked + ignored files with no git history. Anchored on the flag semantic so -xdf/-fdx/-df
# are all caught; bare 'git clean' and 'git clean -n' (no-op / dry-run) are not.
if printf '%s' "$CMD" | grep -qiE 'git[[:space:]][^|;&]*clean[^|;&]*(-[a-z]*[fdx]|--force)'; then
    block "git clean force/dir variant (untracked + ignored files destroyed, no git history)"
fi
# Irreversible git ref/history deletion (CASE-SENSITIVE so branch -D force-delete is caught but safe
# lowercase -d is not over-matched). reflog expire + stash clear are genuinely unrecoverable.
if printf '%s' "$CMD" | grep -qE 'git[[:space:]][^|;&]*(branch[[:space:]][^|;&]*-D|tag[[:space:]][^|;&]*(-d|--delete)([[:space:]]|$)|reflog[[:space:]]+expire|stash[[:space:]]+clear|worktree[[:space:]]+remove[^|;&]*(--force|-f)|update-ref[[:space:]]+-d|filter-branch|filter-repo)'; then
    block "irreversible git ref/history deletion or rewrite (reflog expire / stash clear / branch -D / tag -d/--delete / worktree remove -f / update-ref -d / filter-branch / filter-repo)"
fi
# git commit/push --no-verify — bypasses pre-commit / pre-push verification hooks. Matches the
# explicit --no-verify only: precise, no false positive. Residual gaps (this is a discipline nudge,
# not a hard safety gate, so it does NOT chase git's full arg grammar): bare 'git commit -n',
# abbreviated '--no-ver', quote-split "--no-'verify'", and hook-disabling via
# 'git -c core.hooksPath=/dev/null' or HUSKY=0 are not caught — a short-flag regex over-blocks
# (-uno untracked-mode, -m message text) more than it helps; full coverage needs argv parsing.
if printf '%s' "$CMD" | grep -qiE 'git[[:space:]][^|;&]*(commit|push)[^|;&]*--no-verify'; then
    block "git --no-verify (bypasses pre-commit/pre-push verification — fix the failing check, do not skip the gate)"
fi
# Recursive rm — ORDER-INDEPENDENT: a recursive flag anywhere in the rm segment + a dangerous-scope
# target (absolute /, ~, $HOME, parent .., or a glob *). A clean relative subdir (rm -rf ./build,
# rm -rf node_modules) is NOT blocked — but a glob blocks even when relative (rm -rf ./build/* →
# unpredictable expansion). Quote before the path tolerated (rm -rf "/etc"); flag after
# target tolerated (rm /etc -rf). Segment-scoped so an unrelated absolute path after && doesn't leak.
if printf '%s' "$CMD" | grep -qiE 'rm[[:space:]][^|;&]*(-[a-z]*r[a-z]*|--recursive)'; then
    RM_SEG="$(printf '%s' "$CMD" | grep -oiE 'rm[[:space:]][^|;&]*')"
    if printf '%s' "$RM_SEG" | grep -qiE '[[:space:]]['\''"]?(/|~|\$HOME|\.\.([\\/[:space:]]|$))' || printf '%s' "$RM_SEG" | grep -qiE '[[:space:]]['\''"]?[^[:space:]|;&'\''"]*\*'; then
        block "recursive rm on absolute / home / parent / glob scope"
    fi
fi
# Windows-native destructive (PowerShell + cmd) — the PRIMARY platform here. Mirrors POSIX rm
# scoping: recursive/forced delete on a drive-root, system/profile dir, parent, glob, UNC, or
# env-var path. Remove-Item/ri -Recurse, rd/rmdir /s, del /s. Clean relative subdir is not blocked.
if printf '%s' "$CMD" | grep -qiE '(^|[[:space:]|;&(])(remove-item|rmdir|rd|del|erase|ri)[[:space:]]'; then
    if printf '%s' "$CMD" | grep -qiE '(-recurse|-r([[:space:]]|$)|/s([[:space:]/]|$))'; then
        if printf '%s' "$CMD" | grep -qiE '([A-Za-z]:[\\/]|\\\\|\$env:|%[A-Za-z_]+%|~[\\/]|\.\.[\\/]|\*)'; then
            block "Windows recursive/forced delete on drive-root / system / profile / parent / glob scope"
        fi
    fi
fi
# Windows disk format / volume clear / content wipe (irreversible).
if printf '%s' "$CMD" | grep -qiE '(format-volume|clear-disk|clear-content|format[[:space:]]+[A-Za-z]:)'; then
    block "Windows disk format / volume clear / content wipe"
fi
# POSIX raw-device write / filesystem format (irreversible) — mirrors the Windows matcher above,
# ANCHORED on a /dev/<block-device> TARGET so benign mentions (grep mkfs README, man mkfs) do NOT
# match. Covers dd writing to a block device, mkfs/wipefs/shred/blkdiscard/sgdisk on a device, and a
# redirect into /dev/<device>. /dev/null|stdout|stderr|tty|random|zero are not block devices → not
# matched; reading a device (dd of= a regular file) is a backup, not destruction. Residual (documented,
# not chased — same convention as the rm/git matchers, since regex cannot cleanly disambiguate them):
# cp/tee writing to a device (cp src/dest is ambiguous), variable-indirected targets (of="$DEV"), and
# sudo-/sh -c-wrapped forms. The settings.json deny-list is the complementary layer for those.
if printf '%s' "$CMD" | grep -qiE 'dd[[:space:]][^|;&]*of=/dev/(sd|nvme|hd|vd|mmcblk|mapper|dm-|md|rdisk|disk|loop|xvd|sr|fd)|(mkfs([.][a-z0-9]+)?|wipefs|shred|blkdiscard|sgdisk)[[:space:]][^|;&]*/dev/(sd|nvme|hd|vd|mmcblk|mapper|dm-|md|rdisk|disk|loop|xvd|sr|fd)|>[|]?[[:space:]]*/dev/(sd|nvme|hd|vd|mmcblk|mapper|dm-|md|rdisk|disk|loop|xvd|sr)'; then
    block "POSIX raw-device write / filesystem format (dd to a block device, mkfs/wipefs/shred/blkdiscard/sgdisk, or redirect to /dev/<device> — irreversible disk destruction)"
fi

# Destructive SQL — trailing boundary after the object keyword excludes 'DROP TABLESPACE' over-block.
if echo "$CMD" | grep -qiE '(drop[[:space:]]+(database|table|schema|index|view)([[:space:]]|;|$)|truncate[[:space:]]+table|delete[[:space:]]+from[[:space:]]+[^[:space:]]+([[:space:]]*$|[[:space:]]*;|[[:space:]]+--))'; then
    block "destructive SQL statement (drop / truncate / delete-from without where)"
fi

# Fork bomb — whitespace-tolerant regex (the literal case-glob was evadable by spacing/renaming).
if printf '%s' "$CMD" | grep -qE ':[[:space:]]*\(\)[[:space:]]*\{[[:space:]]*:[[:space:]]*\|[[:space:]]*:[[:space:]]*&[[:space:]]*\}[[:space:]]*;[[:space:]]*:'; then
    block "fork bomb pattern"
fi
# find with -delete / -exec rm — recursive deletion via find.
if printf '%s' "$CMD" | grep -qiE 'find[[:space:]][^|;&]*(-delete|-exec[[:space:]]+rm)'; then
    block "find with -delete / -exec rm (recursive deletion)"
fi
# xargs rm with a recursive/force flag — the find|xargs deletion form (scope lives upstream in the pipe).
if printf '%s' "$CMD" | grep -qiE 'xargs[[:space:]]([^|;&]*[[:space:]])?rm[[:space:]][^|;&]*(-[a-z]*[rf]|--recursive|--force)'; then
    block "xargs rm with recursive/force flag (piped recursive/forced deletion)"
fi

# Remote-to-shell pipe — curl/wget output piped to a shell or interpreter, ANY spacing, incl. a
# 'sudo' between pipe and shell (silent RCE if it runs). grep -iE so all spacings catch.
if printf '%s' "$CMD" | grep -qiE '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(sh|bash|zsh|dash|ksh|python[23]?|perl|ruby|node)([[:space:]]|$|;|&|\|)'; then
    block "remote-to-shell pipe (curl/wget piped to a shell/interpreter)"
fi
# Remote code via process/command substitution fed to a shell or eval: bash <(curl…),
# eval "$(curl…)", sh -c "$(wget…)", source <(curl…). The shell/eval keyword precedes the substitution.
if printf '%s' "$CMD" | grep -qiE '(eval|source|sh|bash|zsh|dash|ksh)[[:space:]][^|;&]*[<$]\([^)]*(curl|wget)'; then
    block "remote code via process/command substitution (curl/wget in a substitution fed to a shell)"
fi

# Bash-mediated credential WRITE — a write-redirect (> / >> / tee) carrying a vendor-key / DSN /
# private-key / AWS-secret pattern. Closes the shell path that bypasses secret-scanner (which only
# sees Write/Edit/MultiEdit). Best-effort: skipped if the shared pattern lib was unavailable.
if [ -n "${SECRET_VENDOR:-}" ] && printf '%s' "$CMD" | grep -qE '(>>?[[:space:]]*[^|;&[:space:]]|(^|[[:space:]|;&])tee[[:space:]])'; then
    if printf '%s' "$CMD" | grep -qE -- "$SECRET_VENDOR" \
       || printf '%s' "$CMD" | grep -qiE -- "$SECRET_DSN" \
       || printf '%s' "$CMD" | grep -qE -- "$SECRET_PK" \
       || printf '%s' "$CMD" | grep -qiE -- "$SECRET_AWS"; then
        block "Bash-mediated credential write (secret pattern in a > / >> / tee redirect)"
    fi
fi

# Shell-mediated secret-file reads (defense in depth against settings deny gaps).
# Uses grep with word-boundary-aware regex to avoid false positives like ".envoy.yaml".
# Basename class targeted: .env, .env.*, foo/.env, foo/.env.* — and same for .pem, .key.

# .env-class reads via common shell tools (cat / more / less / head / tail / type / xxd / od / hexdump).
if echo "$CMD" | grep -qE '(^|[[:space:]>|&;`(])(cat|more|less|head|tail|type|xxd|od|hexdump|base64|file|strings|nl|tac|sort|grep|awk|sed)([[:space:]]+[^[:space:]]+)*[[:space:]]+([^[:space:]]*/)?\.env(rc)?(\.[A-Za-z0-9._-]+)?([[:space:]]|$|;|&|\||>)'; then
    block "shell-mediated .env-class secret read"
fi
# .env via dd if=, or sourced (source / .) which READS AND INJECTS every KEY=value into the environment.
if echo "$CMD" | grep -qE '(dd[[:space:]]+[^|;&]*if=([^[:space:]]*/)?\.env|(^|[[:space:]|;&])(source|\.)[[:space:]]+([^[:space:]]*/)?\.env)'; then
    block "shell-mediated .env read (dd if= / source / . — source-class also injects into the environment)"
fi
# secrets.* / credentials.* file reads via shell tools (settings denies the Read tool, not Bash).
if echo "$CMD" | grep -qiE '(^|[[:space:]>|&;`(])(cat|more|less|head|tail|type|xxd|od|hexdump|base64|file|strings|nl|tac)([[:space:]]+[^[:space:]]+)*[[:space:]]+([^[:space:]]*/)?(secrets|credentials)\.(json|ya?ml|ini|txt|conf|env)([[:space:]]|$|;|&|\||>)'; then
    block "shell-mediated secrets/credentials file read"
fi

# .env via redirection (< .env, while read < .env, cat < .env, etc.)
if echo "$CMD" | grep -qE '<[[:space:]]*([^[:space:]]*/)?\.env(\.[A-Za-z0-9._-]+)?([[:space:]]|$|;|&|\|)'; then
    block "shell redirect read of .env-class file"
fi

# .env via copy / archive / encode (cp / mv / tar / zip / scp / rsync / sftp on .env-class)
if echo "$CMD" | grep -qE '(^|[[:space:]])(cp|mv|tar|zip|7z|rar|scp|rsync|sftp|curl[[:space:]]+-T|wget[[:space:]]+--post-file)([[:space:]]+[^[:space:]]+)*[[:space:]]+([^[:space:]]*/)?\.env(\.[A-Za-z0-9._-]+)?([[:space:]]|$|;|&|\|)'; then
    block "shell-mediated .env-class copy / archive / encode"
fi
# curl/wget exfil of .env-class via upload flags (-T / --upload-file / -F / --form / -d / --data*), @file form.
if echo "$CMD" | grep -qiE '(curl|wget)[^|;&]*(-T|--upload-file|-F|--form|-d|--data(-binary|-raw|-urlencode)?)[^|;&]*@[^[:space:]]*\.env([^A-Za-z0-9._-]|$)'; then
    block "curl/wget exfil of .env-class file (@file upload)"
fi

# Python heredoc / inline-script reading .env-class.
if echo "$CMD" | grep -qE '(python[23]?[[:space:]]+(-c|-)|python[23]?[[:space:]]*$)'; then
    if echo "$CMD" | grep -qE '\.env(rc)?([[:space:]"\x27]|$|\.[A-Za-z0-9._-]+["\x27])'; then
        block "python inline / heredoc reading .env-class file"
    fi
fi

# Node inline-script reading .env-class.
if echo "$CMD" | grep -qE 'node[[:space:]]+(-e|--eval)'; then
    if echo "$CMD" | grep -qE '\.env([[:space:]"\x27]|$|\.[A-Za-z0-9._-]+["\x27])'; then
        block "node -e / --eval reading .env-class file"
    fi
fi

# PowerShell variants on Windows side (Get-Content / iwr | iex).
if echo "$CMD" | grep -qiE '(powershell|pwsh)[[:space:]]+.*get-content[[:space:]]+([^[:space:]]*[\\/])?\.env'; then
    block "powershell Get-Content reading .env-class file"
fi
if echo "$CMD" | grep -qiE '(powershell|pwsh)[[:space:]]+.*((iwr|invoke-webrequest|invoke-restmethod).*\|[[:space:]]*iex)'; then
    block "powershell remote-to-shell pipe (iwr | iex)"
fi

# Private-key / .ssh / .netrc / cloud-creds reads.
if echo "$CMD" | grep -qE '(^|[[:space:]>|&;`(])(cat|more|less|head|tail|type|base64|file|strings|nl|tac|cp|mv|tar|scp|rsync)([[:space:]]+[^[:space:]]+)*[[:space:]]+([^[:space:]]*\.(pem|key|p12|pfx)([[:space:]]|$|;|&|\||>)|([^[:space:]]*/)?id_(rsa|dsa|ecdsa|ed25519)([[:space:]]|$|;|&|\||>)|([^[:space:]]*/)?(\.ssh|\.netrc|\.aws/credentials|\.git-credentials|\.docker/config\.json|\.kube/config|\.config/gh/hosts\.ya?ml)([[:space:]/]|$))'; then
    block "shell-mediated private-key (.pem/.key/.p12/.pfx, extension or dotfile) / .ssh / .netrc / cloud-creds / git-docker-kube-gh creds access"
fi

exit 0
