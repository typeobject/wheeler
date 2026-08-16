---
sidebar_position: 8
title: Two Systems
description: Under Sable's local authority, Bell preparation separates correlation, entanglement, measurement, and adjoint work.
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

Opening the second shield brought a deeper pump tone through the deck. Status lamps moved across the walls while the laboratory
extended isolation around both enclosures.

Sable's machine shop had built the second device. Hand-cut access panels carried a maker's mark shared by several residents. Its
construction claimed local ancestry rather than resemblance to the first.

Adding one qubit doubled the modeled basis from two states to four, still few enough to display together.

```text
|00>  |01>  |10>  |11>
```

Every basis label specified the pair. When Wheeler encoded measurement as an integer, `q[0]` occupied the low-order position.

| `q[1]` | `q[0]` | Basis label | Measurement integer |
| ---: | ---: | --- | ---: |
| `0` | `0` | ket zero zero | `0` |
| `0` | `1` | ket zero one | `1` |
| `1` | `0` | ket one zero | `2` |
| `1` | `1` | ket one one | `3` |

Iona prepared each qubit independently and applied `H` to both. Combining their separate amplitude tables pairwise produced a
**product state**.

```text
( |0> + |1> ) / sqrt(2)
  tensor
( |0> + |1> ) / sqrt(2)

= ( |00> + |01> + |10> + |11> ) / 2
```

The **tensor** rule combined the two state spaces. Two amplitudes from one table paired with two from the other to make four. Joint
amplitude magnitude `1/2` gave every basis outcome probability `1/4`.

Tala concealed the probability column and asked Mara for possible outcomes. Mara identified all four and objected to an examination
conducted beside the answer. Osei reminded her how poorly visible records had protected them at the Archive.

They fixed seed `57721` and ran 2,048 fresh preparations. Every basis outcome appeared.

```text
0  | ##################################################### 531
1  | ###################################################   508
2  | ##################################################    497
3  | ###################################################   512
```

Sample counts varied around equal model weights. Separate preparation had left nonzero amplitude on all four basis rows.

Osei removed one Hadamard and substituted a controlled operation. In `CNOT(q[0], q[1])`, the low-order qubit controlled a flip of
`q[1]` on basis components where `q[0]` was one.

| Input `q[0]` | Input `q[1]` | Output `q[0]` | Output `q[1]` |
| ---: | ---: | ---: | ---: |
| `0` | `0` | `0` | `0` |
| `0` | `1` | `0` | `1` |
| `1` | `0` | `1` | `1` |
| `1` | `1` | `1` | `0` |

Its basis-state table resembled a classical conditional flip. No measurement created an ordinary branch inside the operation;
CNOT transformed every amplitude component coherently.

A **unitary** transformation preserved normalization and possessed an adjoint that reversed it across all allowed states. Wheeler's
`unitary` modifier declared that mathematical contract. A physical target could still implement its gates imperfectly.

Compiler checks governed the transformation. Chamber weather governed its physical attempt. Neither authority absorbed the other.

Sana reopened the Bell source under that distinction and compared Catenary's copy with the artifact carried to Sable. Their digests
were identical.

The bytes had remained fixed while the crew acquired better questions.

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

From prepared `|00>`, Hadamard placed amplitude on two basis rows.

```text
( |00> + |01> ) / sqrt(2)
```

The right-hand basis position represented `q[0]`. CNOT therefore preserved `|00>` and transformed `|01>` into `|11>`.

```text
( |00> + |11> ) / sqrt(2)
```

The ideal amplitude table retained two nonzero rows.

| Basis | Amplitude | Probability |
| --- | ---: | ---: |
| ket zero zero | `1 / sqrt(2)` | `1/2` |
| ket zero one | `0` | `0` |
| ket one zero | `0` | `0` |
| ket one one | `1 / sqrt(2)` | `1/2` |

Sable occulted Catenary before execution. The home relay dropped into silence.

For forty-three minutes no distant authority could approve, forbid, or
misunderstand what happened there. Iona treated the silence as ordinary. The
Covenant of Air had placed emergency authority beside the system at risk; Sable's
orbit enforced that principle more firmly than any court. Local responsibility
lasted until light could carry an answer.

Mara predicted outcomes `0` and `3` while declining to name their counts. Tala fixed the seed and requested 2,048 shots.

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

Every observed pair agreed. This simulator sample from the named preparation exhibited correlation, though the histogram alone did
not establish entanglement.

Sana produced an Archive record from an old two-key door. Its classical controller selected one ordinary bit and copied it into two
audit fields, also yielding only `00` and `11`. A chosen seed could make its histogram identical to the Bell sample.

The exhibit had once called those records *Perfect Agreement*. Apprentice Sana changed the label, and Edrin restored it. Their
ensuing dispute consumed more storage than the controller trace.

The procedures shared an outcome distribution while preparing different states. One produced a classical mixture of definite
records; Bell preparation produced the displayed pure amplitude state. A histogram could not recover that distinction.

Iona required Tala to test whether independent one-qubit tables could factor the Bell amplitudes. Tala used `a` and `b` for one
qubit and `c` and `d` for the other. Any product state would then have joint amplitudes

```text
|00>: a*c
|01>: a*d
|10>: b*c
|11>: b*d
```

Bell rows required nonzero `a*c` and `b*d`, forcing all four factors nonzero. Its zero rows simultaneously required `a*d` and
`b*c` to vanish. No assignments satisfied both demands, so independent one-qubit tables could not produce the Bell state.

A joint pure state with no factorization into states of its parts was **entangled**. The term described that mathematical relation.
It implied neither faster-than-light messaging nor communication through measurement, and it offered no scientific authority to a
metaphor about people.

The observed bars were consistent with the entangled state while remaining insufficient to define it. Iona permitted the term only
after factorization failed. Sable treated impressive nouns like unidentified spare parts: potentially useful and dangerous until
examined.

Mara returned to the basis table. With a target initialized to zero, the output target matched the control's known basis value.
"That operation copied it."

"It copied known basis information," Iona corrected.

"Your qualifications have become migratory."

"You transported Sana here. Complaints about qualification are now outside quota."

A superposed control led CNOT to the Bell state instead of independent duplicates. Cloning would require a product of identical
one-qubit states, which this table could not factor into. CNOT copied known basis information to a clean target; it did not clone an
unknown qubit.

Osei prepared the final source by deleting measurement. He left the removed boundary visible in the comparison.

Removing that boundary opened a coherent road back.

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

The generated **adjoint** reversed gate order and replaced each operation by its adjoint. CNOT and Hadamard were each self-adjoint.
Executed before measurement, their inverse sequence returned the ideal state to `|00>`.

The target schedule allocated duration to every adjoint gate. Controls fired, pumps continued, and the station clock advanced while
the machine performed the return.

```text
BellReturn (quantum) halted after 6 steps
measured = 0
measurements = [0]
```

The operation consumed no VM history and reversed no clock. The target executed fresh adjoint work. It also had no access to the
earlier measured Bell state, whose measurement had already produced a classical number.

Sana placed both runs together. Their preparations matched, and their roads separated at measurement. Coherent adjoint work
restored one run before that boundary. The earlier run left the preservable observation `3`, which provided no path back to its
unknown premeasurement state.

Silence followed while the distinction was still new enough to change their language.

Sable's shadow ended. Relay tones climbed through the room, one after another,
until Catenary returned to the panel as a delayed clock and a waiting queue. The
Second Navigation depended on decisions made through both conditions: local work
during silence, shared judgment when the road reopened.

Osei closed the enclosure and retrieved the Archive's classical XOR source. Its finite permutation already supported forward and
inverse execution. He asked whether the quantum machine could use the same definition coherently.

The Common Book called that crossing [Crossing](08-crossing.md).
