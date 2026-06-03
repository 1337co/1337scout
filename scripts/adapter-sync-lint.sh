#!/usr/bin/env bash
# adapter-sync-lint.sh — checks drift between kit constitution and its runtime adapters.
#
# LIMITATION: this lint catches STRUCTURAL drift only — stale phrases, schema mismatches,
# presence-pattern divergence, cap-number conflicts. It does NOT catch:
#   - ABSENCE-DRIFT: constitution content silently missing from adapter (was in old adapter, dropped)
#   - SEMANTIC DRIFT: technically aligned wording that misleads or implies different scope
#   - INTENT DRIFT: rule preserved but enforcement context lost
# Periodic manual deep-audit required per projection rewrite.
#
# Scope: this lint audits ONLY the kit's own files (constitution + kit adapters). It is
# self-contained: it audits only files within the kit folder.
#   Constitution: docs/KIT-CONSTITUTION.md (source of truth)
#   Adapters: CLAUDE.md, .claude/rules/kit-authoring.md
#
# Drift signals:
#   1. Stale authority phrases ("KIT-RED-LINES.md is supreme authority", etc.)
#   2. Stale path / naming references (retired element names, superseded paths)
#   3. Token cap mentioned in adapter differs from constitution cap table
#   4. Canonical section list mentioned in adapter differs from constitution
#   5. Pressure-state placement claims diverge from constitution Section 2
#   6. Authority hierarchy reference inconsistent
#
# Exit codes:
#   0 = clean (no drift)
#   1 = warnings (informational drift detected)
#   2 = critical drift (adapter claims conflict with constitution)

set -u

# Resolve paths from script location (kit-internal only).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CONSTITUTION="${KIT_ROOT}/docs/KIT-CONSTITUTION.md"
KIT_CLAUDE="${KIT_ROOT}/CLAUDE.md"
KIT_AUTHORING="${KIT_ROOT}/.claude/rules/kit-authoring.md"

WARN_COUNT=0
CRIT_COUNT=0

warn() {
    echo "[WARN] $*" >&2
    WARN_COUNT=$((WARN_COUNT + 1))
}

crit() {
    echo "[CRIT] $*" >&2
    CRIT_COUNT=$((CRIT_COUNT + 1))
}

info() {
    echo "[info] $*"
}

# --- Verify source files exist ---

for f in "$CONSTITUTION" "$KIT_CLAUDE" "$KIT_AUTHORING"; do
    if [ ! -r "$f" ]; then
        crit "missing required file: $f"
    fi
done

if [ $CRIT_COUNT -gt 0 ]; then
    echo "adapter-sync-lint: cannot proceed — source files missing." >&2
    exit 2
fi

info "Constitution: $CONSTITUTION"
info "Adapters: CLAUDE.md + kit-authoring.md"
echo ""

# --- Check 1: Stale authority phrases ---

info "Check 1: Stale authority phrase scan"
STALE_AUTHORITY='KIT-RED-LINES\.md is supreme authority'

for f in "$CONSTITUTION" "$KIT_CLAUDE" "$KIT_AUTHORING"; do
    if [ -r "$f" ] && grep -qE "$STALE_AUTHORITY" "$f"; then
        # Allow retired-references notes which CONTAIN the phrase as historical mention.
        if grep -E "$STALE_AUTHORITY" "$f" | grep -qiE 'retired|historical|deprecated|no longer'; then
            info "  $(basename "$f"): stale authority phrase present in retired-references note (OK)"
        else
            crit "  $(basename "$f"): stale authority phrase as live claim → $(grep -nE "$STALE_AUTHORITY" "$f" | head -1)"
        fi
    fi
done

echo ""

# --- Check 2: Stale naming/path references ---

info "Check 2: Stale naming / retired terminology scan"
STALE_TERMS='visual-build|visual-verify'

for f in "$CONSTITUTION" "$KIT_CLAUDE" "$KIT_AUTHORING"; do
    if [ -r "$f" ]; then
        hits=$(grep -cE "$STALE_TERMS" "$f" 2>/dev/null)
        hits=${hits:-0}
        if [ "$hits" -gt 0 ] 2>/dev/null; then
            warn "  $(basename "$f"): $hits stale-terminology hit(s) — review for live vs historical-example use"
            grep -nE "$STALE_TERMS" "$f" | head -3 | sed 's/^/    /'
        fi
    fi
done

echo ""

# --- Check 3: Token cap consistency ---

info "Check 3: Token cap consistency (constitution vs adapter)"

# Extract token-cap-related lines from constitution (Section 3 cap table).
# Adapter should not state cap numbers; if it does, they must match.

ADAPTER_CAPS=$(grep -oE '[0-9]{3,4} tok|≤ ?[0-9]{3,4}|cap [0-9]{3,4}' "$KIT_AUTHORING" "$KIT_CLAUDE" 2>/dev/null | sort -u || true)

if [ -n "$ADAPTER_CAPS" ]; then
    while IFS= read -r line; do
        # Extract just the number
        num=$(echo "$line" | grep -oE '[0-9]{3,4}' | head -1)
        # Search constitution for this number near "tok" / "cap"
        if grep -qE "${num} tok|tok.*${num}|cap.*${num}" "$CONSTITUTION" 2>/dev/null; then
            info "  '$line' — matches constitution cap table"
        else
            warn "  '$line' in adapter — not found in constitution cap table; possible drift"
        fi
    done <<< "$ADAPTER_CAPS"
else
    info "  No explicit cap numbers in adapter (good — adapter references constitution table)"
fi

echo ""

# --- Check 4: On-Grain form conformance (constitution v2; replaces REBAR 9-section check) ---

info "Check 4: On-Grain form — no structural === scaffolding in element bodies"

# Per Red Line 1 (On-Grain): markdown ## + XML, NOT === SECTION === delimiters, no end-of-body
# reinforcement bookend. A line-start ^=== is the real violation; the kit-element-auditor
# legitimately quotes === patterns INLINE as detection-vocabulary (not line-start), so it is exempt.

EQ_HITS=0
while IFS= read -r f; do
    [ -r "$f" ] || continue
    n=$(grep -cE '^=== ' "$f" 2>/dev/null || echo 0)
    n=${n:-0}
    if [ "$n" -gt 0 ] 2>/dev/null; then
        crit "  $(basename "$f"): $n structural '^=== ' delimiter(s) — On-Grain Red Line 1 forbids ===-section scaffolding"
        EQ_HITS=$((EQ_HITS + n))
    fi
done < <(find "${KIT_ROOT}/.claude/skills" "${KIT_ROOT}/.claude/agents" "${KIT_ROOT}/.claude/rules" "${KIT_ROOT}/.claude/output-styles" -name "*.md" 2>/dev/null; echo "${KIT_ROOT}/CLAUDE.md"; echo "$CONSTITUTION")
[ "$EQ_HITS" -eq 0 ] && info "  no structural '^=== ' delimiters in kit element bodies + kernel + constitution (On-Grain form OK)"

# Constitution must reference the On-Grain method (not the retired REBAR canonical-section mandate).
if grep -qF "ON-GRAIN-AUTHORING-METHOD.md" "$CONSTITUTION" 2>/dev/null; then
    info "  constitution references the On-Grain authoring method (OK)"
else
    crit "  constitution does not reference ON-GRAIN-AUTHORING-METHOD.md — stale/REBAR governance"
fi

# Adapter (kit-authoring) should itself be On-Grain (no === scaffolding in its body).
ADAPTER_EQ=$(grep -cE '^=== ' "$KIT_AUTHORING" 2>/dev/null || echo 0)
ADAPTER_EQ=${ADAPTER_EQ:-0}
if [ "$ADAPTER_EQ" -gt 0 ] 2>/dev/null; then
    crit "  kit-authoring.md carries $ADAPTER_EQ structural '^=== ' delimiter(s) — adapter not converged to On-Grain"
fi

echo ""

# --- Check 5: Pressure-state placement consistency ---

info "Check 5: Pressure-state singular placement"

# Per constitution: pressure-state axiom lives in the kernel adapter + verifier agent + designated routing element only.
# NOT in domain skills, NOT in adherence hook injection, NOT in non-routing/non-verifier agents.

# Find files with DEFINITIONAL pressure-state axiom (not just meta-mentions).
# Definitional phrasings: "second push = user investment" or "third push = stronger evidence".
# Meta-mentions like "three-push detail lives in X" do not match this — they are acknowledged references.
PRESSURE_FILES=()
while IFS= read -r f; do
    # Skip the lint script itself (self-reference)
    base=$(basename "$f")
    if [ "$base" = "adapter-sync-lint.sh" ]; then continue; fi
    if grep -qiE 'second push[^.]*user investment|third push[^.]*stronger evidence' "$f" 2>/dev/null; then
        PRESSURE_FILES+=("$f")
    fi
# Scope to the RUNTIME-loaded surface (elements + kernel + constitution), NOT docs/ reference
# material — the method doc / handoff / this lint legitimately DEFINE or DISCUSS the axiom and
# must not be mistaken for runtime carriers.
done < <(find "${KIT_ROOT}/.claude" \( -name "*.md" -o -name "*.sh" \) 2>/dev/null; echo "${KIT_CLAUDE}"; echo "${CONSTITUTION}")

# Check each is allowed
for f in "${PRESSURE_FILES[@]}"; do
    base=$(basename "$f")
    if echo "$base" | grep -qE '^CLAUDE\.md$|^tester\.md$|^KIT-CONSTITUTION\.md$'; then
        info "  $base: pressure-state present (allowed carrier — adapter / verifier / constitution)"
    elif echo "$f" | grep -qE '/scout/SKILL\.md$'; then
        info "  scout SKILL.md: pressure-state present (allowed carrier — routing element)"
    else
        crit "  $base: pressure-state axiom present outside singular-placement (kernel adapter + verifier + routing only)"
    fi
done

# Check hooks don't leak definitional three-push pattern.
if grep -rE 'second push[^.]*user investment|third push[^.]*stronger evidence' "${KIT_ROOT}/.claude/hooks/" 2>/dev/null >/dev/null; then
    crit "  hook script leaks pressure-state three-push detail (adherence hook layer must not carry)"
fi

echo ""

# --- Check 6: Hook output schema consistency ---

info "Check 6: Hook output schema (Anthropic-documented vs legacy)"

# Constitution + lib/json-helper.sh should use hookSpecificOutput.additionalContext
# Any remaining {"system_reminder": ...} pattern is legacy.

if grep -rE '"system_reminder"' "${KIT_ROOT}/.claude/hooks/" 2>/dev/null | grep -v 'compatibility\|legacy\|shim'; then
    warn "  legacy system_reminder schema referenced outside compatibility shim — verify hook output uses hookSpecificOutput.additionalContext"
fi

if ! grep -qE 'hookSpecificOutput.*additionalContext' "${KIT_ROOT}/.claude/hooks/lib/json-helper.sh" 2>/dev/null; then
    crit "  json-helper.sh missing hookSpecificOutput.additionalContext schema function"
fi

echo ""

# --- Check 7: Adapter projection contract phrasing ---

info "Check 7: Adapter projection contract phrasing"

# Adapters should explicitly reference constitution as source of truth.
for adapter in "$KIT_CLAUDE" "$KIT_AUTHORING"; do
    if grep -qE 'constitution|docs/KIT-CONSTITUTION\.md|KIT-CONSTITUTION' "$adapter" 2>/dev/null; then
        info "  $(basename "$adapter"): references constitution (OK)"
    else
        warn "  $(basename "$adapter"): no reference to constitution — adapter projection contract weak"
    fi
done

echo ""

# --- Check 8: Frontmatter description cap (catalog signal <=250 chars) ---

info "Check 8: Frontmatter description length (catalog signal cap 250 — scout greps ^description:)"

DESC_REPORT=$(python3 - "$KIT_ROOT" <<'PY'
import re, glob, os, sys
root = sys.argv[1]
files = glob.glob(os.path.join(root, ".claude", "skills", "*", "SKILL.md")) + glob.glob(os.path.join(root, ".claude", "agents", "*.md"))
over = 0
for f in sorted(files):
    t = open(f, encoding="utf-8").read()
    m = re.search(r'^description:\s*>?\s*(.*?)(?=^\w[\w-]*:\s)', t, re.S | re.M)
    d = " ".join(m.group(1).split()).strip('"').strip("'") if m else ""
    if len(d) > 250:
        print(f"OVER {len(d)} {os.path.relpath(f, root)}")
        over += 1
print(f"COUNT {over}")
PY
)
OVER_LIST=$(echo "$DESC_REPORT" | grep '^OVER' || true)
if [ -n "$OVER_LIST" ]; then
    while IFS= read -r line; do
        dn=$(echo "$line" | awk '{print $2}')
        dp=$(echo "$line" | awk '{print $3}')
        crit "  ${dp}: description ${dn} chars > 250 cap (HARD when disable-model-invocation, constitution Section 3) — bloats the routing catalog scout greps"
    done <<< "$OVER_LIST"
else
    info "  all element descriptions within the 250-char catalog cap"
fi

echo ""

# --- Check 9: doc-vs-disk element-count drift (current-state README vs live .claude/ inventory) ---

info "Check 9: doc-vs-disk element-count drift (README declared counts vs live inventory)"

# Check 9: doc-vs-disk drift. A current-state README element count that disagrees with the live
# .claude/ inventory fails the lint (CRITICAL), making doc-currency mechanically enforced. Only the
# README's declared "<N> skills|agents|hooks" layout counts are scanned — the canonical current-state
# declaration; prose mentions elsewhere are not.
README_DOC="${KIT_ROOT}/README.md"
N_SKILLS=$(find "${KIT_ROOT}/.claude/skills" -mindepth 2 -maxdepth 2 -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
N_AGENTS=$(find "${KIT_ROOT}/.claude/agents" -mindepth 1 -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
N_HOOKS=$(find "${KIT_ROOT}/.claude/hooks" -mindepth 1 -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
N_MCP=$(find "${KIT_ROOT}/.claude/mcp" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
info "  disk inventory: ${N_SKILLS} skills, ${N_AGENTS} agents, ${N_HOOKS} hooks, ${N_MCP} MCP"

DRIFT9=0
# Anchor on the README's canonical "live set is ..." inventory line (mirrors the constitution check
# below) — NOT a whole-README grep, which false-positives on legitimate launch-README content: a
# competitor-comparison count ("~250 skills, ~28 agents") or a rubric score ("8.88 agents") is not a
# claim about THIS kit. The "live set" line is the single mechanically-gated current-state declaration.
README_LIVE=$(grep -iE 'live set is' "$README_DOC" 2>/dev/null | head -1)
[ -z "$README_LIVE" ] && { warn "  README has no 'live set is ...' inventory line — element counts not mechanically gated"; DRIFT9=$((DRIFT9 + 1)); }
chk_count() {  # disk_count, element-word — extracts ONLY from the anchored README_LIVE line
    local disk="$1" word="$2" claimed
    [ -z "$README_LIVE" ] && return
    claimed=$(printf '%s' "$README_LIVE" | grep -oE "[0-9]+ ${word}" | grep -oE '^[0-9]+' | head -1)
    if [ -z "$claimed" ]; then
        warn "  README 'live set' line declares no '<N> ${word}' count"
        DRIFT9=$((DRIFT9 + 1)); return
    fi
    if [ "$claimed" != "$disk" ]; then
        crit "  doc-vs-disk drift: README 'live set' claims '${claimed} ${word}' but disk has ${disk} — update the README inventory line"
        DRIFT9=$((DRIFT9 + 1))
    fi
}
chk_count "$N_SKILLS" skills
chk_count "$N_AGENTS" agents
chk_count "$N_HOOKS" hooks

# Constitution current-state count-claim (the Section-3 "live set" catalog note) vs disk — closes the
# constitution-prose count-drift an external review flagged TWICE (Check 9 previously gated only the
# README). Anchored on the "live set" phrasing so the HISTORICAL amendment-log counts (e.g. v4
# "4 skills + 2 agents", v5 "12 skills + 10 agents") are NOT false-positived — only the current-state
# declaration is gated. Same string-compare logic as the proven README chk_count above.
CONST_LIVE=$(grep -iE 'live set is' "$CONSTITUTION" 2>/dev/null | head -1)
if [ -n "$CONST_LIVE" ]; then
    cs=$(printf '%s' "$CONST_LIVE" | grep -oE '[0-9]+ skills' | grep -oE '^[0-9]+' | head -1)
    ca=$(printf '%s' "$CONST_LIVE" | grep -oE '[0-9]+ agents' | grep -oE '^[0-9]+' | head -1)
    ch=$(printf '%s' "$CONST_LIVE" | grep -oE '[0-9]+ hooks' | grep -oE '^[0-9]+' | head -1)
    [ -n "$cs" ] && [ "$cs" != "$N_SKILLS" ] && { crit "  constitution 'live set' claims ${cs} skills but disk has ${N_SKILLS} — update the Section-3 catalog note"; DRIFT9=$((DRIFT9 + 1)); }
    [ -n "$ca" ] && [ "$ca" != "$N_AGENTS" ] && { crit "  constitution 'live set' claims ${ca} agents but disk has ${N_AGENTS} — update the Section-3 catalog note"; DRIFT9=$((DRIFT9 + 1)); }
    [ -n "$ch" ] && [ "$ch" != "$N_HOOKS" ] && { crit "  constitution 'live set' claims ${ch} hooks but disk has ${N_HOOKS} — update the Section-3 catalog note"; DRIFT9=$((DRIFT9 + 1)); }
else
    warn "  constitution carries no 'live set' current-state count note — Section-3 catalog currency not mechanically gated"
fi

[ "$DRIFT9" -eq 0 ] && info "  README + constitution 'live set' counts match disk (${N_SKILLS} skills / ${N_AGENTS} agents / ${N_HOOKS} hooks) — no doc-vs-disk drift"

echo ""

# --- Summary ---

echo "=== ADAPTER SYNC LINT SUMMARY ==="
echo "CRITICAL drift: $CRIT_COUNT"
echo "WARNING drift:  $WARN_COUNT"

if [ $CRIT_COUNT -gt 0 ]; then
    echo "Status: CRITICAL drift — adapters claim things that conflict with constitution. Resolve before relying on constitution as source of truth."
    exit 2
elif [ $WARN_COUNT -gt 0 ]; then
    echo "Status: WARNINGS — informational drift; review and decide whether constitution amendment or adapter fix is needed."
    exit 1
else
    echo "Status: clean — no detectable drift between constitution and adapters."
    exit 0
fi
