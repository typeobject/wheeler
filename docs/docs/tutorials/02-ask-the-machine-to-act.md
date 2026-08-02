---
sidebar_position: 3
title: Two Signals
description: A departure handshake reduces a larger physical system to two values and two complete operations.
tutorial_id: CH02
tutorial_steps: T08,T09,T10,T11,T12,T13
tutorial_part: finite-state
tutorial_order: 2
tutorial_kind: exact-and-conceptual-sequence
tutorial_source: primary-fence
tutorial_expectation: two-state-transition
tutorial_evidence: exact-classical-execution
---

# Two Signals

Behind them, the station spoke to departing vessels in pulses of microwave light. Each pulse crossed the widening distance in
vacuum, reached *Vela*'s receiver as an analog disturbance, and passed through enough hardware to become a number on Mara's
console.

For the departure handshake, only two numbers were admitted.

```text
0  request absent
1  request present
```

Calling the signal two-state did not reduce the receiver to two physical conditions. Its antenna warmed. Amplifiers introduced
noise. Threshold circuits occupied voltages between their nominal levels. The protocol ignored those details after they had done
their work, preserving one distinction needed by the next layer.

Mara waited for `1`, acknowledged it, then watched the station return to `0`. The exchange was routine, though the manual had
marked the two values as unfinished business.

Tala opened the accompanying source.

```java
classical class OneBit {
  state long bit = 0;

  entry void main() {
    assert(bit == 0);
    bit = 1;
    assert(bit == 1);
  }
}
```

Although the underlying `long` type could represent many whole numbers, this model admitted only `{0, 1}`, with assertions guarding
the two points visited during the run. That narrower contract, not the storage capacity of `long`, made the location a **bit**.

Tala compiled the source and executed its artifact.

```text
wrote .../build/tutorial/OneBit.wbc (480 bytes)
OneBit (classical) halted after 5 steps
bit = 1
```

One path, `0 -> 1`, followed from the report. Sana accepted the run and rejected Tala's first summary of it.

"The bit can change from zero to one," Tala had written.

"This bit did," Sana said. "A claim about the operation needs every allowed input."

There were only two, which made completeness possible without statistics or faith. Tala wrote them as rows.

| Input | Output |
| --- | --- |
| `0` | `1` |
| `1` | unknown |

Without the missing row, the table did not describe an operation over the complete two-state set, only one
observed transition. Had the input begun at `1`, an assignment to `1` would have produced `1 -> 1`, not the complementary change
Mara associated with a signal flip.

Osei joined them at the chart table while the station receded into the traffic behind. He drew two dots, labeled them `0` and `1`,
and asked for the least eventful operation possible. Tala connected each dot to itself.

| Input | Output |
| --- | --- |
| `0` | `0` |
| `1` | `1` |

Under the **identity operation**, either allowed input remained itself. Deliberately doing nothing to the bit still defined a
complete mapping, which mattered because an unchanged endpoint did not prove that no surrounding work had occurred.

Mara added a second table from the departure protocol.

| Input | Output |
| --- | --- |
| `0` | `1` |
| `1` | `0` |

This was the **flip operation**: not a single assignment to `1`, but a rule that exchanged both allowed states. Every input had one
output, and the two output rows remained distinct.

Tala drew the same rule as arrows.

```text
0 -> 1
1 -> 0
```

Tables and arrows described one finite mapping in different forms. The table made completeness easy to inspect. The arrows made
composition easier to follow.

Osei covered the labels and asked Tala to apply the flip twice. She traced the first input through both copies of the operation,
then repeated the work for the second.

| Input | After first flip | After second flip |
| --- | --- | --- |
| `0` | `1` | `0` |
| `1` | `0` | `1` |

Both inputs returned to their starting values. The composed map matched identity, although each individual flip had changed the
state.

Mara regarded the result with the suspicion pilots reserve for facts that appear obvious only after someone has written them down.
"So it goes there and back."

"For both states in this model," Sana said.

Sana's qualification stayed. Two cases were enough because the allowed set contained exactly two cases. A larger set would require
more rows, and an unbounded set would need a different kind of argument.

Tala wrote *reversible* in the margin, then hesitated. The manual's earlier owners had crossed out the same word in three inks.
Beside it, the most recent hand had left a warning.

```text
Restoring one chosen input is a demonstration.
Defining one output for every input is an operation.
Recovering every input from its output will earn the next word.
```

By then the flip seemed ready to pass that test. Nothing in the chapter had yet shown what failure looked like, and a distinction
learned only from its successful example tends to become praise rather than a rule.

At the edge of the traffic field, *Vela* aligned for the Archive transfer corridor. The habitat identified itself with a stream of
checksummed records and a statement engraved into every public protocol it emitted.

```text
WHAT IS REMEMBERED CAN BE RETURNED
```

Sana read the line without expression. Osei read it twice.

From that claim, the field manual had taken the title of its next chapter: [The Archive](03-one-thing-to-remember.md).
