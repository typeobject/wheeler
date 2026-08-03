---
sidebar_position: 12
title: The Far Instrument
description: Hadamard grows into the three-qubit quantum Fourier transform, its adjoint, and a structural certificate.
tutorial_id: CH11
tutorial_steps: T79,T80,T81,T82
tutorial_part: quantum-fourier-transform
tutorial_order: 11
tutorial_kind: exact-quantum-algorithm-and-certificate
tutorial_source: source-backed-capstone
tutorial_expectation: qft-adjoint-restoration
tutorial_evidence: exact-ideal-execution-and-finite-certificate
---

# The Far Instrument

The main array occupied the instrument's oldest surviving truss. Its eight timing heads faced the sky at measured angles, each one
shielded from the others by black vanes taller than a person. From the interior gallery, the heads appeared only as pale outlines
against Sable. Their purpose was to compare periodic phase patterns in the beacon reference received from Catenary and change the
basis in which those patterns became visible.

No person at the far instrument claimed that this three-qubit calibration kernel created a practical advantage over every
classical method. It existed because the target, transform, and evidence chain were small enough to certify completely before the
same hardware joined larger experiments. Catenary needed that certification to trust which part of the approaching beacon drift
belonged to its clocks and which part belonged to physical weather.

For one qubit, the required transform was already familiar. The quantum Fourier transform over two basis states mapped

```text
|0> -> (|0> + |1>) / sqrt(2)
|1> -> (|0> - |1>) / sqrt(2)
```

That was Hadamard. The smallest QFT had been present since the first interference experiment, waiting for a larger family to give
it a surname.

For two qubits, four basis states replaced two. Their Fourier phases advanced in quarter turns around the complex plane. Hadamard
still created equal magnitudes, while a controlled phase supplied the relative angle that depended on the other qubit.

Iona projected the gate sequence on the gallery glass. Beyond it, technicians walked the outer truss in pressure suits, closing the
last thermal links before calibration. Their suit lamps passed behind the source as slow moving punctuation.

```java
unitary void qft2() {
  H(q[0]);
  CPhase(q[1], q[0], 1.5707963267948966);
  H(q[1]);
  Swap(q[0], q[1]);
}
```

The angle `pi/2` described one quarter turn. `CPhase` applied it only to the basis component in which both selected qubits were
one. The final swap placed the transformed bits in canonical order.

Tala traced each basis input through an amplitude table. Equal magnitudes appeared in all four rows. What changed from input to
input was the sequence of phases. The quarter turns that had looked ornamental when first drawn as complex arrows now distinguished
rows she could predict.

| Input integer | Output phase steps around four basis rows |
| ---: | --- |
| `0` | `0, 0, 0, 0` |
| `1` | `0, pi/2, pi, 3*pi/2` |
| `2` | `0, pi, 0, pi` |
| `3` | `0, 3*pi/2, pi, pi/2` |

In quantum amplitudes, the table expressed the four-point discrete Fourier transform. Measurement of the transformed state still
returned one basis outcome. The transform became useful when a larger algorithm arranged phase structure that concentrated under
this change of basis.

For its operational transform, the far instrument used three qubits and extended the same construction with half and quarter
turns. The checked source had passed between Catenary and Sable for six years. Osei recognized one of his old comments in its
history and discovered that Iona had resolved it eighteen months earlier without telling him.

"I attached the proof," she said.

"You attached a statement ending in *obvious*."

"Then you were motivated to check it."

They had written the first version while sharing quarters on Sable and trading target watch between them. When Osei accepted a
year-long refit at Catenary, Iona asked him not to promise a return date he did not control. The year became a succession of jobs
he chose. Iona chose not to keep his place empty.

They had loved each other. Nothing that followed made that false, and nothing about its truth required Iona to have waited. Their
source had continued to accept revisions from both locations because source possessed an update procedure. A shared life did not.

The current body contained neither comment.

```java
quantum class QFT {
  state long measured = 0;
  qreg q = new qreg(3);

  unitary void qft() {
    H(q[0]);
    CPhase(q[1], q[0], 1.5707963267948966);
    CPhase(q[2], q[0], 0.7853981633974483);
    H(q[1]);
    CPhase(q[2], q[1], 1.5707963267948966);
    H(q[2]);
    Swap(q[0], q[2]);
  }

  entry void main() {
    prepare(q, 5);
    qft();
    reverse qft();
    measured = measure(q);
    assert(measured == 5);
  }
}
```

Nothing in the listing now arrived without preparation. `H` supplied the one-qubit Fourier transform. The `pi/2` controlled phases
joined neighboring significance levels. The `pi/4` phase joined levels two positions apart. The swap corrected output order.

Wheeler generated the adjoint by reversing the gate sequence and replacing every gate with its adjoint. Hadamard, swap, and the
controlled-phase structure retained their subjects, while each phase angle changed sign.

```text
forward: H, CPhase(+pi/2), CPhase(+pi/4), H, CPhase(+pi/2), H, Swap
adjoint: Swap, H, CPhase(-pi/2), H, CPhase(-pi/4), CPhase(-pi/2), H
```

Under the accepted unitary semantics, applying the adjoint immediately after the forward transform restored every possible input
state, not only basis value five. The executable fixture selected five so that one bounded run could expose indexing, phase, and
swap mistakes.

Mara entered the expected result before execution. The number looked arbitrary to her until Tala traced its three low-order bits
through the register order. Then it looked specific, which was more useful.

```text
QFT (quantum) halted
measured = 5
measurements = [5]
```

Alongside the generated adjoint, the compiler emitted a finite structural certificate. It bound the exact source body, lowered
circuit identity, ordered gate subjects, angle encodings, and the rule that generated each reversed operation.

```text
certificate kind: GENERATED_ADJOINT
subject: QFT.qft
claim: generated body is the structural adjoint of the bound forward body
status: verified
```

For that artifact, the certificate proved its named structural claim. The successful run supplied executable restoration evidence
for one prepared basis state. A general theorem about the mathematical QFT required a proposition covering all normalized inputs
and the transform's full specification. None of the three objects borrowed scope from the others.

Tala had spent years watching managers ask whether a system was *verified* as though verification were a liquid poured into the
whole machine. The separate records felt less satisfying and more honest: one run, one structural claim, one still-unanswered
general proposition.

Sana sealed the source identity, artifact identity, run report, and certificate as separate records. Following the pattern Edrin
had shown her, she added a pre-commit manifest that preserved every edge before routine log compaction. Iona attached the pending
calibration plan, which depended on the forward transform but not on the later demonstration of its adjoint.

They now possessed the verified semantic route for the work they had come to do. They did not yet possess the physical evidence
Catenary required.

Mara pointed out that every result so far had lived inside an ideal simulator attached to the instrument. The physical target
waited in a shielded chamber below, with its own gate set, queue, calibration age, noise, and appetite for time. The revised deadline
from home left them one accepted chamber window.

Iona led them downward through pressure stairs built before the spin section. Gravity weakened at each landing. At the final hatch,
Tala could feel the beat of refrigeration through the handrail and, beneath it, the slower flex of the entire truss as Sable pulled
unevenly on the station.

On the chamber door, environmental monitors condensed those differences into one word.

```text
WEATHER
```

There the final chapter began: [Weather](12-weather.md).
