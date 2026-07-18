# Executable examples

Every checked-in `.w` file is accepted by the compiler and Tree-sitter grammar. Classical examples execute on the VM. Quantum and hybrid examples execute through asynchronous `QuantumTarget` jobs on the ideal state-vector target. The bytecode round trip must be canonical before an example runs.

The examples are deliberately bounded. They demonstrate implemented semantics and state unsupported boundaries directly. `QFTProof.w` is also the workspace's declared `test` target, so `wheeler test .` exercises package-driven compilation and execution rather than a special fixture path.

| Example | Contract | Expected final state |
| --- | --- | --- |
| [`Counter.w`](../../wheeler-examples/src/main/wheeler/Counter.w) | Generated inverse calls, reverse-block order, and a kernel-checked generated-inverse theorem | `count = 0` |
| [`BinaryTree.w`](../../wheeler-examples/src/main/wheeler/BinaryTree.w) | Fixed-capacity reversible tree slots | `root = left = right = 0` |
| [`BootstrapControl.w`](../../wheeler-examples/src/main/wheeler/BootstrapControl.w) | Typed signed and Boolean locals, expressions, branch joins, and a bounded counted `for` | `sum = 10`, `branch = 1` |
| [`BytecodeHeader.w`](../../wheeler-examples/src/main/wheeler/BytecodeHeader.w) + [`compiler/Encoding.w`](../../wheeler-examples/src/main/wheeler/compiler/Encoding.w) | Imported bounded little-endian integer emission and checked eight-byte section layout through explicit host output | the header, directory, manifest, strings, scalar global types, empty variants, and padding match stage 0; `finalCursor = 520` |
| [`FixedArrays.w`](../../wheeler-examples/src/main/wheeler/FixedArrays.w) | Fixed immutable arrays, nonescaping borrowed slices, typed calls/results, checked indexing, and structural equality | `selected = 6`, `sum = 20`, `middleSum = 10`, `equal = 1` |
| [`FrozenUtf8.w`](../../wheeler-examples/src/main/wheeler/FrozenUtf8.w) | Strict byte-owner freezing plus nested nonescaping immutable UTF-8 parameter borrows | `byteLength = 6`, `scalarCount = 3`, `middleScalar = 8364`, `valid = 1` |
| [`FunctionValues.w`](../../wheeler-examples/src/main/wheeler/FunctionValues.w) | Signed/Boolean values, typed calls, a callee loop, and a kernel-checked straight-line step bound | `result = 10` |
| [`HostInput.w`](../../wheeler-examples/src/main/wheeler/HostInput.w) | Explicit bounded UTF-8 input and fixed byte-output borrows with no ambient file/network access | for UTF-8 `A¢` and capacity 2: globals `byteLength = 3`, `scalarCount = outputLength = 2`, `firstScalar = 65`; output `A!` |
| [`LoopControl.w`](../../wheeler-examples/src/main/wheeler/LoopControl.w) | Early typed return plus bounded `break` and `continue` edges | `sum = 12`, `selected = 7` |
| [`modules/ModuleMain.w`](../../wheeler-examples/src/main/wheeler/modules/ModuleMain.w) + [`Arithmetic.w`](../../wheeler-examples/src/main/wheeler/modules/Arithmetic.w) + [`Results.w`](../../wheeler-examples/src/main/wheeler/modules/Results.w) | Exact source set, sorted imports, private helper, and direct public function/record/closed-variant APIs | `result = 18`, `decoded = 9` |
| [`LongMap.w`](../../wheeler-examples/src/main/wheeler/LongMap.w) | Region-owned signed map with deterministic access, nested exclusive mutable parameter borrows, and drop | `selected = 17`, `zeroKey = 5`, `present = missing = 1` |
| [`Records.w`](../../wheeler-examples/src/main/wheeler/Records.w) | Nested immutable records, typed record calls, fields, and structural equality | `width = 5`, `equal = 1` |
| [`RecursiveValue.w`](../../wheeler-examples/src/main/wheeler/RecursiveValue.w) | Recursive signed value call under frame and step ceilings | `result = 6` |
| [`RegionStorage.w`](../../wheeler-examples/src/main/wheeler/RegionStorage.w) | Consumed region-factory results, nested exclusive word/byte borrows, strict UTF-8 scanning, affine ownership, and explicit drop | `first = 7`, `byteValue = 65`, `byteLength = 6`, `validUtf8 = 1`, `utf8Scalars = decodedScalars = 3`, `scalarSum = 8591`, `scratchValue = 19` |
| [`Utf8Lexer.w`](../../wheeler-examples/src/main/wheeler/Utf8Lexer.w) | Explicit host UTF-8 source scanned by an imported function module into region-owned identifier/number/punctuation/comment tokens with bounded signed-decimal parsing, recoverable overflow, and an assignment-production parser | `tokenCount = 5`, `numberStart = 2`, `commentStart = 6`, `numericValue = 123`, `parseError = 0`, `outputLength = 3`, `finalCursor = 10`; output `123` |
| [`Variants.w`](../../wheeler-examples/src/main/wheeler/Variants.w) | Closed tagged variants, typed construction, structural equality, and exhaustive payload selection | `selected = 9`, `equal = 1` |
| [`CoherentOracle.w`](../../wheeler-examples/src/main/wheeler/CoherentOracle.w) | One XOR function over classical and coherent data | `bit = 0`, `measured = 1` |
| [`QFT.w`](../../wheeler-examples/src/main/wheeler/QFT.w) | Three-qubit quantum Fourier transform with a generated adjoint and kernel-checked adjoint certificate | `measured = 5` |
| [`QFTProof.w`](../../wheeler-examples/src/main/wheeler/QFTProof.w) | Executable two-qubit inverse law | `measured = 2` |
| [`QuantumOptimizer.w`](../../wheeler-examples/src/main/wheeler/QuantumOptimizer.w) | Two target observations, reversible acceptance update, commit, and target-free replay | `sample = 1`, `bestCost = 1`, `accepted = 1` |
| [`QuantumNeuralNetwork.w`](../../wheeler-examples/src/main/wheeler/QuantumNeuralNetwork.w) | One-bit coherent activation layer | `activation = 1`, `measured = 0` |
| [`QuantumCompiler.w`](../../wheeler-examples/src/main/wheeler/QuantumCompiler.w) | Kernel-checked adjacent-inverse normalization plus basis-state execution | `sourceResult = normalizedResult = 1` |
| [`SurfaceCode.w`](../../wheeler-examples/src/main/wheeler/SurfaceCode.w) | Static correction kernel and generated adjoint | `measured = 0` |

## Scope boundaries

`BinaryTree.w` uses three fixed state slots. It does not claim that generic nodes, allocation, ownership, or unbounded traversal exist. Those facilities belong to the self-hosting language expansion.

`QFTProof.w` is an executable conformance law, not a theorem accepted by a trusted proof kernel. It checks that the generated adjoint restores a basis state on the semantic simulator.

`QuantumOptimizer.w` deliberately uses deterministic basis candidates so CI can assert exact observations. Its event-log test records both jobs and reproduces the classical result through replay without another target call. Parameter binding, sampled objective estimates, and convergence loops remain separate target and language work.

`QuantumNeuralNetwork.w` establishes that a coherent reversible function can serve as a classical activation and a quantum permutation. It does not claim training arrays, gradients, or floating-point optimizers.

`QuantumCompiler.w` checks a small but essential compiler law twice: its exact cancellation rewrite carries a kernel certificate, while execution confirms basis behavior. The self-hosted Wheeler compiler is a larger bootstrap deliverable, not this fixture.

`SurfaceCode.w` is static. A real syndrome loop with measurement, reset, bounded decoding, and conditional correction requires a target that advertises dynamic target-resident control. Wheeler must reject that workflow on a static target rather than hide host latency.

## Running the suite

The canonical [`wheeler.package`](../../wheeler-examples/wheeler.package) declares every example as a package target. Check all targets through the unified command:

```bash
./gradlew :wheeler-tools:wheeler --args='check .'
./gradlew :wheeler-tools:wheeler --args='test .'
```

Use the [development guide](reference/development.md) for the complete gate. The ordinary `check` and `treeSitterTest` tasks cover every example. No example is excluded as future syntax.
