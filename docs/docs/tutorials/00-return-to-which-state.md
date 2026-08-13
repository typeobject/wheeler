---
sidebar_position: 1
title: Home
description: One failed return check exposes several operations hidden inside an ordinary word.
tutorial_id: T00
tutorial_steps: T00
tutorial_part: opening
tutorial_order: 0
tutorial_kind: conceptual
tutorial_source: display
tutorial_expectation: none
tutorial_evidence: exact-source-display
---

# Home

Home arrived by subtraction.

For six days the forward windows had held nothing but stars, hard and innumerable. Then traffic lights appeared among them,
followed by the pale geometry of Catenary's orbital yards, until the constellations were no longer the largest structures in view.
The station was not one station but a civic argument conducted in metal: three old wheels, a spindle of newer gardens, nine
commercial yards, and several unauthorized neighborhoods that had acquired air before they acquired names. Every structure turned
at its chosen rate. From a distance, the moving lights braided themselves into something that looked intentional.

Nobody aboard *Vela* had been born there. All four carried Catenary residency, which was a different and more demanding fact. The
habitat considered arrival a matter of matching velocity, paying for dock mass, and accepting responsibility for whatever crossed
the pressure seal in one's luggage. Mara reduced the remaining distance to a column of burns and corrections. Osei began closing
systems that had been open since departure. Sana requested the final mission lineage. Tala watched Yard Nine rotate into sunlight
and tried not to count the lit windows around the berth they had left empty.

The far instrument's manifest had crossed the reach in time for Catenary to retune its approach beacons provisionally. The full
evidence package was too large for the instrument's narrow transmitter. *Vela* carried it home. Before the charged-particle front
peaked, traffic control had to accept that lineage or revert the beacons to their older profile. Missing one braking window would
not kill the crew. It would put *Vela* into a nineteen-hour contingency orbit, spend most of Mara's reserve, and deliver the
calibration after the decision it was meant to support.

With eleven minutes left before braking, *Vela* laid an amber sentence across the navigation plot.

```text
RETURN CHECK FAILED
```

Mara's hand remained inside the burn cage. Nothing in her posture changed, but the countdown stopped.

Osei was already inside the restoration map, opening branches faster than the display could arrange them. Sana did not touch her
console. She watched the others instead, waiting to learn which event they would later claim had happened.

Tala expanded the report.

```text
navigation       home
workspace        not restored
mission result   present
result lineage   incomplete
```

The contradiction lasted only as long as it took each of them to choose a different line.

To Mara, return meant position: mass, velocity, approach corridor, the clean arithmetic of not striking the station. Osei saw state
that had failed to restore. Sana saw an observation detached from the sequence that had produced it. Tala, who had spent the
voyage learning their vocabularies without yet possessing any of them, saw one ordinary word carrying more machinery than it could
bear.

*Vela* had been rebuilt often enough that nobody knew which subsystem was oldest. The pressure hull began as a survey tender. Her
port radiator came from a hospital barge, her maneuvering model from a racing tug whose owners had considered safety margins a
form of pessimism. Hardware disappeared. Interfaces changed. Names remained. *Return* meant the value produced by a function in
one layer, inverse execution in another, the consumption of retained history in a third, and physical arrival in the navigation
code, where the word predated everyone aboard.

Routine voyages had never required those meanings to agree. A cargo could be delivered after a workspace leak. A test could be
repeated when its lineage proved thin. A ship could miss a polite arrival time and take the outer loop.

This voyage had brought home one result that could not simply be made again. The physical target was entering maintenance, its
calibration would expire during the particle front, and the sealed source observation belonged to the run already completed. They
could preserve it, reject it, or account for it. They could not order the universe to repeat the same past.

Sana opened the result record. Near its end sat a small quantum program whose grammar Tala recognized before its purpose came into
focus.

```wheeler
quantum class Bell {
  state long measured = 0;
  qreg q = new qreg(2);

  unitary void prepareBell() {
    H(q[0]);
    CNOT(q[0], q[1]);
  }

  entry void main() {
    prepare(q, 0);
    prepareBell();
    measured = measure(q);
  }
}
```

Two registers. A preparation. An operation called `H`. A controlled gate. Measurement. The terms marked a route through a subject
Tala did not know, but the record beneath them was plain enough.

```text
Bell (quantum) halted after 4 steps
measured = 3
measurements = [3]
```

"Three," Mara said. "At least something came back."

"Something was recorded," Sana replied.

The distinction irritated Mara, which did not make it less important. "Can the recorded something get us through the burn?"

Osei enlarged the amber region of the restoration map. "Not while its workspace is still out there."

Tala looked again at the number. One ideal-simulator run had halted and recorded `3`. Nothing in the record established what a
second run would produce. A distribution required repeated trials. Entanglement required more than matching digits. Restoration
required an operation absent after the measurement. The smallness of the number had no relation to the size of the missing
explanation.

"It is an observation," she said. "Not yet an answer."

Sana's attention shifted from the record to Tala. During the outward voyage, that pause had often preceded a correction. This time
she entered the sentence unchanged.

At nine minutes, Catenary requested their braking commitment. Mara answered with a delay code and no apology. In the station's
traffic grammar the code meant *technical hold, crew in control*. It bought ninety seconds and placed Neris Venn, director of
traffic continuity, on their channel. Tala knew the voice before the display supplied the name.

"State the unsafe claim," Venn said.

"Working," Tala replied.

The hold could be used once.

Osei isolated the unrestored branch to a computation executed at the far instrument, but its retained history ended at a commit
boundary. Rewinding through that boundary was unavailable. The source still had a generated adjoint somewhere in its artifact,
though measurement had made the original quantum state another matter entirely.

From the ventilation came the smell of hot dust as braking systems left standby. A ceramic bird knocked once against the frame of
Mara's console. She had bought it from a child in the Archive, denied that it was a keepsake, and spent thirty-seven days moving it
to whichever surface currently defined forward. Now she caught it before the next attitude correction and put it in her pocket.

Six meanings of *return* occupied the room, each precise enough to rule out one bad solution. None yet authorized the burn.

Tala reached for the field manual strapped beneath her console. Its cover had softened during the voyage, and Sana's evidence tags
protruded from the binding at irregular intervals. Osei had repaired its spine with sailcloth at the Archive. Iona had drawn a
wiring route across one endpaper and then, after Sana objected, attached enough provenance to make the drawing admissible. Between
them lay the first programs Tala had written aboard *Vela*, beginning with an empty class in the construction berth and ending with
the distinction that might yet bring them through the burn.

The book did not contain a hidden answer. It contained the route by which they had stopped accepting convenient ones.

The relevant record began thirty-seven days earlier, under the heading [Departure](01-write-the-first-instruction.md).
