# Wheeler compiler

This package owns the Wheeler-written scanner, compiler, verifier, codecs, and
package driver. The Java seed lives in [`../bootstrap/stage0`](../bootstrap/stage0).
Examples consume this package through exact locks. They do not carry compiler
copies.

Self-hosting is unfinished. Native compilation reproduces selected physical
compiler products, including complete callable bodies and their linked
executable. That is not a compiler fixed point or a Java-free recovery path.
The [status map](../docs/internal/proposals/self-hosting-status.md) owns current
coverage, identities, and open promotion requirements.

## Source ownership

All paths below are relative to `src/main/wheeler`.

| Path | Responsibility |
| --- | --- |
| `lexer` | Bounded scanning and UTF-8 coordinates |
| `compiler/frontend` | Token, structure, body, and statement products |
| `compiler/syntax` | Statement and call shapes |
| `compiler/resolution` | Typed locals, calls, operands, and scalar constants |
| `compiler/ir` | Types, statements, opcodes, instruction forms, and proof identities |
| `compiler/backend` | Local types, strings, control flow, returns, and encoding |
| `compiler/verification` | Check-before-publication artifact validation |
| `compiler/packages` | Package manifests, names, paths, semantic versions, and canonical layout |
| `compiler/closure` | Counted archive intake, module binding, scheduling, and publication |
| `compiler/closure/products` | Callable signatures, source ranges, and compiled products |
| `compiler/closure/layouts` | Aggregate, ownership, statement, loop, and local-type products |
| `compiler/closure/bodies` | Canonical function and instruction decoding |
| `compiler/closure/linking` | Counted relocation and canonical container emission |
| `compiler/graphs` | Bounded source-graph plans and differential execution |

`compiler/Core.w` lowers and verifies an already linked bounded source.
`compiler/Driver.w` provides the stateless source-graph API. `MinimalCompiler.w`
is its executable wrapper and publishes only the verified output range.

`wheeler.package.yaml`, its lock, and workspace sources define the closed build.
Generated `vendor/` trees belong to exported offline bundles, not source control.

## Counted archive route

Production closure work starts with one immutable package archive, not a list of
special-case source topologies:

1. `ArchiveSources.w` validates sorted paths, the outer identity, and every entry
   digest before publishing path and data ranges. It admits 1,024 archive entries.
2. `ModuleManifest.w` parses the canonical bootstrap graph, checks binding,
   rejects cycles, and proves rooted reachability. Graph storage admits 512 local
   modules and 3,072 imports, independently of archive capacity.
3. `ArchiveModuleSources.w` joins each module's source path and identity to an
   exact archive range. `PackageTarget.w` binds the package's `compiler` tool
   target to the bootstrap root before closure publication.
4. `ClosurePlan.w` records source ranges, import windows, dependency ranks,
   leaf-first order, and executable-owner bits. `ActiveSourceSlots.w` provides
   eight generation-checked 32,768-byte leases and destroys bytes on release.
5. `ModuleSymbols.w` and the symbol owners publish scalar declarations and
   direct-import values. Callable products retain exact signatures, body ranges,
   effects, parameter types, and loan modes without keeping dependency source.
6. Structured compilation lowers selected source bodies into canonical module
   artifacts. Archive emission consumes lexical module and class-name ranges
   from declaration products. Comments do not define another declaration identity.
   Callable-free products use the same checked source-local class-name ranges.
   Constant lookup compares lexical uses with packed names, without reconstructing
   local source offsets or reopening dependency source.
7. The linker resolves stable callable and aggregate identities, rebases code
   and type windows, deduplicates strings, and emits a verified canonical
   container before publishing its identity.

A source window remains bounded at 32,768 bytes and 4,096 scanner tokens.
`StructuredSourceTargets.w` owns imported-target buffer checks so the structured
orchestrator stays inside that token arena. Archive entry, graph, token, type,
frame, code, and artifact limits are separate contracts.

### Structured products

`SourceStatementProducts.w` owns callable statement ranges and balanced block
trees. `SourceValueProducts.w` binds prior named values and exact types.
`DirectStatementProducts.w` lowers admitted root statements. Structured loop
owners resolve signed conditions, bounded limits, nested one-arm guards,
mutations, buffer operations, and calls into source-independent rows.

Callable plans join direct and loop instruction windows in source order and
publish matching local-type windows. Aggregate owners retain nominal identities,
resolve constructors and projections, and splice aggregate instructions into
primitive body products. Temporary scalar carriers are not final nominal types.

Call matching preserves local shadowing and rejects ambiguous imports. Qualified
calls restrict matching to the written dependency. Parameter types, loan modes,
results, effects, and public visibility must agree. Imported relocations resolve
before code mutation. Verifier stubs stay outside retained callable products.

Product owners stage private work and publish measured rows and bytes, not entire
capacity-sized arenas. Canonical emission checks code, types, section extents,
proofs, and identity before caller-visible artifact publication. These checks do
not establish native lowering for every compiler body.

### Retained calls

Ordinary root and loop calls admit zero through eight ordered identifier
arguments, including qualified imports. Signed and Boolean values, UTF-8 and
byte-view loans, and mutable byte and word loans keep exact types.
`compiler/closure/layouts/source/calls/SourceCallArgumentLayouts.w` owns 256 calls and two
4,096-word argument tables. Each column holds 2,048 arguments. Binding, final
returns, typed layout, code planning, loop emission, and imported stubs use the
same profile.

A ninth argument or mismatched type rejects before publication. Filling the
argument tables does not prove simultaneous admission at every other capacity.
Generated inverses still reject argument-bearing calls. Their transfer and
cleanup inverses remain open work. This profile does not widen the separate
bounded helper compiler below.

### Package-manifest composition

`compiler/packages/manifest/words/PackageManifestWords.w` classifies fixed words by exact
length and two base-128 ASCII lanes. Token policy projects scanner ranges into
that owner. Keys, kinds, Booleans, schema version, and canonical layout share its
word codes. Polynomial hash aliases no longer impersonate canonical spellings.
Unknown words return zero. The twelve-byte vocabulary bound does not limit names,
paths, quoted values, or the language's identifiers. Lock, workspace, and snapshot
readers reuse these codes through `wheeler.packages.metadata_tokens`. Their
format-specific negative codes do not widen the compiler's fixed vocabulary.

Dependency and capability entry products own capacity checks, complete field
validation, adjacent ordering, and row publication. They return the next count
only after writing a complete accepted row. Malformed fields take precedence over
ordering. Exhausted capacity rejects before candidate work.

`compiler/packages/manifest/target/source/PackageManifestTargetSourceCollection.w` owns
source-list traversal, strict selector ordering, row publication, and existential
root coverage. Its eight-argument product admits a nonempty collection of at most
1,024 selectors. It returns the next absolute source-row index or `-1`. A rejected
collection may retain admitted row prefixes, but the parser commits no count.
The first excess selector is not published.

`PackageManifestTargetAdmission.w` joins the head, optional module, source list,
and test tail. It returns the validated test-key coordinate or `-1`. Explicitly
empty lists reject. Nonmodular targets may omit sources. The parser derives row
fields from admitted coordinates, without `TargetParse` or another result carrier.
It still owns target capacity, adjacent ordering, publication orchestration,
allocation, collection iteration, and complete manifest publication. Those
remaining composition tasks belong to
[WIP-0049](../docs/internal/proposals/WIP-0049-bounded-native-source-product-compilation.md).

## Bounded recovery compiler

The earlier bounded compiler remains a separate recovery and differential
profile. Its limits are not the retained source-product limits.

- One class may contain an entry or an entryless helper table. Libraries emit
  the canonical unqualified `$library` halt entry.
- A table admits at most twenty-three helpers and sixteen primitive parameters
  per signature. Entry and helper bodies admit at most sixty-four statements.
- Scalar value calls, void calls, and final forwarding calls admit their tested
  forms through seven arguments. Eight arguments reject on this route, even
  though signature storage has sixteen slots.
- Calls preserve exact primitive types and use canonical moves or reborrows.
  Narrow buffer, UTF-8, map, allocation, freeze, and destruction forms have
  dedicated typed resolvers. Unsupported forms publish no artifact.
- Signed fixed-array parameters admit lengths one through sixty-four, with at
  most sixteen distinct descriptor lengths.
- A contiguous block of at most 256 signed or Boolean constants may surround
  optional state but must precede helpers or the entry. Checked evaluation
  admits forward references. Cycles, unknown names, type errors, and arithmetic
  traps reject. Evaluation is bounded at 4,096 steps, sixty-four dependency
  levels, and thirty-two parenthesis levels.
- Narrow reversible signed helpers emit exact result-slot calls, forward and
  inverse bodies, and proofs. This does not provide general inverse lowering.

`frontend/helpers` owns table parsing and resolution. `HelperBody.parameterCount`
and its type column drive descriptors and code generation. Helper-kind encodings
do not recover arity. Focused call, return, intrinsic, and mutation owners keep
syntax admission separate from typed resolution and encoding.

The graph fixtures cover one through seven imports. One import links directly.
Larger fixtures use counted plans for edges, roots, reachability, visibility,
sharing, and leaf-first order. The source
table owns seven fixed 32,768-byte slots plus separate synthetic-root storage.
Replacement validates before mutation and clears stale tails. Exact repeated
private declarations and executable owners collapse once. Collisions do not.
These fixtures test the bounded executor. They do not replace the archive route
or establish general multi-file compiler lowering.

## Verification

Run commands from the repository root with the supported JDK on `PATH`.

```sh
./bootstrap/gradlew -p bootstrap :examples:test \
  --tests '*NativeCompilerPackageManifestSourceCollectionExampleTest' \
  --tests '*NativeCompilerArchiveNamesExampleTest' \
  --tests '*NativeCompilerDeclarationNamesExampleTest' \
  --tests '*NativeCompilerEmptyArchiveNamesExampleTest' \
  --tests '*NativeManifestExampleTest' --no-daemon
```

These focused tests exercise exact row cells, rejected publication, diagnostics,
capacity boundaries, rewind, and bound archive names. Name tests check complete
callable and callable-free artifacts, untouched declaration columns, and rejected
name ranges without an archive traversal. The combined physical test
also compares the complete coordinate artifact and relocated collection/tail
bodies against independent stage-0 compilation:

```sh
./bootstrap/gradlew -p bootstrap :examples:closureEvidenceTest \
  --tests '*NativeCompilerPackageManifestTargetAdmissionPhysicalProductExampleTest' \
  --tests '*NativeCompilerPackageManifestWordsPhysicalProductExampleTest' \
  --no-daemon
```

`wheeler test wheeler-compiler` runs the native package suite through the Wheeler
runtime. The package targets own its discovery and case identities. The separate
closure-evidence task compares selected physical artifacts and complete callable
bodies, links them, verifies the resulting executable, and checks execution and
identity. Run the full physical closure when compiler changes require that
integration evidence, not after every helper edit.

Changed source identities require graph/archive pin and dependent-lock updates.
Source length, header, layout, syntax, instruction-registry, documentation, and
package-portfolio gates remain required. Test fixtures and locks own exact pins.
This README is not a second evidence ledger.

## Promotion

Stage 1 must compile the complete compiler source set into a byte-identical stage
2. Promotion also requires diagnostic parity, diverse-bootstrap and provenance
evidence, and the native recovery and Java-free requirements of
[WIP-0007](../docs/internal/proposals/WIP-0007-self-hosting-compiler-and-bootstrap.md)
and [WIP-0008](../docs/internal/proposals/WIP-0008-java-free-runtime-and-native-bootstrap.md).
Selected products and a linked subset do not discharge those contracts.

New compiler behavior belongs in Wheeler. Any Java addition needs a concrete
stage-crossing reason and a deletion condition. Remove superseded implementations
and fixtures rather than keeping a compatibility path without a contract.
