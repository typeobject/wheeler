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

The production Wheeler compiler shall be a Wheeler program. Every Java source and Gradle file is quarantined under top-level `bootstrap/`; those modules are temporary stage-0 infrastructure and conformance oracles, not permanent dependencies or second implementations. Stage 1 compiles the compiler sources into stage 2, and a successful bootstrap requires canonical stage-1 and stage-2 `.wbc` artifacts to be byte-for-byte identical. WIP-0008 then moves execution and ordinary builds to a native Wheeler toolchain and removes Java completely.

This requirement shapes the language and VM now. The bootstrap profile needs ordinary compiler construction facilities—typed local values, records and tagged variants, bounded sequences, strings and bytes, deterministic maps, control flow, modules, result values, and explicit file effects—without importing JVM object or exception semantics into Wheeler. The compiler emits the same closed reversible typed IR for classical inverse/log/barrier behavior and WIP-0002 semantic quantum regions; OpenQASM, LLVM, native objects, and provider payloads remain derived. Every added facility must preserve ownership, effects, inverse/adjoint relations, bounded execution, canonical bytecode, and quantum compilation even when the compiler operation itself is ordinary irreversible work.

## Motivation

A compiler that can only be maintained in Java leaves Wheeler's most important program outside its own language. It also allows the Java object model, collection order, Unicode handling, or exception behavior to become accidental language semantics.

Self-hosting is a forcing function. It proves that Wheeler can express a large deterministic systems program, that its artifact format is complete enough for independent production, and that the runtime can execute useful nontrivial classical workloads. Reproducible staging makes compiler drift visible instead of trusting two implementations because they happen to accept the examples.

Bootstrapping cannot be deferred as a final translation exercise. Decisions about local values, allocation, effects, modules, diagnostics, and bytecode determinism either make a compiler expressible or require another redesign. The project therefore treats the Wheeler compiler as a first-class acceptance program while expanding the source profile.

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
- Expose source reads and artifact writes as explicit host capabilities rather than ambient Java APIs.
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
- `Option<T>` and `Result<T, E>` rather than ambient null and host exceptions;
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

1. **source** decodes UTF-8, records scalar offsets, and produces source spans;
2. **lex** produces a bounded token stream without semantic name lookup;
3. **parse** builds the accepted syntax tree and recovers only at specified synchronization tokens;
4. **resolve** constructs deterministic symbol tables and module identities;
5. **check** enforces types, effects, reversibility, affine resources, and target-independent quantum rules;
6. **lower** emits canonical classical bodies, quantum regions, and hybrid workflows;
7. **verify** checks the in-memory artifact before serialization;
8. **encode** writes WIP-0001 `.wbc` sections in canonical order;
9. **driver** owns options, diagnostics, limits, and all-or-nothing output.

These are Wheeler modules, not host extension points. Stage 0 follows the same boundaries while it exists so each module can be replaced and compared independently.

The parser remains hand-written and deterministic unless another implementation proves simpler. Tree-sitter is editor tooling and a differential syntax oracle; it is not linked into the production compiler.

### Incubation and promotion

`wheeler-examples` is the executable incubator for the first Wheeler-written compiler slices because stage 0 can already compile, package-select, run, rewind, and differentially test those modules there. It is not their permanent address. Incubation keeps an incomplete compiler from becoming the build authority merely because somebody found a serious directory name for it.

Promotion happens after the modules expose one bounded source-set/options/result API, own stable diagnostics, compile the `Counter.w` milestone through Wheeler verification and execution, and have an explicit package target with no dependency on example-only code. The accepted source set then moves atomically into the canonical compiler tool package. It is not copied and wrapped: package manifests, tests, documentation links, and bootstrap scripts move in the same series; superseded targets in the example package and their module paths are deleted. Afterward, checked-in examples consume the pinned compiler package like any other client.

Later phase promotion follows the same rule. A lexer, verifier, interpreter, or encoder may begin as an independently testable example module, but only one implementation remains authoritative after its package boundary is accepted. The repository does not collect prototype organs in jars.

## Reversibility and effects

Self-hosting does not imply that compilation is physically or logically reversible. Parsing allocates, diagnostics observe malformed input, and artifact writing is external I/O. These operations use ordinary, checked, logged, or barrier semantics as appropriate.

Reversible compiler functions still obey WIP-0001. A data transformation marked `rev` must have a generated or checked inverse. Dropping an arena, reporting a diagnostic, or replacing an output file cannot appear inside such a function merely because the whole compiler can be rerun.

A compilation transaction writes output only after parse, check, lower, verify, and encoding succeed. Abort discards the private output buffer and arena. Replacing a prior filesystem artifact is an explicit atomic host effect, not VM rewind.

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

A seed update is reviewed like source code. CI rebuilds from the prior seed, proves the new fixed point, and verifies diverse evidence before accepting it.

## Trusting trust and diverse bootstrap

A stage-1/stage-2 fixed point answers one question: does this compiler reproduce itself under the declared inputs? It does not answer whether the seed inserted behavior absent from source and arranged to reproduce that behavior. Repeating a compromised lineage is not an exorcism; it is merely a very deterministic haunting.

Recovery-seed promotion therefore follows diverse double compilation:

1. choose a trusted compiler derivation independent of the candidate seed—an earlier independently reproduced Wheeler seed, a separately reviewed stage-0 implementation, or a separately sourced host toolchain capable of rebuilding the Java seed;
2. bind that toolchain, its complete inputs, verifier, options, and limits into the bootstrap manifest;
3. compile the canonical source without first executing candidate-produced code;
4. compare complete canonical artifacts and diagnostics against the ordinary bootstrap path;
5. only after equality may the candidate execute the acceptance suite and become a seed candidate.

Two vendor labels on binaries built from one opaque lineage do not constitute diversity. The evidence records hashes and provenance rather than a reassuring string such as `different=true`. Diverse agreement still leaves hardware, firmware, the chosen trusted path, and review in the trusted computing base; this WIP makes that trust inspectable and smaller instead of claiming its abolition.

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
- [x] The accepted source grammar is formatting-independent and covered by Tree-sitter tooling.
- [ ] Bootstrap feature and module manifests are specified as executable schemas.
- [ ] Signed/Boolean parameters and results, typed frames, static calls, aggregate values, bounded control, affine bounded regions, word/byte buffers, immutable validated UTF-8 owners, fixed signed maps, nested immutable UTF-8 borrows, and exclusive region/word/byte/map borrows execute. Primitive region, word, byte, UTF-8, and map owners now transfer through canonical typed parameters and results and rewind across frames; `OwnedReturns.w` transfers all five owner kinds to a consuming callee and is checked by both interpreters; direct VM fixtures also relay an owner back through a typed result. WIP-0028 returned loans and compiler-scale arenas, WIP-0029 generic collections, WIP-0030 static class evidence, and WIP-0031 typed callables/effects remain, along with library strings, exported collection APIs, and package aliases.
- [ ] Stage 0 links bounded classical function modules with exact sorted imports, direct public visibility, closed DAG inputs, deterministic dependency-first naming, and exact manifest-bound source sets across local/locked builds, and direct public immutable-record, closed-variant, and fixed-array/slice APIs over scalar and direct public nominal values, including imported exhaustive matches parsed dependency-first and full module-qualified public calls and nominal value uses; a bounded FIFO module now composes those APIs over an exclusive word-buffer borrow and explicit result variants. Exact locked `library` targets now contribute only dependency modules reachable from the consuming package root, with entryless roots represented by a verified inert-entry artifact; the full compiler module surface remains.
- [x] The accepted Wheeler compiler, verifier, and scanner sources live only in `wheeler.compiler`; the bounded interpreter lives in `wheeler.runtime`, and shared binary codecs live in `wheeler.core`. Their entryless libraries compile from exact manifest source sets and locks; examples consume exact vendored archives, while the workspace, formatter, documentation checker, Tree-sitter corpus, and differential fixtures follow each canonical root. There is no example-side compiler copy available for archaeology or accidental linkage.
- [ ] The canonical `MinimalCompiler.w`/`compiler/{AggregateVerifier,Codegen,Encoding,FunctionVerifier,HelperParser,InstructionVerifier,Ir,Opcodes,Parser,ProofRules,ProofVerifier,Statements,StorageVerifier,StringTable,Structure,Tokens,TypeCodes,Verifier}.w`/scanner graph accepts a bounded minimal Wheeler source file, derives and canonically sorts source identifier strings, computes aligned section sizes, and emits a complete canonical minimal `.wbc`; for `LongClass` with `state long value = 7` and `value += 5`, every one of 504 bytes matches stage 0, strict decoding and canonical re-encoding succeed, and both direct VM and `wheeler run` paths execute the artifact after Wheeler trims a 512-byte capacity. Alternate class/global names, numeric operands, and no-global empty/signed-local entries, one-global empty entries, and one- through four-statement local/assignment/checked add/subtract/XOR/assertion bodies and a named one- through four-statement helper plus static entry call or reversible helper plus reverse block and optional generated-inverse theorem match stage 0 with IR-derived zero through eight local slots and code lengths; one or two helper invocations derive repeated `CALL`/`UNCALL` sites, and statements before and after a reverse block derive distinct entry local/type windows and function lengths, allowing local declarations and deterministic pre/post-state assertions; two-function artifacts derive four-way string ordering, descriptor/type offsets, `RETURN`, and `CALL`; reversible helpers additionally derive intrinsic inverse code for checked global add/subtract and self-inverse XOR in reverse lexical order, reject plain assignment, derive inverse ranges and `UNCALL`, and check restored-state assertions; certified forms derive a fifth canonical string, seventh directory entry, and `GENERATED_INVERSE` proof payload accepted by the kernel; signed local declarations compose with following state operations and lower through `LOCAL_CONST`/`LOCAL_MOVE` with derived local bases, global assertions lower to local-free `EXPECT_EQ`, signed initializers/operands use checked two's-complement emission and overlong magnitudes fail before output, while duplicate string identities fail before publication. Compiler-local removal of scanner comment tokens now makes the checked-in `Counter.w`—comments, two forward calls, pre-reverse assertion, two inverse calls, post-reverse assertion, and theorem—match stage 0 byte-for-byte through direct VM and package-selected `wheeler run` compiler paths and execute back to `count = 0`; the shared teaching scanner still reports comments because deleting evidence is a parser policy, not a lexer hobby. A Wheeler-native bounded verifier rereads either the private compiler output through an immutable transient `byteview` or an exact host binary artifact through package-selected `NativeVerifier.w` and checks header, directory, payload, descriptor, code-length, accepted opcode, exact operand-count/instruction-length boundaries, global/local/call operand domains, signed/Boolean local type windows, instruction-index branch targets, generated-inverse proof subjects/arguments, and terminal-only `HALT` invariants before `setOutputLength`; hex- and binary-fed Wheeler corpora accept canonical stage-0 artifacts and rejects forged indices, types, calls, and proofs. The verifier now reads operands instead of admiring their upholstery. General multi-function/local/type/control-flow IR remains; optional signed-global IR and assignment and checked arithmetic-update code emission have crossed the line. Canonical string planning and emission live in `StringTable.w` rather than the compiler entry, leaving `MinimalCompiler.w` to coordinate sections instead of collecting every office in the building. The accepted grammar is still tiny, but this is now a compiler slice rather than a writer wearing a fake moustache.
- [ ] Wheeler `.wbc` codec passes stage-0 differential tests.
- [ ] The separate manifest-bound `Utf8Lexer.w`/`lexer/Parser.w`/`lexer/Scanner.w` declaration-demo graph consumes explicit bounded host source input and executes an immutable UTF-8 scanner for identifiers including digit continuations, signed decimal values through `Long.MAX_VALUE` with recoverable overflow, punctuation, whitespace, printable ASCII literals with only canonical escaped quote and backslash pairs, and terminated line/block comments with explicit token kind/start/length buffers, stable scanner diagnostic records with code, byte offset, line, and column for malformed comments/literals/capacity, and checks one `long` local-declaration production through a dependency parser module with an exported closed value/error result, then emits the accepted decimal token through explicit bounded output with a checked publish length; complete token schemas, decoded literal values, streaming/multiple effects, full parser construction, recovery sets, and corpus parity remain. The scanner now says what failed instead of merely pointing at the crater.
  EOF closes neither a block comment nor a literal. Waiting longer has not made that a sound recovery rule.
- [x] Stage 0 accepts checked scalar `const` declarations with direct public import and canonical qualification and finite `enum` declarations elaborated to payload-free variants. Constants emit no globals; enum source reorder canonicalizes by case name. `compiler/Opcodes.w` and `compiler/TypeCodes.w` now own the Wheeler verifier/interpreter opcode/type identities and family predicates, replacing dispatch literals before the opcode surface widens. The constant dependency graph supports checked forward references and canonical cycle diagnostics; reversible finite permutations and coherent power-of-two enum lowering remain WIP-0017 work. At least the number soup now has labels on the tins.
- [x] `NativeVm.w` and `runtime/Interpreter.w` execute the verifier-approved bounded compiler artifact profile inside Wheeler and differentially agree with stage 0 for a checked local/global update, signed/Boolean comparisons and branches, a bounded loop, two-argument signed value calls, signed void calls, the four-function signed/Boolean/negation/looping and static-step-certified `FunctionValues.w`, a generated thirty-five-local frame fixture, a generated eighty-expectation code-window fixture, six-level `RecursiveValue.w` calls, the two-global early-return/break/continue `LoopControl.w`, nested structurally equal `Records.w` values, payload-free `FiniteEnums.w`, payload-carrying `Variants.w`, a checked fixed-array/slice artifact, a checked owned-region/word/byte-buffer artifact with nested mutable borrows, valid and malformed strict UTF-8 artifacts, full package-linked `FrozenUtf8.w` with nested read-only borrows and borrowed byte-length/count/validity/scalar calls, a checked fixed-capacity signed-map artifact with a nested mutable borrow, primitive owner-returning `OwnedReturns.w`, plus the proof-bearing reversible `Counter.w`; every declared global (up to eight) is compared against stage 0; forged branch/call/record-field/variant-tag/array-index-local/slice-index-local/word-or-byte-index-local/UTF-8-index-local/map-key-local operands, static bounds, generated inverse bodies, and malformed artifacts fail before interpretation and the outer execution rewinds exactly. General bytecode coverage and native code remain WIP-0008 work.
- [x] `NativeSha256.w` and `crypto/Sha256.w` compute bounded provider-free SHA-256 over immutable binary input, caller-owned digest output, and 1,088 bytes in three explicit scratch buffers. Checked signed `&` and bounded `rotateRight32` lower to canonical `LOCAL_AND`/`LOCAL_ROTR32`, removing arithmetic bit emulation from each compression round. Empty, `abc`, 55/56/64-byte padding boundaries, and arbitrary two-block binary input match the independent stage-0 oracle, and rewind restores the empty-input baseline. The implementation is portable identity machinery, not a timing-resistant password service; confusing those jobs would at least keep an incident responder employed.
- [x] A classical entry may receive explicit strict UTF-8 or immutable arbitrary-binary `byteview` input and bounded mutable byte-output borrows with a rewindable publish-prefix length; canonical type code 13 admits checked byte reads/length but no writes, ownership, results, or aggregation. VM/runtime APIs and mutually exclusive `wheeler run --input`/`--input-bytes` effect options enforce declared input kind, defensive copying, 16 MiB bounds, physical nonsymlink input, atomic output publication after success, no ambient lookup, and exact rewind to the external-effect baseline. Binary package codecs no longer need to smuggle octets through Unicode wearing an unconvincing hat.
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

- Which ownership rule and region representation provide the smallest sufficient bootstrap heap? — **Owner:** VM and language maintainers — **Decide by:** before aggregate bytecode is accepted
- Which prior seed and independent implementation should be used for a later diverse double bootstrap? — **Owner:** release maintainers — **Decide by:** before the first stable release

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
- [Wheeler source language profile](../reference/language-profile.md)
- [Ken Thompson, “Reflections on Trusting Trust”](https://dl.acm.org/doi/10.1145/358198.358210)
