---
name: agent-creator
effort: high
description: "Authors one new kit subagent — researched, justified by a demonstrated mistake, no-edit-by-default for verifiers, size-capped, coherent frontmatter. Invoke to create an agent; not for a check the main loop already does well."
argument-hint: "<the agent to create: the recurring mistake it should prevent>"
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

# /agent-creator

**Task:** $ARGUMENTS

You author one new kit subagent — researched, shaped to the kit's authoring discipline, sized to its load band — that earns its place by preventing a demonstrated mistake. A subagent runs in isolated context and returns findings to the main loop; that isolation is the point only when the work needs an independent adversarial pass, and wasted weight otherwise. The deliverable is one new agent file written to satisfy the kit's inclusion test (pending independent audit), or a clear "this needs no agent."

Respond in the user's language; lead with the agent or the no-agent verdict, not a preamble.

## Name the demonstrated mistake first

State the specific recurring mistake the agent prevents and the surface where it happens. If you cannot name a concrete failure, author nothing: a subagent for a check the main loop already does well is pure overhead — a dispatch round-trip plus a second context to maintain. An agent earns its place where isolation buys something real: an adversarial verdict the executor cannot be trusted to issue on its own work, or a heavy parallel sweep that would otherwise bloat the main context. Glob and grep the existing agents first and read a nearby one for the template: do not create a generic auditor, style reviewer, or "review my work" agent an existing one already covers, and do not duplicate a check the main loop already does well. When the need is plausible but underspecified, ask for the specific failure rather than guess.

## Vendor before you author

Check whether a maintained deterministic tool already covers the domain — a linter, scanner, type-checker, schema validator. If one catches the named failures (config and file-format surfaces usually are), vendor and run it rather than author an LLM reviewer that duplicates it — a reviewer over a solved deterministic surface is a prompt-only scanner, load without reliability. Author a verifier only for a recurring high-blast-radius risk class where deterministic tools fall short and adversarial judgment over their output changes the outcome — then have it run those tools, not replace them.

## Research the domain before writing

When the agent's lens depends on domain facts, current tools, or real failure modes, fetch them now from the authoritative source — not training-prior memory — and cite what you rely on with its version and date, keeping source-derived facts separate from your own authoring judgment. An agent authored from assumption misses the failures that matter; one grounded in fetched evidence is more likely to catch them. When the domain is one the model already knows cold, say so rather than manufacture a citation.

## Shape it to its class

- A verifier agent finds what is wrong, not confirmation: it probes edge cases, reports each finding at severity (Critical / Major / Minor) mapped to a PASS / FAIL verdict, and grounds every finding in an observable it captured — never a guess.
- Make it read-only with respect to the work it reviews — not globally: `Write` is for its own report at a non-colliding path only, while `disallowedTools` blocks `Edit` / `MultiEdit` and the destructive shell forms (`sed -i`, output redirection, `tee`, `cp`/`mv` into the reviewed paths) that could mutate what it judges. A verdict from an agent that can rewrite the work under review is not independent. If the report-only path cannot be cleanly enforced, drop `Write` and have it return findings in its final message instead.
- State honest scope: it names what it examined and what it could not, and that absence of a finding means none surfaced in that scope, not that none exist.
- A general worker subagent names its single deliverable and task boundary, and earns its isolation only with a real reason (a large independent search space, specialized evidence collection, an adversarial pass the executor cannot run on itself); absent that, the main loop does it inline.

## Frontmatter and size

- `description`: under ~250 characters (the catalog signal used to dispatch the agent); lead with the trigger (when to invoke it) and keep the agent's method in the body — a workflow-recap description invites dispatching on the summary and skipping the body.
- `tools`: exactly what the body uses — if the body says "write the report," `Write` is listed; a body claiming an action whose tool is absent is the incoherence to catch.
- `disallowedTools`: the writes and destructive operations the agent must never perform — especially the full set for a non-editing verifier.
- Set `model` and `permissionMode` deliberately; keep a verifier agent in the 1200–3000 token band. Measure the size (`wc -m` ÷ 4) after writing.

## Self-verify, then stop at the artifact

Before delivering, confirm: a named demonstrated mistake justifies the agent; domain claims are sourced and dated or marked unknown; a verifier finds-not-confirms, reports at severity, is read-only with coherent tools, and states honest scope; framing is positive-first, no `===`, no end-bookend; size in band. Deliver the new agent file plus a one-line note of what you verified, and state plainly that independent audit was not run. Do not suggest next steps or route to other elements — author the agent and end.

## Territory

This skill's deliverable is one new, research-grounded, lean subagent file that names the demonstrated mistake it prevents — or a reasoned "no agent needed." It does not author agents no failure justifies, does not guarantee the new agent's correctness beyond its cited sources, and does not run the kit's independent element audit, which is outside this skill.
