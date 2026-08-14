---
sidebar_position: 11
title: Search
description: Four old camp names become a search space where one changed sign can gather an entire answer.
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

Four calibration channels ran to timing cavities along the outer truss. Their names came from Sable's vanished equatorial camps:
Dawn, Cross, Evening, Deep. Dawn followed the sunward edge. Evening chased it. Cross held the surface road between. Deep stopped
moving when its crews found shelter in a lava tube.

The camps were gone. Their names remained in maintenance speech, beside a collapsed antenna field and debts the cooperative still
honored. Nobody saying *Deep has drifted* needed to remember the people who once carried clocks there. The name remembered for
them.

Exactly one channel in the training record had been marked as faulty, and its identity was available only through a phase oracle.

Mara offered to inspect the channels directly. Osei was already reaching for a probe. Either method, Iona agreed, would beat the
quantum training circuit by half an hour.

That was why the training case had only four channels: not to save time, but to make every amplitude visible.

Two qubits supplied the four basis states. Hadamard prepared them with equal amplitudes.

| Measurement integer | Basis | Initial amplitude |
| ---: | --- | ---: |
| `0` | ket zero zero | `1/2` |
| `1` | ket zero one | `1/2` |
| `2` | ket one zero | `1/2` |
| `3` | ket one one | `1/2` |

With four squared magnitudes of `1/2` summing to one, the preparation was normalized.

```text
4 * (1/2)^2 = 1
```

The oracle marked state `3` by changing only its phase. Iona chose it before the run. Sana sealed the choice. No one could move the
answer afterward to flatter the circuit.

Tala wrote `3` before seeing the trace. It felt less like confidence than closing one door against her future memory.

| State | Before oracle | After oracle |
| ---: | ---: | ---: |
| `0` | `+1/2` | `+1/2` |
| `1` | `+1/2` | `+1/2` |
| `2` | `+1/2` | `+1/2` |
| `3` | `+1/2` | `-1/2` |

Measured now, every state would still have probability `1/4`. The mark needed another operation, something that could force the odd
sign to meet the others.

They worked on the back of an obsolete maintenance card. Tala summed the signed entries. Osei checked the arithmetic, rotated the
card, checked it again.

For these four amplitudes, the average after marking was `1/4`.

```text
(1/2 + 1/2 + 1/2 - 1/2) / 4 = 1/4
```

The **diffusion operation** reflected every amplitude around that average. For an amplitude `a`, the new value was
`2 * average - a`.

```text
unmarked: 2*(1/4) - 1/2  = 0
marked:   2*(1/4) - (-1/2) = 1
```

The unmarked amplitudes fell to zero. The marked one rose to unity.

Phase had crossed into probability.

For the first time since the algorithm racks opened, Mara looked pleased. The marked answer had not been read secretly and copied
into an output field. Its sign had changed how all four alternatives combined.

"One iteration?" she asked.

"For four states," Iona said.

"And then it tells us three?"

"Under the oracle's promise."

Mara pointed at Sana. "That qualification was implied."

"Not while I am on duty," Sana said.

Tala assembled the known gates.

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

The scheduler granted one ideal run before chamber cooling began. On the front plate the channels remained identical. Inside the
simulator, the state vector moved exactly as their maintenance-card arithmetic had predicted.

```text
after preparation  [+0.5, +0.5, +0.5, +0.5]
after mark         [+0.5, +0.5, +0.5, -0.5]
after diffusion    [ 0.0,  0.0,  0.0, -1.0]
measurement        3
```

A global minus separated the gate sequence from their hand calculation. Measurement could not see it.

Tala uncovered her `3`. The answer matched. The old ink mattered more.

Then Mara took Osei's probe and inspected the actual channels. All were healthy. State `3` had been marked in the training oracle.
no fault had been discovered in the timing cavity. *Faulty* belonged to the problem, not the hardware.

The lesson cost them thirty-three minutes more than direct inspection. Mara entered the difference in the maintenance account.

This was one complete Grover iteration in a four-state model, not a practical speedup. The search space was tiny. The oracle was
known. Chamber overhead dwarfed the work. A probe could find a real failed channel without quantum assistance.

"So the machine has successfully demonstrated that a larger machine might someday save the time this machine just spent," Mara
said.

Iona took back the probe. "Now you understand research scheduling."

A claim of advantage would have to survive larger search spaces, honest oracle costs, repeated iterations, state preparation, error
correction. This two-qubit run carried none of that weight.

Sable had little patience for demonstrations promoted into industries. The abandoned camps contained machines sold on promises
extrapolated from cleaner rooms. Their pressure shells failed slowly. Their financing failed at once.

Sana kept the smaller truth: one oracle call marked a state in the ideal model. Diffusion turned the mark into a certain outcome.
Source, trace, assertion, agreement, no grandeur.

Beyond the search module, the main array waited for a transform over phase patterns. Its smallest form was Hadamard. The next needed
controlled phase. A three-qubit version already waited in the ship's source catalog.

Small enough to inspect. Large enough to be wrong.

Beyond the rack-room glass, shutters covered the outer truss. Dawn vanished. Cross. Evening. Deep.

Only the central array remained open to Sable's sky. The station was preparing for the work that had cost its people years of
distance.

Iona opened [Far Instrument](11-far-instrument.md).
