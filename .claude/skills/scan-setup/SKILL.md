---
name: scan-setup
effort: low
description: "Use when wiring a repo to maintained DETERMINISTIC scanner gates (SAST, dependency-CVE/SBOM, secret-history, IaC/container, mutation, fuzz) that produce ground-truth observables — vendored and run, never LLM-cloned. Not for authoring a reviewer."
argument-hint: "<optional: the risk surface — security / supply-chain / test-strength>"
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebFetch
  - WebSearch
---

# /scan-setup

**Task:** $ARGUMENTS

You stand up real verification by wiring maintained, off-the-shelf deterministic scanners to the project — you do not author a scanner, and you do not write an LLM "reviewer" that re-decides a check a maintained tool already runs. A scanner with a provenanced, continually-updated ruleset beats the model re-deriving the same rule each run; the kit's value is the discipline that routes to the real tool and consumes its output, not a hand-rolled clone. Recommend only the scanners the project's stack actually needs, each producing a machine-readable observable a later judgment step can trust.

Respond in the user's language; lead with the recommended scanners and why each earns its place, not a preamble.

## Detect the real stack first

Read the repo before recommending anything: languages and package managers (package.json plus lockfile, requirements/pyproject, go.mod, Cargo.toml, pom/gradle), the test framework and any coverage already wired, the CI config, container and IaC files (Dockerfile, compose, Terraform, Kubernetes manifests), and whether the code is native or unsafe (C/C++, unsafe Rust) or a managed runtime. Recommend a scanner only for a surface the stack actually has — an unrun scanner is config the project maintains and never gains from.

## Map each risk surface to one maintained scanner

For each surface the stack presents, pick the actively-maintained tool and emit its run command, not a description of what it would find:

- Type errors, undefined names, signature mismatches (the most common LLM-codegen defect — the bulk of compile errors are type failures) → the stack's type-checker in check-only mode (`tsc --noEmit`, `mypy` or `pyright`, `go build` + `go vet`, `cargo check`), a cheap exhaustive ground-truth gate run AHEAD of the behavioral tests. Route to the checker; never LLM-reason the types.
- Untrusted-input-to-dangerous-sink, injection, unsafe API use → a maintained SAST engine (Semgrep, or CodeQL where the language is supported), emitting SARIF so each finding carries a location and a rule id.
- Known-vulnerable dependencies → the stack's advisory scanner (OSV-Scanner, Trivy, Grype, `npm audit`, `pip-audit`, or an ecosystem-native one where it is stronger, such as Go `govulncheck` with its reachability filter): a lookup against CVE/OSV/GHSA feeds, not a judgment call.
- Dependency inventory and license exposure → an SBOM generator (Syft or Trivy, emitting SPDX or CycloneDX).
- Infrastructure-as-code, container image, and config misconfiguration → a maintained config/image scanner (Trivy for images and IaC, Checkov for Terraform/CloudFormation/Kubernetes, hadolint for a Dockerfile): the vendor path for these formats, never an LLM reviewer that re-decides a linter's published rules.
- Secrets already committed to history → a history scanner (gitleaks, trufflehog), distinct from a write-time secret block that sees only new writes, not what is already in the tree.
- Whether the test suite actually catches regressions → a mutation runner (Stryker for JS/TS, mutmut for Python, cargo-mutants for Rust, PIT for Java): a kill-rate is the ground truth that line coverage only approximates.
- Memory and undefined-behavior bugs on native code → an actively-developed fuzzer with sanitizers (AFL++, or ClusterFuzzLite to run it in CI, with ASan/UBSan; libFuzzer still works but is in maintenance-only mode), when the stack is C/C++ or unsafe Rust.

When two tools cover one surface, pick the maintained or canonical one and say why. Record each tool's name and the date checked — maintenance and rulesets shift, so the recommendation is dated, not permanent.

## Vendor, never re-implement

When a maintained scanner already covers a surface, run it — do not author an element that re-implements its check in prose, and do not have the model eyeball what a tool reports deterministically. The model's role is to consume the scanner's output and judge reachability, real severity, and the false positives the tool cannot rule out; being the scanner is not its role. A prose re-implementation of a solved deterministic check adds load and drifts from the tool's updated ruleset.

## Wire it as a gate, pin it, hand off the run

Write the run command, the path its output lands at (the SARIF / JSON / SBOM file), and the pre-commit or CI step that runs it on change into the project's config — creating or merging the workflow or pre-commit file — so the observable is produced automatically rather than from memory. Pin the scanner version, and express any required token as an environment reference, never an inlined value. Installing the tool, granting it auth, and running it in CI are the user's actions — you produce the recipe and write the config; you do not install or execute a network-fetching install step yourself.

## Territory

This skill's deliverable is a stack-matched setup for maintained deterministic scanners plus the run-and-gate config — pointing at real verification tooling under the kit's discipline. It authors no scanner and writes no LLM reviewer. Running the tools, holding their tokens, and acting on the findings belong to the user and the verification step; judging whether a finding is reachable in context is a separate step, not this skill's job.
