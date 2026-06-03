---
name: jit-ref
effort: low
description: "Pins a thin, version-locked, dated reference for one niche or post-cutoff API surface the model gets wrong — discardable, re-verify-dated. Use when work leans on a specific proprietary or recent API, not for surfaces the model already knows."
argument-hint: "<the API / library / surface to pin>"
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
  - AskUserQuestion
---

# /jit-ref

**Task:** $ARGUMENTS

You pin a thin, dated, version-locked reference for the one niche, post-cutoff, or proprietary API surface the model demonstrably gets wrong — never a dump of documentation the model already holds. A broad doc dump is stale-doc theater: it rots faster than it helps, costs context on every read, and quietly drifts out of date. The deliverable is a small, sourced, dated note for exactly the surface the work touches.

Respond in the user's language; lead with the pinned reference and its date, not a preamble.

## Confirm the model actually gets it wrong first

Before pinning anything, name the specific error the model makes on this surface — a hallucinated signature, a wrong default, a renamed method, a breaking change it has not seen — and record that error as the reason to pin. If you cannot name a concrete error, the surface is one the model already knows: say so and pin nothing. A reference for a known surface is pure liability — added load plus a second source of truth that can disagree with the model's correct knowledge.

## Pin from the authoritative source, with a version and a date

Fetch the current surface from its canonical source — official docs, the changelog, the release notes, or the source itself — never from memory and never from a random blog. Pin the exact version the project uses and cite the precise location: a docs URL plus section, a release-note URL plus version, or a repo tag/commit plus file path, stamped `Captured: YYYY-MM-DD`. Never pin a floating "latest" when the version is unknown — pin the version in use or pin nothing. Put the version, the capture date, and the re-verify horizon at the top of the reference so a later reader sees at a glance when to distrust it. When the source cannot be reached or the surface cannot be verified, say so plainly and do not fabricate the API; re-verification is a fresh source check with a fresh date, not a carry-forward of the old pin.

## Keep it thin and discardable

Capture only what the work uses — the specific signatures, the gotchas, the breaking-change deltas from what the model assumes — not the whole manual. Set a re-verify-by horizon at the earliest of the next dependency upgrade, the next time this surface is touched, or ~90 days from capture (shorter for beta or preview APIs). Treat the file as disposable scaffolding for this project, not permanent kit weight; when the dependency is dropped or upgraded, the reference goes with it.

## Territory

This skill's deliverable is a thin, version-pinned, dated, sourced reference for one niche surface the model gets wrong — disposable, scoped to the project's actual use. It authors no general documentation the model already holds, guarantees no currency past its stated date, and replaces no real verification of the code that uses the surface.
