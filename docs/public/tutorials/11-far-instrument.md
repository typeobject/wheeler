---
sidebar_position: 12
title: Far Instrument
description: A trusted transform fails forward, passes backward, and forces the far instrument to ask a better question.
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

The main array occupied the oldest truss still in service. Timing heads faced the sky at fixed angles, divided by black vanes taller
than a person. From the gallery they appeared as pale outlines against Sable's dark.

Catenary sent two related references across the reach. A narrow optical signal carried the rhythm of its best clocks. Microwave
carriers carried the navigation signal ships used on approach.

Charged clouds delayed those carriers differently at different frequencies. Radiation and temperature shifted clocks and
circuits. One late pulse, seen alone, could not say which cause had moved it.

Sable compared both references against its own clocks and against the charged environment around it. Its wide orbit often met the
weather before the inner traffic lanes did. The quantum circuit would not predict the storm. The array had a narrower duty: tease
clock drift apart from travel delay before Catenary mistook both for one correction.

Every pulse arriving at Sable described Catenary minutes ago. Meanwhile Sable's clocks had moved on. Emission, travel, comparison,
observation: the calibration had to keep those moments apart, or distance itself would masquerade as error.

The three-qubit circuit was not the mission instrument. It was the smallest version that exercised register order, phase signs,
target translation, and the generated adjoint on the real control stack. The mission used a larger register coupled to the clock.

A small test mattered because a circuit could reverse its own indexing mistake perfectly: beautiful return, useless transform.

Sable's watches bent around the pulses. One arrival could wake the target crew, postpone a meal, claim the machine shop, before
anyone knew whether its data was usable.

The sky kept time. The log kept order.

For one qubit, the required transform was already familiar. The quantum Fourier transform over two basis states mapped

```text
|0> -> (|0> + |1>) / sqrt(2)
|1> -> (|0> - |1>) / sqrt(2)
```

Hadamard. The smallest QFT had been with them since the first interference experiment, waiting for the family resemblance to become
visible.

With two qubits came four basis states. Their Fourier phases advanced by quarter-turns around the complex plane. Hadamard supplied
the equal magnitudes. Controlled phase supplied the angle that depended on the neighboring bit.

Iona projected the inherited gate sequence onto the gallery glass. Outside, suited technicians closed the final thermal links.
Their lamps moved behind the source like slow punctuation.

The sequence began with `H(q[0])`. Tala traced basis input `1`.

Expected: `0, pi/2, pi, 3*pi/2`.

Produced: `0, 0, pi, pi`.

She traced it again. Slower.

"I have the wrong table."

Iona took the table. Osei took the gates. Sana opened the source history. Mara watched the chamber clock. Time had not joined their
surprise.

"The round trip passed," Osei said.

"Of course it passed," Sana replied. "The adjoint can reverse the wrong transform perfectly."

The structural certificate was valid. The generated adjoint truly reversed the forward body.

The forward body was wrong.

For three minutes, Sable possessed a beautifully documented mistake.

The error was significance order. Wheeler read `q[0]` as the low bit. The old circuit had begun there. They turned the construction
around. High bit first.

```wheeler
unitary void qft2() {
  H(q[1]);
  CPhase(q[0], q[1], pi / 2);
  H(q[0]);
  Swap(q[0], q[1]);
}
```

`pi / 2` meant one exact quarter-turn. The source kept the angle symbolic. Later, a target plan would approximate it with timed
controls. The approximation would belong to the machine plan, not creep backward into the mathematics.

`CPhase` turned only the component where both selected qubits were one. The final swap restored the expected bit order.

Tala traced every basis input. Equal magnitudes, every row. Different phases, every input. The quarter-turns that once looked like
ornament now separated patterns she could predict by hand.

Around her, nobody watched the same machine. Vane temperatures on one screen. Clock discipline on another. Iona held the target
plan, Osei the resources, Sana the chain of records. The transform had one mathematical body and many physical dependencies.

| Input integer | Output phase steps around four basis rows |
| ---: | --- |
| `0` | `0, 0, 0, 0` |
| `1` | `0, pi/2, pi, 3*pi/2` |
| `2` | `0, pi, 0, pi` |
| `3` | `0, 3*pi/2, pi, pi/2` |

The table was the four-point discrete Fourier transform. Measuring it directly would still yield one basis outcome. Its use came
when another procedure laid down a regular phase pattern first. Under the transform, that pattern could gather into a narrow set of
outcomes.

The qualification transform extended the pattern to three qubits, adding quarter- and eighth-turns. Once its order and signs were
settled, the mission planner could extend the construction across sixteen positions.

The small body had traveled between Catenary and Sable for six years. In its history Osei found one of his own comments, and Iona's
answer, eighteen months old.

"I attached the proof," she said.

"You attached a statement ending in *obvious*."

"Then you were motivated to check it."

They had written the first version while sharing quarters and trading target watch. Then Osei accepted a year-long refit at
Catenary. Iona asked him not to promise a return date he did not control. The year filled with other jobs, jobs he chose. She stopped
keeping his place empty.

They had loved each other. Distance made that neither false nor sufficient. The code continued to travel between them. Code was
easier to merge than a life.

The corrected body contained neither comment.

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

Each gate now had a reason. `H` supplied the one-qubit transform. `pi/2` joined neighboring significance levels. `pi/4` reached
across one level. The swap repaired output order. Most important, the new amplitude check examined the forward transform itself,
not merely its talent for undoing its own mistake.

Wheeler generated the adjoint by reversing the gate sequence and replacing every gate with its adjoint. Hadamard, swap, and the
controlled-phase structure retained their subjects, while each phase angle changed sign.

```text
forward: H(q2), CPhase(q1,q2,+pi/2), CPhase(q0,q2,+pi/4),
         H(q1), CPhase(q0,q1,+pi/2), H(q0), Swap(q0,q2)
adjoint: Swap(q0,q2), H(q0), CPhase(q0,q1,-pi/2), H(q1),
         CPhase(q0,q2,-pi/4), CPhase(q1,q2,-pi/2), H(q2)
```

Mathematically, the adjoint restored every possible input, not only basis value five. The fixture chose five so a nonzero state
would pass through forward gates, adjoint, and measurement. But forward-then-back could never expose a forward transform that was
wrong in a perfectly reversible way.

They had just paid for that lesson in chamber time.

Mara entered the expected result before execution. The number looked arbitrary to her until Tala traced its three low-order bits
through the register order. Then it looked specific, which was more useful.

```text
QFT (quantum) halted after 6 steps
measured = 5
measurements = [5]
```

Beside the adjoint, the compiler emitted a structural certificate. It tied the source body to the lowered circuit, its gate order
and angles, and the rule used to reverse each operation.

```text
certificate kind: GENERATED_ADJOINT
subject: QFT.qft
claim: generated body is the structural adjoint of the bound forward body
status: verified
```

The certificate established one thing: this generated body was the adjoint of this forward body. The run showed restoration for
basis value five. The amplitude table checked the small transform row by row. A theorem about QFT for every normalized input would
need a broader statement.

The records sat beside one another. None was allowed to wear another's authority.

Mara read the corrected record list. "Which one tells me we fixed the mistake?"

"The amplitude comparison," Tala said.

"Which one tells me we can undo the fix?"

"The structural certificate."

"Which one gets my chamber reservation back?"

Nobody answered. Some losses remained outside the proof system.

Tala had heard managers ask whether a system was *verified*, as though verification were varnish. These separate answers felt less
satisfying, and truer.

Sana sealed the source, compiled artifact, run, amplitude comparison, and certificate separately. Then she used Edrin's pattern: a
manifest preserving their parentage before the routine logs were compressed.

Only then did Iona open the mission procedure.

The optical-clock comparison would place an unknown relative phase on a control register. One qubit would feel the comparison once.
the next, twice. Each after that, twice as long again. Across the register, the unknown angle would write a regular pattern.

Direct measurement would scatter the pattern into useless outcomes. The inverse QFT made those phases interfere and gather near the
integer representing the angle. Ordinary timestamps located the whole clock cycle. Each control qubit doubled the finer divisions.
sixteen divided the remaining cycle into 65,536 bins, as long as coherence held.

The comparison would repeat across timing heads and carrier frequencies. Afterward, ordinary software would combine optical phase
with microwave delay, particle counts, and magnetic measurements.

The quantum target would make one kind of observation. It would not choose Catenary's correction.

Iona named the artifact `BeaconPhaseEstimate.wbc`. Its justification was not a grand claim of advantage. Coherent phase was simply
the quantity this instrument had been built to compare.

They had checked the transform forward, backward, and against its theorem. They did not yet possess the physical observations
Catenary required.

Mara pointed out that everything so far had happened inside a simulator. Below them waited the chamber: its gates, queue, aging
calibration, noise, appetite for time.

The revised deadline left one window.

Iona led them down pressure stairs older than the spin section. Gravity weakened at every landing. At the final hatch, refrigeration
beat through the handrail. Beneath that: a slower flex, the whole truss answering Sable's uneven pull.

On the chamber door, environmental monitors condensed those differences into one word.

```text
WEATHER
```

Beyond the hatch waited [Weather](12-weather.md).
