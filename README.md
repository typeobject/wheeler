# Wheeler

Wheeler is a programming language for [reversible computing](https://en.wikipedia.org/wiki/Reversible_computing) and [quantum computing](https://en.wikipedia.org/wiki/Quantum_computing). A verified reversible function can run as ordinary classical code or be lifted coherently for quantum execution, so the same implementation serves both domains.

The language keeps inverse execution, VM rewind, quantum adjoints, measurement, replay, and retry distinct. It uses familiar class and method syntax while making irreversible effects and affine quantum resources explicit.

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
        assert count == 2;

        reverse {
            increment();
            increment();
        }
        assert count == 0;
    }
}
```

The compiler generates `increment`'s inverse. The `reverse` block executes new inverse operations in reverse lexical order; it does not rewind saved machine history.

Wheeler currently includes canonical `.wbc` artifacts, strict verification, a reversible VM, backend-neutral quantum regions, an ideal state-vector target, asynchronous target jobs, [OpenQASM 3](https://openqasm.com/) lowering, and [Tree-sitter](https://tree-sitter.github.io/tree-sitter/) tooling.

## Read next

- [Documentation](https://wheeler.typeobject.com/)
- [Language profile](docs/docs/reference/language-profile.md)
- [Bytecode format](docs/docs/reference/bytecode.md)
- [Virtual machine](docs/docs/reference/virtual-machine.md)
- [Quantum targets](docs/docs/reference/quantum-targets.md)
- [Improvement proposals](docs/docs/proposals/README.md)
- [Development and test guide](docs/docs/reference/development.md)

Executable examples:

- [`Counter.w`](wheeler-examples/src/main/wheeler/Counter.w) — reversible classical state;
- [`CoherentOracle.w`](wheeler-examples/src/main/wheeler/CoherentOracle.w) — one function over classical and coherent data;
- [`QFT.w`](wheeler-examples/src/main/wheeler/QFT.w) — the [quantum Fourier transform](https://en.wikipedia.org/wiki/Quantum_Fourier_transform) and its generated adjoint.

## License

Wheeler is licensed under the [Apache License 2.0](LICENSE.md).
