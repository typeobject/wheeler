# WIP-0005: Wheeler source language profile

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler language and compiler maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Language, compiler, ergonomics, diagnostics |
| Depends on | WIP-0001, WIP-0002 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler source is a deliberately familiar class-based language with explicit reversible and quantum semantics. Classes, fields, methods, calls, assignments, assertions, and block structure use Java-like ergonomics without claiming Java source or binary compatibility. Wheeler adds computation-domain class modifiers, `rev` and `coherent rev` methods, `unitary` methods, affine `qreg` fields, `reverse`, preparation, measurement, and target-aware execution.

The implementation grows as complete executable profiles rather than accepting broad Java syntax into placeholder AST nodes. Unsupported Java or quantum constructs produce source diagnostics. The compiler lowers the accepted profile into WIP-0001 classical bodies and WIP-0002 quantum regions, and deletes each superseded parser path instead of maintaining dialects.

## Motivation

Wheeler should feel like a plausible evolution of Java for reversible and quantum systems. The first executable implementation used a temporary line-oriented declaration format to validate bytecode. Keeping that format would make the VM testable but would not satisfy the language's purpose or the ergonomics demonstrated by the original examples.

At the same time, copying all of Java's grammar before semantics exist recreates the deleted placeholder compiler. The project needs a Java-shaped subset whose every construct has parsing, diagnostics, lowering, verification, execution, and example coverage. It must grow toward the WIP-0007 bootstrap profile: the compiler is a Wheeler acceptance program, not a permanent Java service.

## Use cases

### Classical reversible class

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

### Quantum class

```java
quantum class Bell {
    state long measured = 0;
    qreg q = new qreg(2);

    unitary void prepareBell() {
        H(q[0]);
        CNOT(q[0], q[1]);
    }

    entry void main() {
        prepare(q, 0);
        prepareBell();
        measured = measure(q);
    }
}
```

### Coherent lift

A `coherent rev` method is callable normally from classical code and may be referenced from a quantum register with `q.apply(method)`. The compiler verifies that the body belongs to the exact finite coherent subset before producing a lifted operation.

## Goals

- Make valid Wheeler source visually and structurally familiar to Java programmers.
- Preserve explicit `classical`, `quantum`, and `hybrid` class intent.
- Provide Java-shaped fields, methods, calls, assignments, assertions, and reverse blocks.
- Keep preparation and measurement explicit and readable.
- Give every accepted construct complete parser-to-runtime coverage.
- Produce line-numbered diagnostics for unsupported syntax and semantic violations.
- Migrate every checked-in example to the accepted profile.
- Grow typed locals, control flow, aggregate values, modules, and effects far enough to express the Wheeler compiler.
- Avoid permanent compatibility with the temporary declaration syntax or Java stage-0 internals.

## Non-goals

- Accept all Java syntax, libraries, reflection, exceptions, threads, generics, or object allocation immediately.
- Treat Java bytecode as Wheeler bytecode.
- Hide measurement behind an ordinary cast or field read.
- Infer coherent eligibility from provider behavior.
- Preserve syntax that was never part of a released Wheeler version.

## Terms and semantic model

`classical class`, `quantum class`, and `hybrid class` select the program domain and available declarations. They do not erase WIP-0002 effects.

A `state long` field is version-1 classical mutable state. A `qreg` field is an affine logical quantum resource. Ordinary Java-like local variables, parameters, object fields, and richer exact types are added only with bytecode and ownership support.

A `rev` method has a compiler-validated inverse body. A `coherent rev` method additionally satisfies WIP-0002 coherent eligibility. A `unitary` method lowers to quantum region IR and receives a generated adjoint.

`reverse method();` invokes one method inverse. A `reverse { ... }` block inverses supported calls in reverse lexical order. It is language-level inverse execution, not VM history rewind.

## Ownership and boundaries

The source parser owns syntax and source locations. Semantic lowerers own name resolution, domain checking, inverse generation, coherent eligibility, quantum resource validation, and diagnostics. WIP-0001 and WIP-0002 remain authoritative for execution semantics.

Tools show source diagnostics and disassembly without exposing parser internals. Examples are executable acceptance programs, not speculative syntax catalogs.

## Design

### First complete profile

The first profile supports:

- one top-level computation-domain class;
- `state long` and `qreg` fields;
- zero-argument `void` methods;
- `rev`, `coherent rev`, `unitary`, and `entry` methods;
- `+=`, `-=`, `^=`, direct logged assignment, method calls, assertions, checkpoint, and commit;
- signed `long` locals, left-to-right arithmetic/comparison expressions, `if`/`else`, and `while (...) limit ...` in ordinary classical methods;
- direct inverse calls and reverse blocks;
- H, X, Z, phase, controlled phase, CNOT, CZ, and swap gates;
- `prepare`, full-register computational-basis measurement, unitary call/adjoint, and coherent method reference;
- comments and conventional semicolons/indentation.

Each later profile must update this WIP or a successor with syntax, semantics, migration, and tests. Feature order is driven by executable examples and the WIP-0007 self-hosting compiler, not by copying the Java grammar.

### Parsing strategy

The initial parser is a small source-located parser for the accepted profile, not a permissive Java parser followed by silent dropping of unsupported nodes. It rejects multiple declarations per line and unsupported nested control flow with an actionable diagnostic. When expression and statement breadth requires it, the parser may be replaced by a token/grammar implementation without changing accepted source semantics.

### Naming and dispatch

Names resolve statically within the class. An entry call to a `unitary` method becomes a quantum-region application; a call to a classical method becomes a classical invocation. `reverse` selects the corresponding inverse or adjoint. `q.apply(method)` selects coherent lifting and requires a `coherent rev` target.

### Java relationship

Wheeler adopts Java familiarity, not Java source or binary compatibility. Constructs whose Java meaning conflicts with reversibility, affine ownership, or bounded execution require Wheeler-specific diagnostics and contracts.

## Reversibility and history

Assignments lower according to WIP-0001 reversibility classes. `+=`, `-=`, and `^=` have generated inverses in eligible methods. Direct assignment is logged and is rejected from methods requiring a generated inverse.

Reverse blocks only accept operations with a declared language-level inverse. External effects, measurement, and commit cannot hide in a reverse block.

## Concurrency and determinism

The initial profile has no Java threads, monitors, volatile fields, or asynchronous syntax. WIP-0004 target jobs remain runtime-managed. A later structured-concurrency WIP must define Java-shaped syntax without inheriting accidental JVM memory semantics.

## Quantum and proof implications

Quantum register references are affine semantic values even when field syntax resembles Java. Gate calls do not expose provider qubit objects. Measurement produces classical state through an explicit operation.

WIP-0011 integrates contracts, theorems, structured proof blocks, experiments, and certificates with stable function, circuit, resource, and package identities.

## Bytecode, persistence, and compatibility

Source syntax does not appear in canonical bytecode except through names and optional debug maps. Temporary pre-WIP source files have no compatibility guarantee and are migrated in place. `.wbc` compatibility remains governed by WIP-0001 and WIP-0002.

## Safety, limits, and failures

The parser bounds source bytes, lines, declarations, methods, statements, registers, gates, and nesting. Diagnostics include line numbers and never produce partial artifacts. Unsupported syntax fails closed.

## Migration and deletion

1. Replace the temporary `wheeler 1` declaration syntax with Wheeler classes.
2. Migrate Counter, QFT, and the coherent-oracle fixture first.
3. Add complete constructs only as the remaining examples require them.
4. Delete temporary parser branches and documentation in the same changes.
5. Keep all examples compiling in CI after each profile expansion.

## Progress

- [x] Wheeler class, field, and method declarations parse.
- [x] Classical state, signed locals, bounded control flow, and reverse blocks lower to WIP-0001.
- [x] Unitary methods and quantum entry operations lower to WIP-0002.
- [x] Coherent method references execute on classical and simulated quantum data.
- [x] Counter, QFT, and coherent-oracle examples use only the Wheeler source profile.
- [x] Temporary source syntax and documentation are deleted.

## Testing and acceptance

- [x] Parser and executable-example tests cover every accepted declaration and statement.
- [x] Negative tests cover unsupported Java syntax, malformed blocks, unresolved names, illegal inverse calls, and invalid quantum references.
- [x] Source diagnostics identify stable line numbers and lexical columns.
- [x] Counter compiles and executes forward and inverse.
- [x] QFT followed by its generated adjoint restores the input state.
- [x] One `coherent rev` method gives matching classical and quantum basis behavior.
- [x] Every checked-in `.w` file compiles and executes in CI.
- [x] Current language reference contains no temporary declaration syntax.

## Alternatives

### Keep the line-oriented DSL

Rejected. It is useful as an internal assembly shape but does not provide the intended class-based ergonomics.

### Restore the broad ANTLR grammar immediately

Rejected. The removed grammar accepted far more syntax than the AST, verifier, or runtime could execute. Grammar breadth follows semantic implementation.

### Use Java annotations only

Rejected. Reversibility, affine quantum resources, reverse blocks, and measurement are core language semantics and deserve direct readable syntax.

## Open questions

- Which exact local-variable, parameter, and aggregate profile is the smallest complete WIP-0007 bootstrap subset? — **Owner:** language and compiler maintainers — **Decide by:** before the BinaryTree migration
- Should coherent invocation eventually use ordinary overload resolution on coherent value types, method references, or both? — **Owner:** language and quantum maintainers — **Decide by:** before parameters are added

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [Language profile](../reference/language-profile.md)
