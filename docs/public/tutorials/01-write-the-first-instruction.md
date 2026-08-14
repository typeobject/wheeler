---
sidebar_position: 2
title: Departure
description: An empty program learns just enough to release Vela from her berth.
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

Thirty-seven days before the failed return, *Vela* waited in Yard Nine: hull nearly closed, arguments still open.

Construction berths occupied Catenary's least fashionable wheel. Gravity changed from corridor to corridor. The air tasted of cut
alloy. Every public wall carried two loads: what the architect had allowed and what the residents had since attached.

Welders crossed the vault on articulated lines. Below them, if *below* could be trusted in a wheel, *Vela* lay in a web of fuel,
data, and cooling lines. Half her hull reflected the berth lamps. The other half kept the soot of earlier voyages.

Mara met Tala at the service lock. The pilot's welcome consisted of a pressure check, a brisk inventory of exits, and a question
about whether Tala became sick in variable gravity. Then she introduced the ship in the order she expected to need it: attitude,
drive, navigation, power, air. Coffee entered the list between power and air, then moved upward when Tala asked whether the galley
unit worked.

"Good," Mara said. "You understand critical systems."

It was the warmest thing she said for the next three hours.

Tala was a systems analyst. For seven years she had traced faults through municipal transit software, where vehicles stayed on the
ground and most state could be copied without consulting physics. Her last network had once announced itself restored while
fourteen passenger cars waited between stations under manual power.

The copied control state was perfect. It was six minutes old.

Neris Venn, the transit director, had two platforms approaching their air limit and a crowd beginning to test locked doors. She
ordered the network reopened from the green control state. Tala invoked the safety veto because the fourteen cars existed outside
that copy. Neither woman had mistaken the pressure on the other. Venn needed movement before the platforms became dangerous. Tala
needed the movement to account for vehicles the dashboard had forgotten.

The cars came back under local control. The public report called the service restored and blamed the additional delay on Tala's
veto. Neither statement was false. Together they were a lie with good posture.

She embarrassed Venn, kept the report, and acquired the kind of reputation that becomes expertise when a different employer needs
it.

Venn's reference apologized for nothing. It said Tala would stop a working system when its account of the world omitted something
physical, then listed the cost of employing anyone willing to do that. Less a recommendation than a warning, but an honest one.

That failure had won her a place on the far-instrument mission. During their first conversation, Osei made clear that it had not
prepared her for the work.

"You know how to distrust a green display," he said, looking at the folded reference.

"Professionally."

"Good. Here, six minutes can be farther away than another planet."

He was waiting in the machine room beside an open rack. Instead of a greeting, he handed her a field manual bound in gray cloth.

"Read the annotations before the printed text," he said. "The text was approved."

No author appeared on the oldest title page. Sana's slip named several probable owners, rejected the impossible dates, and traced
the binding glue to a repair shop on Selene. Propellant arithmetic filled one margin. Another hand corrected it without erasing the
mistake. Lost pressure doors survived by name among the blank leaves.

The book carried engineering forward without pretending it had traveled in a straight line.

Beneath the slip, a handwritten instruction survived in faded blue ink.

```text
Begin with a program that has nowhere to go.
```

Tala opened the Wheeler workspace at the terminal built into the rack and created a directory for the manual's programs.

```bash
mkdir -p manual
```

The first source, `manual/Wake.w`, looked less like a program than a place where one might eventually occur.

```wheeler
classical class Wake {
  entry void main() {
  }
}
```

The manual showed the whole before naming its pieces. `classical` selected ordinary program state. A `class` gathered state and
operations beneath the name `Wake`. Execution entered at `main`. `void` said no value would be returned when it finished. The
braces marked what belonged inside. For now, almost nothing did.

This written form was a **source file**. A compiler could read it and make something executable. Editing the source afterward would
not reach into the past and alter what had already been built.

She invoked the compiler from the repository root.

```bash
wheeler compile manual/Wake.w -o manual/Wake.wbc
```

The compiler reported its output.

```text
wrote manual/Wake.wbc (360 bytes)
```

`Wake.wbc` was the **artifact**: checked, translated, ready to run. Not yet run. Someone had driven that warning through three
leaves of the manual.

```text
A compiled promise remains a promise.
```

Execution required another boundary and another command.

```bash
wheeler run manual/Wake.wbc
```

The runtime entered `main`. It found nothing to do. It stopped.

```text
Wake (classical) halted after 1 steps
```

One entry. No state. No answer. Almost nothing had happened, and for once almost nothing was easy to describe.

Sana arrived while Tala compared the source with what the compiler had made. She asked for both, and for the compiler and run
reports. A thin Archive seal hung at her throat with its inscription turned inward. On Catenary, where people displayed former
institutions as readily as present loyalties, the choice was conspicuous.

"All this for an empty program?" Tala asked.

Sana looked through the rack toward the unfinished ship. Outside, a worker struck the pressure hull, listened, and marked the panel
with chalk.

"Cheap records are where you learn whether the costly ones lie."

Beneath that note, the next annotation added a state declaration.

```wheeler
classical class FirstSignal {
  state long lamp = 0;

  entry void main() {
  }
}
```

`long` held a signed whole number. `lamp` named a **state value** belonging to the program. `0` was where it began. The empty entry
left it there.

```text
FirstSignal (classical) halted after 1 steps
lamp = 0
```

At that moment Mara entered the machine room carrying a physical readiness lamp removed from the flight deck. Its lens was dark.
She set it beside the terminal, where it acquired more presence than the number on the screen.

"Zero is accurate," Tala said.

"The lamp agrees. The ship does not care."

"You brought me hardware to argue with a variable?"

"The hardware was closer. Make it ready."

An assignment inside `main` replaced the current program value. Tala renamed the small experiment and kept every other change
visible in one complete source.

```wheeler
classical class CabinLamp {
  state long lamp = 0;

  entry void main() {
    lamp = 1;
  }
}
```

Now the path had direction: `0 -> 1`. A single `=` changed the value. The final report showed where it came to rest.

```text
CabinLamp (classical) halted after 3 steps
lamp = 1
```

Mara reinstalled the lamp. Nobody pretended the number had lit it. The little program described one condition. The ship still
required power, wire, logic, glass, and the crescent of dust along the lens.

Osei took her place at the console before she had technically offered it. One transition, he said, concealed the question that
mattered to him. He added a second assignment to a state named `signal`.

"Does everyone on this ship teach by taking the controls?" Tala asked.

"Mara teaches by removing parts first," he said. "This is safer."

```wheeler
signal = 1;
signal = 2;
```

From `0`, execution went `0 -> 1 -> 2`. Reverse the lines and the path became `0 -> 2 -> 1`. Instructions were not a basket of
intentions. **Source order** chose the road, even when the report showed only its end.

Sana, reading over his shoulder, objected to the path existing only in their explanation. A later edit could change the assignment
while leaving the explanation intact, a form of durability the archive profession had learned to distrust. She placed an
executable expectation after the transition.

```wheeler
assert(signal == 2);
```

Unlike the assignment's single `=`, the doubled `==` compared the current value with `2`. `assert` required that comparison to
hold at that position in the run. If it held, execution continued. If it failed, the runtime trapped instead of publishing an
ordinary successful halt.

A passing assertion said less than people often wanted. At this point in this run, the comparison held. Sana trusted its modesty.

Station night dimmed the berth lamps, though Yard Nine never stopped. Restaurants served breakfast to one shift and fermented
broth to the next. Families gathered at pressure windows. Freight crews painted temporary constellations on hull plates soon to be
sold for scrap.

Inside *Vela*, the little examples converged on the departure interlock Mara actually needed.

Tala gave the known sequence a method name, `depart`, then called that method from `main`. A method collected instructions into a
named body. A method call transferred control into that body and resumed after the call when the body finished.

In the manual's margin, the word *return* appeared beside its first correction.

```text
Control returns to the caller.
State has not thereby returned to an earlier value.
```

One screen held the complete program.

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

Before execution, Tala traced both values. `berth` would follow `1 -> 0`. `drive` would follow `0 -> 1`. The call would finish
before either assertion examined the state.

She compiled the source on the screen and ran what it produced.

```text
FirstWatch (classical) halted after 9 steps
berth = 0
drive = 1
```

The report kept declaration order, so the names stayed beside their values. Both assertions had passed. Sana wrote no larger claim:
this build of the program had finished with its modeled berth released and drive enabled.

Mara waited for its record and for Osei's review before touching the physical controls. A pilot's trust was not boundless. That was
what made it trust.

The clamps opened.

Metal that had carried *Vela* for nine months withdrew into the berth. The ship slipped under attitude control into the dark between
structures. Yard gravity released Tala's feet. A loose washer rose from the deck, crossed the bridge with stately confidence, and
vanished beneath Osei's palm.

"Fourth inventory," Sana said.

Osei closed his fist around the washer. "The first three established a trend."

Catenary turned beyond the glass: greenhouse bands, repair lights, a funeral lantern drifting from an old wheel. Then Yard Nine
rotated away.

Tala had expected departure to feel like a line crossed. Instead the station remained where it had always been, only small enough
now to cover with one hand.

On the communications panel, traffic control reduced their departure to a pair of values repeated in alternation.

The manual gave those alternating values a name: [Two Signals](02-ask-the-machine-to-act.md).
