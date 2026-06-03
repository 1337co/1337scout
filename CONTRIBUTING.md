# Contributing to 1337scout

Thanks for considering a contribution. This kit is deliberately small and disciplined — contributions are held to the same bar as the kit itself.

## Principles (the bar)
- **Inclusion test** — every line you add must name the demonstrated mistake it prevents, at the surface where it happens. No "be careful" reminders, no hypothetical rules. If you can't name the failure, it doesn't go in. (See `docs/ON-GRAIN-AUTHORING-METHOD.md`.)
- **Safety is sharpen-only** — the credential / destructive-action / intent-evidence / scope gates may be made clearer or stronger, never weakened or removed. (See `docs/KIT-CONSTITUTION.md` → Protected Safety Invariants.)
- **Mechanism over prose for safety-critical rules** — if a rule can be enforced by a hook/validator, prefer that over advisory text.
- **Lean** — respect the per-element size targets in the authoring method. Over target needs recorded evidence.
- **Honest** — if a change can't be verified, say so (a GAP); don't claim done. Every claim must be reproducible.

## How to propose a change
1. Open an issue describing the **demonstrated** failure your change prevents (with a reproduction if possible) — use the "Element / change proposal" template.
2. For a new element, work through the Element Addition Test in `docs/KIT-CONSTITUTION.md`.
3. Run `bash scripts/adapter-sync-lint.sh` — it must exit 0.
4. If you touch a hook or the shared pattern library, run `bash scripts/mechanical-regression.sh` — it must pass (**24/24** caught, **0** false positives on 10 benign).
5. Keep the diff scoped; document the "why" in the PR (the PR template carries the checklist).

## What gets declined
Capability/feature additions that turn the kit into a tool library, anything that weakens a safety invariant, unenforceable "discipline" prose with no named failure, or boilerplate copied from elsewhere.

## Security
Found a way to bypass a safety hook? Report it **privately** — see [`SECURITY.md`](SECURITY.md), not a public issue.

By contributing you agree your work is licensed under the repository's MIT license.
