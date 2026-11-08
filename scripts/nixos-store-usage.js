#!/usr/bin/env node
'use strict';

// Analyze an already-realized system, without evaluating the current checkout.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

function usage() {
  console.log(`Usage: nixos-store-usage.js [options]

Analyze runtime references of an installed NixOS system (no builds or changes).
  --system PATH       System generation (default /run/current-system)
  --metadata FILE     Read nix path-info --json --recursive output from FILE
  --sort KEY          peer (default), unique, total, or shared
  --scope SCOPE       all (default), packages, or system
  --format FORMAT     table (default), csv, or json
  --output FILE       Write report to FILE instead of stdout
  --limit N           Show only the first N rows (default: all)
  --details TEXT      Show matching roots and their largest dependencies
  --help              Show this help

Sizes are NAR sizes (uncompressed serialized store paths), in bytes in CSV/JSON.
Peer is exclusive among profile packages; for other roots it equals unique.
Unique excludes all other discovered roots and the remaining system graph.
Neither is a promise of disk space reclaimed after changing a configuration.`);
}
function fail(message) { throw new Error(message); }
function parseArgs(args) {
  const opts = {system: '/run/current-system', sort: 'peer', scope: 'all', format: 'table', limit: 0};
  const values = new Set(['--system', '--metadata', '--sort', '--scope', '--format', '--output', '--limit', '--details']);
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--help') { usage(); process.exit(0); }
    if (!values.has(arg) || i + 1 >= args.length) fail(`Invalid or incomplete option: ${arg}`);
    opts[arg.slice(2)] = args[++i];
  }
  if (!['peer', 'unique', 'total', 'shared'].includes(opts.sort)) fail('Invalid --sort');
  if (!['all', 'packages', 'system'].includes(opts.scope)) fail('Invalid --scope');
  if (!['table', 'csv', 'json'].includes(opts.format)) fail('Invalid --format');
  if (!/^\d+$/.test(String(opts.limit)) || !Number.isSafeInteger(Number(opts.limit))) fail('Invalid --limit');
  opts.limit = Number(opts.limit);
  if (opts.details && opts.format !== 'table') fail('--details requires --format table');
  return opts;
}
function shortName(p) { return path.basename(p).replace(/^[0-9a-z]{32}-/, ''); }
function human(n) {
  if (!n) return '0 B';
  const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
  const i = Math.min(Math.floor(Math.log(n) / Math.log(1024)), units.length - 1);
  return `${(n / 1024 ** i).toFixed(i ? 2 : 0)} ${units[i]}`;
}
function csvCell(v) { return `"${String(v).replace(/"/g, '""')}"`; }

function main() {
  const opts = parseArgs(process.argv.slice(2));
  const system = fs.realpathSync(opts.system);
  let raw;
  if (opts.metadata) raw = fs.readFileSync(opts.metadata, 'utf8');
  else {
    console.error(`Reading the runtime closure of ${system} from the Nix store...`);
    const proc = spawnSync('nix', ['path-info', '--json', '--recursive', system], {encoding: 'utf8', maxBuffer: 512 * 1024 * 1024});
    if (proc.error) throw proc.error;
    if (proc.status !== 0) fail(`nix path-info failed: ${proc.stderr.trim()}`);
    raw = proc.stdout;
  }
  const parsed = JSON.parse(raw);
  // Older Nix emits an array with a path property; newer versions emit an object.
  const data = Array.isArray(parsed) ? Object.fromEntries(parsed.map(x => [x.path, x])) : parsed;
  if (!data[system]) fail(`System ${system} is absent from metadata`);
  const paths = Object.keys(data);
  const index = new Map(paths.map((p, i) => [p, i]));
  const graph = paths.map(p => {
    const item = data[p];
    if (!Number.isSafeInteger(item.narSize) || item.narSize < 0 || !Array.isArray(item.references)) fail(`Incomplete metadata for ${p}`);
    return item.references.filter(ref => ref !== p).map(ref => {
      if (!index.has(ref)) fail(`Missing referenced path ${ref}`);
      return index.get(ref);
    });
  });
  const sizes = paths.map(p => data[p].narSize);
  const systemId = index.get(system);
  const candidates = new Map();
  function add(id, origin) {
    if (id === systemId) return;
    if (!candidates.has(id)) candidates.set(id, new Set());
    candidates.get(id).add(origin);
  }
  // Profile references are the realized, linked outputs; buildEnv may omit
  // outputs with no selected files, so this is not the evaluated Nix list.
  const profiles = new Map();
  for (let i = 0; i < paths.length; i++) {
    const n = shortName(paths[i]);
    if (n === 'system-path') profiles.set(i, 'system profile');
    else if (n === 'home-manager-path') profiles.set(i, 'home profile');
    else if (n === 'user-environment') profiles.set(i, 'user profile');
  }
  for (const [id, label] of profiles) for (const ref of graph[id]) {
    if (!profiles.has(ref)) add(ref, label);
  }
  // System components and systemd units cover service-only dependencies,
  // kernel, initrd and firmware which do not appear as profile packages.
  for (const ref of graph[systemId]) {
    if (!profiles.has(ref) && shortName(paths[ref]) !== 'etc') add(ref, 'system component');
  }
  const units = new Set();
  for (let i = 0; i < paths.length; i++) {
    if (/^unit-.*\.service$/.test(shortName(paths[i]))) { units.add(i); add(i, 'service unit'); }
  }
  const roots = [...candidates.keys()];
  const visited = new Uint32Array(paths.length);
  let stamp = 0;
  function closure(start, skip) {
    stamp++;
    const stack = [start], result = [];
    visited[start] = stamp;
    while (stack.length) {
      const id = stack.pop(); result.push(id);
      for (const ref of graph[id]) {
        if (visited[ref] !== stamp && !(skip && skip(id, ref))) {
          visited[ref] = stamp; stack.push(ref);
        }
      }
    }
    return result;
  }
  // The baseline is everything still reachable when the discovered profile,
  // component and unit entry edges are cut. Other references to package paths
  // are retained, preventing an optimistic estimate for system-owned paths.
  const baseline = new Uint8Array(paths.length);
  for (const id of closure(systemId, (from, to) =>
    (profiles.has(from) && candidates.has(to)) ||
    (from === systemId && candidates.has(to)) || units.has(to))) baseline[id] = 1;
  const counts = new Uint32Array(paths.length);
  const packageCounts = new Uint32Array(paths.length);
  const isPackage = id => [...candidates.get(id)].some(origin => origin.endsWith('profile'));
  const closures = roots.map(id => {
    const members = closure(id);
    for (const v of members) {
      counts[v]++;
      if (isPackage(id)) packageCounts[v]++;
    }
    return members;
  });
  const sum = ids => ids.reduce((n, id) => n + sizes[id], 0);
  const rows = roots.map((id, i) => {
    let total = 0, unique = 0, baselineShared = 0, peer = 0;
    for (const v of closures[i]) {
      total += sizes[v];
      if (baseline[v]) baselineShared += sizes[v];
      if (counts[v] === 1 && !baseline[v]) unique += sizes[v];
      if (packageCounts[v] === 1 && isPackage(id)) peer += sizes[v];
    }
    if (!isPackage(id)) peer = unique;
    return {name: shortName(paths[id]), path: paths[id], origins: [...candidates.get(id)].sort(),
      kind: isPackage(id) ? 'package' : 'system', total, shared: total - unique, unique, peer,
      peerShared: total - peer, baselineShared, dependencyCount: closures[i].length, rootIndex: i};
  });
  rows.sort((a, b) => b[opts.sort] - a[opts.sort] || b.total - a.total || a.path.localeCompare(b.path));
  const covered = counts.reduce((n, count, i) => n + (count ? sizes[i] : 0), 0);
  const baselineOnly = counts.reduce((n, count, i) => n + (!count && baseline[i] ? sizes[i] : 0), 0);
  const unaccounted = counts.reduce((n, count, i) => n + (!count && !baseline[i] ? sizes[i] : 0), 0);
  const metadata = {system, storePaths: paths.length, systemBytes: sum(paths.map((_, i) => i)),
    rootCount: roots.length, rootsUnionBytes: covered, baselineOnlyBytes: baselineOnly, unaccountedBytes: unaccounted,
    measurement: 'NAR bytes; runtime references of the selected system generation'};
  const scoped = rows.filter(row => opts.scope === 'all' || (opts.scope === 'packages' ? row.kind === 'package' : row.kind === 'system'));
  const selected = opts.limit ? scoped.slice(0, opts.limit) : scoped;
  let output;
  if (opts.details) {
    const matching = scoped.filter(row => `${row.name} ${row.path} ${row.origins.join(' ')}`.toLowerCase().includes(opts.details.toLowerCase()));
    if (!matching.length) fail(`No root matches: ${opts.details}`);
    output = matching.map(row => {
      const deps = closures[row.rootIndex].slice().sort((a, b) => sizes[b] - sizes[a]);
      const shown = opts.limit ? deps.slice(0, opts.limit) : deps;
      return `${row.name}  ${row.path}\nOrigins: ${row.origins.join(', ')}; total ${human(row.total)}; ${row.kind === 'package' ? 'profile peer-exclusive' : 'system-exclusive'} ${human(row.peer)}; system-exclusive ${human(row.unique)}\n` +
        `      SIZE  PROFILE       SYSTEM\n` +
        shown.map(id => `${human(sizes[id]).padStart(11)}  ${(packageCounts[id] > 1 ? 'shared' : packageCounts[id] === 1 ? 'one package' : 'none').padEnd(11)}  ${(baseline[id] ? 'baseline' : counts[id] > 1 ? 'shared' : 'unique').padEnd(8)}  ${paths[id]}`).join('\n');
    }).join('\n\n') + '\n';
  } else if (opts.format === 'json') {
    output = JSON.stringify({metadata, rows: selected.map(({rootIndex, ...row}) => row)}, null, 2) + '\n';
  } else if (opts.format === 'csv') {
    const columns = ['name', 'path', 'kind', 'origins', 'total', 'peer', 'peerShared', 'unique', 'shared', 'baselineShared', 'dependencyCount'];
    output = columns.join(',') + '\n' + selected.map(row => columns.map(col => csvCell(Array.isArray(row[col]) ? row[col].join('; ') : row[col])).join(',')).join('\n') + '\n';
  } else {
    output = `System: ${system}\nRuntime closure: ${human(metadata.systemBytes)}; ${paths.length} paths; ${roots.length} roots\n` +
      `Roots' union: ${human(covered)}; baseline only: ${human(baselineOnly)}; unaccounted: ${human(unaccounted)}\n` +
      `NAR sizes. PEER: exclusive among profile packages; for system roots, equals UNIQUE.\n` +
      `UNIQUE: exclusive of all other roots and remaining system graph. Sort: ${opts.sort}.\n\n` +
      `${'PEER'.padStart(11)}  ${'UNIQUE'.padStart(11)}  ${'SHARED'.padStart(11)}  ${'TOTAL'.padStart(11)}  ROOT [ORIGINS]\n` +
      selected.map(row => `${human(row.peer).padStart(11)}  ${human(row.unique).padStart(11)}  ${human(row.shared).padStart(11)}  ${human(row.total).padStart(11)}  ${row.name} [${row.origins.join(', ')}]`).join('\n') + '\n';
  }
  if (opts.output) fs.writeFileSync(opts.output, output); else process.stdout.write(output);
}
try { main(); } catch (error) { console.error(`nixos-store-usage: ${error.message}`); process.exit(1); }
