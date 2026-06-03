---
name: debug
effort: medium
description: "Use when a bug needs diagnosis — finds the ROOT CAUSE before fixing, via reproduce-first + one-hypothesis-at-a-time + a stop-thrashing gate (3 failed fixes = the approach is wrong). Not for implementing new work or planning."
argument-hint: "<the bug / failing behavior>"
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

# /debug

**Task:** $ARGUMENTS

You find the ROOT CAUSE before applying a fix — debugging is hypothesis-driven, not guess-and-check (temporary logging, probes, and inspection code to FIND the cause are fine; a fix to the real code is what waits for the cause). A fix applied before the cause is understood is a guess: if it works you don't know why, and if it doesn't you have added a variable instead of removing one. The deliverable is the identified cause plus the minimal fix that addresses it, with the failure reproduced before and verified gone after.

Respond in the user's language; lead with the cause and its evidence, not a preamble.

## Reproduce first

Get a reliable, minimal reproduction before forming any hypothesis — the exact input, state, and steps that trigger the failure, and the precise observed-versus-expected. A bug you cannot reproduce, you cannot verify you fixed. If it will not reproduce, that IS the first finding (flaky / environment / timing / data-dependent) — investigate the non-reproduction, do not guess at a fix.

## One hypothesis at a time

State a single specific hypothesis for the cause, predict what you would observe if it is true, and run the smallest check that confirms or kills it. Read the actual error, trace, and state — do not pattern-match to a familiar-looking fix. Trace the failure to its ORIGIN (where the wrong value or state first appears), not the symptom site where it surfaces. Confirm the cause with evidence before touching a fix.

## Stop thrashing — the counter-gate

This is a tripwire, not a quota — it does not license three attempts before thinking. If three attempted fixes have nonetheless failed, STOP fixing and return to reproduction, evidence, and a fresh hypothesis: the approach or the mental model is wrong, not the next fix. Re-question the assumption, the architecture, or whether you are even debugging the right layer. Never bundle several speculative changes at once — that hides which one mattered; change one thing, observe, then the next. Remove temporary probes and logging when done, or justify any you keep.

## Fix the cause, verify the fix

Apply the minimal change that addresses the identified root cause, not the symptom. Verify by re-running the reproduction: it failed before, it passes now — that delta is the proof, not your confidence. Check the fix did not break an adjacent path. Name what you verified and what you did not.

## Territory

This skill's deliverable is an identified root cause plus a minimal cause-addressing fix, with the failure reproduced before and verified gone after. It is distinct from implementing new work, from planning, and from adversarial verification of a finished change.
