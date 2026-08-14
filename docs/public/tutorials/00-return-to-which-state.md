---
sidebar_position: 1
title: Home
description: A failed return check breaks an ordinary word into all the things it was hiding.
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

For six days the forward windows had held only stars, hard and innumerable. Then came traffic lights, then the pale geometry of
Catenary's yards, until the constellations were no longer the largest structures in view.

Catenary was less a station than a civic argument conducted in metal: old wheels, young gardens, commercial yards, neighborhoods
that had acquired air before they acquired names. Each part turned at its chosen rate. From a distance, the lights braided
movement into something that looked intentional.

Nobody aboard *Vela* had been born there. They all carried Catenary residency, a different and more demanding fact. The habitat
considered arrival a matter of matching velocity, paying for dock mass, and taking responsibility for whatever crossed the pressure
seal in your luggage.

Mara reduced the remaining distance to burns and corrections. Osei closed systems left open since departure. Sana called for the
mission record. Tala watched Yard Nine turn into sunlight and tried not to count the windows around their empty berth.

The far instrument's compact manifest had crossed the reach by fallback radio, just in time for Catenary to retune its approach
beacons. The west tracking bearing could no longer hold the narrow outbound laser. Behind the manifest lay too much for radio:
clock comparisons, particle records, chamber logs, calibration receipts. *Vela* carried the rest.

Before the charged-particle front peaked, traffic control had to accept the chain or revert the beacons to their older profile.
Missing one braking window would not kill the crew. It would put *Vela* into a nineteen-hour contingency orbit, spend most of
Mara's reserve, and deliver the calibration after the decision it was meant to support.

With eleven minutes left before braking, *Vela* laid an amber sentence across the navigation plot.

```text
RETURN CHECK FAILED
```

Mara's hand remained inside the burn cage. Nothing in her posture changed, but the countdown stopped.

"Which part?" she asked.

Osei was already inside the restoration map, opening branches faster than the display could arrange them. "Workspace."

Sana did not touch her console. "Lineage."

They looked at Tala. Her formal responsibility was systems analysis. Her practical one was interrupting specialists just as
certainty carried them beyond the edge of their authority.

She expanded the report.

```text
navigation       home
workspace        not restored
mission result   present
result lineage   incomplete
```

"Navigation says home," Mara said.

"Navigation has a charmingly narrow definition of home," Osei replied.

"So does the restoration map," Sana said.

The contradiction lasted only until each of them chose a line. To Mara, return meant position: mass, velocity, approach corridor,
the clean arithmetic of not striking the station. Osei saw a state that had failed to restore. Sana saw a number severed from the
work that had produced it. Tala saw one ordinary word carrying more machinery than it could bear, while each specialist reached for the part they had been
trained to notice.

*Vela* had been rebuilt too often for anyone to know which part was oldest. Her pressure hull began as a survey tender. The port
radiator came from a hospital barge. The maneuvering model, from a racing tug whose owners had considered safety margins a form of
pessimism. Hardware vanished. Interfaces changed. Names survived.

*Return* meant a function's answer in one layer, inverse execution in another, the spending of remembered history in a third. In
navigation it meant arrival, and there the word predated everyone aboard.

Routine voyages let those meanings pass one another without meeting. Cargo could be delivered despite a workspace leak. Another test could replace a weak
record. A ship could miss a courteous arrival and take the outer loop.

Not this time. The physical chamber was entering maintenance. Its calibration would expire in the coming storm. The sealed
observation belonged to work already done. They might preserve it, reject it, or explain it. They could not ask the universe for
the same past twice.

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

A two-position register. A preparation. An operation called `H`. A controlled gate. Measurement. The terms marked a route through a subject
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

Three was at least a number. Tala preferred numbers to people. Numbers usually grew quieter under inspection. This one did not.

An ideal simulation had ended at `3`. A second run might end elsewhere. Matching digits alone could not establish entanglement.
Nothing after measurement could restore the state that had been measured. The number was small. The missing explanation was not.

"It is an observation," she said. "Not yet an answer."

"I liked it better as a number," Mara said.

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

Too many meanings of *return* occupied the room. Each forbade a different bad solution. The distinction might have been beautiful with
more fuel.

Tala reached for the field manual strapped beneath her console. The cover had softened during the voyage. Sana's paper tags
bristled from the binding. Osei had repaired the spine with sailcloth at the Archive. Iona had drawn a wiring route across one
endpaper, then supplied its date and authorship after Sana objected. Between them lay Tala's first programs aboard *Vela*: an empty
class in the construction berth, a black moon, and at last the distinction that might carry them through the burn.

The book did not contain a hidden answer. It contained the route by which they had stopped accepting convenient ones.

The relevant record began thirty-seven days earlier, under the heading [Departure](01-write-the-first-instruction.md).
