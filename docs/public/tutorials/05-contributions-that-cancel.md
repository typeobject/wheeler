---
sidebar_position: 6
title: Contributions That Cancel
description: Two possible paths meet at one detector. Together they can brighten, darken, or disappear.
tutorial_id: CH05
tutorial_steps: T30,T31,T32,T33,T34,T35
tutorial_part: interference-foundations
tutorial_order: 5
tutorial_kind: conceptual-table
tutorial_source: calibration-record
tutorial_expectation: signed-path-sums
tutorial_evidence: exact-arithmetic
---

# Contributions That Cancel

The next packet arrived during the radiator roll. *Vela* turned broadside to the star and offered her patched port wing to cold
space. Sunlight crossed the inhabited rooms in bars. Shadow followed. Sunlight again.

A loose galley line tapped the bulkhead once per rotation. Nobody repaired it. By then the sound belonged to the voyage.

Inside the model, two routes connected a calibration source to one detector. These were parts of a calculation, not secret paths
inside the microwave signal now crossing the reach. Neither route carried a probability. Each brought a signed contribution to the
same destination.

```text
source
  |\
  | \ route B
  |  \
route A \
  |     \
  +---- detector
```

The diagram occupied a whole page. Earlier hands had added waves, arrows, even a pair of canals. Sana covered them.

"I liked the canals," Mara said.

"The canals imply water."

"I was not planning to drink the calculation."

The pictures could wait. First the arithmetic had to stand alone.

Tala began with equal positive entries.

| Route | Contribution at detector |
| --- | ---: |
| A | `+1/2` |
| B | `+1/2` |

When alternatives met at one destination, their contributions added *before* any outcome weight appeared.

```text
+1/2 + +1/2 = +1
```

The routes reinforced. Mara called the answer before Tala uncovered it and leaned back as though prediction conferred ownership.
Turn both signs negative and the total pointed the other way, but kept the same magnitude.

```text
-1/2 + -1/2 = -1
```

Mara objected to the negative total on practical grounds. Detectors did not report minus one event.

"If they did," she said, "traffic accounting would become much easier."

Osei agreed with the objection, not her conclusion. These were not event counts. The signed sum came first. Probability would be
made from its magnitude later.

Only one sign changed in the third packet.

| Route | Contribution at detector |
| --- | ---: |
| A | `+1/2` |
| B | `-1/2` |

Now the addition produced nothing at that destination.

```text
+1/2 + -1/2 = 0
```

Osei requested the packet again. Same checksum. He looked for a disabled route, a failed source, a detector discarding negative
values, the ordinary failures first. The calculation contained none of them.

Both routes remained. Both contributions remained. The destination went dark because equal magnitudes arrived with opposite signs.

Sana compared the three cases.

| Route A | Route B | Sum | Squared magnitude |
| ---: | ---: | ---: | ---: |
| `+1/2` | `+1/2` | `+1` | `1` |
| `-1/2` | `-1/2` | `-1` | `1` |
| `+1/2` | `-1/2` | `0` | `0` |
| `-1/2` | `+1/2` | `0` | `0` |

In the first two rows, both signs turned together and the squared magnitude held. In the last two, one relative sign erased the
outcome. The relation mattered. The common direction did not.

A timing record accompanied each route. The clocks descended from Sable's first navigation network, whose technicians had settled
disagreements by carrying sealed oscillators through tunnels in the moon. Nobody needed to walk the clocks through rock anymore.
The maintenance language still called every comparison a *meeting*.

The manual called the relation between those signs **phase**. For now, two phases were enough: positive and negative. Other angles
would come later. To draw the whole complex plane now would make notation look like explanation.

Probability alone could not supply this arithmetic. Two ordinary probabilities were nonnegative. Adding them could increase or
preserve a total, never cancel equal alternatives to zero.

```text
p(A) >= 0
p(B) >= 0
therefore p(A) + p(B) >= 0
```

Cancellation required another order of work: assign signed contributions. Add those that meet. Only then take the magnitude that
becomes probability. Soon the contributions would receive their quantum name.

Osei recreated the four rows on a diagnostic panel. Instead of trusting the table, he covered the final columns and asked each
crew member for the sum. Mara answered fastest on the reinforcing rows. Sana refused to square a value until its sign had been
written down. Tala missed the final cancellation because she had carried a minus sign from the previous row.

Osei uncovered the answer without comment.

"You can say it," Tala told him.

"I can also reset the panel. One of those improves the next attempt."

They began again. Beyond the glass, sunlight crossed a radiator seam and the cabin flashed copper.

By the last row, *path* no longer meant a private history waiting to be observed.

The diagram summed alternatives in a model. It said nothing about a particle secretly choosing one route, splitting into copies, or
sending messages between paths. Preparation and experiment, not the picture, would decide when the sum predicted nature.

At the edge of sensor range, Sable appeared as absence against the dust-bright plane of the system. The first settlers came to
anchor navigation clocks. They stayed because every clock required comparison, and every comparison required repair.

Radiation storms drove the camps underground after erasing three years of exposed work. The modern station inherited the tunnels,
the language of meetings, and a suspicion of anything advertised as permanent.

The far instrument opened its receiving aperture. Towers emerged one by one from the moon's darkness, visible not by their light
but by the stars they hid.

Then the habitation signal: water sufficient. Pressure holding. Five people. One visitor berth. No uncontained illness.

Its identification packet declared a physical system with two distinguished measurement outcomes and a controlled interface for
preparing it. A note from Iona Vale, the instrument's current keeper, accompanied the declaration.

```text
If the sums surprised you, keep them.
You will need them more than the pictures.
```

Osei read the note before Tala finished checking its identity. He knew Iona's habit of putting the instruction where a greeting
might have gone. Six years had not altered that economy. His hand rested over the unanswered bearing message, then moved away.

For the first time, the manual printed the word it had withheld.

```text
QUBIT
```

The word arrived as Sable's dark horizon filled half the forward glass.

Beside it: [One Qubit](06-one-qubit.md).
