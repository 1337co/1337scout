#!/usr/bin/env node
/*
 * evidence-ledger — a tiny stdio MCP server (the kit's one custom-authored capability).
 *
 * Why it exists: the kit's discipline turns on EVIDENCE, but evidence usually lives as prose a
 * verifier must re-read and trust. This server lets a claim be recorded as a machine-readable
 * RECEIPT and queried deterministically — so a verifier reads recorded evidence, not narration.
 * No external server does this; it is genuinely the kit's own (the moat).
 *
 * Auditable by design: plain Node, zero dependencies, no network, no eval, no obfuscation.
 * Transport: MCP stdio = newline-delimited JSON-RPC 2.0. Storage: one JSON line per receipt at
 * ${CLAUDE_PROJECT_DIR}/.claude/state/receipts.jsonl (local file, no secrets — record the
 * observable, never a credential value). CLAUDE_PROJECT_DIR is the harness-provided project root.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const { StringDecoder } = require('string_decoder');

const ROOT = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const STATE_DIR = path.join(ROOT, '.claude', 'state');
const LEDGER = path.join(STATE_DIR, 'receipts.jsonl');
const KINDS = ['completion', 'test', 'security', 'freshness'];
const SUPPORTED = ['2025-06-18', '2025-03-26', '2024-11-05'];
const MAX_LINE = 1 << 20;   // 1 MiB cap per JSON-RPC message
const MAX_FIELD = 8192;     // summary / evidence length cap
const DEFAULT_LIMIT = 100, MAX_LIMIT = 1000;

function rpcErr(code, message) { const e = new Error(message); e.code = code; return e; }

// Secret guard. A receipt records an OBSERVABLE, never a credential value. This append is a
// disk-write path that does NOT pass through the PreToolUse secret-scanner hook (that hook only
// sees Write|Edit|MultiEdit tool calls), so the high-confidence credential shapes are rejected
// here too — keeping "no secret reaches disk" true for this path. Focused subset of the hooks'
// secret patterns (vendor key / private key / AWS secret / DSN-with-password); reject, don't store.
const SECRET_RX = [
  /(^|[^A-Za-z0-9_])(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|gh[opsur]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,}|sk-(ant|proj|or)-[A-Za-z0-9_-]{16,}|[sr]k_live_[A-Za-z0-9]{16,}|xox[bpasr]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|glpat-[A-Za-z0-9_-]{20}|hf_[A-Za-z0-9]{34}|eyJ[A-Za-z0-9_=-]{8,}\.eyJ[A-Za-z0-9_=-]{8,}\.[A-Za-z0-9_=-]{6,})/,
  /-----BEGIN [A-Z ]*PRIVATE KEY-----/,
  /aws_secret_access_key[\s"'=:]{0,4}[A-Za-z0-9/+]{20,}/i,
  /[a-z][a-z0-9+.-]*:\/\/[^:@/\s]+:[^@/\s]{2,}@/,
];
function looksLikeSecret(s) { return SECRET_RX.some((rx) => rx.test(s)); }

function appendReceipt(r) { fs.mkdirSync(STATE_DIR, { recursive: true }); fs.appendFileSync(LEDGER, JSON.stringify(r) + '\n'); }
function readReceipts() {
  try {
    return fs.readFileSync(LEDGER, 'utf8').split('\n').filter(Boolean)
      .map((l) => { try { return JSON.parse(l); } catch (_) { return null; } }).filter(Boolean);
  } catch (_) { return []; }
}

const TOOLS = [
  {
    name: 'record_receipt',
    description: 'Record a machine-readable discipline receipt — a completion/test/security/freshness claim with the observable that backs it — to the project ledger, so a verifier reads recorded evidence instead of trusting prose.',
    inputSchema: {
      type: 'object',
      properties: {
        kind: { type: 'string', enum: KINDS, description: 'receipt class' },
        summary: { type: 'string', description: 'one-line claim being recorded' },
        evidence: { type: 'string', description: 'the observable that backs it — command output, file path, hash, or URL' },
      },
      required: ['kind', 'summary', 'evidence'],
    },
  },
  {
    name: 'list_receipts',
    description: 'List recorded receipts, optionally filtered by kind and/or since (ISO timestamp), newest-last, capped by limit. Returns the machine-recorded evidence a verifier checks claims against.',
    inputSchema: {
      type: 'object',
      properties: {
        kind: { type: 'string', enum: KINDS },
        since: { type: 'string', description: 'ISO timestamp; return only receipts at or after it' },
        limit: { type: 'integer', minimum: 1, maximum: MAX_LIMIT, description: 'max receipts to return (default 100)' },
      },
    },
  },
];

function runTool(name, args) {
  args = args || {};
  if (name === 'record_receipt') {
    if (!KINDS.includes(args.kind)) throw rpcErr(-32602, 'kind must be one of: ' + KINDS.join(', '));
    if (typeof args.summary !== 'string' || typeof args.evidence !== 'string' || !args.summary || !args.evidence)
      throw rpcErr(-32602, 'summary and evidence are required non-empty strings');
    if (args.summary.length > MAX_FIELD || args.evidence.length > MAX_FIELD)
      throw rpcErr(-32602, 'summary/evidence exceed ' + MAX_FIELD + ' chars');
    if (looksLikeSecret(args.summary) || looksLikeSecret(args.evidence))
      throw rpcErr(-32602, 'receipt appears to contain a secret value — record the observable (a hash, path, count, or PASS/FAIL line), never the credential itself');
    const r = { ts: new Date().toISOString(), kind: args.kind, summary: args.summary, evidence: args.evidence };
    appendReceipt(r);
    return { content: [{ type: 'text', text: 'recorded ' + JSON.stringify(r) }] };
  }
  if (name === 'list_receipts') {
    if (args.kind !== undefined && !KINDS.includes(args.kind)) throw rpcErr(-32602, 'kind must be one of: ' + KINDS.join(', '));
    let sinceMs = null;
    if (args.since !== undefined) { sinceMs = Date.parse(args.since); if (Number.isNaN(sinceMs)) throw rpcErr(-32602, 'since must be an ISO timestamp'); }
    let limit = DEFAULT_LIMIT;
    if (args.limit !== undefined) {
      limit = Number(args.limit);
      if (!Number.isInteger(limit) || limit < 1) throw rpcErr(-32602, 'limit must be a positive integer');
      limit = Math.min(limit, MAX_LIMIT);
    }
    let rs = readReceipts();
    if (args.kind) rs = rs.filter((r) => r.kind === args.kind);
    if (sinceMs !== null) rs = rs.filter((r) => { const t = Date.parse(r.ts); return !Number.isNaN(t) && t >= sinceMs; });
    rs = rs.slice(-limit);
    return { content: [{ type: 'text', text: JSON.stringify(rs, null, 2) }] };
  }
  throw rpcErr(-32602, 'unknown tool: ' + name);
}

function send(msg) { process.stdout.write(JSON.stringify(msg) + '\n'); }
function ok(id, result) { send({ jsonrpc: '2.0', id, result }); }
function fail(id, code, message) { send({ jsonrpc: '2.0', id: id === undefined ? null : id, error: { code, message } }); }
const isNotification = (m) => m === 'notifications/initialized' || m === 'initialized';

function handle(msg) {
  const hasId = Object.prototype.hasOwnProperty.call(msg, 'id');
  const method = msg.method;
  if (isNotification(method)) return;   // notification — never reply
  if (!hasId) return;                   // request without id is unanswerable; drop
  const id = msg.id;
  if (method === 'initialize') {
    const req = msg.params && msg.params.protocolVersion;
    const version = SUPPORTED.includes(req) ? req : SUPPORTED[0];
    return ok(id, { protocolVersion: version, capabilities: { tools: {} }, serverInfo: { name: 'evidence-ledger', version: '0.1.0' } });
  }
  if (method === 'tools/list') return ok(id, { tools: TOOLS });
  if (method === 'tools/call') {
    try { return ok(id, runTool(msg.params && msg.params.name, msg.params && msg.params.arguments)); }
    catch (e) { return fail(id, e.code || -32603, e.message); }
  }
  if (method === 'ping') return ok(id, {});
  return fail(id, -32601, 'method not found: ' + method);
}

const decoder = new StringDecoder('utf8');
let buf = '';
process.stdin.on('data', (chunk) => {
  buf += decoder.write(chunk);
  let nl;
  while ((nl = buf.indexOf('\n')) >= 0) {
    const line = buf.slice(0, nl).trim();
    buf = buf.slice(nl + 1);
    if (!line) continue;
    let msg;
    try { msg = JSON.parse(line); } catch (_) { fail(null, -32700, 'parse error'); continue; }
    try { handle(msg); }
    catch (e) { const id = (msg && Object.prototype.hasOwnProperty.call(msg, 'id')) ? msg.id : null; fail(id, e.code || -32603, e.message); }
  }
  if (buf.length > MAX_LINE) { fail(null, -32700, 'message exceeds max size'); buf = ''; }
});
process.stdin.on('end', () => process.exit(0));
