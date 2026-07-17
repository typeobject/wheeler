# Wheeler

Wheeler is an experimental reversible classical and quantum programming system. Its central goal is to let one verified reversible function execute as ordinary classical bytecode or lower coherently to a quantum target without duplicating the algorithm.

The repository currently implements the first classical slice of [WIP-0001](docs/docs/proposals/WIP-0001-reversible-bytecode-and-machine-state.md):

- a canonical, versioned Wheeler Bytecode Container (`.wbc`);
- a strict decoder and semantic verifier;
- a deterministic typed-global virtual machine;
- intrinsic, checked, logged, and barrier-classified instructions;
- exact per-step rewind records;
- compiler-generated inverse function bodies;
- `wheelc`, `wheel`, and `wheeldis` command-line tools;
- a checked-in `Counter.w` source-to-bytecode-to-VM example.

Quantum region IR, coherent lifting, target adapters, and durable hybrid jobs are specified in WIP-0002 through WIP-0004 and are being implemented in that order.

## Requirements

- JDK 26
- No system Gradle installation is required; use the wrapper.

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
```

Expected final output includes:

```text
Counter halted after 15 steps
count = 0
```

## Executable source profile

The current profile is deliberately small and complete:

```wheeler
wheeler 1
program Counter
kind classical
state count = 0

rev coherent increment {
  add count 1
}

entry {
  call increment
  call increment
  expect count 2
  uncall increment
  uncall increment
  expect count 0
  halt
}
```

See the [language profile](docs/docs/reference/language-profile.md) for the supported declarations and operations.

## Project structure

- `wheeler-core` — bytecode model, codec, verifier, disassembler, and reversible VM.
- `wheeler-compiler` — source parser, diagnostics, lowering, and inverse generation.
- `wheeler-runtime` — quantum targets and hybrid runtime as WIP-0002 onward lands.
- `wheeler-tools` — command-line compiler, runner, and disassembler.
- `wheeler-examples` — executable acceptance programs and integration tests.
- `docs/docs/proposals` — Wheeler Improvement Proposals (WIPs).

## Documentation

- [Proposal index](docs/docs/proposals/README.md)
- [Language profile](docs/docs/reference/language-profile.md)
- [Bytecode format](docs/docs/reference/bytecode.md)
- [Virtual machine](docs/docs/reference/virtual-machine.md)
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
