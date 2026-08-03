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
status light. Between them, engraved in metal, sat the only promise its builders had made.

```text
Uf |x,y> = |x, y xor f(x)>
```

Through those ports, the machine accepted an input bit `x` and a target bit `y`. For one fixed Boolean function `f`, it preserved
`x` and flipped `y` when `f(x)` equaled one. The contract said nothing about how the machine implemented `f`, how expensive that implementation had
been, or whether the function described anything useful.

"An oracle," Mara said, with the disappointment of someone shown a very small cabinet after hearing a very large word.

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

Only once would the quantum circuit call the oracle.

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

This was **phase kickback**. Nothing traveled backward through the circuit. A controlled operation placed phase information on the
joint amplitude associated with its control.

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

Without sampling uncertainty, the ideal runs separated the promise classes.

```text
DeutschConstant  result = 0
DeutschBalanced  result = 1
```

One oracle invocation had answered a global question about two function values. The circuit had not measured both values in
parallel, extracted a hidden table, or made the implementation free. It had arranged phase so that the promised property,
equality versus difference, survived interference while the individual values did not.

Sana recorded five distinct objects: the promised problem, the oracle contract, the oracle implementation, the circuit that made
one call, and the final basis outcome. Calling all five "the algorithm" would have made later evidence impossible to scope.

After both cases passed, the contract machine unlocked its next module. Behind the panel lay a four-state search space and one
marked basis value, small enough to inspect completely and large enough to demonstrate amplification.

From there the field manual continued into [The Search](10-the-search.md).
