#!/usr/bin/env node
// Node handles files and stdout; the compiled MoonBit bridge owns the format.
import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { run } from '../_build/js/debug/build/bridge/bridge.js';

const usage = 'Usage: node bin/mooncallgrind.mjs inspect FILE | totals FILE EVENT | normalize INPUT OUTPUT | diff BEFORE AFTER EVENT';
async function read(path) {
  const data = await readFile(path);
  if (data.length > 32 * 1024 * 1024) throw new Error('Input exceeds 32 MiB');
  return new TextDecoder('utf-8', { fatal: true }).decode(data);
}
export async function main(args) {
  const [op, a, b, c] = args;
  const count = { inspect: 2, totals: 3, normalize: 3, diff: 4 }[op];
  if (!count || args.length !== count) throw new Error(usage);
  const input = await read(a);
  const result = JSON.parse(run(op, input, op === 'diff' ? await read(b) : '', op === 'diff' ? c : op === 'totals' ? b : ''));
  if (!result.ok) throw new Error(`${result.error.kind} at line ${result.error.line}: ${result.error.message}`);
  if (op === 'normalize') await writeFile(b, result.value, { encoding: 'utf8', flag: 'wx' });
  else process.stdout.write(JSON.stringify(result.value, null, 2) + '\n');
}
if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main(process.argv.slice(2)).catch(error => { console.error(error.message); process.exitCode = 1; });
}
