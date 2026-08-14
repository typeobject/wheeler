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
- `CoherentOracle.w`: classical and coherent XOR behavior.
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

This fixture is the gate for broadening coherent eligibility beyond XOR. Checked signed arithmetic is never substituted for modular arithmetic.

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

`QuantumOptimizer.w` grows into a bounded iterative optimizer with typed parameters, parameterized batches, persisted continuation after each iteration, queued-job recovery, replay, fresh retry, and commit horizons.

The test suite stops and restores the run in queued, running, succeeded, failed, cancelled, and unknown states. Duplicate result delivery cannot apply an update twice.

### Calibration-aware circuit compiler

`CalibrationCompiler.w` compiles a semantic circuit against an immutable target descriptor and calibration epoch, submits bounded calibration experiments, and rejects stale results unless policy explicitly accepts them. Provider data remains bounded target input. Credentials and provider objects never enter compiler state.

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

- [ ] Reversible packet codec.
  - [x] `ReversiblePacketCodec.w` encodes a typed record into four region-owned bytes, validates and decodes through a closed value-or-malformed result, checks both decode-encode directions, exhausts 256 bounded field combinations, distinguishes length and checksum errors without partial decode state, cleans every owner, and separately checks a generated inverse over the equivalent fixed word layout.
  - [ ] Make byte-frame encoding itself participate in a checked inverse relation rather than relying on the parallel fixed-word transform.
- [ ] Transactional persistent index.
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
  - Empty and one- through sixty-four-statement entry bodies also match. Signed-result entries require at least one helper call anywhere in that bounded sequence. Later calls may consume prior results. Public, explicit-private, and unqualified helpers have the same independent bound, including the empty body. Ordinary helpers need no class state. Empty reversible helpers and generated-inverse theorems also avoid dummy globals. Nonempty reversible helpers retain the bounded state-update profile. Repeated visibility does not receive a participation trophy. Canonical module-qualified entry and helper names match stage 0. Malformed module headers fail before output. The suite covers signed and Boolean locals, prior signed- and Boolean-local copies, prior-Boolean negation, typed equality declarations over prior locals or signed-local/literal pairs, direct assertions over prior Boolean or signed locals, signed-literal equality assertions, signed-local less-than declarations over prior locals or literal right operands, and direct ordering assertions, one-arm positive or negated prior-Boolean `if` guards and signed-local/literal equality and less-than guards over global assignment and checked updates from literals or prior locals, checked signed-local `+`, `-`, `^`, `*`, `/`, and `%` expressions over literal or prior-local right operands, resolved signed-local and Boolean-local assertions, one global, literal and prior-local assignment, checked arithmetic and XOR over literals or prior locals, void helpers, zero-argument Boolean result helpers with bounded local preludes, one- and two-argument Boolean helpers with literal or prior-local arguments and bounded parameter-aware local preludes, zero-argument signed result helpers with bounded local preludes, one-argument signed helpers with literal or prior-local arguments and bounded parameter-aware local preludes, two-argument signed helpers over literals or prior entry locals with bounded parameter-aware local preludes, and direct or checked arithmetic results over literals or parameters, reverse blocks, and generated inverse certificates.
  - The compiler derives zero through twenty local slots and exact code sizes.
  - Tests cover signed constants, Boolean literals, unary negation, literal and prior-local assertions, exact type windows, shared token and statement identities, decoding, canonical re-encoding, and execution.
  - A Wheeler-native bounded verifier checks emitted bytes before publication. General IR payloads and full control, type, and resource verification remain.
- [ ] Self-hosting compiler fixed point.
- [ ] Wheeler package resolver.
- [ ] Native transition trace parity.
  - [x] The Wheeler-written bounded interpreter hashes every successful ordered opcode identity with Wheeler SHA-256. Independent Java VM observations reproduce all 32 bytes across scalar, call, inverse, recursive, aggregate, ownership, storage, UTF-8, and result-slot fixtures. Malformed artifacts publish no trace identity.
  - [ ] Add interpreter-level rewind, trapped transition records, commit horizons, workflow events, and native machine-code execution to the normalized trace.

### Quantum algorithms

- [ ] Width-explicit arithmetic and lookup oracles.
  - [x] `WidthExplicitOracle.w` combines explicit 32-bit rotate-right semantics, a low-byte mask, and a four-row immutable classical lookup. Checked indexing and exact words make host-width drift visible.
  - [ ] Add finite modular add and compare, coherent controlled marking, clean table workspace and ancillas, exhaustive basis comparison, and generated inverse checks.
- [ ] Grover search and quantum walk.
  - [x] `GroverSearch.w` executes one four-element phase-oracle and diffusion iteration with a generated adjoint. `QuantumWalk.w` executes and uncomputes one Hadamard-coin conditional shift. Both round-trip and run on the bounded ideal target.
  - [ ] Compose the lookup oracle with clean ancillas, compare exact amplitudes and seeded success thresholds, and add repeated walk composition plus graph-cycle distribution comparison.
- [ ] Static and adaptive phase estimation.
  - [x] `StaticPhaseEstimation.w` resolves one exact binary phase with one controlled power and the one-bit inverse transform. `AdaptivePhaseEstimation.w` measures that bit in a dynamic region, conditionally corrects the eigenstate, resets the ancilla, and leaves only final host observation. Artifacts, result slots, jobs, and exact outcomes are checked.
  - [ ] Add multiple controlled powers, a multi-bit inverse QFT, measurement-conditioned phase rotations, and exact comparison of both estimators.
- [ ] Amplitude estimation.
- [ ] VQE, QAOA, quantum kernel, and parameter-shift batches.

### Dynamic and fault-tolerant

- [x] Checked-in `DynamicTeleportation.w` prepares a Bell pair, performs source-side CNOT and Hadamard, measures two target-resident slots, and applies conditional X and Z corrections through `dynamic void` source. Its canonical `.wbc` round-trips byte for byte and reaches the target qubit without a host split. `DynamicTeleportationFixture` checks both basis inputs.
- [x] The bounded dynamic semantic portfolio executes a target-resident parity-syndrome cycle with mid-circuit measurement, classical conditional correction, and ancilla reset. The three-round injected-error fixture corrects once, keeps later syndromes clear, and returns clean ancilla evidence. General fault-tolerant source IR remains.
- [ ] Logical operation and magic-state planning.
- [ ] Distributed entanglement session.
- [ ] Delegated computation protocol.

### Unified I/O and durable hybrid

- [x] The quarantined stage-0 portfolio executes WIP-0032 request purity, await, batch, selection, dependency graphs, positional buffers, bounded threaded overlap, cancellation races, uncertainty, malformed progress, capacity exhaustion, and receipt monotonicity. Native source effects remain.
- [ ] Recoverable iterative optimizer lifecycle matrix.
  - [x] `QuantumOptimizer.w` now covers waiting snapshot encoding, decode and provider-job recovery, completion and commit, replay, retry under new lineage, and cancellation after immediate completion with late-result quarantine on `StateVectorTarget`.
  - [ ] Add bounded iterations and typed parameters, parameterized batches, persistence after every iteration, queued and running restore points, failed, cancelled, and unknown provider states, and duplicate-result suppression on the application itself.
- [ ] Calibration-aware compiler.
- [ ] Adaptive replay decision tree.
- [ ] Compensation fixture.
- [ ] Long-running campaign and cleanup.
- [ ] Certified `Murphy.w` adversarial schedule exploration and replay package.

### Proof, native, and packages

- [x] QFT emits a generated-adjoint certificate, and the quantum compiler example emits a circuit-equivalence certificate. Canonical proof metadata round-trips, executes through the checked examples, and the verifier rejects a minimally forged generated-inverse subject.
- [ ] Resource-bound and inverse-law certificates.
  - [x] `CertifiedInverseBounds.w` carries one generated-inverse certificate and one static straight-line step bound in the same executable. It executes both subjects, restores state, round-trips bytecode, and rewinds complete history.
  - [ ] Add symbolic and concrete qubit, ancilla, gate, depth, measurement, target-cycle, event-byte, and retry bounds tied to semantic-region and compiler identities. Add exhaustive bounded inverse inputs, clean ancillas, and unchanged borrow checks.
- [ ] Bounded certified `Foundry.w` synthesis and minimality package.
- [ ] Package provenance verifier.
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
