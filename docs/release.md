# Source release preparation

CI produces `Rindoncreate-mooncallgrind-0.1.0.zip`, a SHA-256 checksum and a release
manifest containing the exact Git source commit. They are retained together as the
`mooncallgrind-source-<commit>` workflow artifact after all checks pass. The GitHub
artifact download is an outer ZIP containing the actual MoonBit source ZIP; use the
inner source ZIP for the package, not the artifact wrapper.

The package is extracted into a fresh workspace, its MoonBit consumer is compiled on
JS/native, and the JS bridge is rebuilt from packaged source before running the CLI.
The package retains original and third-party licenses, fixtures and documentation.
No compiled bridge from the checkout is used to prove packaged CLI functionality.

```sh
moon package
python3 tools/check_consumer.py
python3 tools/check_release.py
```

These commands prepare and verify a source archive; they do not publish to Mooncakes.
The CI workflow contains no publishing credentials or automatic publication action.
Published versions should be treated as immutable; inspect this exact version before
authorizing a registry upload. Formal competition submission is a separate step.

After authorized publication, run the following in an environment with MoonBit,
Node and a native C compiler:

```sh
python3 tools/check_registry.py
```

This creates a temporary independent module pinned to
`Rindoncreate/mooncallgrind@0.1.0`, fetches it from the registry and checks targets,
callee context, normalization and exact counters on JS/native. There is no sibling
workspace member, archive extraction or local fallback. **Until it has run successfully
after publication, registry installation is unverified.** This script is deliberately
not a required CI step while version 0.1.0 remains an unpublished candidate.
