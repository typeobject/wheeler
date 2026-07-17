---
sidebar_position: 1
slug: /
---

# Start with Wheeler

Wheeler is a reversible classical and quantum programming language. It uses familiar classes and methods while making inverse execution, coherent lifting, unitary regions, measurement, and target jobs explicit.

## Begin with reversible state

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

The compiler generates `increment`'s inverse. The reverse block executes those inverses in reverse lexical order. This is new inverse execution, not debugger rewind.

## Continue through the teaching path

1. Read the [language profile](reference/language-profile.md).
2. Inspect the [bytecode contract](reference/bytecode.md) and [virtual machine](reference/virtual-machine.md).
3. Read [quantum targets](reference/quantum-targets.md) and [hybrid runs](reference/hybrid-runs.md).
4. Run `Counter.w`, `CoherentOracle.w`, and `QFT.w` from `wheeler-examples`.
5. Use the [development guide](reference/development.md) to run every test.
6. Read the [WIP index](proposals/README.md) for design status and future boundaries.

The reference manual describes implemented behavior. Draft and Implementing WIPs describe contracts still being completed.
