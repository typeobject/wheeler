# WIP-0012: Wheeler standard library

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, library, compiler, runtime, quantum, proof, package, and documentation maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Standard library, types, collections, quantum resources, host capabilities |
| Depends on | WIP-0002, WIP-0005, WIP-0007, WIP-0009 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler shall have a standard library written in Wheeler. It supplies the value, collection, text, byte, arithmetic, reversible, quantum, hybrid, proof, capability, package, and test abstractions required by ordinary applications and by Wheeler's self-hosted compiler, runtime, and package manager.

The library is layered. `wheeler.core` is available without heap allocation or host effects. `wheeler.alloc` adds owned bounded storage. `wheeler.std` adds capability-scoped host services and higher-level packages. Quantum modules expose affine logical `Qubit` and `Qreg` values, disjoint borrowed views, circuits, parameters, observables, results, and target requirements without exposing provider objects or physical qubit pointers.

Every public operation declares type, ownership, effects, failure, allocation, bounds, and reversibility. A method is `rev` only when its inverse is valid under stated contracts. A method is coherently liftable only when it denotes an exact finite permutation and uses no hidden allocation, history, measurement, or host effect. Logged containers, transactional APIs, and replay records do not pretend to be intrinsically reversible.

The standard library is distributed as locked Wheeler packages under WIP-0009, compiled by the self-hosted compiler, documented by `wheeler doc`, and included in the native recovery graph. Java, JVM collections, provider SDK types, and host serialization are not part of its contract.

## Motivation

Self-hosting requires more than syntax and bytecode. A compiler needs source text, UTF-8 decoding, byte builders, spans, records, tagged variants, deterministic maps, queues, arenas, diagnostics, paths, and result values. A package manager needs canonical manifests, hashes, graph algorithms, archive readers, capabilities, and atomic output. A proof kernel needs immutable terms, bounded recursion, exact arithmetic, and canonical encodings.

Quantum applications need equally careful types. Treating a qubit as an integer or provider object loses affine ownership, register identity, disjointness, target requirements, and measurement transitions. Reusing arbitrary classical collections for live qubits permits copying and aliasing that the language must reject.

Importing Java's standard library would make Java object identity, exceptions, hash iteration, Unicode behavior, threads, serialization, and allocation part of Wheeler in practice. Thin wrappers would preserve the dependency while hiding it. Wheeler needs small explicit abstractions whose semantics can be implemented by its VM and native runtime and reasoned about by its proof system.

## Goals

- Provide the complete library substrate for the self-hosted compiler, runtime, package manager, proof kernel, and application portfolio.
- Keep a minimal allocation-free and host-free core usable by verifiers, embedded runtimes, and bootstrap stages.
- Define owned, borrowed, affine, movable, copyable, droppable, clean, reversible, and coherently encodable type behavior.
- Supply deterministic bounded collections with canonical iteration and encoding.
- Specify UTF-8, Unicode scalar, string, byte, path, formatting, parsing, and diagnostic behavior.
- Supply fixed-width, modular, fixed-point, rational, complex, angle, matrix, and probability types with explicit arithmetic models.
- Expose quantum resources, operations, observables, parameters, and results as typed provider-neutral APIs.
- Expose hybrid jobs, continuations, event identities, replay, retry, transaction, and target capability records without embedding adapters.
- Expose host I/O, clocks, randomness, processes, network, files, and targets only through explicit capabilities.
- Integrate contracts, theorem APIs, certificates, property tests, and statistical tests.
- Build, test, document, package, and bootstrap the library entirely with Wheeler tooling.

## Non-goals

- Clone the Java, Rust, C++, Python, or POSIX standard library.
- Stabilize every convenience API before ownership, effect, and failure semantics are clear.
- Treat provider SDK objects, credentials, physical qubit handles, sockets, file descriptors, or native pointers as portable Wheeler values.
- Give every collection an intrinsic inverse.
- Hide allocation, history, measurement, target submission, nondeterminism, or blocking behind a `pure` or `rev` signature.
- Make floating-point arithmetic stand in for exact real or complex proofs.
- Put compiler-only AST policy or provider-specific gate sets in the universal prelude.

## Package layers

The library graph is acyclic and divided by trust and capability.

### `wheeler.core`

`wheeler.core` requires no allocator, filesystem, network, clock, randomness, target, or operating-system service. It contains:

- scalar and machine-width types;
- tuples, records, tagged variants, `Option`, and `Result`;
- ownership and effect traits or contracts;
- fixed arrays, slices, ranges, iterators, and comparisons;
- bounded formatting into caller-owned buffers;
- UTF-8 decoding over borrowed bytes;
- hashing primitives needed for canonical identity;
- minimal proof propositions and certificate decoding interfaces;
- panic-free checked arithmetic and explicit traps only where the language requires them.

The compiler, verifier, native transition kernel, and proof kernel can depend on this layer.

### `wheeler.alloc`

`wheeler.alloc` depends on `core` and an explicit allocator capability. It contains:

- owned vectors, strings, byte builders, bit vectors, deques, maps, sets, heaps, graphs, and arenas;
- reference-counted immutable values only if their ownership and cycle behavior are specified;
- region and arena allocation used by compiler phases;
- bounded canonical serialization buffers;
- collection transactions and reversible data structures where their contracts are exact.

Allocation failure returns a typed error or declared trap. It never silently invokes a host collector.

### `wheeler.std`

`wheeler.std` depends on `core`, selected `alloc` packages, and explicit host capabilities. It contains:

- logical paths and package/module identifiers;
- capability-scoped byte input and output;
- atomic artifact replacement;
- process argument and terminal abstractions;
- deterministic command dispatch;
- operational deadlines and cancellation tokens;
- package/archive helpers;
- test runners and report formats;
- quantum target and hybrid runtime client APIs.

Importing `std` grants no capability. Values enter through an application entry point or embedding host.

## Fundamental types

### Scalars

The standard scalar set includes:

- `bool`;
- signed and unsigned fixed-width integers;
- `usize` and `isize` with target-qualified layout but checked portable conversions;
- Unicode scalar `char`;
- finite IEEE floating-point types for executable numeric work;
- fixed-width bit vectors with explicit modular arithmetic;
- `Never` for unreachable results;
- a unit value.

Signed checked arithmetic, unsigned modular arithmetic, and bit-vector arithmetic are distinct APIs. Source operators resolve to a declared model; coherent lifting never guesses that checked arithmetic means modular arithmetic.

Floating-point APIs specify NaN, infinity, signed zero, rounding, comparison, and conversion behavior. Proof code uses explicit finite, rational, algebraic, interval, or symbolic types when mathematical semantics require them.

### Products and variants

Records have named fields and structural value semantics unless declared opaque. Tagged variants are exhaustive and carry bounded payloads. `Option<T>` replaces ambient null. `Result<T, E>` carries ordinary recoverable failure.

A variant tag and record layout have canonical `.wbc` type metadata. Native layout remains derived and cannot change value equality or serialization.

### Ownership classes

Types participate in explicit capabilities such as:

- `Copy`: duplication preserves semantics and ownership;
- `Move`: ownership transfers and the source becomes unavailable;
- `Drop`: destruction has a declared effect and cannot fail invisibly;
- `Borrow`: a scoped shared view;
- `BorrowMut`: a scoped exclusive view;
- `Affine`: use at most once unless reborrowed under its contract;
- `Clean`: value has the distinguished state required for safe uncomputation or release;
- `Reversible`: operations expose checked inverses under stated contracts;
- `Coherent`: finite encoding and operations may lower to exact quantum permutations;
- `CanonicalEncode` and `CanonicalDecode`: versioned bounded representation;
- `Eq`, `Ord`, and `Hash`: deterministic value relations with compatible laws.

The exact surface may use traits, interfaces, contracts, or compiler-known protocols. The semantic distinctions are mandatory.

## Collections

### Arrays and slices

`Array<T, N>` owns exactly `N` elements. `Slice<'a, T>` is a shared bounded view; `SliceMut<'a, T>` is exclusive. Indexing is checked. Iteration order is increasing index.

Splitting a mutable slice proves disjoint ranges. Joining requires matching origin, adjacency, ownership, and lifetime. Quantum register slicing follows related affine rules but does not reuse copyable classical slice semantics blindly.

### Vector and deque

`Vec<T>` and `Deque<T>` own bounded growable storage. Capacity and allocator are explicit construction inputs or policy defaults recorded in the value's execution context. Growth failure is typed.

Iteration, equality, hashing, encoding, and debug output are deterministic. Spare capacity and native addresses do not affect value identity.

Ordinary insertion and deletion are not automatically `rev`: allocation, moved values, and overwritten positions matter. Reversible variants require caller-provided clean storage or return enough owned information to run an exact inverse.

### Maps and sets

The standard deterministic map provides canonical iteration independent of randomized host hash state. Initial implementations may use insertion order with canonical construction or ordered keys. Any hash table separates lookup hashing from semantic iteration.

Map APIs distinguish:

- insert into a known-empty key, which can be reversible when ownership returns exactly;
- replace, which returns the prior value or records a logged effect;
- remove, which returns the owned key/value pair;
- transaction, which exposes explicit commit and abort;
- canonical encode, which uses specified key order.

`Set<T>` follows the same identity and ordering rules.

### Bit vectors and permutations

`BitVec<N>` and dynamically bounded bit vectors support exact bit operations, rank/count operations, endian conversion, and explicit width. `Permutation<N>` validates bijection at construction, composes, inverts, and can become a coherent operation when its encoding fits target and resource bounds.

These types drive arithmetic oracles, packet codecs, bytecode flags, proof finite domains, and state-vector basis mappings.

### Arenas and regions

`Arena` owns a bounded region and returns scoped handles. Dropping an arena releases all its storage as one effect; it is not an intrinsic inverse for arbitrary mutations inside the region.

Compiler phases use immutable values or phase-owned arenas so self-hosting does not require a general tracing collector initially. Values that escape a region are copied, moved to a longer-lived owner, or rejected.

The current language substrate has function-local affine regions and fixed-length mutable signed-word and byte buffers with hard byte/object ceilings, byte-range checks, and explicit drop. It deliberately lacks `Arena`, UTF-8/string APIs, scoped borrows, cross-function ownership, typed allocation failure, and collection APIs; those remain library/profile work rather than being inferred from the primitive.

## Reversible data structures

The library provides reversible structures only where inverse ownership is explicit.

### Reversible cell

`RevCell<T>` supports swap, exchange with a known clean value, and transformations carrying a proved inverse. Direct overwrite either returns the old owned value, records bounded history through an explicit logged type, or is unavailable.

### Reversible vector operations

A reversible push consumes an owned element and known spare clean slot; its inverse pops and returns that same element. A reversible pop returns both value and structural witness needed to invert. Reallocation is excluded unless an explicit allocator transaction and inverse contract cover it.

### Reversible map operations

Insertion requires proof or checked evidence that the key is absent and returns an insertion witness. Removal consumes that witness or returns the complete entry and structural information under a representation-independent theorem. Callers cannot infer intrinsic reversal from an implementation's retained node pointer.

### Logged and transactional containers

`Logged<T>` and `Transaction<T>` own bounded history and expose checkpoint, abort, commit, horizon, and exhaustion. They are effectful library types. Their API uses WIP-0001 and WIP-0004 terminology and never marks a logged overwrite as an intrinsic inverse.

### Reversible algorithms

Library algorithms include swap, rotate, reverse, permutation, stable partition with explicit workspace, sorting with a permutation witness, and reversible graph or tree updates where all discarded information has an owner.

Contracts and WIP-0011 certificates state inverse laws, frame conditions, clean workspace, and complexity bounds.

## Text and bytes

### UTF-8

`Utf8` decoding has one specified malformed-sequence policy: strict decoding returns a source-located error; lossy replacement is a separate named operation. Overlong encodings, surrogates, out-of-range scalars, and truncated sequences are rejected strictly.

`String` is valid UTF-8. Byte length, scalar count, and grapheme segmentation are distinct operations. Indexing a string by arbitrary integer is unavailable; callers use bytes, scalar iterators, or explicit text-boundary indices.

Unicode normalization is never ambient. Identifier and package policies invoke a specific versioned normalization/confusable profile. Compiler canonical artifacts record the relevant profile identity.

### Bytes and builders

`Bytes` is immutable owned byte data; `ByteSlice` is borrowed; `ByteVec` and `ByteWriter` are bounded mutable buffers. Endian reads and writes are explicit. Checked offset arithmetic fails before partial mutation.

Canonical encoders write to caller-owned or transaction-owned buffers and publish only after success. Decoder cursors carry source offset and remaining bounds and cannot read host memory outside the slice.

### Formatting and parsing

Formatting uses deterministic templates and caller-owned writers. Debug formatting has depth and byte limits. Locale, terminal width, pointer address, and map hash order do not enter canonical output.

Integer and floating parsing specify radix, underscore, exponent, overflow, NaN, infinity, and trailing-input behavior. Source literal parsing and standard-library parsing share tested conversion laws but retain source diagnostics.

## Paths and source inputs

`Path` is an opaque host path available only through a filesystem capability. `LogicalPath` is a portable normalized package path using `/`, with no root, drive, traversal, NUL, or host case folding.

Compiler and package APIs accept `SourceInput` and manifests with logical identities and bytes. They do not open arbitrary paths. Directory enumeration is converted by the host or package manager into a sorted bounded manifest before Wheeler code observes it.

Atomic output is a capability operation taking complete bytes and expected destination identity. Partial temporary files are operational host state, not language values or successful artifacts.

## Arithmetic and scientific types

### Fixed and modular integers

`ModInt<N>` and `BitInt<N>` state width and modulus in the type or value schema. Add, subtract, multiply, compare, and controlled forms have exact finite semantics and can satisfy `Coherent` when resource lowering exists.

Checked signed integers remain separate and trap or return overflow. Saturating arithmetic is separately named.

### Fixed point and rationals

`Fixed<Scale, Width>` supports reproducible bounded numerical applications such as reversible simulation and cost accounting. `Rational` uses normalized bounded integers and typed overflow or allocation errors.

These types support exact proof and deterministic cross-runtime behavior where floating point is inappropriate.

### Complex values and angles

`Complex<T>` is a product over an explicit scalar model. `Angle` carries radians or a canonical turn representation and supports exact named fractions where possible. Quantum gate parameters use `Angle` or typed symbolic `Parameter`, not unlabelled provider floats.

Exact quantum proof scalars use a profile accepted by WIP-0011. The simulator may use floating approximations but reports tolerance and cannot mint exact certificates from them.

### Linear algebra and observables

Bounded vectors, matrices, sparse Pauli strings, and Hamiltonian sums live outside `core` in focused packages. Dimensions and index order are explicit. Dense exponential algorithms carry limits and are not pulled into every application.

`ExpectationEstimate` records value, uncertainty, shot count, estimator, observable identity, and target provenance where applicable.

## Quantum resource types

### Logical qubits

`Qubit<'r>` is an affine logical resource borrowed from or moved out of a `Qreg`. It is not an integer, pointer, provider object, copyable handle, serializable host token, or equality-comparable physical identity.

A qubit can participate in gates, controlled operations, measurement, reset when supported, and scoped disjoint borrows. Its source-level debug representation names logical ownership and source span, not provider coordinates.

### Quantum registers

`Qreg<N>` or a dynamically bounded `Qreg` owns an ordered logical register. Construction is preparation under explicit target/runtime semantics, not ordinary heap allocation.

Operations include:

- prepare a declared basis or supported semantic state;
- borrow one qubit;
- split into statically or dynamically checked disjoint affine views;
- apply a unitary or coherent function;
- measure all or a declared subset, consuming or transitioning ownership according to the region contract;
- reset only under target capability and effect rules;
- release only in a state permitted by ownership and target semantics.

Register order defines little-endian outcome encoding unless a typed layout says otherwise. Slices preserve origin and logical index mapping through target lowering.

Ordinary remote `Qreg` values do not survive a job boundary. Persistent quantum memory requires a target-session type with an advertised capability, lifetime, recovery, and failure contract.

### Circuits and operations

`Circuit<Shape>` is immutable semantic region IR or a typed builder that finalizes into it. It contains semantic gates, coherent calls, controls, parameters, measurement only when the circuit kind permits it, and resource requirements.

Builders reject use-after-measure, overlapping mutable qubit views, dirty ancilla release, unsupported control flow, and unbounded construction. Generated adjoint is available only for unitary circuits.

`Unitary<In, Out>` identifies a checked unitary region. `Adjoint<U>` and composition preserve exact semantic identity. Target-native circuits remain derived executable records.

### Gates

Standard gates include stable semantic operations such as H, X, Y, Z, S, T, phase, rotations, controlled variants, swap, and selected multi-qubit primitives. The language/compiler may treat the minimal set intrinsically; the library supplies typed constructors, composition, identities, adjoints, matrices for bounded proof/simulation, and resource metadata.

Provider-native gates belong to versioned target extension packages and require explicit target constraints. They do not enter the universal prelude.

### Parameters

`Parameter<T>` has stable declaration and position identity. `BindingSet` maps a complete parameter schema to canonical finite values. Batch tasks identify schema and bindings independently of provider order.

Parameter expressions are bounded symbolic DAGs with canonical ordering and finite evaluation. Unknown functions or nonfinite bindings fail before submission.

### Observables and results

`Pauli`, `PauliString`, `Observable`, `ExpectationRequest`, `SampleRequest`, and corresponding result types state register layout and endianness.

Counts, per-shot memory, estimates, uncertainty, and diagnostics are separate bounded products. A result always carries task, target, job, request, and schema identity. Convenience access cannot drop provenance silently.

## Hybrid runtime types

The standard hybrid API includes immutable values for:

- target descriptors and independent capabilities;
- task, batch, request, plan, executable, job, and result identities;
- job lifecycle and cancellation request;
- continuations and typed live values;
- semantic events and deterministic reduction;
- run status, observation mode, branch, retry lineage, and commit horizon;
- transaction phase and compensation result;
- bounded persistence snapshots.

Adapters implement host-owned target capabilities. The library owns provider-neutral records and validation. Credentials and provider SDK objects remain embedding-host values outside portable Wheeler state.

Async APIs use structured tasks or explicit polling/futures specified by a concurrency WIP. They do not inherit Java threads or promise callbacks. Local completion follows the same lifecycle as remote work.

## Effects and capabilities

Host services are unforgeable affine or scoped capability values:

- `ByteInput` and `ByteOutput`;
- `FileRead`, `AtomicFileWrite`, and bounded manifest access;
- `Terminal`;
- `MonotonicDeadline`;
- `Entropy` for explicitly nondeterministic applications;
- `Process` for declared native build tools;
- `Network` for constrained registry/provider clients;
- `QuantumTarget`;
- `Credential<T>` opaque to portable code.

A package declares required capabilities; an entry point receives granted values. Importing a module, constructing a string, or calling a pure helper grants nothing.

Effects appear in function types and contracts. Reversible and proof contexts restrict them. Capability denial occurs before the host effect and returns a stable typed error.

## Errors and diagnostics

Recoverable library failure uses `Result`. Optional values use `Option`. Invariant violations at verified boundaries may trap with stable codes. Native crashes, provider failures, cancellation, timeout, malformed data, and resource exhaustion remain distinct variants.

`Diagnostic` contains stable code, severity, primary span, bounded labels, notes, and structured causes. Human rendering is derived. Canonical tests compare structured diagnostics rather than terminal color or host paths.

Error values own no unrestricted provider payload. Attachments are bounded, typed, redacted at ownership boundaries, or content-addressed under policy.

## Proof support

`wheeler.proof` supplies proposition constructors, finite decision procedures, certificate values, resource polynomials, quantum region claims, and kernel interfaces used by WIP-0011 syntax elaboration.

Proof types cannot be constructed through ordinary casts or byte decoding. Certificate decoding invokes the trusted kernel. Experiment evidence has separate types and cannot satisfy exact theorem APIs.

Public library contracts include algebraic laws for equality, ordering, hash compatibility, iteration, encoding, reversible operations, quantum adjoints, ownership, and resource bounds. Critical laws ship with canonical certificates once the proof profile supports them.

## Testing support

`wheeler.test` supplies:

- assertions over typed values and traps;
- table and parameterized tests;
- deterministic property generation with explicit seed and case limits;
- reversible-law helpers checking forward/inverse composition and frame state;
- canonical encoder/decoder round-trip helpers;
- async lifecycle mocks and event-delivery permutations;
- ideal quantum state and distribution assertions;
- statistical tests with declared confidence, tolerance, and flake budget;
- compile-fail and proof-fail fixtures with stable diagnostics;
- capability-denial harnesses.

Test randomness is explicit input. Failed property cases report a replayable seed and minimized value under bounded deterministic shrinking.

## Concurrency

Collection thread safety is not ambient. Immutable values may be shared according to ownership rules. Mutable sharing requires a structured-concurrency and synchronization contract; no type silently maps to Java monitors or volatile fields.

Async target jobs and build tasks use deterministic result reduction independent of completion order. Operational scheduling types are separate from semantic event order.

## Canonical encoding

Portable library values use versioned canonical schemas. Encoding fixes field order, variant tags, integer width, endian order, collection order, string validity, duplicate handling, unknown fields, and limits.

Generic native memory dumps, Java serialization, provider JSON, pointer identity, randomized hash order, and object-graph reflection are forbidden as canonical encodings.

`CanonicalDecode` is total over bounded input: it returns a value or structured error without partial publication. Re-encoding an accepted canonical value produces identical bytes.

## Package and version policy

Standard modules are ordinary locked Wheeler packages with reserved `wheeler.*` namespaces. The compiler may provide intrinsics for performance or primitive semantics, but every intrinsic has the same public contract and conformance tests as its library declaration.

The prelude is small and explicit. It contains scalar types, `Option`, `Result`, core ownership/effect names, and essential annotations; collections, I/O, quantum algorithms, targets, proof automation, and package APIs require imports.

API stability is tracked by package version and language profile. Public type, effect, ownership, inverse, coherent, resource, encoding, and proof contracts participate in compatibility. A method changing from pure to allocating or from intrinsic to logged is a semantic compatibility change.

## Bootstrap graph

The recovery graph builds in layers:

1. primitive VM and native ABI operations;
2. `wheeler.core`;
3. allocator and arenas;
4. compiler byte/text/collection substrate;
5. bytecode codec, verifier, proof kernel, and compiler;
6. package manager and build planner;
7. runtime, quantum, hybrid, testing, and documentation packages;
8. the executable application portfolio.

No lower layer imports a higher layer. A generated dependency graph and package lock enforce the layering.

Stage-0 host implementations exist only during conformance migration. The final library source and tests are Wheeler; native intrinsics are small ABI or backend operations with explicit contracts, not parallel collection or quantum libraries.

## Application fixtures

The standard library is accepted through concrete Wheeler programs:

- `ReversiblePacketCodec.w`: bytes, records, variants, `Result`, builders, and exact inverse;
- `PersistentIndex.w`: arenas, owned nodes, maps, transactions, and canonical encoding;
- Wheeler lexer/parser/compiler: strings, spans, vectors, maps, diagnostics, and source inputs;
- Wheeler package resolver: graphs, versions, hashes, archives, and capabilities;
- `ArithmeticOracle.w`: bit vectors, modular integers, coherent contracts, and permutations;
- `VqeHydrogen.w`: angles, parameters, observables, batches, estimates, and uncertainty;
- `Teleportation.w`: affine qubits, dynamic measurement, conditions, and ownership transition;
- `ExperimentCampaign.w`: jobs, events, persistence, replay, retry, budgets, and deadlines;
- `PackageProvenance.w`: canonical decoding, hashes, proof certificates, and package identities.

## Migration and deletion

1. Specify ownership protocols, effect signatures, package layering, and canonical schemas.
2. Implement scalar, `Option`, `Result`, fixed array/slice, checked arithmetic, and core encoding support.
3. Implement arenas, vectors, strings, bytes, deterministic maps/sets, queues, and diagnostics.
4. Port compiler phases to these Wheeler packages and remove matching Java utility ownership phase by phase.
5. Implement logical paths, source inputs, hashes, archive types, and package graph support.
6. Implement affine quantum resources, circuits, parameters, observables, tasks, batches, and results.
7. Implement hybrid event, persistence, target, and transaction records.
8. Implement proof and test support and certify critical library laws.
9. Build and test the full library through native `wheeler` in the recovery graph.
10. Delete JVM collection adapters, Java serialization, host path leakage, provider-type wrappers, and duplicate stage-0 library implementations at cutover.

## Progress

- [x] Stage-0 code has immutable provider-neutral bytecode, quantum, target, result, and hybrid event records that define initial library schemas.
- [x] Deterministic little-endian outcomes, task identities, target capabilities, and bounded snapshots execute.
- [ ] Core ownership/effect protocols and package layering are accepted.
- [ ] Scalar/aggregate values, affine byte buffers, and strict UTF-8 validation/scalar counting execute as language/VM substrate; Wheeler option/result, owned string, normalization, iteration, and packaged core/text modules remain.
- [ ] Wheeler arenas, vectors, strings, maps, sets, queues, and diagnostics support compiler modules.
- [ ] Reversible collection contracts and witnesses execute and carry proof obligations.
- [ ] Affine qubit/register views and semantic circuit builders execute.
- [ ] Parameter, observable, batch, estimate, and target-plan APIs execute.
- [ ] Hybrid job, event, continuation, transaction, and persistence APIs execute in Wheeler.
- [ ] Proof and test packages support the application portfolio.
- [ ] The self-hosted toolchain and package manager use no host standard library semantics.

## Testing and acceptance

- [ ] Every public operation documents ownership, effects, failure, allocation, limits, inverse availability, and coherent eligibility.
- [ ] Core packages compile and run without allocator or host capabilities.
- [ ] Collection iteration and canonical encoding are stable under insertion, allocation, hash, and task-order variation.
- [ ] Strict UTF-8 validation/scalar counting covers canonical one-to-four-byte and malformed boundary forms; streaming decode, encoding, normalization, string boundaries, and parser numeric differential corpora remain.
- [ ] Allocation exhaustion, integer overflow, index failure, malformed decode, and capability denial occur before partial publication.
- [ ] Reversible structures pass generated forward/inverse laws and reject missing clean storage or ownership witnesses.
- [ ] Arena and ownership tests reject escapes, use after move, overlapping mutable slices, double drop, and cycles unsupported by the profile.
- [ ] Qubit/register tests reject copy, alias, overlap, use after measure, dirty release, and persistence without session capability.
- [ ] Circuit adjoints, coherent operations, parameter bindings, observable order, and result endianness match semantic IR.
- [ ] Host capabilities cannot be forged, serialized, logged, cached, or acquired through import.
- [ ] Canonical decoders reject duplicate, cyclic, noncanonical, oversized, unknown required, and trailing records.
- [ ] Proof certificates validate critical equality, ordering, encoding, inverse, and quantum laws.
- [ ] Standard-library packages build, test, document, and package offline through `wheeler`.
- [ ] The self-hosted compiler, runtime, package manager, proof kernel, and application portfolio use the Wheeler standard library.
- [ ] No Java or provider SDK type appears in a public Wheeler library signature after native cutover.

## Alternatives

### Reuse the Java standard library

Rejected. It keeps Java in the semantic and deployment path and imports incompatible ownership, exception, collection, Unicode, thread, and serialization behavior.

### Make every useful type a language intrinsic

Rejected. It bloats the compiler and trusted base, prevents package evolution, and makes independent implementations harder. Intrinsics are limited to primitive operations with library-level contracts.

### Treat qubits as integer indices

Rejected. Integers are copyable and lack affine ownership, register origin, disjointness, measurement transition, session lifetime, and target semantics.

### Make all containers reversible automatically

Rejected. Overwrite, allocation, growth, deletion, aliasing, and external effects discard information. Reversible APIs require explicit ownership, clean storage, witnesses, history, or transactions.

### Use randomized hash maps and sort only during serialization

Rejected as the default semantic collection. Iteration affects diagnostics, compilation, proof terms, lockfiles, and build plans before serialization. Determinism belongs in the API contract.

### Put provider SDK wrappers in `wheeler.quantum`

Rejected. Provider SDKs are adapter implementation details. Portable library values identify semantic tasks, capabilities, jobs, and results.

## Open questions

- Which ownership protocol surface gives affine quantum resources and ordinary compiler aggregates one coherent model? — **Owner:** language and library maintainers — **Decide by:** before aggregate bytecode acceptance
- Which deterministic map representation should bootstrap first, and what iteration law becomes stable? — **Owner:** compiler and library maintainers — **Decide by:** before Wheeler symbol tables
- Which Unicode versioning and normalization policy belongs in `core` versus package/compiler policy? — **Owner:** text and package maintainers — **Decide by:** before Unicode identifiers
- Which exact scalar tower supports quantum simulation and proof without overloading the bootstrap graph? — **Owner:** math, quantum, and proof maintainers — **Decide by:** before exact QFT certificates
- Which async/structured-concurrency types are required for target and build jobs? — **Owner:** runtime and language maintainers — **Decide by:** before public async syntax

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
