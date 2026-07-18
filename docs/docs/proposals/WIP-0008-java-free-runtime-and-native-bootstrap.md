# WIP-0008: Java-free runtime and native bootstrap

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler runtime, compiler, platform, and release maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Runtime, native code, bootstrap, distribution, Java retirement |
| Depends on | WIP-0001, WIP-0007 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler's production toolchain and runtime shall have no Java dependency. The current Java compiler, VM, runtime, and Gradle build are stage-0 infrastructure. They exist to establish semantics and seed the self-hosted implementation; they are deleted after a conforming Wheeler-written toolchain can rebuild and test itself from a pinned native recovery release. WIP-0009 supplies the Wheeler-native package and build system that replaces Gradle.

Canonical `.wbc` remains the portable executable and semantic boundary. A native backend lowers verified `.wbc` to host code for distribution and bootstrapping. The Wheeler compiler, verifier, VM or execution runtime, disassembler, OpenQASM emitter, and build driver become Wheeler programs. A narrow platform ABI supplies memory, process arguments, bounded file operations, and other explicitly granted host effects. It does not expose JVM objects or reproduce the Java class library.

No self-hosted language builds from literal nothing. A cold build starts from a reviewed prior Wheeler native release and its content-addressed `.wbc` seed, just as WIP-0007 starts from a prior compiler stage. The trust chain is explicit, reproducible, and replaceable; Java is not in it after cutover.

## Motivation

Compiler self-hosting alone is insufficient if every Wheeler artifact still requires a JVM to execute. It would move source code into Wheeler while retaining Java as the actual platform contract, deployment cost, and trusted runtime.

The language already defines machine state, verification, bounded effects, quantum region IR, and hybrid persistence independently of Java. Keeping Java forever would let host collection order, object identity, exceptions, serialization, threads, and numeric conversion leak back into those contracts. It would also prevent small native deployments and make long-lived toolchain maintenance depend on an unrelated managed runtime.

The migration must nevertheless remain testable. Replacing Java in one unverified rewrite would discard the executable semantic oracle before the new runtime proves parity. This WIP therefore defines a staged cross-runtime conformance period followed by complete deletion, not permanent dual implementation.

## Goals

- Ship the unified `wheeler` command and conformance runner without a JRE or JDK.
- Implement production compiler and runtime logic in Wheeler.
- Preserve `.wbc` as the canonical portable artifact regardless of native caching or linking.
- Define a small versioned platform ABI with explicit capabilities and bounded data.
- Produce reproducible native recovery releases from Wheeler sources.
- Cross-check Java and native execution during migration, then delete Java and Gradle paths.
- Support clean bootstrap from a prior native Wheeler release on every tier-1 platform.
- Keep provider SDKs and Python outside the required toolchain.

## Non-goals

- Eliminate the operating system, assembler, linker, or all native toolchain dependencies.
- Make native machine code a portable semantic artifact.
- Standardize every operating-system API as a Wheeler language feature.
- Retain source compatibility with Java libraries or JVM bytecode.
- Keep the Java VM as a fallback after native cutover.
- Require quantum provider access during bootstrap or deterministic CI.

## Terms and invariants

A **portable artifact** is verified `.wbc`. It is sufficient for interpretation, disassembly, replay identity, and native lowering.

A **native image** is a derived target-qualified executable. Its identity includes the `.wbc` hash, backend version, target triple, ABI version, options, and linked runtime identity.

The **platform ABI** is the only boundary between Wheeler runtime code and host services. It uses fixed-width values, bounded byte spans, stable status codes, and owned handles. Host language objects never cross it.

A **recovery release** contains reviewed native executables, their source and `.wbc` identities, the compiler bootstrap manifest, platform ABI identity, and reproduction instructions.

The following invariants hold:

1. Verification occurs before interpretation or native lowering.
2. Native lowering cannot grant capabilities absent from the host launch policy.
3. Native and interpreted executions have the same specified transitions, traps, limits, and observable results.
4. Native images are caches; corrupt or stale images cannot redefine `.wbc` semantics.
5. Canonical artifacts contain no host path, clock, process, address, or random state.
6. A release bootstrap never invokes Java after cutover.

## Architecture

### Wheeler-owned components

The production source tree contains Wheeler implementations of:

- bytecode decoding, structural verification, and canonical encoding;
- the deterministic classical transition kernel;
- quantum region construction and semantic state-vector conformance;
- hybrid event reduction, replay, and persistence validation;
- source compilation from WIP-0007;
- disassembly, OpenQASM emission, and command dispatch;
- native lowering and deterministic build manifests.

These components share data schemas and conformance fixtures. They do not call hidden Java helpers.

### Platform layer

The initial native ABI provides only:

- process arguments and exit status;
- bounded standard input, output, and error byte streams;
- capability-scoped file open, read, atomic replace, and directory-manifest access;
- checked memory reservation, release, and page primitives needed by the Wheeler allocator;
- optional monotonic deadlines for operational timeout policy;
- target submission hooks supplied by an embedding host.

Wall-clock time, environment variables, network sockets, random devices, dynamic libraries, and unrestricted paths are absent unless an application receives an explicit capability. ABI calls return typed status values; they do not throw host exceptions through Wheeler frames.

The ABI may have a small C-compatible shim per operating system. That shim contains no parser, verifier, VM transition, compiler, scheduler, replay, or quantum semantics.

### Native lowering

The first native backend lowers verified `.wbc` through a documented target-neutral native IR and a selected machine-code toolchain. LLVM is a likely implementation component, not the language execution model. A backend WIP shall fix object identity, calling convention, stack maps, traps, and runtime linkage before native output becomes a release artifact.

Ahead-of-time lowering preserves explicit bounds checks, arithmetic traps, effect barriers, history operations, and source mappings. Optimizations must be validated against bytecode semantics and cannot erase observable traps or reorder effects.

An interpreter remains useful for conformance and unusual targets, but its production implementation is Wheeler code and ships as a native image. It is not the old Java VM.

### Storage and memory

The Wheeler runtime owns typed stacks, frames, history, regions, and managed values. The platform layer supplies raw bounded memory only. The first native compiler may use compilation arenas and immutable shared values; long-lived applications require a later specified collector or region ownership model.

Object layout is an ABI between generated native code and the Wheeler runtime, not a source-language promise. Persisted hybrid values continue to use versioned canonical schemas rather than dumping native memory.

## Bootstrap chain

Before cutover:

```text
Java stage 0
  -> Wheeler compiler.wbc
  -> self-host fixed point
  -> native Wheeler compiler/runtime
  -> native conformance comparison
```

After cutover:

```text
prior native Wheeler recovery release
  -> current compiler.wbc and native tools
  -> current compiler rebuilds itself
  -> byte-identical .wbc fixed point
  -> reproducible native recovery release
```

The prior release is not copied into the source semantics. It is a seed with a declared content identity. A later diverse bootstrap may use independently built runtime or backend implementations to reduce trust in one lineage.

## Reversibility and effects

Native execution must preserve WIP-0001 history and inverse rules exactly. A backend cannot replace checked arithmetic with wrapping arithmetic, elide a logged overwrite, or treat commit as an optimizer hint.

Platform calls are effects. File replacement, terminal output, memory mapping, and target submission are not physically reversed by native stack unwinding. Wheeler effect, transaction, replay, compensation, and commit rules remain authoritative.

Quantum adjoints and hybrid replay retain the meanings specified by WIP-0002 and WIP-0004. Native code does not gain access to provider qubit pointers merely because an embedding application has them.

## Conformance and migration

Migration proceeds in replaceable slices:

1. Freeze Java stage-0 semantics behind executable `.wbc`, VM, target, and persistence corpora.
2. Specify the platform ABI and native-image identity.
3. Add a native backend for the classical bootstrap profile.
4. Compile and run Wheeler-written bytecode codec, verifier, and transition kernel natively.
5. Port source compiler and tools under WIP-0007.
6. Port quantum IR, ideal simulator, OpenQASM emission, and hybrid runtime.
7. Run every corpus and example on Java interpretation, Wheeler interpretation, and native execution; compare semantic traces and artifacts.
8. Bootstrap from a prior native release in clean CI with no Java on `PATH`.
9. Replace Gradle orchestration with the WIP-0009 `wheeler` package and build driver plus minimal platform packaging.
10. Delete all production and test Java sources, Gradle files, Java CI setup, and JVM documentation in one cutover series.

A temporary differential harness is migration code. It is removed after native fixtures and trace readers become authoritative.

## Safety, limits, and failures

Native code retains all declared bytecode, history, stack, heap, workflow, event, result, and compiler limits. Backend arithmetic used for offsets, layouts, relocation, allocation, and lengths is checked. The runtime rejects incompatible ABI, target, endianness, pointer width, feature, or artifact identities before execution.

Signals, access violations, and platform faults become bounded fatal runtime reports; they are not silently converted into source exceptions. A native crash never validates a partial artifact or event-log write.

Recovery releases are signed or content-addressed by release policy. Bootstrap scripts verify every seed before execution and record the exact host toolchain used for native reproduction.

## Progress

- [x] `.wbc` semantics and encoding are independent of JVM bytecode.
- [x] Provider-neutral quantum IR and OpenQASM lowering do not require Python.
- [x] Package-selected `NativeVerifier.w` consumes exact binary `.wbc` through immutable `byteview`; `compiler/Verifier.w` owns framing/payload policy; `compiler/FunctionVerifier.w` owns bounded descriptors/type/code windows; `compiler/InstructionVerifier.w` owns opcode framing, scalar/call operands, and branch targets; `compiler/AggregateVerifier.w` owns immutable aggregate operand checks; `compiler/StorageVerifier.w` owns bounded region/word-buffer operand checks; `compiler/ProofVerifier.w` owns generated-inverse/static-step records. The graph accepts the bounded self-hosted compiler profile, rejects damaged artifacts, and rewinds exactly. This is a Wheeler-executed verifier milestone, not yet a native machine-code verifier; changing the adjective would not change the executable.
- [x] `NativeVm.w` and `compiler/Interpreter.w` execute the verified bounded compiler profile inside Wheeler: initialization and indexed access for up to eight signed globals, thirty-two signed/Boolean locals in each of eight bounded frames and up to eight functions, constants/load/store/move/arithmetic, equality/less-than, instruction-index branches, bounded loop checks, expectations, direct reversible global operations, `CALL`, `UNCALL`, bounded structurally interned immutable record, finite-variant, fixed-array, and slice construction, inspection, indexed reads, field reads, and equality, plus bounded owned regions and mutable word buffers with checked allocation/access/drop, typed signed/Boolean `CALL_VALUE`/`CALL_VOID`, `RETURN`/`RETURN_VALUE`, and `HALT`. A checked update agrees with the stage-0 VM and rewinds the outer interpreter exactly; the proof-bearing `Counter.w` artifact emitted by the Wheeler-written compiler matches stage 0 byte-for-byte and returns to zero. Conditionals, a bounded loop, a two-argument value call, an argument-bearing void call, and the four-function signed/Boolean/looping `FunctionValues.w` artifact, six-level `RecursiveValue.w` recursion, and the two-global early-return/break/continue `LoopControl.w`, nested structurally equal `Records.w` values, payload-free `FiniteEnums.w`, and payload-carrying `Variants.w`, a checked fixed-array/slice artifact, and a checked owned-region/word-buffer artifact agree with stage 0 and rewind exactly. `FunctionVerifier.w` checks generic bounded descriptor/type/code windows; `AggregateVerifier.w` checks immutable aggregate metadata use; `StorageVerifier.w` checks bounded owned-storage operands; `ProofVerifier.w` rederives generated inverse instruction order/opcodes/operands and checks static straight-line step bounds, rejecting a structurally valid wrong inverse and a forged smaller bound. Forged branch/call targets, record field operands, variant tags, array index locals, slice index locals, and word index locals also fail Wheeler verification. Byte-buffer/UTF-8/map opcodes, wider function graphs, interpreter-level rewind records, workflows, and native machine code remain. The runtime has entered the building, but it has not yet found every light switch.
- [ ] Platform ABI and native-image identity are specified.
- [ ] Native backend executes the classical bootstrap profile.
- [ ] Wheeler-written verifier and VM pass Java differential traces.
- [ ] Wheeler-written compiler reaches the WIP-0007 fixed point.
- [ ] Quantum and hybrid runtime fixtures pass natively.
- [ ] A clean no-Java bootstrap produces a reproducible recovery release.
- [ ] Java, Gradle, and JVM-specific CI paths are deleted.

## Testing and acceptance

- [ ] All `wheeler` compiler, runtime, disassembly, quantum-lowering, package, and conformance commands run in a container with no Java or Python installation.
- [ ] Interpreted and native runs produce identical classical state, traps, commit horizons, and semantic event traces.
- [ ] Bytecode verifier accept/reject decisions match across all transition implementations.
- [ ] Native checked arithmetic, call frames, inverse execution, rewind, and history exhaustion pass the WIP-0001 corpus.
- [ ] Quantum ideal-state and sampled seeded fixtures match within their exact contracts.
- [ ] Hybrid persistence, replay, retry, corruption, and late-result fixtures match.
- [ ] Native stage 1 and stage 2 compiler `.wbc` artifacts are byte-identical.
- [ ] Two clean native bootstrap runs produce identical release manifests and binaries where the selected object format permits reproducible bytes.
- [ ] Capability-denied file, network, clock, random, and target operations fail before host effects.
- [ ] Repository CI and release jobs contain no JDK setup, Gradle invocation, Java source compilation, or JVM runtime dependency after cutover.
- [ ] No Java source or JVM-specific production path remains after migration.

## Alternatives

### Keep a Java launcher for `.wbc`

Rejected. It keeps the JRE in every deployment and leaves Java in the trusted execution path.

### Rewrite the runtime permanently in C or Rust

Rejected as the production semantic owner. A small host ABI shim is necessary, but Wheeler should be capable of expressing its compiler and runtime. A second full runtime would recreate parallel authorities.

### Make native images canonical

Rejected. Machine code is target- and toolchain-specific and unsuitable as Wheeler's portable semantic, replay, and interchange identity.

### Delete Java before differential conformance

Rejected. The current implementation is the executable migration oracle. It is temporary, but deleting it before stronger evidence would replace one dependency with unmeasured semantic drift.

## Open questions

- Which native IR and backend form the first supported AOT path? — **Owner:** compiler and platform maintainers — **Decide by:** before native code enters ordinary CI
- What is the smallest C-compatible ABI shim that supports tier-1 systems without owning language semantics? — **Owner:** runtime maintainers — **Decide by:** before Wheeler allocator implementation
- Which object formats can provide byte-reproducible native releases, and where must the manifest compare normalized identities instead? — **Owner:** release maintainers — **Decide by:** before the first recovery release

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
