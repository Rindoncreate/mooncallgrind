import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { run } from '../_build/js/debug/build/bridge/bridge.js';

function cli(args, status = 0) {
  const r = spawnSync(process.execPath, ['bin/mooncallgrind.mjs', ...args], { encoding: 'utf8', timeout: 30000 });
  assert.equal(r.status, status, r.stderr);
  return r;
}
const folder = await mkdtemp(join(tmpdir(), 'mooncallgrind-cli-'));
try {
  const source = 'examples/two-sites.callgrind';
  const p = JSON.parse(cli(['inspect', source]).stdout);
  assert.equal(p.records.length, 4);
  assert.deepEqual(p.records[1].positions, ['17', '10']);
  assert.deepEqual(p.records[1].kind.targetPositions, ['112', '70']);
  assert.equal(p.records[3].kind.target.function, 'main');
  assert.equal(JSON.parse(cli(['totals', source, 'Ir']).stdout)[0].value, '7');
  const output = join(folder, 'normalized.callgrind');
  cli(['normalize', source, output]);
  const q = JSON.parse(cli(['inspect', output]).stdout);
  assert.deepEqual(q.records.map(({ line, ...r }) => r), p.records.map(({ line, ...r }) => r));
  cli(['normalize', source, output], 1); // never overwrite an existing file
  const changes = JSON.parse(cli(['diff', source, output, 'Ir']).stdout);
  assert.equal(changes[0].before, changes[0].after);
  cli(['totals', source, 'AbsentEvent'], 1);
  cli(['inspect'], 1);
  const bad = join(folder, 'invalid.callgrind');
  await writeFile(bad, new Uint8Array([0xc0, 0xaf]));
  cli(['inspect', bad], 1); // invalid UTF-8 cannot silently become replacement chars
  const huge = 'events: Ir\nfn=f\n1 18446744073709551615\n';
  const exact = JSON.parse(run('inspect', huge, '', ''));
  assert.equal(exact.value.records[0].values[0], '18446744073709551615');
  const normalized = await readFile(output, 'utf8');
  assert.equal(JSON.parse(run('normalize', normalized, '', '')).value, normalized);
  console.log('CLI: inspect/totals/normalize/diff, exact counters, invalid UTF-8 and overwrite refusal passed');
} finally {
  await rm(folder, { recursive: true });
}
