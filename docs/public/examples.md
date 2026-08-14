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

Covers: Ordered event application, an explicit settled-event identity, adjacent duplicate-delivery suppression, duplicate accounting distinct from the reduced value, typed helper calls, and deterministic final state.

Expected result: `lastEvent = 2`, `reduced = 12`, `duplicates = 1`.

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

Covers: Scale-1024 phase-space coordinates, one integer kick-drift symplectic step, checked fixed-point updates without division or rounding, a generated inverse certificate, exact observed coordinates, and complete phase-point restoration.

Expected result: `observedPosition = 10240`, `observedMomentum = 3072`, `position = 7168`, `momentum = 5120`.

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

Covers: A mutable four-node adjacency table, bounded breadth-first work queues and visited sets, cycle detection, rollback of a tentative back edge, deterministic affected-node invalidation, exact per-node versions, and region cleanup.

Expected result: every node has version `2`, `rebuilds = affected = 4`, and `cycleRejected = 1`.

### `IntegerWaveletTransform.w`

Source: [`IntegerWaveletTransform.w`](../../wheeler-examples/src/main/wheeler/classical/data/IntegerWaveletTransform.w).

Covers: A determinant-one two-step integer lifting transform, checked signed updates between state slots, a generated inverse certificate, exact transformed coefficients, and lossless restoration without rounding state.

Expected result: `observedHigh = 4`, `observedLow = 10`, `high = 10`, `low = 6`.

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

Covers: A typed packet record, a closed decoded-or-malformed result, four-byte encoding, checksum validation, decode-encode byte equality, exhaustive 256-case bounded field generation, distinct length and checksum diagnostics, bounded region cleanup, a fixed-width word layout, and one generated inverse certificate.

Expected result: decoded fields are `3`, `5`, and `42`. Malformed codes are `1` and `2`. `observed = 2753795`, and `packet = 0`.

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

Covers: One XOR function over classical and coherent data.

Expected result: `bit = 0`, `measured = 1`.

### `GroverSearch.w`

Source: [`GroverSearch.w`](../../wheeler-examples/src/main/wheeler/quantum/GroverSearch.w).

Covers: One exact four-element Grover iteration, a phase oracle marking basis state three, diffusion over the uniform state, a generated adjoint certificate, canonical ideal-target execution, and deterministic measurement of the unique marked state.

Expected result: `measured = 3`.

### `QFT.w`

Source: [`QFT.w`](../../wheeler-examples/src/main/wheeler/quantum/QFT.w).

Covers: Quantum Fourier transform whose qreg size is a compile-time constant, with a generated adjoint and kernel-checked adjoint certificate.

Expected result: `measured = 5`.

### `QFTProof.w`

Source: [`QFTProof.w`](../../wheeler-examples/src/main/wheeler/quantum/QFTProof.w).

Covers: Executable two-qubit inverse law.

Expected result: `measured = 2`.

### `StaticPhaseEstimation.w`

Source: [`StaticPhaseEstimation.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/StaticPhaseEstimation.w).

Covers: A one-bit exact eigenphase, controlled negative phase, ancilla basis changes, a generated adjoint certificate, canonical static target execution, and deterministic joint-basis observation.

Expected result: `measured = 3`.

### `AdaptivePhaseEstimation.w`

Source: [`AdaptivePhaseEstimation.w`](../../wheeler-examples/src/main/wheeler/quantum/algorithms/AdaptivePhaseEstimation.w).

Covers: Target-resident phase-bit measurement, a bounded result slot, conditional correction through `applyIf`, measured-ancilla reset, asynchronous dynamic execution, and final host observation without a host split.

Expected result: result slot zero contains `1`, and `measured = 0` after correction and reset.

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

Covers: A Hadamard coin, coherent conditional position shift, entangled intermediate state, a generated adjoint certificate, uncomputation before observation, and exact restoration of the initial walker basis state.

Expected result: `measured = 0`.

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
