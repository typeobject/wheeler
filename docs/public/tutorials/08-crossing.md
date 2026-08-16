---
sidebar_position: 9
title: Crossing
description: Across Sable's maintenance bridge, one finite permutation earns coherent use and every temporary incurs a debt.
tutorial_id: CH08
tutorial_steps: T63,T64,T65,T66,T67,T68
tutorial_part: coherent-reuse
tutorial_order: 8
tutorial_kind: current-coherent-and-intended-cleanup
tutorial_source: current-and-intended-primary-fences
tutorial_expectation: coherent-permutation-and-cleanup
tutorial_evidence: current-execution-and-intended-uncomputation
---

# Crossing

After the Bell enclosure closed, Iona carried the accepted XOR source out of the
laboratory. Tala followed her along the frost-lined corridor, through a pressure
door, and onto the maintenance bridge where the station's shallow gravity fell
away.

At the Archive, XOR by one had been a complete two-row permutation.

| Input | Output |
| ---: | ---: |
| `0` | `1` |
| `1` | `0` |

Each output retained one identifiable input, so the inverse required no execution history. That property qualified the mapping for
further coherent checks rather than guaranteeing acceptance.

The algorithm racks stood on a neighboring truss across a maintenance bridge beyond station spin. Clear floor panels exposed
Sable below. The moon appeared assembled from ridges and impact shelves above hollows that had excluded sunlight for geological
time.

Power cables and classical control lines followed the handrail. Quantum regions remained physically separated at either end.

At midspan, Iona pressed a rail weld marked with Osei's stamp from his final Sable watch.

Six years had left the weld intact. Its survival offered no judgment on the departure that followed.

Osei watched a service cart cross the external rail. "I want one definition to serve both machines."

"Require each machine to justify accepting it," Sana said.

"My request concerned duplicated implementations."

"One implementation also distributes one mistake everywhere."

Wheeler expressed the stronger contract as `coherent rev`. For a closed finite operation, the compiler checked the body before
producing ordinary reversible execution and a coherent quantum lifting.

```wheeler
hybrid class CoherentBridge {
  state long bit = 0;
  state long measured = 0;
  qreg q = new qreg(1);

  coherent rev void flip() {
    bit ^= 1;
  }

  unitary void liftedFlip() {
    q.apply(flip);
  }

  entry void main() {
    flip();
    assert(bit == 1);
    reverse flip();
    assert(bit == 0);

    prepare(q, 0);
    liftedFlip();
    measured = measure(q);
    assert(measured == 1);
  }
}
```

The `hybrid` class placed classical state and a quantum register within one coordinating program. Their coexistence preserved the
border between them; neither kind of state transformed into the other.

Classical calls changed `bit` according to the verified mapping. Within `liftedFlip`, `q.apply(flip)` lifted that finite permutation
over the quantum basis.

```text
classical path: 0 -> 1 -> 0
quantum basis path: |0> -> |1>
```

The lifted call introduced no measurement or ordinary branch. On superposed input, it permuted the full amplitude table.

```text
before:
|0>  amplitude a
|1>  amplitude b

after lifted flip:
|0>  amplitude b
|1>  amplitude a
```

If `a = b`, exchanging them left the table unchanged. If `a = 1/sqrt(2)` and
`b = -1/sqrt(2)`, the exchange introduced a global minus. The permutation stayed
fixed while the amplitudes around it changed.

Mara approved of the economy: one definition supported classical execution, generated inverse work, and coherent lifting. Osei had
spent too many watches reconciling copied rules. He began listing other operations suitable for reuse.

Sana waited until the list reached ambition and interrupted. Shared source removed drift while increasing the reach of any false
assumption it contained.

"You allowed me to continue," Osei said.

"The rate of expansion was useful evidence."

Compiler diagnostics enforced the caution she had named.

| Body operation | Coherent result |
| --- | --- |
| exact XOR permutation | accepted |
| overwrite two inputs with one value | rejected because the map is not one-to-one |
| measurement | rejected because it creates a classical observation |
| file or network output | rejected because it creates an external effect |
| allocation with unbounded identity | rejected because the closed operation is not finite |
| division that discards a remainder | rejected because distinct inputs may collide |

Each prohibited operation entered the body and met a diagnostic. Repetition gave the refusals a work-song rhythm.

```text
overwrite       rejected
measurement     rejected
network output  rejected
unbounded state rejected
```

All refusals occurred before target planning, preserving chamber time for source whose coherent contract could be justified.

The `coherent` modifier declared an obligation rather than conferring one. Information loss, measurement, and external effects
violated that obligation and could not acquire unitarity through syntax.

The bridge delivered them to cabinets layered with old repair decals: an orbital
union's linked circles, a six-fingered hand born from a printer fault, the faded
green triangle of the first quantum-target crew. During the Withdrawal those
unions had converted abandoned work orders into claims of possession. Sable's
cooperative still treated a maker's mark as evidence that labor had joined the
machine's history.

The actual work order computed a temporary value, used it for a phase mark, and had to remove it afterward. A surviving temporary
would keep later interference entangled with workspace.

Iona opened Wheeler's paired `compute` and `use` pattern.

```wheeler
unitary void markMatchingRecord(
    borrow QIndex<8> index,
    borrow ClassicalTable<8> table,
    borrow QWord<8> target,
    borrow mut QBit marked
) {
    compute {
        ancilla qvalue<BitInt<8>> value = clean(0);
        lookup(index, table, borrow mut value);
    } use {
        xorIfEqual(
            value,
            target,
            borrow mut marked
        );
    }
}
```

Within `compute`, a clean **ancilla** supplied temporary quantum space in a known basis state. Coherent lookup wrote a value there
without measurement. The `use` block let that value control a phase mark, after which Wheeler inverted the compute work and returned
the ancilla to zero before scope exit.

Iona required a separate column for the temporary. It held meaningful state after `compute`, controlled the intended effect during
`use`, and owed the scope a clean zero at completion.

The phase mark remained on its destination after inverse work removed the temporary state.

```text
compute     |0> -> |value>
use         mark phase from |value>
uncompute   |value> -> |0>
```

Neither measurement nor reset nor retained execution history removed the temporary. Deliberate inverse work performed
**uncomputation**, restoring workspace while preserving the effect transferred to `marked`.

Measurement would create classical information and end the coherence needed by the inverse. Reset would reach an apparently clean
endpoint through nonunitary preparation. Wheeler prohibited both substitutions.

Osei inspected the resource account. Every ancilla listed width, allocation origin, cleanup work, and the point where its physical
allocation became reusable.

"At last, workspace dirt has an owner," he said.

Iona looked at his open tool case across the bridge. "The report covers quantum workspace. Your classical audit remains open."

The word *workspace* had previously suggested housekeeping to Tala. In this rack, an uncleared temporary could corrupt later
interference while visible outputs retained plausible shapes.

Sable converted the compiler report into physical scheduling. Width claimed hardware, and depth claimed cooling time. Reusing an
allocation refunded neither energy nor elapsed work. Uncomputation restored state without restoring the station's power account.

The phrase *workspace restored* finally referred to a state contract they could test.

Iona transferred the accepted operation. Scheduler changes crossed the habitat: the machine shop yielded a coolant loop, mushroom
lamps lost power, and personal transmissions moved into the following watch.

Every computation at Sable occupied a physical season shared with neighbors.

The rack ignored prose about intention. It required a finite mapping and a justified coherent implementation.

The interface concealed no face and exercised no judgment. Its contract admitted
one kind of question.

Its readiness lamp changed from amber to green.

At station midnight, the crew crossed back over Sable. A pale excavation rotated beneath the transparent floor, held the shape of
an open eye for several seconds, and passed into black terrain.

The accepted mapping opened the rack on the far side: [Contract Machine](09-contract-machine.md).
