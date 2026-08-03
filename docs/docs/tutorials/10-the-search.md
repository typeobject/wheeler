---
sidebar_position: 11
title: The Search
description: One marked phase and one diffusion step amplify a selected state in a four-item search space.
tutorial_id: CH10
tutorial_steps: T75,T76,T77,T78
tutorial_part: quantum-search
tutorial_order: 10
tutorial_kind: exact-quantum-algorithm
tutorial_source: primary-fence
tutorial_expectation: marked-state-three
tutorial_evidence: exact-ideal-execution
---

# The Search

Four calibration channels appeared in the module. Exactly one had been marked as faulty, and its identity was available only through
a phase oracle.

Mara read the number of channels and offered to inspect them directly. Iona agreed that this would be faster than constructing a
quantum circuit. The point of the module was not to improve four-item maintenance. It was to expose the mechanism while every
amplitude still fit in one table.

Two qubits supplied four basis states. Hadamard on both prepared equal amplitudes.

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

By changing only phase, the oracle marked state `3`.

| State | Before oracle | After oracle |
| ---: | ---: | ---: |
| `0` | `+1/2` | `+1/2` |
| `1` | `+1/2` | `+1/2` |
| `2` | `+1/2` | `+1/2` |
| `3` | `+1/2` | `-1/2` |

Immediate measurement would still assign probability `1/4` to every state. A phase mark became useful only when another operation
made the sign difference interfere.

For these four amplitudes, the average after marking was `1/4`.

```text
(1/2 + 1/2 + 1/2 - 1/2) / 4 = 1/4
```

Around that average, the **diffusion operation** reflected each amplitude. If an amplitude was `a`, its reflected value was
`2 * average - a`.

```text
unmarked: 2*(1/4) - 1/2  = 0
marked:   2*(1/4) - (-1/2) = 1
```

Three amplitudes fell to zero. The marked amplitude rose to one. Phase had become outcome probability through interference.

Tala assembled the known gates.

```java
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

The state-vector trace matched the hand table row for row.

```text
after preparation  [+0.5, +0.5, +0.5, +0.5]
after mark         [+0.5, +0.5, +0.5, -0.5]
after diffusion    [ 0.0,  0.0,  0.0, -1.0]
measurement        3
```

One global minus separated the gate sequence from the hand reflection, changing no measurement prediction. This
four-state run demonstrated one complete Grover iteration. It did not establish practical speedup. The fixture was small,
the oracle implementation was known, target overhead dominated, and a classical inspection could identify the marked channel
without difficulty.

Any scalable claim required a family of search spaces, an oracle cost model, a number of iterations proportional to the square
root of the space size, and evidence that state preparation and error correction did not erase the advantage. None of those claims
followed from a successful two-qubit run.

Sana preserved the narrower statement. One phase oracle call marked a state in a four-item ideal model. One diffusion step converted
that mark into a certain basis outcome. The source, state trace, and assertion agreed.

Beyond the search module, the instrument's main calibration array waited for a transform over phase patterns. Its smallest case was
Hadamard. Its next case needed controlled phase. Its operational case occupied three qubits and already existed in the ship's source
catalog.

Iona opened the final algorithm chapter: [The Far Instrument](11-the-far-instrument.md).
