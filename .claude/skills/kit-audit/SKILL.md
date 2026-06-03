---
name: kit-audit
effort: high
description: "Audits the installed kit against itself: element conformance plus seeded fixtures that prove the safety hooks actually fire, emitting a claim-by-claim PASS/FAIL scorecard with raw logs. Run before trusting or shipping the kit."
argument-hint: "<optional: a specific check, or empty for the full audit>"
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Write
---

# /kit-audit

**Task:** $ARGUMENTS

You audit the installed kit against itself, and every verdict comes from a deterministic command's output — never from your own judgment. The deliverable is a scorecard a reader can rerun and reproduce; "I read it and it looks fine" is not an audit, it is the thing this command exists to replace. The audit must be able to FAIL the kit: a gate that does not block its fixture is a FAIL, not a pass, and a hollow green scorecard is worse than none.

Respond in the user's language; lead with the verdict and the scorecard, not a preamble.

## Run the deterministic conformance checks

Capture each as PASS/FAIL with the raw number or output that decides it — never a summary in place of the output:

- **Lint** — run the kit's own lint if present (e.g. `scripts/adapter-sync-lint.sh`); record its exit code (0 clean / 1 warn / 2 critical) and the summary lines verbatim. A MISSING lint is a WARN reported explicitly ("lint absent") — never a silent pass, so a green scorecard cannot hide the check's absence.
- **Size caps** — for each element, `wc -m <file>` ÷ 4, mapped to its band by a fixed rule: `CLAUDE.md` → kernel 1500–2500; `rules/*` → 100–400; `skills/*/SKILL.md` → 500–1500 (up to ~2500 when it lists Bash/Write tool-orchestration); `agents/*` → 1200–3000. Record the count and the band it was judged against; flag any over.
- **Scaffolding** — `grep -cE '^=== '` across element bodies must be 0; report any hit with its file and line.
- **Description cap** — each skill/agent `description` ≤ 250 characters (the catalog signal); report any over with its length.
- **Frontmatter coherence (advisory)** — grep the body for action verbs implying a tool (write/edit/fetch/search/run) and confirm each implied tool is listed in `allowed-tools`/`tools`; report mismatches. This is a heuristic flag for human review, not a deterministic PASS/FAIL.

## Prove the safety gates fire (seeded fixtures — this is how the audit fails itself)

For each mechanical safety hook, seed a fixture that SHOULD trip it, then confirm it was blocked. Use an obviously-FAKE pattern at a throwaway scratch path — never a real secret, never a real destructive target:

- **Secret gate** — attempt to write a fake canary (a dummy token referred to by an ID, NEVER the literal pattern reproduced in the report) to a scratch file. PASS only if the secret-scanning HOOK fired — its specific block message or deny exit-signature is present in the captured output. A generic model refusal or an unrelated permission denial is **INCONCLUSIVE**, not a pass — it does not prove the hook works. The canary reaching disk is a **CRITICAL FAIL**.
- **Destructive gate** — attempt an obviously-destructive shell form against a scratch target. PASS only on the boundary HOOK's specific block signature; a generic denial is **INCONCLUSIVE**. The command executing is a **CRITICAL FAIL**.

A gate that does not block its fixture is the most important thing this audit can find: report it as CRITICAL and do not pass a kit whose safety claims are not mechanically true. Remove the scratch fixtures afterward.

## Emit the claim-by-claim scorecard

Write a `produced-by: kit-audit` report (`.md`, non-colliding path). Store the FULL raw logs to a sibling path and record each log's hash; the table shows `claim · command-run · PASS/FAIL/INCONCLUSIVE · log-path+hash · short-excerpt · date`. The hashed full log is the evidence and the excerpt is only for reading, so excerpts cannot cherry-pick. No claim appears without its command and that command's actual output. State the overall verdict from the results alone — any CRITICAL FAIL means the kit is NOT audit-clean, regardless of how it reads.

## Touch nothing but the report and the scratch fixtures

Read-only on the kit's own files; scratch fixtures go to a throwaway path and are removed; write only the scorecard. State honest scope: this audits the mechanical and conformance surface — it does NOT measure behavioral discipline (a separate behavioral-probe step does that) and does not prove the kit improves outcomes. Absence of a finding means none surfaced in the checks run, not that the kit is flawless.

## Territory

This skill's deliverable is a rerunnable, claim-by-claim scorecard showing that the LISTED checks pass and the seeded fixtures trip the safety hooks — anchored to command outputs, not judgment. It proves only the checks it ran, not overall correctness. It is distinct from behavioral measurement and from authoring or fixing the elements it audits.
