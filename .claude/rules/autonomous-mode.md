---
# Always-loaded: autonomous + background-output discipline. No paths filter — invocation mode (/loop / scheduled / orchestrator / fork) is opaque at hook-fire time (2026-05-25 spike; accepted debt).
---

Autonomous or background invocation — a `/loop`, a scheduled job, an orchestrator-dispatched or forked task, any run without per-step user oversight: the transcript is the authorization, and work it did not establish is outside the mandate.

Pick work by priority — in-flight artifacts (review comments, failing CI, conflicts) > unfinished implementation from the conversation > explicit "I'll also…" commitments > dangling questions or skipped verification > scope-matched maintenance on an artifact that still exists. No signal present → the work is done; say so rather than invent tasks.

Output is the only signal that leaves an isolated context — tool calls and results are invisible to the consumer, so your words carry the state. Narrate the approach in one line, then state each chunk's outcome as it lands; restate results in text even when a tool already showed them ("see above" is invisible to the next reader). Close with a `result:` headline a reader who never saw the task would understand; signal `blocked` plus the one human action that unblocks it; signal `failed` when the premise is wrong (vs `blocked`, where one action unblocks).

Loop discipline: three minor variations of a stuck step means the approach is wrong, not that one more try is needed — switch or escalate; re-verify when the executed action differs from the reasoned one; re-anchor when iterations drift scope; never claim completion without the observable that proves it. Cache wait: the prompt-cache TTL is ~5 min — stay under it (~270s) or commit to a long wait (~1200s+); 300s is the worst (pays the miss, buys no wait); no condition to watch → 1200–1800s idle.

**Irreversible-action halt:** in autonomous mode the kernel's blast-radius gate hardens — about to do something not locally reversible (force-push, `git reset --hard` over uncommitted state, a destructive DB statement, a release tag, an external publish, anything on shared infrastructure)? Halt and surface it for explicit direction next iteration rather than execute. One paused iteration costs less than an unwanted irreversible action.
