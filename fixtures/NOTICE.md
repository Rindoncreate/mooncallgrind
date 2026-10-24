# Real compatibility fixture

`http_server.callgrind` is copied unchanged from mizchi/moon-pprof:

- Source: https://github.com/mizchi/moon-pprof/blob/7d145f742e1ffa3db73b29e714e4b64a41abf32a/notes/http_server.callgrind
- Commit: `7d145f742e1ffa3db73b29e714e4b64a41abf32a`
- SHA-256: `e731d131366a4f1f485209ef2940774a37b849c8f9b1de4cbe824cb9ec21af77`
- Repository license: Apache-2.0; original license retained in `LICENSE-APACHE`.
- Producer recorded in file: Callgrind 3.22.0; one part, line positions, Ir event.

This is public profiling data used to test real compressed records. It is not
our implementation, our benchmark workload, or evidence of endorsement. No
moon-pprof parser or KCachegrind source is copied into the library.

The file's declared summary is `363764634`, while its literal self-cost body sums
to `363764636`. `tools/check_fixture.py` inventories the pinned line/Ir sample
independently. The library retains both facts; it does not "repair" the source.

`examples/two-sites.callgrind` is an original synthetic fixture under this
project's MIT license.
