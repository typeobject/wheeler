---
sidebar_position: 5
title: Long Count
description: Sable greets Vela with thirty-two outcomes and waits to see which story distance will tempt the crew to invent.
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

Tala woke because the ship had become too quiet. The drive was idle, and the
traffic receiver had stopped murmuring through the bulkhead beside her berth. She
pulled herself along the ceiling rail to the galley, where Sana had strapped the
gray book to the chart table.

The last traffic return had vanished during her sleep, twelve hours after the
Archive fell behind them. *Vela* crossed a region where aid required weeks and the
ship's waste heat outshone every neighboring object.

Passage watches replaced station time. Mara divided sleep into short pieces. Osei listened through meals for changes in pump tone.
Every morning Sana opened a new account page, even when vacuum had supplied nothing to enter.

On a small ship, privacy belonged to the watch schedule. Tala learned the creak outside Sana's berth and the difference between
Mara's contented silence and her dangerous one. Osei disassembled healthy devices whenever Sable's distant repairs occupied him.
Questions about reassembly only extended the process.

Tala kept Venn's folded reference inside her private locker and read it when the
ship was quiet. The page warned that she would halt apparently healthy machinery when its model
omitted something physical. Some nights that sounded like judgment. Some nights
it sounded like a machine fault wearing her name. She had joined *Vela* without
learning which version was true.

Meals attached themselves magnetically to the chart table. The galley could provide chairs for the crew or screens for the watch.
Mara defended the arrangement as design, Osei as scheduling. Sana had opened an inquiry into the missing chair.

The gray book traveled with the watch.

Tala opened the route map above the table. The Giant occupied its center as a
striped disk. Catenary's wheels clustered deep inside the magnetic field to the
right of *Vela*'s track. Sable moved far to sunward on an irregular captured
orbit, close to the boundary where stellar wind first pressed against the
Giant's field.

She advanced the weather layer. The charged front crossed Sable's path first.
Only later did the model carry it inward to Catenary. Sable's independent clocks
and instruments therefore felt a change while the traffic lanes still had time
to act.

The Second Navigation had grown around that geometry. Catenary supplied the
traffic network and an optical reference. Sable supplied a comparison made on the
weatherward side. No vote at either port could manufacture the other's
observation.

Early surveys had processed Sable's darkness as an absence in their data. The instrument orbiting that moon greeted *Vela* with
thirty-two binary observations and no explanation.

```text
0 1 1 0 0 1 0 0
1 0 1 1 0 0 1 0
0 0 1 0 1 1 0 1
1 0 0 1 0 1 0 0
```

Mara moved the digits onto her navigation pane. Old Reach pilots had pulled pulsar fixes through charged dust, and binary
ephemerides still hung above some Thorn bunks. Ordered lights invited her to find a road. She followed eight with one finger, then
withdrew her hand.

Osei searched for a header. Sana traced the transmission and found that each digit came from a fresh preparation at the same remote
source. The sequence carried no route. It was the instrument's greeting, a small test of
what the receiving crew would invent before the real data arrived. Sable's camps
had inherited too many charter reports whose confidence grew with transmission
distance; the cooperative now tested the interpreter as carefully as the link.

Experimental procedure decided what the sequence meant. Repeated readings of one evolving system would form a history. Here the
instrument made a fresh preparation for every reading, producing thirty-two trials.

Tala called each complete preparation and procedure a **trial**. Observation ended it with one **outcome**. This interface admitted
`0` or `1`; each trial supplied one of them.

Mara isolated the first `0`. "What have we learned about the source?"

"This preparation produced zero under this procedure."

Mara selected the following digit. "And this?"

"A separate trial produced one."

"The Reach has made you less informative."

Tala shared the disappointment. Sana's approval confirmed that responsibility had caused it.

Catenary surrounded every number with neighboring systems and people available to contradict it. Across the Reach, invention could
arrive hours ahead of correction.

A single outcome could answer only its own trial. Sana preserved all thirty-two in order and named the finite collection a
**sample**.

With the individual outcomes preserved, Tala counted.

```text
outcome 0: 18
outcome 1: 14
total:     32
```

Counting left the observations unchanged while discarding their order. Sana retained the sequence beside its totals, following the
Archive practice of displaying what a summary had consumed.

Mara's Archive bird stood upright during thrust and searched slowly for down whenever the drive slept.

The Common Book gave every counted trial one visible mark.

```text
0 | ################## 18
1 | ##############     14
```

Those bars formed a **histogram** of observed counts. They depicted neither amplitude nor confidence nor a wave in the chamber.
Any permutation of the sequence would preserve the histogram while changing the ordered sample.

Osei converted the counts by dividing each one by thirty-two.

| Outcome | Count | Frequency |
| --- | ---: | ---: |
| `0` | 18 | `18 / 32 = 0.5625` |
| `1` | 14 | `14 / 32 = 0.4375` |

Each resulting **frequency** described the finite sample. A later packet finally delivered the source specification and numbers of
another kind.

```text
model probability of 0: 0.5
model probability of 1: 0.5
```

The **probability model** assigned weights independently of this particular sample. Equal model probabilities did not require equal
counts in a finite block. Frequencies away from `0.5` could agree with the model, while a perfect split could occur without proving
it.

The first calibration deadline drew closer. Mara enlarged the bars, looking for a count she could place on a schedule. "How many
trials finish the question?"

Sana opened the model's stated scope. "Which question?"

Conversation stopped as quickly as a hand leaving an unsafe switch.

Additional independent trials could steady an estimate when the named preparation and model applied. Quantity could not supply an
unstated assumption.

Osei prepared a simulator request for thirty-two fresh trials. Target, shot count, and seed entered the mission account before the
sample existed, beyond the reach of later preference.

```bash
wheeler run manual/BinaryTrials.wbc \
  --target ideal \
  --shots 32 \
  --seed 104729
```

Its ordered outcomes differed from Sable's greeting. Their counts produced the same bars.

```text
0 | ################## 18
1 | ##############     14
```

Mara compared the displays. "The simulator repeated them."

Sana aligned the sequences. "It repeated the histogram."

Different observations occupied the two sequences. Identical totals occupied the histogram, whose construction had discarded
order.

The recorded seed made this simulator sample reproducible. Another seed would create another reproducible sample. Neither command
predicted a future physical preparation without that seeded numerical model.

Sable withheld the approach reservation until Mara acknowledged the greeting. A second physical sample required six hours and
would leave the same assumptions unstated. Refusal spent fuel; invention spent trust.

"Give me the sentence I can sign," Mara said.

Tala returned to the transmitted record. "These instrument trials produced the preserved sequence and counts. The attached model
assigns equal probability to both outcomes. The sample alone does not establish that model."

"Your yes requires unusual cargo space."

"It fits the evidence we possess."

Mara entered the statements separately and accepted Sable's approach. She preserved contingency fuel for contradiction. Limited
evidence still permitted a limited decision.

Tala arranged the three names in the gray book.

| Object | Statement it supports |
| --- | --- |
| One outcome | One trial ended in `0` or `1` |
| One sample | These trials produced these counts and frequencies |
| Probability model | The stated preparation and procedure assign these outcome probabilities |

An outcome belonged to one trial. A histogram summarized a sample. The model assigned probabilities under assumptions and promised
no particular next digit.

Sable's carrier tone became the only nearby voice. The next packets described two modeled routes meeting at a detector, each
bearing a signed quantity that ordinary probability could not represent.

One pair reinforced while another vanished. Mara shook her head. "Observed counts cannot do that."

Artificial evening dimmed the cabin. The watch continued around the new arithmetic.

The packet and the gray book met under one heading: [Contributions That Cancel](05-contributions-that-cancel.md).
