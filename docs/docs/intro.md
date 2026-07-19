---
sidebar_position: 1
slug: /
title: What is Wheeler?
description: Wheeler's reversible, quantum, and systems programming model, its executable core, and the work still in progress.
---

# What is Wheeler?

Wheeler is under active development. It has an executable core and one canonical bytecode format. This page also covers planned parts of the language that are not finished yet.

Wheeler is a programming language for reversible computing, quantum computing, and software that uses both quantum and classical code.

Most languages let programs overwrite or discard information; a variable changes value; a temporary object disappears. A program prints output or calls an API, then keeps going.

That works well on an ordinary computer. Reversible and quantum programs need stricter rules about where information goes.

A reversible operation must keep enough information to run backward exactly. Quantum operations have more limits. Quantum data cannot be copied, read, or discarded like normal data, and temporary quantum state often has to be uncomputed on purpose.

Wheeler puts those rules in the language. The compiler and runtime do not have to guess what a comment or helper library meant.

Wheeler follows these rules:

- use ordinary classical code where it fits;
- mark an operation as reversible when the compiler can check it and build its inverse;
- write quantum operations without tying source code to one provider;
- reuse supported reversible logic as coherent quantum logic;
- make measurement, external effects, retries, and replay visible;
- place machine-checkable claims next to the code as proof support grows.

Each form lowers to one typed Wheeler IR. Reversibility here means careful information accounting. It does not mean that printing a message can somehow be undone.

A destructive classical step records bounded rewind data. A host observation creates a barrier. A coherent call describes an exact finite permutation, while a unitary region has an adjoint. Measurement and workflow boundaries stay visible. Native code and provider circuits come from the same IR, so they do not replace its meaning.

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
  state long bit = 0;
  state long measured = 0;
  qreg q = new qreg(1);

  coherent rev void flip() {
    bit ^= 1;
  }

  unitary void oracle() {
    q.apply(flip);
  }

  entry void main() {
    flip();
    assert(bit == 1);
    reverse flip();
    assert(bit == 0);

    prepare(q, 0);
    oracle();
    measured = measure(q);
    assert(measured == 1);
  }
}
```

The same exact finite permutation runs over classical state and can also run coherently. The current implementation starts with simple permutations such as XOR. Wider modular arithmetic, table lookup, reversible comparison, and richer oracle tools are planned.

One source definition can be both the testable classical reference and the quantum operation. Later, it can also carry proof duties. That gives the two execution paths less room to disagree.

### 2. Generate inverses instead of maintaining them by hand

Quantum code often needs an adjoint. The adjoint reverses the operation order and replaces each gate with its inverse.

A person can write and update that code by hand. The compiler can do it more consistently.

A Wheeler `unitary` method gets a generated adjoint. The checked-in QFT example writes one forward circuit and then invokes it in reverse:

```java
quantum class QFT {
  state long measured = 0;
  qreg q = new qreg(3);

  unitary void qft() {
    H(q[0]);
    CPhase(q[1], q[0], 1.5707963267948966);
    CPhase(q[2], q[0], 0.7853981633974483);
    H(q[1]);
    CPhase(q[2], q[1], 1.5707963267948966);
    H(q[2]);
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

1. build parameters;
2. choose a target;
3. lower a circuit for that target;
4. submit a job;
5. save the job identity;
6. wait for completion;
7. handle failure, cancellation, duplicate delivery, stale capabilities, or a restart;
8. validate the result;
9. update classical state;
10. repeat when needed.

Wheeler treats hybrid quantum and classical work as a durable lifecycle. The current runtime has content-identified tasks and events, recovery for accepted jobs, bounded persistence, result checks, branch quarantine, retry, cancellation, replay, and commit horizons. The source profile includes a bounded optimizer. Production continuation syntax and more dynamic applications remain unfinished.

A long-running optimizer can save a submission identity, recover its accepted result, and apply that result once. It may replay a recorded observation without buying another hardware run. A deliberate retry creates a new physical lineage instead.

This model matches remote, asynchronous, capability-based hardware. It also makes failures and restarts part of the design.

### 4. Keep proofs separate from experiments

Reversible and quantum programs make claims such as these:

- an inverse restores the starting state;
- a circuit is unitary;
- a generated adjoint is exact;
- two circuits have the same meaning;
- every temporary qubit returns clean;
- a plan stays within its qubit or depth limit;
- replay never submits another target job.

Those claims often live in prose or tests. Wheeler is moving contracts, theorems, proof blocks, resource claims, and canonical certificates into the language and package model.

The first trusted-kernel pieces can check generated inverses, generated quantum adjoints, adjacent-inverse circuit rewrites, and straight-line step bounds against exact artifact bodies. General propositions, contracts, quantum and resource rules, and structured proof terms are not implemented yet. `QFTProof.w` remains an executable conformance law, not a trusted quantum theorem certificate.

An experiment is useful evidence, but it is not a universal proof. A simulator run or a 4,096-shot hardware result describes what happened during that run. Wheeler records the target, request, shot count, estimator, and observations without treating repeated success as a theorem.

Quantum software mixes normal bugs, mathematical claims, and probabilistic hardware; clear boundaries make each kind of evidence easier to judge.

### 5. Build a systems language around the quantum parts

Wheeler is meant to do more than express a few circuits and hand the rest of the work to Python.

The executable core already has signed and Boolean values, immutable records, tagged variants, fixed arrays, nonescaping slices, typed calls, bounded loops, and bounded regions. It also has factories for owned word, byte, UTF-8, and map storage; nonescaping storage borrows; strict validation; deterministic module linking; canonical bytecode; deterministic package formats; and exact offline dependency inputs.

Some major pieces are still under construction. These include owning parameters, returned loans, mutable slices, fuller UTF-8 strings, generic deterministic collections, complete nominal and package modules, and streaming effects. Explicit bounded UTF-8 and binary input already run, as does byte output with checked publish lengths.

The production compiler is intended to be written in Wheeler. The same applies to the package manager, verifier, runtime, [OpenQASM](https://openqasm.com/) emitter, build planner, and test tools. A successful self-hosting bootstrap compiles the compiler twice and requires byte-identical canonical `.wbc` output.

A compiler uses many parts of a general-purpose language. Building Wheeler with Wheeler will test whether those parts work together under real load.

## Possible projects

Once the remaining language and standard-library work lands, Wheeler could support projects beyond textbook quantum algorithms.

A reversible packet codec could parse bytes into typed records, then run its inverse to recreate the canonical frame exactly.

A reversible image transform could apply an integer wavelet transform to a tile and recover the original bytes.

A time-travel debugger could show the difference between VM rewind and inverse execution instead of calling both actions "undo."

A quantum search playground could use one predicate as a classical test and as the coherent oracle for Grover search.

A certifying circuit optimizer could produce a smaller circuit with checkable evidence that its meaning did not change.

A recoverable molecular-energy experiment could save optimizer steps, submissions, results, uncertainty estimates, and target identities. After a crash, it could resume or replay without spending another hardware budget.

A fault-tolerance planner could calculate logical qubits, code distance, correction cycles, magic-state throughput, and failure budgets before submitting costly work.

A distributed entanglement workflow could track sessions, delayed heralding, timeouts, cancellation, and discarded branches. Deleting a database row wouldn't be confused with destroying a Bell pair elsewhere.

A hermetic package builder could work offline from exact content identities. It could verify provenance and proof certificates, then block undeclared file or network access before the effect starts.

The far-future [algorithm foundry](future/foundry.md) explores a bounded program grammar, uncomputes rejected candidates, checks every bounded input, proves correctness and relative minimality, and publishes the result as a normal Wheeler package. It is a research direction, not a current feature or roadmap promise.

The future [adversarial timeline debugger](future/murphy.md) explores every bounded message and fault schedule for a distributed protocol. It can replay a failure, prove the shortest counterexample, or return an exact bounded-safety certificate. Without a counterexample or certificate, the result is `Inconclusive`.

## What works today?

Wheeler already has an executable base.

The repository includes:

- familiar class and method syntax with source-located diagnostics;
- signed and Boolean values, immutable records, tagged variants, fixed arrays, nonescaping slices, typed calls, recursion, conditionals, bounded loops, and function-local bounded regions;
- affine mutable word and byte buffers, immutable UTF-8 owners, signed maps, and bounded classical function modules;
- generated inverses for the supported reversible subset;
- one canonical `.wbc` format, strict decoding, semantic verification, disassembly, and exact VM rewind;
- finite proof rules for generated inverses, generated adjoints, circuit rewrites, and static step bounds;
- provider-neutral quantum regions, generated circuit adjoints, and coherent XOR lifting;
- an asynchronous ideal state-vector target and an application-supplied OpenQASM 3 execution interface;
- durable hybrid events, recovery, replay, retry, cancellation, quarantine, and transaction phases;
- canonical package, workspace, lock, build-plan, vendor, and `.wpk` archive formats;
- exact offline locked builds, sealed-plan execution, explicit grants, and atomic output publication;
- a Tree-sitter grammar, corpus, highlighting, and executable examples.

The examples cover reversible state, typed aggregate values, bounded and recursive control, classical modules, coherent reuse, QFT with a generated adjoint, a bounded hybrid optimizer, circuit normalization, and static error-correction structure.

Large areas are still unfinished. They include borrowing, mutable slices, and compiler-scale region storage. The project also needs a standard library, self-hosted tools, and native Java-free execution. Dynamic target control, richer coherent arithmetic, complete application fixtures, and the full proof system remain open.

Wheeler runs today, but the language is not complete. The WIPs describe reviewed design work and implementation plans; they do not claim that every proposed feature already exists.

## Common questions

### Does Wheeler run on Java?

The syntax is familiar, and the stage-0 implementation uses Java. Wheeler's runtime contract is independent of Java. The project plans to self-host, then remove the Java and Gradle path after the native Wheeler toolchain reaches conformance.

### Does Wheeler replace provider SDKs?

Wheeler uses provider-neutral quantum regions and can lower supported programs to [OpenQASM 3](https://openqasm.com/). Qiskit or another SDK may consume that output outside Wheeler. Python APIs, credentials, provider objects, and SDK state do not become Wheeler values or artifact semantics.

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

## Further reading

- [Language profile](reference/language-profile.md)
- [Executable examples](examples.md)
- [Bytecode format](reference/bytecode.md) and [virtual machine](reference/virtual-machine.md)
- [Quantum targets](reference/quantum-targets.md)
- [Hybrid runs, history, and replay](reference/hybrid-runs.md)
- [Packages, locks, archives, and offline builds](reference/packages.md)
- [WIP index](proposals/README.md)
- [Wheeler repository](https://github.com/typeobject/wheeler)
- [Published documentation](https://wheeler.typeobject.com/)
