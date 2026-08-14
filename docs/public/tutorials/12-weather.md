---
sidebar_position: 13
title: Weather
description: In the chamber, mathematics meets weather. On the way home, every kind of return must answer for itself.
tutorial_id: CH12
tutorial_steps: T83,T84,T85,T86,T87,T88,T89,T90,T91,T92,T93
tutorial_part: targets-and-evidence
tutorial_order: 12
tutorial_kind: intended-complete-hybrid-execution
tutorial_source: current-and-intended-capstones
tutorial_expectation: auditable-return
tutorial_evidence: intended-hardware-workflow-and-formal-records
---

# Weather

The physical target occupied three decks and answered through one interface.

Pumps held the vacuum. Refrigeration lifted heat through shield within shield. Control racks turned scheduled pulses into fields,
and the fields went slightly wrong in ways that had to be measured. From the gallery, a quantum run looked less like mathematics
than a truce among incompatible temperatures.

The residents took their places. A coolant bypass closed by hand while the controls watched. Someone lifted a family photograph
from a rack that would shake during pump-down. There was no ceremonial silence: seals, tools, the warm bearing and whether its risk
belonged to tonight or tomorrow.

Years from Catenary, the frontier was mostly maintenance performed before a fault became interesting.

The simulator and chamber understood the same Wheeler operations. They could not show the same things. The simulator exposed a
state vector inside its numerical model. The chamber returned outcomes, times, calibration, uncertainty. Naming amplitudes in
source did not make hardware reveal them.

Before submission, Sana separated the kinds of record.

| Record | What it could show |
| --- | --- |
| classical execution | what one deterministic run did with a particular program and input |
| ideal state vector | amplitudes inside the named simulator and numerical profile |
| seeded simulation | reproducible counts for that seed and shot count |
| hardware sample | observations from one physical job |
| statistical analysis | an inference under its stated model and assumptions |
| structural certificate | one artifact rule checked by the trusted kernel |
| theorem certificate | one proposition proved from explicit assumptions |

No row swallowed another. Hardware brought noise and physical fact. Simulation offered a view no chamber could. A theorem might
settle its proposition and remain silent about the warm bearing.

Sana gave each kind its own pane.

"Which one gets us home?" Mara asked.

Sana pointed to the empty space where their connections would go.

"Not one. The chain."

Before the chamber received anything, Wheeler translated the quantum region into a machine plan. Iona first selected the QFT
round-trip they had repaired.

The planner was brief.

```text
declared purpose:       phase calibration
forward transform:      present
immediate adjoint:      present
net quantum operation:  identity
```

Silence.

"Excellent restoration test," Tala said.

"Terrible calibration," Iona said.

The round trip went out and back. No clock ever touched it. The mission needed phase accumulation followed by the inverse transform.
Iona selected `BeaconPhaseEstimate.wbc`. Its plan coupled the control register to the optical reference, then applied the corrected
QFT adjoint before measurement.

For an OpenQASM target, the compiler emitted derived text for the ordinary gate regions.

```bash
wheeler qasm mission/BeaconPhaseEstimate.wbc \
  --target far-instrument-physical \
  -o mission/BeaconPhaseEstimate.qasm
```

The text showed the opening inverse-transform gates. The separate machine plan described the clock interaction for which standard
gates had no words.

```qasm
OPENQASM 3.0;
include "stdgates.inc";
bit[16] measured;
qubit[16] phase;
swap phase[0], phase[15];
swap phase[1], phase[14];
// six remaining bit-order swaps
h phase[0];
cp(-pi / 2) phase[0], phase[1];
```

QASM was useful machinery, not the meaning of the Wheeler source. Its record tied the emitted bytes to the program and to the
translation used for this chamber.

The chamber could hold only so many qubits and perform only certain gates. Its profile also said whether it could couple to the
optical reference, measure and reset mid-circuit, make a fast local branch, accept the requested shots, and remain within
calibration. An older rack nearby could run fixed gate sequences but could not measure until the end.

Iona sent the dynamic correction plan to the older rack first.

Tala expected refusal. Osei named the missing abilities. Mara expected originality.

The planner refused before submission.

```text
TARGET CAPABILITY REJECTION
required: classical_conditional, mid_circuit_measurement, reset
missing:  classical_conditional, mid_circuit_measurement, reset
submitted: false
```

The correction had to be chosen beside the qubits. Its measurement could not wait for a message to cross the station, let alone the
reach. *Target-resident* meant the branch happened there. `classical_conditional` was the required ability.

The rejected plan entered no queue and touched no hardware. Refusal was the safe behavior.

The phase-estimation plan passed the chamber checks. Tala submitted it with its shot count and calibration record.

The command returned. The machine did not.

```bash
wheeler run mission/BeaconPhaseEstimate.wbc \
  --target far-instrument-physical \
  --shots 4096 \
  --record mission/beacon-phase-run
```

```text
job state: submitted
submission: sha256:6d6f...
target job: FI-4096-771
```

A **quantum job** bundled preparation, operations, measurements, and shots. Submission was not completion. Between acceptance and
execution, or execution and validation, lay time enough for cancellation, failure, a broken link, a changed mind.

The chamber gave those intervals weight. Acceptance arrived while shutters closed. Then cooling: long enough to eat. During the
run Sable eclipsed the star and the station went to battery power. Someone could leave the gallery, sleep, return, and still find the
job between two verbs.

The program joined chamber work to later classical changes. Wheeler called the whole life of it a **hybrid run**. Planning,
acceptance, completion, validation: each belonged to the system that performed it. Only at the end could an observation alter
ordinary program state.

```text
01 plan_selected          plan record
02 submission_created     hybrid event
03 target_accepted        target receipt
04 target_completed       target receipt
05 result_validated       validation record
06 observation_applied    hybrid event
```

The numbered display did not make the events interchangeable. Messages might arrive out of order. Identities said which completion
belonged to which submission. Validation checked the chamber, shots, outcome width, plan, and calibration before any observation
could change classical state.

At the final event, measurement crossed the boundary. Physical systems became basis outcomes. Wheeler continued with integers. No
generated inverse could unfold those integers into the unknown state before measurement.

The phase job passed validation. Its outcomes placed the received optical reference into phase bins, blurred by finite shots and
chamber error. Ordinary software combined them with microwave delay, particle counts, and magnetic readings. The program, machine
plan, calibration, and estimator stayed attached.

Only then did clock drift separate from propagation delay.

The result proved neither the whole chamber nor the transform and made no claim to universal advantage. It gave traffic control a
physical measurement whose path could be followed.

Sana sent the compact manifest by fallback radio. The underlying clock comparisons, carrier readings, particle data, chamber
receipts, and correction logs would take too long. Their calibration would expire in transit. She sealed them aboard *Vela*.

Catenary acknowledged the summary. The beacon update stayed open.

With the mission window safe, Iona submitted `BellPair.wbc` as a separate diagnostic. Its ideal model allowed only `0` and `3`. Any
other bar would show the chamber's weather.

The bars appeared.

Nobody mistook them for mystery. Iona read the counts with the displeasure of someone finding frost inside a seal.

```text
shots: 4096
0 | ################################################# 1978
1 | ##                                                   61
2 | #                                                    55
3 | ################################################## 2002
```

The ideal Bell state assigned probability only to `0` and `3`. Here, other outcomes appeared. Some population had left the expected
rows. Yet the surviving `0` and `3` counts said nothing about whether their relative phase remained. A classical mixture could draw
the same first histogram.

Iona changed the basis of the question. After the same Bell preparation, the chamber applied `H` to both qubits before measurement.
The Hadamards turned phase relation into parity. An ideal Bell state would still yield matching outcomes. Damage to that relation
would feed the mismatched rows.

```text
complementary-basis shots: 4096
0 | #############################################       1801
1 | ######                                               254
2 | ######                                               247
3 | #############################################       1794
```

Mismatch grew sharply in the second basis. Faulty control, readout error, leakage, drift, lost phase: the noise model allowed each
to contribute. No single bar confessed its cause. Together, the two parities narrowed what the chamber might have done.

The loss of usable phase relation through uncontrolled contact with the environment was **decoherence**. No Wheeler operation had
requested it. No secret random gate explained it away. The chamber report inferred the loss through a calibrated physical model and
gave the inference an uncertainty.

Hardware still had not shown them an amplitude table.

"Again," Mara said.

She meant: *Will it recur?* The command meant something else.

Sana stopped before submission and replayed the existing observation.

```bash
wheeler replay mission/bell-run
```

Replay fed the saved observation through the later classical decisions. No chamber was contacted. No qubits were prepared. No
shots spent. No statistics improved. The record showed that replay had occurred and invented no physical event.

```text
source observation: sha256:8aa1...
target submissions: 0
replay status: applied
```

A **retry** crossed back into physics. Same program, same chamber, same shots: fresh systems, fresh job, another branch in the
record.

```bash
wheeler retry mission/bell-run --record mission/bell-retry
```

```text
task identity:       sha256:b41e...
prior target job:    FI-BELL-042
new target job:      FI-BELL-043
retry branch:        sha256:891c...
target submissions:  1
```

The new sample could differ because the physical preparations were new. It could be compared or combined with the first only by a
plan written in advance, not used as a cleaner replacement.

The retry showed similar mismatch in both bases. Mara waited for Iona to define the comparison before calling it better or worse.
Sana kept both runs. The inconvenient one remained.

One deck below, error correction faced the same problem sharpened to a point. A physical qubit could drift without naming the fault.
Measure it directly and the diagnosis would destroy the protected state.

The chamber spread one useful **logical qubit** across a pattern of physical qubits. A valid encoded state obeyed certain
agreements. Temporary ancillas touched the pattern and were measured, not to reveal the protected value, but to ask which agreements
had broken.

The answers formed a **syndrome**. A **decoder** mapped the recognized pattern to a correction. Drift did not wait. Measurement,
decision, and correction all had to remain inside the chamber.

The static `SurfaceCode.w` fixture could prepare and reverse one correction kernel. It could not perform that measured feedback
cycle. The dynamic plan therefore had a different name: `ErrorCorrectionCycle.w`.

The check and correction kernels remained unitary where promised. Syndrome measurement created classical information. Reset
prepared those measured ancillas for another cycle. It did not masquerade as uncomputation. Conditional control chose the
correction. The boundaries kept their names because the physics differed.

A position in source named one logical resource. The chamber planner expanded it into a patch of physical sites, then surrounded the
patch with ancillas for repeated checks. The phase register and its protection occupied thousands of physical qubits. Sixteen in
the algorithm. Thousands in the room.

The full chamber accepted the plan.

During execution, syndromes poured down the panels in narrow columns. Corrections followed too quickly for Catenary, the Archive,
or anyone in the gallery to intervene. *Target-resident* did not mean unsupervised. It meant the team had agreed every allowed
branch before the moment of choice.

The report tied the cycles to their layout, decoder, syndrome stream, corrections, and final logical measurement. Its lower logical
error estimate belonged to these runs. It was not a promise that every encoded state would survive every fault.

Eight hours became one status line: `completed with corrections`.

Accurate, Iona thought, in the way *pressure loss* was accurate while omitting the room.

While the chamber cooled, Sana finished the QFT record.

Basis value five had gone forward and returned. The structural certificate showed that the generated body was the adjoint of the
gate sequence. Neither had noticed that the sequence itself was the wrong Fourier transform.

The corrected source kept its angles as symbolic fractions of `pi`. Now a theorem could address the proposition that had been
missing: the forward body itself implemented the eight-point Fourier transform.

```text
theorem: QFTDefinition
subjects: QFT.qft, EightPointFourierTransform
assumptions: normalized three-qubit input, exact symbolic angles,
             accepted unitary semantics
claim: qft(state) = EightPointFourierTransform(state)
kernel status: verified
```

The theorem ranged beyond one fixture, but only within its assumptions. It said nothing about chamber fidelity, pulse
approximation, clock coupling, uptime, or some other implementation that happened to share the name QFT.

Tala wrote the distinctions into the manual's last open page. No glossary followed. Their speech had changed without permission.
Mara no longer called replay *running again*. Osei heard *clean* and asked, *in which basis?* Sana withheld *result* until an
observation could name its origin.

Catenary's acknowledgment arrived during undocking. Traffic control accepted the compact manifest and scheduled a provisional
retuning ahead of the particle front. Final acceptance would wait for the full record aboard *Vela*.

The message offered no praise. It named the application, the next contact, and the consequences of arriving late.

"We saved their beacon schedule," Mara said.

"Provisionally," Sana replied.

"I am celebrating provisionally."

She read the message twice anyway.

Iona remained at the inner lock while *Vela* withdrew. She returned the empty sensor case to Osei and kept his blue cup in the
common rack.

"I do not have a return date," he said.

"Good."

"I can write before the next failure."

"Write about something that works."

Behind Iona, Sable's residents had returned to pumps, meals, and the bearing deferred to tomorrow's risk. The instrument narrowed
against the moon: station, black line, nothing.

Its result traveled inward. Its makers remained.

On the homeward passage, the charged front crossed Sable and pressed inward against the giant world's magnetic field. *Vela* saw it
first as numbers. Microwave paths shifted by frequency. Local clocks wandered by smaller amounts. The optical references held.
Catenary's reducer separated the motions and changed the beacon profile once.

Later the weather became light: a pale aurora following the giant world's field toward home. Inside *Vela*, the crew slept, worked,
argued. The hull translated beauty into allowable exposure.

Catenary's reports described weather at human scale. Old wheels shuttered their widest glass. Gardens dimmed their lamps. Markets
left the exposed spokes for school corridors, where children treated emergency stalls as festival booths until their parents' fear
outlasted the game.

Under the provisional beacons, traffic slowed. It did not stop.

On the second day inward, Osei wrote Iona about a radiator valve. Why the old part failed. How the replacement seated. The sound of
flow returning. He explained neither his departure nor a future arrival.

Sana logged the transmission without asking to read it.

Tala began the manual again. Her early notes looked broad now. She corrected them without hiding the old ink.

Edrin accepted Sana's amendment to the evacuation exhibit and added two words: *losses remembered*.

She let the message wait.

Weeks later, orbital yards replaced stars in the forward glass.

Amber filled the navigation plot.

```text
RETURN CHECK FAILED
navigation       home
workspace        not restored
mission result   present
result lineage   incomplete
```

This time Tala could read the failure.

One hold. Eight minutes, fifty-eight seconds. Falling.

Mara kept her hand in the burn cage. Commit or abort. She waited for Tala to name the problem.

"The result bytes match the manifest," Venn said. "I can carry the provisional profile for one cycle if you attest the result now
and repair its lineage after docking."

The offer was not reckless. Venn had separated immediate traffic from later accounting, as she once tried to separate crowded
platforms from fourteen forgotten cars.

The dangerous word was *result*.

The bytes matched. The claim had lost its past.

Tala wanted yes. Mara needed the burn. Catenary needed the calibration. Venn had offered a defensible path between them.

Still the noun stood unsupported.

"I can attest the bytes," Tala said. "I cannot attest the result. Keep the hold."

Venn took one breath. "You have it."

They moved.

Sana: sealed manifest.

Osei: reversible branch.

Tala broke the failed check into smaller claims. Mara kept the burn alive while every passing second changed it.

No meeting. No allocation of blame. Their responsibilities found their work.

The return policy had confused two experiments. In the unmeasured Bell test, the adjoint restored coherent workspace to `|00>`. In
the hardware run, measurement deliberately made classical observations and ended the quantum state.

To demand that state back was not rigor. It was asking for the wrong thing.

The broken chain had another cause. During homeward checks, Sana had replayed the validated beacon observation. The selected result
now descended from that replay, but compression had dropped the link to the original submission.

Bytes survived. Parentage did not.

Sana opened the pre-commit manifest copied from Edrin's practice at the Archive. There: the missing identity, and behind it the
signed chamber receipt. She checked both. Rejoined the edge. No new job.

The result could walk backward again, from validation to completion, acceptance, submission, plan, artifact, source.

"Lineage complete," she said.

Osei ran the classical branch's generated inverse from the state they had now. He claimed no history beyond commit. The remaining
workspace warning belonged only to the measured Bell run.

Tala narrowed the promise to what restoration had ever been capable of restoring.

Tala replaced the generic check with explicit contracts.

```text
navigation position             home
classical reversible state      restored by generated inverse
VM history before commit        unavailable by declared horizon
coherent Bell workspace         restored before measurement
hardware measurement            recorded irreversible observation
beacon phase observation        validated physical lineage
calibration reducer inputs      complete
replay                           linked to original observation
retry                            separate physical lineage
mission result lineage          complete
QFT structural certificate      verified
QFT theorem certificate         verified
```

The measured qubits were not recovered.

Nothing required them to be.

Osei ran the checker.

```text
RETURN CONTRACT SATISFIED
```

Sana transmitted the repaired chain. Tala sent the separated contracts beside it.

Seconds moved.

Venn read. She distinguished the preserved observation from the state no one claimed to restore. Then she bound the record to the
provisional beacon update.

"Calibration accepted," she said. "Proceed to burn."

The navigation system cleared the hold and displayed one final notice.

```text
RETURN AUTHORIZED
THIS EVENT CANNOT BE REPLAYED AS PROPULSION
```

"Now it develops a sense of scope," Mara said.

She looked once at Tala.

On their first day, Mara had trusted a departure interlock because its promise fit on one screen. This decision was larger. Its
parts were still visible.

Seven minutes, thirty-one seconds.

She committed.

Acceleration struck through the deck. No replay could produce it later. Beyond the windows, the yards stopped growing and began to
hold.

Sana closed the mission account only after docking contact. Iona's calibration remained itself. So did the Archive transfer, the
hardware runs, replay, refusals, theorem. Connected, not blended.

She sent Edrin the manifest that had saved the missing edge. Beneath it she answered his amendment: *remembered is not restored.
both matter*.

Catenary had changed. Shield shutters covered the oldest windows. Traffic followed the retuned beacons. Someone had painted a blue
spiral across *Vela*'s berth wall. Maintenance had already sent the removal charge.

Home had not held still for them.

Tala returned the gray manual to the machine room. The binding still named no final authority. She signed only the changes that
were hers.

Inside the cover, beneath the old sentence about return, she wrote what the voyage had left them:

```text
Home is not the state before the journey.
Home is the state the contract promised to restore,
with every surviving result able to explain how it arrived.
```

Outside the hull, Catenary took *Vela*'s weight.

Mara set the Archive bird on the console. In the yard's spin it tipped forward, pointing not toward the places behind them but into
the ship. Osei opened a delayed message from Sable. No fault report. He began a reply. Sana watched the mission account enter its
other stores, then let the screen go dark.

Nothing moved backward.

The doors opened anyway.
