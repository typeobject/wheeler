---
sidebar_position: 2
title: Departure
description: In Yard Nine, Tala learns the first source and earns Mara's trust one visible transition at a time.
tutorial_id: CH01
tutorial_steps: T01,T02,T03,T04,T05,T06,T07
tutorial_part: ordinary-state
tutorial_order: 1
tutorial_kind: exact-execution-sequence
tutorial_source: primary-fences
tutorial_expectation: departure-state
tutorial_evidence: exact-classical-execution
---

# Departure

The service lock admitted Tala into a ship shaped like a narrow argument. One
passage ran forward between four sleeping berths, crossed a galley scarcely wider
than its table, and ended at the bridge. Behind the lock, the machine room pressed
against the drive shielding. Nine clamps held all of it inside Yard Nine while
the crew continued deciding whether *Vela* was ready to leave.

Mara met her inside the lock, tested her suit seal, and pointed to every exit
before offering a name. As they walked forward, local gravity changed direction
twice. A cable bundle claimed one wall, family storage nets another. The vanished
charter house still owned Yard Nine in three registries; the people who patched
its air and paid its spin tax had stopped waiting for the law to notice.

Beyond each open service panel, welders traveled the vault on jointed tethers.
Fuel hoses and cooling trunks descended toward *Vela*'s uncertain down. New hull
plates shone under berth lamps beside sections that still carried reentry soot.
The air tasted of cut alloy and hot sealant.

Mara presented the ship according to emergency priority as they moved: attitude,
drive, navigation, power, air. Coffee began below power and rose two places when
Tala stopped in the galley to test the unit herself.

"You recognize life support," Mara said. "Promising."

For most of the watch, her hospitality improved no further.

A green readiness lamp shone beside the machine-room rack. Tala disliked it on
sight.

The last green display she had trusted belonged to Catenary transit. It had shown
a perfectly restored control state while fourteen passenger cars continued under
local power beyond the copy. Six minutes separated the display from the physical
network.

She could still hear passengers striking the locked platform doors when Neris
Venn ordered service reopened. Air margins were falling on two platforms. Tala
used the safety veto because the missing cars were still on the rails. Venn had
needed movement before the crowd became its own emergency; Tala had needed every
movement to account for vehicles the green state had forgotten.

Local crews recovered the cars. The public report later called the service
restored and assigned the remaining delay to Tala's veto. She had carried a folded
copy ever since.

Osei drew that copy from beneath the gray book where Tala had set it. Venn's
reference contained no apology. It warned that Tala would stop apparently healthy
machinery when its model omitted something physical, then listed the cost of
giving her authority.

Osei tapped the paper. "You have evidence against the color green."

"Seven years of it."

"Keep the distrust. Out here, six minutes can contain a different world."

He was waiting in the machine room beside an open rack. Instead of a greeting, he
handed her a field manual bound in gray cloth. Ship crews called its many related
copies the Common Book of Return. Their programs and accident accounts had
crossed the Reach under different titles, gathering repairs faster than any
custodian could reconcile them.

"Begin in the margins," he said. "Approval lives in the middle."

The oldest title page named nobody. Sana's paper slip proposed several owners, discarded impossible dates, and identified a Selene
repair shop from the binding glue. Propellant sums crowded one margin. A later hand repaired the arithmetic while preserving the
error. Blank leaves carried the names of pressure doors no longer installed on any living ship.

Its knowledge had survived by wandering.

Faded blue writing waited beneath Sana's note.

```text
Begin with a program that has nowhere to go.
```

At the rack terminal, Tala opened a Wheeler workspace and made a directory for the book's exercises.

```bash
mkdir -p manual
```

`manual/Wake.w` contained the outline of an event and almost none of the event itself.

```wheeler
classical class Wake {
  entry void main() {
  }
}
```

The page presented the complete source before explaining its grammar. `classical` chose ordinary program state. The `Wake` class
held related state and operations. Runtime entry occurred at `main`; `void` promised no returned value. Braces enclosed the method
body, which currently enclosed silence.

This was a **source file**, written material from which the compiler could produce executable form. A later source edit would create
a new possibility. It could not revise an artifact already built.

From the repository root, Tala asked the compiler to bind it.

```bash
wheeler compile manual/Wake.w -o manual/Wake.wbc
```

The compiler named the thing it had written.

```text
wrote manual/Wake.wbc (360 bytes)
```

`Wake.wbc` was the **artifact**, translated and checked for execution. Readiness was still only readiness. Three separate hands had
pressed that distinction into the book.

```text
A compiled promise remains a promise.
```

Crossing into execution took its own command.

```bash
wheeler run manual/Wake.wbc
```

The runtime entered `main`, encountered the empty body, and halted.

```text
Wake (classical) halted after 1 steps
```

Execution made one entry and changed no state. It yielded no answer. Almost
nothing had happened, and for once the account was easy to keep.

Sana found Tala comparing source and artifact. She requested both, followed by the compiler report and execution account. A narrow
Archive seal rested at her throat with its inscription against her skin. Catenary residents often wore former allegiances openly;
Sana had turned hers away.

"You need four records for one empty body?" Tala asked.

Beyond the open rack, a yard worker sounded *Vela*'s hull with a hammer and drew a chalk ring around the answer.

"Learn the chain while failure is inexpensive," Sana said. "Later it will resist you."

The next annotated source gave the empty class one state value.

```wheeler
classical class FirstSignal {
  state long lamp = 0;

  entry void main() {
  }
}
```

A `long` represented a signed whole number. The name `lamp` identified **state** owned by the program, initialized to `0`. Since
`main` remained empty, execution left the value at its beginning.

```text
FirstSignal (classical) halted after 1 steps
lamp = 0
```

Mara arrived with the flight deck's readiness lamp in both hands. Its dark lens bore scratches from several former ships. Placed
beside the terminal, the hardware made the displayed zero look very small.

"The model says unready."

"The glass agrees," Mara said. "*Vela* remains unimpressed."

"Did you remove a flight component for rhetorical support?"

"It was within reach. Change the state."

Tala placed an assignment in `main`, replacing the current value, and renamed the experiment. She kept the full source visible so
nothing hid between versions.

```wheeler
classical class CabinLamp {
  state long lamp = 0;

  entry void main() {
    lamp = 1;
  }
}
```

Execution now followed `0 -> 1`. The single `=` performed assignment, and the run report exposed the final state.

```text
CabinLamp (classical) halted after 3 steps
lamp = 1
```

Mara carried the lamp back to the flight deck. The assignment had modeled readiness without delivering current to a wire. Physical
light still required its circuit, scratched lens, and a ship willing to supply power.

Osei occupied the terminal as soon as Mara left it. A single transition, he said, made the road easy to overlook. He gave a state
named `signal` two assignments.

"Is possession of the console part of every lesson?" Tala asked.

"Mara begins with disassembly. I have chosen restraint."

```wheeler
signal = 1;
signal = 2;
```

Starting at `0`, the instructions produced `0 -> 1 -> 2`. Exchanging their lines produced `0 -> 2 -> 1`. **Source order** governed
the path. A final value alone could not reveal which road execution had taken.

Sana refused to let their spoken explanation become the only witness. Prose could survive after an edit made it false, a familiar
Archive failure. She added an expectation the runtime itself would test.

```wheeler
assert(signal == 2);
```

The doubled `==` compared rather than assigned. At that point in execution, `assert` required `signal` to equal `2`. A true
comparison allowed the run onward; a false one trapped before the runtime could report an ordinary successful halt.

The passing assertion spoke only for this position in this execution. Sana copied it into the account without enlarging the sentence.

Catenary night lowered the yard lamps without quieting the wheel. One shift ate breakfast while another queued for fermented broth.
Children pressed their palms to pressure windows. Freight crews painted constellations on scrap plates that would lose the stars at
auction.

The small sources finally reached the interlock holding *Vela* in Yard Nine.

Tala gathered the transition under a method named `depart` and invoked it from `main`. A method gave a body of instructions one
name. Calling it moved control into that body; completion resumed execution after the call.

The margin introduced *return* and immediately narrowed it.

```text
Control returns to the caller.
State has not thereby returned to an earlier value.
```

The whole departure model fit within the terminal glass.

```wheeler
classical class FirstWatch {
  state long berth = 1;
  state long drive = 0;

  void depart() {
    berth = 0;
    drive = 1;
  }

  entry void main() {
    depart();
    assert(berth == 0);
    assert(drive == 1);
  }
}
```

Tala traced the values before running them. `berth` moved from `1` to `0`; `drive` moved from `0` to `1`. Both assignments inside
the call completed before the assertions inspected them.

She compiled the displayed source, then executed its artifact.

```text
FirstWatch (classical) halted after 9 steps
berth = 0
drive = 1
```

Declaration order kept each reported name beside its value. Both assertions passed. Sana entered a sentence no broader than the
run: this artifact had halted with modeled berth released and modeled drive enabled.

Mara read the execution account and waited for Osei's assent. Only then did she reach for the physical release. Her trust had edges,
which made it useful.

Nine clamps withdrew.

Under Catenary's Covenant, a vessel became responsible for her own pressure and
motion at that instant. The yard witness touched the old brass plate beside the
lock, a ceremony inherited from workers who had once watched charter ships leave
without knowing whether another payroll would follow.

The berth relinquished nine months of *Vela*'s weight. Attitude jets carried the ship into the open lane, where the yard's rotation
released Tala's boots. A washer lifted from the deck and sailed across the bridge with ceremonial calm. Osei captured it.

"That makes four," Sana said.

Osei pocketed the washer. "We now have a convincing series."

Greenhouse bands rolled beyond the glass. Repair lamps stitched one truss, and a funeral lantern drifted from an old wheel into its
allotted dark. Yard Nine turned out of sight.

Tala had expected a border. Catenary merely diminished until her open hand could hide the place that still held her residency.

Traffic control rendered the completed departure as two alternating values.

The next leaf began with the pair and called them [Two Signals](02-ask-the-machine-to-act.md).
