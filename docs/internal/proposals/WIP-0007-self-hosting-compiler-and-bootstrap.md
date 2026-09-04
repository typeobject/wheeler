# WIP-0007: Self-hosting compiler and reproducible bootstrap

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler language, compiler, bytecode, and runtime maintainers |
| Created | 2026-07-17 |
| Updated | 2026-09-04 |
| Area | Compiler, bootstrap, language profile, trusted computing base |
| Depends on | WIP-0001, WIP-0005, WIP-0006, WIP-0017 |
| Supersedes | None |
| Superseded by | None |

## Summary

The production Wheeler compiler will be written in Wheeler. All Java source and Gradle files stay under top-level `bootstrap/`. Those modules are temporary stage-0 tools and conformance oracles. They are not permanent dependencies or a second production implementation.

Stage 1 compiles the compiler into stage 2. A successful bootstrap requires the canonical stage-1 and stage-2 `.wbc` artifacts to match byte for byte. WIP-0008 then moves normal execution and builds to a native Wheeler toolchain and removes Java.

This goal shapes the language and VM now. A compiler needs typed locals, records, tagged variants, bounded sequences, strings, bytes, deterministic maps, control flow, modules, result values, and explicit file effects. Wheeler must provide those tools without importing the JVM object model or exception rules.

The compiler emits Wheeler's shared typed IR. Classical code keeps inverse, log, and barrier behavior. WIP-0002 quantum regions stay semantic and backend-neutral. OpenQASM, LLVM, native objects, and provider payloads remain derived output. Every new facility must preserve ownership, effects, inverse or adjoint relations, bounds, canonical bytecode, and quantum lowering.

## Motivation

A compiler maintained only in Java leaves Wheeler's most important program outside Wheeler. It also lets Java collection order, object behavior, Unicode handling, and exceptions leak into the language by accident.

Self-hosting tests the full system. It shows that Wheeler can express a large deterministic program, produce its own artifacts, and run useful classical workloads. Reproducible stages also expose compiler drift. Matching examples alone is not enough evidence that two compilers agree.

Bootstrap work cannot wait until the end as a source translation. Choices about locals, allocation, effects, modules, diagnostics, and bytecode order determine whether a compiler can be written at all. Wheeler therefore grows its source profile around a real compiler from the start.

## Use cases

### Cold bootstrap

A clean checkout uses the pinned stage-0 path to compile the Wheeler compiler sources. The resulting stage-1 compiler runs on the Wheeler VM and compiles the same sources. The build compares stage 1 and stage 2 and fails on any byte difference.

### Normal development

After the first reproducible bootstrap, ordinary compiler development runs the pinned stage-1 `.wbc` compiler. During migration, a stage-0 rebuild remains an explicit trust operation. After WIP-0008 cutover, cold builds use the prior native Wheeler recovery release and do not invoke Java.

### Cross-runtime validation

The same compiler artifact runs on the reference VM and any conforming independent VM. Both produce identical `.wbc` output and stable diagnostics for the conformance corpus.

### Quantum compilation

The self-hosted compiler emits canonical WIP-0002 region IR. OpenQASM and later target formats remain downstream derivations. The compiler does not need provider SDK objects or network access.

## Goals

- Make the production lexer, parser, semantic analysis, lowering, verifier front end, and artifact writer Wheeler code.
- Define a minimal general-purpose classical profile sufficient for compiler construction.
- Make all compiler data structures and iteration orders deterministic and bounded.
- Produce byte-identical stage-1 and stage-2 artifacts from identical inputs and options.
- Keep source diagnostics stable across bootstrap stages.
- Expose source reads and artifact writes as explicit host capabilities instead of ambient Java APIs.
- Retire the Java source compiler after the Wheeler compiler and a recovery seed are proven.
- Keep one source-language authority and one canonical `.wbc` writer contract throughout migration.

## Non-goals

- Reimplement Gradle, Git, Tree-sitter, provider SDKs, or the documentation site in Wheeler.
- Require all compiler operations to be logically reversible.
- Copy the Java class library, garbage collector, reflection, exceptions, or hash collection semantics.
- Make compiler execution depend on quantum hardware.
- Claim a diverse double bootstrap proves the absence of a malicious seed.
- Preserve stage-0 implementation internals as public compiler APIs.

## Terms and invariants

**Stage 0** is the temporary host implementation used to seed the first Wheeler compiler artifact.

**Stage 1** is the compiler artifact produced by stage 0 from the canonical Wheeler compiler sources.

**Stage 2** is the artifact produced when stage 1 compiles those same sources with the same declared options.

A **bootstrap-fixed point** exists when stage 1 and stage 2 are byte-identical. Debug paths, timestamps, map iteration order, host locale, process identity, and filesystem enumeration order cannot enter canonical output.

The **recovery seed** is a reviewed, content-addressed `.wbc` compiler artifact plus source and build identity. It permits a cold build after stage 0 is deleted. It is generated, not hand-edited.

The following invariants are mandatory:

1. One canonical source tree produces both bootstrap stages.
2. Stage 0 and the self-hosted compiler consume the same specified language, not overlapping dialects.
3. Stage 0 cannot emit privileged bytecode unavailable to the normal artifact writer.
4. Compiler input order, symbol order, constant order, diagnostics, and artifact bytes are deterministic.
5. A failed or resource-exhausted compilation emits no partial canonical artifact.
6. Unknown bytecode or source constructs fail closed at every stage.
7. Stage-0 Java code and Gradle machinery remain below `bootstrap/`. Canonical Wheeler packages contain no Java source or build file.
8. Fixed-point equality is reproducibility evidence, not proof that the seed is benign.
9. Recovery-seed promotion requires diverse double-compilation evidence from an independently derived trusted path plus the ordinary fixed point.
10. The candidate seed is not executed in the diverse path before its output has been compared with the trusted derivation.
11. Every seed records exact provenance and a routinely tested source-reproduction command.
12. Bootstrap binaries are minimized. No convenience binary enters the required chain merely because it is content-addressed.
13. The build driver has an alternate bootstrap path and never requires an opaque copy of itself.

## Auditable bootstrap chain

Wheeler follows the bootstrappable-build rule: every required seed has a source-correspondence story. The repository minimizes opaque bootstrap binaries rather than renaming them as releases. A seed record names the exact source revision, build command, builder, closed dependency set, normalized environment, and produced identity. A reviewer must be able to walk that record to an older reproducible seed or to the independently maintained stage-0 source implementation.

The Java stage 0 is deliberately small, unoptimized, and exercised on every compiler build. It remains a real alternate implementation until a smaller source-bootstrap path replaces it. A checked-in `.wbc` file without provenance cannot become bootstrap authority. A downloaded host compiler is admissible only as a declared seed whose origin and reproduction procedure are recorded. A URL and checksum establish transport identity, not source correspondence.

Ordinary fixed-point, diverse double compilation, and seed traceability answer different questions. The fixed point detects drift. Diverse compilation challenges one compiler lineage. The seed chain lets distributors and users reproduce each binary generation from source. Promotion requires all three. CI must publish the machine-readable chain and execute the documented cold-build command routinely, because an untested bootstrap path is archival fiction.

This rule applies to the build driver too. The production build system must have a minimal bootstrap path that does not require itself. Before Java and Gradle are removed, WIP-0009 must provide a bounded launcher or script path from the recovery release to the first current `wheeler` build tool.

## Bootstrap language profile

The self-hosting profile extends WIP-0005 in complete vertical slices.

### Values and types

The required value set is:

- `bool`, signed fixed-width integers, Unicode scalar values, and finite floating-point values where quantum angles require them.
- immutable `String` and mutable bounded `byte[]` or an equivalent byte builder.
- fixed and growable bounded sequences with explicit element types.
- value records for tokens, source spans, declarations, instructions, and diagnostics.
- tagged variants for token, expression, statement, type, opcode, and result alternatives.
- WIP-0041 `Slot<T>` for explicit presence and `Result<T, E>` for recoverable failure, with no ambient null or host exceptions.
- deterministic insertion-ordered or sorted maps whose order is specified.

Reference identity is not part of value equality unless a later ownership WIP adds it explicitly. Hash randomization cannot affect semantic iteration.

### Functions and control flow

The required executable profile includes typed parameters and returns, local bindings, lexical blocks, `if`, bounded `while` and `for`, exhaustive variant selection, `break`, `continue`, and early result return. Recursion is permitted only under configured stack and step limits.

Pure, ordinary, `rev`, and `coherent rev` functions remain distinct. Compiler code is primarily ordinary deterministic classical code. Reversible containers and transformations may be used where useful, but allocation, diagnostics, and file effects are not mislabeled as intrinsic inverses.

### Storage and ownership

The VM needs typed stack/local slots and a bounded heap or region store. Allocation is an ordinary effect with explicit failure. Immutable values may share storage. Mutable values have statically checked ownership or copying rules. Raw host pointers and JVM objects never enter Wheeler state or `.wbc`.

The first collector may reclaim an entire compilation region at run completion. General tracing collection is not a prerequisite if region and memory limits make compiler execution practical.

### Modules and effects

Compiler sources require modules, imports, private declarations, and explicit exported entry points. Module resolution uses the WIP-0009 canonical package manifest and normalized logical paths. It never depends on directory enumeration order.

The compiler entry receives bounded `SourceInput` values and `CompilerOptions` and returns an `Artifact` or diagnostics. A launcher owns filesystem access. Reads and writes are explicit effects with normalized bytes, declared encoding, size ceilings, and atomic output replacement.

## Compiler architecture

The self-hosted compiler is split by semantic ownership:

1. The `source` stage decodes UTF-8, records scalar offsets, and produces source spans.
2. The `lex` stage produces a bounded token stream without semantic name lookup.
3. The `parse` stage builds the accepted syntax tree and recovers only at specified synchronization tokens.
4. The `resolve` stage constructs deterministic symbol tables and module identities.
5. The `check` stage enforces types, effects, reversibility, affine resources, and target-independent quantum rules.
6. The `lower` stage emits canonical classical bodies, quantum regions, and hybrid workflows.
7. The `verify` stage checks the in-memory artifact before serialization.
8. The `encode` stage writes WIP-0001 `.wbc` sections in canonical order.
9. The `driver` stage owns options, diagnostics, limits, and all-or-nothing output.

These are Wheeler modules, not host extension points. Stage 0 follows the same boundaries while it exists so each module can be replaced and compared independently.

The parser remains hand-written and deterministic unless another implementation proves simpler. Tree-sitter is editor tooling and a differential syntax oracle. It is not linked into the production compiler.

### Incubation and promotion

`wheeler-conformance` is the executable proving ground for Wheeler-written compiler, verifier, runtime, package, and bootstrap slices. Stage 0 can compile, package-select, run, rewind, and compare those programs without filing them beside tutorials. Accepted implementations still move into their canonical library packages. A conformance probe is evidence, not build authority. `wheeler-examples` now contains only programs intended to teach or demonstrate the language.

Promotion starts when the modules expose one bounded source-set, options, and result API. They must own stable diagnostics, compile the `Counter.w` milestone, pass Wheeler verification, and execute successfully. They also need an explicit package target with no example-only dependency.

The accepted source set then moves into the canonical compiler tool package as one change. Manifests, tests, documentation links, and bootstrap scripts move with it. The old example targets and module paths are deleted. After that, checked-in examples use the pinned compiler package like any other client.

Later phases follow the same rule. A lexer, verifier, interpreter, or encoder may begin as an independent example module. Once its package boundary is accepted, only one implementation remains authoritative.

## Reversibility and effects

Self-hosting does not imply that compilation is physically or logically reversible. Parsing allocates, diagnostics observe malformed input, and artifact writing is external I/O. These operations use ordinary, checked, logged, or barrier semantics as appropriate.

Reversible compiler functions still obey WIP-0001. A data transformation marked `rev` must have a generated or checked inverse. Dropping an arena, reporting a diagnostic, or replacing an output file cannot appear inside such a function only because the whole compiler can be rerun.

A compilation transaction writes output only after parse, check, lower, verify, and encoding succeed. Abort discards the private output buffer and arena. Replacing a prior filesystem artifact is an explicit atomic host effect, not VM rewind.

WIP-0032 exclusively owns the launcher's I/O request and completion API. The compiler library continues to consume bounded owned inputs and produce an owned artifact or diagnostics. It does not discover files or grow a compiler-specific stream/future family. Atomic output replacement establishes no data or namespace durability without an exact receipt.

## Determinism and canonical output

Canonical compilation fixes:

- UTF-8 decoding and malformed-input behavior.
- line, column, and scalar-offset accounting.
- module and source ordering.
- symbol, function, region, constant, and section ordering.
- integer and floating-point literal conversion.
- diagnostic ordering and stable codes.
- compiler options and feature profile identity.
- `.wbc` reserved bytes, padding, and checksums.

Parallel analysis may be added later, but task completion order cannot affect diagnostics or output. The fixed-point comparison excludes no canonical section. If source maps include logical source identities, those identities must also match.

## Bootstrap procedure

The build executes these steps:

1. Compile the canonical Wheeler compiler source set with stage 0 to `compiler-stage1.wbc`.
2. Run stage 1 on the same source manifest and options to produce `compiler-stage2.wbc`.
3. Compare complete artifacts byte for byte and report the first differing section on failure.
4. Compile the conformance examples with both stages and compare artifacts and diagnostics.
5. Run the stage-2 artifact through the compiler acceptance suite.
6. Rebuild the stage-0 seed or stage-1 compiler through an independently derived trusted path and perform diverse double compilation of the canonical Wheeler compiler sources.
7. Compare the complete diverse output with the ordinary stage-1 artifact before executing the candidate output.
8. Publish the stage-2 content identity, diverse evidence, and build manifest as the next recovery-seed candidate.

`wheeler bootstrap-manifest` implements the final fail-closed comparison and evidence codec. It reads only bounded physical files. It requires a canonical source archive, lock, stage artifacts, and closed acceptance artifacts. It compares stage 1, stage 2, diverse output, and diagnostics before publication. It then emits schema-2 `wheeler.bootstrap.yaml` atomically. The exact schema and command contract live in the [bootstrap evidence reference](../../public/reference/bootstrap.md). The command never executes the candidate. CI must still order candidate acceptance after diverse comparison. The YAML file records evidence, but it does not prove that CI ran the steps in the required order.

A seed update is reviewed like source code. CI rebuilds from the prior seed, proves the new fixed point, and verifies diverse evidence before accepting it.

## Trusting trust and diverse bootstrap

A stage-1/stage-2 fixed point answers one question: does this compiler reproduce itself from the declared inputs? It does not show that the seed matches the source. A compromised seed could insert hidden behavior and reproduce it in later stages.

Recovery-seed promotion therefore follows diverse double compilation:

1. choose a trusted compiler derivation independent of the candidate seed. An earlier independently reproduced Wheeler seed, a separately reviewed stage-0 implementation, or a separately sourced host toolchain capable of rebuilding the Java seed.
2. bind that toolchain, its complete inputs, verifier, options, and limits into the bootstrap manifest.
3. compile the canonical source without first executing candidate-produced code.
4. compare complete canonical artifacts and diagnostics against the ordinary bootstrap path.
5. only after equality may the candidate execute the acceptance suite and become a seed candidate.

Two vendor labels on binaries built from one opaque lineage do not constitute diversity. The evidence records hashes and provenance instead of a reassuring string such as `different=true`. Diverse agreement still leaves hardware, firmware, the chosen trusted path, and review in the trusted computing base. This WIP makes that trust inspectable and smaller instead of claiming its abolition.

The strict independent bytecode verifier is part of both paths. It prevents either compiler from granting itself malformed or privileged opcodes, but it cannot prove source correspondence. Fixed point, differential conformance, verifier acceptance, source review, reproducible host builds, and diverse double compilation are complementary gates.

## Safety and limits

Every compiler phase has declared source-byte, token, nesting, declaration, symbol, instruction, diagnostic, heap-byte, stack-depth, and step limits. Arithmetic used for sizes and offsets is checked. Decoders reject overlong, truncated, duplicate, cyclic, and unknown required records.

The launcher grants read-only source inputs and one atomic artifact destination. Compiler code receives no credentials, network capability, ambient environment map, clock, random source, or unrestricted filesystem path.

## Migration and deletion

1. Freeze the current Java stage-0 profile and document its accepted grammar as the bootstrap baseline.
2. Add typed parameters, returns, locals, conditionals, bounded loops, records, variants, strings, bytes, and deterministic collections in vertical parser-to-VM slices.
3. Add module manifests and explicit source/artifact effects.
4. Implement `.wbc` and proof-certificate decoding and encoding in Wheeler and compare them against stage 0.
5. Port lexer and parser, then resolution, checking, lowering, verification, and the driver in executable example slices.
6. Promote the accepted source set by moving it into the canonical compiler tool package. Move manifests, tests, and documentation and delete the superseded targets from the conformance package in the same series.
7. Produce stage 1 and stage 2. Require fixed-point and differential conformance tests in CI.
8. Switch ordinary builds to the Wheeler compiler artifact.
9. Delete the Java lexer, parser, source model, lowerers, and artifact-generation path as part of the WIP-0008 no-Java cutover.
10. Retain only the pinned `.wbc` recovery seed, native Wheeler launcher, and generation provenance. Do not retain a parallel Java compiler or VM.

## Progress

The [self-hosting status map](self-hosting-status.md) owns current cross-proposal
progress and points to executable inventories. The [compiler](catalog/compiler.md),
[manifest](catalog/manifests.md), and [native testing](catalog/testing.md) catalogs
retain the individual implementation records. Their measured subsets do not
close this WIP's whole-compiler acceptance gate.

### Established substrate

- [x] Java and Gradle stay under `bootstrap/`. The canonical compiler, runtime,
  and shared codecs live in separate Wheeler packages with exact manifests and locks.
- [x] Stage 0 emits canonical `.wbc` and links the accepted typed classical profile.
  CI compares complete workspace artifact trees across independent JDK distributions.
  This is host-diversity evidence, not diverse double compilation.
- [x] Bootstrap evidence codecs bind source, graph, archive, lock, feature, options,
  limits, toolchain, artifact, and diagnostic identities. They reject false stage
  equality and partial publication. No completed compiler bootstrap manifest exists.
- [x] The accepted substrate provides typed frames, bounded control flow, records,
  variants, arrays, slices, affine regions, word/byte buffers, UTF-8, signed maps,
  primitive owner returns, and exact imported visibility.
- [x] Wheeler lexer, scalar compiler, verifier, codec, interpreter, and SHA-256
  slices have differential evidence. `Counter.w` compiles byte for byte, executes
  its inverse, and passes verification. This is a bounded profile, not full grammar parity.
- [x] Counted physical source products and identity-based relocations feed a verified
  linked subset. Direct products preserve scalar types, borrowed operations, result
  slots, generated inverses, and proof rows within their admitted forms.
- [x] The compiler package has native source-backed cases with deterministic shard
  selection, fresh execution storage, canonical rows, and report identities.
- [x] A bounded scalar AOT profile runs verified, capsule-bound WBC on x86-64 Linux.
  Stage 0 still owns that backend. It is not the self-hosted compiler or full runtime.

### Remaining integration

- [ ] Compile every physical compiler module from local source and counted dependency
  products through WIP-0044 through WIP-0049, WIP-0051, and WIP-0054.
- [ ] Compile the complete accepted example and negative corpus with Wheeler semantic
  analysis and lowering. Match canonical artifacts and stable diagnostics.
- [ ] Produce byte-identical stage-1 and stage-2 compiler artifacts and compare the
  independent diverse derivation before candidate acceptance.
- [ ] Switch ordinary builds to the proven compiler and complete Java deletion with
  WIP-0008. Preserve a reproducible source-to-seed recovery path under WIP-0053.

## Testing and acceptance

- [ ] Stage 1 and stage 2 `.wbc` artifacts are byte-identical in clean CI.
- [ ] Stage 0, stage 1, and stage 2 produce identical artifacts for every accepted example.
- [ ] All stages produce the same stable diagnostics for the negative corpus.
- [x] Canonical CI reproduces the alternate stage 0, builds the complete workspace, and emits the same verified artifact tree under Temurin and Zulu JDK 26 on separate clean workers. The final job compares every output byte before accepting the run, and build identities exclude checkout paths.
- [x] Thirty-two deterministic pseudo-random whitespace, line-comment, and block-comment layouts reproduce the baseline source-map-free artifact bytes in stage 0 and the Wheeler compiler.
- [ ] Deterministic collection tests vary insertion history and host hash seeds.
- [x] The accepted compiler profile enforces source, token, statement, local, function, call, recursion, arena, artifact, output, history, and transition ceilings before publication. Boundary and first-excess fixtures require untouched output after failure. Wider closure profiles retain their own explicit bounds.
- [x] The accepted shared corpus rejects malformed UTF-8, signed literal overflow, excessive structured nesting, cyclic imports, duplicate or ambiguous symbols, and malformed bytecode before output. Stage 0 and the Wheeler verifier or compiler agree on acceptance and atomic failure. Closure-wide diagnostic text parity remains.
- [ ] The self-hosted compiler emits classical, coherent, quantum, and hybrid examples accepted by the independent verifier.
- [ ] The recovery seed can rebuild its successor from a clean checkout.
- [ ] Diverse double compilation reproduces the candidate artifact without executing candidate-produced code before comparison.
- [ ] The bootstrap manifest binds both derivation paths, source trees, tools, options, limits, verifiers, and complete output identities.
- [ ] No Java parser, lowerer, or `.wbc` writer remains on the normal compiler path after cutover.
- [ ] Current compiler documentation explains the trust chain, fixed-point test, limits, and seed update procedure.

## Alternatives

### Keep the compiler in Java

Rejected. It leaves Wheeler unable to express its defining systems program and makes JVM behavior part of the practical language contract.

### Translate the Java compiler mechanically at the end

Rejected. The resulting Wheeler program would inherit Java-shaped APIs and force late changes to values, storage, effects, and modules. Bootstrap requirements guide those contracts now.

### Keep Java and Wheeler compilers indefinitely

Rejected. Parallel authorities drift. Differential operation is a migration phase with a deletion gate, not a compatibility policy.

### Use Tree-sitter as the production parser

Rejected for the bootstrap baseline. It adds a native generated runtime to the trusted path and does not own Wheeler semantic diagnostics. Tree-sitter remains required editor tooling and a differential grammar test.

### Check in only generated Java or native code

Rejected. The canonical executable is `.wbc`. Provider formats and host-native images are derived caches.

## Open questions

- Which ownership rule and region representation provide the smallest sufficient bootstrap heap (owner: VM and language maintainers. Decision point: before aggregate bytecode is accepted)?
- Which prior seed and independent implementation should be used for a later diverse double bootstrap (owner: release maintainers. Decision point: before the first stable release)?

## References

- [Current self-hosting status and evidence](self-hosting-status.md)
- [Compiler implementation records](catalog/compiler.md)
- [Native compiler test records](catalog/testing.md)
- [Native image and runtime records](catalog/platform.md)

- [WIP-0053: Auditable bootstrap seed chain](WIP-0053-auditable-bootstrap-seed-chain.md)

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0016](WIP-0016-nonconfigurable-source-formatter.md)
- [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md)
- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [Wheeler source language profile](../../public/reference/language-profile.md)
- [Ken Thompson, "Reflections on Trusting Trust"](https://dl.acm.org/doi/10.1145/358198.358210)
