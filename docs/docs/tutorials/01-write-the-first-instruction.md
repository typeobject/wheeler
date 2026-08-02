---
sidebar_position: 2
title: Write the first instruction
description: Create a complete Wheeler source file and compile it into an artifact.
tutorial_id: T01
tutorial_part: ordinary-state
tutorial_order: 1
tutorial_kind: exact-compilation
tutorial_source: primary-fence
tutorial_expectation: compile-success
tutorial_evidence: exact-classical-compilation
---

# Write the first instruction

Thirty-seven days before the failed return, the *Vela* waited in its construction berth. It had no mysterious result, no damaged
lineage, and no reason to know the apprentice's name.

The book displayed three lines of punctuation and called them a complete program.

## Question

Can ordinary text become something the Wheeler machine accepts?

That is a smaller question than what a program means. We will first give the compiler a complete source file and ask whether the
file follows the language's current structural rules.

## What you already know

You can create a text file and run a terminal command. You do not need to know what a class, method, entry point, or artifact is.
Those words can wait until the machinery gives them work to do.

Run commands from the root of your Wheeler source checkout. Configure JDK 26 once in the terminal session:

```bash
export JAVA_HOME="$(brew --prefix openjdk)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
mkdir -p build/tutorial
```

The [development guide](../reference/development.md) explains the complete local setup.

## Predict

A Wheeler source file is ordinary UTF-8 text. Before you compile it, predict which of these things the text editor has created:

1. a running process.
2. a quantum state.
3. a source file containing characters.

Only the third has happened. Writing instructions and carrying them out are different events.

## Program

Save this complete text as `build/tutorial/Wake.w`:

```java
classical class Wake {
  entry void main() {
  }
}
```

Do not improve it. Its emptiness is useful. When an experiment contains almost nothing, almost nothing can hide the result.

## Compile it

Run this command from the repository root:

```bash
./bootstrap/gradlew -p bootstrap -q :tools:wheeler \
  --args="compile $PWD/build/tutorial/Wake.w -o $PWD/build/tutorial/Wake.wbc"
```

The command prints a line like this after any host Java warnings:

```text
wrote .../build/tutorial/Wake.wbc (360 bytes)
```

The leading path depends on the location of your checkout. The filename and byte count belong to this exact source and current
compiler profile.

## What happened

The compiler read `Wake.w`, accepted its structure, and wrote `Wake.wbc`.

The two files are not interchangeable.

- `Wake.w` contains source text intended for people and the compiler.
- `Wake.wbc` contains canonical Wheeler bytecode intended for the Wheeler verifier and runtime.

The compiler did not run the program. It produced an artifact that another command can verify and execute.

Mara called this paperwork. Osei called it the first point at which the ship could reject a bad instruction before trusting it.
They were describing the same event at different scales.

## Walk through it

`classical class Wake` gives the program a class named `Wake` and marks it as classical rather than quantum or hybrid.

`entry void main()` marks the place where execution will begin. The braces contain its instructions.

There are no instructions between the inner braces. Empty is not missing. The program has a declared beginning and nothing to do
after it begins.

The punctuation belongs to Wheeler syntax. You do not need to memorize the full grammar. You will reuse this shape while changing
one small part at a time.

## Name the idea

A **source file** is authored text in a programming language. It describes a program before the compiler translates that text into
an executable artifact.

To **compile** is to perform that translation and check the rules required at the compiler boundary.

Compilation success means the compiler accepted this source under its current profile. It does not mean the program has run, does
what its author intended, or proves a claim about every input.

## Try one change

Change the first line to this:

```java
classical class Woken {
```

Compile the file again to the same `Wake.wbc` path. Predict which name the runtime will later report, `Wake` or `Woken`.

Then restore the original source and compile it once more. Later lessons assume the exact `Wake` program shown above.

## What this does not mean

The word `classical` does not mean old-fashioned, approximate, or unimportant. It selects Wheeler's ordinary classical execution
model. The series will earn the contrast with `quantum` after the required ideas exist.

A `.wbc` file is not native machine code and is not a hidden copy of the source text. It is Wheeler's canonical bytecode artifact.
The bytecode reference will matter later. Right now, the artifact gives the runtime something exact to inspect.

## Check yourself

Which event has happened so far?

- The text editor created source.
- The compiler translated source into an artifact.
- The runtime executed the artifact.

The first two happened. The third has not.

## Next question

The artifact exists. Does it do anything?

Continue with [Ask the machine to act](02-ask-the-machine-to-act.md).

## Language ledger

**Words earned:** source file, compile, artifact.

**Words sharpened:** program. It can refer to authored instructions without implying that execution has occurred.

**Phrases retired:** "the program ran" when only compilation succeeded.

**Evidence label:** exact classical compilation. The source shown above compiles into the stated canonical artifact under the
current stage-0 profile.
