---
sidebar_position: 4
title: The Archive
description: In the Black Vault, retained history, generated inverse, and twelve names force the Archive to narrow its motto.
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

The Archive's dock curved upward beyond *Vela*'s bridge glass. As the ship matched
the inhabited rim, doors and signal lamps climbed the wheel until another berth
hung above them like a ceiling. Farther inward, the Black Vault occupied the hub
as a perfect absence in the stars.

People and waste heat lit the rim. The vault returned no light.

Whatever remained warm was current. The cold mass existed for earlier things.

The dock wall carried six rival charter seals beneath the Archive's gray mark.
Their owners had trusted a neutral vault before they trusted one another. By the
time the companies vanished in the Withdrawal, cargo titles and engineering
debts were still legible here. The keeper of their ledgers had become the court
that interpreted them.

A storage offer reached *Vela* before docking instructions. The Archive reserved
volumes for approach telemetry and current ship state, plus a narrow directory
titled *material regret may make valuable*.

"Does regret have an excess rate?" Mara asked.

Sana continued through the terms. "Everything has an excess rate. Regret receives superior indexing."

Through the lock port, Tala watched an Archive family gathered at a key desk.
Two children held storage wafers while an elder and a gray-sealed witness divided
access between them. A funeral notice on the wall listed the keys that would be
destroyed at the next watch. Here inheritance meant responsibility for water
votes, pressure-wall inspections, and correspondence the dead had left
inconveniently complete.

Mara rejected the regret directory. Osei duplicated the approach telemetry anyway. Sana reached the lock before equalization and
watched the inner door with the patience of someone awaiting a known difficulty.

Tala granted her privacy by studying the pressure gauge far beyond its educational value.

The inner door revealed Edrin Saye in a custodian's gray seal. Time had pared him down and left his bearing intact. He gave Sana her
formal name before greeting the rest of the crew.

"You continued keeping records."

"I continued keeping distinctions. Records sometimes survive them."

Pressure reached equality. Tala's chosen instrument had nothing further to contribute.

Edrin read the paper tags on Sana's case without touching them. Tala had seen his
hand in their shape: every statement tethered to a source, every uncertain date
left uncertain. Sana had learned that discipline from him before either of them
was old enough to hold their present silence.

They left the dock together. Edrin took the inward corridor, and the curve of the
wheel carried the Black Vault from the floor-side windows toward the wall. Neither
he nor Sana mentioned the nine years of careful messages between them.

The route to verification crossed a public gallery of reconstructed machine histories. Behind glass, pumps withdrew from failure
and valves closed ahead of old leaks. An ore carrier's guidance system backed through the arithmetic that had driven it into a
mast. Each display consumed retained transitions from newest to oldest until a selected state returned.

School groups shared the gallery with pilgrims and lunch traffic. Children sold ceramic birds weighted to find local down. A noodle
stall claimed the oldest continuously maintained broth in human space; Sana identified two breaks in its lineage before they
crossed the aisle. Mara purchased a bird and declined the food.

Visitors applauded a reactor simulation that spent several minutes retreating from a subsecond fault.

Edrin recited the public motto. "What is remembered can be returned."

Osei examined the history counter. "What is remembered can be rewound."

The additional word narrowed the claim. Edrin carried the correction in silence
to the gallery's inward end, where a dark window looked across at the vault.
Beside it stood the evacuation reconstruction.

Its first panel told Tala what the Archive had built its doctrine around. A
century earlier, automated repair had overwritten the pressure system's sole recoverable
configuration. The surrounding habitat survived. Twelve workers died behind a
sealed door. Afterward, custodians began retaining every
transition of critical machinery.

Sana stopped before the public conclusion: *damaged section returned to service*.
She had cataloged those words as Edrin's apprentice and left the Archive after he
defended their byte-level accuracy. Twelve names now stood directly beneath the
sentence.

The reconstruction advanced to the old emergency and stopped. Retained
transitions vanished in reverse order. Alarms cleared and the damaged section
opened. The twelve names held their places while machine state traveled away from
their deaths.

Sana faced her teacher. "You added the names."

"Yes."

"When did you change it?"

"After your departure. Before I found words that did not ask you to forgive it."

The overlay restored no person and settled no doctrine. It allowed the machine to rewind without making the dead appear to follow.

Sana remained until she had read all twelve. Edrin let the silence belong to her.

A terminal in the verification room held another two-state mapping. One row separated it from the flip.

| Input | Output |
| --- | --- |
| `0` | `0` |
| `1` | `0` |

Its arrows converged on a single destination.

```text
0 -> 0 <- 1
```

The result exposed only `0`. Current state no longer distinguished an input of `0` from an input of `1`. Reconstruction from that
state would have to invent which past had occurred.

The collision, rather than the value zero, caused the loss. Any mapping that joined separate inputs discarded their distinction
from current state.

Tala wrote the collision as an ordinary assignment.

```wheeler
classical class EraseBit {
  state long bit = 1;

  entry void main() {
    bit = 0;
    assert(bit == 0);
  }
}
```

The run halted successfully. Mara nodded at the final zero. Osei traced the two
converging arrows with one finger and stopped where they met.

Tala could account for both reactions. Mara had received the requested endpoint.
Osei had received a state incapable of naming its own origin.

One line of code carried two responsibilities. Mara needed its successful
endpoint; Osei needed a road back from it. Neither enjoyed the other's
correctness.

Edrin opened the execution trace. The Archive had stored the former value `1` beside current `bit = 0`. Program state had lost the
distinction; retained history carried it elsewhere.

Current values collided in one column. The history column separated the rows.

| Input | Current bit | Retained earlier bit |
| --- | --- | --- |
| `0` | `0` | `0` |
| `1` | `0` | `1` |

Rewind could consume that retained entry and rebuild the earlier value. Its information came openly from history. Nothing inside
`bit = 0` secretly remembered the input.

Sana indicated the retained value. "Remove this record."

"Then this transition provides no reconstruction from current state," Edrin answered.

He offered no defense. The motto expressed Archive policy rather than mathematics. Tala wondered how many years it had taken Edrin
to let a qualification stand on its own.

The Common Book reserved **inverse** for something stricter: an operation that could take an output and recover its corresponding
input without consulting a private history. Such an inverse existed only when different inputs stayed different at the end.

The overwrite failed the stricter rule. Tala declared it reversible to see where the compiler would object.

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

The `rev` modifier requested generated inverse execution. The compiler reached the destructive assignment and refused the body.

```text
wheeler: line 4: reversible function contains SET_LOGGED, which has no generated inverse
```

"Short answer," Mara said.

"Useful answer," Osei said.

"Accurate answer," Sana said.

Ordinary execution could remember the destructive assignment. A `rev` body could
not borrow that memory and call itself invertible. The compiler's refusal
preserved what Edrin's gallery had revealed: rewind and inverse execution might both recover an earlier value while drawing
information from separate sources.

The original flip supplied a mapping without collisions.

| Input | Output |
| --- | --- |
| `0` | `1` |
| `1` | `0` |

Every output identified its source, allowing an inverse table. For the two-state flip, inverse and forward tables were identical.
A second application recovered either input.

Wheeler used XOR by one for that exchange. Across the admitted states, `bit ^= 1` sent `0` to `1` and `1` to `0` while preserving
the distinction.

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

The compiler generated an inverse for this body. Calling `reverse flip();` consulted no snapshot. Execution performed the inverse
operation as fresh work.

```text
ReversibleFlip (classical) halted after 9 steps
bit = 0
```

Final state alone showed zero. Source and run together showed the outward transition to one and inverse work back to zero.

Mara had grown visibly impatient with a gallery full of backward events. She asked how inverse execution handled a body with more
than one operation. Osei answered with two reversible methods whose order changed the result.

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

Forward work added two and then applied the XOR mask, following `0 -> 2 -> 5`. Inverse work began with the most recent operation:
the mask returned `5 -> 2`, then inverse `rise` returned `2 -> 0`. Inverting operations while preserving their forward order would
follow another mapping.

```text
ReverseOrder (classical) halted after 15 steps
value = 0
```

A person crossing doors A and B must encounter B first on the way out. Composition imposed the same order. The later operation had
to release the state needed by the earlier inverse.

Edrin opened *Vela*'s requested transfer. Its lineage reached the source, and its digest matched Sable's request. Archive release
required commit, which placed the prior execution history beyond ordinary rewind.

"Commit closes the way back," Mara said. "That sounds familiar."

"It closes rewind," Tala answered. "The inverse remains."

Mara pointed between Tala and Sana. "Catenary must never put both of you on one naming council."

"Councils retain proceedings," Sana said. "Their reversibility remains unproved."

The Common Book placed commit and inverse execution in one final source.

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

Commit closed retained VM history before the reverse call. The artifact still contained the generated inverse, allowing later
execution to perform that operation anew.

```text
CommittedInverse (classical) halted after 10 steps
bit = 0
```

Rewind depended on surviving history and could recover a destructive overwrite. Inverse execution depended on an invertible
operation. Commit ended the history road while leaving the generated operation available.

The paths converged at zero after following different roads and paying different
prices.

Sana reviewed the transfer beside Edrin. The Covenant had made the Archive
necessary after distant owners withdrew; it had never settled how much truth a
neutral keeper owed the dead. Their old argument narrowed from doctrine to
particulars: what was current, what history remained, which inverse belonged to
the program, where commit had closed the past.

Their new vocabulary left Sana and Edrin in disagreement, though each could now identify its border.

Before Sana signed, Edrin demonstrated a newer retention practice. Commit permitted compression of routine logs, while a sealed
manifest preserved the surviving record's parentage. Storage could shrink without severing the summary from its origin.

"Your narrower sentence costs storage," Edrin said.

"The cost is lower than salvaging the wrong thing," Sana replied.

Mara recognized Sana's answer from the chart table, performed an injury for half
a second, and laughed. Edrin's expression remained severe while the skin around his eyes
eased. Sana copied the manifest pattern into *Vela*'s mission policy.

Edrin released the transfer to *Vela*.

Archive traffic offered *Vela* a complete copy of her approach history. Osei retained its digest and declined the additional mass.
Before undocking, Sana submitted an amendment to the evacuation exhibit: *machine state restored. Losses unchanged*.

Edrin marked the amendment for review and sent no private words.

Mara mounted the ceramic bird above her console. When the corridor cleared, one sustained burn carried the Black Vault across the
sun until darkness swallowed darkness.

Archive beacons continued after the wheel left sight, each pulse surviving its visible source.

Twelve hours outward, a distant source sent thirty-two zeros and ones. The irregular sequence invited interpretation before its
size had earned one.

Tala turned its next worn leaf to [Long Count](04-long-count.md).
