# Development guide

## Local gate

Use JDK 26 and the checked-in Gradle wrapper:

```bash
export JAVA_HOME="$(brew --prefix openjdk)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
./gradlew clean check treeSitterTest
```

Java compilation enables all lint warnings and treats warnings as errors. `check` runs JUnit and generates JaCoCo reports for modules with tests. `treeSitterTest` installs the pinned CLI, regenerates the parser, runs the syntax corpus, and compiles editor queries.

## Documentation check

`wheeler check-docs <file-or-directory>...` walks physical nonsymlink `.w` files in lexical path order, reads bounded strict UTF-8, prints stable `WDOC` diagnostics, and never writes source. `wheeler check-docs --stdin` checks one bounded buffer and reports it as `<stdin>`. Duplicate normalized inputs, symbolic links, malformed UTF-8, non-`.w` files, and more than 65,535 selected sources fail closed.

The implemented checker requires a first-content nonempty `//!` file summary and adjacent nonempty `///` documentation for public and Wheeler-semantic member declarations. It checks canonical facet order and the required `Effects`, `Inverse`, `Coherent`, and `Adjoint` facets. Declaration attachment uses the shared parser-owned module, type, member, and block ranges; malformed structural recovery is never mistaken for a declaration. The command does not discover configuration, phone home, or write a tasteful stub about “leveraging synergies.”

## Source formatting

`wheeler format <file-or-directory>...` formats the same bounded, strict-UTF-8, physical `.w` input set in canonical path order. It parses every selected file before publication, stages changed bytes in verified sibling files, preserves ordinary POSIX permission bits where available, and requires atomic replacement. A validation failure publishes nothing; a crash during replacement may leave a sorted prefix updated, and an idempotent rerun converges.

`wheeler format --check <file-or-directory>...` writes nothing and reports every differing path as `WFMT001`. `wheeler format --stdin` writes one formatted UTF-8 document; adding `--check` writes only a difference diagnostic. `WFMT002` reports structural parse or formatter-limit failure, `WFMT003` reports the bounded input boundary, and `WFMT004` reports publication failure.

The current stage-0 style normalizes LF and one final newline, four-space structural indentation, braces, semicolons, operators, comment markers, blank separators, and basic horizontal lists. WIP-0016's 100-scalar local line breaking and complete vertical-list table remain unimplemented; the command makes no contrary claim, however photogenic the output.

## Design workflow

Cross-cutting semantic changes begin as a [Wheeler Improvement Proposal](../proposals/README.md). Reference pages describe implemented behavior only. A WIP becomes Implemented after its acceptance tests, documentation, migration, and required deletion are complete.

## Maintenance rules

- Keep source files focused and below 1,000 lines.
- Delete replaced implementations; do not maintain parallel authorities.
- Add negative tests for every parser, verifier, capability, and lifecycle boundary.
- Prefer pure transition functions and immutable artifact models.
- Keep provider objects and credentials outside canonical bytecode and persisted language values.
- Commit and push each independently verified major feature.

## Module dependency direction

```text
wheeler-core <- wheeler-compiler
wheeler-core <- wheeler-runtime
wheeler-package
wheeler-core + compiler + runtime + package <- wheeler-tools
wheeler-core + compiler + runtime + package <- wheeler-examples tests
```

Core has no runtime dependencies. Source parsing does not depend on a provider. Quantum adapters will implement runtime contracts rather than entering language semantics.
