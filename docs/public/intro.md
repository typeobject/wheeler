---
sidebar_position: 1
slug: /
title: What is Wheeler?
description: The Catenary account of Wheeler's reversible, quantum, and systems model, its accepted core, and its unfinished work.
---

# What is Wheeler?

_Issued from the Catenary compiler yard. This account names accepted behavior and
leaves unfinished work outside the seal._

Wheeler is a programming language for reversible computing, quantum computing,
and work that joins quantum and classical code. Its earliest forms traveled among
ships and instrument stations, where heat, history, and remote observation made
careless uses of *undo* expensive.

Most languages let programs overwrite or discard information. For example, when a variable changes value, a temporary object disappears. A program prints output or calls an API, then keeps going.

That works well on an ordinary computer. Reversible and quantum programs need stricter rules about where information goes.

A reversible operation must keep enough information to run backward exactly. Quantum operations have more limits. Quantum data cannot be copied, read, or discarded like normal data, and temporary quantum state often has to be uncomputed on purpose.

Wheeler puts those rules in the language. The compiler and runtime do not have to guess what a comment or helper library meant.

Wheeler follows these rules:

- use ordinary classical code where it fits.
- mark an operation as reversible when the compiler can check it and build its inverse.
- write quantum operations without tying source code to one provider.
- reuse supported reversible logic as coherent quantum logic.
- make measurement, external effects, retries, and replay visible.
- place machine-checkable claims next to the code as proof support grows.

Each form lowers to one typed Wheeler IR. Reversibility here means careful information accounting. It does not mean that printing a message can somehow be undone.

A destructive classical step records rewind data under the artifact's declared limits. A host observation creates a barrier. A coherent call describes an exact finite permutation, while a unitary region has an adjoint. Measurement and workflow boundaries stay visible. Native code and provider circuits come from the same IR, so they do not replace its meaning.

Wheeler tracks what a program does, what information it uses, what can be undone, and what evidence supports its claims.

## The smallest useful example

This reversible counter is executable:

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

The `rev` keyword says that `increment` is reversible. Wheeler generates the inverse, which subtracts one instead of adding it.

The `reverse` block calls those inverses in reverse source order. It doesn't restore a saved copy of the machine. The program runs new operations that are mathematical inverses of the earlier ones.

This difference matters once a program measures qubits, writes files, sends network requests, starts remote jobs, or calls a payment service. Those effects cannot all be handled as one generic kind of undo.

## Does Wheeler reverse time?

No.

Several related operations are often called "reverse," but they do different jobs.

Inverse execution runs the mathematical inverse of a reversible function.

VM rewind walks backward through saved classical execution history.

Uncomputation clears temporary reversible or quantum state by applying inverse operations.

Replay uses recorded observations again so later classical choices can be reproduced.

Retry prepares fresh state and runs the work again. The new run may return a different result.

These operations cannot replace one another. Replaying a measurement does not undo it. Retrying a hardware job does not restore the old qubits, and an inverse circuit cannot recover a quantum state that no longer exists.

Wheeler keeps the terms separate so programs do not promise more than physics, a remote service, or saved history can provide.

## Why does this matter?

Five parts of the design are especially useful.

### 1. Write one algorithm instead of two

A quantum algorithm often needs a classical reference and a separate quantum oracle or circuit. Both versions should mean the same thing, yet they can drift apart as the code changes.

Wheeler's `coherent rev` model reduces that duplication:

```java
hybrid class CoherentOracle {
  state long value = 0;
  state long measured = 0;
  qreg q = new qreg(3);

  coherent rev void addThree() {
    value += 3;
  }

  unitary void oracle() {
    q.apply(addThree);
    CPhase(q[0], q[1], 3.141592653589793);
  }

  entry void main() {
    addThree();
    assert(value == 3);
    reverse addThree();
    assert(value == 0);

    prepare(q, 5);
    oracle();
    measured = measure(q);
    assert(measured == 0);
  }
}
```

The same finite permutation runs over classical state and coherently modulo the explicit register width. The controlled phase marks one comparison state without allocating table workspace or ancillas. Exhaustive ideal-target tests compare every basis amplitude and apply the generated adjoint to recover each input.

One source definition is both the testable classical reference and the quantum operation. Its inverse and proof duties remain attached to that definition, leaving the two execution paths less room to disagree.

### 2. Generate inverses instead of maintaining them by hand

Quantum code often needs an adjoint. The adjoint reverses the operation order and replaces each gate with its inverse.

A person can write and update that code by hand. The compiler can do it more consistently.

A Wheeler `unitary` method gets a generated adjoint. The maintained QFT case writes one forward circuit and then invokes it in reverse:

```java
quantum class QFT {
  state long measured = 0;
  qreg q = new qreg(3);

  unitary void qft() {
    H(q[2]);
    CPhase(q[1], q[2], 1.5707963267948966);
    CPhase(q[0], q[2], 0.7853981633974483);
    H(q[1]);
    CPhase(q[0], q[1], 1.5707963267948966);
    H(q[0]);
    Swap(q[0], q[2]);
  }

  entry void main() {
    prepare(q, 5);
    qft();
    reverse qft();
    measured = measure(q);
    assert(measured == 5);
  }
}
```

The executable profile already checks static register references, circuit shape, generated adjoints, coherent calls, and the measurement workflow. Full affine quantum slices, dirty-ancilla checks, and dynamic resource control are still being designed.

Generated inverses and explicit uncomputation move common correctness rules into the compiler. Affine ownership will add more checks as that work lands.

### 3. Model quantum work as a durable workflow

A real quantum program usually does more than call a function and receive a result.

```text
result = quantumComputer.doQuantumThing();
```

In practice, it must do work like this:

1. build parameters.
2. choose a target.
3. lower a circuit for that target.
4. submit a job.
5. save the job identity.
6. wait for completion.
7. handle failure, cancellation, duplicate delivery, stale capabilities, or a restart.
8. validate the result.
9. update classical state.
10. repeat when needed.

Wheeler treats hybrid quantum and classical work as a durable lifecycle. The current runtime has content-identified tasks and events, recovery for accepted jobs, size-limited persistence, result checks, branch quarantine, retry, cancellation, replay, and commit horizons. The source profile includes an optimizer with a fixed iteration limit. Production continuation syntax and more dynamic applications remain unfinished.

A long-running optimizer can save a submission identity, recover its accepted result, and apply that result once. It may replay a recorded observation without buying another hardware run. A deliberate retry creates a new physical lineage instead.

This model matches remote, asynchronous, capability-based hardware. It also makes failures and restarts part of the design.

### 4. Keep proofs separate from experiments

Reversible and quantum programs make claims such as these:

- an inverse restores the starting state.
- a circuit is unitary.
- a generated adjoint is exact.
- two circuits have the same meaning.
- every temporary qubit returns clean.
- a plan stays within its qubit or depth limit.
- replay never submits another target job.

Those claims often live in prose or tests. Wheeler is moving contracts, theorems, proof blocks, resource claims, and canonical certificates into the language and package model.

The first trusted-kernel pieces can check generated inverses, generated quantum adjoints, adjacent-inverse circuit rewrites, and straight-line step bounds against exact artifact bodies. General propositions, contracts, quantum and resource rules, and structured proof terms are not implemented yet. `QFTProof.w` remains an executable conformance law, not a trusted quantum theorem certificate.

An experiment is useful evidence, but it is not a universal proof. A simulator run or a 4,096-shot hardware result describes what happened during that run. Wheeler records the target, request, shot count, estimator, and observations without treating repeated success as a theorem.

Quantum software mixes normal bugs, mathematical claims, and probabilistic hardware. Clear boundaries make each kind of evidence easier to judge.

### 5. Build a systems language around the quantum parts

Wheeler is meant to do more than express a few circuits and hand the rest of the work to Python.

The executable core already has signed and Boolean values, immutable records, tagged variants, fixed arrays, nonescaping slices, typed calls, loops with explicit limits, and fixed-capacity regions. It also has factories for owned word, byte, UTF-8, and map storage, plus nonescaping storage borrows, strict validation, deterministic module linking, canonical bytecode, deterministic package formats, and exact offline dependency inputs.

Some major pieces are still under construction. These include owning parameters, returned loans, mutable slices, fuller UTF-8 strings, generic deterministic collections, complete nominal and package modules, and streaming effects. Explicit size-limited UTF-8 and binary input already run, as does byte output with checked publish lengths.

The production compiler is intended to be written in Wheeler. The same applies to the package manager, verifier, runtime, OpenQASM emitter, build planner, and test tools. A successful self-hosting bootstrap compiles the compiler twice and requires byte-identical canonical `.wbc` output.

A compiler uses many parts of a general-purpose language. Building Wheeler with Wheeler will test whether those parts work together under real load.

## What works today?

Wheeler already has an executable base.

The maintained yards carry:

- familiar class and method syntax with source-located diagnostics.
- signed and Boolean values, immutable records, tagged variants, fixed arrays, nonescaping slices, typed calls, recursion, conditionals, loops with explicit limits, and function-local regions with declared capacity.
- affine mutable word and byte buffers, immutable UTF-8 owners, signed maps, and classical function modules with declared graph ceilings.
- generated inverses for the supported reversible subset.
- one canonical `.wbc` format, strict decoding, semantic verification, disassembly, and exact VM rewind.
- finite proof rules for generated inverses, generated adjoints, circuit rewrites, and static step bounds.
- provider-neutral quantum regions, generated circuit adjoints, and coherent XOR and width-modular constant arithmetic.
- an asynchronous ideal state-vector target and an application-supplied OpenQASM 3 execution interface.
- durable hybrid events, recovery, replay, retry, cancellation, quarantine, and transaction phases.
- canonical package, workspace, lock, build-plan, vendor, and `.wpk` archive formats.
- exact offline locked builds, sealed-plan execution, explicit grants, and atomic output publication.
- a Tree-sitter grammar, corpus, highlighting, and executable examples.

The maintained cases cover reversible state, typed aggregate values, finite and recursive control, classical modules, coherent reuse, QFT with a generated adjoint, a 64-iteration hybrid optimizer, circuit normalization, and static error-correction structure. Executable bootstrap, identity, compiler, package, and runtime probes live in a separate conformance package. They were useful examples only of how long a directory name can postpone an architectural decision.

Large areas are still unfinished. They include borrowing, mutable slices, and compiler-scale region storage. The yard plan also requires a standard library, self-hosted tools, and native Java-free execution. Dynamic target control, richer coherent arithmetic, complete application fixtures, and the full proof system remain open.

Wheeler runs today, and the language remains incomplete. The instrument
appendices state its accepted boundary. Maintainers keep proposals and research
sketches on the internal shelves until executable evidence earns their
publication.

## Common questions

### Does Wheeler run on Java?

The syntax is familiar, and the stage-0 implementation uses Java. Wheeler's runtime contract is independent of Java. The yard plan calls for self-hosting, followed by removal of the Java and Gradle
path after the native Wheeler toolchain reaches conformance.

### Does Wheeler replace provider SDKs?

Wheeler uses provider-neutral quantum regions and can lower supported programs to OpenQASM 3. Qiskit or another SDK may consume that output outside Wheeler. Python APIs, credentials, provider objects, and SDK state do not become Wheeler values or artifact semantics.

### Can measurement be reversed?

Measurement creates a classical observation. Wheeler can record and replay that observation, or it can prepare new state and retry. Rolling back a transaction cannot restore an unknown quantum state.

### What code can run coherently?

Only supported exact finite reversible functions can be lifted into coherent execution. File I/O, randomness, measurement, unchecked allocation, and floating-point behavior do not become unitary because a modifier was added.

### Must every Wheeler program be reversible?

Compilers allocate memory. Tools read files and print diagnostics. Hybrid workflows receive measurements. Wheeler labels reversible, logged, irreversible, quantum, and external effects so the compiler and runtime know which guarantees still hold.

## Who uses Wheeler?

Wheeler is aimed at people working on programming languages, quantum software, formal methods, runtimes, compilers, and reproducible systems. It also applies to tools that need exact undo, replay, or evidence.

You do not need a quantum computer to use these ideas. Reversible state, exact round trips, deterministic artifacts, replayable workflows, scoped capabilities, and proof-carrying packages also matter in classical systems.

When software crosses classical, reversible, quantum, and external-effect boundaries, Wheeler makes those boundaries visible and enforceable.

## Roads onward

- [*Home Was the Easy Part*](tutorials/index.mdx), the *Vela* mission account
- [The Reckoning of the Reach](appendix/index.mdx)
- [The Wheeler Language](reference/language-profile.md)
- [The program ledger](examples.md)
- [Artifacts and Bytecode](reference/bytecode.md) and [The Ways of Return](reference/virtual-machine.md)
- [Quantum Targets](reference/quantum-targets.md)
- [Observations, Replay, and Retry](reference/hybrid-runs.md)
- [Packages, Locks, and Builds](reference/packages.md)
