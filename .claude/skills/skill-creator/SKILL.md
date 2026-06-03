---
name: skill-creator
effort: high
description: "Authors one new kit skill — researched, justified by a demonstrated mistake, size-capped, with coherent frontmatter and lean positive-first prose. Invoke to create a skill; not for a surface the model already handles."
argument-hint: "<the skill to create: the recurring mistake it should prevent>"
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

# /skill-creator

**Task:** $ARGUMENTS

You author one new kit skill — grounded in real research, shaped to the kit's authoring discipline, sized to its load band — that earns its place by preventing a demonstrated mistake. A skill written to "be better at X" with no named failure is a trap: it adds load, leaks its shape into the model's output, and the model was already competent at X. The deliverable is one new skill file written to satisfy the kit's inclusion test (pending independent audit), or a clear "this needs no skill" when it does not.

Respond in the user's language; lead with the skill or the no-skill verdict, not a preamble.

## Name the demonstrated mistake first

State the specific recurring mistake the skill prevents and the surface where it happens — a real failure you can point to, not a hypothetical "would be nice." If you cannot name a concrete failure, say so and author nothing: the model is competent by default in short, clean contexts, and a skill for a surface it already handles is pure liability — added load plus a second source of truth that can disagree with correct knowledge. A skill earns its place at a measured failure surface or a high-blast-radius boundary, not by how popular its topic is. A bare topic, a desired improvement, or a generic "make me better at X" — with no observable recurring failure and no high-blast-radius boundary behind it — is not enough; author nothing until one is supplied. Glob and grep the existing skills first and read a nearby one for the house style: confirm none already covers this need and the name does not collide. When the need is plausible but underspecified, ask for the specific failure rather than guess.

## Vendor before you author

Check whether the capability already exists as a maintained tool or a first-party skill. Most capability the model already has; where a maintained external tool, library, or official skill already does the job, vendor or align it under the kit's discipline rather than re-author the capability as a new skill. Author a new skill only for a discipline or process gap — a demonstrated behavioral failure at a real surface — not to re-own a capability the ecosystem already maintains.

## Research the domain before writing

When the skill's value depends on domain facts, current APIs, or real failure modes, fetch them now from the authoritative source — official docs, the changelog, the spec, high-signal real usage — not training-prior memory. Cite what you rely on with its version and date, and keep source-derived facts separate from your own authoring judgment. A skill authored from assumption ships stale or hallucinated guidance; one grounded in a fetched, dated source survives contact with the real task. When the domain is one the model already knows cold, skip the research and say so rather than manufacture a citation.

## Write lean: positive target, smallest instruction, concrete over abstract

- Lead each rule with the positive target ("do X"); add a "don't Y" only for a real repeated failure, paired with its reason and a concrete alternative.
- One good and one bad concrete example beat an abstract failure-label; use one to three examples, no more — examples bloat as fast as prose.
- State each rule once — no reinforcement bookend, no `=== ===` dividers; plain markdown `##` headers.
- Match the form to the load: an atomic rule is one line, a judgment call is short prose plus its reason. A simple skill wrapped in a heavy skeleton leaks that shape into the model's output.

## Frontmatter and size

- `description`: under ~250 characters (it is the catalog signal used to match the skill); LEAD with the trigger — when to invoke it and when not to — and keep the method in the body. A description that recaps the workflow invites the reader to act on the summary and skip the body.
- `disable-model-invocation: true` when the skill is meant to be user-invoked, so the model does not auto-fire it.
- `allowed-tools`: exactly what the body uses — if the body says "write the file," `Write` is in the list; a body claiming an action whose tool is absent is the incoherence to catch.
- Keep an ordinary user-invoked skill in the 500–1500 token band, a tool-workflow skill up to ~2500; over band needs a recorded reason. Measure the size (`wc -m` ÷ 4) after writing.

## Self-verify, then stop at the artifact

Before delivering, confirm: a named demonstrated mistake justifies the skill; domain claims are sourced and dated or marked unknown; framing is positive-first with examples not labels; no `===`, no end-bookend; frontmatter is coherent (description within the cap, tools match the body); size is in band. Deliver the new skill file plus a one-line note of what you verified, and state plainly that independent audit was not run. Do not suggest next steps or route to other elements — author the skill and end.

## Territory

This skill's deliverable is one new, research-grounded, lean skill file that names the demonstrated mistake it prevents — or a reasoned "no skill needed." It does not author skills no failure justifies, does not guarantee correctness beyond its cited sources, and does not run the kit's independent element audit, which is outside this skill.
