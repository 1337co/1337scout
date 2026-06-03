# Security Policy

## Supported versions
1337scout ships on npm (`npx 1337scout`) and is developed on GitHub. Only the latest published version (currently the `0.1.x` line) receives security fixes. Pin for reproducible installs: `npx 1337scout@0.1.2`.

## Reporting a vulnerability
Report security issues **privately** — please do not open a public issue for a vulnerability.

- Preferred: this repository → **Security → Report a vulnerability** (a private GitHub advisory).

The most useful reports describe a concrete way to defeat a guarantee the kit *does* make, for example:
- a way to get a destructive command or a secret-write past the `PreToolUse` hooks (`boundary-guard`, `secret-scanner`) so it reaches execution;
- a destructive / exfil command **shape** the matchers miss (a genuine new bypass class);
- a way to make a read-only verifier agent rubber-stamp unsafe work;
- a supply-chain issue in the `npx` installer or the published package.

Please include a minimal reproduction and the affected version. We aim to acknowledge within a few days.

## Scope & threat model (honest)
1337scout is a **discipline + safety-floor kit, not a complete sandbox** — be precise about what it does and does not defend:

- The two `PreToolUse` hooks block a defined set of destructive commands and secret-write patterns **before** they run, fail-CLOSED, verified by `bash scripts/mechanical-regression.sh` (24/24 seeded defects caught, 0 false positives on 10 benign).
- They are **one layer of three** (a permission deny/ask list + the two hooks), explicitly **not** a sandbox or an absolute guarantee. The hooks document their own residual gaps in-file (e.g. encoded secrets, sudo-wrapped device writes).
- The kit makes **no network requests at runtime** except the Anthropic API (via Claude Code). `npx 1337scout` fetches the package from the npm registry at install time only.

## What is *not* a vulnerability
- The honest behavioral limits stated in the README (the prose-discipline layer's edge being small on moderate prompts) are documented design facts, not security issues.
- A defeat that requires access the kit never claimed to contain (e.g. an attacker who already controls the shell or the environment) is out of scope.
