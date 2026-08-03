---
sidebar_position: 8
title: Two Systems
description: Two qubits distinguish independence, coherent control, correlation, entanglement, cloning, and adjoint restoration.
tutorial_id: CH07
tutorial_steps: T51,T52,T53,T54,T55,T56,T57,T58,T59,T60,T61,T62
tutorial_part: two-qubits
tutorial_order: 7
tutorial_kind: exact-quantum-sequence
tutorial_source: primary-fences
tutorial_expectation: bell-state-model
tutorial_evidence: ideal-state-and-seeded-samples
---

# Two Systems

Opening the second shield doubled the number of qubits and quadrupled the number of basis states.

```text
|00>  |01>  |10>  |11>
```

Each label contained two positions because a complete basis state had to state the basis value of each qubit. Wheeler's canonical
measurement integer treated `q[0]` as the low-order bit.

| `q[1]` | `q[0]` | Basis label | Measurement integer |
| ---: | ---: | --- | ---: |
| `0` | `0` | ket zero zero | `0` |
| `0` | `1` | ket zero one | `1` |
| `1` | `0` | ket one zero | `2` |
| `1` | `1` | ket one one | `3` |

Iona prepared both qubits independently, applied `H` to each, and paused before measurement. Each one-qubit amplitude table
contained two entries. Combining independent systems multiplied entries pairwise, producing a **product state**.

```text
( |0> + |1> ) / sqrt(2)
  tensor
( |0> + |1> ) / sqrt(2)

= ( |00> + |01> + |10> + |11> ) / 2
```

Here **tensor** named the rule for combining state spaces. In this two-qubit example it created four pairwise products. Each
basis amplitude had magnitude `1/2`, so every basis outcome had probability `1/4`.

A seeded run of 2,048 fresh preparations produced all four outcomes.

```text
0  | ################################################## 505
1  | ################################################### 513
2  | ################################################## 501
3  | ##################################################### 529
```

Around the equal model, the counts varied. More importantly, no outcome was absent. Independence had spread amplitude across the
complete four-row basis.

Osei replaced the second Hadamard with a controlled operation. `CNOT(q[0], q[1])` used `q[0]` as control and flipped `q[1]` when
the control basis value was one.

| Input `q[0]` | Input `q[1]` | Output `q[0]` | Output `q[1]` |
| ---: | ---: | ---: | ---: |
| `0` | `0` | `0` | `0` |
| `0` | `1` | `0` | `1` |
| `1` | `0` | `1` | `1` |
| `1` | `1` | `1` | `0` |

On basis states the table resembled a classical conditional flip. In a quantum region, however, the control was not measured and
converted into an ordinary branch condition. The operation transformed the complete amplitude table without selecting one measured
branch.

Such an amplitude transformation was **unitary** when it preserved normalization and possessed an adjoint that reversed it on every
accepted state. Wheeler's `unitary` method modifier admitted only operations that met that contract. It did not mean that a sampled
hardware execution would avoid physical error.

That difference returned them to the program from the failed homecoming.

```java
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

Tala ran 2,048 shots with a fixed seed.

```bash
wheeler run tutorial/BellPair.wbc \
  --target ideal \
  --shots 2048 \
  --seed 161803
```

```text
0  | ################################################## 1009
1  |                                                       0
2  |                                                       0
3  | #################################################### 1039
```

Every recorded pair matched. The sample established correlation under the declared preparation, simulator, seed, and shot count.
It did not establish entanglement from histogram shape alone.

Sana demonstrated the gap with a classical record. She prepared two ordinary bits by choosing one fair classical bit, then copying
that known value into the second location. Repeating the procedure also produced only `00` and `11`. With a suitable seed, even the
counts could match the Bell histogram exactly.

Two preparations had produced the same measurement distribution. One was a classical mixture of two definite records. The other
had the ideal amplitude state shown above. Distinguishing them required the state and preparation model, not a more enthusiastic
reading of the bars.

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

A joint pure state that could not be factored into states for its parts was **entangled**. The term described the complete joint
state. Correlated counts remained evidence consistent with that state, not a replacement for its preparation and model.

Mara returned to the CNOT table. When the target began at zero, the output target matched a known control basis value. "It copied
the bit."

"A known basis value," Iona said.

For a superposed control, CNOT produced the Bell state rather than two independent copies of the original one-qubit state. If it
had cloned the unknown state, the result would have factored into two identical tables. It did not. CNOT could copy classical
basis information into a clean basis target without becoming a universal quantum cloning operation.

In the last experiment, measurement disappeared so that the Bell preparation itself could attempt a return.

```java
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

A generated **adjoint** reversed the gate order and replaced each gate with its inverse. CNOT inverted itself. Hadamard inverted
itself. Applied before measurement, the adjoint restored `|00>` exactly in the ideal model.

```text
BellReturn (quantum) halted
measured = 0
measurements = [0]
```

This was not VM rewind. The target would physically execute the adjoint gates as new operations. Nor did it undo the measured Bell
run from the opening record. That run had crossed a measurement boundary and produced a classical observation.

At the homeward failure, the crew had possessed the measured program but not this separation. They now knew which part could carry
an adjoint, which part produced an observation, and why one word could not return both.

Osei closed the second shield and opened the source for the classical XOR flip from the Archive. If an exact finite permutation
already knew how to go forward and backward, perhaps the quantum machine could use it without translating the logic by hand.

In the field manual, that passage was [The Bridge](08-the-bridge.md).
