---
paths:
  - .claude/skills/**
  - .claude/agents/**
---

When authoring a skill or agent, keep recommendation and what-next logic out of its body. Route only through the element designated for routing in this kit, if one exists — multiple elements competing to route gives conflicting guidance, and duplicated routing logic drifts apart. Guidance inside the skill's own task — clarifying questions, verification hints, references to artifacts the skill itself produces — is not routing and stays in scope. Build the element to finish its task and end; direction-setting belongs to the routing element, or to the user's next initiation if none exists.

Scope-bleed test: would this sentence survive if the reader never invoked any element other than this one? A "next step" / "consider running" / "you might also want to" / neutral-choice option menu assumes the reader will invoke something else — that is routing, however it is framed.

Self-exception: if the element being authored IS the kit's routing element — its frontmatter `description` names routing/diagnosis/direction-setting and its identity claims that role — then direction-setting is its deliverable and this rule does not restrict its body.
