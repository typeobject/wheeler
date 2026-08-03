---
sidebar_position: 7
title: One Qubit
description: A two-outcome physical system earns basis states, amplitudes, interference, phase, and measurement.
tutorial_id: CH06
tutorial_steps: T36,T37,T38,T39,T40,T41,T42,T43,T44,T45,T46,T47,T48,T49,T50
tutorial_part: one-qubit
tutorial_order: 6
tutorial_kind: exact-quantum-sequence
tutorial_source: primary-fences
tutorial_expectation: one-qubit-model
tutorial_evidence: ideal-state-and-seeded-samples
---

# One Qubit

Below *Vela*, the far instrument rotated like a piece of dark glass set into the orbit of a minor moon. No habitation ring softened
its outline. The station existed to prepare small physical systems, transform them under controlled fields, and measure what
survived the encounter.

Iona met the crew at the inner lock. She wore no uniform, only a gray work coat with conductive thread bright at the cuffs, and
looked first at the evidence case in Sana's hand.

"The Archive signed it?"

"The Archive recorded it," Sana said.

A slight change in Iona's expression suggested that the answer restored an older confidence. She led them to a laboratory where
one shielded device occupied the center of an otherwise empty room.

Its controlled system had two distinguished measurement outcomes. The instrument labeled them `0` and `1`. Those labels formed the
**computational basis**, written `|0>` and `|1>` when they named quantum states rather than classical integers.

In Dirac notation, the vertical mark and angle bracket formed a ket. `|0>` was read "ket zero." It did not claim that a tiny
written zero lived inside the device.

Wheeler represented the system with one quantum register.

```java
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

`qreg q = new qreg(1)` declared a register containing one qubit. `prepare(q, 0)` established the known basis state `|0>`. The
measurement produced one classical outcome and stored it in `measured`.

```text
KnownZero (quantum) halted
measured = 0
measurements = [0]
```

A single run established one outcome. Target interfaces called one complete preparation, operation, and measurement trial a
**shot**. Iona requested 256 shots, each of which created fresh state and a complete execution. Measuring the already measured
system 256 times would not have been the same experiment.

```bash
wheeler run tutorial/KnownZero.wbc \
  --target ideal \
  --shots 256 \
  --seed 271828
```

```text
0 | ################################################################ 256
1 |                                                                  0
```

Under the ideal model, this preparation and basis predicted certainty. Hardware could later depart from the ideal through noise and
imperfect control, but no uncertainty had yet entered the semantic experiment.

Mara recognized the next operation before Tala did. `X` exchanged the two basis states just as the finite flip had exchanged
classical `0` and `1`.

```java
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

On the computational basis, the table was familiar.

| Input state | After `X` |
| --- | --- |
| ket zero | ket one |
| ket one | ket zero |

That resemblance had a boundary. A classical bit always occupied one of its allowed values in the classical model. A qubit required
more states than the two basis labels could name.

Iona introduced `H`, the Hadamard operation, without defining those states in advance.

```java
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

Tala ran 1,024 fresh shots with a declared seed.

```bash
wheeler run tutorial/HadamardSample.wbc \
  --target ideal \
  --shots 1024 \
  --seed 314159
```

```text
0 | ################################################### 509
1 | #################################################### 515
```

Every shot still ended in one classical outcome. The histogram approached equal frequencies, yet nothing in a single outcome
identified the state that existed before measurement. Calling the qubit a hidden coin would reproduce the counts and fail the next
experiment.

Only the ideal simulator could expose its mathematical state before measurement. That diagnostic belonged to the simulator, not
to an ordinary hardware observation.

```text
basis   amplitude
|0>     +0.7071067811865475
|1>     +0.7071067811865475
```

Each row carried an **amplitude**. The state after `H` on `|0>` was therefore written

```text
(|0> + |1>) / sqrt(2)
```

or, more compactly,

```text
H|0> = (|0> + |1>) / sqrt(2)
```

A state with nonzero amplitudes on more than one basis state was a **superposition** in that basis. The term named the amplitude
description. It did not mean that measurement would report two outcomes in one shot.

Probability came from squared amplitude magnitude. Both real amplitudes had magnitude `1 / sqrt(2)`, so each basis outcome had
probability `1/2`.

```text
|1 / sqrt(2)|^2 = 1/2
```

Because the state was **normalized**, its probabilities summed to one.

```text
1/2 + 1/2 = 1
```

With the amplitude table in place, the path arithmetic from the incoming packets found its quantum use. Iona applied `H` a second
time before measurement.

```java
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

Measurement therefore returned `0` with certainty in the ideal model. A hidden fair coin flipped twice would not have made the
same prediction. The amplitudes, including their signs, carried information absent from ordinary probabilities.

Osei studied the zero amplitude. "The route disappeared."

"The route was never an outcome," Iona said. "Its contribution canceled at that destination."

Such a distinction mattered whenever a diagram tempted someone to assign a classical private history to each quantum path.

A second gate made phase visible. `Z` preserved `|0>` and negated the amplitude of `|1>`.

| Input state | After `Z` |
| --- | --- |
| ket zero | ket zero |
| ket one | minus ket one |

Applied directly to prepared `|0>`, `Z` changed no prediction. Applied between two Hadamards, it changed everything.

```java
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

After the first `H`, the amplitudes were `(+,+)`. `Z` changed them to `(+,-)`. The final `H` converted that relative sign into a
certain basis outcome, `1`.

Negating both amplitudes instead would have produced `(-,-)`, a **global phase** change. Every amplitude would rotate together, so
no interference experiment on the isolated state could reveal the difference. Negating only one row changed **relative phase**,
which later operations could convert into different outcome probabilities.

Beyond two signs lay every other possible phase. Wheeler's `Phase` operation could rotate an amplitude through any declared angle.
At a quarter turn, the real number line became a plane.

```text
1       points right
-1      points left
i       points up
-i      points down
```

A **complex number** supplied two real coordinates on that plane. Its magnitude measured distance from the origin, while its angle
carried phase. Rotating an amplitude could change its angle without changing the probability obtained from squared magnitude.

Tala drew one final state table.

| Basis | Amplitude | Probability |
| --- | --- | ---: |
| ket zero | `1 / sqrt(2)` | `1/2` |
| ket one | `i / sqrt(2)` | `1/2` |

Nothing in the table made complex numbers mysterious. One arrow pointed right, another up, both had equal length, and a later
operation could bring their angular difference into interference.

When the calibration ended, Iona opened the adjacent shield. A second qubit waited inside, coupled to the first by a controlled
operation. On Sana's evidence case, the old Bell record from the homeward failure changed status from inscrutable source to a
question they could finally approach.

Iona had already opened the next chapter, [Two Systems](07-two-systems.md).
