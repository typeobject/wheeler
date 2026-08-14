# Executable examples

Every checked-in `.w` file must pass both the compiler and the Tree-sitter grammar. Classical examples run on the VM. Quantum and hybrid examples use asynchronous `QuantumTarget` jobs on the ideal state-vector target. Before any example runs, its bytecode must complete a canonical round trip.

Each example has a fixed bound. It shows behavior that works today and names any limit it reaches. The `wheeler.examples` package contains only programs meant to be read as examples. Bootstrap probes, identity codecs, and native differential subjects remain in the repository's internal conformance manual.

## Exact bundle example

This self-contained case executes twice during the semantic documentation build. The bundle retains its source, artifact, output, and result identities. A failed compile, trap, replay mismatch, or output mismatch prevents publication.

```wheeler-exact name=answer-byte output=2a
module documentation.answer_byte;

classical class AnswerByte {
  entry void main(borrow utf8 input, borrow mut bytes output) {
    assert(bufferLength(input) == 0);
    setByte(output, 0, 42);
  }
}
```

## Examples

### `CertifiedInverseBounds.w`

Source: [`CertifiedInverseBounds.w`](../../wheeler-examples/src/main/wheeler/proof/CertifiedInverseBounds.w).

Covers: One generated inverse body, one kernel-checked inverse-law certificate, one straight-line value routine, one static step-bound certificate, exact execution, restored reversible state, and complete VM rewind.

Expected result: `observed = 1`, `value = 0`, `successor = 5`.

### `Counter.w`

Source: [`Counter.w`](../../wheeler-examples/src/main/wheeler/classical/control/Counter.w).

Covers: Generated inverse calls, reverse-block order, kernel-checked generated-inverse theorem, and byte-identical compilation by the Wheeler-written bounded compiler.

Expected result: `count = 0`.

### `EventReducer.w`

Source: [`EventReducer.w`](../../wheeler-examples/src/main/wheeler/classical/control/EventReducer.w).

Covers: Reordered content-identified event delivery, deterministic sequence storage, duplicate suppression, conflicting-occupant rejection, duplicate and conflict counts distinct from reduced value, canonical checkpoint bytes under independent owners, fresh-map recovery, and exactly-once resumed delivery.

Expected result: `lastEvent = checkpointSequence = 2`, `reduced = checkpointValue = resumedValue = 12`, `duplicates = 2`, and `conflicts = 1`.

### `BinaryTree.w`

Source: [`BinaryTree.w`](../../wheeler-examples/src/main/wheeler/classical/data/BinaryTree.w).

Covers: Fixed-capacity reversible tree slots.

Expected result: `root = left = right = 0`.

### `BootstrapControl.w`

Source: [`BootstrapControl.w`](../../wheeler-examples/src/main/wheeler/classical/control/BootstrapControl.w).

Covers: Typed signed and Boolean locals, expressions, branch joins, and a bounded counted `for`.

Expected result: `sum = 10`, `branch = 1`.

### `FixedArrays.w`

Files: [`FixedArrays.w`](../../wheeler-examples/src/main/wheeler/classical/data/FixedArrays.w) + [`collections/FixedLongs.w`](../../wheeler-core/src/main/wheeler/collections/FixedLongs.w).

Covers: Fixed immutable arrays, signed/Boolean scalar arrays embedded in records and variant payloads, nonescaping borrowed slices, locked core reductions, checked indexing, and structural equality.

Expected result: `selected = 6`, `sum = 20`, `middleSum = 10`, `equal = 1`, `recordSelected = 7`, `variantSelected = 13`.

### `FixedPointSymplectic.w`

Source: [`FixedPointSymplectic.w`](../../wheeler-examples/src/main/wheeler/classical/data/FixedPointSymplectic.w).

Covers: Scale-1024 two-body phase-space coordinates, equal-and-opposite integer kicks and drifts, zero total momentum, 256 exhaustive bounded phase cases, signed extremes, checked overflow rejection, a generated inverse certificate, exact observed coordinates, and complete phase-point restoration without division or rounding.

Expected result: observed phase points are `(10240, 3072)` and `(-10240, -3072)`. Restored points are `(7168, 5120)` and `(-7168, -5120)`, and `generatedCases = 256`.

### `FrozenUtf8.w`

Files: [`FrozenUtf8.w`](../../wheeler-examples/src/main/wheeler/text/FrozenUtf8.w) + [`text/Utf8.w`](../../wheeler-core/src/main/wheeler/text/Utf8.w).

Covers: Strict byte-owner freezing plus locked core metrics/scalar inspection over nested nonescaping immutable UTF-8 parameter borrows.

Expected result: `byteLength = 6`, `scalarCount = 3`, `middleScalar = 8364`, `valid = 1`.

### `FiniteEnums.w`

Source: [`FiniteEnums.w`](../../wheeler-examples/src/main/wheeler/classical/data/FiniteEnums.w).

Covers: Compile-time scalar constants and a finite enum elaborated to a payload-free variant.

Expected behavior:

- Checked constant folding emits no extra global.
- Exhaustive enum matching selects `Right` and produces `selected = 7`.
- Compiler acceptance compares enum spelling with the equivalent nullary variant bytes, executes both cases, and rejects missing arms or mixed-type equality.
- Complete rewind.

### `FunctionValues.w`

Source: [`FunctionValues.w`](../../wheeler-examples/src/main/wheeler/classical/control/FunctionValues.w).

Covers: Signed/Boolean values, typed calls, right-associative logical negation, a callee loop, and a named compile-time constant used by a kernel-checked straight-line step bound.

Expected result: `result = 10`.

### `HostBinaryInput.w`

Source: [`HostBinaryInput.w`](../../wheeler-examples/src/main/wheeler/host/HostBinaryInput.w).

Covers: Explicit immutable `byteview` host input, arbitrary octet reads, bounded byte output, defensive input copying, and exact rewind.

Expected behavior:

- Input `00 ff 7f 80` gives `byteLength = 4`, `middleByte = 255`, `checksum = 510`.
- Output `00 80`.
- UTF-8 binding and source mutation are rejected.

### `HostInput.w`

Source: [`HostInput.w`](../../wheeler-examples/src/main/wheeler/host/HostInput.w).

Covers: Explicit bounded UTF-8 input and byte-output borrows with no ambient file/network access.

Expected behavior:

- For UTF-8 `A¢` and capacity 2: globals `byteLength = 3`, `scalarCount = outputLength = 2`, `firstScalar = 65`.
- Output `A!`.

### `IncrementalDependencyGraph.w`

Source: [`IncrementalDependencyGraph.w`](../../wheeler-examples/src/main/wheeler/classical/control/IncrementalDependencyGraph.w).

Covers: A mutable four-node adjacency table, a deterministic signed map for versions, bounded breadth-first work queues and visited sets, a tagged accepted-or-cycle result, rollback of a tentative back edge, explicit staged and rolled-back phases, deterministic affected-node invalidation, and region cleanup.

Expected result: every node has version `2`, `rebuilds = affected = 4`, `cycleRejected = 4`, and `transactionPhase = 2`.

### `TransactionalPersistentIndex.w`

Source: [`TransactionalPersistentIndex.w`](../../wheeler-examples/src/main/wheeler/classical/control/TransactionalPersistentIndex.w).

Covers: Copy-on-write root staging, root-before-marker commit ordering, deterministic transaction identities, tagged duplicate rejection, an injected marker-free torn record, bounded committed-record scanning, and reopen of the latest complete root. A native companion writes the same log through `NativePositionalFile`, forces payload and marker separately, forces a second payload without its marker, halts the child process without cleanup, and recovers from a fresh parent-process capability.

Expected result: `committedRoot = stagedRoot = reopenedRoot = 11`, `reopenedSequence = commitMarkerObserved = duplicateRejected = 1`, and `tornRecovered = 2`. Native recovery reads exact bytes `(7, 0, 1, 11, 1, 1, 19, 2, 0)` and selects root `11` at sequence `1`.

This is process-crash evidence under the declared FileChannel force contract. It is not power-cut, filesystem, device-cache, or namespace-durability evidence.

### `IntegerWaveletTransform.w`

Source: [`IntegerWaveletTransform.w`](../../wheeler-examples/src/main/wheeler/classical/data/IntegerWaveletTransform.w).

Covers: Determinant-one lifting over a two-pair integer tile, 256 exhaustive bounded coefficient cases, signed extremes, checked overflow rejection, a generated inverse certificate, exact transformed coefficients, byte-identical tile reconstruction, and lossless restoration without rounding state.

Expected result: observed coefficient pairs are `(4, 10)` and `(8, 21)`. Restored sample pairs are `(10, 6)` and `(21, 13)`, and `generatedCases = 256`.

### `LoopControl.w`

Source: [`LoopControl.w`](../../wheeler-examples/src/main/wheeler/classical/control/LoopControl.w).

Covers: Early typed return plus bounded `break` and `continue` edges.

Expected result: `sum = 12`, `selected = 7`.

### `modules/ModuleMain.w`

Files: [`modules/ModuleMain.w`](../../wheeler-examples/src/main/wheeler/modules/ModuleMain.w) + [`Arithmetic.w`](../../wheeler-examples/src/main/wheeler/modules/Arithmetic.w) + [`Collections.w`](../../wheeler-examples/src/main/wheeler/modules/Collections.w) + [`Results.w`](../../wheeler-examples/src/main/wheeler/modules/Results.w).

Covers: Exact source set, sorted imports, qualified calls and value types, private helper, and direct public function/record/variant/scalar-array/slice APIs. The exported `ArrayBox` carries a fixed scalar array across the module boundary.

Expected result: `result = 18`, `decoded = 9`, `arrayValue = 5`, `arrayRecordValue = 6`, `sliceValue = 15`, `nominalArrayValue = 8`, `nominalSliceValue = 26`, `qualifiedVariant = 1`.

### `LongMap.w`

Files: [`LongMap.w`](../../wheeler-examples/src/main/wheeler/classical/data/LongMap.w) + [`collections/LongMap.w`](../../wheeler-core/src/main/wheeler/collections/LongMap.w).

Covers: Region-owned signed map using the locked core package's deterministic insert/lookup and membership API, nested exclusive mutable parameter borrows, and drop.

Expected result: `selected = 17`, `zeroKey = 5`, `present = missing = 1`.

### `OwnedReturns.w`

Source: [`OwnedReturns.w`](../../wheeler-examples/src/main/wheeler/classical/ownership/OwnedReturns.w).

Covers: Caller-region factories returning unique word, byte, immutable UTF-8, and signed-map owners through typed calls, followed by final-caller use and one consuming sink over all five owner kinds, stage-0/Wheeler interpreter parity, and exact rewind.

Expected result: `wordValue = 17`, `byteValue = 65`, `scalarCount = 2`, `mapValue = 23`.

### `Records.w`

Source: [`Records.w`](../../wheeler-examples/src/main/wheeler/classical/data/Records.w).

Covers: Nested immutable records, typed record calls, fields, and structural equality.

Expected result: `width = 5`, `equal = 1`.

### `RecursiveValue.w`

Source: [`RecursiveValue.w`](../../wheeler-examples/src/main/wheeler/classical/control/RecursiveValue.w).

Covers: Recursive signed value call under frame and step ceilings.

Expected result: `result = 6`.

### `ReversiblePacketCodec.w`

Source: [`ReversiblePacketCodec.w`](../../wheeler-examples/src/main/wheeler/classical/data/ReversiblePacketCodec.w).

Covers: A typed packet record, four canonical byte-valued frame fields under a generated inverse relation, direct projection into region-owned bytes without a packed-word surrogate, a closed decoded-or-malformed result, checksum validation, decode-encode byte equality, exhaustive 256-case bounded field generation, distinct length and checksum diagnostics, and bounded owner cleanup.

Expected result: decoded fields are `3`, `5`, and `42`. Malformed codes are `1` and `2`. `observed = 2753795`, and reverse frame execution clears all four fields.

### `ReversibleResult.w`

Source: [`ReversibleResult.w`](../../wheeler-examples/src/main/wheeler/classical/control/ReversibleResult.w).

Covers: A checked relation over two preserved signed parameters bound through one exact
signed local, the implicit caller-owned result slot, dedicated two-source binary-fill, call,
and return instructions, and one generated-inverse
certificate. Core conformance also commits VM history between the forward and inverse
call. The Wheeler-native compiler emits the same computed helper, adjacent slot locals,
generated bodies, computed-local collapse, and proof bytes as stage 0. Differential fixtures also select the first or second independent prelude without emitting discarded local state. The Wheeler-native interpreter executes both
call directions and checks restored vacancy against the Java VM. The inverse recomputes
both preserved sources for `34 + 8` instead of asking the debugger whether 42 looked familiar.

Expected result: `observed = 42`.

### `RegionStorage.w`

Source: [`RegionStorage.w`](../../wheeler-examples/src/main/wheeler/classical/ownership/RegionStorage.w).

Covers: Consumed region-factory results, nested exclusive word/byte loans, one shared byte loan followed by resumed mutation, strict UTF-8 scanning, affine ownership, and explicit drop.

Expected result: `first = 7`, `byteValue = 65`, `byteLength = 6`, `validUtf8 = 1`, `utf8Scalars = decodedScalars = 3`, `scalarSum = 8591`, `scratchValue = 19`.

### `Utf8Lexer.w`

Files: [`Utf8Lexer.w`](../../wheeler-examples/src/main/wheeler/text/Utf8Lexer.w) + [`lexer/Parser.w`](../../wheeler-examples/src/main/wheeler/lexer/Parser.w) + [`lexer/Scanner.w`](../../wheeler-compiler/src/main/wheeler/lexer/Scanner.w).

Covers: An explicit host UTF-8 source scanned and parsed by dependency-first modules. The scanner creates region-owned identifier, number, punctuation, escaped ASCII literal, and line or block comment tokens. It supports digits after the first identifier character, bounded decimal, hexadecimal, and binary parsing, and stable diagnostic codes with byte offset, line, and column. A typed-local-declaration parser consumes those tokens.

Expected behavior:

- Input `long x2=123;/*c*/` gives `tokenCount = 6`, `numberStart = 8`, `commentStart = 12`, `numericValue = 123`, `lexicalCode = 0`, `outputLength = 3`, `finalCursor = 17`.
- Malformed comment, literal, and token-capacity cases report codes 1, 2, and 3 with one-based source coordinates.
- Output `123`.

### `Variants.w`

Source: [`Variants.w`](../../wheeler-examples/src/main/wheeler/classical/data/Variants.w).

Covers: The one-value `Done` completion type, ordinary `done` returns, closed tagged variants, compiler-owned `Slot<long>` presence, typed construction, structural equality, and exhaustive payload selection.

Expected result: `selected = 9`, `equal = 1`, `presence = 11`.

### `WidthExplicitOracle.w`

Source: [`WidthExplicitOracle.w`](../../wheeler-examples/src/main/wheeler/classical/oracles/WidthExplicitOracle.w).

Covers: Explicit 32-bit rotate-right semantics inside a signed host word, a bounded bit mask, a four-row immutable lookup table, checked indexing, and exact width-independent results.

Expected result: `rotated = 268435456`, `masked = 0`, `selected = 13`.

### `WorkQueue.w`

Files: [`WorkQueue.w`](../../wheeler-examples/src/main/wheeler/classical/data/WorkQueue.w) + [`collections/LongQueue.w`](../../wheeler-core/src/main/wheeler/collections/LongQueue.w).

Covers: Bounded FIFO over an exclusive word-buffer borrow with immutable cursor and explicit `Full`/`Empty` results.

Expected result: `first = 4`, `second = 9`, `finalHead = 2`, `finalTail = 4`, `emptyObserved = fullObserved = 1`.

### `CoherentOracle.w`

Source: [`CoherentOracle.w`](../../wheeler-examples/src/main/wheeler/quantum/CoherentOracle.w).

Covers: Add-three modulo an explicit three-qubit width, classical forward and inverse execution, coherent lifting, controlled-phase marking of low-bit comparison state three, no workspace ancilla, exhaustive comparison of all eight basis amplitudes, and generated-adjoint cleanup.

Expected result: classical `value` returns to `0`. Coherent basis `5` maps to basis `0`, so `measured = 0`. Every exhaustive forward-adjoint pair restores its exact input amplitude.

### `GroverSearch.w`

Source: [`GroverSearch.w`](../../wheeler-examples/src/main/wheeler/quantum/GroverSearch.w).

Covers: One exact four-element Grover iteration, a zero-workspace lookup phase oracle marking basis state three, diffusion over the uniform state, an exact complex-amplitude oracle, a 256-shot seeded success threshold, a generated adjoint certificate, and canonical ideal-target execution.

Expected result: the marked-state amplitude has magnitude one, at least 250 of 256 seeded shots return basis state three, and source execution records `measured = 3`.

### `QFT.w`

Source: [`QFT.w`](../../wheeler-examples/src/main/wheeler/quantum/QFT.w).

Covers: Quantum Fourier transform whose qreg size is a compile-time constant, with a generated adjoint and kernel-checked adjoint certificate.

Expected result: `measured = 5`.

### `QFTProof.w`

Source: [`QFTProof.w`](../../wheeler-examples/src/main/wheeler/quantum/QFTProof.w).

Covers: Executable two-qubit inverse law.

Expected result: `measured = 2`.

### `DelegatedComputation.w`

Source: [`DelegatedComputation.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/DelegatedComputation.w).

Covers: The bounded `MASKED_NOT_V1` protocol under an explicit honest-but-curious single-provider model, client-owned secret and mask state, a nonce-backed commitment, provider-visible blinded bits, challenge-bound verification, exact unmasking, and one-shot transcript consumption.

Expected result: secret one with mask zero produces blinded input one, provider output zero, and verified output zero. A self-consistent envelope carrying the wrong NOT relation rejects. The fixture leaves `generalPrivacyClaim = 0`. It proves no malicious-provider, collusion, side-channel, transport, or randomness claim.

### `DistributedBell.w`

Source: [`DistributedBell.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/DistributedBell.w).

Covers: Two ordered target endpoints, explicit network-entanglement capability, content-identified request and branch state, handle-free persistence, delayed heralding, deadline expiry, and local branch discard.

Expected result: a herald at cycle 19 satisfies the cycle-20 deadline, survives snapshot restoration without another request, and can be discarded locally. The fixture leaves `remoteDestroyed = 0`. A static target without network capability rejects before session creation.

### `StaticPhaseEstimation.w`

Source: [`StaticPhaseEstimation.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/StaticPhaseEstimation.w).

Covers: The exact two-bit eigenphase three quarters, two controlled powers, a two-bit inverse transform, complete complex-amplitude comparison, a generated adjoint certificate, canonical static target execution, and deterministic joint-basis observation.

Expected result: the low two bits are `3`, the eigenstate bit remains set, and joint observation records `measured = 7`.

### `AdaptivePhaseEstimation.w`

Source: [`AdaptivePhaseEstimation.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/AdaptivePhaseEstimation.w).

Covers: Two target-resident phase rounds, bounded result slots, measurement-conditioned phase and eigenstate corrections through `applyIf`, measured-ancilla reset after each round, asynchronous dynamic execution, and final host observation without a host split.

Expected result: result slots contain `(true, false)`, both ancillas reset, the corrected eigenstate clears, and final observation records `measured = 0`.

### `AmplitudeEstimation.w`

Source: [`AmplitudeEstimation.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/AmplitudeEstimation.w).

Covers: Exact preparation of a one-half good-state probability, two source-ordered calls to a controlled coherent half-turn, complete complex-amplitude comparison, generated adjoints for preparation and estimation, 4,096-shot deterministic samples of exact probabilities one half and one, explicit qubit and circuit-application counts, probability, standard error, visible uncertainty bounds, and submission provenance.

Expected result: exact ideal amplitudes occupy basis states zero and three equally. Both adjoints restore basis zero. The half-probability estimate remains between `0.45` and `0.55`, its standard error is below `0.009`, and the exact value `0.5` lies inside the reported two-error interval. The certain estimate records all 4,096 successes, zero error, and exact unit bounds. The one-shot source fixture records deterministic sample `3` without treating that sample as the estimate.

### `LogicalMagicPlanning.w`

Source: [`LogicalMagicPlanning.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/LogicalMagicPlanning.w).

Covers: Exact logical-qubit, layer, Clifford, T, measurement, T-depth, magic-state, factory-batch, target-cycle, code-distance, and failure-budget dimensions. Runtime planning closes immutable logical layers against one named bounded factory and one logical-capable target. It rejects insufficient state, cycles, qubits, logical capability, or failure budget before publishing a plan identity.

Expected result: the four-layer fixture needs five magic states, two four-state factory batches, 28 target cycles, code distance seven, and 780 parts per trillion of modeled failure under a budget of 800. T-depth remains `2`. It is not replaced by the five-gate T count. A static physical target without verified logical lowering rejects the plan.

### `VqeHydrogen.w`

Source: [`VqeHydrogen.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/VqeHydrogen.w).

Covers: A pinned one-qubit `Z` Hamiltonian, two exact parameter points, ordered parameter binding, selected-point resource fields, and a generated ansatz adjoint.

Expected result: the pi ansatz reaches basis one and has exact Z energy `-1`, below the zero-angle energy `1`. Batch and single execution agree. Recorded-result replay makes no target call, a fresh seed changes retry identity, and an OpenQASM executor reproduces the ideal outcomes.

### `QaoaMaxCut.w`

Source: [`QaoaMaxCut.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/QaoaMaxCut.w).

Covers: One fixed two-vertex, one-edge cost layer, controlled phase, fixed mixer, exact depth, and complete complex-amplitude comparison.

Expected result: the depth-five pi layer has amplitudes `(0.5, 0.5, 0.5, -0.5)` in little-endian basis order and an exact cut probability of one half. A 4,096-shot seeded batch remains within the declared cut-count bound.

### `QuantumKernelClassifier.w`

Source: [`QuantumKernelClassifier.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/QuantumKernelClassifier.w).

Covers: A two-row feature map, generated adjoint overlap, four bounded kernel entries, and one fixed accepted label.

Expected result: equal features have unit overlap, features separated by pi have zero overlap, and the complete matrix is symmetric. A bounded diagonal-versus-off-diagonal classifier selects label one. Replay consumes result records without retaining a job or calling the target.

### `ParameterShift.w`

Source: [`ParameterShift.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/ParameterShift.w).

Covers: An ordered positive and negative parameter pair, exact expectation reduction, generated adjoints, and explicit application count.

Expected result: shifts around pi over two yield expectations `-1` and `1` and therefore derivative `-1`. Reversing completion arrival does not change canonical angle order or the reduced gradient.

### `QuantumOptimizer.w`

Source: [`QuantumOptimizer.w`](../../wheeler-examples/src/main/wheeler/quantum/QuantumOptimizer.w).

Covers: Two target observations, reversible acceptance update, waiting-snapshot persistence, provider-job recovery without resubmission, commit, target-free replay, branched retry, and cancellation with late-result quarantine.

Expected result: `sample = 1`, `bestCost = 1`, `accepted = 1`.

### `QuantumNeuralNetwork.w`

Source: [`QuantumNeuralNetwork.w`](../../wheeler-examples/src/main/wheeler/quantum/QuantumNeuralNetwork.w).

Covers: One-bit coherent activation layer.

Expected result: `activation = 1`, `measured = 0`.

### `QuantumCompiler.w`

Source: [`QuantumCompiler.w`](../../wheeler-examples/src/main/wheeler/quantum/QuantumCompiler.w).

Covers: Kernel-checked adjacent-inverse normalization plus basis-state execution.

Expected result: `sourceResult = normalizedResult = 1`.

### `QuantumWalk.w`

Source: [`QuantumWalk.w`](../../wheeler-examples/src/main/wheeler/quantum/QuantumWalk.w).

Covers: Two composed Hadamard-coin conditional shifts on a two-node cycle, exact complex amplitudes after each step, the signed uniform two-step distribution, a generated adjoint certificate, reverse composition before observation, and exact restoration of the initial walker basis state.

Expected result: the two-step basis amplitudes are `(1/2, -1/2, 1/2, 1/2)`, both adjoints restore basis zero, and source execution records `measured = 0`.

### `SurfaceCode.w`

Source: [`SurfaceCode.w`](../../wheeler-examples/src/main/wheeler/quantum/SurfaceCode.w).

Covers: Static correction kernel and generated adjoint.

Expected result: `measured = 0`.

## Scope boundaries

No checked-in example uses the planned WIP-0032 unified I/O API. `HostInput.w`, `HostBinaryInput.w`, and the current asynchronous quantum jobs cover the smaller host boundaries that exist today. They do not implement `IoScope`, operation graphs, or durability receipts. The planned conformance fixture remains in WIP-0010 until a full vertical slice can compile, parse, format, and run.

`BinaryTree.w` uses three fixed state slots. Generic nodes, allocation, ownership, and unbounded traversal are outside its scope. Those features belong to the self-hosting language work.

`QFTProof.w` is an executable conformance law. The trusted proof kernel does not accept it as a theorem. It checks that the generated adjoint restores one basis state on the semantic simulator.

`QuantumOptimizer.w` uses deterministic basis candidates so CI can check exact observations. Its event-log test records both jobs, then reproduces the classical result through replay without another target call. Parameter binding, sampled objective estimates, and convergence loops remain separate work.

`QuantumNeuralNetwork.w` shows that one coherent reversible function can act as a classical activation and a quantum permutation. Training arrays, gradients, and floating-point optimizers are not part of this example.

`QuantumCompiler.w` checks one small compiler law in two ways. Its exact cancellation rewrite carries a kernel certificate, and execution checks the basis behavior. This fixture is separate from the larger self-hosted compiler effort.

`SurfaceCode.w` is static. A full syndrome loop needs measurement, reset, bounded decoding, conditional correction, and a target that supports dynamic resident control. Wheeler must reject that workflow on a static target. It cannot hide the cost of host round trips.

## Running the suite

The canonical [`wheeler.package.yaml`](../../wheeler-examples/wheeler.package.yaml) declares every example as a package target. Use the same commands to check them all:

```bash
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='check .'
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='test .'
```

See the [development guide](reference/development.md) for the full gate. The normal `check` and `treeSitterTest` tasks cover every example. None is excluded as future syntax.
