---
sidebar_position: 10
title: Contract Machine
description: A machine answers one narrow question, and phase carries more than the answer seems to contain.
tutorial_id: CH09
tutorial_steps: T69,T70,T71,T72,T73,T74
tutorial_part: algorithmic-interference
tutorial_order: 9
tutorial_kind: intended-quantum-algorithm
tutorial_source: intended-primary-fences
tutorial_expectation: deutsch-classification
tutorial_evidence: intended-ideal-execution
---

# Contract Machine

Without its controls, the contract machine was an unremarkable rack. Optical ports crossed the front plate. One status lamp
answered them. Beneath the new finish, the old survey-locker inventory remained faintly legible, anchors, oxygen, drilling charges.

Among those dead promises, cut deep enough to survive another reuse, stood the living one:

```text
Uf |x,y> = |x, y xor f(x)>
```

The machine accepted input bit `x` and target bit `y`. For a fixed Boolean function `f`, it preserved `x` and flipped `y` whenever
`f(x)` was one. Nothing on the plate promised how `f` was built, what it cost, or whether anyone should care.

"An oracle," Mara said, with the disappointment of someone shown a very small cabinet after hearing a very large word.

The cabinet answered with its entire vocabulary.

```text
ORACLE READY
calls remaining: 1
```

Sable's first crews had called their thermal-fracture forecaster an *oracle*. It displayed a risk color and concealed the mapping,
assumptions, geology. When a forecast failed, the vendor explained that Sable's captured-rock strata fell outside the service
boundary. No such boundary had appeared on the camp display.

Afterward, the cooperative required every machine promise to fit on a plate durable enough to outlive vendor, housing, and brand.
The quantum engineers kept *oracle* only after engraving the callable map where nobody could confuse it with prophecy.

An **oracle** was a callable input-output map. It volunteered no explanation. If the map was difficult, somebody still had to build
the difficulty into the box.

Behind an opaque screen, Iona loaded one of the possible one-bit functions. Sana sealed the implementation digest before anyone
predicted. The crew did not know the answer. The record did.

Ignorance was part of the test. Missing parentage would have been a fault.

| Function | `f(0)` | `f(1)` | Class |
| --- | ---: | ---: | --- |
| zero | `0` | `0` | constant |
| one | `1` | `1` | constant |
| identity | `0` | `1` | balanced |
| negation | `1` | `0` | balanced |

The promise allowed two classes. A **constant** function gave the same output twice. A **balanced** one gave different outputs. Ask
for only one input and either class might answer zero or one. Classically, both inputs were needed.

The quantum circuit would call the oracle once. Tala disliked the restriction. In transit work she queried a system until enough
records accumulated to betray it. Here they had to shape one interaction so equality or difference became visible while the
individual values did not.

"One question," she said.

"One paid question," Iona corrected.

Mara nodded. Cost had supplied the first explanation she trusted immediately.

Its target qubit began in `|1>` and passed through `H`.

```text
H|1> = (|0> - |1>) / sqrt(2)
```

This state, often written `|->`, had a useful response to `X`.

```text
X|-> = -|->
```

A flip changed only the target's global sign. Make that flip conditional on the input, however, and the sign became relative between
input alternatives. The target returned locally unchanged. The function value appeared as phase on the joint state.

```text
|x>|->  ->  (-1)^f(x) |x>|->
```

This was **phase kickback**. Nothing traveled backward. The name survived from diagrams whose arrows suggested otherwise. Iona
crossed out the arrows and kept the diagrams: scars were sometimes better teachers than clean paper.

The controlled operation had placed phase on the amplitude associated with its control.

Tala prepared the input in an equal superposition, giving both promised function values a place to affect relative phase. For a
constant function, both input amplitudes acquired the same sign.

```text
(+,+) or (-,-)
```

A final Hadamard sent either common-sign pattern to input outcome `0`. `(+,+)` and `(-,-)` still differed only globally: no
measurement here could tell them apart.

```wheeler
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

The final Hadamard made either relative-sign pattern visible as `1`.

```wheeler
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
the source and guessed wrong once.

"The left relay sounded balanced," she said.

"The left relay is cooling," Iona replied.

The result showed that coolant relays leaked less useful information than a pilot might hope.

Without sampling uncertainty, the ideal runs separated the promise classes.

```text
DeutschConstant  result = 0
DeutschBalanced  result = 1
```

One call answered a question about the relation between two function values. The circuit had not read both in parallel or extracted
the hidden table. It arranged the phase so that equality versus difference survived interference. The values themselves fell
away.

The tiny classification had no operational value at Sable. That was its virtue. The whole promised world fit in one table. A
person could follow every contribution by hand. The station kept the module for the reason Catenary kept hand pumps beside automated water
walls: small working things expose what large working things conceal.

Sana kept the promise, the oracle's map, its hidden implementation, the calling circuit, and the final outcome in separate records.
Calling the whole bundle *the algorithm* would make later questions impossible to ask cleanly.

While she worked, a delayed message arrived from Catenary. Neris Venn, now director of traffic continuity, had signed it. The
particle front had accelerated within forecast.

The retuning deadline moved forward.

The request named the physical sample, the intended application, and the chain between them. Six years earlier Venn had trusted a
green transit display that hid fourteen cars. Tala could not tell whether the new care came from that failure or some later policy.
It did not matter. The care was here.

No one at Sable could hurry light. They could only finish before the deadline, and leave Catenary no honest reason to refuse the
result.

After both cases passed, the contract machine unlocked its next module. Behind the panel lay a four-state search space and one
marked basis value, small enough to inspect completely and large enough to demonstrate amplification.

Behind the open panel lay [Search](10-search.md).
