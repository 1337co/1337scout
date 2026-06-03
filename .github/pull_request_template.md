## What this changes

<!-- One or two sentences. Link the issue if there is one. -->

## The mistake it prevents

<!-- Per the kit's inclusion test: name the demonstrated failure this addresses. -->

## Checklist
- [ ] I read `docs/KIT-CONSTITUTION.md` and `CONTRIBUTING.md`.
- [ ] `bash scripts/adapter-sync-lint.sh` exits 0.
- [ ] `bash scripts/mechanical-regression.sh` passes (24/24, 0 FP) — if I touched a hook or the shared pattern library.
- [ ] No safety invariant is weakened (sharpen-only).
- [ ] Every added line names the failure it prevents; no "be careful" prose.
- [ ] No secrets; no hardcoded paths beyond the Claude Code surface; no competitor names.
- [ ] Every claim is reproducible, or marked as a GAP.
