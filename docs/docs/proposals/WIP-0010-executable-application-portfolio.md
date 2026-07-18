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

Wheeler's application portfolio is an executable conformance surface, not a syntax gallery. It shall demonstrate reversible systems programming, coherent classical/quantum reuse, current hardware workflows, durable hybrid computation, self-hosting, package management, native execution, and checkable claims.

Each portfolio item has a named semantic purpose and an implementation gate. A `.w` file enters the repository only when the compiler, bytecode, verifier, runtime or target planner, Tree-sitter grammar, tests, and documentation support every construct it uses. Designs that need future syntax remain in this WIP until that vertical slice exists.

The portfolio is intentionally broader than textbook quantum algorithms. Wheeler must prove useful for compilers, codecs, package resolution, transactional state, simulation, optimization, error correction, target planning, and long-running recovery. Quantum examples must state whether they require static circuits, batches, expectations, dynamic control, logical qubits, sessions, networking, or proof support.

## Goals

- Maintain a concrete application target for every major semantic and tooling capability.
- Exercise Wheeler as a general systems language rather than a gate-circuit notation.
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

1. Wheeler source using the accepted profile;
2. canonical `.wbc` round-trip coverage;
3. Tree-sitter parsing without unexpected `ERROR` or `MISSING` nodes;
4. deterministic expected state or a declared statistical test with fixed confidence and seed policy;
5. target capability requirements and a negative planning test for missing requirements;
6. replay and retry expectations when observations occur;
7. explicit qubit, shot, event, memory, stack, and step ceilings;
8. a concise reference entry explaining what the fixture proves and what it does not prove.

A formal fixture additionally identifies its trusted checker, claim schema, assumptions, and certificate bounds. A native or bootstrap fixture identifies its compiler, runtime, platform ABI, package lock, and reproducibility inputs.

No authored fixture file exceeds 1,000 lines. Larger applications are packages composed of smaller modules.

## Current executable base

The repository currently executes these bounded fixtures:

- `Counter.w`: generated inverse and reverse-block order;
- `BinaryTree.w`: fixed-capacity reversible state layout;
- `BootstrapControl.w`: signed locals, expressions, branch joins, and a source-bounded loop;
- `FunctionValues.w`: signed parameters, returns, static value calls, and callee control flow;
- `CoherentOracle.w`: classical and coherent XOR behavior;
- `QFT.w`: unitary execution and generated adjoint;
- `QFTProof.w`: executable inverse law;
- `QuantumOptimizer.w`: repeated observations, classical acceptance, commit, and replay;
- `QuantumNeuralNetwork.w`: one-bit coherent layer;
- `QuantumCompiler.w`: source/normalized circuit equivalence on basis input;
- `SurfaceCode.w`: static correction kernel and dynamic-target boundary.

These files are starting points. Their names remain stable when richer implementations preserve the same teaching role; otherwise a new fixture gets a distinct name and contract.

## Reversible systems applications

### Reversible packet codec

`ReversiblePacketCodec.w` parses a bounded binary frame into a typed record and emits the identical bytes through its generated inverse. It covers byte slices, tagged variants, checked lengths, checksums, malformed-input results, and region cleanup.

Acceptance requires:

- `decode(encode(value)) == value` over generated bounded records;
- `encode(decode(bytes)) == bytes` for canonical frames;
- malformed lengths and checksums fail without partial output;
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

`bytecode/codec.w` reads and writes canonical `.wbc`; `bytecode/verify.w` rejects malformed control, type, resource, workflow, and quantum records. Stage output and diagnostics match the independent conformance corpus byte for byte where specified.

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

`PhaseEstimation.w` estimates a phase for a unitary with known eigenstate. A static implementation covers controlled powers and inverse QFT; an adaptive implementation is a separate dynamic-target fixture with measurement-conditioned rotations.

### Amplitude estimation

`AmplitudeEstimation.w` estimates a known prepared amplitude and records estimator uncertainty. It covers controlled coherent calls, repeated applications, result schemas beyond one basis outcome, and resource accounting.

## Variational and sampled applications

### Molecular energy

`VqeHydrogen.w` estimates a small molecular Hamiltonian with parameterized circuit batches and expectation results. The fixture pins the Hamiltonian, ansatz, optimizer policy, seeds, shot allocation, and confidence criterion.

Acceptance requires:

- exact state-vector energy for a reference parameter point;
- batch and single-task estimators agree under deterministic simulation;
- replay reaches the same optimizer state without target calls;
- fresh retry creates a distinct observation lineage;
- an OpenQASM executor receives equivalent static circuits.

### Graph optimization

`QaoaMaxCut.w` solves a small fixed graph. It exercises graph aggregates, parameter binding, commuting gate scheduling, expectation evaluation, and target-depth planning. The result contract compares objective value and observed cut distribution rather than one lucky sample.

### Quantum kernel classifier

`QuantumKernelClassifier.w` builds a deterministic toy feature map, submits a symmetric kernel batch, and trains a bounded classical classifier. It checks batch identity, matrix symmetry, replay, and absence of quantum handles between jobs.

### Parameter-shift gradient

`ParameterShift.w` submits paired parameter bindings, reduces results in canonical parameter order independent of completion order, and compares the sampled gradient with the exact simulator derivative.

### Monte Carlo risk estimate

`AmplitudeRisk.w` encodes a small discrete loss distribution and estimates a tail probability. It states all approximation, fixed-point, qubit, shot, and confidence bounds. It does not claim an advantage from a fixture-sized instance.

## Dynamic and fault-tolerant applications

### Teleportation

`Teleportation.w` performs Bell preparation, mid-circuit measurement, classical conditions, and corrections inside one dynamic target region. Static targets must reject it with the complete missing-capability set. An ideal dynamic target checks all basis inputs and selected superpositions.

### Repeated error correction

`ErrorCorrectionCycle.w` performs syndrome preparation, measurement, reset, bounded decoding, correction, and cycle reporting as a target-resident workflow. It upgrades the static `SurfaceCode.w` role when dynamic control exists.

Acceptance requires target-resident feedback capability, bounded decoder latency metadata, replayable host-visible cycle results, and explicit separation between logical correction and physical rollback.

### Logical lattice operation

`LogicalCnot.w` expresses a logical operation and resource request without physical coupling-map assumptions. A mock logical target plans code distance, logical qubits, cycles, and failure budget. A physical static target rejects the semantic operation unless an explicit verified lowering is available.

### Magic-state resource plan

`MagicStateFactory.w` composes logical resources, factory throughput, distillation error, and consumption schedule into a bounded target plan. It is primarily a type, unit, planning, and proof-certificate fixture; ordinary CI uses a deterministic planner, not hardware.

### Distributed Bell pair

`DistributedBell.w` requests networked entanglement between two target endpoints, persists session identities, handles delayed heralding, and discards a timed-out branch without treating cancellation as destroyed entanglement. It requires an explicit network/session capability and a mock target.

### Blind delegated computation

`DelegatedComputation.w` separates client-owned secret preparation from provider execution and validates a bounded verification result. The fixture must state its protocol and threat model; ordinary target metadata or redaction is not presented as cryptographic privacy.

## Durable hybrid applications

### Recoverable optimizer

`QuantumOptimizer.w` grows into a bounded iterative optimizer with typed parameters, parameterized batches, persisted continuation after each iteration, queued-job recovery, replay, fresh retry, and commit horizons.

The test suite stops and restores the run in queued, running, succeeded, failed, cancelled, and unknown states. Duplicate result delivery cannot apply an update twice.

### Calibration-aware circuit compiler

`CalibrationCompiler.w` compiles a semantic circuit against an immutable target descriptor and calibration epoch, submits bounded calibration experiments, and rejects stale results unless policy explicitly accepts them. Provider data remains bounded target input; credentials and provider objects never enter compiler state.

### Adaptive experiment

`AdaptivePhaseEstimation.w` selects each next circuit from recorded prior observations. Replay follows the identical decision tree without target calls; fresh mode may follow another valid branch. Completion arrival order cannot change batch reduction.

### Hybrid workflow compensation

`CompensatedExperiment.w` combines a target submission with a mock external reservation or accounting effect. Abort before and after observation demonstrates cancellation, branch discard, declared compensation, compensation failure, and commit without claiming distributed physical rollback.

### Long-running scientific campaign

`ExperimentCampaign.w` executes a bounded set of experiments over target descriptor epochs, persists after every result, applies budget limits, quarantines stale jobs, and emits a reproducible report from recorded observations. It exercises event cleanup while retaining live continuation references.

## Proof and certificate applications

### QFT unitary certificate

`QFTProof.w` grows from an executable inverse law into a checked claim that its gate composition is unitary and its generated adjoint is exact. The trusted checker validates a bounded certificate over canonical circuit identity.

### Circuit equivalence

`CircuitEquivalence.w` proves or exhaustively certifies that source and normalized circuits in `QuantumCompiler.w` have the same small-width unitary up to declared global phase. Larger claims require a specified proof method rather than simulator sampling.

### Resource-bound certificate

`ResourceBound.w` checks symbolic and concrete upper bounds for qubits, ancillas, gates, depth, measurements, target cycles, event bytes, and retries. Target planning may rely on the checked certificate only when semantic region and compiler identities match.

### Reversible function law

`InverseLaw.w` generates bounded inputs for a `rev` function and checks `inverse(forward(x)) == x`, clean ancillas, and unchanged borrowed state. Testing supports a claim but does not become a universal proof without a trusted exhaustive or symbolic certificate.

### Package provenance

`PackageProvenance.w` verifies a package archive's member hashes, manifest identity, dependency lock, compiler identity, and build-plan provenance. Signature verification establishes namespace authorization; it does not establish semantic correctness of package code.

## Native and package applications

### Hermetic workspace build

The Wheeler workspace builds compiler, runtime, package manager, tools, examples, and documentation inputs through `wheel` with network disabled. Two clean builds produce identical canonical artifacts, lockfile, package archives, and plans.

### Capability-denied build tool

`CapabilityProbe.w` is a negative tool fixture that attempts undeclared file, environment, clock, random, network, process, credential, and target access. Every attempt fails before the host effect and leaves no output.

### Registry mirror

`RegistryMirror.w` verifies and mirrors immutable package objects by content identity. Random transfer order, interruption, duplicate delivery, and mirror path changes do not alter the resulting index snapshot.

### Cross-target native execution

`NativeMatrix.w` is a package of small semantic kernels compiled for every tier-1 target triple. Native and interpreted normalized traces match; native image identities remain derived from the same `.wbc` artifacts.

## Teaching applications

The teaching track uses small fixtures with one primary law each:

- reversible counter and swap;
- fixed-capacity structured state;
- packet codec and `Result` diagnostics;
- coherent bit permutation;
- Bell state and measurement;
- QFT and adjoint;
- Grover oracle and uncomputation;
- measured optimizer, persistence, and replay;
- dynamic teleportation and capability rejection;
- package resolution and compiler bootstrap;
- checked circuit equivalence and resource bounds.

A teaching example may share implementation modules with a portfolio application but keeps its entry point and expected result small enough to inspect manually.

## Implementation policy

Portfolio work follows these rules:

- The required semantic WIP is accepted or implementing before source syntax lands.
- One feature slice lands parser, model, bytecode, verifier, runtime, Tree-sitter, negative tests, reference text, and at least one fixture together.
- The fixture states exact current scope in source comments and reference documentation.
- Mock targets model lifecycle and capabilities; they do not report fake hardware fidelity.
- Randomized tests record seeds and bound case counts.
- Statistical tests state null hypothesis, confidence, tolerance, and flake budget.
- Live tests are opt-in and never gate deterministic CI.
- Superseded bounded implementations are replaced in place; no compatibility path keeps two semantic authorities.

## Progress

### Executable base

- [x] Counter and fixed-capacity tree fixtures execute.
- [x] Coherent XOR and one-bit layer fixtures execute classically and quantumly.
- [x] QFT and executable adjoint-law fixtures execute.
- [x] Bounded optimizer records observations and replays without target calls.
- [x] Circuit normalization and static correction fixtures execute.

### Reversible systems

- [ ] Reversible packet codec.
- [ ] Transactional persistent index.
- [ ] Incremental dependency graph.
- [ ] Integer wavelet transform.
- [ ] Fixed-point symplectic simulation.
- [ ] Wheeler event-reducer fixture.

### Toolchain

- [ ] Wheeler lexer and parser.
- [ ] Wheeler bytecode codec and verifier.
- [ ] Self-hosting compiler fixed point.
- [ ] Wheeler package resolver.
- [ ] Native transition trace parity.

### Quantum algorithms

- [ ] Width-explicit arithmetic and lookup oracles.
- [ ] Grover search and quantum walk.
- [ ] Static and adaptive phase estimation.
- [ ] Amplitude estimation.
- [ ] VQE, QAOA, quantum kernel, and parameter-shift batches.

### Dynamic and fault-tolerant

- [ ] Dynamic teleportation.
- [ ] Target-resident error-correction cycle.
- [ ] Logical operation and magic-state planning.
- [ ] Distributed entanglement session.
- [ ] Delegated computation protocol.

### Durable hybrid

- [ ] Recoverable iterative optimizer lifecycle matrix.
- [ ] Calibration-aware compiler.
- [ ] Adaptive replay decision tree.
- [ ] Compensation fixture.
- [ ] Long-running campaign and cleanup.

### Proof, native, and packages

- [ ] Trusted QFT and circuit-equivalence certificates.
- [ ] Resource-bound and inverse-law certificates.
- [ ] Package provenance verifier.
- [ ] Hermetic workspace bootstrap.
- [ ] Capability-denied tool and registry mirror.
- [ ] Cross-target native trace matrix.

## Testing and acceptance

- [ ] Every checked-in `.w` file satisfies the fixture contract and ordinary CI.
- [ ] The portfolio covers every accepted source statement, type, effect, bytecode family, workflow edge, event kind, target capability, persistence record, and proof record.
- [ ] Every capability has at least one successful fixture and one actionable rejection fixture.
- [ ] Every nondeterministic fixture defines replay and fresh-execution behavior.
- [ ] Every external effect fixture defines abort, commit, cancellation, compensation, or barrier behavior.
- [ ] Every aggregate and storage fixture has malformed, exhausted, aliasing, and cleanup tests.
- [ ] Every quantum fixture declares endianness, approximation, resource, target, and statistical contracts.
- [ ] Every proof fixture identifies its trusted checker and rejects a minimally corrupted certificate.
- [ ] Compiler stages produce identical portfolio artifacts and diagnostics for their shared profile.
- [ ] Interpreted and native executions produce matching normalized traces.
- [ ] The package manager builds the complete implemented portfolio offline from a locked vendor set.
- [ ] The documentation index reports implementation state without presenting planned fixtures as current behavior.

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

- Which three aggregate/storage fixtures should define the first bootstrap heap profile? — **Owner:** language, VM, and compiler maintainers — **Decide by:** before aggregate bytecode lands
- Which dynamic simulator and capability vocabulary should gate teleportation and correction fixtures? — **Owner:** quantum target maintainers — **Decide by:** before dynamic workflow implementation
- Which proof checker is small enough to join the trusted recovery graph? — **Owner:** proof and bootstrap maintainers — **Decide by:** before formal QFT claims land
- Which statistical testing library and report schema belong in the Wheeler package test contract? — **Owner:** runtime and package maintainers — **Decide by:** before sampled portfolio tests expand

## References

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
- [Executable examples](../examples.md)
