---
sidebar_position: 1
slug: /
title: What Is Wheeler?
description: Wheeler's reversible, quantum, and systems programming model, its executable core, and the work still in progress.
---

# What Is Wheeler?

*A reversible, quantum, systems programming language for people wondering why all of those words need to be in the same sentence.*

> **Project status:** Wheeler is under active development. It has an executable core and one canonical bytecode format. The broader language described here is the destination, not a claim that every feature is finished today.

## Okay, what is all of this?

Wheeler is a programming language for **reversible computing**, **quantum computing**, and programs that combine quantum work with ordinary classical software.

That sentence is technically accurate and emotionally unhelpful, so let us try again.

Most programming languages are built around doing things and moving on. They overwrite variables, discard temporary values, delete objects, print output, call APIs, and generally leave a trail of lost information behind them. On an ordinary computer, this is normal. Nobody calls an incident-response team because `x = 7` forgot that `x` used to be `4`.

Reversible and quantum computation care much more about where information goes.

A reversible operation must preserve enough information to run backward exactly. A quantum operation obeys stricter rules still: quantum data cannot be casually copied, inspected, or thrown away, and useful temporary state often has to be deliberately **uncomputed**.

Wheeler makes those concerns part of the language instead of leaving them as comments, conventions, helper libraries, and prayers.

The basic idea is:

- write ordinary classical code when ordinary classical code is appropriate;
- mark operations as reversible when the compiler can validate and generate an inverse;
- write provider-neutral quantum operations with generated adjoints;
- reuse eligible reversible logic as coherent quantum logic;
- make measurement, external effects, retries, and replay explicit;
- attach machine-checkable claims to the same code as the proof profile lands.

All of those forms lower to one reversible typed Wheeler IR. “Reversible” is an accounting discipline, not a claim that printing a diagnostic is bijective: ordinary destructive transitions declare bounded rewind data, host observations declare barriers, coherent calls declare exact finite permutations, and unitary regions declare adjoints. Measurement and workflow edges stay visible. Native code and provider circuits are derived from that IR rather than quietly replacing it.

Wheeler asks not only **“What does this program do?”** but also **“What information did it consume, what can be undone, and what evidence do we have that any of this is correct?”**

That is the project in one paragraph. The rest explains why it is interesting rather than merely exhausting.

## The smallest useful example

Here is an executable reversible counter:

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

The `rev` declaration says that `increment` is reversible. Wheeler generates its inverse: subtract one instead of adding one.

The `reverse` block executes inverse calls in reverse lexical order. This is not a saved screenshot of the machine. It is new execution of mathematically inverse operations.

That distinction sounds fussy until a program includes measurement, files, network requests, remote jobs, or a payment API. At that point, “just reverse it” becomes less of a design and more of a hostage negotiation.

## Is Wheeler a time machine?

No.

Wheeler is strict about several operations that are often lazily called “reverse” even though they mean different things.

**Inverse execution** runs the mathematical inverse of a reversible function.

**VM rewind** walks backward through retained classical execution history.

**Uncomputation** cleans temporary reversible or quantum state by applying inverse operations.

**Replay** reuses recorded observations so later classical decisions can be reproduced.

**Retry** prepares new state and performs the work again, possibly obtaining a different result.

These operations are related, but not interchangeable. Replaying a measurement does not undo the original measurement. Retrying a hardware job does not restore the original qubits. Running an inverse circuit after a quantum state has disappeared is not “rewinding the universe.” The universe, regrettably, has no customer-support escalation path.

This vocabulary is one of Wheeler’s central contracts. It prevents programs from making promises that physics, remote services, or discarded history cannot keep.

## Why should I care?

There are five large reasons.

### 1. Stop writing the same algorithm twice

Quantum algorithms often need a classical reference implementation and a separate quantum oracle or circuit implementation. The two versions are supposed to mean the same thing. Then one gets fixed, the other does not, and six months later everyone is comparing results with the solemn expression of people defusing a bomb.

Wheeler’s `coherent rev` model reduces that duplication:

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

The same exact finite permutation executes over ordinary classical state and is lifted into coherent execution. The implemented subset begins with simple finite permutations such as XOR. Width-explicit modular arithmetic, table lookup, reversible comparison, and richer oracle building blocks remain planned work.

Why care? The classical implementation becomes the testable reference, the quantum implementation, and eventually the subject of proof obligations. One source definition gets several jobs instead of several definitions getting one opportunity each to disagree.

### 2. Let the compiler handle the mistakes humans repeat

Quantum code frequently needs an adjoint: the operations in reverse order, with each gate replaced by its inverse.

Humans can maintain that manually. Humans can also synchronize distributed databases with handwritten shell scripts. The question is not whether it is possible. The question is what kind of week you would like to have.

A Wheeler `unitary` method receives a generated adjoint. The checked-in QFT writes one forward circuit and invokes it in reverse:

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

The executable profile already verifies static register references, circuit structure, generated adjoints, coherent calls, and measurement workflow. Complete affine quantum slices, dirty-ancilla checking, and dynamic resource control remain WIP work.

Why care? Generated inverses, affine ownership, and explicit uncomputation turn subtle correctness conventions into compiler-enforced structure.

### 3. Treat quantum programs as workflows, not glamorous function calls

A useful quantum program is usually not:

```text
result = quantumComputer.doQuantumThing();
```

It is closer to:

1. construct parameters;
2. select a target;
3. lower a circuit for that target;
4. submit a job;
5. retain its durable identity;
6. wait somewhere between milliseconds and geological time;
7. handle failure, cancellation, duplicate delivery, stale capabilities, or process restart;
8. validate the result;
9. update classical state;
10. repeat.

Wheeler models hybrid quantum/classical work as a durable lifecycle. The current runtime has content-identified tasks and events, acknowledged-job recovery, bounded persistence, result validation, branch quarantine, retry, cancellation, replay, and commit horizons. The source profile exercises a bounded optimizer; production-scale continuation syntax and more dynamic applications remain unfinished.

A long-running optimizer can therefore preserve a submission identity, recover an accepted result, and apply it exactly once. It can replay a recorded observation to reproduce later classical state without submitting another paid job. Or it can deliberately retry, producing a new physical lineage.

Why care? Real quantum hardware is remote, asynchronous, capability-dependent, and nondeterministic. Wheeler designs for the machine that exists, not the one implied by a tidy five-line tutorial.

### 4. Keep proofs and experiments adjacent without pretending they are the same

Reversible and quantum programs naturally produce claims:

- this inverse restores the original state;
- this circuit is unitary;
- this generated adjoint is exact;
- these circuits are equivalent;
- every temporary qubit returns clean;
- this plan stays below a qubit or depth limit;
- replay never submits another target job.

Today, such claims often live in prose, tests, or the reassuring tone of a pull-request description.

Wheeler’s proof direction puts contracts, theorems, proof blocks, resource claims, and canonical certificates in the language and package model. The first trusted-kernel slices now check generated inverses, generated quantum adjoints, adjacent-inverse circuit rewrites, and straight-line step bounds against exact artifact bodies. General propositions, contracts, quantum/resource rules, and structured proof terms remain unimplemented; `QFTProof.w` is still an executable conformance law, not a trusted quantum theorem certificate.

Proof is also distinct from experiment. A simulator run or a 4,096-shot hardware result may be useful evidence, but it is not a universal theorem. Wheeler records experimental provenance—target identity, request, shots, estimator, and observations—without allowing “it passed on Tuesday” to mature into mathematics through repetition.

Why care? Quantum software combines ordinary software bugs, mathematical claims, and probabilistic hardware. Keeping those categories distinct is not academic fussiness. It is basic hygiene.

### 5. Build a systems language, not only a circuit notation

The destination is not a language that can express three famous algorithms and then asks Python to handle everything difficult.

The executable core already has signed and Boolean values, immutable records, tagged variants, fixed arrays, nonescaping slices, typed calls, bounded loops, bounded regions, owner-returning word/byte/UTF-8/map factories, nonescaping storage borrows, strict validation, deterministic classical function-module linking, canonical bytecode, deterministic package formats, and exact offline dependency inputs. Owning parameters, returned loans, mutable slices, UTF-8 strings, generic deterministic collections, full nominal/package modules, and streaming effects remain under construction; explicit bounded UTF-8/binary input and byte-output entry effects with checked publish lengths already execute.

The production compiler is intended to be written in Wheeler. The package manager, verifier, runtime, [OpenQASM](https://openqasm.com/) emitter, build planner, and test tools are intended to become Wheeler programs as well. A successful self-hosting bootstrap compiles the compiler twice and requires byte-identical canonical `.wbc` artifacts.

Why care? Self-hosting is a ruthless test of whether a language is general-purpose. A compiler needs strings, variants, maps, graphs, errors, modules, file input, output, allocation, and enough control flow to become annoyed with all of them. If Wheeler can build Wheeler, it has escaped the “interesting demo language” enclosure.

## What could you build with it?

Once the remaining language and standard-library slices land, useful projects extend well beyond textbook quantum algorithms.

A **reversible packet codec** could parse bytes into typed records and run its inverse to recreate the exact canonical frame.

A **reversible image transform** could apply an integer wavelet transform to a tile and reconstruct the original bytes exactly.

A **time-travel debugger** could distinguish machine rewind from inverse execution, making the difference visible instead of hiding both behind one suspiciously cheerful undo button.

A **quantum search playground** could use one predicate as a classical testable function and as the coherent oracle inside Grover search.

A **certifying circuit optimizer** could emit a smaller circuit with checkable evidence that it preserves the old circuit’s meaning.

A **recoverable molecular-energy experiment** could persist optimizer steps, submissions, results, uncertainty estimates, and target identities, then resume after a crash or replay without spending another hardware budget.

A **fault-tolerance planner** could calculate logical qubits, code distance, correction cycles, magic-state throughput, and failure budgets before asking a target to do anything expensive.

A **distributed entanglement workflow** could track session identities, delayed heralding, timeout, cancellation, and branch discard without claiming that deleting a database row destroyed a Bell pair in another building.

A **hermetic package forge** could build offline from exact content identities, verify provenance and proof certificates, and deny undeclared filesystem or network access before the effect occurs.

A far-future **[algorithm foundry](future/foundry.md)** could search a finite program grammar, uncompute rejected candidates, check every bounded input, prove correctness and relative minimality, and publish the discovered implementation as a normal Wheeler package. That is a hardware- and proof-system moonshot, not current syntax or a roadmap promise.

A future **[adversarial timeline debugger](future/murphy.md)** could generate every bounded message/fault schedule for a distributed protocol, replay a proposed failure, prove the shortest counterexample, or return an exact bounded-safety certificate. No counterexample and no certificate means `Inconclusive`, not “probably cosmic rays.”

And, naturally, someone will build a reversible todo list. Completing an item will be mathematically invertible. Avoiding the item will remain an unsolved human problem.

## What works today?

Wheeler is not starting from a whiteboard.

The repository currently includes:

- familiar class and method syntax with source-located diagnostics;
- signed and Boolean values, immutable records, tagged variants, fixed arrays, nonescaping slices, typed calls, recursion, conditionals, bounded loops, and function-local bounded regions with affine mutable word/byte buffers, immutable UTF-8 owners, signed maps, and bounded classical function modules;
- generated inverses for the supported reversible subset;
- one canonical `.wbc` format, strict decoding, semantic verification, disassembly, exact VM rewind, and finite generated-inverse, generated-adjoint, circuit-rewrite, and static-step-bound proof rules;
- provider-neutral quantum regions, generated circuit adjoints, and coherent XOR lifting;
- an asynchronous ideal state-vector target and application-supplied OpenQASM 3 execution interface;
- durable hybrid events, recovery, replay, retry, cancellation, quarantine, and transaction phases;
- canonical package, workspace, lock, build-plan, vendor, and `.wpk` archive formats;
- exact offline locked dependency builds and source-bound sealed-plan execution with explicit grants and atomic output publication;
- Tree-sitter grammar, corpus, highlighting, and executable examples.

Checked-in examples cover reversible state, typed aggregate values, bounded and recursive control, exact classical module source sets, one function used classically and coherently, QFT with a generated adjoint, a bounded hybrid optimizer, circuit normalization, and static error-correction structure.

Major unfinished work includes borrowing, mutable slices, compiler-scale region storage, a Wheeler standard library, a self-hosted compiler and package manager, native Java-free execution, dynamic target-resident control, richer coherent arithmetic, complete application fixtures, and the complete proof language and kernel.

The honest answer is: **Wheeler is executable, but it is not finished.** WIPs are reviewed design commitments and work plans, not a magical bag of features summoned by adding an import.

## What Wheeler is not

### It is not “Java, but backward”

The syntax is intentionally familiar, and the stage-0 implementation uses Java. Java is not Wheeler’s runtime contract. The project intends to self-host and delete the Java and Gradle path once the native Wheeler toolchain reaches conformance.

### It is not Qiskit with different punctuation

Wheeler uses provider-neutral quantum regions and lowers supported programs to [OpenQASM 3](https://openqasm.com/). Qiskit or another provider SDK may consume that output outside Wheeler, but Python APIs, credentials, provider objects, and SDK state are not Wheeler language values or artifact semantics.

### It does not pretend measurement is reversible

Measurement creates a classical observation. Wheeler can record and replay that observation or prepare new state and retry. It cannot restore the original unknown quantum state because a transaction rolled back. Physics reviewed the feature request and marked it “working as designed.”

### It does not promise every classical function becomes quantum code

Only exact finite reversible functions with supported coherent lowerings can be lifted. File I/O, random values, measurement, unchecked allocation, floating-point accidents, and “trust me, this is bijective” do not become unitary because somebody adds a modifier.

### It does not require every program to be reversible

Compilers allocate memory. Programs read files. Tools print diagnostics. Hybrid workflows receive measurements. Wheeler does not label everything reversible. It makes reversible, logged, irreversible, quantum, and external effects explicit enough for the compiler and runtime to know which promises remain valid.

## Who is Wheeler for?

Wheeler is for people working at the intersection of programming languages, quantum software, formal methods, runtimes, compilers, reproducible systems, and anyone who has looked at an “undo” feature and muttered, “That is absolutely not what undo means.”

You do not need a quantum computer to care about the project. Reversible state, exact round trips, deterministic artifacts, replayable workflows, capability-scoped tools, and proof-carrying packages are useful systems ideas on their own.

You also do not need to believe every future computer will be quantum. Wheeler’s bet is narrower: when software crosses classical, reversible, quantum, and external-effect boundaries, those boundaries should be visible and enforceable.

## The one-paragraph answer

Wheeler makes information flow a first-class part of programming. It lets ordinary code remain ordinary, gives reversible functions compiler-validated inverses, lets eligible reversible logic run classically or coherently, represents quantum work without binding source code to one provider, treats remote quantum execution as a durable workflow, and aims to connect executable programs with checkable proofs and resource claims. That can eliminate duplicated classical and quantum implementations, make uncomputation and ownership safer, make experiments reproducible, and turn “we think this circuit still means the same thing” into something a machine can check.

Or, more briefly:

> **Wheeler is trying to make “do it, undo it, run it quantumly, resume it tomorrow, and prove what happened” one coherent programming model.**

Admittedly, “coherent” is doing a lot of work in that sentence.

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
