# Wheeler

Wheeler is an experimental [reversible computing](https://en.wikipedia.org/wiki/Reversible_computing) and [quantum computing](https://en.wikipedia.org/wiki/Quantum_computing) system. Its central goal is to let one verified reversible function execute as ordinary classical bytecode or lower coherently to a quantum target without duplicating the algorithm.

The repository currently implements:

- a canonical, versioned Wheeler Bytecode Container (`.wbc`);
- a strict decoder and semantic verifier;
- a deterministic typed-global virtual machine;
- intrinsic, checked, logged, and barrier-classified instructions;
- exact per-step rewind records;
- compiler-generated inverse function bodies;
- backend-neutral quantum regions and generated adjoints;
- an ideal state-vector reference target;
- asynchronous capability-based quantum jobs;
- [OpenQASM 3](https://openqasm.com/) lowering and an asynchronous provider-executor SPI;
- coherent lifting for exact XOR permutations;
- formatting-independent Wheeler parsing and [Tree-sitter](https://tree-sitter.github.io/tree-sitter/) tooling;
- `wheelc`, `wheel`, and `wheeldis` command-line tools;
- executable Counter, coherent-oracle, and [quantum Fourier transform](https://en.wikipedia.org/wiki/Quantum_Fourier_transform) examples.

## Requirements

- [JDK 26](https://openjdk.org/projects/jdk/26/)
- No system [Gradle](https://gradle.org/) installation is required; use the wrapper.

On macOS with Homebrew:

```bash
export JAVA_HOME="$(brew --prefix openjdk)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
```

## Build and test

```bash
./gradlew clean check
```

The build treats Java compiler warnings as errors. Tests include canonical bytecode round trips, malformed artifacts, generated inverse calls, logged mutation, commit horizons, randomized rewind laws, and the checked-in example.

## Compile and run the example

Build the classes:

```bash
./gradlew classes
```

The Gradle tasks can be run from an interactive Gradle invocation, while the direct development commands are:

```bash
CP="wheeler-tools/build/classes/java/main:\
wheeler-compiler/build/classes/java/main:\
wheeler-core/build/classes/java/main:\
wheeler-runtime/build/classes/java/main"

java -cp "$CP" com.typeobject.wheeler.tools.Wheelc \
  wheeler-examples/src/main/wheeler/Counter.w -o /tmp/Counter.wbc
java -cp "$CP" com.typeobject.wheeler.tools.Wheeldis /tmp/Counter.wbc
java -cp "$CP" com.typeobject.wheeler.tools.Wheel /tmp/Counter.wbc

# Emit a static quantum submission for any OpenQASM 3 consumer.
java -cp "$CP" com.typeobject.wheeler.tools.Wheelc \
  wheeler-examples/src/main/wheeler/QFT.w -o /tmp/QFT.wbc
java -cp "$CP" com.typeobject.wheeler.tools.Wheelqasm \
  /tmp/QFT.wbc /tmp/QFT.qasm
```

Expected final output includes:

```text
Counter (classical) halted after 15 steps
count = 0
```

## Executable source profile

The current profile is deliberately small and complete:

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

See the [language profile](docs/docs/reference/language-profile.md) for the supported declarations and operations.

## Project structure

- `wheeler-core` — bytecode model, codec, verifier, disassembler, and reversible VM.
- `wheeler-compiler` — source parser, diagnostics, lowering, and inverse generation.
- `wheeler-runtime` — quantum targets and durable hybrid execution.
- `wheeler-tools` — command-line compiler, runner, disassembler, and OpenQASM emitter.
- `wheeler-examples` — executable acceptance programs and integration tests.
- `docs/docs/proposals` — Wheeler Improvement Proposals (WIPs).
- `tree-sitter-wheeler` — incremental grammar and editor queries.

## Documentation

- [Proposal index](docs/docs/proposals/README.md)
- [Language profile](docs/docs/reference/language-profile.md)
- [Bytecode format](docs/docs/reference/bytecode.md)
- [Virtual machine](docs/docs/reference/virtual-machine.md)
- [Quantum targets](docs/docs/reference/quantum-targets.md)
- [Development guide](docs/docs/reference/development.md)

## Status and scope

Wheeler is pre-release research software. The reference documentation describes implemented behavior. Draft WIPs describe intended contracts and must not be read as existing functionality.

The long-term architecture distinguishes:

- classical inverse execution;
- VM history rewind;
- quantum adjoints and uncomputation;
- measurement observations;
- replay and fresh hardware retry.

Those operations are related, but they are not falsely presented as one physical notion of reversing time.

## License

Wheeler is licensed under the Apache License 2.0; see [LICENSE.md](LICENSE.md).
