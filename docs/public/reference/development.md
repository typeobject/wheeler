---
title: Yard Procedures
description: Local acceptance, source formatting, manual publication, registries, and module direction.
---

# Yard Procedures

Catenary yards keep one rule above the build terminals: a successful command is an
event, and its account must name the inputs that made it possible.

## Local acceptance

Use JDK 26 and the checked-in Gradle wrapper:

```bash
export JAVA_HOME="$(brew --prefix openjdk)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
./bootstrap/gradlew -p bootstrap clean check treeSitterTest
```

Java compilation enables every `javac` lint warning and treats warnings as
errors. `check` runs JUnit, creates JaCoCo reports for tested modules, and runs
source-conformance gates. Ordinary JUnit methods have a two-minute preemptive
limit. Each worker quits after its first failure.

The complete Wheeler-owned compiler package suite is deliberate integration
evidence and does not run twice inside ordinary `tools:check` matrices:

```bash
./bootstrap/gradlew -p bootstrap :tools:nativeCompilerPackageTest
```

It executes 240 cases across 91 physical compiler modules. One fresh retained
attempt supplies execution, report, and adapter evidence. The test has a
forty-one-minute hard stop. CI runs it once on Temurin after both ordinary build
matrices finish, which keeps the long suite from starving bounded example jobs.

Hosted acceptance assigns sorted example classes to exactly one of eight shards.
Each shard has a fifteen-minute hard stop.

The complete physical compiler product rebuild is separate integration evidence:

```bash
./bootstrap/gradlew -p bootstrap :examples:closureEvidenceTest
```

Each closure method receives twenty minutes. The task stops after twenty-five.

`sourceHeaderTest` requires an appropriate opening description in every authored
Java, Wheeler, JavaScript, stylesheet, Gradle, Tree-sitter query, shell, and Python
file. `sourceLayoutTest` permits at most ten Wheeler files in one physical source
directory. Generated parser and site files are outside the authored set.

`treeSitterTest` installs the pinned CLI, regenerates the parser, runs the syntax
corpus, and compiles editor queries.

## Prose kept fit for service

Use active voice and name the actor. Instructions may address the operator as
`you`. Prefer concrete nouns, direct verbs, and stated limits. Cut repeated
conclusions, filler, and promotional language.

Public mission accounts may carry a lyrical cadence while preserving technical
meaning. Standard terms such as *adjoint*, *measurement*, and *replay* should not
be replaced for ornamental variety.

The maintained style gate rejects semicolons, en dashes, em dashes, selected
filler phrases, and obvious passive forms that hide the actor. Code retains the
punctuation required by its syntax. Mechanical checks remain narrow. Review must
still catch weak causality, repeated rhetorical forms, and jokes whose work ended
several revisions ago.

## Wheeler source comments

```text
wheeler check-docs <file-or-directory>...
wheeler check-docs --include-tests <file-or-directory>...
wheeler check-docs --stdin
```

The command walks physical nonsymlink `.w` files in canonical path order, reads
strict UTF-8, prints stable `WDOC` diagnostics, and changes no source. Directory
walks validate public package sources by default and omit the conventional
`src/test/wheeler` subtree. `--include-tests` adds that subtree. Standard input
always validates the supplied source.

Each file begins with a nonempty `//!` summary. Public declarations and
Wheeler-semantic members receive adjacent nonempty `///` text. Facets follow their
canonical order, including required `Effects`, `Inverse`, `Coherent`, and
`Adjoint` entries.

Selections may contain at most 65,535 files. Duplicate normalized paths, links,
malformed UTF-8, and non-Wheeler inputs fail.

The hosted bootstrap routes formatting, documentation checks, bundle API
extraction, and editor requests through one byte-oriented source-tooling boundary.
`SourceEditorTooling` maps its result to zero-based lines and UTF-16 characters.
It returns one scalar-aligned edit for formatting and point ranges for
parser-owned documentation diagnostics. CRLF boundaries and Unicode scalars are
never split. The hosted API does not claim the remaining Wheeler-native cutover.

## Manual bundle

```text
wheeler docs <manual-dir> --wheeler <source-dir>... -o <bundle-dir>
```

The command reads explicit physical roots, validates source comments through the
compiler export, and emits profile `wheeler-doc-bundle-4`.

The bundle contains:

- canonical manual, heading, and Wheeler API nodes.
- resolved local links and graph edges.
- navigation and search indexes.
- inert `.md` and `.mdx` source under `pages/`.
- executable results in `examples.json`.
- every emitted digest in `manifest.json`.

Publication creates a new directory through one atomic move. Existing output,
malformed source, missing titles, duplicate routes, failed examples, escaped
links, and nonphysical parents fail first.

An exact executable fence has this fixed header:

````text
```wheeler-exact name=answer output=2a
<one self-contained Wheeler module>
```
````

The name and output use lowercase canonical forms. The semantic build compiles the
module, runs two fresh machines, requires byte-identical replay, and compares the
declared output. The graph binds source, artifact, output, and result identities.
One run supplies execution evidence rather than a theorem.

Manual IDs come from logical paths without `.md` or `.mdx`. Heading IDs use
canonical suffixes when text repeats. Relative page and heading links remain
inside one manual root.

## Static site

```text
wheeler site -o <directory>
wheeler site --bundle <bundle-directory> -o <directory>
```

The first form builds a private semantic bundle from the fixed repository roots.
The second begins from an immutable bundle, allowing render retry without
regenerating semantics.

Both forms verify profile, path, and digest closure before rendering static HTML
and CSS under `wheeler.doc-site/2`. One fixed local script adds code-copy buttons.
Manual content cannot add scripts or event handlers.

Front matter supplies scalar metadata and never appears as page prose. `index.md`
and `index.mdx` own directory routes. `sidebar: false` omits one page from
navigation. An index may set `sidebar_children: false` while leaving descendants
routable and searchable.

The renderer executes neither MDX nor JSX. It has one stylesheet, no plugin or
theme graph, a restrictive content-security policy, fixed output limits, and one
atomic publication step.

`sitemap.xml` lists every HTML route and carries a content-set digest.
`publication-manifest.json` binds the input bundle, renderer classes, and every
site file. Atomic publication selects one complete userspace tree and issues no
power-loss durability receipt.

## Instruction registry

`registry/instructions.wreg` owns promoted classical instruction identities,
forms, ordered roles, and reversibility classes.

```bash
python3 bootstrap/registry/generate.py
python3 bootstrap/registry/generate.py --check
```

The first command publishes Java and Wheeler views through atomic replacement.
The second writes nothing and rejects stale output. Maintainers edit the registry,
rather than either generated view.

## Source formatting

```text
wheeler format <file-or-directory>...
wheeler format --check <file-or-directory>...
wheeler format --stdin
```

Formatting reads the same physical strict-UTF-8 source set in canonical path
order. It parses every input before staging verified sibling files and uses atomic
replacement where available.

`--check` writes nothing and reports differences as `WFMT001`. `WFMT002` reports
structural parse or formatter-limit failure, `WFMT003` reports the input boundary,
and `WFMT004` reports publication failure.

The canonical style uses LF endings, one final newline, two-space indentation,
regular braces and operators, tight unary operators, and stable blank separators. Groups remain on one
line when their normalized form fits within 100 Unicode scalar values. Longer
comma groups place each item and closing delimiter on stable lines. Long binary
expressions continue with leading operators.

Comments and indivisible literals remain unchanged. Deeply indented tokens may
cross the soft line target rather than change spelling.

## Design and maintenance

Cross-cutting semantic changes begin as Wheeler Improvement Proposals. Public
appendices describe accepted behavior. Proposals retain work that has not yet
crossed its executable gate.

Maintainers follow these rules:

- keep source files focused and below 1,000 lines.
- place at most ten Wheeler files in one physical directory.
- use the existing package and example map.
- delete replaced implementations rather than retaining two authorities.
- add negative cases at parser, verifier, capability, and lifecycle boundaries.
- prefer immutable artifact models and pure transition functions.
- keep credentials and provider objects outside canonical artifacts and persisted
  language values.
- accept each major feature through its full gate before promotion.

## Module direction

```text
bootstrap/core <- bootstrap/stage0
bootstrap/core <- bootstrap/runtime
bootstrap/package
bootstrap/core + stage0 + runtime + package <- bootstrap/tools
bootstrap/core + stage0 + runtime + package <- bootstrap/examples tests
```

All Java and Gradle files live below `bootstrap/`. There is no root Gradle project.
Bootstrap core has no runtime dependencies. Source parsing has no provider
dependency. Quantum adapters implement runtime contracts and do not define
language semantics.

The Wheeler compiler source has one home:
`wheeler-compiler/src/main/wheeler`. The package exports a `compiler` tool and an
entryless `library`. Core encoding and SHA-256 modules live under
`wheeler-core/src/main/wheeler`. The interpreter lives under
`wheeler-runtime/src/main/wheeler`. Package codecs live under
`wheeler-package/src/main/wheeler`.

Hosted bootstrap work uses two JDK distributions and compares the complete emitted
artifact trees byte for byte. This supplies host-diversity evidence for the current
stage-0 design. It does not satisfy independent diverse compilation because both
paths still descend from the same Java source.

[Bootstrap and trust](bootstrap.md) records the remaining seed and fixed-point
work.
