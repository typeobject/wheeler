---
sidebar_position: 3
title: Two Signals
description: Catenary's departure signals lead from a complete two-state world toward the Archive's dangerous promise.
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

The first outbound meal collected at the chart table one hatch aft of the
bridge. Tala could see Mara's shoulders through the open hatch and, beyond them,
Catenary shrinking behind the ship.

The habitat had already receded into microwave speech. Its wheels shared official
languages while keeping local accents, work whistles, and market codes. Traffic
separation admitted a smaller vocabulary.

Each pulse reached *Vela* as a faint analog disturbance. Receivers and threshold circuits worked through the noise until Mara's
console could display one integer.

Every class of vessel left Catenary on its own scale. Ore hulls planned a berth days ahead. Passenger needles burned hard enough to
justify their fares. Moving family habitats eased away while their gardens slowly learned a new direction for sunlight.

The traffic protocol asked each of them for the same pair of answers.

One flotilla vessel carried a white thorn painted across its radiator spine. Mara
magnified it until individual repair patches became visible. The mark had begun
during the Withdrawal as a warning that an abandoned charter vessel remained
inhabited and under mutual protection. Crews later placed their ships in family
and labor trusts, and the warning became a compact.

Mara had grown up among the Thorn Families, whose addresses named a vessel, a
pressure section, and the next three planned transfers. In that childhood, home
had never meant a fixed place. It meant that the pilot had matched velocity well
enough for two locks to meet.

She had learned docking aboard the vessel on the display. Its traffic packet
included the compact's ordinary invitation.

```text
BERTH OPEN THROUGH NEXT TRANSFER
```

The words required no confession of longing and made no promise beyond geometry.
Catenary was the first address Mara had held that remained valid while she
traveled. She copied its coordinates into a reply, left the message unsent, and
restored the traffic plot to its useful scale.

The departure handshake permitted two numbers.

```text
0  request absent
1  request present
```

*Two-state* did not mean the receiver possessed only two physical conditions. The antenna warmed. Amplifiers added noise.
Threshold circuits wandered through voltages between their named levels. Once those details had done their work, the protocol let
them fall away. It kept one distinction: absent, present.

Mara received `1`, sent her answer, and watched Catenary settle to `0`. The exchange carried separation authority while private
channels carried everything else. Two former colleagues had written Tala. Mara's queue belonged mostly to vendors collecting their
accounts before vacuum weakened the obligation.

When Sana noticed the queue, Mara hid it. "Approach hazards."

"Do your creditors operate tugs?"

"Two feed tug crews. Access may be negotiable."

One Sable packet waited for Osei. The cooperative addressed him as a member in arrears and placed a private sentence below the
bearing-maintenance ballot.

```text
The west bearing outlasted your estimate.
It did not outlast the mission.
Iona
```

Osei retained the packet and left its reply empty.

In the gray book, an earlier crew had circled the traffic pair and written *unfinished*.

Tala called up the source bound to that note.

```wheeler
classical class OneBit {
  state long bit = 0;

  entry void main() {
    assert(bit == 0);
    bit = 1;
    assert(bit == 1);
  }
}
```

The `long` type admitted many whole numbers, though this model confined the value to `{0, 1}` and checked both positions. That
restricted state space made `bit` a **bit**; the wide container did not.

She compiled the file and ran the resulting artifact.

```text
OneBit (classical) halted after 5 steps
bit = 1
```

One path appeared in the account: `0 -> 1`. Tala described it as *the bit can change from zero to one* and believed she had kept the
sentence narrow.

Sana found room inside it.

"This execution changed it," Sana said. "An operation has to answer for every admitted input."

"The world has two states."

"Then we can afford the entire world."

Two inputs made completeness affordable. Tala could draw every row and leave
neither statistics nor faith to fill a missing case.

| Input | Output |
| --- | --- |
| `0` | `1` |
| `1` | unknown |

Without the second row, they had one witnessed transition rather than a complete operation. Starting the assignment at `1` would
leave it at `1`; Mara's intended flip required an exchange.

Osei brought the question to the chart table, the only flat place not currently claimed by meals. A dismantled fan impeller lay
beside Catenary's diminishing plot. *Vela* gave abstract work whatever surface maintenance could spare.

He marked dots `0` and `1`, then asked Tala to draw an operation with no change. She returned each dot to itself.

| Input | Output |
| --- | --- |
| `0` | `0` |
| `1` | `1` |

The table defined the **identity operation**. Either input remained itself. Deliberate inaction was still a whole mapping. An unchanged end
never proved that nothing had happened around it.

Mara laid the traffic flip beside it.

| Input | Output |
| --- | --- |
| `0` | `1` |
| `1` | `0` |

The second table defined the **flip operation**: an exchange rather than an assignment to `1`. Each input had one destination. The destinations did not
collide.

Tala translated that table into arrows.

```text
0 -> 1
1 -> 0
```

Both forms described one mapping. Rows revealed completeness; arrows revealed composition.

Osei hid the final column and placed two flips in sequence. Tala followed `0` through both, then began again from `1`.

| Input | After first flip | After second flip |
| --- | --- | --- |
| `0` | `1` | `0` |
| `1` | `0` | `1` |

Every admitted input returned to its origin. The two flips composed to identity.

Mara studied the rows as if their obviousness were a navigational trick. "There. Then home."

"Across this complete two-state model," Sana answered.

"Is every extra phrase billable?"

"When the extra words keep someone from salvaging the wrong thing."

"The Archive must have celebrated your departure."

Sana attached the table to the account. "Celebration was not recorded."

Mara fitted the fan impeller together and watched Catenary lose another band of light.

The qualification remained in the account. Two rows exhausted a two-state world. Finite worlds grew more expensive with size;
infinite ones required reasoning beyond enumeration.

Tala began to write *reversible*. Three former hands had already written and struck out the word. The newest correction pointed her
to a stricter test.

```text
Restoring one chosen input is a demonstration.
Defining one output for every input is an operation.
Recovering every input from its output will earn the next word.
```

The flip appeared to satisfy it. Tala had seen enough green displays to distrust a rule demonstrated only by success.

Catenary disappeared during the third passage sleep. Two watches later, the first
Archive buoy entered the forward plot and *Vela* turned into the old corridor.

Each buoy carried the newest correction in case its neighbors failed. Beneath the
current traffic code, their identity plates still bore rival charter seals.
Supply ships had followed this route when the outer settlements were pressure
tents and a message could arrive before the sender's legal identity. Those rivals
had trusted their titles to the Black Vault because none would trust a
competitor's memory.

The Archive's law reached them hours before its inhabited wheel. Checksums crossed the receiver, followed by the sentence stamped
into every public exchange.

```text
WHAT IS REMEMBERED CAN BE RETURNED
```

Sana's thumb pressed the hidden inscription of her seal. Her face gave Tala no interpretation. Osei read the motto, paused, and
read it again.

The gray book preserved the same words above its next account: [The Archive](03-one-thing-to-remember.md).
