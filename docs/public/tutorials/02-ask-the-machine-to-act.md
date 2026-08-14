---
sidebar_position: 3
title: Two Signals
description: Two lights in the dark become a bit, a flip, and the first hint of a way back.
tutorial_id: CH02
tutorial_steps: T08,T09,T10,T11,T12,T13
tutorial_part: finite-state
tutorial_order: 2
tutorial_kind: exact-and-conceptual-sequence
tutorial_source: primary-fence
tutorial_expectation: two-state-transition
tutorial_evidence: exact-classical-execution
---

# Two Signals

Behind them, Catenary spoke in microwave pulses. The station had official languages, neighborhood dialects, private whistles,
market slang. Traffic control trusted none of these with separation distance.

A pulse crossed the widening vacuum. It touched *Vela* as an analog tremor, passed through layers of hardware, and arrived on
Mara's console as a number.

Departure unfolded at many speeds. Ore carriers began braking days before berth. Passenger needles changed velocity with the
impatience of people who charged by the minute. Family habitats drifted so slowly their gardens leaned toward a different sun by
the time they cleared the yards.

Traffic control reduced them all to the same two replies.

One flotilla vessel carried a white thorn painted across its radiator spine. Mara magnified it until individual repair patches
became visible. She had grown up among the Thorn Families, whose addresses named a vessel, a pressure section, and the next three
planned transfers. In that childhood, home had never meant a fixed place. It meant that the pilot had matched velocity well enough
for two locks to meet.

Catenary was the first address Mara had held that remained valid while she traveled. She watched the thorn recede without opening a
private channel, then restored the traffic plot to its useful scale.

For the departure handshake, only two numbers were admitted.

```text
0  request absent
1  request present
```

*Two-state* did not mean the receiver possessed only two physical conditions. The antenna warmed. Amplifiers added noise.
threshold circuits wandered through voltages between their named levels. Once those details had done their work, the protocol let
them fall away. It kept one distinction: absent, present.

Mara waited for `1`, answered, watched the station fall back to `0`. Routine. The exchange carried no wisdom and none of the
farewells accumulating on private channels. Tala had two from former colleagues. Mara's came from food vendors who wanted their
accounts settled before distance became an excuse.

"Those are navigational hazards," Mara said when Sana noticed the queue.

"Only if the vendors own pursuit craft."

"Two of them cater tug crews. I am not ruling it out."

Osei had one from the Sable Instrument Cooperative. It addressed him as a delinquent member and contained a private line beneath
the maintenance vote.

```text
The west bearing outlasted your estimate.
It did not outlast the mission.
Iona
```

He marked the message to keep. He did not answer.

The manual had marked the two traffic values as unfinished business.

Tala opened the accompanying source.

```wheeler
classical class OneBit {
  state long bit = 0;

  entry void main() {
    assert(bit == 0);
    bit = 1;
    assert(bit == 1);
  }
}
```

A `long` could hold many whole numbers. This model allowed only `{0, 1}` and checked both states as it passed. The narrow rule, not
the size of the container, made the location a **bit**.

Tala compiled the source and executed its artifact.

```text
OneBit (classical) halted after 5 steps
bit = 1
```

The report showed one path: `0 -> 1`. Tala wrote, *the bit can change from zero to one*. Restrained, she thought. Safe.

It did not.

"This bit did," Sana said. "A claim about the operation needs every allowed input."

"There are two."

"Then completeness should be affordable."

Only two inputs existed. No statistics were needed. No faith either. Tala drew the rows.

| Input | Output |
| --- | --- |
| `0` | `1` |
| `1` | unknown |

The missing row mattered. Without it, the table described one transition, not an operation over both states. Begin at `1` and the
assignment would give `1 -> 1`, not the exchange Mara meant by *flip*.

Osei joined them at the chart table. Catenary receded behind him. Beside the navigation plot, a fan impeller lay in pieces. On
*Vela*, abstraction happened wherever repair work surrendered a flat surface.

He drew two dots, labeled them `0` and `1`, and asked for the least eventful operation possible. Tala connected each dot to itself.

| Input | Output |
| --- | --- |
| `0` | `0` |
| `1` | `1` |

This was the **identity operation**. Either input remained itself. Deliberate inaction was still a whole mapping. An unchanged end
never proved that nothing had happened around it.

Mara added a second table from the departure protocol.

| Input | Output |
| --- | --- |
| `0` | `1` |
| `1` | `0` |

This was the **flip operation**: an exchange, not an assignment to `1`. Each input had one destination. The destinations did not
collide.

Tala drew the same rule as arrows.

```text
0 -> 1
1 -> 0
```

Same mapping, two views. The table exposed a missing case. The arrows made one operation easier to follow into the next.

Osei covered the labels and asked Tala to apply the flip twice. She traced the first input through both copies of the operation,
then repeated the work for the second.

| Input | After first flip | After second flip |
| --- | --- | --- |
| `0` | `1` | `0` |
| `1` | `0` | `1` |

Both inputs came home. Two changes composed into identity.

Mara regarded the result with the suspicion pilots reserve for facts that appear obvious only after someone has written them down.
"So it goes there and back."

"For both states in this model," Sana said.

"You invoice by the qualification?"

"Only when it prevents salvage."

"I am starting to understand why the Archive let you leave."

Sana folded the table into the mission record. "They did not use *let*."

Mara looked at the repaired impeller, then at the thinning lights of home, and let the answer stand.

Sana's qualification stayed. Two rows settled a world containing two possibilities. A larger world would demand more work. An
endless one, a different kind of argument.

Tala wrote *reversible* in the margin, then hesitated. The manual's earlier owners had crossed out the same word in three inks.
Beside it, the most recent hand had left a warning.

```text
Restoring one chosen input is a demonstration.
Defining one output for every input is an operation.
Recovering every input from its output will earn the next word.
```

The flip seemed to pass. Too easily. A rule learned only from success soon curdles into praise.

At the edge of traffic, *Vela* turned into the Archive corridor. The route was older than Catenary. Supply ships had followed it
when the outer settlements were pressure tents and a message might arrive before the sender's legal identity.

Now buoys kept the lane. Each remembered the latest correction in case the others forgot.

The Archive appeared first as jurisdiction, hours before it appeared as light. Checksums filled the receiver. Beneath them came the
sentence it had engraved into every public protocol:

```text
WHAT IS REMEMBERED CAN BE RETURNED
```

Sana read the line without expression. Her thumb found the inward-facing seal at her throat, held it for one breath, and moved
away. Osei read the motto twice.

The next surviving heading borrowed the Archive's claim: [The Archive](03-one-thing-to-remember.md).
