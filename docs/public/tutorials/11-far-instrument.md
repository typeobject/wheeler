---
sidebar_position: 12
title: Far Instrument
description: An inherited QFT reverses its own mistake while Sable's chamber clock charges everyone for finding it.
tutorial_id: CH11
tutorial_steps: T79,T80,T81,T82
tutorial_part: quantum-fourier-transform
tutorial_order: 11
tutorial_kind: current-kernel-and-intended-symbolic-source
tutorial_source: current-capstone-with-intended-extension
tutorial_expectation: qft-definition-and-adjoint-restoration
tutorial_evidence: current-ideal-model-and-intended-symbolic-certificate
---

# Far Instrument

Beyond the algorithm racks, the maintenance bridge narrowed into Sable's oldest
surviving truss. Tala followed Iona until it opened into the main-array gallery.
At the far end, a pressure stair descended toward the physical chamber.

Black vanes taller than Tala separated timing heads fixed toward the sky. Through
the gallery glass, their edges drew a pale geometry against the moon below.

Two references traveled outward from Catenary. A narrow optical link carried its finest clock rhythm, while microwave carriers bore
the navigation signal used by approaching ships.

Charged weather changed microwave travel by frequency. Temperature and radiation could also shift the clocks and control circuits.
A late pulse carried no label identifying the cause of its delay.

Sable compared both references against its own clocks and against the charged
environment around it. Its wide orbit often met the weather before the inner
traffic lanes did. The array's duty was to tease clock drift apart from travel
delay before Catenary mistook both for one correction. Forecasting the storm
belonged to a larger chain of instruments.

An arriving pulse described Catenary at emission, minutes before Sable observed it. Sable's clocks continued during travel. The
calibration had to distinguish emission time, propagation, local comparison, and observation so that distance did not appear as
clock error.

The three-qubit circuit served as the smallest qualification of register order,
phase signs, target translation, and the generated adjoint on the real control
stack. The mission used a larger register coupled to the clock.

A circuit with wrong indexing could still reverse itself perfectly. Round-trip beauty offered no evidence that the forward
transform was useful.

Instrument watches followed incoming reference pulses. One arrival could wake a crew, displace a meal, and claim machine-shop
cooling before anyone established whether the observation would serve.

The sky determined the opportunity, and the mission account preserved its sequence.

They already knew the one-qubit member of the required family. Over two basis states, the quantum Fourier transform mapped

```text
|0> -> (|0> + |1>) / sqrt(2)
|1> -> (|0> - |1>) / sqrt(2)
```

Those rows were Hadamard. The smallest QFT had appeared in their first interference work before they knew which larger construction
it belonged to.

Two qubits expanded the transform to four rows whose phases advanced in quarter turns. Hadamard established equal magnitude;
controlled phase supplied angles determined by neighboring significance bits.

Iona projected the inherited source across the gallery window. Beyond its lines, suited technicians closed thermal links and moved
their work lamps through the gate sequence.

The old body began at low-order `q[0]`. Tala followed basis input `1` through every gate.

The Fourier row required phases `0, pi/2, pi, 3*pi/2`.

The inherited body produced `0, 0, pi, pi`.

Tala repeated the trace at half speed.

"My result disagrees with the Fourier table."

Iona verified the expected row, Osei traced gate order, and Sana opened source lineage. Mara kept her eyes on the reservation clock,
which continued through their surprise.

"Forward and adjoint still restore," Osei said.

"Restoration answers a different question," Sana said. "The adjoint faithfully reverses this incorrect body."

The structural certificate remained valid because adjoint generation had faithfully reversed its bound gate sequence.

That bound sequence failed to implement the intended QFT.

Sable spent three chamber minutes establishing the ancestry of an error.

The chamber clock continued beneath it. Cooling had already claimed the machine
shop. Venn's legacy-profile notice remained in one corner of the gallery glass,
small beside the source and heavier than either. Mara did not tell anyone to
hurry. She moved the abort threshold forward by three minutes and let every
specialist see the price.

Register significance caused the failure. Wheeler treated `q[0]` as low order, while the inherited construction began its gates
there. They reversed the construction and started from the high bit.

```wheeler
unitary void qft2() {
  H(q[1]);
  CPhase(q[0], q[1], pi / 2);
  H(q[0]);
  Swap(q[0], q[1]);
}
```

The symbolic angle `pi / 2` represented an exact quarter turn. A physical plan would later approximate that angle through timed
controls. Keeping the approximation in the target plan preserved the mathematical source.

`CPhase` rotated the amplitude component on which both selected qubits had basis value one. The concluding swap corrected output
order.

Tala checked every basis input and found equal magnitudes with the required phase progression in each row. Controlled quarter turns
now separated hand-checkable patterns instead of decorating the circuit.

Each officer watched a different dependency. Iona held the machine plan, Osei tracked allocated resources, and Sana maintained the
evidence chain while thermal vanes and clock discipline occupied separate panes. One mathematical body crossed many physical
duties.

| Input integer | Output phase steps around four basis rows |
| ---: | --- |
| `0` | `0, 0, 0, 0` |
| `1` | `0, pi/2, pi, 3*pi/2` |
| `2` | `0, pi, 0, pi` |
| `3` | `0, 3*pi/2, pi, pi/2` |

The verified rows formed the four-point discrete Fourier transform. Direct measurement would still return one basis value. The
transform became useful after another procedure encoded a regular phase pattern, allowing interference to gather that pattern near
a smaller set of outcomes.

The qualification body extended the construction to three qubits and included quarter- and eighth-turn phases. Once signs and
significance were verified there, planning could extend it to the mission's sixteen positions.

Six years of transfers between Catenary and Sable lived in the source history. Osei found his own comment beside Iona's answer from
eighteen months earlier.

"My reply included the proof," Iona said.

"Your proof concluded with the word *obvious*."

"It has now produced the intended motivation."

Tala expanded the old commit metadata. The first body alternated their names on
successive target watches and gave both the same quarters address. A later branch
began at Catenary under Osei alone.

"The refit was supposed to take a year," he said.

Iona kept her eyes on the source. "I asked you not to promise a date you did not
control. I did not ask you to fill six years with work."

The blue cup in Sable's galley had already told Tala that affection survived.
This exchange told her what it could not repair. Code had continued crossing the
Reach because a merge required fewer promises than a shared life.

Osei deleted his old comment. Iona deleted hers.

```wheeler
quantum class QFT {
  const long QUBITS = 3;
  state long measured = 0;
  qreg q = new qreg(QUBITS);

  unitary void qft() {
    H(q[2]);
    CPhase(q[1], q[2], pi / 2);
    CPhase(q[0], q[2], pi / 4);
    H(q[1]);
    CPhase(q[0], q[1], pi / 2);
    H(q[0]);
    Swap(q[0], q[2]);
  }

  theorem qftAdjoint proves adjoint(qft);

  entry void main() {
    prepare(q, 5);
    qft();
    reverse qft();
    measured = measure(q);
    assert(measured == 5);
  }
}
```

The new order exposed each gate's role. `H` supplied the local Fourier step, `pi/2` connected adjacent significance levels, and
`pi/4` reached across one level. Swap restored output order. Forward amplitude comparisons now tested the transform's definition
rather than only its ability to reverse itself.

Adjoint generation reversed gate order and substituted each gate's adjoint. Hadamard and swap remained self-adjoint. Controlled
phase kept its qubit subjects while negating the angle.

```text
forward: H(q2), CPhase(q1,q2,+pi/2), CPhase(q0,q2,+pi/4),
         H(q1), CPhase(q0,q1,+pi/2), H(q0), Swap(q0,q2)
adjoint: Swap(q0,q2), H(q0), CPhase(q0,q1,-pi/2), H(q1),
         CPhase(q0,q2,-pi/4), CPhase(q1,q2,-pi/2), H(q2)
```

The adjoint law covered every allowed input, though the executable fixture selected nonzero basis value five. That run exercised
forward gates, generated adjoint, and measurement on one value. Any forward-then-adjoint check remained incapable of detecting a
consistently invertible wrong transform.

The reservation clock had charged them for learning the distinction.

Mara recorded expected value five before running the fixture. Tala traced its three bits through Wheeler's low-order convention,
turning an arbitrary-looking numeral into a specific register state.

```text
QFT (quantum) halted after 6 steps
measured = 5
measurements = [5]
```

The compiler emitted a structural certificate with the generated adjoint. It bound source to lowered circuit, listed gate order and
angles, and identified every adjoint rule used.

```text
certificate kind: GENERATED_ADJOINT
subject: QFT.qft
claim: generated body is the structural adjoint of the bound forward body
status: verified
```

Certificate evidence established that the generated body was the structural adjoint of its bound forward body. Execution restored
basis value five. The amplitude comparison covered the small transform's basis rows. A universal QFT statement over normalized
inputs required theorem evidence.

Sana arranged the evidence side by side and kept each item within its own authority.

Mara read the list. "Where is the evidence that addresses our original error?"

"The forward amplitude rows," Tala answered.

"What establishes the generated way back?"

"The structural adjoint certificate."

"Which evidence restores the three minutes?"

No proof proposition addressed spent chamber time.

Transit managers had used *verified* as a finish applied to whole systems. These separate pieces of evidence denied Tala that comfort
and gave her sharper answers.

Sana sealed source, artifact, execution, amplitude comparison, and certificate under separate identities. Before compressing
routine logs, she used Edrin's manifest pattern to preserve their parentage.

With the source and its evidence sealed, Iona opened the mission procedure.

The optical-clock comparison would place an unknown relative phase on a control register. One qubit would feel the comparison once.
The next would feel it twice. Each after that, twice as long again. Across the register, the unknown angle would write a regular pattern.

Direct measurement would scatter the pattern into useless outcomes. The inverse QFT made those phases interfere and gather near the
integer representing the angle. Ordinary timestamps located the whole clock cycle. Each control qubit doubled the finer divisions.
Sixteen qubits divided the remaining cycle into 65,536 bins, as long as coherence held.

The procedure would repeat over multiple timing heads and carrier frequencies.
Classical reduction would then join optical phase to microwave delay, local
particle counts, and magnetic observations.

This was the bargain at the heart of the Second Navigation. Sable would make one
kind of observation under its own instrument charter. Catenary would choose the
traffic correction and remain answerable for that choice.

Iona named the artifact `BeaconPhaseEstimate.wbc`. Its justification remained practical: the instrument had been built to compare
coherent phase.

Forward rows addressed the transform, and the generated adjoint addressed its road back. Sana still had the broader definition
theorem open. Catenary required observations from the physical chamber.

Mara indicated the target status below. Every result so far belonged to simulation. Physical gates, queue state, calibration age,
noise, and elapsed time waited behind the chamber door.

Venn's revised deadline and Sable's cooling cycle overlapped once.

Iona descended pressure stairs older than the station's spin. Each landing weakened gravity. At the last hatch, refrigeration
vibrated through the rail above the slower flex of a truss answering Sable's irregular pull.

Environmental monitors gathered the chamber's present differences under one status.

```text
WEATHER
```

The hatch opened onto [Weather](12-weather.md).
