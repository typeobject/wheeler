# WIP-0007: Self-hosting compiler and reproducible bootstrap

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, compiler, bytecode, and runtime maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Compiler, bootstrap, language profile, trusted computing base |
| Depends on | WIP-0001, WIP-0005, WIP-0006 |
| Supersedes | None |
| Superseded by | None |

## Summary

The production Wheeler compiler shall be a Wheeler program. The current Java compiler and VM are temporary stage-0 infrastructure, not permanent dependencies or second implementations. Stage 1 compiles the compiler sources into stage 2, and a successful bootstrap requires canonical stage-1 and stage-2 `.wbc` artifacts to be byte-for-byte identical. WIP-0008 then moves execution and ordinary builds to a native Wheeler toolchain and removes Java completely.

This requirement shapes the language and VM now. The bootstrap profile needs ordinary compiler construction facilities—typed local values, records and tagged variants, bounded sequences, strings and bytes, deterministic maps, control flow, modules, result values, and explicit file effects—without importing JVM object or exception semantics into Wheeler. Every added facility must remain compatible with reversibility, bounded execution, canonical bytecode, and future quantum compilation.

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
6. Publish the stage-2 content identity and build manifest as the next recovery-seed candidate.

A seed update is reviewed like source code. CI rebuilds from the prior seed and proves the new fixed point before accepting it.

## Safety and limits

Every compiler phase has declared source-byte, token, nesting, declaration, symbol, instruction, diagnostic, heap-byte, stack-depth, and step limits. Arithmetic used for sizes and offsets is checked. Decoders reject overlong, truncated, duplicate, cyclic, and unknown required records.

The launcher grants read-only source inputs and one atomic artifact destination. Compiler code receives no credentials, network capability, ambient environment map, clock, random source, or unrestricted filesystem path.

## Migration and deletion

1. Freeze the current Java stage-0 profile and document its accepted grammar as the bootstrap baseline.
2. Add typed parameters, returns, locals, conditionals, bounded loops, records, variants, strings, bytes, and deterministic collections in vertical parser-to-VM slices.
3. Add module manifests and explicit source/artifact effects.
4. Implement `.wbc` and proof-certificate decoding and encoding in Wheeler and compare them against stage 0.
5. Port lexer and parser, then resolution, checking, lowering, verification, and the driver.
6. Produce stage 1 and stage 2; require fixed-point and differential conformance tests in CI.
7. Switch ordinary builds to the Wheeler compiler artifact.
8. Delete the Java lexer, parser, source model, lowerers, and artifact-generation path as part of the WIP-0008 no-Java cutover.
9. Retain only the pinned `.wbc` recovery seed, native Wheeler launcher, and generation provenance; do not retain a parallel Java compiler or VM.

## Progress

- [x] Canonical `.wbc` and a deterministic stage-0 compiler exist.
- [x] The accepted source grammar is formatting-independent and covered by Tree-sitter tooling.
- [ ] Bootstrap feature and module manifests are specified as executable schemas.
- [ ] Signed/Boolean parameters and results, typed frames, static calls, aggregate values, bounded control, affine local regions, word/byte buffers, immutable validated UTF-8 owners, and fixed signed maps execute; cross-function ownership, library strings, generic collections, exported variant/collection module APIs, cross-package linking, and compiler-scale arenas remain.
- [ ] Stage 0 links bounded classical function modules with exact sorted imports, direct public visibility, closed DAG inputs, deterministic dependency-first naming, and exact manifest-bound source sets across local/locked builds, and direct public immutable-record APIs; the Wheeler implementation and full module surface remain.
- [ ] Wheeler `.wbc` codec passes stage-0 differential tests.
- [ ] `Utf8Lexer.w` executes a bounded UTF-8 scanner with explicit token-kind/start buffers; complete token schemas, comments/numbers, diagnostics, source input capabilities, parser construction, and corpus parity remain.
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
- Should tagged variants use dedicated bytecode metadata or sealed value records in the first profile? — **Owner:** compiler and bytecode maintainers — **Decide by:** before parser AST implementation
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
- [Wheeler source language profile](../reference/language-profile.md)
- [Ken Thompson, “Reflections on Trusting Trust”](https://dl.acm.org/doi/10.1145/358198.358210)
