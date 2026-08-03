---
sidebar_position: 2
title: Departure
description: An empty program grows into the checked state transition that releases Vela from her berth.
tutorial_id: CH01
tutorial_steps: T01,T02,T03,T04,T05,T06,T07
tutorial_part: ordinary-state
tutorial_order: 1
tutorial_kind: exact-execution-sequence
tutorial_source: primary-fences
tutorial_expectation: departure-state
tutorial_evidence: exact-classical-execution
---

# Departure

Thirty-seven days before the failed return, *Vela* waited in her construction berth with most of her hull closed and several
important disagreements still exposed.

Mara met Tala at the service lock. The pilot's welcome consisted of a pressure check and a brisk inventory of exits, after which
she introduced the ship in the order she expected to need it: attitude, drive, navigation, power, air. Coffee entered the list
between power and air, then moved upward when Tala asked whether the galley unit worked.

By profession Tala was a systems analyst. She had spent seven years tracing failures through municipal transit software, where
vehicles remained on the ground and most state could be copied without consulting the laws of physics. The far-instrument mission
had hired her for that experience, not because it was sufficient, and Osei made the distinction during their first conversation.

He was waiting in the machine room beside an open rack. Instead of a greeting, he handed her a field manual bound in gray cloth.

"Read the annotations before the printed text," he said. "The text was approved."

On the oldest title page, no author appeared. Sana had attached a provenance slip containing eight probable owners, three
impossible dates, and a note that the binding adhesive matched a repair shop on Selene. Beneath the slip, a handwritten
instruction survived in faded blue ink.

```text
Begin with a program that has nowhere to go.
```

Tala opened the Wheeler workspace at the terminal built into the rack and created a directory for the manual's programs.

```bash
mkdir -p tutorial
```

For the first exercise, the manual supplied `tutorial/Wake.w` and a complete source small enough to look less like a program
than the space reserved for one.

```java
classical class Wake {
  entry void main() {
  }
}
```

Authored text came first. In Wheeler, as in the transit systems Tala knew, a **source file** described the program before a compiler
translated it into an executable artifact. The distinction mattered because changing the source did not reach backward through
time and alter an artifact already produced from earlier bytes.

She invoked the compiler from the repository root.

```bash
wheeler compile tutorial/Wake.w -o tutorial/Wake.wbc
```

The compiler reported its output.

```text
wrote tutorial/Wake.wbc
```

Inside `Wake.wbc`, canonical Wheeler bytecode formed the **artifact**. Compilation had checked the source rules and translated the
program. It had not executed the empty body, a point the manual emphasized with a margin note written by someone who pressed hard
enough to score the next three leaves.

```text
A compiled promise remains a promise.
```

Execution required another boundary and another command.

```bash
wheeler run tutorial/Wake.wbc
```

After verifying the artifact, the runtime entered `main`, found no body instruction, and halted.

```text
Wake (classical) halted after 1 steps
```

One entry transition. No declared state. No value to report. The run had done almost nothing, which left little room to disagree
about what it had done.

Sana arrived while Tala was comparing the source and artifact digests. She requested both for the mission record, along with the
compiler profile and run report. When Tala asked whether an empty program deserved so much lineage, Sana looked through the rack
toward the unfinished ship.

"The inexpensive records establish whether the expensive ones can be trusted."

Beneath that note, the next annotation added a state declaration.

```java
classical class FirstSignal {
  state long lamp = 0;

  entry void main() {
  }
}
```

Here `lamp` named a **state value** owned by the program, while `0` supplied its initial value. The empty entry changed nothing, so
an exact run ended where the declaration began.

```text
FirstSignal (classical) halted after 1 steps
lamp = 0
```

At that moment Mara entered the machine room carrying a physical readiness lamp removed from the flight deck. Its lens was dark.
She set it beside the terminal, where it acquired more presence than the number on the screen.

"Zero is accurate," Tala said.

"Accuracy has stages," Mara replied. "Make it ready."

An assignment inside `main` replaced the current program value. Tala renamed the small experiment and kept every other change
visible in one complete source.

```java
classical class CabinLamp {
  state long lamp = 0;

  entry void main() {
    lamp = 1;
  }
}
```

Now the state path had direction: `0 -> 1`. The single `=` changed a value rather than comparing two values, and the runtime's
final report reflected the transition.

```text
CabinLamp (classical) halted after 3 steps
lamp = 1
```

Mara reinstalled the physical lamp without suggesting that the Wheeler value had touched it. The program modeled one condition.
The hardware remained a larger system with power, wiring, control logic, and a lens that had collected a crescent of dust along its
lower edge.

Osei took her place at the console. One transition, he said, concealed the question that mattered to him. He added a second
assignment to a state named `signal`.

```java
signal = 1;
signal = 2;
```

From an initial `0`, execution followed `0 -> 1 -> 2`. Reversing the two source lines produced `0 -> 2 -> 1`. The statements were
not an unordered collection of intentions. **Source order** selected a path, even when only the endpoint appeared in the final
state report.

Sana, reading over his shoulder, objected to the path existing only in their explanation. A later edit could change the assignment
while leaving the explanation intact, a form of durability the archive profession had learned to distrust. She placed an
executable expectation after the transition.

```java
assert(signal == 2);
```

Unlike the assignment's single `=`, the doubled `==` compared the current value with `2`. `assert` required that comparison to
hold at that position in the run. If it held, execution continued. If it failed, the runtime trapped instead of publishing an
ordinary successful halt.

A passing assertion did not prove the program correct for every input, artifact, or target. It supported a smaller claim about one
specified point in one execution. Its modesty appealed to Sana more than a broad promise would have.

By the end of the shift, the examples had converged on the departure interlock Mara actually needed reviewed. Tala gave the known
sequence a method name, `depart`, then called that method from `main`. A method collected instructions into a named body. A method
call transferred control into that body and resumed after the call when the body finished.

In the manual's margin, the word *return* appeared beside its first correction.

```text
Control returns to the caller.
State has not thereby returned to an earlier value.
```

One screen held the complete program.

```java
classical class FirstWatch {
  state long berth = 1;
  state long drive = 0;

  void depart() {
    berth = 0;
    drive = 1;
  }

  entry void main() {
    depart();
    assert(berth == 0);
    assert(drive == 1);
  }
}
```

Before execution, Tala traced both values. `berth` would follow `1 -> 0`. `drive` would follow `0 -> 1`. The call would finish
before either assertion examined the state.

She compiled the displayed source into its canonical artifact and ran it.

```text
FirstWatch (classical) halted after 9 steps
drive = 1
berth = 0
```

Canonical output order placed `drive` before `berth`, though the names preserved which value belonged to which location. Both
assertions had succeeded. The run therefore supported the bounded claim Sana attached to the departure record: this artifact,
under this runtime profile, finished with the modeled berth released and drive enabled.

Mara waited for the record identity and Osei's review before enabling the physical sequence. She did not mistake caution for doubt.
A pilot trusted systems by knowing the limits of what they had established.

Without ceremony, the clamps opened. Metal that had carried *Vela*'s weight for nine months withdrew into the berth, and the ship
moved under attitude control into the dark between structures. Tala watched the yard rotate out of the forward windows. On the
communications panel, the station reduced their departure to a pair of values repeated in alternation.

Its next chapter bore the same spare title: [Two Signals](02-ask-the-machine-to-act.md).
