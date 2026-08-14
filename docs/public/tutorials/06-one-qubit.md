---
sidebar_position: 7
title: One Qubit
description: At Sable, one small physical system opens a larger world of amplitude, phase, and interference.
tutorial_id: CH06
tutorial_steps: T36,T37,T38,T39,T40,T41,T42,T43,T44,T45,T46,T47,T48,T49,T50
tutorial_part: one-qubit
tutorial_order: 6
tutorial_kind: intended-quantum-sequence
tutorial_source: intended-primary-fences
tutorial_expectation: one-qubit-model
tutorial_evidence: ideal-model-and-intended-seeded-samples
---

# One Qubit

Below *Vela*, the far instrument turned like dark glass in Sable's orbit. The captured moon rolled beneath it without the courteous
regularity of a native satellite. No habitation ring softened the station. Its spin section hid in shield-shadow. Laboratories
stood far apart on trusses, so one failed refrigerator could not warm the next.

Five people lived there. Mushrooms grew along the warm return lines. Once a month they voted on which delayed broadcasts deserved
the bandwidth. A bad year was measured in parts machined from other parts.

Personal messages shared a channel with target telemetry. Drinking water appeared in the same accounts as the vacuum pumps.

The station prepared small physical systems, worked upon them with controlled fields, and measured what came out. Catenary needed
the comparison to distinguish drifting beacons from the charged weather moving toward the inner orbits. That need, not the machine's
elegance, had carried *Vela* across the reach.

Iona met the crew at the inner lock. She wore no uniform, only a gray work coat with conductive thread bright at the cuffs, and
looked first at the record case in Sana's hand.

"The Archive signed it?"

"The Archive recorded it," Sana said.

"Better. Signatures make them sentimental."

Something in Iona's face eased. During the instrument's first winter, a corrupt manifest had delivered thousands of fasteners in
the wrong alloy and a beautifully signed explanation. She and Sana had corresponded ever since, mostly through questions attached
to rejected paperwork.

Only then did she look at Osei. He opened a padded case: two bearing sensors, one for the mounting he remembered, one for the
revision installed after he left. Mara had surrendered cargo mass for both and had not suffered in silence.

Iona selected the revised part. "You checked."

"Eventually."

"He brought both," Mara said. "Eventually weighed four kilograms."

The sensor would keep the west bearing within its safe range. It would not give the outbound laser its old precision. That needed a
new race, a cargo berth, a long shutdown, none available now.

Radio would carry summaries. *Vela* would carry the weight.

Iona's thumb remained against the sealed case for a moment before she passed it to a technician. No embrace would have told Tala as
much about the years between them.

Iona led them down a corridor where *down* moved gently beneath their feet. Frost feathered one wall behind a warning grid. At the
laboratory they changed into clean layers and passed through fields that stripped away the dust Sable raised even in vacuum.

One shielded device stood at the center of an empty room. Mara asked what the empty floor had cost. Iona told her. The architecture
received no further review.

Before touching the chamber, Iona opened its ideal simulator. Both accepted the same Wheeler operations. Only one forgave mistakes
for free.

The modeled system offered two distinguished outcomes, labeled `0` and `1`. Together they formed the **computational basis**. As
quantum states rather than ordinary integers, they were written `|0>` and `|1>`.

The vertical line and angle bracket formed a *ket*. `|0>` was read "ket zero." The notation named a state. No tiny numeral lived
inside the device.

Wheeler represented the system with one quantum register.

```wheeler
quantum class KnownZero {
  state long measured = 0;
  qreg q = new qreg(1);

  entry void main() {
    prepare(q, 0);
    measured = measure(q);
    assert(measured == 0);
  }
}
```

`qreg q = new qreg(1)` made room for one qubit. `prepare(q, 0)` placed it in the known state `|0>`. Measurement ended with a
classical outcome stored in `measured`.

```text
KnownZero (quantum) halted after 4 steps
measured = 0
measurements = [0]
```

One run. One outcome. The simulator offered no fanfare. A green border appeared around the report. Across the room, the physical
chamber continued its expensive hum, innocent of participation.

"Most expensive room I have ever used to run software," Mara said.

"You did not use the room," Iona replied.

"That has not reduced its cost."

A fresh preparation, its operations, and one measurement made a **shot**. Iona requested 256. Each began again. Re-reading one
already measured qubit would have been a different experiment entirely.

```bash
wheeler run manual/KnownZero.wbc \
  --target ideal \
  --shots 256 \
  --seed 271828
```

```text
0 | ################################################################ 256
1 |                                                                  0
```

In the ideal model, this preparation ended at zero with certainty. Real controls would later introduce noise. Here, the mathematics
had not.

Mara recognized the next operation before Tala did. `X` exchanged the two basis states just as the finite flip had exchanged
classical `0` and `1`.

```wheeler
quantum class BasisFlip {
  state long measured = 0;
  qreg q = new qreg(1);

  entry void main() {
    prepare(q, 0);
    X(q[0]);
    measured = measure(q);
    assert(measured == 1);
  }
}
```

On basis states, the old flip returned in a new machine.

| Input state | After `X` |
| --- | --- |
| ket zero | ket one |
| ket one | ket zero |

The resemblance ended there. A classical bit occupied one of its two values. Two labels were not enough to describe every qubit
state.

Iona introduced `H`, the Hadamard operation, without defining those states in advance.

```wheeler
quantum class HadamardSample {
  state long measured = 0;
  qreg q = new qreg(1);

  entry void main() {
    prepare(q, 0);
    H(q[0]);
    measured = measure(q);
  }
}
```

Iona asked for predictions. Mara wanted equal bars because the simulator was ideal. Osei expected both outcomes and refused the
counts. Sana wrote down what, precisely, they were about to do.

"You are all finding different ways not to commit," Iona said.

Remembering the long count, Tala predicted uneven bars around an even model. Specific enough to fail. Modest enough to keep.

She ran 1,024 fresh shots with the seed fixed in advance.

```bash
wheeler run manual/HadamardSample.wbc \
  --target ideal \
  --shots 1024 \
  --seed 314159
```

```text
0 | #################################################### 516
1 | ###################################################  508
```

Mara inspected the word *ideal* for loopholes, then conceded the eight-count difference. Each shot still ended in one classical
answer. No single answer revealed the state before measurement. A hidden coin could mimic these bars, and fail the next test.

During a cooling pause, they went to the galley. Borrowed machine-shop dishes stretched five places to nine. Osei opened the old
cupboard without asking and found filters. Iona pointed across the room.

His chipped blue cup remained in the common rack, not preserved. Used. She filled it and set it beside her own.

Sable rolled across the ceiling window, its surface black except where old prospecting charges had exposed pale veins. The residents
asked about Catenary's gardens and whether the Archive still served the impossible broth. Nobody asked whether the experiment had
worked. At the instrument, that question was considered too broad for a meal.

The simulator could show the mathematical state before measurement. Hardware would not. That privileged view belonged to the
model.

```text
basis   amplitude
|0>     +0.7071067811865475
|1>     +0.7071067811865475
```

Each row carried an **amplitude**: a contribution, now attached to a basis state. After `H`, the state was written

```text
(|0> + |1>) / sqrt(2)
```

or, more compactly,

```text
H|0> = (|0> + |1>) / sqrt(2)
```

Nonzero amplitudes on several basis states made a **superposition** in that basis. The word described the state before measurement.
it did not promise several answers afterward.

Probability came from squared amplitude magnitude. Both real amplitudes had magnitude `1 / sqrt(2)`, so each basis outcome had
probability `1/2`.

```text
|1 / sqrt(2)|^2 = 1/2
```

The state was **normalized**: all outcome probabilities together summed to one.

```text
1/2 + 1/2 = 1
```

Now the signed-path arithmetic found its quantum use. Iona applied `H` again before measurement.

```wheeler
quantum class HadamardReturn {
  state long measured = 0;
  qreg q = new qreg(1);

  entry void main() {
    prepare(q, 0);
    H(q[0]);
    H(q[0]);
    measured = measure(q);
    assert(measured == 0);
  }
}
```

For output `|0>`, two contributions reinforced.

```text
+1/2 + +1/2 = 1
```

For output `|1>`, opposite contributions canceled.

```text
+1/2 + -1/2 = 0
```

So the ideal measurement returned `0` with certainty. A fair hidden coin, tossed twice, could not promise that. The signs carried
something ordinary probabilities had lost.

Osei studied the zero amplitude. "The route disappeared."

"The route was never an outcome," Iona said. "Its contribution canceled at that destination."

"That distinction feels designed to annoy maintenance engineers."

"Maintenance engineers discovered it. Physics declined to revise."

He rubbed the bridge of his nose, an admission he offered more readily than agreement, and amended the note himself. Any diagram of
quantum paths invited a private classical history. The temptation had to be named before it could be refused.

A second gate made phase visible. `Z` preserved `|0>` and negated the amplitude of `|1>`.

| Input state | After `Z` |
| --- | --- |
| ket zero | ket zero |
| ket one | minus ket one |

Applied directly to prepared `|0>`, `Z` changed no prediction. Applied between two Hadamards, it changed everything.

```wheeler
quantum class RevealPhase {
  state long measured = 0;
  qreg q = new qreg(1);

  entry void main() {
    prepare(q, 0);
    H(q[0]);
    Z(q[0]);
    H(q[0]);
    measured = measure(q);
    assert(measured == 1);
  }
}
```

First `H`: `(+,+)`. Then `Z`: `(+,-)`. Final `H`: the hidden sign became a visible `1`.

Mara looked from the source to the result. "So the middle operation changed nothing we could measure until the last operation made
it everybody's problem."

"That is an operationally hostile summary," Sana said.

"But admissible?"

Sana left the sentence in the record.

Had both signs changed together to `(-,-)`, the state would have acquired **global phase**. Everything rotated. Nothing inside the
isolated experiment could reveal it. Change one sign relative to the other, and later interference could turn that **relative
phase** into a different outcome.

Beyond the two signs waited every other angle. The far instrument had been built because those angles could carry structure.

Its oldest clocks still used mechanical shutters cut in the settlement years. Its newest target shaped fields with timings those
builders could not have imagined. Old machine, new machine: both asked where one cycle stood beside another.

Wheeler's `Phase` operation could rotate an amplitude through any chosen angle. At a quarter turn, the real number line became a
plane.

```text
1       points right
-1      points left
i       points up
-i      points down
```

A **complex number** supplied two coordinates on that plane. Distance from the origin gave magnitude. Direction gave phase. Turn
an amplitude without changing its length and its probability stayed still.

Tala drew one final state table.

| Basis | Amplitude | Probability |
| --- | --- | ---: |
| ket zero | `1 / sqrt(2)` | `1/2` |
| ket one | `i / sqrt(2)` | `1/2` |

One arrow pointed right. One pointed up. Equal length, different direction. A later operation could make the difference meet itself.

Station night came without darkness. The laboratory dimmed. Sable continued its uneven roll across the shield cameras.

Iona opened the next enclosure.

A second qubit waited inside.

The old Bell record lay on Sana's case. Its lone `3` had seemed childishly small beside the distance required to make it. Now Tala
could see the state folded inside the number, and what the folding had destroyed.

Iona turned the page to [Two Systems](07-two-systems.md).
