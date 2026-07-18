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

The available domains are `classical`, `quantum`, and `hybrid`. The first format supports signed 64-bit classical state and affine logical quantum registers:

```java
state long measured = 0;
qreg q = new qreg(3);
```

Raw provider qubits are never source values.

## Methods

```java
long add(long left, long right) { return left + right; }
void helper() { ... }
rev void increment() { ... }
coherent rev void flip() { ... }
unitary void qft() { ... }
entry void main() { ... }
```

- A normal classical method may take typed `long` or `boolean` parameters and return `long`, `boolean`, or `void`.
- A `rev` method receives a compiler-validated inverse.
- A `coherent rev` method also satisfies the exact finite subset that can become a unitary operation.
- A `unitary` method lowers to backend-neutral quantum region IR and receives a generated adjoint.
- Exactly one zero-argument `entry void main()` method defines execution.

`public`, `private`, `protected`, and `static` are accepted where meaningful for familiar organization. Ordinary classical methods have typed signed or Boolean parameters, return values, and local bindings, plus bounded control flow. `rev`, `coherent rev`, and `unitary` methods remain zero-argument and `void` until their parameter ownership and inverse signatures are implemented.

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

## Local expressions and bounded control

Ordinary classical methods support signed `long` and `boolean` locals, left-to-right expressions over `+`, `-`, `^`, `<`, and `==`, `if`/`else`, source-bounded `while`, and source-bounded `for`. Arithmetic and ordering require signed operands. Equality requires equal operand types and returns Boolean. XOR accepts two signed values or two Booleans and preserves their type. Conditions require Boolean values; integers are never truthy:

```java
long i = 0;
while (i < 5) limit 5 {
    sum += i;
    i += 1;
}
boolean complete = sum == 10;
if (complete) {
    branch = 1;
} else {
    branch = 2;
}
```

A familiar counted loop carries the same mandatory semantic bound:

```java
for (long i = 0; i < 5; i += 1) limit 5 {
    sum += i;
}
```

Its initializer executes once, then the limit is evaluated once. Wheeler checks the limit before every body iteration and traps before executing an iteration beyond the bound. In a `while`, `continue;` transfers to condition reevaluation; in a `for`, it executes the update before reevaluating the condition and therefore cannot evade the next bound check. `break;` exits the innermost bounded loop. Both are rejected outside a loop. Nested loops carry distinct targets and counters. The whole-program step limit remains a separate defense.

Value calls evaluate arguments left to right, move them through a verified contiguous typed call window, initialize callee parameter registers, and place one signed or Boolean result in a caller register of the exact declared type. A value-returning method may return early from a conditional, but every reachable path must end in `return expression;` of the declared type. Static recursion is permitted under the VM's hard 1,024-frame ceiling and the program step ceiling.

Local control compiles to verified typed frame registers and explicit control-flow targets. The function descriptor stores one canonical type code per register. The verifier rejects unknown type codes, invalid targets, out-of-range locals, reads not definitely assigned on every incoming path, operand or call type mismatches, non-Boolean conditions, invalid Boolean constants, and a function that falls through its body.

Control flow is not accepted in `rev` or `coherent rev` methods yet. Wheeler will add reversible branches and loops only with an exact branch or iteration witness; it does not retain hidden history automatically.

## Value records

A nominal record declares one or more ordered, immutable fields:

```java
record Span(long start, long end) {}
record Token(Span span, boolean valid) {}

Token token = new Token(new Span(3, 8), true);
long width = token.span.end - token.span.start;
```

A field may use a scalar or a previously declared record type. Requiring prior declaration makes recursive and cyclic inline values impossible. Construction is left to right and checks exact arity and field types. Field access is read-only. Records may be locals, parameters, and results; `==` compares nominal type and complete immutable field values.

The VM interns equal immutable values in deterministic construction order. Handles are verified implementation values, not source integers or artifact identity. Rewind removes allocations made by the rewound step, and snapshots include the record table. The current hard ceiling is 65,535 distinct record values per machine.

## Tagged variants

A variant declares a closed ordered case set. Cases carry zero or more typed payload fields:

```java
variant Option {
    case None();
    case Some(long value);
}

Option option = new Option.Some(9);
match (option) {
    case Option.None() { result = 0; }
    case Option.Some(long value) { result = value; }
}
```

Payload types must already be declared, preventing recursive inline layouts. Construction checks the nominal type, case, arity, and payload types. `match` names one variant type in every arm, rejects duplicate or unknown cases, checks binding types, and requires the complete case set. The final arm is safe without a fallback because verified values can carry only descriptor tags. Bindings are typed locals in their case body. Variants may be parameters and results, and `==` uses nominal structural equality.

The VM interns variants separately from records under a 65,535-value ceiling. Snapshots and rewind include both tables; a checked payload read traps before mutation if its expected tag does not match.

## Fixed arrays

A fixed array owns an immutable, homogeneous sequence whose length is part of its type:

```java
long[4] values = new long[4](2, 4, 6, 8);
long selected = values[2];
```

Construction requires exactly the declared number of left-to-right elements and checks every element type. Arrays may be locals, parameters, and results. Index expressions are signed values and trap before mutation when negative or at least the array length. `==` compares the complete typed value. Lengths range from 1 through 65,535; nested array syntax and mutation are not in this slice.

An immutable borrowed slice uses `T[]` and an explicit checked constructor:

```java
long[] middle = slice(values, 1, 2);
long selected = middle[1];
```

The constructor retains the array origin plus start and length, rejects negative or overflowing ranges before allocation, and never copies elements. Slice indexing is relative and checked. Slices may be locals and parameters but cannot be function results or aggregate elements, so a borrow cannot escape its owner. Mutable slices, split/join, and overlapping-borrow analysis remain future work.

Equal arrays and slices are interned in deterministic construction order under separate 65,535-value machine ceilings. Handles remain unobservable and type-specific. Snapshots and rewind include both tables.

## Generated inverse and adjoint theorems

The initial proof slice accepts four closed theorem forms:

```java
theorem incrementInverse proves inverse(increment);
theorem qftAdjoint proves adjoint(qft);
theorem normalized proves equivalent(sourceCircuit, normalizedCircuit);
theorem addBound proves steps(add, 4);
```

The compiler resolves each subject and emits a canonical rule certificate tied to the function or circuit ID. `GENERATED_INVERSE` requires a `rev` function; the trusted `ProofKernel` reconstructs its expected inverse from the forward opcodes. `GENERATED_ADJOINT` requires a `unitary` circuit; the kernel reverses its operation order, inverts every semantic gate or coherent call, and checks that taking the adjoint twice restores the exact circuit body. `CIRCUIT_EQUIVALENCE` requires two circuits on the same register and checks equality after deterministic cancellation of adjacent inverse operations. `STATIC_STEP_BOUND` requires a straight-line function with no calls or branches and checks that its complete forward instruction count does not exceed the stated positive bound or the program ceiling. Unknown subjects, unsupported operations, noncanonical IDs, unknown rules, changed inverse bodies, and malformed metadata reject before execution. This is formal structural evidence, unlike an executable round-trip test.

These rules prove exact compiler generation, one named cancellation rewrite, and straight-line static instruction bounds for the accepted subsets. They do not yet establish matrix-level circuit equivalence under arbitrary rewrites or global phase. General propositions, contracts, proof terms, resource certificates, assumptions, and experiments remain WIP-0011 work.

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

The compiler lexer records line, column, and stage-0 UTF-16 source-character offset. Required identifiers are ASCII letters, digits, and underscore; Unicode remains valid in comments, not names. Inputs are capped at 64 MiB and 16 Mi source characters, tokens at 4,096 characters, token and line counts at 1,000,000 each, declarations at 65,535, and structured block nesting at 256. The parser is formatting-independent and rejects unsupported constructs rather than dropping them.

`tree-sitter-wheeler` provides an incremental grammar, corpus, highlighting, and fold queries for `.w` files. Its concrete syntax tree does not attempt type checking; method and gate meaning are resolved by the compiler.

## Bootstrap direction

The current compiler and VM use Java only as stage-0 infrastructure. The production compiler will be Wheeler source and must compile itself to a byte-identical second-stage `.wbc` artifact. Signed, Boolean, and immutable record values, typed parameters and returns, static calls, and bounded classical control form the current bootstrap slice. Variants, arrays, slices, strings, bytes, deterministic collections, modules, and explicit file effects follow as complete vertical slices.

After native runtime conformance, the Java compiler, VM, tools, Gradle build, and JVM deployment path will be deleted. A cold build will use a content-addressed prior native Wheeler release and `.wbc` recovery seed. Java APIs and object semantics are therefore not prospective Wheeler contracts.

See [WIP-0007](../proposals/WIP-0007-self-hosting-compiler-and-bootstrap.md), [WIP-0008](../proposals/WIP-0008-java-free-runtime-and-native-bootstrap.md), and the Wheeler-native package/build contract in [WIP-0009](../proposals/WIP-0009-wheeler-package-and-build-system.md).

## Proof direction

Proofs will use integrated Wheeler syntax and semantics. Contracts attach to executable declarations; theorem and experiment declarations resolve through ordinary modules; structured proof blocks elaborate to canonical terms checked by a small trusted kernel. Formal theorem evidence remains distinct from simulator tests and sampled hardware results.

The current `QFTProof.w` is an executable inverse law, not a formal theorem. `Counter.w`, `QFT.w`, and `QuantumCompiler.w` carry the initial finite-rule certificates. General proposition terms, contracts, matrix-level quantum proofs, resource claims, and tooling contracts remain specified work in [WIP-0011](../proposals/WIP-0011-integrated-proofs-and-certificates.md).

## Standard library direction

The Wheeler-written standard library will provide allocation-free core values, owned deterministic collections, bytes and UTF-8, explicit host capabilities, reversible data structures with honest inverse contracts, affine logical qubits and registers, circuits, observables, target jobs, proof support, and test utilities. Its package layering and ownership rules are specified in [WIP-0012](../proposals/WIP-0012-wheeler-standard-library.md).

## Teaching path

1. `Counter.w`, `BinaryTree.w`, `BootstrapControl.w`, `FunctionValues.w`, and `RecursiveValue.w`: reversible state, fixed-capacity data, typed locals, bounded control, parameters, returns, static calls, and bounded recursion.
2. `CoherentOracle.w` and `QuantumNeuralNetwork.w`: exact XOR permutations over classical and coherent data.
3. `QFT.w` and `QFTProof.w`: unitary regions, generated adjoints, and executable inverse laws.
4. `QuantumOptimizer.w`: repeated target observations, classical acceptance, commit, and target-free replay.
5. `QuantumCompiler.w`: semantic comparison of source and normalized circuits.
6. `SurfaceCode.w`: a static correction kernel whose documentation states the dynamic-target boundary.

See [executable examples](../examples.md) for exact results and scope. Every checked-in example compiles, executes, and parses without Tree-sitter error nodes in the ordinary test gate.
