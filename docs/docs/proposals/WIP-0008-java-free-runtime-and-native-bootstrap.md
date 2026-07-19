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

Wheeler's production runtime and toolchain will not depend on Java. The current Java compiler, VM, runtime, and Gradle build stay under top-level `bootstrap/` as stage-0 tools. They establish the initial rules and seed the self-hosted system. Once a Wheeler-written toolchain can rebuild and test itself from a pinned native recovery release, these Java paths are removed.

WIP-0009 provides the Wheeler package and build system that replaces Gradle.

Canonical `.wbc` remains the portable executable and semantic boundary. A native backend lowers verified `.wbc` into host IR and machine code for distribution and bootstrap use. Derived backend data cannot change ownership, effects, traps, inverse relations, or adjoints.

The Wheeler compiler, verifier, VM or execution runtime, disassembler, OpenQASM emitter, and build driver become Wheeler programs. A small platform ABI provides memory, process arguments, bounded file operations, and other granted host effects. It does not expose JVM objects or copy the Java class library.

A cold build starts from a reviewed earlier Wheeler native release and a content-addressed `.wbc` seed. Fixed-point reproduction is paired with diverse double compilation and full provenance. A malicious old compiler can reproduce its own output, so a matching fixed point is useful but not enough. After cutover, Java is no longer part of the trust chain.

## Motivation

Self-hosting the compiler does not remove Java when every Wheeler artifact still needs a JVM. That would change the source language while leaving Java as the real platform, deployment cost, and trusted runtime.

Wheeler already defines machine state, verification, bounded effects, quantum IR, and hybrid persistence without Java. Keeping Java would let host collection order, object identity, exceptions, serialization, threads, and numeric conversions affect those contracts. It would also block small native deployments and tie long-term maintenance to an unrelated managed runtime.

The migration still needs an executable reference. Replacing Java in one unverified rewrite would remove the current oracle before the new runtime proves parity. This WIP uses a limited cross-runtime conformance period, then requires full deletion. It does not create two permanent implementations.

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

Ahead-of-time lowering preserves explicit bounds checks, arithmetic traps, effect barriers, history operations, and source mappings; optimizations must be validated against bytecode semantics and cannot erase observable traps or reorder effects.

An interpreter remains useful for conformance and unusual targets, but its production implementation is Wheeler code and ships as a native image. It is not the old Java VM.

### Storage and memory

The Wheeler runtime owns typed stacks, frames, history, regions, and managed values. The platform layer supplies raw bounded memory only. The first native compiler may use compilation arenas and immutable shared values; long-lived applications require a later specified collector or region ownership model.

Object layout is an ABI between generated native code and the Wheeler runtime, not a source-language promise. Persisted hybrid values continue to use versioned canonical schemas instead of dumping native memory.

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

Quantum adjoints and hybrid replay retain the meanings specified by WIP-0002 and WIP-0004. Native code does not gain access to provider qubit pointers only because an embedding application has them.

## Native I/O fabric

The native runtime implements WIP-0032 behind one explicit application-supplied `Io` interface. Deterministic inline and bounded threaded backends come before platform-tuned completion, polling, direct-storage, RDMA, or target adapters. Native paths preserve operation ownership, cancellation uncertainty, buffer release, bounds, and receipt meaning exactly.

Java stage-0 file, network, and target helpers remain quarantined migration infrastructure. They do not define Wheeler's source API, canonical bytecode, or durability semantics.

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

- [x] All Java source, Java tests, Gradle modules, and the Gradle wrapper are confined to `bootstrap/`; canonical Wheeler package directories contain no Java or Gradle files.
- [x] `.wbc` semantics and encoding are independent of JVM bytecode.
- [x] Provider-neutral quantum IR and OpenQASM lowering do not require Python.
- [x] Package-selected `NativeVerifier.w` reads exact binary `.wbc` through immutable `byteview`.
  - `compiler/verification/Verifier.w` checks framing and payload policy.
  - `compiler/verification/FunctionVerifier.w` checks bounded descriptors, type windows, and code windows.
  - `compiler/verification/InstructionVerifier.w` checks opcode framing, scalar and call operands, and branch targets.
  - `compiler/verification/AggregateVerifier.w` checks immutable aggregate operands.
  - `compiler/verification/StorageVerifier.w` checks bounded region, word, byte, map, and UTF-8 operands.
  - `compiler/verification/ProofVerifier.w` checks generated-inverse and static-step records.
  - The graph accepts the bounded self-hosted compiler profile, rejects damaged artifacts, and rewinds exactly.
  - This is a Wheeler-executed verifier milestone, not a native machine-code verifier.
- [x] The accepted aggregate, storage, UTF-8, map, and transition interpreters live only in the entryless `wheeler.runtime` package, locked to `wheeler.compiler` verification and `wheeler.core` binary primitives. The examples consume its exact vendored archive. No runtime implementation remains in compiler or example source.
- [x] `NativeVm.w` and `runtime/Interpreter.w` execute the verified bounded compiler profile inside Wheeler.
  - The profile supports up to eight signed globals, eight frames, sixty-four typed locals per frame, 128 instructions per function, and eight functions. Only the active function window is cleared.
  - It executes constants, loads, stores, moves, arithmetic, comparisons, branches, bounded loops, expectations, reversible global operations, `CALL`, `UNCALL`, `CALL_VALUE`, `CALL_VOID`, `RETURN`, `RETURN_VALUE`, and `HALT`.
  - Aggregate support covers immutable records, finite variants, fixed arrays, and slices. It includes construction, inspection, indexed or field reads, and equality.
  - Storage support covers bounded regions, mutable word and byte buffers, strict UTF-8, nested read-only and mutable loans, owner-carrying calls, and fixed-capacity signed maps.
  - A checked local and global update matches stage 0 and rewinds the outer interpreter exactly.
  - The Wheeler compiler emits the proof-bearing `Counter.w` artifact byte for byte with stage 0. The interpreter runs its forward and inverse calls back to zero.
  - Control fixtures cover conditionals, a bounded loop, a two-argument value call, an argument-bearing void call, and the four-function `FunctionValues.w` graph.
  - Stress fixtures cover a 35-local frame, an 80-expectation code window, six levels of `RecursiveValue.w`, and `LoopControl.w` with early return, `break`, and `continue`.
  - Aggregate fixtures include nested `Records.w`, payload-free `FiniteEnums.w`, payload-carrying `Variants.w`, fixed arrays, and slices.
  - Storage fixtures include owned regions, word and byte buffers, nested mutable loans, valid and malformed UTF-8, `FrozenUtf8.w`, and a signed map.
  - Every declared global, up to eight, agrees with stage 0 before exact rewind.
  - `FunctionVerifier.w`, `AggregateVerifier.w`, `StorageVerifier.w`, and `ProofVerifier.w` each check their own metadata and operands.
  - The proof verifier rejects a structurally valid but wrong inverse and a forged smaller step bound.
  - Forged branch and call targets fail before interpretation.
  - Forged record-field, variant-tag, array-index-local, slice-index-local, word-index-local, byte-index-local, UTF-8-index-local, and map-key-local operands fail at the same boundary.
  - Opcode-family guards avoid running aggregate or storage checks for scalar instructions. A `LOCAL_MOVE` does not scan unrelated heap state.
  - Returned public loans, interpreter-level rewind records, workflows, and native machine code remain unfinished.
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

- Which derived native backend IR and code generator form the first supported AOT path (owner: compiler and platform maintainers; decision point: before native code enters ordinary CI)?
- What is the smallest C-compatible ABI shim that supports tier-1 systems without owning language semantics (owner: runtime maintainers; decision point: before Wheeler allocator implementation)?
- Which object formats can provide byte-reproducible native releases, and where must the manifest compare normalized identities instead (owner: release maintainers; decision point: before the first recovery release)?

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
- [WIP-0025](WIP-0025-native-ffi-and-system-integration.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
