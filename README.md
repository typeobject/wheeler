# Wheeler Virtual Machine (WVM)

A reversible, concurrent virtual machine and programming language.

**This project is just an experiment and is still in the early stages of development.**

## Overview

The Wheeler Virtual Machine provides a platform for writing and executing perfectly reversible programs, including support for concurrent execution. Every operation can be reversed, enabling exact reconstruction of previous program states.

Key features:
- Perfect reversibility of all operations.
- Concurrent execution with reversible synchronization.
- Quantum-inspired instruction set.
- Modern Java implementation.
- Comprehensive testing framework.

## Requirements

- Java 17 or higher
- Gradle 8.0 or higher

## Quick Start

Build the project:
```bash
./gradlew build
```

Compile a Wheeler program:
```bash
./gradlew wheelc -Psource=examples/HelloWorld.w
```

Run a Wheeler program:
```bash
./gradlew wheel -Pfile=HelloWorld.wc
```

## Project Structure

- `wvm-core`: Core virtual machine implementation
- `wvm-compiler`: Wheeler language compiler
- `wvm-runtime`: Runtime libraries and support
- `wvm-tools`: Development and debugging tools
- `wvm-examples`: Example programs and tests

## Documentation

- [User Guide](docs/user-guide.md)
- [Language Reference](docs/language-reference.md)
- [VM Specification](docs/vm-spec.md)
- [Bytecode Format](docs/bytecode-format.md)
- [Development Guide](docs/development-guide.md)

## Example

```wheeler
// Simple reversible counter
rev class Counter {
    rev int<32> value = 0;

    rev void increment() {
        value++;
    }

    rev void decrement() {
        value--;
    }
}
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to the project.

## License

Wheeler is licensed under the Apache License 2.0 - see [LICENSE](LICENSE) for details.

## Acknowledgments

Inspired by:
- John Wheeler's "It from Bit" concept.
- Bennett's work on reversible computation.
- The Java Virtual Machine.

## Status

Wheeler is currently in early development. The API and bytecode format are subject to change.

## Getting Help

- [Issue Tracker](https://github.com/typeobject/wheeler/issues)
- [Discussion Forum](https://github.com/typeobject/wheeler/discussions)

## Citation

If you use Wheeler in your research, please cite:
```bibtex
@software{wheeler_vm_2024,
  title = {Wheeler Virtual Machine},
  author = {TypeObject},
  year = {2024},
  url = {https://github.com/typeobject/wheeler}
}
```
