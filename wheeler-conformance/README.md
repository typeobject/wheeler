# Wheeler executable conformance

This package contains bounded executable subjects for compiler, verifier, runtime, package,
bootstrap, I/O, and identity conformance. These programs exist to pin bytes, transitions,
failure boundaries, and rewind behavior against stage 0. They are not alternate implementations
of the canonical libraries and they are not tutorials wearing steel-toed boots.

The package groups source by the contract under test:

- `bootstrap/` validates evidence vocabularies, closures, toolchains, and fixed-point metadata.
- `compiler/` drives native compilation, bytecode identity, canonical re-encoding, and verification.
- `crypto/` pins Wheeler-native SHA-256 behavior.
- `io/` exercises lifecycle and durability contracts.
- `packages/` validates manifests, locks, plans, archives, snapshots, and workspaces.
- `runtime/` interprets verified bounded bytecode.

Every deployable target consumes exact locked archives from `wheeler.compiler`, `wheeler.core`,
`wheeler.packages`, and `wheeler.runtime`. The package carries no private copy of those sources.
A conformance program may fail closed. It may not quietly become specification authority because
a test happened to like its output.

Run its package gate from the repository root:

```bash
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='check wheeler-conformance'
```

The Java differential harness remains quarantined under `bootstrap/examples`. That historical
Gradle module name is not exported and does not put these programs back in the example portfolio.
