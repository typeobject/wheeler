---
sidebar_position: 9
title: The Bridge
description: An exact classical permutation crosses into coherent execution and returns its temporary quantum workspace clean.
tutorial_id: CH08
tutorial_steps: T63,T64,T65,T66,T67,T68
tutorial_part: coherent-reuse
tutorial_order: 8
tutorial_kind: exact-coherent-sequence
tutorial_source: primary-fences
tutorial_expectation: coherent-permutation-and-cleanup
tutorial_evidence: exact-classical-and-ideal-quantum-execution
---

# The Bridge

At the Archive, the XOR flip had been a two-row classical permutation.

| Input | Output |
| ---: | ---: |
| `0` | `1` |
| `1` | `0` |

Its generated inverse required no execution log because each output identified one input. The same property made the mapping a
candidate for coherent use, although reversibility alone did not grant that use automatically.

The algorithm racks occupied a separate truss from the measurement lab. Iona took them there through a maintenance bridge with no
spin gravity and transparent inspection panels underfoot. Sable filled the view below, not round so much as accumulated: ridges,
impact shelves, and black hollows that had kept sunlight out for geological time. Cables ran beside the handrail in labeled bundles,
carrying ordinary power and classical control between systems whose quantum regions remained isolated at either end.

Halfway across, Osei stopped to watch a service cart traverse the outside rail. "One definition on both sides," he said. "That is
what I want."

"Then ask both sides to prove they can accept it," Sana said.

Wheeler required the stronger declaration `coherent rev`. The compiler then checked a closed finite operation for coherent
eligibility and produced both ordinary inverse-bearing code and its quantum lifting.

```java
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

During the classical calls, `bit` changed according to the original table. Inside `liftedFlip`, `q.apply(flip)` applied that same
finite permutation to quantum basis states.

```text
classical path: 0 -> 1 -> 0
quantum basis path: |0> -> |1>
```

No measurement selected a branch inside the lifted call. On a superposition, the operation moved every basis amplitude according
to the permutation.

```text
before:
|0>  amplitude a
|1>  amplitude b

after lifted flip:
|0>  amplitude b
|1>  amplitude a
```

With `a = b`, the state looked unchanged because swapping equal entries changed no table. With `a = 1/sqrt(2)` and
`b = -1/sqrt(2)`, the swap introduced a global minus sign. The operation remained the same in both cases. The amplitude context
determined what the permutation did to the complete state.

Mara called the software bridge economical. One definition served as a classical reference, acquired a generated inverse, and
supplied a coherent operation. Osei had spent most of his career watching equivalent rules diverge after being copied into separate
systems. The shared definition appealed to him enough that he began listing other candidates aloud.

Sana called it dangerous unless the eligibility boundary stayed visible. Reuse could remove one source of drift while magnifying
one mistaken assumption across every context.

On this point, the compiler agreed with Sana.

| Body operation | Coherent result |
| --- | --- |
| exact XOR permutation | accepted |
| overwrite two inputs with one value | rejected because the map is not one-to-one |
| measurement | rejected because it creates a classical observation |
| file or network output | rejected because it creates an external effect |
| allocation with unbounded identity | rejected because the closed operation is not finite |
| division that discards a remainder | rejected because distinct inputs may collide |

They submitted each altered body to the compiler. Rejection arrived before a target plan existed, which meant no physical device
had been asked to imitate an operation the source could not justify. Adding `coherent` could not convert information loss or an
external effect into a unitary transformation. The modifier requested a proof obligation. It did not excuse one.

By then the bridge had delivered them to the algorithm rack. Its cabinets bore decals from every repair expedition that had reached
Sable: concentric circles from an orbital union, a hand with six fingers from a printer calibration error, and the faded green
triangle of the team that had installed the first quantum target. The rack's current work order required more than a one-bit flip.
It computed a temporary value, used that value to mark a phase, and then had to remove the temporary state. Leaving the value
behind would entangle the answer with workspace that later interference expected to be clean.

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

Inside the compute block, a clean **ancilla** began as a temporary quantum resource with a known basis value and acquired data
through an exact coherent lookup. The use block consumed the computed value only as coherent control for the phase mark. Wheeler
then generated the inverse of the compute block, returning `value` to its declared clean zero before the scope ended.

Iona made Tala trace the temporary value in a separate column. At the end of `compute`, it mattered. During `use`, it controlled
what mattered. At scope exit, it had to stop mattering in exactly the promised way. The intended mark survived because it had been
placed elsewhere, not because the temporary record had been ignored.

```text
compute     |0> -> |value>
use         mark phase from |value>
uncompute   |value> -> |0>
```

On `marked`, the middle effect remained. The temporary record disappeared from the live state without measurement, reset, or a
history rewind. **Uncomputation** meant executing coherent inverse work so that workspace returned to a known clean state while the
intended result survived elsewhere.

A measured ancilla could not satisfy that contract. Measurement would create a classical observation and disturb the coherent
state needed by the generated inverse. Resetting the resource to zero would produce a clean-looking endpoint through a nonunitary
effect, not prove exact cleanup. Wheeler rejected both substitutions.

Osei examined the resource report. It listed every ancilla, its width, the operation that created it, the inverse that cleaned it,
and the point after which the compiler could reuse its physical allocation. He had spent the outward passage treating workspace
as a housekeeping concern. Here an uncleared temporary could change later interference while leaving every visible result field
plausible.

For the first time, the phrase *workspace restored* named a contract precise enough to check.

Iona transferred the cleaned oracle into the instrument's algorithm rack. The station scheduler reserved a calibration window and
began moving heat, personnel, and lower-priority work away from the target chamber. On Sable, computation had a weather forecast of
its own. The rack accepted no prose about what the function was
supposed to know. It accepted an operation with an exact input-output contract and a coherent implementation.

Behind the interface sat no face, voice, or judgment. The machine answered one kind of query and nothing else. Its front plate did
not glow with intelligence. A cooling status changed from amber to green.

The crew crossed the maintenance bridge again at station midnight. Far below, one of Sable's pale excavations rotated into view and
looked briefly like an open eye before the moon carried it back into darkness.

In the field manual, the rack became [The Contract Machine](09-the-contract-machine.md).
