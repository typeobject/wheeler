# Development guide

## Local gate

Use JDK 26 and the checked-in Gradle wrapper:

```bash
export JAVA_HOME="$(brew --prefix openjdk)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
./bootstrap/gradlew -p bootstrap clean check treeSitterTest
```

Java compilation enables every lint warning and treats warnings as errors. `check` runs JUnit, creates JaCoCo reports for modules with tests, and runs the source conformance gates.

`sourceHeaderTest` requires each authored Java, Wheeler, JavaScript, stylesheet, Gradle, Tree-sitter query, shell, and Python file to begin with a suitable documentation comment. `sourceLayoutTest` allows no more than ten Wheeler files in one physical source directory. Generated parser and website files are not part of the authored set.

`treeSitterTest` installs the pinned CLI, regenerates the parser, runs the syntax corpus, and compiles the editor queries.

## Documentation check

`wheeler check-docs <file-or-directory>...` walks physical, nonsymlink `.w` files in lexical path order. It reads bounded strict UTF-8, prints stable `WDOC` diagnostics, and never changes source files.

`wheeler check-docs --stdin` checks one bounded buffer and reports its name as `<stdin>`. Duplicate normalized inputs, symbolic links, malformed UTF-8, non-`.w` files, and selections larger than 65,535 sources fail closed.

The current checker requires a nonempty `//!` file summary as the first content; it also requires adjacent, nonempty `///` documentation for public declarations and Wheeler-semantic members.

The checker verifies canonical facet order and the required `Effects`, `Inverse`, `Coherent`, and `Adjoint` facets. Declaration attachment comes from parser-owned module, type, member, and block ranges. Parser recovery nodes never count as valid declarations.

The command does not read configuration, use the network, or create placeholder text. The same parser boundary exports module identity and selected declaration details for the stage-0 documentation bundle. Those details include kind, name, source position, modifiers, summary, and ordered facets; a renderer consumes this model but cannot redefine what the source declares.

## Documentation bundle

`wheeler docs <manual-dir> --wheeler <source-dir>... -o <bundle-dir>` builds a renderer-neutral stage-0 bundle from explicit physical roots. Inputs must be strict UTF-8, nonsymlink files chosen in logical-path order.

The command validates Wheeler `//!` and `///` documentation through the compiler export; it then emits sorted manual, heading, and Wheeler API nodes. Explicit `manual:` and `wheeler:` links, along with root-contained relative Markdown links, become canonical edges.

The bundle includes navigation and search indexes, inert Markdown under `pages/`, and a digest for every emitted file in `manifest.json`. Publication creates a new directory with one required atomic move.

Existing destinations, malformed source, missing manual titles, duplicate node identities, links in the input tree, and nonphysical parents all fail before publication.

The current profile is `wheeler-doc-bundle-2`. Profile 2 adds semantic heading nodes and relative page or heading edges. It does not change profile 1 in place.

Manual IDs come from logical paths. Heading text produces canonical heading IDs with deterministic suffixes for duplicates; Wheeler IDs use module or source identity plus the declaration name.

Relative links to `.md` pages and canonical `#heading` anchors resolve only within the manual root. Escapes, missing targets, and noncanonical anchors fail. Repository source links remain normal site links instead of semantic manual edges.

`wheeler site -o <directory>` is the only website command. It finds the fixed repository roots and builds the semantic bundle in private staging. Next, it verifies the exact profile, path, and digest closure. It renders the inert Markdown subset as static HTML and CSS under `wheeler.doc-site/1`.

Scalar MDX-style front matter becomes bounded metadata and is never printed as page text. The renderer does not execute MDX or JSX.

Navigation uses one fixed order: Manual, Reference, Proposals, then Future. Overview pages come first, and the proposal template stays out of the sidebar. The profile has one stylesheet, no scripts, no themes, no plugins, a restrictive content security policy, bounded output, and one atomic publication step.

`sitemap.xml` comes from every generated HTML route and includes a deterministic content-set digest; a page edit changes the sitemap without adding build time to the semantic inputs.

`publication-manifest.json` binds the bundle, renderer classes, and every site file. Existing output is rejected. Atomic publication prevents a partial tree from becoming the selected tree. It is not a [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md) data or namespace durability receipt.

Java doclet nodes, executable examples, proof references, and generated reference tables remain part of WIP-0019. The current Java generator and renderer are stage-0 tools. WIP-0019 requires a Wheeler-written generator to reproduce the same bundle bytes before the Java implementation can be removed.

## Source formatting

`wheeler format <file-or-directory>...` formats the same bounded, strict-UTF-8, physical `.w` input set in canonical path order. It parses every selected file before publication and stages changed bytes in verified sibling files. Where available, it keeps ordinary POSIX permission bits and requires atomic replacement.

A validation failure publishes nothing. A crash during replacement may leave a sorted prefix updated, but running the idempotent command again converges. Atomic replacement controls visibility; it does not prove durable data or namespace state.

`wheeler format --check <file-or-directory>...` writes nothing and reports each differing path as `WFMT001`. `wheeler format --stdin` writes one formatted UTF-8 document. Adding `--check` writes only a difference diagnostic.

`WFMT002` reports a structural parse or formatter-limit failure. `WFMT003` covers the bounded input boundary, and `WFMT004` reports publication failure.

The current stage-0 style normalizes LF line endings, one final newline, two-space indentation, braces, semicolons, operators, comment markers, and blank separators. Module declarations and complete import groups each get one following blank line. Named declarations have one blank line between them.

A finished conditional, loop, match, or `reverse` block gets one blank line before another statement in the same block. It gets no blank line before its closing brace, an `else`, or the next `case`.

A parameter, argument, or record group stays on one line only when its full normalized form fits within 100 Unicode scalar values. Otherwise, each comma item and the closing delimiter get stable lines.

Long binary expressions continue with leading operators at one fixed extra indent. Comments and indivisible literals stay unchanged instead of being wrapped. Bounded-loop headers and the remaining syntax-owned break rules are still WIP-0016 work.

## Design workflow

Cross-cutting semantic changes start as a [Wheeler Improvement Proposal](../proposals/README.md). Reference pages describe behavior that exists now. A WIP becomes Implemented only after its tests, documentation, migration, and required cleanup are complete.

## Maintenance rules

- Keep source files focused and under 1,000 lines.
- Group Wheeler files by concern, with at most ten files in one physical directory.
- Use the current compiler, package, and example directory map. `misc` is not a concern.
- Delete replaced implementations instead of keeping two authorities.
- Add negative tests for every parser, verifier, capability, and lifecycle boundary.
- Prefer pure transition functions and immutable artifact models.
- Keep provider objects and credentials out of canonical bytecode and persisted language values.
- Commit and push each independently verified major feature.

## Module dependency direction

```text
bootstrap/core <- bootstrap/stage0
bootstrap/core <- bootstrap/runtime
bootstrap/package
bootstrap/core + stage0 + runtime + package <- bootstrap/tools
bootstrap/core + stage0 + runtime + package <- bootstrap/examples tests
```

All Java and Gradle files live below `bootstrap/`. There is no root Gradle project, and canonical Wheeler packages contain no Java source. Run the gate with `./bootstrap/gradlew -p bootstrap ...`.

Bootstrap core has no runtime dependencies. Source parsing does not depend on a provider. Quantum adapters implement runtime contracts and do not define language semantics.

The Wheeler compiler source has one home: `wheeler-compiler/src/main/wheeler`. Its package exposes a `compiler` tool and an entryless `library`.

`wheeler-examples` uses that library through its exact committed lock. Workspace commands rebuild the matching archive from the canonical compiler member in memory, and tests resolve source fixtures through that root. The examples tree keeps no duplicate compiler source.

The first allocation-free library, binary-encoding, and SHA-256 modules live only under `wheeler-core/src/main/wheeler`. `wheeler.compiler`, `WorkQueue.w`, and other consumers reach them through the lock-verified `wheeler.core` workspace archive.

The bounded interpreter follows the same rule under `wheeler-runtime/src/main/wheeler`, where it locks compiler verification and core primitives. Package codecs live under `wheeler-package/src/main/wheeler`. Its entryless `wheeler.packages` library uses core SHA-256, while the examples contain only executable consumers.

Hosted bootstrap CI builds the full workspace with both Temurin and Zulu JDK 26. It verifies each emitted `.wbc`, writes a canonical `wheeler.artifact-set/1` manifest inside each closed output tree, and compares the downloaded trees byte for byte.

`wheeler manifest-artifacts <directory>` rejects empty, malformed, oversized, changing, symbolic, special, or unmanifested inputs. It then replaces one manifest atomically. This provides host-diversity evidence, but it is not the full diverse double compilation required by WIP-0007 because both paths still use the same Java source design.

Later, `bootstrap/stage0` will compile the exact compiler package into stage 1, and stage 1 will compile it into stage 2. Byte-identical stages prove a fixed point, though they do not prove a safe ancestry.

Recovery-seed promotion also needs WIP-0007's diverse compilation path, full provenance, and a comparison made before any candidate-produced code runs. `wheeler bootstrap-manifest` performs the bounded byte comparisons and writes canonical `wheeler.bootstrap.yaml` atomically. It rejects unequal stages, different diagnostics, duplicate compiler identities, and stale acceptance trees.

The [bootstrap evidence reference](bootstrap.md) defines every bound identity and the remaining pipeline-order requirement.
