---
name: tdd
effort: medium
description: "Use when implementing test-first (opt-in methodology) — drives code with a failing test written and WATCHED failing first, then minimal green, then refactor. Not for after-the-fact verification, or when test-after fits the work better."
argument-hint: "<the behavior to build test-first>"
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

# /tdd

**Task:** $ARGUMENTS

When this skill is chosen, you drive the implementation with a failing test written FIRST: no new production behavior exists until a test demands it and you have watched that test fail for the right reason. A test written after the code, or never watched failing, proves little — it may pass for the wrong reason, or exercise nothing. This is an opt-in methodology: when test-after genuinely fits the work better, say so and use it — do not force the ceremony where it does not earn its place. Poor fits — UI-only polish, exploratory spikes, generated assets, trivial config, or a hard-to-test integration seam — are better implemented directly and verified after, not forced into a red → green cycle.

Respond in the user's language; lead with the test and its observed failure, not a preamble.

## Write the test first, watch it fail

For each behavior, write the smallest test that specifies it before the implementation exists. Run it and WATCH IT FAIL — read the failure and confirm it fails for the RIGHT reason (the behavior is genuinely missing), not a wrong one (a typo, an import error, a misconfigured harness). A test you have not watched fail is not yet evidence; the watched failure is what proves the test actually exercises the behavior you think it does.

## Minimal green

Write the smallest implementation that makes the failing test pass — no more. Run it and watch it pass. Resist building beyond what the current test demands; the next behavior earns its own test first. Speculative code with no test driving it is exactly what this discipline exists to prevent.

## Refactor on green

With the test green, improve the structure if it needs it — and re-run the test after each change to stay green. Refactor only while green; never refactor and add new behavior in the same step, or you cannot tell which one broke it.

## Stay honest about the loop

Each behavior is one red → green → refactor cycle. If you wrote code before its test, or never watched a test fail, the cycle was not followed — say so plainly rather than relabel test-after work as TDD. Report which behaviors were genuinely test-driven and which were not.

## Territory

This skill's deliverable is implementation driven by tests written-and-watched-failing first, each behavior a red → green → refactor cycle with the failure observed before the pass. It is an opt-in methodology, distinct from after-the-fact verification, from planning, and from general implementation.
