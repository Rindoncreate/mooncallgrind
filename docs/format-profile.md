# Callgrind 1 cost/call profile

Reference: [Valgrind format specification](https://valgrind.org/docs/manual/cl-format.html).
This is an explicit supported profile, not all Callgrind extensions.

## Accepted

- Version omitted or `version: 1`; `events:` once per part; default position `line`.
- Ordered unique `line`, `instr`, `bb` position fields and physical event fields.
- `ob`, `fl`, `fn`, `fi`, `fe`, `cob`, `cfi`/`cfl`, `cfn`, paired `calls`/cost lines.
- Separate object/file/function ID dictionaries; `fn`/`cfn` share IDs, as do all file
  aliases. Dictionaries survive parts; later definitions replace earlier definitions.
- UInt64 decimal and lowercase `0x` hexadecimal values. Positions support absolute,
  `+delta`, `-delta`, `*`, based on the corresponding previous cost-line position.
  Initial bases are zero and reset per part. Target positions use those bases without
  changing the next source-position base. Negative results and overflow fail.
- Omitted trailing event costs become zero; extra columns fail. All position columns
  are required. Call count is separate from event costs.
- Blank and `#` comment lines, including between `calls` and its cost line.
- Ordered metadata headers. `totals` is a trailer; another header after body starts a
  new part. Repeated explicit `part:` also preserves empty parts. Each part needs events.
- `summary`/`totals` are checked unsigned values and retained, not substituted for body
  costs or recomputed. They may legitimately differ from recorded self costs.

## Boundaries

`jump`, `jcnd`, unknown body directives/position fields, future versions and absent
selected physical events raise `Unsupported`, never partial success. Derived `event:`
formulas are retained as metadata but not evaluated. IDs of processes and threads are
also metadata, accessible through the owning part.

Set `fn` before costs and `cfn` before the first call in each function. A resolved callee
may be reused until the next `fn`/part. Object/file overrides are resolved when `cfn` is
read; an override alone does not redefine the callee. A pending call must be followed
by its cost line; intervening non-comment directives and EOF are syntax errors.

Outer ASCII whitespace is trimmed from strings. Comments, whitespace, original ID
spelling and unreferenced function declarations are not retained. This is a record
model, not a byte-lossless document AST. Gzip, pprof and cachegrind's separate grammar
are outside this version. Core input is a complete MoonBit String, not a byte stream.

## Limits and errors

Input: 16 Mi UTF-16 code units; line: 1 Mi; parts: 1,024; records: 200,000;
headers per part: 4,096; events: 64; IDs per namespace: 100,000. Integer tokens have
at most 20 digits after an optional `0x`. Arithmetic checks precede operations.

Resolved records have a conservative 16 Mi code-unit expansion budget, including names,
numeric columns and fixed overhead. Normalization preflights headers plus records
against another 16 Mi budget. Compact files with large name expansion may be rejected.
These are practical bounds, not exact process-memory caps or a hardened security audit.
The CLI also rejects files over 32 MiB and invalid UTF-8.

- `Syntax(line,message)`: malformed input or a corrupted supplied model.
- `Unsupported(line,message)`: a construct or metric outside this profile.
- `Resource(line,message)`: a size or UInt64 arithmetic limit.

Input line numbers are one-based; zero denotes a whole-input/API error.

## Normalization

`normalize` parses first and emits absolute decimal positions with fresh name IDs,
retaining supported records and ordered headers (`totals` is moved to the end).
It adds `part:` when absent, preserving empty boundaries, and does not recalculate
summaries, reorder events, drop recursion or merge call sites. Source line numbers
change. Re-reading must preserve supported record semantics, not original bytes.
