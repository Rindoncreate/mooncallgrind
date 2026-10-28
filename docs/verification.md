# Verification and reproduction

Verified toolchain: moon/moonrun `0.1.20261023` (`3778465`), moonc
`v0.10.17+d971670cd`, Linux x86-64. CI installs the official toolchain and records its
version; compiler updates require revalidation. Node CI is 24; local Windows smoke
uses Node 24.19.0. The user's Windows application-control policy blocks MoonBit
binaries; compilation uses GitHub Linux runners without bypassing that policy.

## Checks

```sh
for target in js wasm wasm-gc native; do
  moon check --target "$target" --deny-warn
  moon build --target "$target" --deny-warn
  moon test --target "$target" --deny-warn
done
moon run examples/sites --target js
moon run examples/sites --target native
node tools/check_cli.mjs
node tools/check_input.mjs
moon package
python3 tools/check_consumer.py
```

15 core tests cover exact UInt64 values/overflow, relative positions, shared name
dictionaries, two call sites and different targets, recursion, inline files, per-part
event order, normalization semantics/idempotence, empty parts, malformed input,
resource limits, callee overrides across self costs, canonical `instr bb line` ordering,
and corrupt public-model indices. A deterministic corpus of 400
generated inputs is inside one test, not 400 independent coverage claims. No fuzzing
campaign or percentage coverage is claimed.

The CLI check executes real subprocess commands for inspect/totals/normalize/diff,
compares records, checks invalid UTF-8, UInt64 JSON strings and refusal to overwrite.
Bounded-input tests cover partial reads, multibyte UTF-8 split across chunks, exact
limits, truncated UTF-8 and growth after a size check. Over-limit regular files are
rejected before loading their contents; the reader also enforces the cap while reading.
`examples/sites` prints both sites using the public MoonBit model.

The source-package consumer unpacks `moon package` into a fresh workspace and compiles
a separate module on JS and native. It proves distinct target positions and >2^53
counters survive public API use. Its output includes dependency tests as well as its
one consumer test. This does not establish a Mooncakes registry install.
The ZIP is separately extracted outside that workspace and the bridge is rebuilt
before running the packaged CLI, so workspace artifact paths cannot mask missing files.

## Independent compatibility checks (Linux with Valgrind installed)

```sh
sha256sum -c fixtures/SHA256SUMS
python3 tools/check_fixture.py
node tools/check_reference.mjs
```

`callgrind_annotate` 3.22.0 reads original and normalized synthetic/real files; the
test compares the function-self-cost rows it emits with identical settings. The
callee-state fixture additionally compares inclusive calling-tree rows, detecting
wrong target file/object assignment through intervening self costs. Its
thresholded report is not a complete proof of every target position, jump extension,
producer or file size. Target positions are checked through typed record tests.

The real public HTTP fixture has 12,205 cost records and 2,072 calls. An independent,
limited Python body inventory gives self Ir `363764636`; the file declares summary
`363764634`, also shown as PROGRAM TOTALS by Valgrind. Both are retained and tested
separately. No forced equality or alteration of the upstream data is appropriate.

This is interoperability with an existing reader, not independent demand or adoption.
The only real producer fixture is Callgrind 3.22.0, line/Ir, one part. Multievent and
instruction positions currently use synthetic tests. Other backend tests execute the
same core suite; the real-file CLI/reference checks run the JS backend.

## Development transport

`tools/export_ci.py` exports an exact public source/build allowlist to the CI log so
the Windows workspace can inspect formatted sources and generated JS. It does not
export credentials or environment variables. `receive_ci.py` bounds decompression,
checks paths against the allowlist and writes only inside this project; it executes
none of the imported paths. Check the job's exact source SHA before importing.

This transport is development tooling, not part of the library API or adoption evidence.

Successful CI retains the tested source ZIP, SHA-256 and source-commit manifest;
see [release preparation](release.md). Registry verification is prepared but must be
run only after the candidate is published; it is not claimed by the source-package tests.
