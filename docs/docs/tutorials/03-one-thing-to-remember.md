---
sidebar_position: 4
title: Give the machine one thing to remember
description: Add one named state value and observe it in the execution report.
tutorial_id: T03
tutorial_part: ordinary-state
tutorial_order: 3
tutorial_kind: exact-execution
tutorial_source: primary-fence
tutorial_expectation: state-value-zero
tutorial_evidence: exact-classical-execution
---

# Give the machine one thing to remember

Before launch, every compartment on the *Vela* carried a small status lamp. Green meant ready. Dark meant one of fourteen things,
all of which the maintenance manual described as *not ready*.

The book selected one imaginary lamp and removed the other thirteen possibilities.

```text
lamp = 0
```

It had reduced a starship to one named number. This was unfair to the starship and helpful to the apprentice.

## Question

How can a Wheeler program carry one value from its beginning to its final report?

`Wake` had structure but no declared state. We will add one named location with one starting value and change nothing else.

## What you already know

You can save Wheeler source, compile it into a `.wbc` artifact, and execute that artifact. You know that compilation and execution
are separate events.

You do not need to know how the value changes yet. This lesson leaves it alone.

## Predict

The new program declares `lamp = 0` and contains no instruction that changes `lamp`.

What value should the final report show?

Write down the answer before you run the program. A prediction turns output into a test of your explanation rather than a surprise
you explain afterward.

## Program

Save this complete source as `build/tutorial/FirstSignal.w`:

```java
classical class FirstSignal {
  state long lamp = 0;

  entry void main() {
  }
}
```

The empty line separates the state declaration from the entry. It changes nothing about execution.

## Run it

Compile the source:

```bash
./bootstrap/gradlew -p bootstrap -q :tools:wheeler \
  --args="compile $PWD/build/tutorial/FirstSignal.w -o $PWD/build/tutorial/FirstSignal.wbc"
```

The current compiler reports:

```text
wrote .../build/tutorial/FirstSignal.wbc (392 bytes)
```

Now execute the artifact:

```bash
./bootstrap/gradlew -p bootstrap -q :tools:wheeler \
  --args="run $PWD/build/tutorial/FirstSignal.wbc"
```

The runtime reports:

```text
FirstSignal (classical) halted after 1 steps
lamp = 0
```

## What happened

The program began with `lamp` equal to `0`. Its entry body did nothing. The program halted with `lamp` still equal to `0`.

The output matches the prediction. This result is not impressive, which makes it valuable. Before studying change, we need a case
in which nothing changes.

Mara called it a lamp that never turned on. Osei called it a stable initial condition. Sana recorded both phrases and the exact
value, because prose has never prevented a maintenance dispute as reliably as a number with a name.

## Walk through it

The new line has four parts:

```java
state long lamp = 0;
```

`state` says that the class owns a value that the runtime will track.

`long` selects the current signed whole-number type used by this example.

`lamp` gives the state location a name.

`= 0` gives that location its initial value.

The final semicolon ends the declaration. It belongs to syntax and does not introduce another idea.

The runtime prints `lamp = 0` because `lamp` is declared program state. It does not print every temporary detail used inside the
runtime.

## Name the idea

A **state value** is a named value that belongs to the program at a particular point in its execution.

The **initial value** is the value assigned when that program state begins.

For this run, the state begins as:

```text
lamp = 0
```

It ends as:

```text
lamp = 0
```

Those equal lines tell us that the named value is equal at the two points. They do not yet tell us what would happen after a change
or whether the complete machine returned to an earlier state.

## Try one change

Change the declaration to:

```java
state long lamp = 1;
```

Before compilation, predict the final line. Then compile and run the edited program.

You should see:

```text
lamp = 1
```

Restore `lamp = 0` afterward. The next lesson will change the value during execution rather than changing its initial declaration.

## What this does not mean

A state value is not the complete state of the host computer, runtime process, or physical ship. It belongs to the declared
Wheeler program model.

An unchanged final value also does not prove that no intermediate work occurred. This program has no body instruction, so we know
that from its structure. Later programs may change a value and change it back. Equal endpoints alone do not reveal the path.

That distinction will matter when the crew tries to decide whether the *Vela* returned or merely arrived with a familiar number on
the console.

## Check yourself

If `lamp` starts at `7` and the entry contains no instructions, what final value should the runtime report?

It should report `7`.

What supports that answer?

- the declaration supplies the initial value.
- the entry contains no instruction that changes it.
- execution reaches a successful halt.

## Next question

How does a program change a state value while it runs?

The next draft lesson will add one assignment. The tutorial does not link that page until its source, output, explanation, and
language ledger are complete.

## Language ledger

**Words earned:** state value, initial value.

**Words sharpened:** same. The initial and final values are equal. We have not claimed that every part of the machine followed an
inverse path.

**Phrases retired:** "nothing happened" when the more precise claim is "the declared state value did not change."

**Evidence label:** exact classical execution. The displayed source halts after one step with `lamp = 0` under the current stage-0
profile.
