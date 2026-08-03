---
sidebar_position: 13
title: Weather
description: Physical targets, jobs, noise, replay, retry, correction, and proof complete the return contract.
tutorial_id: CH12
tutorial_steps: T83,T84,T85,T86,T87,T88,T89,T90,T91,T92,T93
tutorial_part: targets-and-evidence
tutorial_order: 12
tutorial_kind: complete-hybrid-execution
tutorial_source: source-backed-capstones
tutorial_expectation: auditable-return
tutorial_evidence: exact-simulated-hardware-and-formal
---

# Weather

Across three decks, the physical target exposed one logical endpoint.

Pumps maintained its vacuum. Refrigeration carried heat upward through nested shields. Control racks translated scheduled pulses
into fields whose errors had to be measured rather than wished away. Seen from the chamber gallery, a quantum job looked less like
an equation than a treaty among incompatible temperatures.

The instrument's other residents took positions around the chamber. One closed a coolant bypass by hand while the control system
watched. Another removed a family photograph from a rack that would vibrate during pump-down. Nobody stood in ceremonial silence.
They checked seals, traded tool counts, and argued about whether a warm bearing belonged to this window's risk budget or the next
one. Years from Catenary, the frontier consisted mostly of maintenance performed before a fault became interesting.

An ideal semantic simulator and this machine implemented the same accepted Wheeler operations, but they offered different evidence.
The simulator could expose an exact bounded state vector under its numeric profile. The target returned classical observations,
calibration records, timestamps, and uncertainty. Hardware did not reveal its amplitudes merely because the source had names for
them.

Sana divided the mission records before any submission occurred.

| Evidence | What it could support |
| --- | --- |
| exact classical execution | one deterministic run under a bound artifact and input |
| ideal state-vector result | amplitudes under the named ideal simulator and numeric profile |
| seeded simulator sample | reproducible counts under a target, seed, and shot count |
| hardware sample | recorded observations from one physical job lineage |
| statistical analysis | an inference under declared estimator and assumptions |
| structural certificate | one finite artifact rule checked by the trusted kernel |
| theorem certificate | one proposition under explicit assumptions checked by the trusted kernel |

A row lower in the table did not automatically dominate a row above it. Hardware supplied physical evidence and noise. The ideal
simulator supplied state access hardware could not. A theorem established its proposition without predicting whether the warm
bearing would survive tonight's run.

Sana gave each record class its own pane. Mara asked which pane would get them home. Sana answered by pointing to the blank lineage
that would have to connect all the relevant ones.

Before a target received anything, Wheeler lowered the verified quantum region into a target plan. For an OpenQASM target, the
compiler emitted derived text.

```bash
wheeler qasm tutorial/QFT.wbc \
  --target far-instrument-physical \
  -o mission/QFT.qasm
```

A fragment named the same gates in the target language.

```qasm
OPENQASM 3.0;
include "stdgates.inc";
qubit[3] q;
h q[0];
cp(pi / 2) q[1], q[0];
cp(pi / 4) q[2], q[0];
```

Although useful to the target, QASM was neither Wheeler semantics nor source authority. Its identity bound the Wheeler artifact,
target profile, lowering profile, and emitted bytes so that the submitted plan could be traced back to the verified program.

Capabilities constrained that lowering. The chamber target advertised qubit count, native gates, control depth, measurement,
reset, dynamic branches, shot bounds, and calibration age. A second target in the rack supported static circuits but no
mid-circuit measurement.

Iona deliberately sent the dynamic correction plan to the static target planner. Tala predicted a capability failure. Osei
predicted the three missing fields. Mara predicted that the older rack would find a new way to be difficult. Rejection occurred
before submission.

```text
TARGET CAPABILITY REJECTION
required: mid_circuit_measurement, reset, target_resident_branch
missing:  mid_circuit_measurement, reset, target_resident_branch
submitted: false
```

No queue entry, provider charge, or physical lineage existed for the rejected plan. Complete preflight failure was part of target
behavior, not an inconvenience to bypass.

Once the QFT plan satisfied the physical chamber's capability contract, Tala submitted it with a bounded shot count and calibration
identity. The command returned before the machine did.

```bash
wheeler run tutorial/QFT.wbc \
  --target far-instrument-physical \
  --shots 4096 \
  --record mission/qft-run
```

```text
job state: submitted
submission: sha256:6d6f...
target job: FI-2048-771
```

A **quantum job** was asynchronous even when a local target happened to complete immediately. Submission, acceptance, execution,
completion, validation, and application remained separate events because remote time could place a crash or cancellation between
any two of them.

The physical chamber made those intervals tangible. Acceptance arrived while its shutters closed. Execution began after a cooling
hold long enough for the crew to eat. During the run, Sable eclipsed the primary and the station changed to battery power. A person
could leave the gallery, sleep, and return before one semantic event yielded to the next.

With each remote change, the mission record grew by one immutable transition.

```text
01 plan_selected
02 submission_created
03 target_accepted
04 target_completed
05 result_validated
06 observation_applied
```

Arrival order did not define semantic order. Submission identity selected the accepted completion. Validation checked target,
shots, outcome width, plan identity, and calibration bounds before the observation could change classical program state.

At event six, measurement crossed the quantum-classical boundary. The target had produced basis outcomes from physical systems.
Wheeler recorded those outcomes and continued classically. No generated inverse could reconstruct the unknown premeasurement state
from the resulting integers.

The QFT job passed its declared validation bounds. The instrument's calibration reducer bound its hardware sample to the source,
artifact, target plan, chamber calibration, and estimator, then produced the signed result Catenary had requested. The result did
not certify the whole target or prove the transform. It supplied one timely physical measurement under a chain that traffic
control could audit.

Sana transmitted the result manifest immediately. The bulk sample would take longer to cross the reach. Catenary acknowledged the
manifest and held the beacon update open.

With the mission window secured, Iona submitted `BellPair.wbc` as a separate diagnostic under `mission/bell-run`. Its ideal model
allowed only outcomes `0` and `3`, which made departures easy to see. In that first hardware Bell run, the weather became visible.
Nobody in the gallery mistook the unwanted bars for a revelation. Iona had seen cleaner nights and much worse mornings. She read the counts with the practiced displeasure of someone finding frost
inside a seal.

```text
shots: 4096
0 | ################################################# 1978
1 | ##                                                   61
2 | #                                                    55
3 | ################################################## 2002
```

Ideal Bell semantics assigned probability only to `0` and `3`. The physical sample contained 116 other outcomes. Control error,
readout error, decoherence, leakage, and drift could all contribute under the target's calibrated noise model. The histogram alone
did not identify which mechanism caused each event.

**Decoherence** described loss of usable quantum phase relations through uncontrolled interaction with the environment. It was not
a semantic operation in the Wheeler source and not a hidden random gate the program had requested. The target report supplied a
physical model and calibration evidence for it.

Mara asked for another run. What she wanted was understandable: a chance to learn whether the 116 unwanted outcomes would recur.
What she said was, "Run it again," as though repetition named only one operation.

Sana stopped the command before submission and replayed the existing observation instead.

```bash
wheeler replay mission/bell-run
```

Replay consumed the validated record, reproduced the same later classical choices, and emitted a new replay event. It did not
contact the target, create qubits, spend shots, or improve the statistical evidence.

```text
source observation: sha256:8aa1...
target submissions: 0
replay status: applied
```

A **retry** would do something else. It would prepare fresh physical systems and create a new submission lineage, even if source,
target, and shot count remained unchanged.

```bash
wheeler retry mission/bell-run --record mission/bell-retry
```

```text
prior submission: sha256:6d6f...
new submission:   sha256:891c...
target submissions: 1
```

Because retry prepared fresh physical state, the new sample could differ. Combining it with the first required an explicit
statistical plan rather than silently replacing an unpleasant result.

The retry contained 121 unwanted outcomes. Mara did not call that better or worse until Iona named the comparison and its
assumptions. Sana retained both lineages. No convenient sample disappeared.

On the deck below, the instrument's error-correction target exercised the distinction between static structure and dynamic work.
`SurfaceCode.w` prepared a logical patch, extracted syndrome information into ancillas, measured those ancillas during the run,
reset them, selected corrections through target-resident branches, and repeated the bounded cycle under a declared noise budget.

Where their contracts required it, the exact stabilizer and correction kernels remained unitary. Syndrome measurement produced new
classical observations. Reset prepared resources for another cycle without pretending to uncompute the measured state. Dynamic
control selected a correction from the observed syndrome. Each boundary retained its own operation name.

Unlike the static target, the fully capable chamber accepted the plan. During execution, syndrome observations crossed the control
panels in narrow columns. Corrections followed close enough that no instruction could wait for Catenary, the Archive, or even a
person in the gallery. Target-resident did not mean unsupervised. It meant the supervision and branch contract had been established
before the physical event required them.

The report bound cycle count, logical layout, physical qubits, decoder profile, syndrome records, corrections, and final logical
measurement. A lower logical error estimate was a statistical claim over the declared runs, not proof that every encoded state
would survive every physical fault.

While the target cooled between jobs, Sana completed the evidence ledger for the three-qubit QFT.

For prepared basis value five, the executable test showed restoration. The structural certificate verified that the generated body
was the adjoint of the bound gate sequence. A theorem certificate covered the general proposition.

```text
theorem: QFTAdjointLaw
subjects: QFT.qft, generated_adjoint(QFT.qft)
assumptions: normalized three-qubit input, accepted unitary semantics
claim: adjoint(qft)(qft(state)) = state
kernel status: verified
```

Because the theorem named assumptions and subjects, it established more than the one fixture and something different from the
hardware sample. It did not certify provider uptime, physical fidelity, or the correctness of an unrelated QFT implementation.

Into the field manual's last open signature went those distinctions. Tala added no glossary. By then the crew's speech had changed
without one. Mara no longer asked whether a job had "run again" when Sana replayed it. Osei no longer accepted "clean" without a
basis and scope. Sana used *result* only after lineage connected observation to preparation.

Catenary's acknowledgment reached Sable during undocking. Traffic control had accepted the compact manifest and scheduled a
provisional beacon retuning before the particle front. Final acceptance still required the full evidence package aboard *Vela*.
The message contained no praise, only an application identity and the next expected contact. Mara read it twice anyway.

Iona remained at the inner lock while *Vela* withdrew. She returned the empty sensor case to Osei and kept his blue cup in the
common rack.

"I do not have a return date," he said.

"Good."

"I can write before the next failure."

"Write about something that works."

Behind her, the station's five residents had already returned to pump work, meal rotation, and the bearing they had deferred into
the next risk budget. The instrument contracted into a black line against Sable. Its result traveled inward with the ship. The
place and people that produced it stayed where they were.

Their departure from the far instrument began the homeward half of the voyage.

On the homeward passage, the charged-particle front reached the inner system. *Vela* watched it first through instrument reports:
noise floors rose, beacon clocks drifted, and Catenary's newly calibrated network changed profiles exactly once. Later the front
became visible as a pale aurora along the magnetic field of the world below home. The crew slept, worked, and argued inside a hull
that reduced the event to allowable exposure.

Tala read the field manual from the beginning. In the outward margin she found her own early notes too broad, corrected them, and
left enough of the old ink visible to show why. Sana received a message from Edrin accepting the evacuation-exhibit amendment.
He had added two words: *losses remembered*. She did not answer immediately.

Weeks later, with orbital yards replacing stars in the forward windows, the return checker produced the amber report from which
the manual had begun.

```text
RETURN CHECK FAILED
navigation       home
workspace        not restored
mission result   present
result lineage   incomplete
```

This time Tala could read the failure rather than merely divide it among the crew. Neris Venn had granted one technical hold. The
burn cage showed eight minutes, fifty-eight seconds and continued counting. Mara kept her hand inside it, ready to commit or abort,
and waited for Tala's nouns.

"The result bytes match the manifest," Venn said. "I can carry the provisional profile for one cycle if you attest the result now
and repair its lineage after docking."

The offer was not reckless. It separated immediate traffic from later records, just as reopening the transit platforms had once
separated crowd safety from fourteen cars outside the copied state. The dangerous word was *result*. Its bytes matched. Its claim
did not yet possess the history required for acceptance.

"I can attest the bytes," Tala said. "I cannot attest the result. Keep the hold."

Venn took one breath. "You have it."

One undifferentiated return policy had covered two experiments. In the unmeasured Bell restoration test, the generated adjoint had
returned coherent workspace to `|00>`. In the sampled hardware experiment, measurement had intentionally
created classical observations and ended the quantum state lineage. Demanding restoration after that boundary was not strict. It
was a category error.

A separate cause lay behind the lineage failure. During homeward verification, Sana had replayed the validated QFT observation.
The selected mission result now came from that replay event, whose compact record had lost its original submission edge. The bytes
had survived. One relation had not.

Sana opened the pre-commit manifest whose pattern she had copied from Edrin at the Archive. It preserved the missing identity and
its parents. She recovered the signed target receipt, verified both content identities, and restored the edge without submitting
another target job. The result now connected backward through validation, completion, acceptance, submission, plan, artifact, and
source.

"Lineage complete," she said.

Osei had already isolated the reversible classical branch. He executed its generated inverse from the current state, without
claiming access to history beyond the commit horizon. The remaining workspace warning belonged only to the measured Bell branch.
Tala narrowed that contract to the state restoration had ever been able to cover.

Tala replaced the generic check with explicit contracts.

```text
navigation position             home
classical reversible state      restored by generated inverse
VM history before commit        unavailable by declared horizon
coherent Bell workspace         restored before measurement
hardware measurement            recorded irreversible observation
replay                           linked to original observation
retry                            separate physical lineage
mission result lineage          complete
QFT structural certificate      verified
QFT theorem certificate         verified
```

No row claimed that the measured qubits had been recovered. No row needed them to be.

Osei ran the checker.

```text
RETURN CONTRACT SATISFIED
```

Sana transmitted the repaired full lineage. Tala sent the explicit contracts beside it. Venn read far enough to separate the
recorded observation from the state nobody claimed to restore, then bound the lineage to the provisional application.

"Calibration accepted," she said. "Proceed to burn."

Mara looked once at Tala. On their first day she had trusted a departure interlock because its claim was small enough to inspect.
Now she trusted a larger decision for the same reason. She resumed the countdown at eight minutes, forty-one seconds. The braking
burn arrived as acceleration through the deck, a physical fact no replay could reproduce for them later. Beyond the windows, the orbital yards stopped growing and began to hold
their position.

Sana closed the mission lineage only after docking contact. Iona's calibration, the Archive transfer, both hardware lineages, the
replay, every rejected preflight, and the final theorem remained distinct records inside one account. She sent Edrin a reference to
the manifest that had saved the edge, followed by an answer to his amendment: *remembered is not restored, and both matter*.

Catenary had changed while they were gone. Shield shutters covered the oldest windows. Traffic moved under the retuned beacon
profile. In Yard Nine, somebody had painted the berth wall with a blue spiral and a maintenance crew had already billed *Vela* for
removing it. Home had not held still to make their return easier.

Tala returned the gray field manual to the machine room. Its binding still listed no revision authority, so she added her name only
to the changes she could support. On the inside cover, beneath the old sentence about return, she wrote the narrower conclusion the
voyage had earned.

```text
Home is not the state before the journey.
Home is the state the contract promised to restore,
with every surviving result able to explain how it arrived.
```

Outside the hull, Catenary took *Vela*'s weight. Mara placed the Archive bird on the console. In the yard's spin it tipped forward,
as if pointing into the ship rather than toward anything they had left behind. Osei opened a delayed Sable message that contained
no fault report and began a reply. Sana watched the mission record propagate into three independent stores.

Nothing moved backward. The doors opened anyway.
