# On-Grain Authoring — the kit's authoring method

Read before creating or editing any kit element. Models its own rules: lean, positive, concrete, markdown headers, no `=== ===`, no end-bookend.

## The principle
Write the smallest instruction that prevents a demonstrated mistake at the surface where it actually happens.

Default behavior is assumed competent in short, clean contexts — empirically: clean Opus 4.8 corrects false premises, guards destructive scope under urgency, and held correct positions under authority pressure and true multi-turn 3-push in our probes. Kit intervention is justified only at a MEASURED decay surface or a high-blast-radius safety boundary. Anthropic trains by "a minimal set of well-understood rules + judgment," and warns unexplained constraints make the model generalize to a worse self-model — so the kit anchors, it does not re-teach.

Calibration (honest): "did not decay" = NOT OBSERVED to decay in our current Opus-4.8 probes (short-context, limited conditions). Re-measure on model/version/context change. The real Claude Code environment (tool errors, stale files, mixed CLAUDE.md, long context, partial edits, sustained real pressure) can break defaults in ways short clean probes do not show.

## Inclusion test (every line)
"If I remove this, what demonstrated mistake does Claude make, at which surface?" No concrete answer → cut. Earns its place by preventing an observed failure, not a hypothetical one. Exception: rare-but-high-cost safety failures may be anchored preventively (see Protected Safety Invariants).

## Decay surfaces — anchor ONLY here
- long context (deep in a large window)
- accumulated pushback across many real turns
- high-blast-radius / destructive / irreversible actions
- genuinely ambiguous high-stakes scope
- tool-failure loops and error recovery
- stale cross-session memory drift
- verifier / closure moments (claiming done)
- cross-tool handoff (Read→Edit→Bash intent/context drift)
- evaluator capture (model rates its own bad output as good — observed in visual-design generation)
- output-modality mismatch (text spec good, rendered/executed artifact bad)
- authority-layer conflict (user-global / workspace / kit / skill disagree at once)
- model-upgrade drift (today's default ≠ next model's)
- reference ambiguity (domain/design references misinterpreted)

Not anchor surfaces (per probes): single-turn pressure, authority/consensus framing, urgency, 3-push pressure — defaults held. The long-context / tool-loop / stale-memory / cross-tool / modality surfaces are not yet measured → measure before anchoring.

## Form
- Mode-match the form to cognitive load: atomic rule → one line; judgment call → short prose + the reason; complex classifier/verifier → structured + detailed. No universal skeleton.
- Markdown `##` headers + XML tags (`<example>`, data). Reserve a hard-boundary fence only for a genuine read-only/destructive constraint. No `=== SECTION ===` on ordinary content.
- State each rule once. No reinforcement bookends.
- Keep bodies lean: heavy bodies leak shape into output, and large/complex system prompts make Opus 4.8 over-think (official Opus-4.8 prompt-eng doc; the doc also states 4.8 needs less FRONTEND-design prompting + follows more literally — generalizing "less scaffolding" beyond frontend is our probe-supported inference, not a blanket Anthropic claim).

## Framing
- Positive target first: "do X." Add "don't Y" only for a real repeated failure, paired with a concrete reason + concrete alternative (official doc: "tell Claude what to do, not what not to do").
- Examples over labels: 1 good + 1 bad concrete example beats an abstract "(counter: X)". Use 1–3 examples. (BUT cap example count — examples can bloat; see failure modes.)
- Reserve NEVER/IMPORTANT for hard safety, tool-routing, or a hard output requirement.

## Evidence routing (quality that depends on domain taste)
If desired quality depends on taste or external correctness, do NOT add behavioral rules — bind it to reality: load the relevant reference/spec, ask when it is missing, and verify with the surviving observable for that domain — tests for code, reproduced probes for claims, @tester for adversarial verification, or user/external review for taste-bound artifacts outside kit scope. If no observable exists in the kit, mark the claim unverified rather than manufacture confidence. A behavioral rule cannot install taste.

## Protected Safety Invariants (NEVER cut during a lean rewrite — only sharpen)
These are anchored preventively (high-cost, sometimes rare) and survive every converge:
- credentials/secrets handling
- destructive / irreversible operations gating
- intent-evidence gate
- blast-radius gate
- scope-escalation gate
- verifier PASS/FAIL + observable-proof discipline
- user-authority hierarchy
- backup/restore before irreversible edits
A converge may rewrite these leaner/clearer; it may never weaken or remove them. Safety anchoring may be heavier than taste/productivity anchoring.

## Pressure-state axiom (preserve, narrow)
First push → cheap re-observe against original evidence. Third push → pressure-state classification (stronger evidence position is correct). Lives ONLY in the kit + workspace CLAUDE.md, verifier agents, and the routing element — never in a generic domain skill.

## Add or edit an element
1. Observe an actual failure (not hypothetical).
2. Locate the surface (which decay surface / safety boundary).
3. Choose the smallest element: a line < a rule < a new skill/agent.
4. Write the minimal instruction in these form/framing rules.
5. Test against a before/after prompt on the real task; capture the observable.
6. Record in the Evidence Backlog.

## Evidence Backlog schema (per anchored rule)
`observed-failure | surface | prompt/task | before-behavior | after-behavior | date+model | recurrence-count | action: add/keep/cut/watch`. The backlog replaces abstract failure-pattern inventory expansion. "watch" = suspected but not yet recurrent/high-cost.

## Size targets (by LOAD-FREQUENCY + complexity; calibration start, tune empirically)
| Element | Target |
|---|---|
| Always-loaded kernel (CLAUDE.md) | 1500–2500 tok (hard pressure) |
| Auto-loaded rule | 100–400 tok |
| User-invoked ordinary skill | 500–1500 tok |
| Tool-workflow skill | up to 2500 tok |
| Verifier agent | 1200–3000 tok |
| Complex verifier harness | 3000+ ONLY if lazy-loaded |
| Hook PROSE injection | near-zero |
| Mechanical hook CODE | no prose cap; latency cap |
Skill >2000 needs recorded evidence — but don't force-cut a genuinely complex skill. Mechanical hooks (validators/enforcement) are a separate category from prose injection; don't lean them as if they were prose.

## Conformance audit (periodic)
Scan for: over-length vs target, duplication/restatement, negative:positive ratio, `=== ===`, end-bookends, abstract failure-labels, unsupported claims, stale references, examples present (and not bloated), observable verification on completion. Automate mechanical parts via the kit's lint script (`scripts/adapter-sync-lint.sh`). Audit-subjectivity risk: the removal test can be gamed → require a named observed failure + surface in the backlog, not a verbal justification.

## Failure modes of this method (watch + mitigate)
- Under-specification → trusting default, missing a project-specific invariant. Mitigation: evidence backlog + the invariant-recurrence exception.
- Evidence bottleneck → rare/high-cost failures never get a preventive rule. Mitigation: rare+high-cost exception (Protected Invariants).
- Regression by model update → today's robust default differs next model. Mitigation: a regression probe suite, re-run on upgrade.
- Safety-trimming accident → "lean" zeal weakens a boundary. Mitigation: Protected Safety Invariants list.
- Examples bloat → cutting abstract labels balloons examples. Mitigation: 1–3 example cap.
- Silent taste default → visual/writing tasks fall back to vanilla taste. Accepted, not mitigated: taste is out of kit scope (Axiom 3 corollary) — the kit disciplines process, not taste.

## When heavier scaffolding IS justified
Credential/destructive ops · verifier agents (PASS/FAIL) · security-review/incident-response · multi-step tool workflows with known parser/hook failure · a project-specific invariant Claude repeatedly violates · legal/financial/medical risk. NOT for: visual taste, writing style, ordinary coding discipline, "be careful" reminders, anti-slop inventories, generic anti-sycophancy restatements.
