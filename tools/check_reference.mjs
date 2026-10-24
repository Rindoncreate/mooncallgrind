// Independent reader check: Valgrind's callgrind_annotate, not a second local parser.
import assert from 'node:assert/strict';
import { readFile, writeFile, mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { run } from '../_build/js/debug/build/bridge/bridge.js';

function annotated(path) {
  const r = spawnSync('callgrind_annotate', ['--auto=no', '--show=Ir', '--show-percs=no', '--threshold=100', '--inclusive=no', '--tree=none', path], { encoding: 'utf8', timeout: 30000, maxBuffer: 8000000 });
  assert.equal(r.status, 0, r.stderr);
  assert.equal(r.stderr, '', `reference warnings: ${r.stderr}`);
  const rows = r.stdout.split('\n').flatMap(line => {
    const m = line.match(/^\s*([0-9][0-9,]*)\s+(.+)$/);
    return m ? [[m[2].trim(), m[1].replaceAll(',', '')]] : [];
  });
  assert(rows.some(([name]) => name === 'PROGRAM TOTALS'), r.stdout);
  return rows.sort((a, b) => a[0].localeCompare(b[0]));
}
const folder = await mkdtemp(join(tmpdir(), 'mooncallgrind-reference-'));
const inventory = JSON.parse(await readFile('fixtures/http_server.inventory.json', 'utf8'));
try {
  for (const path of ['examples/two-sites.callgrind', 'fixtures/http_server.callgrind']) {
    const text = await readFile(path, 'utf8');
    const result = JSON.parse(run('inspect', text, '', ''));
    assert.equal(result.ok, true, JSON.stringify(result.error));
    const norm = JSON.parse(run('normalize', text, '', ''));
    assert.equal(norm.ok, true, JSON.stringify(norm.error));
    const output = join(folder, 'normalized.callgrind');
    await writeFile(output, norm.value);
    const original = annotated(path);
    assert.deepEqual(annotated(output), original, 'independent function self-costs changed after normalization');
    const total = original.find(([name]) => name === 'PROGRAM TOTALS')[1];
    const computed = JSON.parse(run('totals', text, '', 'Ir'));
    assert.equal(computed.ok, true, JSON.stringify(computed.error));
    const sum = computed.value.reduce((acc, row) => acc + BigInt(row.value), 0n);
    const real = path.includes('http_server');
    // PROGRAM TOTALS is declared metadata, not necessarily the sum of body records.
    assert.equal(sum.toString(), real ? inventory.selfIr : '7', 'body self-cost sum differs from independently inventoried counters');
    assert.equal(total, real ? inventory.declaredSummaryIr : '7', 'reference declared total changed');
    const calls = result.value.records.filter(r => r.kind.type === 'call');
    if (path.includes('http_server')) {
      assert.equal(calls.length, 2072);
      assert.equal(result.value.records.length, inventory.records);
      assert.equal(result.value.parts.length, 1);
    }
    console.log(`Independent reference passed: ${path}; ${result.value.records.length} records, ${calls.length} calls, body Ir=${sum}, declared Ir=${total}`);
  }
} finally {
  await rm(folder, { recursive: true });
}
