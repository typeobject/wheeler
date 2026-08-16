---
sidebar_position: 10
title: Contract Machine
description: An oracle plate, one paid call, and Venn's advancing deadline turn a Boolean promise into relative phase.
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

On the next crossing, Tala's left hand found the rail weld with Osei's mark
before she looked down. Sable filled the clear floor until Iona opened the
algorithm-rack door and station structure closed around them.

The contract machine stood immediately inside: an ordinary equipment rack with
optical ports and one status lamp. Beneath recent paint, Tala could still read the
inventory from its first life as a survey locker: anchors, oxygen, drilling
charges.

A newer inscription had been cut deeply enough to survive its next use.

```text
Uf |x,y> = |x, y xor f(x)>
```

For fixed Boolean function `f`, the map preserved input `x` and XORed `f(x)` into target `y`. The plate described no implementation
cost, internal construction, or useful purpose.

"This cabinet is the oracle?" Mara asked. The noun had promised her more architecture.

Its status lamp supplied the only available reply.

```text
ORACLE READY
calls remaining: 1
```

Sable's first charter crews had called their thermal-fracture forecaster an
*oracle*. It displayed a risk color and concealed the mapping, assumptions, and
geology. When a forecast failed, the vendor explained that Sable's captured-rock
strata fell outside the service boundary. The camp display had carried no such
warning, and the vendor's charter ended before the repairs did.

The cooperative later required every callable promise to fit on a plate that could outlast vendor and enclosure. Quantum engineers
retained the inherited word *oracle* after placing its complete map where prophecy could not hide inside it.

An **oracle** supplied a callable input-output map and no explanation of its internals. Any computational difficulty remained real;
someone had to implement it behind the interface.

Iona selected one allowed one-bit function behind an opaque screen. Sana sealed its implementation digest before collecting
predictions. The choice remained hidden from the crew and fixed in the record.

The experiment required their ignorance. The evidence required known parentage.

| Function | `f(0)` | `f(1)` | Class |
| --- | ---: | ---: | --- |
| zero | `0` | `0` | constant |
| one | `1` | `1` | constant |
| identity | `0` | `1` | balanced |
| negation | `1` | `0` | balanced |

The promise divided the allowed functions into two classes. A **constant** function returned one shared value for both inputs; a
**balanced** function returned one of each value. One classical query could receive zero or one from either class, so classical
classification required both inputs.

The quantum procedure permitted one oracle call. Tala's transit practice had been to accumulate queries until inconsistency exposed
itself. Here she had to arrange one interaction so the relation between two function values survived while the values themselves
did not.

"We receive one question."

"The station pays for one call," Iona said.

Physical cost made the restriction immediately credible to Mara.

They prepared the target qubit in `|1>` and applied `H`.

```text
H|1> = (|0> - |1>) / sqrt(2)
```

The resulting state, written `|->`, responded to `X` by acquiring a global sign.

```text
X|-> = -|->
```

An unconditional flip changed only global phase on the target. Conditioning that flip on input made the sign differ across input
alternatives. The target's local state returned unchanged while the joint amplitudes carried `f(x)` in phase.

```text
|x>|->  ->  (-1)^f(x) |x>|->
```

The effect was called **phase kickback**, though nothing propagated backward. Old diagrams had encouraged that mistake with
backward arrows. Iona struck out the arrows and preserved the marked pages so their error could remain visible.

Control-dependent phase now belonged to the corresponding input amplitude.

An equal input superposition exposed amplitude components for both promised values. Under a constant function, those components
received matching signs.

```text
(+,+) or (-,-)
```

The final Hadamard mapped either shared-sign pattern to measured input `0`. Patterns `(+,+)` and `(-,-)` differed by global phase,
which this measurement could not distinguish.

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

With `prepare(q, 2)`, low-order input `q[0]` began at zero and target `q[1]` at one. An empty oracle represented constant zero. A
constant-one implementation would apply `X` to the target and differ only by the unobservable global sign in this procedure.

A balanced function assigned opposite signs to the input amplitude components.

```text
(+,-) or (-,+)
```

The last Hadamard converted either opposing-sign pattern into input outcome `1`.

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

CNOT supplied the identity oracle because it flipped the target when `q[0]` was one. A negation oracle would create the other
relative-sign pattern and retain the same balanced classification.

Iona concealed which case occupied the rack. Mara ignored the source, listened to the controls, and misclassified one run.

"The left relay has a balanced sound," Mara said.

"The left relay operates refrigeration."

Cooling hardware had revealed less about the oracle than Mara's ear requested.

The ideal executions classified both promised cases without sampling uncertainty.

```text
DeutschConstant  result = 0
DeutschBalanced  result = 1
```

One oracle call answered whether the two function values agreed. The circuit neither read both values in parallel nor recovered the
hidden table. It encoded their equality relation in phase, then used interference to preserve the classification while discarding
the individual values.

Sable gained no operational advantage from the tiny classification. Its value lay in a complete four-row world whose amplitudes
could be followed by hand. The station kept it as Catenary kept hand pumps beside automated water walls: a small mechanism exposed
the law hidden by larger machinery.

Sana preserved separate identities for the promise, callable map, hidden implementation, calling circuit, and result. Collapsing
them under *algorithm* would obstruct later questions about which part had failed.

A delayed Catenary message arrived while Sana completed the chain. Neris Venn had signed it as director of traffic continuity. The
charged front was accelerating within its forecast range.

Traffic control advanced the beacon-retuning deadline.

The request named the physical sample, the intended application, and the chain
between them. An attached traffic plan showed the cost of failure. Catenary could
keep the old beacon profile through the charged front by widening every approach
interval. Ore and passengers would arrive. Air catalysts and garden trace metals
would wait in outer orbits.

The Second Navigation had taught Catenary that a common standard would fail if
distant observations arrived as anonymous authority. Six years earlier Venn had
trusted a green transit display that hid fourteen cars. Tala could not tell
whether the new care came from that failure or some later policy. The care was
here. She read Venn's signature three times and found that correction could
travel without apology.

Sable could neither shorten light travel nor extend Catenary's traffic margins. Its crew could finish within the remaining window
and make every link required for honest acceptance.

After both classifications passed, the rack released another module. It contained four basis states and one phase-marked value,
allowing complete inspection of amplitude amplification.

The abandoned camp names on its channels opened into [Search](10-search.md).
