---
sidebar_position: 10
title: The Contract Machine
description: Phase kickback and one exact oracle call distinguish constant from balanced one-bit functions.
tutorial_id: CH09
tutorial_steps: T69,T70,T71,T72,T73,T74
tutorial_part: algorithmic-interference
tutorial_order: 9
tutorial_kind: exact-quantum-algorithm
tutorial_source: primary-fences
tutorial_expectation: deutsch-classification
tutorial_evidence: exact-ideal-execution
---

# The Contract Machine

Without controls, the contract machine occupied one unremarkable rack. Four optical ports entered its front plate. One returned a
status light. The housing had been fabricated from a Sable survey locker, and the locker inventory still showed faintly beneath the
new finish: anchors, emergency oxygen, drilling charges. Between those obsolete promises, engraved deep enough to survive another
use, sat the only current one.

```text
Uf |x,y> = |x, y xor f(x)>
```

Through those ports, the machine accepted an input bit `x` and a target bit `y`. For one fixed Boolean function `f`, it preserved
`x` and flipped `y` when `f(x)` equaled one. The contract said nothing about how the machine implemented `f`, how expensive that
implementation had been, or whether the function described anything useful.

"An oracle," Mara said, with the disappointment of someone shown a very small cabinet after hearing a very large word.

The first Sable crews had used *oracle* for forecasting software that predicted thermal fractures in the moon. When one forecast
failed, the word acquired the suspicion usually reserved for gambling. The quantum engineers kept it only after engraving the
callable mapping where nobody could mistake a bounded operation for prophecy.

An **oracle** was exactly that cabinet's contract: a callable operation exposing a declared input-output mapping. It possessed no
wisdom and volunteered no explanation. An algorithm that required a difficult oracle still required someone to implement the
difficult oracle.

Iona loaded one of four possible one-bit functions.

| Function | `f(0)` | `f(1)` | Class |
| --- | ---: | ---: | --- |
| zero | `0` | `0` | constant |
| one | `1` | `1` | constant |
| identity | `0` | `1` | balanced |
| negation | `1` | `0` | balanced |

Under the promise, the hidden function was either **constant**, with equal outputs, or **balanced**, with different outputs. A
classical query to one input could not distinguish the classes because either class could return either first value. Querying both
inputs settled the question.

Only once would the quantum circuit call the oracle. Tala found the restriction unsettling. In transit work, an analyst repeated a
query until the system yielded enough ordinary records to expose its mistake. Here the circuit had to arrange one interaction so
that the promised property, rather than either individual function value, became visible.

Its target qubit began in `|1>` and passed through `H`.

```text
H|1> = (|0> - |1>) / sqrt(2)
```

This state, often written `|->`, had a useful response to `X`.

```text
X|-> = -|->
```

Flipping the target changed only its global sign. When the oracle applied that flip conditionally from the input, the sign became
relative between input alternatives. The target returned to the same local state while the function value appeared as phase on the
input.

```text
|x>|->  ->  (-1)^f(x) |x>|->
```

This was **phase kickback**. Nothing traveled backward through the circuit. The name survived from older diagrams whose arrows had
encouraged that misconception. Iona crossed out two such arrows in the manual and left the diagrams themselves intact as evidence.
A controlled operation placed phase information on the joint amplitude associated with its control.

Tala prepared the input in an equal superposition, giving both promised function values a place to affect relative phase. For a
constant function, both input amplitudes acquired the same sign.

```text
(+,+) or (-,-)
```

A final Hadamard converted either common-sign pattern into input outcome `0`. The global difference between `(+,+)` and `(-,-)`
remained unobservable.

```java
quantum class DeutschConstant {
  state long result = 0;
  qreg q = new qreg(2);

  unitary void oracle() {
  }

  entry void main() {
    prepare(q, 2);
    H(q[0]);
    H(q[1]);
    oracle();
    H(q[0]);
    result = measure(q[0]);
    assert(result == 0);
  }
}
```

`prepare(q, 2)` set low-order input `q[0]` to zero and target `q[1]` to one. The empty oracle implemented the constant-zero case.
A constant-one oracle would apply `X` to the target and produce the same measured input result through a global sign.

For a balanced function, the two input alternatives acquired opposite signs.

```text
(+,-) or (-,+)
```

Afterward, the final Hadamard converted either relative-sign pattern into input outcome `1`.

```java
quantum class DeutschBalanced {
  state long result = 0;
  qreg q = new qreg(2);

  unitary void oracle() {
    CNOT(q[0], q[1]);
  }

  entry void main() {
    prepare(q, 2);
    H(q[0]);
    H(q[1]);
    oracle();
    H(q[0]);
    result = measure(q[0]);
    assert(result == 1);
  }
}
```

CNOT implemented the identity function by flipping the target exactly when input `q[0]` equaled one. The negation function would
produce the other opposite-sign pattern and the same classification.

Iona loaded the two cases without telling Mara which implementation occupied the rack. Mara watched the control lights instead of
the source and guessed wrong once, proving only that target plumbing leaked less useful information than pilot intuition preferred.

Without sampling uncertainty, the ideal runs separated the promise classes.

```text
DeutschConstant  result = 0
DeutschBalanced  result = 1
```

One oracle invocation had answered a global question about two function values. The circuit had not measured both values in
parallel, extracted a hidden table, or made the implementation free. It had arranged phase so that the promised property,
equality versus difference, survived interference while the individual values did not.

At the far instrument, this tiny classification was not operationally valuable. Its value lay in being complete enough to audit.
Every promised function fit in the table. Every circuit contribution could be traced. Every grander phrase could be checked against
what the machine had actually done. The station kept the module for the same reason Catenary kept a hand pump beside each automated
water wall. Small working things exposed assumptions that large working things could hide.

Sana recorded five distinct objects: the promised problem, the oracle contract, the oracle implementation, the circuit that made
one call, and the final basis outcome. Calling all five "the algorithm" would have made later evidence impossible to scope.

A delayed status update arrived from Catenary while she worked. Neris Venn had signed it in her new office as director of traffic
continuity. The particle front had accelerated within the forecast range, and Venn moved the retuning deadline forward by
forty-three minutes.

The acceptance request named the physical sample, application identity, and complete lineage separately. Six years earlier, Venn
had trusted one green transit state because the larger system had hidden fourteen cars from her. Tala could not tell whether this
new precision came from that failure or from an unrelated policy review. Either origin would have to survive the same checks.

No one aboard the far instrument could make light cross the reach faster. They could only finish the calibration without creating a
reason for it to be rejected at the other end.

After both cases passed, the contract machine unlocked its next module. Behind the panel lay a four-state search space and one
marked basis value, small enough to inspect completely and large enough to demonstrate amplification.

From there the field manual continued into [The Search](10-the-search.md).
