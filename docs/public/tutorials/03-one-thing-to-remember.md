---
sidebar_position: 4
title: The Archive
description: The Archive remembers everything and discovers that memory is not the same as return.
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

From a distance, the Archive resembled a wheel built around an error in the stars. Its inhabited rim shone softly. The central
vault gave back no light.

Heat belonged to the present. The vault had been built for the past.

Every vessel entering the corridor received storage before docking instructions. The port authority reserved volumes for *Vela*'s
approach, for ship state, and one narrow directory labeled: *anything you may later regret losing*.

"Do they charge for regret above quota?" Mara asked.

Sana was reading the retention terms. "They charge for everything above quota. Regret is merely well indexed."

Archive citizens inherited no land. They inherited the duty to remember. Water votes. The life of a pressure wall. An ancestor's
unedited correspondence, growing less charming with every generation. Schools taught compression beside handwriting. Weddings
merged storage trusts. Funerals waited for the witnessed division, or destruction, of the dead person's keys.

Mara declined the invitation. Osei doubled the telemetry checks. Sana stood at the forward lock before the pressure equalized,
watching the inner door as if she knew who would be waiting behind it.

Tala noticed and performed the polite social maneuver of becoming intensely interested in a pressure gauge.

Edrin Saye wore the gray seal of an Archive custodian. Age had narrowed him without making him look fragile. When the door opened,
he greeted Sana first and used the formal version of her name.

"You still keep records," he said.

"I keep distinctions. Records are one way."

The gauge informed Tala that pressure was equal. It offered no guidance for the next thirty seconds.

His glance moved to the tags on her case. He had taught her, before she was old enough to enter the vault, never to let a claim
wander far from its source. She had later discovered that a perfect source could support a dishonest sentence if someone trimmed
its edges with care.

For nine years their messages had been courteous. Thorough. Rare.

Whatever answer he had expected, hers belonged to that older conversation.

Memory had not become sacred there by accident. A century earlier, during an evacuation, an automated repair system overwrote the
only state from which its pressure model could be rebuilt. The habitat survived. Twelve workers behind a sealed door did not.

Afterward the custodians kept every transition in every critical machine. From catastrophe they made policy. From policy, a
culture.

Sana had cataloged the evacuation as Edrin's apprentice. The public history said the damaged section had been *returned to
service*. Operationally correct. Beside twelve names: grotesque.

Edrin defended the record because no byte in it was false. Sana argued that accuracy drawn around the wrong thing was another kind
of erasure. She left before either of them learned how to retreat.

A nearly true sentence could bear a terrifying amount of weight.

Edrin led the crew through a gallery where old machine states moved behind glass in synchronized reconstruction. Broken pumps
unfailed. Valves closed before leaks. A guidance computer backed away from the arithmetic fault that had sent an ore carrier
through a docking mast. Each exhibit consumed stored records in reverse order until the selected earlier state reappeared.

The gallery was museum, shrine, market. Children sold ceramic birds whose weighted beaks found local down. A noodle counter
advertised the oldest continuously preserved broth in human space, a claim Sana could disprove from across the aisle. Mara bought a
bird and refused the broth.

Around them, visitors applauded while a reactor simulation backed away from a fault it had taken less than a second to enter.

"What is remembered can be returned," Edrin said.

Osei studied the reconstruction controls. "Rewound."

One word. A hairline crack through the Archive motto. Edrin heard it. He waited until the evacuation exhibit to answer.

Behind its glass, the failed pressure system approached the old emergency, stopped, and began consuming its retained transitions in
reverse. Warnings cleared. The damaged section reopened. Twelve names remained fixed across the glass while the machinery withdrew
from the event that had killed them.

Sana looked at Edrin. "That overlay was not here."

"No."

"When?"

"After you left. Before I learned how to tell you."

The change repaired neither their argument nor the dead. It merely refused to drag the people backward with the machinery.

Sana read every name. Edrin asked nothing.

In the verification room, Tala found a two-state example waiting on the terminal. Its operation differed from the flip by one row.

| Input | Output |
| --- | --- |
| `0` | `0` |
| `1` | `0` |

Both arrows met at the same output.

```text
0 -> 0 <- 1
```

At the output, only `0` remained. Had the input been `0` or `1`? The current state could not say. Any attempted reconstruction must
choose one past and thereby be wrong about the other.

Zero held no special power here. Whenever two inputs met at one output, the distinction between them left the state.

Tala entered the operation as an ordinary assignment.

```wheeler
classical class EraseBit {
  state long bit = 1;

  entry void main() {
    bit = 0;
    assert(bit == 0);
  }
}
```

Execution succeeded. Mara nodded. Osei did not.

Tala could translate the silence. The assignment reached the endpoint Mara had asked for: finished. The endpoint could not tell
Osei where it came from: unfinished.

Same line of code. Different responsibility. Neither of them enjoyed the other's correctness.

Edrin opened the Archive trace. Beside the current `bit = 0`, the system had retained the earlier value `1`. What the program state
alone could not distinguish, the larger history record still could.

The current-bit column collided. Add the saved input and the rows separated again.

| Input | Current bit | Retained earlier bit |
| --- | --- | --- |
| `0` | `0` | `0` |
| `1` | `0` | `1` |

A rewind could spend the saved row and restore the earlier value. The answer lived in the Archive's history, not, secretly, inside
`bit = 0`.

Sana touched the second column. "If the record is unavailable?"

"Then the state cannot be reconstructed from this transition," Edrin said.

He conceded the point without defense. The Archive motto named a policy, not a law of mathematics. Perhaps the years since Sana
left had taught him the mercy of saying less.

The field manual reserved **inverse** for something stricter: an operation that could take an output and recover its corresponding
input without consulting a private history. Such an inverse existed only when different inputs stayed different at the end.

By that test, the overwrite failed. Tala asked the Wheeler compiler to treat it as reversible anyway.

```wheeler
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

"Concise," Mara said.

"Hostile," Osei said.

"Correct," Sana said.

Ordinary execution could remember the destructive assignment. A `rev` body could not borrow that memory and call itself
invertible. The compiler's refusal preserved what Edrin's gallery had revealed: rewind and inverse execution might arrive at the
same earlier value, but they paid for the journey with different information.

Tala returned to the two-state flip. Its rows did not collide.

| Input | Output |
| --- | --- |
| `0` | `1` |
| `1` | `0` |

Each output identified one input, so the inverse table existed. In this case it happened to equal the forward table. Flipping
again restored either starting value.

Wheeler expressed that operation with XOR by one. Over the allowed two-state set, `bit ^= 1` exchanged `0` and `1` without merging
them.

```wheeler
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

Here the compiler could build the inverse. `reverse flip();` restored no snapshot. It performed new work, following `flip` the
other way.

```text
ReversibleFlip (classical) halted after 9 steps
bit = 0
```

The final zero concealed the route. The program supplied it: forward to one. Backward to zero.

Mara, who had tolerated the gallery with the restlessness of someone surrounded by events traveling in the wrong direction, asked
what happened when a reversible method contained several operations. Osei replaced the one-bit example with two methods whose
order mattered.

```wheeler
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

The order was unavoidable. Cross doors A, then B. To leave, cross B, then A. Nothing mystical. The second operation held the state
the first inverse would need, and had to give it back first.

Edrin opened the transfer *Vela* had come to collect. Its trail was intact. Its digest matched the far instrument's request.
Archive policy required a commit before release. Beyond that horizon, ordinary rewind could not go.

"If commit prevents return," Mara said, "we are back where we began."

"It prevents one kind," Tala said.

Mara pointed at her. "That sentence is why you and Sana should not be allowed to form a committee."

"Committees retain minutes," Sana said. "They rarely generate inverses."

For the final distinction, the manual offered another program.

```wheeler
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

The paths had separated. An overwrite might be rewound while history survived. A reversible operation could walk its own inverse.
Commit could close the first path and leave the second open.

Same destination. Different road. Different price.

Sana reviewed the transfer beside Edrin. Their old argument narrowed from doctrine to particulars: what was current, what history
remained, which inverse belonged to the program, where commit had closed the past.

Precision did not make them agree about the Archive. It made the disagreement small enough to keep.

Before signing, Edrin showed her a newer practice. Routine logs could be compressed after commit, but a sealed manifest kept the
parentage of the surviving record. The bulk might close. The summary would not become an orphan.

"An expensive qualification," he said.

"Only when it prevents salvage."

Mara, hearing her own phrase returned, looked wounded for half a second and then laughed. Edrin did not, but the severity around
his eyes eased. Sana copied the manifest pattern into *Vela*'s mission policy.

Edrin authorized the transfer.

At departure, the habitat offered *Vela* her whole approach history as a courtesy. Osei kept the digest and declined the weight.
Sana sent Edrin one amendment to the evacuation exhibit: *machine state restored. Losses unchanged*.

He accepted it for review. No message.

Mara fixed the ceramic bird above her console, waited for the corridor to clear, then put the Archive behind them with one sustained
burn. The dark vault crossed the sun. Vanished.

Its beacons continued for several minutes: pulse after pulse, an event outliving the place that sent it.

Twelve hours later, another signal arrived from beyond the range where a single observation could be mistaken for a pattern. It
contained a sequence of zeros and ones, irregular enough to invite a story and too short to justify one.

The field manual opened at [Long Count](04-long-count.md).
