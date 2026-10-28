import assert from 'node:assert/strict';
import { readUtf8Handle } from '../bin/read-input.mjs';

function source(bytes, shortRead = 65536) {
  let offset = 0;
  const requests = [];
  return {
    requests,
    async read(buffer, start, length) {
      requests.push(length);
      const count = Math.min(length, shortRead, bytes.length - offset);
      bytes.copy(buffer, start, offset, offset + count);
      offset += count;
      return { bytesRead: count };
    },
    get consumed() { return offset; },
  };
}
const bytes = Buffer.from('猫🐱\n');
const short = source(bytes, 1);
assert.equal(await readUtf8Handle(short, bytes.length), '猫🐱\n');
assert(short.requests.every(n => n > 0 && n <= 65536));
const growing = source(Buffer.alloc(200000));
await assert.rejects(readUtf8Handle(growing, 70000), /Input exceeds/);
assert.equal(growing.consumed, 70001);
assert.deepEqual(growing.requests, [65536, 4465]);
const incomplete = source(Buffer.from([0xf0, 0x9f, 0x90]), 1);
await assert.rejects(readUtf8Handle(incomplete, 10), TypeError);
assert.equal(await readUtf8Handle(source(Buffer.alloc(0)), 0), '');
console.log('Bounded input: short reads, UTF-8 boundaries, exact limit, truncated UTF-8 and growing input passed');
