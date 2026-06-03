---
name: mcp-setup
effort: low
description: "Wires a project's real stack to vetted maintained MCP servers via a recommended .mcp.json — capability the kit points at, not owns. Use when a project needs live tool access (repo, browser, DB, cloud) from proven servers, not reinvented."
argument-hint: "<optional: stack or capability to focus on>"
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebFetch
  - AskUserQuestion
---

# /mcp-setup

**Task:** $ARGUMENTS

You wire real capability into the project by recommending maintained, off-the-shelf MCP servers — you do not author capability and you do not reimplement a server that already exists. Capability is a commodity the ecosystem maintains and keeps current; the kit's value is the discipline that governs how any tool is used. Emit a `.mcp.json` that wires only the servers the project's actual stack needs, with every secret referenced from the environment, never inlined.

Respond in the user's language; lead with the recommended wiring and why each server earns its place, not a preamble.

## Detect the real stack first

Read the repo before recommending anything: manifests and lockfiles (package.json, requirements.txt, pyproject, go.mod, Cargo.toml, *.csproj), version control (.git plus its remote host), containers and clusters (Dockerfile, compose, k8s manifests), database config (connection-string shape, ORM config, migration dirs), and cloud markers (provider SDK deps, infra-as-code files). Recommend a server only for a surface the stack actually uses — an unused server is load the project pays for and never calls.

## Map each real need to one maintained server

Wire a server only when the stack uses that surface — none are default, not even repo or fetch. For each used surface pick the actively-maintained, official-or-canonical server, judged by current maintenance rather than star count — never an unmaintained duplicate, never a hand-rolled copy of a server that already exists:

- Repo / PR / issue / CI state the model cannot read unaided → the official GitHub MCP server.
- Render / screenshot / click / read console on a real page (so "looks right" becomes observable) → the official Playwright MCP server.
- Fetch real HTTP content → the official reference Fetch server.
- Run a real query and read a live schema → a maintained multi-database SQL server, or the platform's own server when the stack is built on one.
- Live cloud or cluster state → the official cloud or Kubernetes server, wired only when the project touches that control plane.
- Isolated, discardable execution of risky or parallel work — so a destructive or experimental step runs in a throwaway sandbox on its own branch, not the live tree → a maintained container-sandbox MCP server, opt-in because it adds a container runtime the project may not otherwise need.
- Go-to-definition / find-references / rename across a large codebase via a real language server → a maintained LSP server, when grep-level search is demonstrably insufficient.
- Current package versions and defense against hallucinated package names → a maintained package-registry server.
- Valid .xlsx / .docx / .pptx / .pdf with computed (not stringified) output → install the vendor's document skills and note the install; do not wire an MCP or author one.

When two servers cover one surface, pick the maintained or official one and say why. Record each server's name, source, and the date checked — adoption and maintenance shift, so the recommendation is dated, not permanent.

## Wire secrets by reference, never inline

Every token, connection string, or key in the emitted config is an environment-variable reference (`${VAR}`-style), never a literal value — and never a realistic-looking example token either (no `ghp_…` / `sk-…`-shaped placeholders); the only value that ever appears is the reference. Name the variables the user must set and where to set them — shell profile, the harness secret store, or CI secrets — so the config points at the secret and never contains it. Add any file that would hold a real secret to the ignore list before it could be committed. Decline to inline a credential even when asked, and surface the environment-reference path instead.

## Emit the recipe and mark the user's steps

Produce the `.mcp.json` (or merge into the existing one) carrying only the stack-matched servers, each with a short line: what it provides, the install or auth step to run, and the env vars to set. Installing a server, granting its auth, and setting its tokens are the user's actions — you wire the config, you do not create accounts or authenticate. Date the recipe and name each server so a later pass can re-verify it is still maintained and still the best choice.

## Territory

This skill's deliverable is a stack-matched `.mcp.json` recommendation plus the user's install-and-auth checklist — pointing at maintained external capability under the kit's discipline. It authors no capability and reimplements no existing server. Running the servers, holding their secrets, and granting auth are the user's; judging whether a wired tool's output is trustworthy is a separate verification step, not this skill's job.
