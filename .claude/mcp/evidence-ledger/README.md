# evidence-ledger — the kit's discipline-receipt MCP

The kit's one custom-authored capability. The kit's discipline turns on evidence, but evidence usually lives as prose a verifier must re-read and trust. This server records a claim as a machine-readable **receipt** and lets a verifier query it deterministically — recorded evidence, not narration. No external server does this; it is genuinely the kit's own (the moat). Everything else the kit needs is vendored off-the-shelf (see `/mcp-setup`).

## Wire it into `.mcp.json`

```json
{
  "mcpServers": {
    "evidence-ledger": {
      "command": "node",
      "args": ["${CLAUDE_PROJECT_DIR:-.}/.claude/mcp/evidence-ledger/server.js"]
    }
  }
}
```

The `${CLAUDE_PROJECT_DIR:-.}` fallback resolves to the project root when the harness sets `CLAUDE_PROJECT_DIR`, and to the current directory otherwise — so `/doctor` does not flag a missing variable, and the server still finds itself (it resolves its own state dir via `CLAUDE_PROJECT_DIR || process.cwd()`). If your harness expands neither form, use the absolute path to `server.js`. Requires Node (no install, no dependencies).

## Tools

- `record_receipt(kind, summary, evidence)` — `kind` ∈ `completion | test | security | freshness`; appends one JSON line to `${CLAUDE_PROJECT_DIR}/.claude/state/receipts.jsonl`.
- `list_receipts(kind?, since?)` — returns recorded receipts, optionally filtered by kind and/or an ISO `since` timestamp.

## Why a verifier should read it

A verifier (the kit's adversarial verifier, the security pass) can `list_receipts` to check whether a "tests pass" / "scan clean" / "deps fresh" claim is backed by a recorded observable, instead of trusting a prose assertion. A claim with no matching receipt is unbacked.

## Auditable by design

Plain Node, zero dependencies, no network, no `eval`, no obfuscation — readable before you run it. Storage is a local newline-delimited JSON file holding no secrets. Receipts record the *observable* (command output, path, hash, URL) — never a credential value.
