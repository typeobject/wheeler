# WIP-0010: Executable application portfolio

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, compiler, runtime, quantum, proof, package, and documentation maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Examples, conformance, applications, teaching |
| Depends on | WIP-0001, WIP-0002, WIP-0003, WIP-0004, WIP-0005, WIP-0006 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler's application portfolio is an executable conformance suite, not a collection of syntax samples. It must show reversible systems programming, coherent classical and quantum reuse, current hardware workflows, durable hybrid work, self-hosting, package management, native execution, and checkable claims.

Each application has one stated purpose and a clear implementation gate. A `.w` file enters the repository only after every construct it uses works across the compiler, typed IR, verifier, runtime or target planner, Tree-sitter grammar, tests, and docs. Fixtures label each transition as an inverse, logged rewind, barrier, coherent permutation, unitary or adjoint, measurement, replay, or retry. Success in one category does not prove another.

Designs that need future syntax stay in this WIP until their full vertical slice exists.

The portfolio goes beyond textbook quantum algorithms. Wheeler must also handle compilers, codecs, package resolution, transactional state, simulation, optimization, error correction, target planning, and long-running recovery. Each quantum example states whether it needs static circuits, batches, expectations, dynamic control, logical qubits, sessions, networking, or proof support.

## Goals

- Maintain a concrete application target for every major semantic and tooling capability.
- Exercise Wheeler as a general systems language instead of a gate-circuit notation.
- Demonstrate one-source classical execution and coherent lifting where mathematically valid.
- Cover local, OpenQASM, delayed, recovered, replayed, retried, dynamic, logical, and distributed target plans.
- Drive self-hosting and native runtime work with Wheeler programs of increasing scale.
- Give every example exact expected results, statistical criteria, capability requirements, and resource ceilings.
- Keep every checked-in example accepted by the ordinary compiler and Tree-sitter CI gate.
- Replace a bounded fixture with a richer implementation in place when its required profile lands.

## Non-goals

- Check in pseudocode under a `.w` suffix.
- Present sampled hardware evidence as a proof.
- Emulate unavailable dynamic control through silent host round trips.
- Require network access, credentials, paid hardware, or nondeterministic providers in ordinary CI.
- Add language features solely to mimic another language's example syntax.
- Keep multiple examples that exercise the same law without adding a distinct failure or capability boundary.

## Fixture contract

Every executable fixture provides:

1. Wheeler source using the accepted profile.
2. canonical `.wbc` round-trip coverage.
3. Tree-sitter parsing without unexpected `ERROR` or `MISSING` nodes.
4. deterministic expected state or a declared statistical test with fixed confidence and seed policy.
5. target capability requirements and a negative planning test for missing requirements.
6. replay and retry expectations when observations occur.
7. explicit qubit, shot, event, memory, stack, and step ceilings.
8. a concise reference entry explaining what the fixture proves and what it does not prove.

A formal fixture also identifies its trusted checker, claim schema, assumptions, and certificate bounds. A native or bootstrap fixture identifies its compiler, runtime, platform ABI, package lock, and reproducibility inputs.

No authored fixture file exceeds 1,000 lines. Larger applications are packages composed of smaller modules.

## Current executable base

The repository currently executes these bounded fixtures:

- `Counter.w`: generated inverse and reverse-block order.
- `BinaryTree.w`: fixed-capacity reversible state layout.
- `BootstrapControl.w`: signed locals, expressions, branch joins, and a source-bounded loop.
- `FunctionValues.w`: signed/Boolean parameters, logical negation, returns, static value calls, and callee control flow.
- `RecursiveValue.w`: recursive value calls under hard frame and step ceilings.
- `RegionStorage.w`: affine bounded word/byte storage and UTF-8 scalar decoding.
- `FrozenUtf8.w`: checked consumption of mutable bytes into immutable UTF-8.
- `HostInput.w`: explicit bounded host UTF-8 input and byte output without ambient authority.
- `LongMap.w`: region-owned fixed-capacity signed symbol map.
- `modules/ModuleMain.w` plus `Arithmetic.w`, `Collections.w`, and `Results.w`: exact package source set with private helpers, public function/record/closed-variant/fixed-array/slice linking over scalar and nominal values, and an imported exhaustive match.
- `Utf8Lexer.w` plus `lexer/Parser.w` and `lexer/Scanner.w`: manifest-bound scanner/parser modules over explicit UTF-8 input and bounded byte output.
- `CoherentOracle.w`: finite modular addition and controlled marking over classical and coherent state.
- `QFT.w`: unitary execution and generated adjoint.
- `QFTProof.w`: executable inverse law.
- `QuantumOptimizer.w`: repeated observations, classical acceptance, commit, and replay.
- `QuantumNeuralNetwork.w`: one-bit coherent layer.
- `QuantumCompiler.w`: source/normalized circuit equivalence on basis input.
- `SurfaceCode.w`: static correction kernel and dynamic-target boundary.

These files are starting points. Their names remain stable when richer implementations preserve the same teaching role. Otherwise a new fixture gets a distinct name and contract.

## Reversible systems applications

### Reversible packet codec

`ReversiblePacketCodec.w` parses a bounded binary frame into a typed record and emits the identical bytes through its generated inverse. It covers byte slices, tagged variants, checked lengths, checksums, malformed-input results, and region cleanup.

Acceptance requires:

- `decode(encode(value)) == value` over generated bounded records.
- `encode(decode(bytes)) == bytes` for canonical frames.
- malformed lengths and checksums fail without partial output.
- inverse execution and VM rewind are tested as different operations.

This fixture drives bootstrap strings, bytes, records, variants, and `Result` values.

### Transactional persistent index

`PersistentIndex.w` implements a bounded ordered tree or B-tree page with insert, lookup, delete, transaction abort, commit horizon, and snapshot serialization. It replaces the fixed-slot `BinaryTree.w` role once owned allocation and aggregates exist.

Acceptance requires deterministic shape, no leaked nodes after abort, exact recovery from a persisted checkpoint, and stable encoding independent of allocation address.

### Incremental dependency graph

`DependencyGraph.w` maintains module edges, detects cycles, invalidates affected nodes, and reverses a tentative graph update. It exercises deterministic maps, sets, work queues, tagged diagnostics, and transaction phases needed by the compiler and package manager.

### Reversible image transform

`ReversibleWavelet.w` implements a bounded integer lifting transform and exact inverse over a small image tile. It demonstrates useful reversible arithmetic beyond control-flow examples. Property tests cover extremes, checked overflow, and byte-identical reconstruction.

### Symplectic simulation

`ReversibleOrbit.w` advances a fixed-point symplectic integrator for a bounded two-body system and applies the exact discrete inverse to return to the initial state. It distinguishes reversible numerical integration from floating-point claims that do not survive rounding.

### Event-sourced state machine

`ReplicatedCounter.w` reduces reordered and duplicated content-identified events, rejects conflicting sequence occupants, persists a checkpoint, and resumes without double application. It is a Wheeler implementation of the core event laws used by hybrid runs.

## Compiler and toolchain applications

### Wheeler lexer

`compiler/lex.w` decodes UTF-8, emits source-located tokens, and produces stable malformed-input diagnostics. Stage-0 and Wheeler token streams must match for the accepted corpus and generated whitespace/comment variants.

### Wheeler parser

`compiler/parse.w` builds records and tagged syntax variants with bounded recovery. It compiles every portfolio source and matches the stable negative corpus. Tree-sitter remains a differential concrete-syntax implementation, not a linked parser dependency.

### Bytecode codec and verifier

`bytecode/codec.w` reads and writes canonical `.wbc`. `bytecode/verify.w` rejects malformed control, type, resource, workflow, and quantum records. Stage output and diagnostics match the independent conformance corpus byte for byte where specified.

### Self-hosting compiler

`compiler/driver.w` resolves, checks, lowers, verifies, and emits the compiler itself. The stage-1 and stage-2 artifacts reach the WIP-0007 byte-identical fixed point and compile every portfolio fixture supported by their declared profile.

### Wheeler package resolver

`package/resolve.w` resolves workspace manifests against an identified registry snapshot. Randomized input and registry enumeration order produce one canonical lockfile and build plan. Conflict diagnostics carry a deterministic explanation chain.

### Native runtime trace

`runtime/transition.w` executes the classical transition corpus and emits normalized semantic traces. Interpreted, native, and migration-oracle traces must match for forward execution, inverse calls, rewind, traps, and commit horizons.

## Coherent algorithm applications

### Width-explicit arithmetic oracle

`ArithmeticOracle.w` implements fixed-width modular add, compare, and controlled mark operations. The same functions run over classical values and lift to exact finite permutations. Exhaustive small-width tests compare every basis state and generated inverse.

The implemented lift admission binds constant add/subtract to the explicit `qreg` width and therefore to one finite modulus. Ordinary classical execution remains checked signed arithmetic. It cannot stand in for exhaustive coherent-basis evidence.

### Reversible lookup oracle

`LookupOracle.w` marks keys in a small immutable table and uncomputes all workspace. It exercises coherent table access, ancilla ownership, clean-value checks, and resource estimates.

### Grover search

`GroverSearch.w` composes `LookupOracle.w` with diffusion and returns the marked key distribution. The ideal target test checks exact amplitudes for small instances and a seeded shot test checks a declared success threshold. The generated oracle inverse must clean every ancilla.

### Quantum walk

`QuantumWalk.w` implements a bounded coined walk over a cycle or small graph. It exercises controlled reversible movement, coherent graph indexing, repeated unitary composition, and distribution comparison.

### Phase estimation

`PhaseEstimation.w` estimates a phase for a unitary with known eigenstate. A static implementation covers controlled powers and inverse QFT. An adaptive implementation is a separate dynamic-target fixture with measurement-conditioned rotations.

### Amplitude estimation

`AmplitudeEstimation.w` estimates a known prepared amplitude and records estimator uncertainty. It covers controlled coherent calls, repeated applications, result schemas beyond one basis outcome, and resource accounting.

## Variational and sampled applications

### Molecular energy

`VqeHydrogen.w` estimates a small molecular Hamiltonian with parameterized circuit batches and expectation results. The fixture pins the Hamiltonian, ansatz, optimizer policy, seeds, shot allocation, and confidence criterion.

Acceptance requires:

- exact state-vector energy for a reference parameter point.
- batch and single-task estimators agree under deterministic simulation.
- replay reaches the same optimizer state without target calls.
- fresh retry creates a distinct observation lineage.
- an OpenQASM executor receives equivalent static circuits.

### Graph optimization

`QaoaMaxCut.w` solves a small fixed graph. It exercises graph aggregates, parameter binding, commuting gate scheduling, expectation evaluation, and target-depth planning. The result contract compares objective value and observed cut distribution instead of one lucky sample.

### Quantum kernel classifier

`QuantumKernelClassifier.w` builds a deterministic toy feature map, submits a symmetric kernel batch, and trains a bounded classical classifier. It checks batch identity, matrix symmetry, replay, and absence of quantum handles between jobs.

### Parameter-shift gradient

`ParameterShift.w` submits paired parameter bindings, reduces results in canonical parameter order independent of completion order, and compares the sampled gradient with the exact simulator derivative.

### Monte Carlo risk estimate

`AmplitudeRisk.w` encodes a small discrete loss distribution and estimates a tail probability. It states all approximation, fixed-point, qubit, shot, and confidence bounds. It doesn't claim an advantage from a fixture-sized instance.

## Unified I/O application

### I/O lifecycle conformance

`IoFabricConformance.w` will exercise WIP-0032 positional independence, structured operation ownership, bounded backpressure, cancellation races, deterministic replay, graph dependencies, and receipt separation over deterministic and bounded threaded backends. A companion negative fixture will reject operation leaks, early buffer reuse, hidden fallback, and receipt upgrades.

WIP-0032 owns every I/O type and method used by these fixtures. This portfolio WIP owns only the executable acceptance story. No `.w` file lands until the generic, ownership, effect, parser, bytecode, runtime, Tree-sitter, and package slices execute end to end.

## Dynamic and fault-tolerant applications

### Teleportation

`Teleportation.w` performs Bell preparation, mid-circuit measurement, classical conditions, and corrections inside one dynamic target region. Static targets must reject it with the complete missing-capability set. An ideal dynamic target checks all basis inputs and selected superpositions.

### Repeated error correction

`ErrorCorrectionCycle.w` performs syndrome preparation, measurement, reset, bounded decoding, correction, and cycle reporting as a target-resident workflow. It upgrades the static `SurfaceCode.w` role when dynamic control exists.

Acceptance requires target-resident feedback capability, bounded decoder latency metadata, replayable host-visible cycle results, and explicit separation between logical correction and physical rollback.

### Logical lattice operation

`LogicalCnot.w` expresses a logical operation and resource request without physical coupling-map assumptions. A mock logical target plans code distance, logical qubits, cycles, and failure budget. A physical static target rejects the semantic operation unless an explicit verified lowering is available.

### Magic-state resource plan

`MagicStateFactory.w` composes logical resources, factory throughput, distillation error, and consumption schedule into a bounded target plan. It is primarily a type, unit, planning, and proof-certificate fixture. Ordinary CI uses a deterministic planner, not hardware.

### Distributed Bell pair

`DistributedBell.w` requests networked entanglement between two target endpoints, persists session identities, handles delayed heralding, and discards a timed-out branch without treating cancellation as destroyed entanglement. It requires an explicit network/session capability and a mock target.

### Blind delegated computation

`DelegatedComputation.w` separates client-owned secret preparation from provider execution and validates a bounded verification result. The fixture must state its protocol and threat model. Ordinary target metadata or redaction is not presented as cryptographic privacy.

## Durable hybrid applications

### Recoverable optimizer

`QuantumOptimizer.w` supplies the reversible candidate update and commit fixture. `RecoverableOptimizerCampaign` supplies bounded typed parameters, parameterized batches, persisted continuation after each iteration, queued-job recovery, replay, and explicit terminal provider states.

The test suite stops and restores the run in queued and running states, then covers succeeded, failed, cancelled, and unknown outcomes. Duplicate result delivery cannot apply an update twice.

### Calibration-aware circuit compiler

`CalibrationCompiler.w` records an exact calibration epoch, bounded gate set and samples, derived cycle count, additive error upper bound, and committed plan. `CalibrationAwareCompiler` submits the matching request through a narrow provider boundary and binds the semantic artifact, circuit, immutable target descriptor, request, result, and stale policy into one plan identity. Missing capability, gate, sample, target, request, or epoch evidence rejects before plan publication. Credentials and provider objects never enter compiler state.

### Adaptive experiment

`AdaptivePhaseEstimation.w` selects each next circuit from recorded prior observations. Replay follows the identical decision tree without target calls. Fresh mode may follow another valid branch. Completion arrival order cannot change batch reduction.

### Hybrid workflow compensation

`CompensatedExperiment.w` combines a target submission with a mock external reservation or accounting effect. Abort before and after observation demonstrates cancellation, branch discard, declared compensation, compensation failure, and commit without claiming distributed physical rollback.

### Long-running scientific campaign

`ExperimentCampaign.w` executes a bounded set of experiments over target descriptor epochs, persists after every result, applies budget limits, quarantines stale jobs, and emits a reproducible report from recorded observations. It exercises event cleanup while retaining live continuation references.

### Certified adversarial schedule debugger

`Murphy.w` is the future WIP-0015 capstone. It searches finite distributed-protocol schedules in increasing length, reverses modeled event transitions through explicit witnesses, replays proposed failures deterministically, proves the violation and absence of shorter failures, and packages the reproducer. Empty samples, target timeout, and failed proof search return `Inconclusive`. They never establish safety. The [future-system design](../future/murphy.md) remains documentation syntax until structured concurrency, finite protocol artifacts, replay packages, and general certificates execute.

## Proof and certificate applications

### QFT unitary certificate

`QFTProof.w` grows from an executable inverse law into a checked claim that its gate composition is unitary and its generated adjoint is exact. The trusted checker validates a bounded certificate over canonical circuit identity.

### Circuit equivalence

`CircuitEquivalence.w` proves or exhaustively certifies that source and normalized circuits in `QuantumCompiler.w` have the same small-width unitary up to declared global phase. Larger claims require a specified proof method instead of simulator sampling.

### Resource-bound certificate

`ResourceBound.w` checks symbolic and concrete upper bounds for qubits, ancillas, gates, depth, measurements, target cycles, event bytes, and retries. Target planning may rely on the checked certificate only when semantic region and compiler identities match.

### Reversible function law

`InverseLaw.w` generates bounded inputs for a `rev` function and checks `inverse(forward(x)) == x`, clean ancillas, and unchanged borrowed state. Testing supports a claim but does not become a universal proof without a trusted exhaustive or symbolic certificate.

### Package provenance

`PackageProvenance.w` verifies a package archive's member hashes, manifest identity, dependency lock, compiler identity, and build-plan provenance. Signature verification establishes namespace authorization. It does not establish semantic correctness of package code.

### Bounded algorithm foundry

`Foundry.w` is the fault-tolerant-era capstone from WIP-0014. It searches a canonical finite grammar for the smallest reversible sorting network over eight 4-bit values. Each candidate execution is uncomputed, and the full `2^32`-value input domain is checked. The run also checks certificates showing that no shorter candidate works, then publishes the winner as a proof-bearing package. Search samples are evidence only. Exact checking and the trusted kernel authorize the result. The [future-system design](../future/foundry.md) remains documentation syntax until every dependency runs end to end.

## Native and package applications

### Hermetic workspace build

The Wheeler workspace builds compiler, runtime, package manager, tools, examples, and documentation inputs through `wheeler` with network disabled. Two clean builds produce identical canonical artifacts, lockfile, package archives, and plans.

### Capability-denied build tool

`CapabilityProbe.w` is a negative tool fixture that attempts undeclared file, environment, clock, random, network, process, credential, and target access. Every attempt fails before the host effect and leaves no output.

### Registry mirror

`RegistryMirror.w` verifies and mirrors immutable package objects by content identity. Random transfer order, interruption, duplicate delivery, and mirror path changes do not alter the resulting index snapshot.

### Cross-target native execution

`NativeMatrix.w` is a package of small semantic kernels compiled for every tier-1 target triple. Native and interpreted normalized traces match. Native image identities remain derived from the same `.wbc` artifacts.

## Teaching applications

The teaching track uses small fixtures with one primary law each:

- reversible counter and swap.
- fixed-capacity structured state.
- packet codec and `Result` diagnostics.
- coherent bit permutation.
- Bell state and measurement.
- QFT and adjoint.
- Grover oracle and uncomputation.
- measured optimizer, persistence, and replay.
- dynamic teleportation and capability rejection.
- package resolution and compiler bootstrap.
- checked circuit equivalence and resource bounds.

A teaching example may share implementation modules with a portfolio application but keeps its entry point and expected result small enough to inspect manually.

## Implementation policy

Portfolio work follows these rules:

- The required semantic WIP is accepted or implementing before source syntax lands.
- One feature slice lands parser, model, bytecode, verifier, runtime, Tree-sitter, negative tests, reference text, and at least one fixture together.
- The fixture states exact current scope in source comments and reference documentation.
- Mock targets model lifecycle and capabilities. They do not claim measured hardware fidelity.
- Randomized tests record seeds and bound case counts.
- Statistical tests state null hypothesis, confidence, tolerance, and flake budget.
- Live tests are opt-in and never gate deterministic CI.
- Superseded bounded implementations are replaced in place. No compatibility path keeps two semantic authorities.

## Progress

### Executable base

- [x] Counter and fixed-capacity tree fixtures execute.
- [x] Coherent XOR and one-bit layer fixtures execute classically and quantumly.
- [x] QFT and executable adjoint-law fixtures execute.
- [x] Bounded optimizer records observations and replays without target calls.
- [x] Circuit normalization and static correction fixtures execute.
- [x] A bounded manifest-linked FIFO exercises word-buffer borrowing, immutable cursors, and explicit full/empty results.

### Reversible systems

- [x] `ReversiblePacketCodec.w` produces four canonical byte-valued frame fields under one generated inverse relation, projects those exact fields into region-owned bytes without a packed-word surrogate, validates and decodes through a closed value-or-malformed result, checks decode-encode byte equality, exhausts 256 bounded field combinations, distinguishes length and checksum errors without partial decode state, reverses every frame field to zero, and cleans every owner.
- [x] `TransactionalPersistentIndex.w` stages a copy-on-write root while the old root remains visible, writes root and sequence before the commit marker, records applied transaction identities in the locked deterministic map, rejects duplicate application through a tagged result, injects one marker-free torn record, and scans a bounded log to reopen the latest committed root. The native fixture repeats that layout through `NativePositionalFile`, forces payload and marker at distinct process-crash durability boundaries, writes and forces a second payload without its marker, terminates the child by `Runtime.halt`, reopens through a fresh parent-process capability, observes the exact torn bytes, and selects committed root 11 at sequence 1.
- [x] `IncrementalDependencyGraph.w` owns a mutable four-node adjacency table, deterministic signed maps for versions and generation-tagged visited sets, the locked core queue API for bounded breadth-first work, a tagged accepted-or-cycle result, staged and rolled-back phases, rollback of a tentative back edge, affected-node invalidation, owner cleanup, canonical execution, and complete rewind.
- [x] `IntegerWaveletTransform.w` applies determinant-one lifting steps to a two-pair integer tile, exhausts 256 bounded input pairs through the independent coefficient and reconstruction equations, checks signed extreme values, traps checked coefficient overflow before publishing a result, carries a generated inverse certificate, restores every sample without rounding, and compares exact initial and reconstructed tile bytes.
- [x] `FixedPointSymplectic.w` advances a scale-1024 two-body phase state through equal-and-opposite integer kicks and drifts, checks zero total momentum, exhausts a 256-point bounded phase grid through independent forward and inverse equations, checks signed extremes, rejects overflow before result publication, validates a generated inverse certificate, and restores the exact initial phase point without floating point or rounding state.
- [x] `EventReducer.w` reduces reordered content-identified events through a deterministic sequence map, suppresses duplicate delivery, rejects a conflicting sequence occupant without changing reduced value, writes a canonical bounded checkpoint twice under distinct owners, recovers event identities and value into a fresh map, and proves that replayed delivery cannot apply twice. Typed calls, branches, owner cleanup, canonical artifact acceptance, and complete rewind are checked.

### Toolchain

- [x] The Wheeler-written UTF-8 scanner and bounded local-declaration parser consume explicit source input, publish token and diagnostic coordinates, return a closed parse result, and rewind exactly. General Wheeler grammar coverage remains WIP-0007.
- [x] The Wheeler-native bounded bytecode emitter, canonical codec slice, and emitted-product verifier execute for the documented scalar compiler profile. General arbitrary-artifact decoding and full control, type, ownership, quantum, and workflow verification remain:
  - `compiler/Core.w` parses one linked bounded source and emits the full artifact through the shared encoding module. The direct linker handles one import. Complete plans and `graphs/plans/GraphExecutor.w` handle every rooted acyclic scalar-constant graph from two through seven imports. `compiler/Driver.w` owns the public graph-aware facade. `MinimalCompiler.w` is its thin executable wrapper, while `NativeCompilerIdentity.w` keeps output private and publishes only the verified digest.
  - Source strings are sorted canonically, and section layout is derived.
  - All 504 bytes for `LongClass` with `state long value = 7` and `value += 5` match stage 0.
  - Empty and bounded nonempty entry and helper bodies match stage 0. Ordinary
    helpers need no dummy state. The admitted profile covers typed scalar locals,
    assertions, arithmetic, guarded updates, helper calls, reverse blocks, and
    generated inverse certificates. Module-qualified names remain canonical, and
    malformed headers fail before publication. The
    [self-hosting status map](self-hosting-status.md) points to current compiler
    evidence instead of repeating each intermediate source profile here.
  - The compiler derives exact local windows and code sizes within each admitted profile.
  - Tests cover signed constants, Boolean literals, unary negation, literal and prior-local assertions, exact type windows, shared token and statement identities, decoding, canonical re-encoding, and execution.
  - A Wheeler-native bounded verifier checks emitted bytes before publication. General IR payloads and full control, type, and resource verification remain.
- [ ] Self-hosting compiler fixed point.
- [ ] Wheeler package resolver.
- [ ] Native transition trace parity.
  - [x] The Wheeler-written bounded interpreter hashes every successful ordered opcode identity with Wheeler SHA-256. Independent Java VM observations reproduce all 32 bytes across scalar, call, inverse, recursive, aggregate, ownership, storage, UTF-8, and result-slot fixtures. Malformed artifacts publish no trace identity.
  - [ ] Add interpreter-level rewind, trapped transition records, commit horizons, workflow events, and native machine-code execution to the normalized trace.

### Quantum algorithms

- [x] `WidthExplicitOracle.w` combines explicit 32-bit rotate-right semantics, a low-byte mask, and a four-row immutable classical lookup with checked indexing. `CoherentOracle.w` adds three modulo an explicit three-qubit width, marks low-bit comparison state three by controlled phase, and carries a generated adjoint. The ideal engine exhausts all eight basis inputs against an independent permutation-and-phase oracle and applies the adjoint to recover every exact input amplitude. The oracle uses no table workspace or ancilla to leave dirty.
- [x] `GroverSearch.w` composes an exact two-qubit lookup phase oracle for basis state three with diffusion and needs no workspace ancilla. The ideal engine checks the complete complex amplitude vector, a 256-shot seeded run checks the declared success threshold, and the generated adjoint is certified. `QuantumWalk.w` composes two Hadamard-coin conditional shifts on a two-node cycle, checks both exact complex distributions, applies both generated adjoints, restores basis zero, and round-trips through the canonical artifact.
- [x] `StaticPhaseEstimation.w` resolves the exact two-bit phase three quarters through two controlled powers and a two-bit inverse transform. The ideal engine checks the complete complex amplitude vector and generated-adjoint restoration. `AdaptivePhaseEstimation.w` runs two target-resident rounds, records bounded result slots `(true, false)`, feeds each result into a conditional phase or eigenstate correction, resets both measured ancillas, converges to basis zero, and leaves only final host observation. Canonical artifacts, dynamic jobs, and exact outcomes are checked.
- [x] Amplitude estimation.
  - [x] `AmplitudeEstimation.w` prepares an exact one-half good-state probability, correlates one estimate qubit by phase kickback, records explicit qubit, circuit-application, and planned-shot bounds, and carries generated adjoints for preparation and estimation. The ideal engine checks exact forward amplitudes and complete adjoint cleanup. `AmplitudeEstimate` reduces 4,096 seeded outcomes into success count, probability, standard error, visible two-error bounds, resource fields, and exact submission identity.
  - [x] The source estimator calls its controlled coherent half-turn twice in source order. Static unitary-call lowering resolves only declared methods on the caller's exact qreg, flattens nested bodies into the canonical circuit, and rejects unknown, recursive, dynamic, or cross-register calls. The sampled estimator compares independently prepared exact probabilities of one half and one, each over 4,096 shots. The certain distribution has zero standard error and exact clipped bounds.
- [x] VQE, QAOA, quantum kernel, and parameter-shift batches.
  - [x] `VqeHydrogen.w`, `QaoaMaxCut.w`, `QuantumKernelClassifier.w`, and `ParameterShift.w` replace the former combined sketch with one readable source authority per application. They carry fixed resource fields and generated adjoints. The canonical runtime portfolio binds symbolic phase and controlled-phase parameters in ordered immutable batches. VQE compares exact Z energies at zero and pi and selects the lower ansatz. The parameter-shift pair recovers derivative negative one at pi over two. Kernel overlap gives unit fidelity for equal features and zero for features separated by pi. The QAOA layer matches all eight exact real and imaginary amplitude fields. Batch and submission identities retain parameter values, order, shots, and seeds.
  - [x] The pinned one-qubit hydrogen reduction gives equal batch and single-task energy at pi. Recorded-result replay selects the same energy without another target submission, while a new seed creates a distinct retry identity. An OpenQASM executor receives the same bound static ansatz and reproduces all ideal outcomes. The one-edge QAOA fixture records exact depth five, exact cut probability one half, and a 4,096-shot bounded cut distribution. The four-entry kernel batch is exactly symmetric, trains one bounded diagonal-versus-off-diagonal classifier, and replays from result records without retaining jobs or calling the target. Reversed parameter-shift arrival order sorts by the canonical bound angle before reduction and matches exact derivative negative one.

### Dynamic and fault-tolerant

- [x] Checked-in `DynamicTeleportation.w` prepares a Bell pair, performs source-side CNOT and Hadamard, measures two target-resident slots, and applies conditional X and Z corrections through `dynamic void` source. Its canonical `.wbc` round-trips byte for byte and reaches the target qubit without a host split. `DynamicTeleportationFixture` checks both basis inputs.
- [x] The bounded dynamic semantic portfolio executes a target-resident parity-syndrome cycle with mid-circuit measurement, classical conditional correction, and ancilla reset. The three-round injected-error fixture corrects once, keeps later syndromes clear, and returns clean ancilla evidence. General fault-tolerant source IR remains.
- [x] Logical operation and magic-state planning.
  - [x] `LogicalMagicPlanning.w` records one exact four-layer schedule with separate logical-qubit, Clifford, T, measurement, T-depth, magic-state, factory-batch, and target-cycle dimensions. `LogicalResourcePlan` closes immutable nonempty layers against one content-identified factory. It derives five required states, two factory batches, and 28 target cycles without treating peak qubits or T-depth as additive operation counts. Insufficient factory batches or target cycles reject before plan identity publication.
  - [x] `LogicalTarget` requires the explicit `LOGICAL_QUBITS` capability and binds the exact descriptor, odd code distance, cycle ceiling, and per-cycle error model into its identity. The plan combines target-cycle and factory-output errors under one explicit parts-per-trillion failure budget and rejects excess before identity publication. A static physical descriptor without verified logical lowering fails at target-plan construction.
- [x] `DistributedBell.w` records one delayed-heralding branch and local discard while keeping remote destruction false. `DistributedEntanglementSession` orders two visible endpoints, requires `NETWORK_ENTANGLEMENT`, binds request and deadline cycles into a canonical session identity, persists handle-free snapshots, and restores without another request. A timely content-identified herald advances one exact branch. A missed deadline expires it. Discard after herald or expiry revokes only local use and makes no remote physical rollback claim. A static target without network capability rejects before session creation.
- [x] `DelegatedComputation.w` names protocol and threat-model codes, keeps client secret and mask distinct from provider-visible bits, accepts one transcript, and leaves `generalPrivacyClaim` false. `DelegatedComputationSession` implements bounded `MASKED_NOT_V1` under the explicit `HONEST_BUT_CURIOUS_SINGLE_PROVIDER` model. The request exposes neither mask nor opening nonce. It binds a nonce-backed secret commitment, blinded input, task, challenge, protocol, and threat model. The provider returns a challenge-bound result. The client verifies the exact NOT relation, unmasks once, and emits a transcript identity. A wrong relation and duplicate consumption fail. The fixture makes no malicious-provider, collusion, side-channel, randomness-quality, transport, or general cryptographic-privacy claim.

### Unified I/O and durable hybrid

- [x] The quarantined stage-0 portfolio executes WIP-0032 request purity, await, batch, selection, dependency graphs, positional buffers, bounded threaded overlap, cancellation races, uncertainty, malformed progress, capacity exhaustion, and receipt monotonicity. Native source effects remain.
- [x] Recoverable iterative optimizer lifecycle matrix.
  - [x] `QuantumOptimizer.w` covers waiting snapshot encoding, decode and provider-job recovery, completion and commit, replay, retry under new lineage, and cancellation after immediate completion with late-result quarantine on `StateVectorTarget`.
  - [x] `RecoverableOptimizerCampaign` bounds campaigns and batches at 64, requires angle, probability, or scalar parameter kinds to match each submission binding, and persists every logical transition through one atomic snapshot adapter. Ordered member identities restore queued and running work without resubmission. Failed, cancelled, and unknown provider states are terminal and explicit. Result application checks job and submission identity, and an applied submission identity cannot update the objective again. The two-iteration fixture restores from both active states, applies two first-batch results, suppresses a repeated second-batch result, and exercises failure, cancellation, missing-provider recovery, and changed-plan rejection.
- [x] Calibration-aware compiler. `CalibrationCompiler.w` executes the exact-epoch resource fixture. `CalibrationAwareCompiler` requests one to 64 direct semantic gates with at most 100,000 samples each, validates complete sorted gate metrics, and derives exact duration plus a parts-per-trillion union error bound. Exact and accepted-stale epochs produce distinct identities. Older, future, wrong-target, wrong-request, incomplete, and capability-denied inputs publish no plan.
- [x] Adaptive replay decision tree. `AdaptiveReplay.w` executes both branches of one bounded two-level tree and replays the recorded lower path without a target call. `AdaptiveReplayTree` validates one to 64 source-ordered nodes, forward-only distinct children, rooted reachability, terminal leaves, lowercase content identities, and at most 64 accepted observations. Fresh execution records exact node, ordinal, value, evidence identity, and selected child coordinates. Replay accepts no observation source, follows only those records, and rejects missing, trailing, reordered, changed-branch, changed-plan, or changed-identity evidence. Plan and run identities are canonical SHA-256 products. Retry derives a deterministic distinct lineage rather than mutating replay evidence.
- [x] Compensation fixture. `CompensationWorkflow.w` keeps original visibility, remedy preparation, remedy acceptance, rejection, and inverse claims in separate state. It applies one visible balance change, observes a rejected remedy without changing that balance, accepts a later remedy as a second effect, and finishes at zero while leaving `inverseClaim` false. The runtime `IoCompensation` boundary constructs its request without provider work, requires an effect-bearing original completion, issues an unforgeable receipt only after successful remedy work, and cuts a distinct VM commit horizon when accepted. Failed remedies establish no boundary. The receipt is neither durability evidence nor reversible history.
- [x] Long-running campaign and cleanup. `RecoverableOptimizerCampaign` executes the complete 64-iteration bound with one durable queued checkpoint and one applied-result checkpoint per iteration, retains 64 distinct submission identities and objectives, reaches generation 128 after its initial generation, and finishes without an active provider handle. Partial batch submission cancels every acknowledged prefix job. Invalid batch metadata, rejected queued checkpoints, failed awaits, changed result identities, terminal polling, explicit cancellation, and partial recovery all attempt cancellation for every known job before releasing handles. One cleanup failure cannot prevent later cleanup attempts. It publishes `UNKNOWN` with bounded uncertainty detail rather than claiming cancellation. `CompositeQuantumBatchJob` applies the same all-member cleanup rule when submission or cancellation fails.
- [ ] Certified `Murphy.w` adversarial schedule exploration and replay package.

### Proof, native, and packages

- [x] QFT emits a generated-adjoint certificate, and the quantum compiler example emits a circuit-equivalence certificate. Canonical proof metadata round-trips, executes through the checked examples, and the verifier rejects a minimally forged generated-inverse subject.
- [ ] Resource-bound and inverse-law certificates.
  - [x] `CertifiedInverseBounds.w` carries one generated-inverse certificate and one static straight-line step bound in the same executable. It executes both subjects, restores state, round-trips bytecode, and rewinds complete history.
  - [ ] Add symbolic and concrete qubit, ancilla, gate, depth, measurement, target-cycle, event-byte, and retry bounds tied to semantic-region and compiler identities. Add exhaustive bounded inverse inputs, clean ancillas, and unchanged borrow checks.
- [ ] Bounded certified `Foundry.w` synthesis and minimality package.
- [x] Package provenance verifier. `PackageProvenance.w` accepts one bounded witness only after archive, manifest, lock-root, target-source, build-plan, toolchain, dependency-archive, output-identity, and output-length facts agree. `PackageProvenanceVerifier` performs the full byte-level check. It decodes and canonically re-encodes the package archive, requires the exact manifest and lock root, requires the node to belong to the plan and package, hashes the exact target-source input, matches every direct manifest dependency to its planned and locked archive, binds the toolchain, checks the recorded output expectation, and publishes one domain-separated evidence identity after the complete pass. Changed archive, lock, plan, source, dependency, or output bytes publish no evidence.
- [ ] Hermetic workspace bootstrap.
- [ ] Capability-denied tool and registry mirror.
- [ ] Cross-target native trace matrix.

## Testing and acceptance

- [x] Package portfolio tests require every checked-in example and conformance `.w` file to belong to a canonical manifest target and round-trip through its canonical package archive. Compiler, runtime, and package suites execute those selected targets in ordinary CI.
- [ ] The portfolio covers every accepted source statement, type, effect, bytecode family, workflow edge, event kind, target capability, persistence record, and proof record.
- [ ] Every capability has at least one successful fixture and one actionable rejection fixture.
- [x] Every currently admitted sampled or provider-backed portfolio fixture distinguishes replay from fresh execution. Replay consumes recorded evidence without submission. Retry or another seeded run creates a new branch and execution lineage.
- [ ] Every external effect fixture defines abort, commit, cancellation, compensation, or barrier behavior.
- [x] Implemented aggregate and owned-storage fixtures cover malformed descriptors and operands, index and capacity exhaustion, mutable-loan alias rejection, owner escape and use after move, wrong drop order, cleanup after transfer, and exact rewind. Returned loans and dynamic split and join remain outside the accepted profile.
- [x] Every implemented quantum fixture declares little-endian basis and sample interpretation, exact or sampled evidence, qubit and shot bounds, required target capabilities, seed policy where deterministic, and acceptance thresholds where statistical. Exact dynamic fixtures make no hardware-fidelity claim.
- [x] Implemented proof fixtures name the bounded `ProofKernel` rule profile and reject minimally corrupted rule arguments, subject bodies, inverse bodies, and nonreversible subjects. Passing tests remain evidence about the named proposition rather than a substitute theorem.
- [ ] Compiler stages produce identical portfolio artifacts and diagnostics for their shared profile.
- [ ] Interpreted and native executions produce matching normalized traces.
  - [x] Stage-0 and Wheeler interpreter runs produce the same successful-opcode trace identity and terminal globals across the bounded interpreter corpus. The identity is SHA-256 over ordered two-byte opcode values.
  - [ ] Extend equality to interpreter rewind, traps, commit horizons, semantic workflow events, and actual native images.
- [ ] The package manager builds the complete implemented portfolio offline from a locked vendor set.
- [x] `examples.md` lists readable checked-in programs and current results. The internal conformance manual lists only checked-in verification and recovery subjects. Planned portfolio entries remain in this WIP and future pages rather than appearing as implemented examples.

## Alternatives

### Keep only minimal language examples

Rejected. Minimal fixtures do not force the aggregate values, effects, persistence, target planning, diagnostics, packages, and native execution needed by real programs.

### Check in aspirational source files

Rejected. Unsupported `.w` files create a second fictional language. Planned programs stay in this WIP until executable.

### Use benchmark kernels without expected semantics

Rejected. Performance data is useful only after a fixture defines correct output, traps, bounds, and effects.

### Depend on live hardware for realism

Rejected. Deterministic simulators and lifecycle mocks establish semantics. Opt-in hardware runs provide operational evidence under explicit target and budget identities.

## Open questions

- Which three aggregate/storage fixtures should define the first bootstrap heap profile (owner: language, VM, and compiler maintainers. Decision point: before aggregate bytecode lands)?
- Which bounded decoder and loop forms should extend the accepted `dynamic void` preparation, measurement, reset, and X/Z conditional profile? **Owner:** quantum target maintainers. **Decision point:** before adaptive phase estimation.
- Which proof checker is small enough to join the trusted recovery graph (owner: proof and bootstrap maintainers. Decision point: before formal QFT claims land)?
- Which statistical testing library and report schema belong in the Wheeler package test contract (owner: runtime and package maintainers. Decision point: before sampled portfolio tests expand)?

## Integration with reversible concurrency

### Reversible concurrency fixtures

`BakeryMutex.w` implements one-shot bounded Lamport bakery with WIP-0039 tasks and SC atomics. It covers canonical scheduling, replay, exploration, deadlock, overflow, and exact rewind.

`ReversibleBakery.w` adds a WIP-0040 TaskScheduleWitness. Forward then source inverse restores application, task, atomic, ownership, control-witness, and schedule-witness state.

`BakeryScheduleModel.w` interprets a tiny finite schedule as reversible model data, marks a violation bit, and uncomputes cleanly. Direct coherent lifting of live bakery rejects.

A later `BlackWhiteBakery.w` covers repeated bounded entry after generic atomics and reversible control exist.

## References
- [WIP-0039](WIP-0039-deterministic-structured-task-machine-and-global-rewind.md)
- [WIP-0040](WIP-0040-explicit-schedule-witnesses-for-reversible-task-scopes.md)

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0003](WIP-0003-quantum-target-and-qiskit-backend.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [Executable examples](../../public/examples.md)
