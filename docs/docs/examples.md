# Executable examples

Every checked-in `.w` file is accepted by the compiler and Tree-sitter grammar. Classical examples execute on the VM. Quantum and hybrid examples execute through asynchronous `QuantumTarget` jobs on the ideal state-vector target. The bytecode round trip must be canonical before an example runs.

The examples are deliberately bounded. They demonstrate implemented semantics and state unsupported boundaries directly.

| Example | Contract | Expected final state |
| --- | --- | --- |
| [`Counter.w`](../../wheeler-examples/src/main/wheeler/Counter.w) | Generated inverse calls and reverse-block order | `count = 0` |
| [`BinaryTree.w`](../../wheeler-examples/src/main/wheeler/BinaryTree.w) | Fixed-capacity reversible tree slots | `root = left = right = 0` |
| [`BootstrapControl.w`](../../wheeler-examples/src/main/wheeler/BootstrapControl.w) | Typed local registers, expressions, branch joins, and source-bounded loop | `sum = 10`, `branch = 1` |
| [`FunctionValues.w`](../../wheeler-examples/src/main/wheeler/FunctionValues.w) | Signed parameters, return values, nested expressions, static value calls, and callee loop | `result = 10` |
| [`RecursiveValue.w`](../../wheeler-examples/src/main/wheeler/RecursiveValue.w) | Recursive signed value call under frame and step ceilings | `result = 6` |
| [`CoherentOracle.w`](../../wheeler-examples/src/main/wheeler/CoherentOracle.w) | One XOR function over classical and coherent data | `bit = 0`, `measured = 1` |
| [`QFT.w`](../../wheeler-examples/src/main/wheeler/QFT.w) | Three-qubit quantum Fourier transform and generated adjoint | `measured = 5` |
| [`QFTProof.w`](../../wheeler-examples/src/main/wheeler/QFTProof.w) | Executable two-qubit inverse law | `measured = 2` |
| [`QuantumOptimizer.w`](../../wheeler-examples/src/main/wheeler/QuantumOptimizer.w) | Two target observations, reversible acceptance update, commit, and target-free replay | `sample = 1`, `bestCost = 1`, `accepted = 1` |
| [`QuantumNeuralNetwork.w`](../../wheeler-examples/src/main/wheeler/QuantumNeuralNetwork.w) | One-bit coherent activation layer | `activation = 1`, `measured = 0` |
| [`QuantumCompiler.w`](../../wheeler-examples/src/main/wheeler/QuantumCompiler.w) | Basis-state equivalence of source and normalized circuits | `sourceResult = normalizedResult = 1` |
| [`SurfaceCode.w`](../../wheeler-examples/src/main/wheeler/SurfaceCode.w) | Static correction kernel and generated adjoint | `measured = 0` |

## Scope boundaries

`BinaryTree.w` uses three fixed state slots. It does not claim that generic nodes, allocation, ownership, or unbounded traversal exist. Those facilities belong to the self-hosting language expansion.

`QFTProof.w` is an executable conformance law, not a theorem accepted by a trusted proof kernel. It checks that the generated adjoint restores a basis state on the semantic simulator.

`QuantumOptimizer.w` deliberately uses deterministic basis candidates so CI can assert exact observations. Its event-log test records both jobs and reproduces the classical result through replay without another target call. Parameter binding, sampled objective estimates, and convergence loops remain separate target and language work.

`QuantumNeuralNetwork.w` establishes that a coherent reversible function can serve as a classical activation and a quantum permutation. It does not claim training arrays, gradients, or floating-point optimizers.

`QuantumCompiler.w` checks a small but essential compiler law: removing adjacent self-inverse gates preserves basis behavior. The self-hosted Wheeler compiler is a larger bootstrap deliverable, not this fixture.

`SurfaceCode.w` is static. A real syndrome loop with measurement, reset, bounded decoding, and conditional correction requires a target that advertises dynamic target-resident control. Wheeler must reject that workflow on a static target rather than hide host latency.

## Running the suite

The canonical [`wheeler.package`](../../wheeler-examples/wheeler.package) declares every example as a package target. Check all targets through the unified command:

```bash
./gradlew :wheeler-tools:wheeler --args='check wheeler-examples'
```

Use the [development guide](reference/development.md) for the complete gate. The ordinary `check` and `treeSitterTest` tasks cover every example. No example is excluded as future syntax.
