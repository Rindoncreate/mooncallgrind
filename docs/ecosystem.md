# Scope, alternatives and attribution

Snapshot audit: 2026-10-23. Public index searches cannot exclude private/unindexed work,
establish worldwide absence, or guarantee initial-review acceptance.

- [moon-pprof](https://github.com/mizchi/moon-pprof/tree/7d145f742e1ffa3db73b29e714e4b64a41abf32a)
  already collects, converts, reports and compares profiles. At the audited commit its
  summary reader decodes pprof Protobuf; no Callgrind text command was found. Adding one
  there is a reasonable alternative to a separate library.
- [hotpath.mbt](https://github.com/gpui-mbt/hotpath.mbt/tree/4275312cb80bc3d6da10289bd5cb7513aa287bd7)
  measures/aggregates in-program instrumentation; the inspected API does not import files.
- [profiler-md](https://github.com/TomerAberbach/profiler-md/blob/65ecfbdabb4adcb83b99448ca5981f095393fa24/src/formats/callgrind/parse.ts)
  already parses Callgrind and creates TypeScript reports/diffs. Its aggregate model
  ignores call target positions. That is a valid report design, not an alleged defect.

The increment is an in-process MoonBit format/API layer retaining call sites, targets,
parts and exact counters across backends. It is not the first Callgrind reader, a new
profiling algorithm, or a new comparison idea. The CLI is a consumer, not the reason
to establish the library. No maintainer has promised adoption or endorsed this work.

Implementation follows the [official format](https://valgrind.org/docs/manual/cl-format.html).
[KCachegrind's loader](https://github.com/KDE/kcachegrind/blob/master/libcore/cachegrindloader.cpp)
was inspected for state semantics; its GPL source is not copied/linked. Valgrind's
separately installed `callgrind_annotate` is a CI-only independent reader.

The real HTTP fixture from moon-pprof remains Apache-2.0, with commit, checksum and
original license in `fixtures/`. Other implementation and synthetic fixtures are MIT.
AI assisted development. Generic CI export and fresh-package consumer scaffolding was
adapted from the author's previous moondhcp4; no DHCP implementation is reused here.
