---
sidebar_position: 11
title: Search
description: Dawn, Cross, Evening, and Deep become four amplitudes under a chamber window Sable cannot replace.
tutorial_id: CH10
tutorial_steps: T75,T76,T77,T78
tutorial_part: quantum-search
tutorial_order: 10
tutorial_kind: intended-quantum-algorithm
tutorial_source: intended-primary-fence
tutorial_expectation: marked-state-three
tutorial_evidence: intended-ideal-execution
---

# Search

Four outer-truss channels inherited the names of Sable's lost equatorial camps. Dawn had traveled the sunward rim, and Evening kept
the opposing side. Cross maintained the surface road. Deep ended its migration in lava-tube shelter.

The camps were gone. Their names remained in maintenance speech, beside a
collapsed antenna field and debts the cooperative still honored. Charter
companies had abandoned both during the Withdrawal; Sable accepted the debts it
could trace to real labor and rejected the ownership notices that arrived without
maintenance. Nobody saying *Deep has drifted* needed to remember the people who
once carried clocks there. The name remembered for them.

The training oracle phase-marked exactly one channel as faulty without exposing its identity directly.

Mara proposed opening the channel account. Osei reached for a physical probe. Iona agreed that either ordinary method would finish
thirty minutes earlier.

The training case used four channels so every amplitude would remain visible.

A two-qubit register supplied four basis states, and Hadamards assigned them equal initial amplitude.

| Measurement integer | Basis | Initial amplitude |
| ---: | --- | ---: |
| `0` | ket zero zero | `1/2` |
| `1` | ket zero one | `1/2` |
| `2` | ket one zero | `1/2` |
| `3` | ket one one | `1/2` |

Each of four amplitude magnitudes was `1/2`. Their squared magnitudes summed to one, establishing normalization.

```text
4 * (1/2)^2 = 1
```

Iona selected state `3`, and the oracle negated only that state's phase. Sana sealed the selection before execution, preventing any
later relocation of the answer.

Tala committed `3` to old paper before viewing the trace, denying her future memory room to improve the prediction.

| State | Before oracle | After oracle |
| ---: | ---: | ---: |
| `0` | `+1/2` | `+1/2` |
| `1` | `+1/2` | `+1/2` |
| `2` | `+1/2` | `+1/2` |
| `3` | `+1/2` | `-1/2` |

Immediate measurement would still assign probability `1/4` to each outcome because phase negation preserved magnitude. Another
operation had to bring the exceptional sign into interference.

They used the blank side of an obsolete maintenance card. Tala summed the amplitudes. Osei verified the arithmetic, rotated the
card, and verified it from the opposite side.

After the phase mark, the mean of the four amplitudes was `1/4`.

```text
(1/2 + 1/2 + 1/2 - 1/2) / 4 = 1/4
```

The **diffusion operation** reflected each amplitude across the mean, mapping amplitude `a` to `2 * average - a`.

```text
unmarked: 2*(1/4) - 1/2  = 0
marked:   2*(1/4) - (-1/2) = 1
```

Reflection sent all three unmarked amplitudes to zero and the marked amplitude to one.

Interference had converted the phase mark into outcome certainty.

Mara finally approved of an algorithm rack. The answer had never been extracted and inserted into output. Its phase had altered how
every alternative combined.

"That requires one iteration?"

"For this four-state space," Iona said.

"Measurement returns three with certainty?"

"Inside the stated oracle promise."

Mara indicated Sana. "I could hear that qualification approaching."

"Implication has no authority on my watch," Sana said.

Tala translated the arithmetic into gates.

```wheeler
quantum class GroverFour {
  state long measured = 0;
  qreg q = new qreg(2);

  unitary void markThree() {
    CZ(q[0], q[1]);
  }

  unitary void diffuse() {
    H(q[0]);
    H(q[1]);
    X(q[0]);
    X(q[1]);
    CZ(q[0], q[1]);
    X(q[0]);
    X(q[1]);
    H(q[0]);
    H(q[1]);
  }

  entry void main() {
    prepare(q, 0);
    H(q[0]);
    H(q[1]);
    markThree();
    diffuse();
    measured = measure(q);
    assert(measured == 3);
  }
}
```

The schedule permitted one ideal execution before cooling. The rack's four channel lamps remained alike while the simulator state
followed the maintenance-card calculation.

```text
after preparation  [+0.5, +0.5, +0.5, +0.5]
after mark         [+0.5, +0.5, +0.5, -0.5]
after diffusion    [ 0.0,  0.0,  0.0, -1.0]
measurement        3
```

The gate sequence produced a global minus absent from their hand result. It left every measurement prediction unchanged.

Tala exposed the `3` written before execution. Its age mattered more than its correctness.

Then Mara took Osei's probe and inspected the actual channels. All were healthy. State `3` had been marked in the training oracle.
No fault had been discovered in the timing cavity. *Faulty* belonged to the problem, not the hardware.

Compared with direct inspection, the training execution spent thirty-three additional minutes. Mara charged every one to the
maintenance account.

A delayed traffic notice arrived while she was signing it.

```text
RETUNING RESERVE       one chamber window
NEXT CONTACT           full manifest or legacy profile
LEGACY CONSEQUENCE     widened approach intervals
```

Venn had signed before the training run began. She did not know which minutes
Sable would spend. She had made clear that Catenary would spend them too.

They had performed one complete Grover iteration over four states. It demonstrated no practical speedup: the search space and
oracle were tiny, chamber overhead dominated, and an ordinary probe could identify a physical channel fault.

"We spent half an hour proving that a future machine may avoid spending it," Mara said.

Iona reclaimed the probe. "You have understood the research calendar."

Any advantage claim would need larger spaces, accounted oracle construction, repeated iterations, state-preparation cost, and error
correction. The two-qubit execution established none of those conditions.

Sable distrusted demonstrations promoted into industries. Machines in the abandoned camps had been sold through extrapolations
from cleaner laboratories. Financing vanished long before their pressure shells finished failing.

Sana recorded the result at its demonstrated scale. In the ideal model, one oracle call phase-marked a state and diffusion made its
outcome certain. She attached source, trace, assertion, and agreement without an advantage claim.

The main array required a transform over structured phase patterns. Hadamard supplied its one-qubit form. Larger forms added
controlled phase, and *Vela* carried a three-qubit source ready for qualification.

Three qubits permitted complete inspection and sufficient room for a significant error.

Shutters crossed the outer truss beyond the rack-room glass, covering Dawn, then Cross, Evening, and Deep.

The central array alone remained open to the sky. Sable redirected years of maintained distance toward the coming comparison.

Iona bound the inherited source to the [Far Instrument](11-far-instrument.md).
