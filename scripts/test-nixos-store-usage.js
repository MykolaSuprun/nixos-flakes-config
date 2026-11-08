#!/usr/bin/env node
'use strict';
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const {spawnSync} = require('child_process');
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'store-usage-test-'));
try {
  const make = name => path.join(dir, '00000000000000000000000000000000-' + name);
  const system = make('nixos-system'), profile = make('system-path');
  const a = make('package-a'), b = make('package-b'), common = make('common');
  const service = make('unit-example.service'), baseline = make('baseline'), etc = make('etc');
  fs.writeFileSync(system, '');
  const graph = {
    [system]: {narSize: 1, references: [profile, service, etc]},
    [etc]: {narSize: 1, references: [baseline]},
    [profile]: {narSize: 2, references: [a, b]},
    [a]: {narSize: 10, references: [a, common, baseline]},
    [b]: {narSize: 20, references: [common]},
    [common]: {narSize: 5, references: []},
    [service]: {narSize: 3, references: [a]},
    [baseline]: {narSize: 7, references: []},
  };
  const metadata = path.join(dir, 'metadata.json');
  fs.writeFileSync(metadata, JSON.stringify(graph));
  const script = path.join(__dirname, 'nixos-store-usage.js');
  function run(...args) {
    const result = spawnSync(process.execPath, [script, '--system', system, '--metadata', metadata, ...args], {encoding: 'utf8'});
    if (result.error) throw result.error;
    assert.strictEqual(result.status, 0, result.stderr);
    return result.stdout;
  }
  const result = JSON.parse(run('--format', 'json'));
  const byName = Object.fromEntries(result.rows.map(row => [row.name, row]));
  assert.strictEqual(result.metadata.systemBytes, 49);
  assert.strictEqual(result.metadata.unaccountedBytes, 0);
  assert.strictEqual(byName['package-a'].total, 22);
  assert.strictEqual(byName['package-a'].peer, 17); // baseline retained separately
  assert.strictEqual(byName['package-a'].peerShared, 5);
  assert.strictEqual(byName['package-a'].unique, 0); // service also retains it
  assert.strictEqual(byName['package-b'].peer, 20);
  assert.strictEqual(byName['package-b'].unique, 20);
  assert.strictEqual(byName['package-b'].shared, 5);
  assert.strictEqual(JSON.parse(run('--scope', 'packages', '--limit', '1', '--format', 'json')).rows[0].name, 'package-b');
  assert.match(run('--details', 'package-a'), /baseline\s+.*baseline/);
  assert.match(run('--format', 'csv'), /peerShared/);
  console.log('nixos-store-usage tests passed');
} finally { fs.rmSync(dir, {recursive: true, force: true}); }
