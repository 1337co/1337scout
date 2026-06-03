#!/usr/bin/env node
'use strict';
/*
 * 1337scout installer — scaffolds the kit into a project directory.
 * Zero dependencies (Node built-ins only). Fetches nothing from the network:
 * every file ships inside this npm package. Refuses to overwrite any existing
 * kit item unless --force (the kit's own blast-radius discipline, applied to its
 * own installer), and git-ignores the kit's runtime-state dirs in the target.
 */
const fs = require('fs');
const path = require('path');

const PKG_ROOT = path.join(__dirname, '..');
// The kit = enforcement + governance files copied into the target project root.
// README and LICENSE are NOT scaffolded: README would clobber the user's own
// (--with-readme drops it as 1337scout-README.md), and the kit's MIT LICENSE
// belongs in the npm package / repo, never overwriting a project's own LICENSE.
const KIT_ITEMS = ['.claude', 'CLAUDE.md', '.mcp.json', 'docs', 'scripts'];
// Refuse to overwrite ANY existing kit item without --force — the kit's own
// blast-radius discipline applied to its installer: never silently clobber a
// file (docs/, scripts/, .mcp.json, …) the target project may already have.
const GUARD_ITEMS = KIT_ITEMS;

const HELP = `1337scout — scaffold a discipline-first Claude Code kit into a project.

Usage:
  npx 1337scout [target-dir] [options]

Copies .claude/, CLAUDE.md, .mcp.json, docs/, scripts/ into the target
directory (default: the current directory). Then open a Claude Code session at
that directory — the PreToolUse safety hooks activate automatically.
Requires bash + python3 on PATH (the hooks' parser + the harness).

Options:
  -n, --dry-run      Show what would be written; change nothing.
  -f, --force        Overwrite if any of those items already exist (default: refuse).
      --with-readme  Also copy the kit README as 1337scout-README.md.
  -h, --help         Show this help.

Nothing is downloaded — every file ships inside this package. Pin a version for
reproducible installs, e.g.  npx 1337scout@0.1.2`;

function parseArgs(argv) {
  const a = { target: null, force: false, dryRun: false, help: false, withReadme: false };
  for (const t of argv) {
    if (t === '--force' || t === '-f') a.force = true;
    else if (t === '--dry-run' || t === '-n') a.dryRun = true;
    else if (t === '--help' || t === '-h') a.help = true;
    else if (t === '--with-readme') a.withReadme = true;
    else if (!t.startsWith('-') && a.target === null) a.target = t;
    else { console.error(`[1337scout] unknown argument: ${t}`); return null; }
  }
  return a;
}

function ensureGitignore(target) {
  // The kit writes runtime state into the project — the evidence-ledger MCP's
  // .claude/state/receipts.jsonl and the compaction backup's .kit-state/. Make sure
  // both are git-ignored so a user never accidentally commits them. Idempotent and
  // additive: appends only the entries that are missing; creates .gitignore if absent.
  const gi = path.join(target, '.gitignore');
  const need = ['.claude/state/', '.kit-state/'];
  let cur = '';
  try { cur = fs.readFileSync(gi, 'utf8'); } catch (_) {}
  const have = new Set(cur.split(/\r?\n/).map((l) => l.trim()));
  const missing = need.filter((e) => !have.has(e));
  if (!missing.length) return [];
  const block = (cur && !cur.endsWith('\n') ? '\n' : '') +
    '\n# 1337scout runtime state (verifier receipts, compaction backups) — never commit\n' +
    missing.join('\n') + '\n';
  fs.appendFileSync(gi, block);
  return missing;
}

function main() {
  if (typeof fs.cpSync !== 'function') {
    console.error('[1337scout] needs Node >= 16.7 (fs.cpSync). Please upgrade Node.');
    return 1;
  }
  const args = parseArgs(process.argv.slice(2));
  if (args === null) { console.error('\n' + HELP); return 1; }
  if (args.help) { console.log(HELP); return 0; }

  const target = path.resolve(args.target || process.cwd());
  if (!fs.existsSync(target) || !fs.statSync(target).isDirectory()) {
    console.error(`[1337scout] target is not an existing directory: ${target}`);
    return 1;
  }

  const conflicts = GUARD_ITEMS.filter((p) => fs.existsSync(path.join(target, p)));
  if (conflicts.length && !args.force) {
    console.error(`[1337scout] refusing to overwrite existing ${conflicts.join(', ')} in:`);
    console.error(`            ${target}`);
    console.error(`[1337scout] back them up, or re-run with --force. Use --dry-run to preview.`);
    return 2;
  }

  const plan = KIT_ITEMS.filter((item) => fs.existsSync(path.join(PKG_ROOT, item)));
  console.log(`[1337scout] ${args.dryRun ? 'DRY-RUN — would install' : 'installing'} into: ${target}`);
  for (const item of plan) console.log(`  ${args.dryRun ? 'would copy ' : 'copy '} ${item}`);

  if (args.dryRun) { console.log('[1337scout] dry-run only — nothing written.'); return 0; }

  for (const item of plan) {
    fs.cpSync(path.join(PKG_ROOT, item), path.join(target, item), { recursive: true });
  }
  if (args.withReadme) {
    const readme = path.join(PKG_ROOT, 'README.md');
    if (fs.existsSync(readme)) fs.copyFileSync(readme, path.join(target, '1337scout-README.md'));
  }

  const ignored = ensureGitignore(target);
  if (ignored.length) console.log(`[1337scout] git-ignored runtime state in target: ${ignored.join(', ')}`);

  console.log('\n[1337scout] installed. Next:');
  console.log('  claude                                  # open a session here; hooks fire automatically');
  console.log('  bash scripts/mechanical-regression.sh   # prove the safety floor is live (24/24)');
  console.log('  note: the hooks need bash + python3 on PATH; without them they fail closed (block).');
  return 0;
}

process.exit(main());
