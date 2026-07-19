# WIP-0007: Self-hosting compiler and reproducible bootstrap

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler language, compiler, bytecode, and runtime maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-18 |
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

A clean checkout uses the pinned stage-0 path to compile the Wheeler compiler sources; the resulting stage-1 compiler runs on the Wheeler VM and compiles the same sources. The build compares stage 1 and stage 2 and fails on any byte difference.

### Normal development

After the first reproducible bootstrap, ordinary compiler development runs the pinned stage-1 `.wbc` compiler. During migration, a stage-0 rebuild remains an explicit trust operation. After WIP-0008 cutover, cold builds use the prior native Wheeler recovery release and do not invoke Java.

### Cross-runtime validation

The same compiler artifact runs on the reference VM and any conforming independent VM. Both produce identical `.wbc` output and stable diagnostics for the conformance corpus.

### Quantum compilation

The self-hosted compiler emits canonical WIP-0002 region IR; OpenQASM and later target formats remain downstream derivations. The compiler does not need provider SDK objects or network access.

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
7. Stage-0 Java code and Gradle machinery remain below `bootstrap/`; canonical Wheeler packages contain no Java source or build file.
8. Fixed-point equality is reproducibility evidence, not proof that the seed is benign.
9. Recovery-seed promotion requires diverse double-compilation evidence from an independently derived trusted path plus the ordinary fixed point.
10. The candidate seed is not executed in the diverse path before its output has been compared with the trusted derivation.

## Bootstrap language profile

The self-hosting profile extends WIP-0005 in complete vertical slices.

### Values and types

The required value set is:

- `bool`, signed fixed-width integers, Unicode scalar values, and finite floating-point values where quantum angles require them;
- immutable `String` and mutable bounded `byte[]` or an equivalent byte builder;
- fixed and growable bounded sequences with explicit element types;
- value records for tokens, source spans, declarations, instructions, and diagnostics;
- tagged variants for token, expression, statement, type, opcode, and result alternatives;
- `Option<T>` and `Result<T, E>` instead of ambient null and host exceptions;
- deterministic insertion-ordered or sorted maps whose order is specified.

Reference identity is not part of value equality unless a later ownership WIP adds it explicitly. Hash randomization cannot affect semantic iteration.

### Functions and control flow

The required executable profile includes typed parameters and returns, local bindings, lexical blocks, `if`, bounded `while` and `for`, exhaustive variant selection, `break`, `continue`, and early result return. Recursion is permitted only under configured stack and step limits.

Pure, ordinary, `rev`, and `coherent rev` functions remain distinct. Compiler code is primarily ordinary deterministic classical code. Reversible containers and transformations may be used where useful, but allocation, diagnostics, and file effects are not mislabeled as intrinsic inverses.

### Storage and ownership

The VM needs typed stack/local slots and a bounded heap or region store. Allocation is an ordinary effect with explicit failure. Immutable values may share storage; mutable values have statically checked ownership or copying rules. Raw host pointers and JVM objects never enter Wheeler state or `.wbc`.

The first collector may reclaim an entire compilation region at run completion. General tracing collection is not a prerequisite if region and memory limits make compiler execution practical.

### Modules and effects

Compiler sources require modules, imports, private declarations, and explicit exported entry points. Module resolution uses the WIP-0009 canonical package manifest and normalized logical paths; it never depends on directory enumeration order.

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

The parser remains hand-written and deterministic unless another implementation proves simpler. Tree-sitter is editor tooling and a differential syntax oracle; it is not linked into the production compiler.

### Incubation and promotion

`wheeler-examples` is the executable incubator for the first Wheeler-written compiler slices. Stage 0 can compile, package-select, run, rewind, and compare those modules there. They move out once they meet the promotion rules, so incomplete compiler code does not become the build authority.

Promotion starts when the modules expose one bounded source-set, options, and result API. They must own stable diagnostics, compile the `Counter.w` milestone, pass Wheeler verification, and execute successfully. They also need an explicit package target with no example-only dependency.

The accepted source set then moves into the canonical compiler tool package as one change. Manifests, tests, documentation links, and bootstrap scripts move with it. The old example targets and module paths are deleted. After that, checked-in examples use the pinned compiler package like any other client.

Later phases follow the same rule. A lexer, verifier, interpreter, or encoder may begin as an independent example module. Once its package boundary is accepted, only one implementation remains authoritative.

## Reversibility and effects

Self-hosting does not imply that compilation is physically or logically reversible. Parsing allocates, diagnostics observe malformed input, and artifact writing is external I/O. These operations use ordinary, checked, logged, or barrier semantics as appropriate.

Reversible compiler functions still obey WIP-0001. A data transformation marked `rev` must have a generated or checked inverse. Dropping an arena, reporting a diagnostic, or replacing an output file cannot appear inside such a function only because the whole compiler can be rerun.

A compilation transaction writes output only after parse, check, lower, verify, and encoding succeed. Abort discards the private output buffer and arena. Replacing a prior filesystem artifact is an explicit atomic host effect, not VM rewind.

WIP-0032 exclusively owns the launcher's I/O request and completion API. The compiler library continues to consume bounded owned inputs and produce an owned artifact or diagnostics; it does not discover files or grow a compiler-specific stream/future family. Atomic output replacement establishes no data or namespace durability without an exact receipt.

## Determinism and canonical output

Canonical compilation fixes:

- UTF-8 decoding and malformed-input behavior;
- line, column, and scalar-offset accounting;
- module and source ordering;
- symbol, function, region, constant, and section ordering;
- integer and floating-point literal conversion;
- diagnostic ordering and stable codes;
- compiler options and feature profile identity;
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

`wheeler bootstrap-manifest` implements the final fail-closed comparison and evidence codec. It reads only bounded physical files; requires canonical source archive, lock, stage artifacts, and closed acceptance artifacts; compares stage 1, stage 2, diverse output, and diagnostics before publication; and atomically emits schema-1 `wheeler.bootstrap.yaml`. The exact schema and command contract live in the [bootstrap evidence reference](../reference/bootstrap.md). The command never executes the candidate. CI must still order candidate acceptance after diverse comparison. The YAML file records evidence, but it does not prove that CI ran the steps in the required order.

A seed update is reviewed like source code. CI rebuilds from the prior seed, proves the new fixed point, and verifies diverse evidence before accepting it.

## Trusting trust and diverse bootstrap

A stage-1/stage-2 fixed point answers one question: does this compiler reproduce itself from the declared inputs? It does not show that the seed matches the source. A compromised seed could insert hidden behavior and reproduce it in later stages.

Recovery-seed promotion therefore follows diverse double compilation:

1. choose a trusted compiler derivation independent of the candidate seed; an earlier independently reproduced Wheeler seed, a separately reviewed stage-0 implementation, or a separately sourced host toolchain capable of rebuilding the Java seed;
2. bind that toolchain, its complete inputs, verifier, options, and limits into the bootstrap manifest;
3. compile the canonical source without first executing candidate-produced code;
4. compare complete canonical artifacts and diagnostics against the ordinary bootstrap path;
5. only after equality may the candidate execute the acceptance suite and become a seed candidate.

Two vendor labels on binaries built from one opaque lineage do not constitute diversity. The evidence records hashes and provenance instead of a reassuring string such as `different=true`. Diverse agreement still leaves hardware, firmware, the chosen trusted path, and review in the trusted computing base; this WIP makes that trust inspectable and smaller instead of claiming its abolition.

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
6. Promote the accepted source set by moving it into the canonical compiler tool package; move manifests, tests, and documentation and delete the superseded targets from the example package in the same series.
7. Produce stage 1 and stage 2; require fixed-point and differential conformance tests in CI.
8. Switch ordinary builds to the Wheeler compiler artifact.
9. Delete the Java lexer, parser, source model, lowerers, and artifact-generation path as part of the WIP-0008 no-Java cutover.
10. Retain only the pinned `.wbc` recovery seed, native Wheeler launcher, and generation provenance; do not retain a parallel Java compiler or VM.

## Progress

- [x] Every Java source, Java test, Gradle module, wrapper, and Gradle build file lives below top-level `bootstrap/`. Canonical Wheeler package roots contain only Wheeler sources and package metadata; host code can no longer pass as compiler source by sharing the directory.
- [x] `bootstrap/stage0` owns the disposable Java compiler seed, while `wheeler-compiler` owns the exact Wheeler package compiled into later stages.
- [x] CI builds the full canonical workspace under independently distributed Temurin and Zulu JDK 26 toolchains and compares every output byte; hosted run `29669052893` passed for commit `8527b18`. This is host-diversity evidence, not yet diverse double compilation.
- [x] Each CI producer emits the same canonical verified artifact-set manifest before comparison; hosted Temurin/Zulu run `29670968056` verified and byte-compared the complete trees for `2dea61e`.
- [x] Canonical `.wbc` and a deterministic stage-0 compiler exist.
- [x] Schema-1 `wheeler.bootstrap.yaml` binds canonical compiler source/archive/lock/profile/options/limits identities, both complete compiler/runtime/verifier/toolchain derivations, stage 1, stage 2, diverse output, diagnostics, and the closed acceptance artifact set. Its executable codec rejects unknown fields, false fixed points, diagnostic drift, identical alleged diverse compilers/toolchains, malformed artifacts, stale artifact sets, links, changing inputs, and partial publication. No manifest is checked in because no complete fixed point or diverse derivation exists yet.
- [x] The accepted source grammar is formatting-independent and covered by Tree-sitter tooling.
- [ ] Bootstrap feature and module manifests are specified as executable schemas.
- [ ] The executable compiler substrate now covers signed and Boolean parameters, results, typed frames, static calls, aggregate values, and bounded control flow. It also covers affine regions, word and byte buffers, validated UTF-8 owners, signed maps, and nested borrows. Primitive region, word, byte, UTF-8, and map owners move through typed parameters and results and rewind across frames. `OwnedReturns.w` checks all five owner kinds in both interpreters. Direct VM fixtures also return an owner through a typed result. Returned loans, compiler-scale arenas, generic collections, class evidence, typed callables, library strings, exported collection APIs, and package aliases remain.
- [ ] Stage 0 links bounded classical modules from exact manifest source sets. Imports are sorted, visibility is direct, inputs form a closed DAG, and names follow dependency order. Public records, closed variants, fixed arrays, and slices work across module boundaries. Importers can use qualified calls and nominal values, then match imported variants exhaustively. A bounded FIFO composes those APIs through an exclusive word-buffer borrow and explicit result variants. Locked `library` targets include only modules reachable from the consuming root. Entryless roots use a verified inert-entry artifact. The full compiler module surface remains.
- [x] The accepted Wheeler compiler, verifier, and scanner sources live only in `wheeler.compiler`; the bounded interpreter lives in `wheeler.runtime`, and shared binary codecs live in `wheeler.core`. Their entryless libraries compile from exact manifest source sets and locks; examples consume exact vendored archives, while the workspace, formatter, documentation checker, Tree-sitter corpus, and differential fixtures follow each canonical root. There is no example-side compiler copy that can be linked by mistake.
- [ ] The bounded Wheeler compiler slice now covers these cases:
  - `MinimalCompiler.w`, `compiler/{backend,frontend,ir,verification}`, and the scanner modules parse a bounded Wheeler source file, sort source identifiers, derive aligned sections, and emit a complete canonical `.wbc`.
  - For `LongClass` with `state long value = 7` and `value += 5`, all 504 bytes match stage 0. Strict decoding, canonical re-encoding, direct VM execution, and `wheeler run` also succeed after trimming a 512-byte output capacity.
  - Alternate names and numeric operands match stage 0 across empty and one- through five-statement entry bodies. The tests cover signed and Boolean locals, assertions, one global, assignment, checked add or subtract, XOR, helper calls, reverse blocks, and an optional inverse theorem.
  - The IR derives zero through twenty local slots and exact code lengths. Repeated helper calls produce repeated `CALL` or `UNCALL` sites, while statements around a reverse block get distinct local and type windows.
  - Two-function artifacts derive four-way string order, descriptor and type offsets, `RETURN`, and `CALL`.
  - Reversible helpers derive inverse code for checked global add or subtract and self-inverse XOR in reverse source order. Plain assignment is rejected, inverse ranges and `UNCALL` are derived, and restored-state assertions are checked.
  - Certified forms add a fifth canonical string, a seventh directory entry, and a `GENERATED_INVERSE` proof payload accepted by the kernel.
  - Signed and Boolean literals, unary negation, literal assertions, and earlier Boolean locals compose with later state operations. They lower through `LOCAL_CONST`, `LOCAL_XOR`, `LOCAL_MOVE`, and `EXPECT_TRUE` with exact type windows.
  - A shared registry owns token hashes, punctuation, and parser statement identities. Global assertions use local-free `EXPECT_EQ`, signed values use checked two's-complement encoding, overlong magnitudes fail before output, and duplicate string identities fail before publication.
  - The checked-in `Counter.w`, including comments, forward calls, inverse calls, both assertions, and its theorem, matches stage 0 through direct and package-selected compiler paths. It executes back to `count = 0`. The teaching scanner still reports comment tokens, while the compiler parser discards them by policy.
  - A Wheeler-native verifier reads private compiler output through `byteview` or an exact host artifact through `NativeVerifier.w`.
  - `compiler/verification/Verifier.w`, `FunctionVerifier.w`, `InstructionVerifier.w`, and `ProofVerifier.w` check framing, descriptors, instruction lengths, opcode and operand domains, local type windows, branch targets, proof references, and terminal-only `HALT` rules.
  - Verification finishes before `setOutputLength` publishes the result.
  - Binary and hex corpora accept canonical artifacts and reject forged indices, types, calls, and proofs.
  - General multi-function, local, type, and control-flow IR still remains; signed-global IR, assignment, and checked arithmetic updates are available.
  - `StringTable.w` owns canonical string planning and emission. `MinimalCompiler.w` now coordinates sections instead of implementing every detail itself.
  - The grammar is still small, but the slice performs real parsing, lowering, verification, encoding, and execution.
- [ ] Wheeler `.wbc` codec passes stage-0 differential tests.
- [ ] The manifest-bound `Utf8Lexer.w`, `lexer/Parser.w`, and `lexer/Scanner.w` graph reads explicit bounded UTF-8 source input. Its scanner handles identifiers with digit continuations, signed decimals through `Long.MAX_VALUE`, punctuation, whitespace, printable ASCII literals, and terminated line or block comments. Token buffers record kind, start, and length. Diagnostics include a stable code, byte offset, line, and column for malformed comments, literals, or capacity limits. A dependency parser checks one `long` local declaration and returns a closed value-or-error result. The entry then publishes the accepted decimal token through bounded output. Complete token schemas, decoded values, streaming effects, full parsing, recovery sets, and corpus parity remain.
  EOF does not close a block comment or literal. The scanner reports that error immediately.
- [x] Stage 0 accepts checked scalar `const` declarations with public import and canonical qualification. It also accepts finite `enum` declarations lowered to payload-free variants; constants emit no globals, and enum case order is canonical. `compiler/ir/Opcodes.w` and `compiler/ir/TypeCodes.w` own opcode and type identities plus family checks, so verifier and interpreter dispatch no longer use raw numeric literals. The constant graph supports forward references and canonical cycle diagnostics; reversible finite permutations and coherent enum lowering remain under WIP-0017.
- [x] `NativeVm.w` and `runtime/Interpreter.w` execute the verified bounded compiler profile inside Wheeler.
  - They agree with stage 0 on local and global updates, signed and Boolean branches, a bounded loop, typed value and void calls, and the four-function `FunctionValues.w` graph.
  - The suite covers a 35-local frame, an 80-expectation code window, six levels of `RecursiveValue.w`, and `LoopControl.w` with early return, `break`, and `continue`.
  - Aggregate fixtures include nested `Records.w`, payload-free `FiniteEnums.w`, payload-carrying `Variants.w`, fixed arrays, and slices.
  - Storage fixtures cover regions, word and byte buffers, nested mutable borrows, valid and malformed UTF-8, `FrozenUtf8.w`, signed maps, and owner-returning calls.
  - The proof-bearing `Counter.w` also executes under the Wheeler verifier and interpreter.
  - Every declared global, up to eight, must match stage 0.
  - Forged branch or call targets fail before interpretation.
  - Forged record-field, variant-tag, array-index-local, slice-index-local, word-index-local, byte-index-local, UTF-8-index-local, and map-key-local operands fail at the same boundary.
  - Bad static bounds, wrong generated inverses, and malformed artifacts also fail closed.
  - The outer execution rewinds exactly. Wider bytecode coverage and native code remain WIP-0008 work.
- [x] `NativeSha256.w` and `crypto/Sha256.w` compute bounded, provider-free SHA-256 from immutable binary input into caller-owned output. The implementation uses 1,088 bytes across three explicit scratch buffers; checked signed `&` and bounded `rotateRight32` lower to canonical `LOCAL_AND` and `LOCAL_ROTR32`. Empty input, `abc`, the 55-, 56-, and 64-byte padding boundaries, and arbitrary two-block input match the independent stage-0 result. Rewind restores the empty-input baseline. This code provides portable content identity; it is not a password-hashing API.
- [x] A classical entry may receive strict UTF-8 or immutable binary `byteview` input. It may also receive a bounded mutable byte-output borrow with a rewindable published length. Type code 13 allows checked byte reads and length queries, but not writes, ownership, results, or aggregates. VM and runtime APIs enforce the declared input kind, defensive copies, a 16 MiB bound, physical nonsymlink input, and no ambient lookup. `wheeler run --input` and `--input-bytes` are mutually exclusive. Output is published atomically after success, and rewind returns to the external-effect baseline.
- [ ] Wheeler semantic analysis and lowering compile all examples.
- [ ] Stage 1 and stage 2 reach a byte-identical fixed point.
- [ ] Ordinary builds use the Wheeler compiler and the Java compiler path is deleted.

## Testing and acceptance

- [ ] Stage 1 and stage 2 `.wbc` artifacts are byte-identical in clean CI.
- [ ] Stage 0, stage 1, and stage 2 produce identical artifacts for every accepted example.
- [ ] All stages produce the same stable diagnostics for the negative corpus.
- [ ] Bootstrap succeeds under at least two supported host JDKs and clean environments without path-dependent output.
- [ ] Randomized source whitespace and comment placement preserve artifact bytes where source maps are disabled.
- [ ] Deterministic collection tests vary insertion history and host hash seeds.
- [ ] Compiler memory, stack, token, diagnostic, and step limits fail before partial output.
- [ ] Malformed UTF-8, literal overflow, deep nesting, cyclic imports, duplicate symbols, and malformed bytecode fail identically.
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

Rejected. The canonical executable is `.wbc`; provider formats and host-native images are derived caches.

## Open questions

- Which ownership rule and region representation provide the smallest sufficient bootstrap heap (owner: VM and language maintainers; decision point: before aggregate bytecode is accepted)?
- Which prior seed and independent implementation should be used for a later diverse double bootstrap (owner: release maintainers; decision point: before the first stable release)?

## References

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
- [Wheeler source language profile](../reference/language-profile.md)
- [Ken Thompson, "Reflections on Trusting Trust"](https://dl.acm.org/doi/10.1145/358198.358210)
