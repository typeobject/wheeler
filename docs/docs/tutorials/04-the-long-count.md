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

Twelve hours beyond the Archive, the first signal from the far instrument arrived as thirty-two binary observations and no
explanation.

```text
0 1 1 0 0 1 0 0
1 0 1 1 0 0 1 0
0 0 1 0 1 1 0 1
1 0 0 1 0 1 0 0
```

Mara put the sequence on the navigation display, where it resembled a route chosen by a nervous machine. Osei searched for a
protocol header. Sana checked the transmission identity and found that each digit belonged to a separate preparation at the same
remote source.

That distinction altered the record. Thirty-two readings from one object changing over time would have described a history.
Thirty-two readings from thirty-two fresh preparations described repeated trials.

Tala gave the smallest pieces names. A **trial** began with one declared preparation, carried out one bounded procedure, and ended
with one observed **outcome**. Here each trial produced either `0` or `1`. No trial produced a fraction, a ratio, or a little cloud
of both digits.

Mara selected the first `0`. "What does this tell us about the source?"

"That one trial ended in zero," Tala said.

"And the next one?"

"Ended in one."

Such answers sounded deliberately unhelpful because the questions were asking individual outcomes to describe a pattern. Sana
copied the complete sequence into a new record and called the collection a **sample**. Only then did Tala count.

```text
outcome 0: 18
outcome 1: 14
total:     32
```

Nothing in the count changed any recorded digit. Counting reduced the sample to two totals and discarded order. To preserve the
shape of those totals, the manual drew one mark per trial.

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

Mara enlarged the two bars. "How many trials settle it?"

Sana looked at the source claim attached to the model. "Settle what?"

Sana's question restored the missing scope. A larger sample could estimate frequencies more tightly under stated assumptions. It
could not transform an unstated preparation into a known one, establish independence that the procedure had not guaranteed, or
turn agreement with one model into proof that no other model fit.

To make the operational boundary visible, Osei requested another thirty-two preparations from the recorded simulator profile. He
named the target, shot count, and seed before execution.

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

Tala placed the first outcome, the first sample, and the model side by side.

| Object | Statement it supports |
| --- | --- |
| One outcome | One declared trial ended in `0` or `1` |
| One sample | These bounded trials produced these counts and frequencies |
| Probability model | The declared preparation and operation assign these outcome probabilities |

With those names in place, three common substitutions became visible. One outcome was not a distribution. A histogram was not its
generating model. A probability was not a promise about the next trial.

Outside the ship, the far instrument continued to transmit. The new packets contained no binary outcomes. Instead, they described
two routes by which one calibration signal reached the same detector, together with signed entries that ordinary probabilities
could not accommodate.

Mara watched one pair add and another disappear. "Counts do not cancel."

They did not. The manual turned to [Contributions That Cancel](05-contributions-that-cancel.md).
