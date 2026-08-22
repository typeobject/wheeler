# Wheeler executable conformance

This package contains bounded executable subjects for compiler, verifier, runtime, package,
bootstrap, I/O, and identity conformance. These programs exist to pin bytes, transitions,
failure boundaries, and rewind behavior against stage 0. They are not alternate implementations
of the canonical libraries and they are not tutorials wearing steel-toed boots.

The package groups source by the contract under test:

- `bootstrap/` validates evidence vocabularies, closures, toolchains, and fixed-point metadata.
- `compiler/` drives native compilation, bytecode identity, canonical re-encoding, and verification.
  Its module frame admits zero through seven dependencies and at most 32,768 bytes per source.
- `crypto/` pins Wheeler-native SHA-256 behavior.
- `io/` exercises lifecycle and durability contracts.
- `packages/` validates manifests, locks, plans, archives, snapshots, and workspaces.
- `runtime/` interprets verified bounded bytecode.
- `testing/` publishes runtime-owned identities, summaries, reports, outcomes, and metadata.
  `testing/runners/NativeTestRunner.w` accepts up to 64 ordered artifact cases. It checks the package, deployable target, root module, dependency-free lock, source plan, strict UTF-8 modules, acyclic ordered local imports, descriptors, and shard selection before execution.
  A one-case descriptor over one root and up to seven local imported sources may request native entry compilation with zero artifact length and `<target>::entry`. Up to 64 root tests over one root and up to seven local imports may instead use zero artifact lengths. Parameterless cases use `<target>::<declaration>`. Canonical `long` and `boolean` rows use `<target>::<declaration>[<ordinal>]`. The native source profile enforces canonical `limits(steps = N, history = N)` step bounds for both artifact modes. A sorted selected-tag frame filters canonical `tags(...)` declarations by conjunction before identity, sharding, or compilation. Unknown selected tags reject. Case-count byte 255 asks the runtime to construct, sort, compile, and execute the complete selected descriptor set without caller-supplied names or artifacts. `wheeler test` uses this mode as a mandatory summary gate for dependency-free packages with one modular test source when the conformance package is available. The native runner discovers, lowers, compiles, verifies, and executes it without a Java-supplied artifact.
  For transported artifacts, the runner discovers up to 64 root `test void` cases with the native lexer. Parameterless declarations bind `<target>::<declaration>`. Canonical `long` and `boolean` rows bind `<target>::<declaration>[<ordinal>]`. Each selected artifact is verified exactly once. The runtime binds its first function to the selected root module and discovered declaration. It also binds the synthetic entry to the exact parameter row, executes it once with fresh storage, and reduces it through the same profile-2 report path. Malformed-artifact diagnostics reuse the retained verifier outcome.

Every deployable target consumes exact locked archives from `wheeler.compiler`, `wheeler.core`,
`wheeler.packages`, and `wheeler.runtime`. The package carries no private copy of those sources.
A conformance program may fail closed. It may not quietly become specification authority because
a test happened to like its output. Test identity, shard, summary, report, and artifact-execution semantics live in `wheeler.runtime`.
The conformance entry points contain only publication effects.

Run its package gate from the repository root:

```bash
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='check wheeler-conformance'
```

The Java differential harness remains quarantined under `bootstrap/examples`. That historical
Gradle module name is not exported and does not put these programs back in the example portfolio.
