---
sidebar_position: 5
title: The Long Count
description: A sequence of binary observations separates one outcome from a sample and a probability model.
tutorial_id: CH04
tutorial_steps: T24,T25,T26,T27,T28,T29
tutorial_part: probability
tutorial_order: 4
tutorial_kind: conceptual-and-recorded-data
tutorial_source: recorded-signal
tutorial_expectation: bounded-histogram
tutorial_evidence: exact-recorded-observations
---

# The Long Count

Twelve hours beyond the Archive, traffic disappeared. *Vela* entered the cold reach between inhabited orbits, where rescue plans
were measured in weeks and a ship's discarded heat was the brightest nearby object. The crew changed to passage time. Mara slept
in four-hour intervals, Osei listened to pumps during meals, and Sana opened a fresh mission ledger each morning even though no
external event had occurred overnight.

Privacy became a scheduling convention rather than a place. Tala learned which floor panel creaked outside Sana's bunk, how long
Mara could remain silent before silence became concern, and that Osei dismantled harmless equipment when he missed work he could
not reach. They ate from magnetic trays around the chart table because the galley had enough seats or enough working displays, but
not both. The field manual traveled with the person on watch.

The far instrument circled Sable, a captured moon so dark that early surveyors had mistaken its shadow for missing data. Its first
signal arrived as thirty-two binary observations and no explanation.

```text
0 1 1 0 0 1 0 0
1 0 1 1 0 0 1 0
0 0 1 0 1 1 0 1
1 0 0 1 0 1 0 0
```

Mara put the sequence on the navigation display, where it resembled a route chosen by a nervous machine. Pilots had once crossed
the reach by reading pulsar fixes through charged dust. A few still kept old binary ephemerides above their bunks, and Mara's first
instinct was to see direction in any ordered lights. She traced the first eight digits with one finger before stopping herself.

Osei searched for a protocol header. Sana checked the transmission identity and found that each digit belonged to a separate
preparation at the same remote source. The packet was not a navigation instruction. It was the instrument's calibration greeting,
designed to reveal what a receiving crew assumed before the actual data arrived.

That distinction altered the record. Thirty-two readings from one object changing over time would have described a history.
Thirty-two readings from thirty-two fresh preparations described repeated trials.

Tala gave the smallest pieces names. A **trial** began with one declared preparation, carried out one bounded procedure, and ended
with one observed **outcome**. Here each trial produced either `0` or `1`. No trial produced a fraction, a ratio, or a little cloud
of both digits.

Mara selected the first `0`. "What does this tell us about the source?"

"That one trial ended in zero," Tala said.

"And the next one?"

"Ended in one."

"I had hoped distance would improve your conversation."

Tala had hoped the same. On Catenary she could soften a bounded answer with context supplied by a thousand nearby systems. Out
here, an unsupported story would cross the reach faster than its correction.

Such answers sounded deliberately unhelpful because the questions were asking individual outcomes to describe a pattern. Sana
copied the complete sequence into a new record and called the collection a **sample**. Only then did Tala count.

```text
outcome 0: 18
outcome 1: 14
total:     32
```

Nothing in the count changed any recorded digit. Counting reduced the sample to two totals and discarded order. Sana kept the
original sequence in view while Tala worked, an old Archive habit that made every reduction answerable to what it had left out.
Above the console, Mara's ceramic bird pointed its beak toward the deck under thrust and drifted sideways when the engines rested.

To preserve the shape of those totals, the manual drew one mark per trial.

```text
0 | ################## 18
1 | ##############     14
```

Drawn this way, the sample became a **histogram**. Its bars represented counts, not amplitudes, physical waves, or confidence.
Reordering the thirty-two observations would leave the histogram unchanged even though it would produce a different sequence.

Osei divided each count by the number of trials.

| Outcome | Count | Frequency |
| --- | ---: | ---: |
| `0` | 18 | `18 / 32 = 0.5625` |
| `1` | 14 | `14 / 32 = 0.4375` |

A **frequency** belonged to this finite sample. The source specification, when Sana finally recovered it from the following packet,
contained a different kind of number.

```text
model probability of 0: 0.5
model probability of 1: 0.5
```

A **probability model** assigned expected long-run weights to the possible outcomes before the particular sample was known. It did
not promise sixteen zeros and sixteen ones in every block of thirty-two. The observed frequencies could differ from `0.5` without
contradicting the model, just as a small sample could happen to match `0.5` without proving the model.

Mara enlarged the two bars. The first calibration deadline was approaching, and a number of trials sounded like the kind of answer
that could be put on a schedule. "How many settle it?"

Sana looked at the source claim attached to the model. "Settle what?"

The question had the force of a hand closing over an unsafe control. Sana's question restored the missing scope. A larger sample
could estimate frequencies more tightly under stated assumptions. It could not transform an unstated preparation into a known one,
establish independence that the procedure had not guaranteed, or turn agreement with one model into proof that no other model fit.

To make the operational boundary visible, Osei requested another thirty-two preparations from the recorded simulator profile. He
named the target, shot count, and seed before execution. The request entered the mission ledger before anyone knew whether its bars
would look persuasive.

```bash
wheeler run tutorial/BinaryTrials.wbc \
  --target ideal \
  --shots 32 \
  --seed 104729
```

A second sample produced a different sequence and a nearby histogram.

```text
0 | ################ 16
1 | ################ 16
```

Same procedure. Same model. Different observed counts. Because the seed belonged to the execution identity, repeating that exact
command reproduced the same sample. Changing the seed created another deterministic simulator experiment rather than revealing
what unseeded hardware must do.

The arrival protocol required Mara to acknowledge the greeting before the instrument would reserve their close approach. Waiting
for a larger transmitted sample would cost six hours and still would not establish facts the preparation record had failed to
state. Proceeding without scope would turn schedule pressure into an invented conclusion.

"What can I sign?" she asked.

Tala read the record again. "That these thirty-two instrument trials produced these counts. That the attached model assigns equal
probability. Not that one proves the other."

Mara entered those claims separately, accepted the close approach, and kept the contingency fuel she would need if later packets
contradicted the declared preparation. Uncertainty had narrowed the decision. It had not made action impossible.

Tala placed the first outcome, the first sample, and the model side by side.

| Object | Statement it supports |
| --- | --- |
| One outcome | One declared trial ended in `0` or `1` |
| One sample | These bounded trials produced these counts and frequencies |
| Probability model | The declared preparation and operation assign these outcome probabilities |

With those names in place, three common substitutions became visible. One outcome was not a distribution. A histogram was not its
generating model. A probability was not a promise about the next trial.

Outside the ship, the reach remained empty enough that the far instrument's carrier tone felt like company. New packets crossed
the hours between Sable and *Vela*. They contained no binary outcomes. Instead, they described two routes by which one calibration
signal reached the same detector, together with signed entries that ordinary probabilities could not accommodate.

Mara watched one pair add and another disappear. "Counts do not cancel."

The cabin lights had entered artificial evening. For the first time since Catenary vanished, nobody moved to end the watch.

They did not. The manual turned to [Contributions That Cancel](05-contributions-that-cancel.md).
