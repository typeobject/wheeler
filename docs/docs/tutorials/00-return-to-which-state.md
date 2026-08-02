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
followed by the pale geometry of the orbital yards, until the constellations were no longer the largest structures in view. Mara
reduced the remaining distance to a column of burns and corrections. Osei began closing systems that had been open since departure.
Sana requested the final mission lineage.

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

*Vela* had been rebuilt often enough that nobody knew which subsystem was oldest. Hardware disappeared. Interfaces changed. Names
remained. *Return* meant the value produced by a function in one layer, inverse execution in another, the consumption of retained
history in a third, and physical arrival in the navigation code, where the word predated everyone aboard.

Routine voyages had never required those meanings to agree.

This one had.

Sana opened the result record. Near its end sat a small quantum program whose grammar Tala recognized before its purpose came into
focus.

```java
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

At nine minutes, the station requested their braking commitment. Mara answered with a delay code and no apology. Osei isolated the
unrestored branch to a computation executed at the far instrument, but its retained history ended at a commit boundary. Rewinding
through that boundary was unavailable. The source still had a generated adjoint somewhere in its artifact, though measurement had
made the original quantum state another matter entirely.

Six meanings of *return* now occupied the room, each precise enough to rule out one bad solution.

Tala reached for the field manual strapped beneath her console. Its cover had softened during the voyage, and Sana's evidence tags
protruded from the binding at irregular intervals. Between them lay the first programs Tala had written aboard *Vela*, beginning
with an empty class in the construction berth and ending with the distinction that might yet bring them through the burn.

The relevant record began thirty-seven days earlier, under the heading [Departure](01-write-the-first-instruction.md).
