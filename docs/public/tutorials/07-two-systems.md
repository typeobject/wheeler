---
sidebar_position: 8
title: Two Systems
description: A second qubit makes room for independence, entanglement, and a return that measurement forbids.
tutorial_id: CH07
tutorial_steps: T51,T52,T53,T54,T55,T56,T57,T58,T59,T60,T61,T62
tutorial_part: two-qubits
tutorial_order: 7
tutorial_kind: current-source-and-intended-sampling
tutorial_source: primary-fences-and-intended-command
tutorial_expectation: bell-state-model
tutorial_evidence: ideal-model-and-intended-seeded-samples
---

# Two Systems

When the second shield opened, the room found a lower note. A deeper pump entered through the deck. Status lights crossed the walls
as isolation widened from one enclosure to two.

The second device had been made on Sable. Its access panels were cut by hand. Several residents shared the maker's mark. Nothing
about it looked like a copy.

In the model, one qubit became two, and two basis states became four. The growth was small enough, still, to write in one line:

```text
|00>  |01>  |10>  |11>
```

Each label named both qubits. Wheeler read `q[0]` as the low-order bit when it turned the pair into a measurement integer.

| `q[1]` | `q[0]` | Basis label | Measurement integer |
| ---: | ---: | --- | ---: |
| `0` | `0` | ket zero zero | `0` |
| `0` | `1` | ket zero one | `1` |
| `1` | `0` | ket one zero | `2` |
| `1` | `1` | ket one one | `3` |

Iona prepared the qubits separately, applied `H` to each, and paused. Their amplitude tables combined pair by pair, making a
**product state**.

```text
( |0> + |1> ) / sqrt(2)
  tensor
( |0> + |1> ) / sqrt(2)

= ( |00> + |01> + |10> + |11> ) / 2
```

Here **tensor** named the rule that combined the state spaces. Two entries met two entries and produced four. Each amplitude had
magnitude `1/2`. Each outcome, probability `1/4`.

Tala covered the probabilities and asked Mara what could appear. Mara named all four, then objected to being examined beside a
printed answer. Osei observed that print had offered them little protection at the Archive.

A seeded run of 2,048 fresh preparations under seed `57721` produced all four outcomes.

```text
0  | ##################################################### 531
1  | ###################################################   508
2  | ##################################################    497
3  | ###################################################   512
```

The counts wandered around equality. No outcome vanished. Independence had spread amplitude across all four basis states.

Osei replaced the second Hadamard with a controlled operation. `CNOT(q[0], q[1])` used `q[0]` as control and flipped `q[1]` when
the control basis value was one.

| Input `q[0]` | Input `q[1]` | Output `q[0]` | Output `q[1]` |
| ---: | ---: | ---: | ---: |
| `0` | `0` | `0` | `0` |
| `0` | `1` | `0` | `1` |
| `1` | `0` | `1` | `1` |
| `1` | `1` | `1` | `0` |

On basis states, the table resembled a classical conditional flip. But no measurement turned the control into an ordinary branch.
CNOT transformed the whole amplitude table at once.

A transformation was **unitary** when it preserved normalization and had an adjoint capable of reversing it for every allowed
state. Wheeler's `unitary` modifier made that mathematical promise. Hardware could still err while attempting the gates.

The compiler checked mathematics. The chamber supplied weather. Each considered the other outside its department.

That difference returned them to the Bell program. Sana compared the copy received at Catenary with the one carried across the
reach. The digests matched.

The program had not changed. Its readers had.

```wheeler
quantum class BellPair {
  state long measured = 0;
  qreg q = new qreg(2);

  unitary void prepareBell() {
    H(q[0]);
    CNOT(q[0], q[1]);
  }

  entry void main() {
    prepare(q, 0);
    prepareBell();
    measured = measure(q);
  }
}
```

Starting from `|00>`, the Hadamard created two contributions.

```text
( |00> + |01> ) / sqrt(2)
```

Because `q[0]` occupied the right-hand position in the basis label, CNOT left `|00>` unchanged and carried `|01>` to `|11>`.

```text
( |00> + |11> ) / sqrt(2)
```

Only two rows in the ideal amplitude table remained nonzero.

| Basis | Amplitude | Probability |
| --- | ---: | ---: |
| ket zero zero | `1 / sqrt(2)` | `1/2` |
| ket zero one | `0` | `0` |
| ket one zero | `0` | `0` |
| ket one one | `1 / sqrt(2)` | `1/2` |

Before the run, Sable moved between the station and Catenary. Home disappeared from the relay panel.

For forty-three minutes no distant authority could approve, forbid, or misunderstand what happened there. Iona treated the silence
as ordinary. At Sable, light itself enforced local responsibility.

Mara predicted that `0` and `3` would appear and refused to predict equal counts. Tala ran 2,048 shots with a fixed seed.

```bash
wheeler run manual/BellPair.wbc \
  --target ideal \
  --shots 2048 \
  --seed 161803
```

```text
0  | ################################################### 1027
1  |                                                       0
2  |                                                       0
3  | ################################################### 1021
```

Every pair matched. Under this preparation and simulator, the sample showed correlation. The bars alone could not say whether the
state had been entangled.

Sana answered with a record from the Archive's old two-key doors. Their controller chose an ordinary bit and copied it to two audit
locations. That procedure also produced only `00` and `11`. With the right seed, even the bars could be made identical.

The Archive had displayed those records under *Perfect Agreement*. As an apprentice, Sana changed the label. Edrin changed it
back. The dispute eventually required more storage than the example.

Different preparations. Same distribution. One made a classical mixture of definite records. The other made the amplitude state
above. No enthusiasm applied to a histogram could erase the difference.

Iona asked whether the Bell amplitude table could be separated into independent one-qubit tables. Tala assigned symbolic entries
`a` and `b` to the first qubit, then `c` and `d` to the second. A product state would have joint amplitudes

```text
|00>: a*c
|01>: a*d
|10>: b*c
|11>: b*d
```

For the Bell table, `a*c` and `b*d` had to be nonzero, which made `a`, `b`, `c`, and `d` nonzero. It also required `a*d` and
`b*c` to be zero. Those conditions could not all hold together. No pair of independent one-qubit tables produced the Bell state.

A joint pure state that could not be factored into states of its parts was **entangled**. The word belonged to the joint state, not
to messages sent faster than light, not to useful communication by measurement, and not to human intimacy borrowing scientific
authority.

The matching bars agreed with that state. They did not define it. Iona allowed the noun only after the factorization failed. At
Sable, impressive words were stored beside unlabeled spare parts: useful sometimes, dangerous by default.

Mara returned to the CNOT table. When the target began at zero, the output target matched a known control basis value. "It copied
the bit."

"A known basis value," Iona said.

"That qualification again," Mara said.

"You brought Sana across the reach. You have exceeded your complaint quota."

With a superposed control, CNOT made the Bell state, not two independent copies. A true clone would have factored into identical
one-qubit tables. This state would not. CNOT could copy known basis information into a clean target. It could not copy an unknown
qubit.

For the last experiment, Osei removed measurement. He paused over the empty line and left it visible in the diff.

One missing boundary changed the meaning of return.

```wheeler
quantum class BellReturn {
  state long measured = 0;
  qreg q = new qreg(2);

  unitary void prepareBell() {
    H(q[0]);
    CNOT(q[0], q[1]);
  }

  entry void main() {
    prepare(q, 0);
    prepareBell();
    reverse prepareBell();
    measured = measure(q);
    assert(measured == 0);
  }
}
```

A generated **adjoint** took the gates in reverse order and inverted each one. CNOT undid itself. So did Hadamard. Before
measurement, that new work restored `|00>` in the ideal model.

The scheduler gave the reverse gates their own duration. Nothing vanished from the station clock. Pumps ran. Controls fired. The
crew waited for the work of going back.

```text
BellReturn (quantum) halted after 6 steps
measured = 0
measurements = [0]
```

No VM history moved backward. The target performed the adjoint as new physical work. Nor could this touch the earlier measured Bell
run. That state had crossed into a classical number.

Sana placed the restored run beside the earlier `3`. They shared a preparation, then divided at measurement. One returned while it
was still coherent. The other left a classical number: preservable, repeatable in a report, useless as a road back to the unknown
state.

Later, at home, the distinction would seem obvious. Here it was new enough to quiet them.

Sable's shadow ended. Relay tones climbed through the room, one after another, until Catenary returned to the panel as a delayed
clock and a waiting queue.

Osei closed the second shield and opened the source for the classical XOR flip from the Archive. If a reversible finite permutation
already knew how to go forward and backward, perhaps the quantum machine could use it without translating the logic by hand.

The manual called that crossing [Crossing](08-crossing.md).
