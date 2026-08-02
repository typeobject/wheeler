---
sidebar_position: 3
title: Ask the machine to act
description: Execute the first Wheeler artifact and read its bounded report.
tutorial_id: T02
tutorial_part: ordinary-state
tutorial_order: 2
tutorial_kind: exact-execution
tutorial_source: previous-step
tutorial_expectation: run-success
tutorial_evidence: exact-classical-execution
---

# Ask the machine to act

The book inspected `Wake.wbc` and displayed a new sentence.

```text
An instruction that never executes has made a very tidy promise.
```

Osei approved of tidy promises. Mara pointed out that the *Vela* would remain in its berth if everyone stopped there.

## Question

What changes when you run a compiled Wheeler artifact?

The source already exists. The artifact already exists. This step asks the runtime to begin at the declared entry and carry out the
artifact's instructions.

## What you already know

[The previous step](01-write-the-first-instruction.md) created this source:

```java
classical class Wake {
  entry void main() {
  }
}
```

It compiled the source into `build/tutorial/Wake.wbc`. Restore and compile that exact version before continuing if you changed it.

## Predict

The entry body contains no instructions. What should a successful run report?

It should not invent useful work merely because we asked politely. It should begin, find no body instruction to execute, and halt.

## Program

This experiment executes the exact `Wake.wbc` artifact from the previous step. It does not compile the source again. That
separation lets us ask one question about one boundary.

## Run it

From the repository root, run:

```bash
./bootstrap/gradlew -p bootstrap -q :tools:wheeler \
  --args="run $PWD/build/tutorial/Wake.wbc"
```

After any host Java warnings, the Wheeler runtime prints:

```text
Wake (classical) halted after 1 steps
```

The runtime counts the entry transition as one bounded step. The empty body contributes no additional instruction.

## What happened

The runtime verified and executed the artifact. Execution reached the end of `main`, then halted successfully.

Nothing visible changed inside the program because the program declared no state. That is still an execution result. The runtime
started the program, followed its control structure, and stopped within a known number of steps.

The *Vela* had millions of state locations and a schedule full of work. The book began with none because scale is good at hiding
causes. One empty room makes it easy to notice the door.

## Walk through it

The report contains four useful pieces:

| Text | Meaning in this experiment |
| --- | --- |
| `Wake` | The class whose entry executed |
| `classical` | The execution model declared by the class |
| `halted` | Execution reached a successful stopping point |
| `after 1 steps` | The bounded runtime recorded one entry transition |

The report does not contain a program state value. `Wake` did not declare one.

## Name the idea

To **execute** a program is to carry out its accepted instructions under a runtime.

A **run** is one bounded execution attempt with one artifact and runtime configuration.

A successful halt describes this run. It does not establish what another artifact, another input, or an edited source file would
do.

The distinction seems fussy when the program is empty. Fussy distinctions are cheapest when nothing is on fire.

## Try one change

Run the same `Wake.wbc` artifact again without recompiling it.

Predict the report first. Both runs should report the same class, execution model, halt status, and step count. This program has no
input, mutable state, target, or sampling operation that could vary between runs.

## What this does not mean

Deterministic output from `Wake` does not show that every Wheeler program has one fixed result. Later programs will accept inputs,
change state, sample quantum measurements, and communicate with targets.

It also does not show that rerunning and replaying are the same. You ran the artifact again. A later replay lesson will consume a
recorded observation without repeating its target event.

## Check yourself

Put these events in order:

1. execute the artifact.
2. write the source file.
3. compile the source.

The order is source, compilation, execution.

If you edit `Wake.w` after compilation and run the old `Wake.wbc`, which one does the runtime execute? It executes the artifact.
The source edit has no effect until another compilation publishes a replacement artifact.

## Next question

A program can run and stop without remembering anything. What must it declare before its report can include a value?

Continue with [Give the machine one thing to remember](03-one-thing-to-remember.md).

## Language ledger

**Words earned:** execute, run, halt.

**Words sharpened:** result. Here it means the bounded report from one exact execution, not every possible behavior of the source.

**Phrases retired:** "compile and run" as if translation and execution were one event.

**Evidence label:** exact classical execution. The stated artifact halts after one runtime step under the current stage-0 profile.
