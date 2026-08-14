---
sidebar_position: 6
title: Contributions That Cancel
description: Two paths create the signed arithmetic needed to explain interference before a qubit appears.
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

The next packet arrived during *Vela*'s radiator roll. For twenty minutes the ship turned broadside to the primary, presenting her
patched port wing to cold space while the inhabited compartments passed through alternating bars of sunlight and shadow. A loose
line in the galley tapped the same bulkhead once per rotation. Nobody repaired it. The sound had become part of the passage.

Inside the far instrument, two modeled routes connected its calibration source to one detector. The routes belonged to a bounded
calculation sent ahead of the mission result, not to the microwave carrier now crossing the reach. The packet described neither
route as a probability. Each carried a signed real contribution to the same destination.

```text
source
  |\
  | \ route B
  |  \
route A \
  |     \
  +---- detector
```

The diagram occupied a full page of the field manual. Under it, four former owners had drawn waves, arrows, and once a pair of
canals. Sana covered the pictures. Whatever intuition they offered would have to wait until the arithmetic could survive without
them.

Tala began with equal positive entries.

| Route | Contribution at detector |
| --- | ---: |
| A | `+1/2` |
| B | `+1/2` |

When alternatives led to the same destination, the instrument's rule added their contributions before producing an outcome
weight.

```text
+1/2 + +1/2 = +1
```

Together, the routes reinforced. Mara called the result before Tala exposed the sum, then leaned back as if prediction had made
her responsible for it. Replacing both signs with minus left the magnitude of the sum unchanged.

```text
-1/2 + -1/2 = -1
```

Mara objected to the negative total on practical grounds. Detectors did not report minus one event. Osei agreed, but pointed out
that the table had not called its entries event counts. The signed sum was an intermediate quantity. A later rule would convert its
magnitude into a nonnegative probability.

Only one sign changed in the third packet.

| Route | Contribution at detector |
| --- | ---: |
| A | `+1/2` |
| B | `-1/2` |

Now the addition produced nothing at that destination.

```text
+1/2 + -1/2 = 0
```

Osei requested the packet again. The checksum matched. He checked whether either route had been disabled, whether the source had
failed between records, and whether the detector had silently discarded a negative value. All three explanations would have been
familiar machine faults. None appeared in the declared calculation.

No route had ceased to exist in the model. Neither contribution had become zero. Their sum vanished because equal magnitudes
arrived with opposite signs.

Sana compared the three cases.

| Route A | Route B | Sum | Squared magnitude |
| ---: | ---: | ---: | ---: |
| `+1/2` | `+1/2` | `+1` | `1` |
| `-1/2` | `-1/2` | `-1` | `1` |
| `+1/2` | `-1/2` | `0` | `0` |
| `-1/2` | `+1/2` | `0` | `0` |

Across the first two rows, the common sign changed while squared magnitude did not. Within the last two rows, one sign difference
changed the prediction completely. What mattered was the sign of one contribution **relative** to the other.

The instrument attached a timing record to each route. Its clocks descended from the first navigation clocks placed around Sable.
Technicians had once corrected disagreements among those machines by carrying sealed oscillators through tunnels in the moon. The
modern values no longer depended on a person walking through rock, but the maintenance language still called every comparison a
meeting.

The manual used **phase** for the relation exposed by the signs. At this stage only two phases were needed, represented by positive and negative real
signs. Later rotations would require complex numbers, but introducing a plane of arrows before the sign had done any work would
have made the notation look like a cause.

Probability alone could not supply this arithmetic. Two ordinary probabilities were nonnegative. Adding them could increase or
preserve a total, never cancel equal alternatives to zero.

```text
p(A) >= 0
p(B) >= 0
therefore p(A) + p(B) >= 0
```

To model cancellation, the instrument assigned signed contributions first, added all contributions reaching the same destination,
and only then converted the resulting magnitude into probability. Those contributions would soon receive their quantum name.

Osei recreated the four rows on a diagnostic panel. Instead of trusting the table, he covered the final columns and asked each
crew member for the sum. Mara answered fastest on the reinforcing rows. Sana refused to square a value until its sign had been
recorded. Tala missed the final cancellation because she had carried a minus sign from the previous row. Osei uncovered the answer
without comment and reset the panel.

They went through all four again. Beyond the glass, the sun crossed a radiator seam and turned the cabin briefly copper. Tala
noticed that the exercise had changed their use of *path*: a path no longer implied an independently observable history.

Here the distinction mattered. The diagram was a calculation over alternatives in a model. It did not establish that a particle had
traveled along one hidden route, split into physical copies, or sent messages between paths. A later quantum experiment would
specify the preparation and operation that made the sum predictive.

At the edge of sensor range, Sable appeared as an absence against the dust-bright plane of the system. The first settlers had come
to anchor navigation clocks, then remained because every clock needed a comparison and every comparison needed maintenance. Their
surface camps migrated underground after radiation storms erased three years of exposed work. The modern station inherited those
tunnels, the meeting language, and a suspicion of any component advertised as permanent.

The far instrument opened its receiving aperture. Towers emerged one at a time from the moon's darkness, not illuminated but
visible where they concealed stars. A habitation signal followed: water reserve, pressure status, five persons aboard, one visitor
berth available, no uncontained illness.

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

The word arrived with Sable's dark horizon filling half the forward windows. Beside it, the accompanying chapter carried the title
[One Qubit](06-one-qubit.md).
