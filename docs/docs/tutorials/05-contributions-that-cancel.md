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

Inside the far instrument, two routes connected its calibration source to one detector. The next packet described neither route as
a probability. Each carried a signed real contribution to the same destination.

```text
source
  |\
  | \ route B
  |  \
route A \
  |     \
  +---- detector
```

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

Together, the routes reinforced. Replacing both signs with minus left the magnitude of the sum unchanged.

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

For that relation, the manual used **phase**. At this stage only two phases were needed, represented by positive and negative real
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
recorded. Tala noticed that the exercise had changed their use of *path*: a path no longer implied an independently observable
history.

Here the distinction mattered. The diagram was a calculation over alternatives in a model. It did not establish that a particle had
traveled along one hidden route, split into physical copies, or sent messages between paths. A later quantum experiment would
specify the preparation and operation that made the sum predictive.

At the edge of sensor range, the far instrument opened its receiving aperture. Its identification packet declared a physical
system with two distinguished measurement outcomes and a controlled interface for preparing it.

For the first time, the manual printed the word it had withheld.

```text
QUBIT
```

Beside `QUBIT`, the accompanying chapter carried the title [One Qubit](06-one-qubit.md).
