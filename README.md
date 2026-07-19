# Wheeler

Wheeler is a programming language for [reversible computing](https://en.wikipedia.org/wiki/Reversible_computing) and [quantum computing](https://en.wikipedia.org/wiki/Quantum_computing). A verified reversible function can run as ordinary classical code or be lifted coherently for quantum execution, so the same implementation serves both domains.

The language keeps inverse execution, VM rewind, coherent permutations, quantum adjoints, measurement, replay, compensation, and retry distinct. Familiar class and method syntax lowers to one verified reversible typed IR: ordinary destructive work declares bounded history or a barrier, `rev` work declares an exact inverse, coherent work declares a finite permutation, and unitary work declares an adjoint-bearing quantum region. Irreversible effects and affine quantum resources stay explicit.

## Example

```java
classical class Counter {
    state long count = 0;

    rev void increment() {
        count += 1;
    }

    entry void main() {
        increment();
        increment();
        assert(count == 2);

        reverse {
            increment();
            increment();
        }
        assert(count == 0);
    }
}
```

The compiler generates `increment`'s inverse. The `reverse` block executes new inverse operations in reverse lexical order; it does not rewind saved machine history.

Wheeler currently includes canonical `.wbc` artifacts, strict verification, a reversible VM, backend-neutral quantum regions, an ideal state-vector target, asynchronous target jobs, [OpenQASM 3](https://openqasm.com/) lowering, and [Tree-sitter](https://tree-sitter.github.io/tree-sitter/) tooling.

Package targets have exactly three kinds: `deployable`, `library`, and `tool`. A runnable target may carry the orthogonal `test` selector; examples need no ceremonial fourth kind. The Wheeler-written core, compiler, runtime, and package-codec slices are ordinary entryless packages with exact committed locks and vendor archives. `wheeler-examples` consumes those archives and retains executable roots, not spare implementation copies kept “just in case.”

All Java source and Gradle machinery is quarantined under [`bootstrap/`](bootstrap/). It is a disposable stage-0 seed and conformance oracle, not the canonical compiler. The production source is [`wheeler-compiler/`](wheeler-compiler/). Its bounded native slices compile and verify current examples; a complete stage-1/stage-2 fixed point and independent diverse-bootstrap gate remain WIP-0007 acceptance work. A fixed point catches drift; by itself it does not catch a compiler that learned Thompson's joke.

Documentation uses one fixed repository convention and no renderer configuration: `./bootstrap/gradlew -p bootstrap :tools:wheeler --args='site -o docs-site'` validates the semantic graph and atomically emits the static site.

## Read next

- [Full documentation](https://wheeler.typeobject.com/)
- [Language profile](docs/docs/reference/language-profile.md)
- [Bytecode format](docs/docs/reference/bytecode.md)
- [Virtual machine](docs/docs/reference/virtual-machine.md)
- [Semantic coverage](docs/docs/reference/coverage.md)
- [Quantum targets](docs/docs/reference/quantum-targets.md)
- [Improvement proposals](docs/docs/proposals/README.md)
- [Development and test guide](docs/docs/reference/development.md)

Executable examples:

- [`Counter.w`](wheeler-examples/src/main/wheeler/classical/control/Counter.w) — reversible classical state;
- [`CoherentOracle.w`](wheeler-examples/src/main/wheeler/quantum/CoherentOracle.w) — one function over classical and coherent data;
- [`QFT.w`](wheeler-examples/src/main/wheeler/quantum/QFT.w) — the [quantum Fourier transform](https://en.wikipedia.org/wiki/Quantum_Fourier_transform) and its generated adjoint.

## License

Wheeler is licensed under the [Apache License 2.0](LICENSE.md).
