# Wheeler source language profile

Wheeler uses familiar class, field, method, call, assignment, and block forms while giving reversibility and quantum resources explicit semantics. The profile grows only when a construct has parser, verifier, runtime, negative, editor-grammar, and end-to-end tests.

Whitespace and line breaks are not semantic. Simple statements end in semicolons. `//` and `/* ... */` comments are supported.

## Classes and state

A file contains one computation-domain class:

```java
classical class Counter {
    state long count = 0;
}
```

The available domains are `classical`, `quantum`, and `hybrid`. Version 1 supports signed 64-bit classical state and affine logical quantum registers:

```java
state long measured = 0;
qreg q = new qreg(3);
```

Raw provider qubits are never source values.

## Methods

```java
void helper() { ... }
rev void increment() { ... }
coherent rev void flip() { ... }
unitary void qft() { ... }
entry void main() { ... }
```

- A normal method has a forward classical body.
- A `rev` method receives a compiler-validated inverse.
- A `coherent rev` method also satisfies the exact finite subset that can become a unitary operation.
- A `unitary` method lowers to backend-neutral quantum region IR and receives a generated adjoint.
- Exactly one zero-argument `entry void main()` method defines execution.

`public`, `private`, `protected`, and `static` are accepted where meaningful for familiar organization. The first profile has zero-argument methods; parameters and locals will be added with corresponding bytecode and ownership semantics.

## Classical statements

| Source | Meaning |
| --- | --- |
| `count += 1;` | Checked signed addition; inverse is subtraction. |
| `count -= 1;` | Checked signed subtraction; inverse is addition. |
| `bit ^= 1;` | Bitwise XOR; self-inverse and coherently eligible. |
| `count = 7;` | Logged overwrite; rejected from generated-inverse methods. |
| `increment();` | Invoke a forward method or unitary region. |
| `reverse increment();` | Invoke a method inverse or unitary adjoint. |
| `assert count == 2;` | Trap before mutation when unequal. |
| `checkpoint();` | Add a reversible checkpoint marker. |
| `commit();` | Advance the local rewind horizon. |

A reverse block invokes supported calls in reverse lexical order:

```java
reverse {
    first();
    second();
}
```

This executes `reverse second();` and then `reverse first();`.

## Quantum statements

Unitary methods use Java-shaped gate calls over indexed registers:

```java
unitary void bell() {
    H(q[0]);
    CNOT(q[0], q[1]);
}
```

The current semantic gates are `H`, `X`, `Z`, `Phase`, `CPhase`, `CNOT`, `CZ`, and `Swap`. Target adapters may decompose them but cannot change their ideal meaning.

Preparation and measurement are explicit:

```java
prepare(q, 0);
bell();
measured = measure(q);
```

Measurement creates a classical observation and cannot be hidden in a `pure`, `rev`, or `unitary` method.

## Coherent lifting

The first coherent subset supports finite XOR permutations. The same checked method may run on classical state and be referenced from a quantum register:

```java
coherent rev void flip() {
    bit ^= 1;
}

unitary void oracle() {
    q.apply(flip);
}
```

The compiler rejects checked arithmetic, logged writes, measurement, I/O, and other non-unitary operations from this subset. Broader exact finite arithmetic will be added with explicit width semantics.

## Distinct meanings of reverse

- `reverse method();` is new execution of a verified inverse or adjoint.
- VM rewind consumes prior classical step records.
- Uncomputation returns temporary coherent state to its required clean value.
- Replay reuses recorded observations.
- Retry performs a fresh preparation and target execution.

These operations are related but not interchangeable.

## Parser and editor tooling

The compiler lexer records line, column, and source offset. The parser is formatting-independent and rejects unsupported constructs rather than dropping them.

`tree-sitter-wheeler` provides an incremental grammar, corpus, highlighting, and fold queries for `.w` files. Its concrete syntax tree does not attempt type checking; method and gate meaning are resolved by the compiler.

## Bootstrap direction

The current compiler and VM use Java only as stage-0 infrastructure. The production compiler will be Wheeler source and must compile itself to a byte-identical second-stage `.wbc` artifact. Typed locals, parameters, returns, control flow, records, variants, strings, bytes, deterministic collections, modules, and explicit file effects will be added as complete vertical slices to support that compiler.

After native runtime conformance, the Java compiler, VM, tools, Gradle build, and JVM deployment path will be deleted. A cold build will use a content-addressed prior native Wheeler release and `.wbc` recovery seed. Java APIs and object semantics are therefore not prospective Wheeler contracts.

See [WIP-0007](../proposals/WIP-0007-self-hosting-compiler-and-bootstrap.md) and [WIP-0008](../proposals/WIP-0008-java-free-runtime-and-native-bootstrap.md).

## Teaching path

1. `Counter.w`: classical state, reversible methods, assertions, and reverse blocks.
2. `CoherentOracle.w`: one XOR permutation on classical and coherent data.
3. `QFT.w`: unitary regions and generated adjoints.
4. Measured hybrid optimizers: observations and repeated target execution.
5. Dynamic correction: target capabilities and low-latency feedback.

Every teaching example is compiled and executed in the test suite when its profile is implemented.
