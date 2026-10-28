import { open } from 'node:fs/promises';

const LIMIT = 32 * 1024 * 1024;
const CHUNK = 64 * 1024;

// Reads at most limit + 1 bytes, including if the file grows after stat().
export async function readUtf8Handle(handle, limit = LIMIT) {
  const decoder = new TextDecoder('utf-8', { fatal: true });
  const pieces = [];
  let total = 0;
  while (true) {
    const wanted = Math.min(CHUNK, limit - total + 1);
    const buffer = Buffer.allocUnsafe(wanted);
    const { bytesRead } = await handle.read(buffer, 0, wanted, null);
    if (!bytesRead) {
      pieces.push(decoder.decode());
      return pieces.join('');
    }
    total += bytesRead;
    if (total > limit) throw new Error(`Input exceeds ${limit} bytes`);
    pieces.push(decoder.decode(buffer.subarray(0, bytesRead), { stream: true }));
  }
}

export async function readUtf8File(path) {
  const handle = await open(path, 'r');
  try {
    const stat = await handle.stat();
    if (!stat.isFile()) throw new Error('Input must be a regular file');
    if (stat.size > LIMIT) throw new Error('Input exceeds 32 MiB');
    return await readUtf8Handle(handle);
  } finally {
    await handle.close();
  }
}
