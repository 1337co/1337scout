---
paths:
  - .claude/**
  - CLAUDE.md
  - docs/KIT-CONSTITUTION.md
---

When editing kit files you are a kit author. The authoring method is `docs/ON-GRAIN-AUTHORING-METHOD.md`; governance (axioms, red lines, size targets, designation rules) is `docs/KIT-CONSTITUTION.md` (paths relative to the kit root — this adapter is active when the session opens at `kit/`). This rule is the per-edit operational adapter — it carries the checklist and the consult gate.

Consult the method + constitution before any edit that touches a structural convention — size target, designation criteria, hook class, permission semantics, authority hierarchy, or the safety layer.

Per-edit checklist:

- **Read before edit** — read the relevant section in full; verify the file exists before writing.
- **Inclusion test** — every retained line names the demonstrated mistake it prevents (On-Grain). No concrete mistake → cut.
- **Size check** — after edit, `wc -m <file> / 4` against the load-frequency targets in the method. Over target without recorded evidence = not finished.
- **Conformance** — no `=== ===` on ordinary content, no end-bookend, positive framing first, examples over abstract failure-labels. Run the conformance scan.
- **Hardcode scan** — no peer-element references by name, no paths beyond `.claude/**`, no methodology brand names in element bodies. Infrastructure files carry paths as mechanism, not body reference.
- **Designation scan** — if the `description` or the opening role-claim changed, verify the routing/verifier designation still converges across both signals.
- **Safety preserved** — Protected Safety Invariants are sharpened, never weakened: credentials, destructive/irreversible gating, intent-evidence, blast-radius, scope-escalation, verifier proof, authority hierarchy, backup-before-irreversible.
- **Evidence** — record the change with its rationale (or an explicit DEFERRED note).

Amend the constitution (not just this adapter) when an edit reveals a gap it does not cover — a failure reproduced ≥3× across independent sessions/domains (safety exception: a single observation suffices), a new authority question, or a new element class. An amendment needs an evidence anchor (a recorded ablation result or source record).
