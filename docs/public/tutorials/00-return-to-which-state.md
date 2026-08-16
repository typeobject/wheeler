---
sidebar_position: 1
title: Home
description: Eleven minutes from braking, Vela discovers that position, workspace, evidence, and home have shared one unsafe name.
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

Catenary assembled itself in the forward glass while Tala watched from the
starboard systems station. Six days of unbroken stars gave way first to traffic
lamps, then yard beacons, then the pale rims of inhabited wheels. Human geometry
crowded the constellations toward the edges.

Mara sat on the bridge centerline with one hand near the burn cage. Osei worked
to port, and Sana had unfolded her evidence desk beside the aft hatch. The braking
clock showed eleven minutes.

The nearest garden wheel rolled over Yard Nine and laid a moving green reflection
across Mara's console. Behind it, a freight drum turned at half the rate. Air
lines crossed the gap between them in flexible silver loops. The old charter
builders had forbidden those connections; Tala could still see their separate
seals on the hubs. The pipes had outlived the prohibition.

Her approach pane asked every person aboard to renew Catenary residency. Four
names turned green. None of them had been born in the habitat. Membership here
was a current obligation: match the city's motion, account for mass at the dock,
and answer for whatever entered through its pressure seals.

Mara read burn times aloud. Each number shortened the room. Osei closed machinery
that had remained open during passage, and the port-side schematic lost one blue
branch after another. At Sana's desk, separate stores began feeding the mission
chain onto a single pane.

The first link had arrived ahead of them by fallback radio: Sable's compact
manifest, thin enough for the west bearing to carry after the narrow laser lost
Catenary. The rest sat in sealed storage beneath Tala's boots. Clock comparisons,
particle readings, chamber receipts, and every correction between them had needed
a hull.

That was how the Second Navigation crossed distance. Light brought warning.
Someone still had to arrive carrying the grounds for trust.

A charged front was already folding around the Giant toward Catenary. Traffic
control needed Sana's chain before it committed the beacons to a new profile. If
Mara missed this burn, *Vela* would spend nineteen hours in the outer loop, use
most of her reserve, and deliver the evidence after the decision it was meant to
support.

Eleven minutes before the burn, amber covered the approach plot.

```text
RETURN CHECK FAILED
```

Mara kept one hand within the burn cage. The clock froze while she remained perfectly still.

"Name the failure."

Osei opened the restoration branches until they overlapped on the glass. "Workspace."

Sana had yet to move. "Lineage."

Both answers reached Tala. Systems analysis was the office written beside her name. In practice, she stood where another person's
certainty crossed out of its jurisdiction.

She opened the four reported fields.

```text
navigation       home
workspace        not restored
mission result   present
result lineage   incomplete
```

"Position has us home," Mara said.

"Position is enjoying a smaller problem," Osei said.

Sana turned toward him. "Your map chose its own border too."

Tala touched `navigation`, and a line ran to Mara's approach solution: mass inside
the corridor, velocity converging, no collision ahead. `workspace` opened Osei's
restoration map and stopped at an amber branch. `lineage` crossed to Sana's desk,
where one edge ended in empty space.

The report had given all three lines the value *home*.

A vibration passed through the deck as the hospital-barge radiator changed flow.
*Vela* herself made the word difficult. Survey plating enclosed them. A racing
tug's maneuvering model counted their reserve. Refit crews had replaced hardware
for decades without finding a moment when the ship ceased to be *Vela*.

Tala searched the report for every use of *return*. Source methods returned
answers. Reversible functions offered inverse execution. VM history could be
spent in rewind. Mara used the word for arrival, a meaning older than any
component aboard.

On an ordinary voyage those meanings never needed to agree. Freight could arrive
with dirty workspace. A doubtful test could be repeated. Spare propellant could
buy another orbit.

This observation had one physical past. Sable's chamber was cooling toward maintenance, and the charged weather would soon age its
calibration beyond use. The crew could preserve the observation, reject it, or state its reach. The systems that produced it could
never occupy that earlier moment again.

Sana exposed the selected result. Near the final edge of its lineage sat a small quantum source. Tala knew the grammar before she
understood why the return policy had reached into it.

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
Tala had yet to learn. The record beneath them was plain enough.

```text
Bell (quantum) halted after 4 steps
measured = 3
measurements = [3]
```

"Three came home," Mara said. "We have that much."

"Three was observed and retained," Sana said.

Mara's fingers tightened inside the cage. "Can that observation clear my burn?"

Osei drew the amber branch across their displays. "The checker says its workspace never came back."

Tala had always trusted numbers to lose their drama when divided into smaller questions. This one became louder.

The ideal simulator had yielded `3` on one run. Another preparation could yield another value, and an identical histogram could
come from a state with a different history. Measurement had ended access to the unknown state that preceded the number. Two bits
of outcome now carried a problem larger than themselves.

"We know what was observed," Tala said. "We have not established what the observation answers."

"It was friendlier when it was three."

Sana held Tala's gaze. Outbound, such a pause had usually ended with a narrower sentence. She copied this one into the account.

At nine minutes, Catenary demanded a braking commitment. Mara sent the station code for *technical hold, crew in control*. Ninety
seconds entered their account, along with the voice of Neris Venn, director of traffic continuity. Tala recognized her before the
nameplate appeared.

"Which statement is unsafe?" Venn asked.

"We are separating it now," Tala said.

Traffic law granted that hold once per approach.

Osei traced the workspace warning to work performed at the far instrument. Its retained VM history stopped at commit, closing the
road to rewind. A generated adjoint remained bound into the artifact, though that operation could not reach through measurement to
the state already consumed.

Braking hardware woke, and hot dust entered the ventilation. The Archive bird above Mara's console tipped free and struck its
ceramic beak against the frame. For thirty-seven days she had moved the little weight whenever thrust redefined down, all while
denying that she kept souvenirs. She caught it and closed it inside her pocket.

Every meaning of *return* now prohibited its own shortcut. With a full tank, Tala might have admired the precision.

Tala reached for the gray shipboard recension strapped beneath her console. It
belonged to the scattered family of manuals called the Common Book of Return,
though no council had accepted a common text. The cover had softened during the
voyage. Sana's paper tags bristled from the binding. Osei had repaired the spine
with sailcloth at the Archive. Iona had drawn a wiring route across one endpaper,
then supplied its date and authorship after Sana objected. Between them lay Tala's
first programs aboard *Vela*: an empty class in the construction berth, a black
moon, and at last the distinction that might carry them through the burn.

The gray book offered no verdict. Its pages preserved the experiments that had taught the crew to distrust easy words.

Thirty-seven days earlier, Tala had opened its first unwritten leaf in Yard Nine: [Departure](01-write-the-first-instruction.md).
