---
sidebar_position: 9
title: Crossing
description: A reversible classical rule crosses into quantum work and learns to clean up after itself.
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

At the Archive, the XOR flip had been a two-row classical permutation.

| Input | Output |
| ---: | ---: |
| `0` | `1` |
| `1` | `0` |

Its inverse needed no execution log. Each output pointed to one input. That made the mapping a candidate for coherent use, but only
a candidate.

The algorithm racks occupied another truss. To reach them, Iona led the crew across a maintenance bridge beyond the station's spin.
Through clear panels underfoot, Sable filled the dark, not round so much as accumulated: ridge on impact shelf on black hollows that
had kept sunlight out for geological time.

Cables followed the rail. Ordinary power. Classical control. At either end, the quantum regions remained apart.

At the midpoint, Iona tested a rail weld bearing Osei's old mark. His last shift at Sable.

The weld still held. Neither mistook that for an argument about the life around it.

Halfway across, Osei stopped to watch a service cart traverse the outside rail. "One definition on both sides," he said. "That is
what I want."

"Then ask both sides to prove they can accept it," Sana said.

"I asked for fewer implementations."

"Shared definitions include shared mistakes."

Wheeler demanded a stronger promise: `coherent rev`. For a closed finite operation, the compiler checked whether that promise could
hold. If so, it produced ordinary reversible code and a quantum lifting.

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

A `hybrid` class held ordinary state beside a quantum register. Neither became the other. The program merely coordinated them, and
had to keep the border visible.

During the classical calls, `bit` changed according to the original table. Inside `liftedFlip`, `q.apply(flip)` applied that same
finite permutation to quantum basis states.

```text
classical path: 0 -> 1 -> 0
quantum basis path: |0> -> |1>
```

No measurement chose a branch inside the lifted call. On a superposition, the permutation moved every amplitude.

```text
before:
|0>  amplitude a
|1>  amplitude b

after lifted flip:
|0>  amplitude b
|1>  amplitude a
```

If `a = b`, exchanging them left the table unchanged. If `a = 1/sqrt(2)` and `b = -1/sqrt(2)`, the exchange introduced a global
minus. Same permutation. Different amplitudes around it.

Mara called the bridge economical. One definition served ordinary execution, generated an inverse, and crossed into coherent work.
Osei had spent his career watching copied rules drift apart. He began naming other functions they could share.

Sana let the list gather momentum, then stopped him. Reuse could remove one source of disagreement while spreading one bad
assumption everywhere.

"You could have interrupted sooner," he said.

"I wanted to know how fast the fever rose."

On this point, the compiler agreed with Sana.

| Body operation | Coherent result |
| --- | --- |
| exact XOR permutation | accepted |
| overwrite two inputs with one value | rejected because the map is not one-to-one |
| measurement | rejected because it creates a classical observation |
| file or network output | rejected because it creates an external effect |
| allocation with unbounded identity | rejected because the closed operation is not finite |
| division that discards a remainder | rejected because distinct inputs may collide |

They altered the body and submitted it. Again. Again. The diagnostic panel found a rhythm.

```text
overwrite       rejected
measurement     rejected
network output  rejected
unbounded state rejected
```

Every refusal arrived before target planning. No chamber time was spent asking physics to imitate an operation the source could not
justify.

`coherent` could not bless information loss, measurement, or an external side effect into unitarity. It was a promise the body had
to keep, not a favor requested from the compiler.

The bridge delivered them to cabinets layered with old repair decals: an orbital union's circles. A six-fingered hand born from a
printer fault. The faded green triangle of the first quantum-target crew.

The current work order needed more than a flip. It would compute a temporary value, use it to mark phase, then remove it. Leave the
temporary behind and later interference would remain tangled with the workspace.

Iona showed the pattern in Wheeler's paired compute and use form.

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

Inside `compute`, a clean **ancilla** began as temporary quantum space in a known basis state. The lookup wrote a value into it
without measurement. Inside `use`, that value controlled the phase mark. Then Wheeler ran the compute work backward, returning the
ancilla to zero before its scope closed.

Iona made Tala give the temporary value its own column. After `compute`, it mattered. During `use`, it controlled what mattered.
At the end, it had to be gone.

The mark survived elsewhere. The temporary had not been ignored. It had been unmade.

```text
compute     |0> -> |value>
use         mark phase from |value>
uncompute   |value> -> |0>
```

The phase on `marked` remained. The temporary vanished from the live state without measurement, reset, or stored history.
**Uncomputation** was this deliberate inverse work: clean the workspace. Preserve the effect placed elsewhere.

Measurement would not do. It created a classical observation and broke the coherence the inverse needed. Reset would make the
endpoint look clean by a different, nonunitary route. Wheeler rejected both.

Osei examined the resource report. Each ancilla had a width, an origin, a cleanup operation, and a point after which its allocation
could be used again.

"Finally," he said, "a system that tells me who left the workspace dirty."

Iona looked through the glass at his open tool case. "Quantum workspace. The classical report is still pending."

Until then, *workspace* had sounded like housekeeping. Here a dirty temporary could alter later interference while every visible
result continued to look plausible.

At Sable, the report became a work order. Width consumed hardware. Depth consumed the cooling window. A reusable allocation did
not refund time or energy already spent. Uncomputation cleaned state, not history and not the power account.

For the first time, the phrase *workspace restored* named a contract precise enough to check.

Iona transferred the cleaned operation to the rack. The scheduler began clearing a path around the chamber. The machine shop gave
up a coolant loop. Mushroom lamps dimmed. Personal transmissions slipped to the next watch.

On Sable, computation had weather. It had neighbors.

The rack accepted no prose about what the function was supposed to know. It accepted a mapping and a coherent way to perform it.

No face waited behind the interface. No judgment. The machine answered one kind of question.

Amber became green.

The crew crossed the maintenance bridge again at station midnight. Far below, one of Sable's pale excavations rotated into view and
looked briefly like an open eye before the moon carried it back into darkness.

On the other side waited [Contract Machine](09-contract-machine.md).
