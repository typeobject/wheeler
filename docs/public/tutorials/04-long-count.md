---
sidebar_position: 5
title: Long Count
description: A string of distant signals refuses to become a pattern until the crew learns what may be counted.
tutorial_id: CH04
tutorial_steps: T24,T25,T26,T27,T28,T29
tutorial_part: probability
tutorial_order: 4
tutorial_kind: conceptual-and-intended-sampling
tutorial_source: recorded-signal-and-intended-command
tutorial_expectation: bounded-histogram
tutorial_evidence: exact-record-and-intended-seeded-sample
---

# Long Count

Twelve hours beyond the Archive, traffic disappeared. *Vela* entered the cold between inhabited orbits. Rescue was counted in
weeks there. A ship's discarded heat became the brightest object nearby.

The crew changed to passage time. Mara slept in short intervals. Osei listened to pumps over meals. Sana opened the day's mission
book each morning, though the universe had neglected to provide any new event overnight.

Privacy became a time slot, not a place. Tala learned the panel that creaked outside Sana's bunk. She learned when Mara's silence
meant peace and when it meant trouble. Osei, missing work he could not reach, took harmless machines apart. Asking whether he meant
to rebuild them only delayed the rebuilding.

They ate from magnetic trays around the chart table. The galley offered enough seats or enough working displays, never both. Mara
called this design. Osei called it scheduling. Sana was still investigating the fourth chair.

The field manual traveled with the watch.

Catenary turned close to the giant world, deep inside its restless magnetic field. Sable wandered a wide, irregular orbit near the
sunward boundary, where the star's charged wind first pressed against that field. In this season the moon crossed the weather
before Catenary did. Its clocks kept an independent rhythm. Its instruments felt the charged front while the inner habitats still
had time to prepare.

The far instrument circled Sable, a moon so dark early surveyors had mistaken its shadow for missing data. Its first greeting
contained thirty-two binary observations. Nothing else.

```text
0 1 1 0 0 1 0 0
1 0 1 1 0 0 1 0
0 0 1 0 1 1 0 1
1 0 0 1 0 1 0 0
```

Mara put the sequence on the navigation display, where it resembled a route chosen by a nervous machine. Pilots had once crossed
the reach by reading pulsar fixes through charged dust. A few still kept old binary ephemerides above their bunks, and Mara's first
instinct was to see direction in any ordered lights. She traced the first eight digits with one finger before stopping herself.

Osei searched for a header. Sana traced the transmission and found that each digit came from a fresh preparation at the same remote
source. No route lay hidden in the sequence. This was the instrument's greeting, a small test of what the receiving crew would
invent before the real data arrived.

The difference was the experiment. Thirty-two readings from one changing object would tell a history. Thirty-two fresh
preparations made thirty-two trials.

Tala named the pieces. A **trial** began with a preparation, performed the chosen procedure, and ended in one observed **outcome**.
Here that outcome was `0` or `1`, never a fraction, never both.

Mara selected the first `0`. "What does this tell us about the source?"

"That one trial ended in zero," Tala said.

"And the next one?"

"Ended in one."

"I had hoped distance would improve your conversation."

Tala had hoped the same. Unfortunately Sana looked pleased, which meant the answer had probably been responsible.

On Catenary, context arrived from a thousand nearby systems. Out here, an invented story could cross the reach long before its
correction.

The answers sounded unhelpful because the questions demanded a pattern from single events. Sana preserved the sequence and named
the collection a **sample**.

Only then did Tala count.

```text
outcome 0: 18
outcome 1: 14
total:     32
```

The count altered no digit. It reduced the sequence to totals and threw away order. Sana kept the original beside it, an Archive
habit: never let a summary hide what it consumed.

Above the console, Mara's ceramic bird found the deck under thrust and drifted sideways when the engines slept.

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

A **probability model** assigned long-run weight before this sample existed. It promised no perfect split in any particular block.
The frequencies might wander from `0.5` without refuting the model, or land on `0.5` without proving it.

Mara enlarged the two bars. The first calibration deadline was approaching, and a number of trials sounded like the kind of answer
that could be put on a schedule. "How many settle it?"

Sana looked at the source claim attached to the model. "Settle what?"

The question closed over the conversation like a hand over an unsafe control.

More trials could steady an estimate (if the preparations were what they claimed, the trials were independent, the model applied).
More trials could not repair assumptions nobody had made.

Osei requested another thirty-two preparations from the simulator. Before execution he fixed the target, shot count, and seed. The
request entered the mission book before anyone knew whether the bars would look persuasive.

```bash
wheeler run manual/BinaryTrials.wbc \
  --target ideal \
  --shots 32 \
  --seed 104729
```

The second sample produced a different sequence and exactly the same histogram as the transmitted record.

```text
0 | ################## 18
1 | ##############     14
```

Mara frowned at it. "It copied the answer."

Sana put both sequences side by side. "It copied the counts."

The digits differed. The bars did not. A histogram was blind to order by design.

Because the seed belonged to the run, the same command reproduced the same simulator sample. Change the seed and a different
repeatable sample appeared. Neither result foretold the next act of unseeded hardware.

The instrument would not reserve their approach until Mara acknowledged the greeting. Another transmitted sample would cost six
hours and still could not supply missing assumptions. Refusal had a price. So did pretending.

"What can I sign?" she asked.

Tala read the record again. "That these thirty-two instrument trials produced these counts. That the attached model assigns equal
probability. Not that one proves the other."

"That is a very long way to say yes."

"It is the yes these data can carry."

Mara entered the claims separately, accepted the approach, and kept enough contingency fuel to answer any later contradiction.
Uncertainty had narrowed the decision. It had not made action impossible.

Tala set outcome, sample, and model beside one another.

| Object | Statement it supports |
| --- | --- |
| One outcome | One trial ended in `0` or `1` |
| One sample | These trials produced these counts and frequencies |
| Probability model | The stated preparation and procedure assign these outcome probabilities |

The names kept the objects apart. An outcome was not a distribution. Bars were not the model that might have produced them.
Probability made no promise about the next light to appear.

Outside, the reach was empty enough for the far instrument's carrier tone to feel like company. New packets crossed the hours from
Sable. No binary outcomes this time: two routes to one detector, and signed quantities that ordinary probability could not hold.

Mara watched one pair add and another disappear. "Counts do not cancel."

The cabin lights entered artificial evening. Nobody moved to end the watch.

Tala turned the page: [Contributions That Cancel](05-contributions-that-cancel.md).
