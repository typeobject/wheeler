---
sidebar_position: 1
title: Return to which state?
description: The destination appears before the vocabulary needed to explain it.
tutorial_id: T00
tutorial_part: opening
tutorial_order: 0
tutorial_kind: conceptual
tutorial_source: display
tutorial_expectation: none
tutorial_evidence: exact-source-display
---

# Return to which state?

The *Vela* was eleven minutes from its braking burn when the flight computer refused to go home.

```text
RETURN CHECK FAILED
navigation       home
workspace        not restored
mission result   present
result lineage   incomplete
```

Mara read the first two lines and said that the report contradicted itself. She flew the ship. To her, *home* was a place with
coordinates, weather, and a docking controller that disliked surprises.

Osei read the middle lines and said that the ship could reach home without returning home. He maintained the systems that were
supposed to put every temporary register back as they found it.

Sana read the last line twice. She kept the mission records. A result without a lineage was a rumor wearing a number.

The apprentice at the fourth console had been aboard for thirty-seven days. That was long enough to know that three senior crew
members could disagree without any of them being foolish. It was not long enough to know which meaning of *return* the computer
wanted.

The ship's manual offered this:

```text
RETURN
To cause a system, operation, vessel, request, state, record, or person to return.
```

The manual had achieved the rare technical feat of using the mystery inside its own definition.

You are the apprentice.

## Question

What would you need to know before you could decide whether the *Vela* had returned?

Do not reach for a quantum explanation yet. The report has already given us a smaller problem. One ordinary word has hidden several
questions.

- Did the vessel reach its earlier location?
- Did the program recover an earlier value?
- Did it reconstruct an exact earlier state?
- Did it use saved records or execute an inverse operation?
- Did the mission repeat an experiment or reuse an old observation?
- Did the crew preserve the result while cleaning temporary work?

The word *return* answers none of them by itself.

## The sealed program

The failed report names one mission program. It is valid Wheeler source from much later in this series.

```java
quantum class Bell {
  state long measured = 0;
  qreg q = new qreg(2);

  unitary void prepareBell() {
    H(q[0]);
    CNOT(q[0], q[1]);
  }

  entry void main() {
    prepare(q, 0);
    prepareBell();
    measured = measure(q);
  }
}
```

One local ideal-simulator run ended with this report:

```text
Bell (quantum) halted after 4 steps
measured = 3
measurements = [3]
```

You are not expected to understand the source. The words `quantum`, `qreg`, `unitary`, `H`, `CNOT`, `prepare`, and `measure` have
not earned explanations yet. The number `3` will later connect to a two-bit reading. For now, it is one recorded observation from
one run.

## What can you say?

You can say that the displayed run halted and recorded `3`.

You cannot yet say that every run records `3`. You cannot infer a distribution from one observation. You cannot infer entanglement
from the number alone. You cannot say that the program returned its quantum state, because this version measures the register and
does not apply an adjoint.

This is the first habit of the voyage: say the strongest thing the evidence supports, then stop.

Sana entered that sentence into the mission record. The return warning remained.

## Predict

Suppose the crew runs the program again. Which prediction can you defend now?

1. It must record `3`.
2. It must record `0`.
3. It will record either `0` or `3` equally often.
4. The displayed evidence does not yet justify any of those claims.

The fourth answer is the careful one. Later experiments will give you the preparation, state model, simulator contract, seed, and
shot count needed to make a stronger prediction.

## The book opens

A panel slid from the ship's manual. It contained a second book, although no one remembered installing one.

Its first page held a single line.

```text
Before you can return a computation, you must make one go somewhere.
```

Then the page supplied a filename.

```text
Wake.w
```

No definition of *computation* followed. The book preferred demonstrations to declarations and had enough confidence to be
annoying about it.

Continue with [Write the first instruction](01-write-the-first-instruction.md).

## Language ledger

**Words earned:** none. You have observed a problem before naming its machinery.

**Words sharpened:** return. It now requires an object, an earlier condition, and a mechanism.

**Phrases retired:** "the quantum program worked." The current evidence supports a recorded output, not that broad claim.

**Evidence label:** exact current source display and one local ideal-simulator observation. The observation is an opening artifact,
not a distribution or proof.
