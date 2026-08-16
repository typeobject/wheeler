---
sidebar_position: 7
title: One Qubit
description: Sable's instrument gives amplitudes physical consequence while an old blue cup keeps another history.
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

Rotation settled weight into Tala's boots while *Vela*'s service lock joined the
shielded habitat above Sable. Through a port below her shoulder, the far
instrument lay across the moon like a dark pane on darker rock.

Sable rolled beneath it with the irregularity of captured stone. Shield shadow
concealed most of the habitat, and laboratory trusses reached far enough apart to
keep one failed refrigerator from warming every chamber.

Five resident names appeared on the inner-lock witness panel. Below them, an old
charter seal had been scored through and replaced by the cooperative's linked
circles. The change dated from the season when relief stopped arriving and the
crews opened their own stores under witness.

Warm air from the return lines smelled faintly of mushrooms. A bandwidth ballot
shared the wall with personal messages and target telemetry. At the bottom, the
same ledger counted drinking water, vacuum-pump work, and three replacement parts
the machine shop would have to cut from older parts.

A clock comparison moved across the overhead status strip: Catenary's optical
reference arriving, Sable's local clock answering, charged weather thickening
between them. The station prepared small physical systems, shaped them with
controlled fields, and measured what came out because those angles could separate
a drifting beacon from a changing path. That need had carried *Vela* across the
Reach.

Iona received them inside the pressure lock wearing a gray work coat threaded for conductivity. Her first inspection belonged to
Sana's sealed case.

"Did the Archive sign your transfer?"

"The Archive witnessed and retained it," Sana answered.

"Better. A signature encourages their emotions."

Iona relaxed by a degree. In the instrument's first winter, a false manifest had delivered thousands of fasteners made from the
wrong alloy with an immaculate signature attached. She and Sana began corresponding afterward, usually in the questions appended
to rejected manifests.

She looked at Osei after the records were secure. He opened a padded case: two bearing sensors, one for the mounting he remembered, one for the
revision installed after he left. Mara had surrendered cargo mass for both and had not suffered in silence.

Iona chose the revised sensor. "You noticed the mounting change."

"Before departure," Osei said.

Mara lifted the unused case. "His uncertainty has four kilograms of mass."

The replacement would keep the west bearing safe and preserve the fallback radio. Recovering narrow-laser precision required a new
race, imported cargo, and a shutdown longer than Sable could presently afford.

Summaries could leave by radio. The detailed evidence needed *Vela*.

Iona held her thumb against Osei's seal before handing the case onward. Tala learned more from that pause than an embrace would have
made safe to ask.

The corridor's shallow spin moved down beneath their steps. Frost grew behind a warning grid along one wall. At the laboratory,
they changed into clean layers and crossed fields designed to remove the electrostatic dust Sable lifted without air.

A single shielded device occupied a room defined mostly by unused floor. Mara asked the price of emptiness. Iona supplied it, and
the discussion ended.

Iona began on the ideal simulator. It accepted the Wheeler operations intended for the chamber while charging no coolant, queue
time, or hardware damage for error.

The model distinguished outcomes `0` and `1`, together forming the **computational basis**. State notation wrote them as `|0>` and
`|1>` to separate quantum states from ordinary integer values.

The vertical line and angle bracket formed a *ket*. `|0>` was read "ket zero."
The notation named a state in the model; the device contained a physical system
prepared to answer the corresponding experiment.

A one-position quantum register represented that modeled system in Wheeler.

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

The declaration `qreg q = new qreg(1)` allocated one qubit. `prepare(q, 0)` established known state `|0>`. Measurement then produced
a classical value and assigned it to `measured`.

```text
KnownZero (quantum) halted after 4 steps
measured = 0
measurements = [0]
```

The run produced one outcome and a green report border. Across the unused floor, the physical chamber continued humming without
having participated.

"This is an impressive room for work done elsewhere," Mara said.

"The room remains unused."

"Its expense appears unaffected."

A **shot** included fresh preparation, the selected operations, and measurement. Iona requested 256 independent beginnings. A
second reading of an already measured system would constitute another procedure.

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

Under the ideal model, this known preparation assigned certainty to outcome zero. Physical control error had no place in that
specific calculation.

Mara recognized `X` from the two-state work. On computational-basis states, it exchanged `|0>` and `|1>` as the finite flip had
exchanged ordinary values.

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

The earlier mapping had found a quantum implementation on basis inputs.

| Input state | After `X` |
| --- | --- |
| ket zero | ket one |
| ket one | ket zero |

The shared table did not make a qubit into a classical bit. Classical state held one admitted value, while a qubit required
amplitudes beyond two labels.

Iona made the missing state space necessary by applying the Hadamard operation, `H`.

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

Before execution, Iona required predictions. Mara chose equal counts from the word *ideal*. Osei predicted both outcomes while
withholding exact totals. Sana documented the preparation and measurement that would decide among them.

"Each of you has invented a separate shelter from being wrong," Iona said.

Tala used the long count and predicted unequal sample counts around equal model probability. The prediction could fail without
asking one sample to imitate the model perfectly.

She fixed the seed, then executed 1,024 fresh simulator shots.

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

Mara searched the target label for an escape from the eight-count imbalance and found none. Every shot had yielded a single
classical value, none revealing the premeasurement state. An ordinary hidden coin could reproduce these bars and still fail a later
interference experiment.

The target schedule opened a cooling pause, and the crew joined Sable's residents in the galley. Machine-shop dishes extended a
table built for five. Osei opened a cupboard from memory and found the filters before Iona redirected him.

His chipped blue cup still stood in the common rack with the wear of continued use. Iona filled it and placed it beside hers.

Sable crossed the ceiling window, black rock broken by pale veins from old prospecting charges. Residents asked about Catenary's
gardens and the Archive's fraudulent broth. They avoided asking whether the experiment had worked because instrument keepers
regarded the question as too broad for a meal.

Afterward, the simulator exposed its numerical state before measurement. No chamber could return the same privileged description;
it belonged to the ideal model.

```text
basis   amplitude
|0>     +0.7071067811865475
|1>     +0.7071067811865475
```

Every basis row carried an **amplitude**, the signed contribution now attached to a quantum basis state. The state after `H` could
be written as

```text
(|0> + |1>) / sqrt(2)
```

The same relation had a shorter form.

```text
H|0> = (|0> + |1>) / sqrt(2)
```

Nonzero amplitudes on several basis states made a **superposition** in that basis. The word described the state before measurement.
It did not promise several answers afterward.

Squaring amplitude magnitude produced outcome probability. Each real amplitude had magnitude `1 / sqrt(2)`, giving each basis
outcome probability `1/2`.

```text
|1 / sqrt(2)|^2 = 1/2
```

Because the complete set of outcome probabilities summed to one, the state was **normalized**.

```text
1/2 + 1/2 = 1
```

Iona made the earlier signed arithmetic operational by placing a second `H` before measurement.

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

Two modeled contributions met constructively at output `|0>`.

```text
+1/2 + +1/2 = 1
```

At output `|1>`, contributions of opposite sign canceled.

```text
+1/2 + -1/2 = 0
```

The ideal model therefore assigned certainty to measured `0`. Two tosses of a fair hidden coin offered no such guarantee. Relative
sign had retained structure absent from ordinary outcome probabilities.

Osei pointed to the zero row. "One route is gone."

"The route names part of the sum," Iona said. "Its contribution canceled at this output."

"Someone designed the language against maintenance."

"Maintenance discovered the problem. Physics rejected our complaint."

Osei rubbed the bridge of his nose and amended his own note. The gesture admitted more than his voice would. A path diagram tempted
its interpreter to invent a private classical history, so the warning had to live beside the picture.

The `Z` gate provided a controlled change in phase. It preserved `|0>` while negating the amplitude of `|1>`.

| Input state | After `Z` |
| --- | --- |
| ket zero | ket zero |
| ket one | minus ket one |

A `Z` acting on prepared `|0>` left every prediction unchanged. Between two Hadamards, its relative sign altered the final
interference.

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

The first `H` produced `(+,+)`, and `Z` changed the pattern to `(+,-)`. The final `H` converted that relative sign into outcome `1`.

Mara compared source and outcome. "The middle gate concealed its effect until the last gate made it observable."

Sana considered the sentence. "Hostile phrasing."

"Does the account admit it?"

Sana retained Mara's summary.

Changing both signs together to `(-,-)` would add **global phase**, rotating the entire state without creating an observable
difference inside the isolated experiment. Changing one sign altered **relative phase**, which later interference could reveal as
a changed outcome.

Positive and negative signs marked only two angles. The far instrument existed to extract structure carried across the full cycle.

Mechanical shutters from Sable's settlement years still served its oldest clocks. The newest target shaped fields at timings their
builders never possessed. Both generations asked how one cycle stood relative to another.

Wheeler's `Phase` operation rotated amplitude through a chosen angle. A quarter turn required leaving the real line for a plane.

```text
1       points right
-1      points left
i       points up
-i      points down
```

A **complex number** provided coordinates on that plane. Its distance from the origin determined magnitude, while direction
determined phase. Rotation that preserved length also preserved probability magnitude.

Tala assembled one final amplitude table.

| Basis | Amplitude | Probability |
| --- | --- | ---: |
| ket zero | `1 / sqrt(2)` | `1/2` |
| ket one | `i / sqrt(2)` | `1/2` |

The two amplitudes had equal length and different directions, one rightward and one upward. A later operation could bring that
angular difference into interference.

Station night lowered the laboratory lights while Sable rolled unevenly across the shield cameras.

Iona released the shield on the neighboring enclosure.

The interface now admitted a second qubit.

Sana placed the old Bell record on her case. Its measured `3` had once looked too small to justify a journey across the Reach. Tala
could now see how much modeled state measurement had compressed into that number and how much access had ended.

Iona opened the Bell source under the Common Book's next account, [Two Systems](07-two-systems.md).
