---
sidebar_position: 13
title: Weather
description: Chamber weather follows Vela home, where evidence, traffic, memory, and one physical burn must keep separate authority.
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

Refrigeration entered the handrail as Tala descended from the main-array gallery.
Gravity weakened at each landing. By the chamber level, the vibration had grown
strong enough to numb her palm.

Three decks of machinery stood behind the target's single callable interface.

Vacuum pumps pulled against leaks too small for human hearing. Nested shields carried heat toward refrigeration. Control racks
translated schedules into fields whose physical errors required calibration. From Tala's gallery rail, execution looked like an
agreement negotiated among temperatures that could never meet.

The residents took their places. A coolant bypass closed by hand while the
controls watched. Someone lifted a family photograph from a rack that would shake
during pump-down. Their cooperative form of the Covenant placed authority for the
run among the people sharing its heat, air, and consequences. Conversation moved
through seals, tools, the warm bearing, and whether its risk belonged to tonight
or tomorrow.

Far from Catenary, the frontier was mostly maintenance performed before a fault
became interesting. The Sable cooperative had learned that habit during the
Withdrawal, when a deferred repair could outlive the charter office that deferred
it.

Simulator and target each accepted the supported Wheeler operations. The numerical model could
show its own state vector. Hardware returned observations with timing, calibration, and uncertainty. Amplitude names in source gave
no chamber the power to reveal a physical state vector.

Sana arranged the possible evidence before allowing a submission.

| Record | What it could show |
| --- | --- |
| classical execution | what one deterministic run did with a particular program and input |
| ideal state vector | amplitudes inside the named simulator and numerical profile |
| seeded simulation | reproducible counts for that seed and shot count |
| hardware sample | observations from one physical job |
| statistical analysis | an inference under its stated model and assumptions |
| structural certificate | one artifact rule checked by the trusted kernel |
| theorem certificate | one proposition proved from explicit assumptions |

Every row retained separate authority. Physical observations carried chamber fact and chamber noise. Simulation exposed numerical
state unavailable from hardware. A theorem could prove its proposition while saying nothing about the bearing heating below them.

She assigned each evidence kind an independent pane and identity.

"Which pane clears Catenary?" Mara asked.

Sana touched the blank region reserved for lineage edges.

"Their chain, if we complete it."

Wheeler planned the quantum region before any target submission. Iona deliberately began with their repaired QFT round trip.

The planner reduced its purpose to three lines.

```text
declared purpose:       phase calibration
forward transform:      present
immediate adjoint:      present
net quantum operation:  identity
```

Nobody defended the result.

"It qualifies restoration," Tala said.

"It observes no clock," Iona answered.

Forward transform followed immediately by adjoint yielded identity without allowing a clock interaction. The mission required the
optical reference to accumulate phase before inverse QFT. Iona selected `BeaconPhaseEstimate.wbc`, whose plan inserted that physical
coupling before adjoint and measurement.

The compiler emitted OpenQASM for the target's ordinary gate regions.

```bash
wheeler qasm mission/BeaconPhaseEstimate.wbc \
  --target far-instrument-physical \
  -o mission/BeaconPhaseEstimate.qasm
```

Its text began with inverse-transform gates. A separate machine plan retained the clock coupling that standard gate syntax could not
express.

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

QASM served as derived target machinery. Its record bound emitted bytes to Wheeler source and to the exact translation used for
this chamber.

The target profile limited qubit capacity and native gates. It also declared optical coupling, mid-circuit measurement, reset,
local conditional control, shot limits, and calibration range. An older Sable rack accepted fixed gate sequences and supported
measurement only at completion.

Iona tested the dynamic correction plan against that older profile.

Tala predicted rejection, and Osei listed its causes. Mara requested a more surprising outcome.

Planning ended before any submission identity existed.

```text
TARGET CAPABILITY REJECTION
required: classical_conditional, mid_circuit_measurement, reset
missing:  classical_conditional, mid_circuit_measurement, reset
submitted: false
```

Measurement and correction had to occur beside the physical qubits, within their timing window. A station message would already
arrive too late. *Target-resident* control required a local branch, represented by capability `classical_conditional`.

Rejection consumed neither queue position nor hardware work. The profile had protected the target by refusing early.

The unprotected phase-estimation qualification passed the chamber checks. Tala
submitted it with its shot count and calibration record.

The submission command completed while the physical machine continued into its own schedule.

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

A **quantum job** identified preparation, operations, measurement, and shot count as one target task. Submission established a
request rather than completion. Acceptance, execution, return, and validation left room for cancellation, target failure, lost
links, and changed decisions.

Chamber life made each interval tangible. Acceptance arrived during shutter closure. Cooling lasted through a meal. Sable eclipsed
the star during execution and placed the station on batteries. A resident could leave, sleep, and return while one job remained
between lifecycle states.

Wheeler called the complete coordination between target work and later classical state a **hybrid run**. Planner, target, and host
each owned their lifecycle events. A validated observation could change ordinary state only at the declared boundary.

```text
01 plan_selected          plan record
02 submission_created     hybrid event
03 target_accepted        target receipt
04 target_completed       target receipt
05 result_validated       validation record
06 observation_applied    hybrid event
```

Sequence numbers aided reading without making events interchangeable. Messages could arrive out of order, and identities bound a
completion to its submission. Validation checked target, shots, outcome width, machine plan, and calibration before application to
classical state.

Measurement crossed from physical quantum systems to classical basis outcomes. Wheeler continued with integer observations.
Generated inverse or adjoint work could not expand those numbers into the unknown premeasurement state.

The qualification job passed validation. Its outcomes placed the received optical
reference into phase bins, blurred by finite shots and chamber error. Ordinary
software could set them beside multifrequency carrier travel, local particle
counts, and field measurements. The provisional reduction could distinguish
clock motion from path delay under the chamber's existing error model.

Traffic could not use it yet. Sable's instrument charter required a current
on-watch diagnostic before the model could accompany a production observation.
The source, machine plan, calibration, and estimator remained attached, but the
chain still ended inside the station.

Sana prepared the compact manifest and left its final identity blank. The raw
comparisons and carrier readings would travel aboard *Vela* with the physical
job's receipts and correction history. Light would carry only the notice,
when they had earned one.

Venn's last traffic notice remained unanswered. The beacon update stayed open.

Iona submitted `BellPair.wbc` as the required diagnostic. Its ideal model allowed only `0` and `3`. Any
other bar would show the chamber's weather.

The diagnostic histogram filled its pane.

Iona treated the unexpected rows as a maintenance fact. Her expression resembled Osei's when he found frost beyond a pressure
seal.

```text
shots: 4096
0 | ################################################# 1978
1 | ##                                                   61
2 | #                                                    55
3 | ################################################## 2002
```

The ideal Bell model assigned nonzero probability only to `0` and `3`; hardware also returned `1` and `2`. Population had reached
unexpected rows. Counts remaining in `0` and `3` revealed no relative-phase information because a classical mixture could produce
the same basis histogram.

Iona repeated Bell preparation with Hadamards on both qubits before measurement. The basis change converted the phase relation into
observable parity. Ideal Bell preparation retained matching outcomes there; damage to relative phase increased mismatches.

```text
complementary-basis shots: 4096
0 | #############################################       1801
1 | ######                                               254
2 | ######                                               247
3 | #############################################       1794
```

The complementary-basis mismatch rose sharply. The calibrated noise model allowed contributions from control fault, readout error,
leakage, drift, and phase loss. Neither histogram identified one cause, though their two parity tests narrowed the possible chamber
behavior.

The loss of usable phase relation through uncontrolled contact with the
environment was **decoherence**. It entered outside Wheeler's requested
operations. A calibrated physical model, rather than an invented secret gate,
supported the chamber's inference and its uncertainty.

At no point had hardware exposed amplitudes.

Mara pointed at the diagnostic. "Repeat it."

Her operational question concerned recurrence. Wheeler required them to distinguish replay from another physical attempt.

Sana intercepted the command and first replayed the saved observation.

```bash
wheeler replay mission/bell-run
```

Replay fed the saved observation through the later classical decisions. It
contacted no chamber, prepared no qubits, spent no shots, and improved no
statistics. The entry showed that replay had occurred and invented no physical
event.

```text
source observation: sha256:8aa1...
target submissions: 0
replay status: applied
```

A **retry** created a fresh physical job under the same program, chamber, and shot count. New systems and a new submission formed a
separate lineage branch.

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

Fresh preparation allowed the retry sample to differ. Comparison or combination with the earlier sample required a predeclared
analysis plan; preference after observation could not turn the retry into a replacement.

Both bases showed similar mismatch on retry. Mara withheld a judgment of improvement until Iona applied the planned comparison.
Sana retained both physical branches, including the less convenient first run.

The repeated mismatch gave Iona the answer the production plan needed: the
chamber's present weather would not disappear through optimism or another clean
sample. She revised the plan around a protected logical register and kept both
diagnostics in its calibration lineage.

Error correction on the deck below addressed a sharper version of the problem. Physical qubits drifted without identifying the
fault, while direct measurement would destroy the logical state requiring protection.

The chamber spread one useful **logical qubit** across a pattern of physical
qubits. A valid encoded state obeyed certain agreements. Temporary ancillas
touched the pattern and were measured to learn which agreements had broken while
the protected value remained undisclosed.

Measured agreement checks produced a **syndrome**. A **decoder** mapped recognized syndrome patterns to corrections. Physical drift
continued during this work, requiring measurement, decoding, and correction inside the target.

Static fixture `SurfaceCode.w` demonstrated preparation and reversal of one correction kernel. It lacked the measured feedback
cycle needed by production work, which belonged to dynamic plan `ErrorCorrectionCycle.w`.

Check and correction kernels retained their unitary contracts. Syndrome measurement created classical data. Reset prepared
measured ancillas for reuse through physical initialization rather than uncomputation. Conditional control selected corrections.
Each boundary kept a separate name because each performed different physics.

One logical source resource expanded during planning into a patch of physical sites surrounded by check ancillas. Protecting the
sixteen-position phase register required thousands of physical qubits in the chamber.

The full chamber accepted the plan. The production phase comparison occupied its
protected logical register. If this submission failed, Venn's remaining chamber
window would close before Sable could cool the machine and begin again.

Syndromes streamed down the panels during execution, followed by corrections too fast for intervention from gallery, Archive, or
Catenary. *Target-resident* control remained supervised through a plan whose allowed branches the team had approved before timing
made the choices immediate.

The report bound cycles to layout, decoder, observed syndromes, selected corrections, and final logical measurement. Its logical
error estimate described these runs under their calibration and did not promise survival for every encoded state or fault.

The interface condensed eight hours of chamber work to `completed with corrections`.

Tala watched Iona read the line twice. Its accuracy had the narrowness of *pressure loss* written without the room.

The protected phase outcomes passed validation. Ordinary software combined their
bins with microwave delay, particle counts, and magnetic readings. This reduction
separated clock drift from propagation delay with the program, machine plan,
calibration, diagnostic samples, retry, syndrome stream, and estimator still
attached.

Sana filled the blank identity in the compact manifest and sent it by fallback
radio. The underlying clock comparisons, carrier readings, chamber receipts, and
correction logs would take too long and their calibration would expire in
transit. She sealed them aboard *Vela*, following the old packet rule: light
carried the notice; a hull carried the weight behind it.

During cooldown, Sana completed the QFT evidence chain.

Executable basis value five had survived forward body and generated adjoint. The structural certificate proved the generated
sequence was that body's adjoint. Those facts had failed to test whether the body implemented the Fourier transform.

Symbolic fractions of `pi` remained in corrected source. A theorem could now state and prove the missing proposition that the
forward body implemented the eight-point Fourier transform.

```text
theorem: QFTDefinition
subjects: QFT.qft, EightPointFourierTransform
assumptions: normalized three-qubit input, exact symbolic angles,
             accepted unitary semantics
claim: qft(state) = EightPointFourierTransform(state)
kernel status: verified
```

The theorem covered normalized inputs under its explicit mathematical assumptions rather than one executable fixture. It made no
statement about chamber fidelity, approximate pulses, optical coupling, uptime, or unrelated implementations sharing the name
QFT.

Tala used the last open leaf of the gray book. Their working speech had already absorbed the distinctions. Mara separated replay
from fresh execution. Osei required a basis whenever someone called workspace clean. Sana allowed *result* only after an
observation could identify its origin.

Catenary acknowledged the compact manifest during undocking and scheduled provisional beacon retuning ahead of the front. Traffic
control reserved final acceptance for the full chain aboard *Vela*.

The acknowledgment specified application, next contact, and late-arrival consequence without congratulation.

"Their beacon schedule survives," Mara said.

"Under provisional acceptance," Sana said.

"Then my celebration matches its status."

Mara returned to the acknowledgment after closing its pane.

Iona stood inside Sable's lock during *Vela*'s withdrawal. She returned Osei's empty sensor case. His blue cup remained in the common
rack behind her.

"I cannot offer a return date," Osei said.

"Then leave it unpromised."

"I can write before machinery gives me an excuse."

"Send me a working thing."

Beyond Iona, residents returned to meals, pumps, and a bearing whose risk they had deferred until tomorrow. As *Vela* withdrew, the
instrument narrowed against Sable until its final truss merged with the moon.

The compact result went toward Catenary while the people responsible for it stayed at Sable.

On the homeward passage, the charged front crossed Sable and pressed inward against the Giant's magnetic field. *Vela* saw it
first as numbers. Microwave paths shifted by frequency. Local clocks wandered by smaller amounts. The optical references held.
Catenary's reducer separated the motions and changed the beacon profile once.

Later the weather became light: a pale aurora following the Giant's field toward home. Inside *Vela*, the crew slept, worked,
argued. The hull translated beauty into allowable exposure.

Catenary translated charged weather into inhabited consequences. Old wheels closed broad shutters, gardens reduced light, and
markets moved from exposed spokes into school corridors. Children treated emergency stalls as a festival until adult fear lasted
longer than the game.

The provisional beacon profile widened traffic intervals while preserving motion.

On the second inward day, Osei wrote Iona about a radiator valve: the old part's failure, the replacement seating, and the sound of
restored flow. He offered no explanation of his departure and promised no future arrival.

Sana recorded the transmission identity and left its private content unopened.

Tala reread the gray book from Yard Nine. Her first annotations now exceeded their evidence. She added corrections beside the old
ink.

Edrin approved Sana's evacuation amendment and appended *losses remembered*.

Sana retained the message without answering during that watch.

Weeks of inward travel ended when orbital yards displaced the forward stars.

The navigation plot turned amber.

```text
RETURN CHECK FAILED
navigation       home
workspace        not restored
mission result   present
result lineage   incomplete
```

The voyage had taught Tala how to divide its warning.

They possessed one hold and eight minutes fifty-eight seconds, both diminishing.

Mara's hand entered the burn cage between commit and abort. She gave Tala the remaining seconds to identify the unsafe statement.

"Manifest and selected bytes match," Venn said. "Attest the result now, and I can preserve the provisional profile for one cycle
while you repair lineage after docking."

Venn's offer made operational sense. It separated current traffic continuity from later evidence repair, echoing the choice she had
made between crowded platforms and fourteen cars missing from green state.

Her sentence placed unsupported weight on *result*.

The bytes retained identity while their selected lineage had lost an edge.

Every pressure pushed Tala toward acceptance: Mara's burn, Catenary's beacons, Venn's defensible separation, and her own old fear
of becoming a human veto.

The result designation still lacked its physical ancestry.

"I attest byte identity," Tala said. "The result lineage remains incomplete. Hold us."

One breath crossed the channel. Venn answered, "Hold granted."

Across the traffic plot, her decision became physical. An ore carrier lost its
inner approach. A passenger needle took the long side of Catenary's oldest wheel.
Venn had not granted Tala private time. She had spent public motion on the chance
that this distinction mattered.

The bridge divided into practiced work.

Sana opened the sealed manifest.

Osei isolated the reversible branch.

Tala separated the generic failure into explicit contracts. Mara maintained a valid burn solution as time continuously altered it.

They held no meeting and assigned no blame. Their responsibilities found their
work.

The policy had joined two Bell experiments. In the unmeasured ideal test, generated adjoint restored coherent workspace to `|00>`.
The hardware diagnostic deliberately measured physical systems, produced classical observations, and ended access to their prior
quantum state.

A restoration requirement after measurement misidentified the experiment and added no rigor.

A separate failure lay in lineage. Sana had replayed the validated beacon observation during homeward checks. The selected value now
descended from replay, while compression had removed its edge to the original target submission.

Content identity remained intact; selected parentage was incomplete.

Edrin's pre-commit manifest preserved the missing submission identity and its signed chamber receipt. Sana verified both and
restored the lineage edge without creating another target job.

The repaired chain now traced from validated observation through target completion, acceptance, submission, machine plan, artifact,
and source.

"The physical ancestry is complete," Sana said.

Osei executed the classical branch's generated inverse from current state. He invoked no retained history beyond commit. The only
remaining workspace warning referred to the intentionally measured Bell diagnostic.

Tala rewrote the return promise around states and evidence that their operations could actually recover.

She replaced the overloaded check with named contracts.

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

No contract reported recovery of measured qubits.

The mission required their classical observations and complete lineage.

Osei executed the revised checker.

```text
RETURN CONTRACT SATISFIED
```

Sana transmitted repaired lineage, and Tala transmitted the explicit contracts under a separate identity.

The burn clock continued.

Venn reviewed the separation between preserved physical observation and unrecoverable measured state. She then bound the accepted
observation chain to Catenary's provisional beacon update.

"Calibration chain accepted," Venn said. "Burn authority restored."

Navigation released the hold with one final scope warning.

```text
RETURN AUTHORIZED
THIS EVENT CANNOT BE REPLAYED AS PROPULSION
```

"Navigation has learned a useful qualification," Mara said.

She met Tala's eyes before returning to the cage.

In Yard Nine, Mara had trusted an interlock whose complete promise fit on one pane. This decision occupied many panes, yet every
necessary part remained visible.

Seven minutes thirty-one seconds remained.

Mara committed the burn.

New acceleration entered the deck and every body aboard. Replay could never supply that propulsion. Catenary's yards stopped
expanding across the glass as *Vela* matched their motion.

Sana kept the mission account open until physical docking. Archive transfer, Iona's calibration, hardware observations, replay,
planner refusals, and theorem evidence retained separate identities joined by lineage.

She sent Edrin the manifest that had saved the missing edge. Beneath it she answered his amendment: *Remembered is not restored.
Both matter.*

Shield shutters covered Catenary's oldest windows. Traffic moved under the retuned beacons. A blue spiral now crossed *Vela*'s berth
wall, accompanied by a maintenance invoice for removing it.

Their membership had continued inside a city altered by their absence.

Tala returned *Vela*'s gray recension of the Common Book to the machine room. The
binding still named no final authority. She signed only the changes that were
hers.

Tala wrote beneath the old return sentence inside the cover.

```text
Home is not the state before the journey.
Home is the state the contract promised to restore,
with every surviving result able to explain how it arrived.
```

Yard Nine's clamps accepted *Vela*'s mass.

The traffic channel stayed open one breath beyond the docking witness.

"I remember the fourteen cars," Venn said.

Tala had imagined an apology often enough to distrust every version. This was a
fact offered without defense.

"So do I."

The line closed.

The Thorn invitation had expired two transfers ago. Mara opened it, entered Yard
Nine's moving coordinates, and sent a new offer outward.

```text
CATENARY
BERTH OPEN WHEN VECTORS MEET
```

She set the Archive bird on the console. In the yard's spin it tipped forward,
away from the roads behind them and into the ship. Osei opened a delayed message
from Sable. No fault report. He began a reply. Sana watched the mission account
enter its other stores, then let the screen go dark.

The voyage remained in the state it had changed.

Ahead of them, the pressure doors opened.
