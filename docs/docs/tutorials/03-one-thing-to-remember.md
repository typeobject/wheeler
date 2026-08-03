---
sidebar_position: 4
title: The Archive
description: A habitat that records every transition reveals why history, rewind, and inverse execution remain different.
tutorial_id: CH03
tutorial_steps: T14,T15,T16,T17,T18,T19,T20,T21,T22,T23
tutorial_part: reversible-foundations
tutorial_order: 3
tutorial_kind: exact-and-rejection-sequence
tutorial_source: primary-fences
tutorial_expectation: reversible-foundation
tutorial_evidence: exact-classical-execution
---

# The Archive

From a distance, the Archive resembled a wheel assembled around an error in the stars. Its inhabited rim shone softly. The central
vault did not shine at all, because heat and light were facts about the present, while the vault had been built to preserve the
past.

Every vessel entering the transfer corridor received a storage allotment before it received docking instructions. *Vela* acquired
forty-eight terabytes for approach telemetry, six for ship state, and one narrow directory in which the port authority invited the
crew to record anything they might later regret losing.

Archive citizens inherited no land. They inherited retention obligations. A family might be responsible for three generations of
water-allocation votes, the maintenance history of a pressure wall, and one ancestor's unedited correspondence. Public schools
taught compression beside handwriting. Weddings merged storage trusts. Funerals began only after the deceased person's keys had
been distributed or destroyed according to a witnessed plan.

Mara declined the invitation. Osei doubled the telemetry checks. Sana stood at the forward lock before the pressure equalized,
watching the inner door as if she knew who would be waiting behind it.

Edrin Saye wore the gray seal of an Archive custodian. Age had narrowed him without making him look fragile. When the door opened,
he greeted Sana first and used the formal version of her name.

"You still keep records," he said.

"I keep distinctions. Records are one way."

His glance moved to the evidence tags on her case. He had trained her to bind a claim to its source before she was old enough to
enter the central vault. She had left after discovering that a perfect source could still support a dishonest sentence when its
scope was trimmed carefully enough. For nine years their messages had remained courteous, complete, and infrequent.

Whatever answer he had expected, hers belonged to that older conversation.

Memory had earned its authority there. A century earlier, during an evacuation, an automated repair system had overwritten the
only state from which its pressure model could be reconstructed. The habitat survived. Twelve workers in a sealed section did not.
Afterward, the custodians recorded every accepted transition in critical systems and built a culture around the proposition that a
retained past could not become an inaccessible one.

Sana had cataloged the evacuation while apprenticed to Edrin. The accepted public history said the damaged section had been
*returned to service*. The phrase was operationally correct and, beside the twelve names, morally grotesque. Edrin had defended
the record because no byte in it was false. Sana had argued that accuracy at the wrong boundary was another way to lose the event.
She left before either of them learned how to retreat.

Nearly true propositions made dangerous foundations, especially when a culture had built upward from them.

Edrin led the crew through a gallery where old machine states moved behind glass in synchronized reconstruction. Broken pumps
unfailed. Valves closed before leaks. A guidance computer backed away from the arithmetic fault that had sent an ore carrier
through a docking mast. Each exhibit consumed stored records in reverse order until the selected earlier state reappeared.

The gallery served as museum, civic shrine, and market. Children sold ceramic orientation birds whose weighted beaks pointed along
the habitat's local gravity. A noodle counter advertised the oldest continuously preserved broth in human space, a claim Sana
could disprove from three meters away. Mara bought one of the birds and refused the broth. Around them, visitors applauded as a
reactor simulation withdrew from a fault it had taken less than a second to enter.

"What is remembered can be returned," Edrin said.

Osei studied the reconstruction controls. "Rewound."

With that single word, a hairline fracture crossed the Archive motto. Edrin heard it and chose not to answer until they reached the
evacuation exhibit.

Behind its glass, the failed pressure system approached the old emergency, stopped, and began consuming its retained transitions in
reverse. Warnings cleared. The damaged section reopened. Twelve names remained fixed across the glass while the machinery withdrew
from the event that had killed them.

Sana looked at Edrin. "That overlay was not here."

"No."

"When?"

"After you left. Before I learned how to tell you."

The change did not repair their argument or return the dead. It prevented the reconstruction from carrying the people backward
with the machine state. Sana read every name. Edrin waited without asking what the revision had earned.

In the verification room, Tala found a two-state example waiting on the terminal. Its operation differed from the flip by one row.

| Input | Output |
| --- | --- |
| `0` | `0` |
| `1` | `0` |

Both arrows met at the same output.

```text
0 -> 0 <- 1
```

If the current state contained only `0`, nothing in that state identified whether the earlier input had been `0` or `1`. An
operation claiming to reconstruct the input would need to choose between two compatible pasts, and either choice would be wrong
for one row.

Zero was not special. Any mapping that merged two allowed inputs into one output discarded the
distinction between them from its declared current state.

Tala entered the operation as an ordinary assignment.

```java
classical class EraseBit {
  state long bit = 1;

  entry void main() {
    bit = 0;
    assert(bit == 0);
  }
}
```

Execution succeeded. That success meant the assignment had produced its stated endpoint, not that the endpoint retained enough
information to recover what came before it. Mara would have called the operation complete. Osei would have called it unfinished.
Both descriptions depended on the task.

Edrin opened the Archive trace. Beside the current `bit = 0`, the system had retained the earlier value `1`. What the program state
alone could not distinguish, the larger history record still could.

For the two possible inputs, that record prevented the rows from colliding completely.

| Input | Current bit | Retained earlier bit |
| --- | --- | --- |
| `0` | `0` | `0` |
| `1` | `0` | `1` |

A rewind could consume the retained record and restore the earlier program state. The method worked because the Archive had kept
extra information outside the current state, not because `bit = 0` contained a hidden answer.

Sana touched the second column. "If the record is unavailable?"

"Then the state cannot be reconstructed from this transition," Edrin said.

He offered the concession without defensiveness. The Archive motto described an operational policy, not a mathematical property,
and perhaps he had spent the years since Sana's departure learning the value of saying so.

For the field manual, **inverse** named a different object: an operation that, given the output state covered by its contract,
reconstructed the exact corresponding input. No private log from the earlier execution could be assumed. A finite mapping could
have such an inverse only when distinct inputs remained distinct at the output.

By that test, the overwrite failed. Tala asked the Wheeler compiler to treat it as reversible anyway.

```java
classical class RejectedErase {
  state long bit = 1;

  rev void erase() {
    bit = 0;
  }

  entry void main() {
    erase();
  }
}
```

In source, the `rev` modifier requested a generated inverse. Compilation stopped at the assignment.

```text
wheeler: line 4: reversible function contains SET_LOGGED, which has no generated inverse
```

Ordinary execution could log the destructive assignment. A `rev` body could not borrow that log and pretend the assignment had an
inverse. The rejection preserved the distinction Edrin's gallery had made visible: history-backed rewind and inverse execution
might reach the same earlier value in one demonstration, but they obtained it through different information.

Tala returned to the two-state flip. Its complete table had no collision.

| Input | Output |
| --- | --- |
| `0` | `1` |
| `1` | `0` |

Each output identified one input, so the inverse table existed. In this case it happened to equal the forward table. Flipping
again restored either starting value.

Wheeler expressed that operation with XOR by one. Over the allowed two-state set, `bit ^= 1` exchanged `0` and `1` without merging
them.

```java
classical class ReversibleFlip {
  state long bit = 0;

  rev void flip() {
    bit ^= 1;
  }

  entry void main() {
    flip();
    assert(bit == 1);
    reverse flip();
    assert(bit == 0);
  }
}
```

The compiler found enough information in the `rev` body to generate its inverse. The command `reverse flip();` did not restore a
snapshot. It executed new work selected from the inverse of `flip`.

```text
ReversibleFlip (classical) halted after 9 steps
bit = 0
```

At the final zero, the route remained invisible. Source and artifact supplied the missing account: forward flip, checked state
one, inverse flip, checked state zero.

Mara, who had tolerated the gallery with the restlessness of someone surrounded by events traveling in the wrong direction, asked
what happened when a reversible method contained several operations. Osei replaced the one-bit example with two methods whose
order mattered.

```java
classical class ReverseOrder {
  state long value = 0;

  rev void rise() {
    value += 2;
  }

  rev void mask() {
    value ^= 7;
  }

  entry void main() {
    rise();
    mask();
    assert(value == 5);

    reverse {
      rise();
      mask();
    }

    assert(value == 0);
  }
}
```

Forward execution added two, then applied the XOR mask: `0 -> 2 -> 5`. To return, Wheeler inverted the last operation first. The
mask carried `5 -> 2`, after which the inverse of `rise` carried `2 -> 0`. Reversing each operation without reversing their order
would have described a different path.

```text
ReverseOrder (classical) halted after 15 steps
value = 0
```

Composition made the rule unavoidable. If forward work crossed doors A and B in that order, exact return crossed B before A. No
mysticism was involved. The second operation had received the state produced by the first, so its inverse had to surrender that
state before the first inverse could accept it.

Edrin brought up the transfer record *Vela* had come to collect. Its lineage was complete, its digest matched the far-instrument
request, and Archive policy required a commit before release. Commit would establish a horizon in the retained VM history. Earlier
steps would no longer remain available for ordinary rewind through that boundary.

"If commit prevents return," Mara said, "we are back where we began."

"It prevents one kind," Tala said.

For the final distinction, the manual offered another program.

```java
classical class CommittedInverse {
  state long bit = 0;

  rev void flip() {
    bit ^= 1;
  }

  entry void main() {
    flip();
    assert(bit == 1);
    commit();
    reverse flip();
    assert(bit == 0);
  }
}
```

Before the reverse call, commit ended the rewindable history. The generated inverse remained an operation in the artifact, so the
later call could execute as new work.

```text
CommittedInverse (classical) halted after 10 steps
bit = 0
```

Three routes now stood apart. An overwrite could return through retained history while that history survived. A reversible
operation could execute its inverse from the current state. A commit could close the first route without deleting the second.
Equal endpoints did not make the mechanisms interchangeable.

Sana reviewed the transfer lineage beside Edrin. Their disagreement had narrowed from doctrine to fields in a record: which state
was current, which history remained available, which inverse belonged to the artifact, and where commit had established the
horizon. Precision had not made them agree about the Archive. It had made their remaining disagreement small enough to preserve.

Before the final signature, Edrin showed her a newer retention practice. Routine event logs could be compacted after commit, but a
sealed pre-commit manifest preserved the identities and edges from which the compact record had been derived. The bulk history
could close without leaving a summary unable to explain its parents.

"An expensive qualification," he said.

"Only when it prevents salvage."

Mara, hearing her own phrase returned, looked wounded for half a second and then laughed. Edrin did not, but the severity around
his eyes eased. Sana copied the manifest pattern into *Vela*'s mission policy.

Edrin authorized the transfer.

At departure, the habitat streamed *Vela*'s approach history back to the ship as a courtesy. Osei retained the verified digest and
declined the bulk record. Sana sent Edrin one amendment to the evacuation exhibit: *machine state restored, losses unchanged*. He
accepted it into review without a message.

Mara fixed the ceramic bird above her console with removable adhesive, waited until the corridor cleared, then moved the Archive
behind them with one sustained burn. The habitat's dark vault crossed the sun and vanished. For several minutes afterward its
record beacons remained visible, each pulse insisting that an event could outlast the place that emitted it.

Twelve hours later, another signal arrived from beyond the range where a single observation could be mistaken for a pattern. It
contained a sequence of zeros and ones, irregular enough to invite a story and too short to justify one.

The field manual opened at [The Long Count](04-the-long-count.md).
