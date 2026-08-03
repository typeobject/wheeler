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

Mara called the bridge economical. One definition served as a classical reference, acquired a generated inverse, and supplied a
coherent operation. Sana called it dangerous unless the eligibility boundary stayed visible.

On this point, the compiler agreed with Sana.

| Body operation | Coherent result |
| --- | --- |
| exact XOR permutation | accepted |
| overwrite two inputs with one value | rejected because the map is not one-to-one |
| measurement | rejected because it creates a classical observation |
| file or network output | rejected because it creates an external effect |
| allocation with unbounded identity | rejected because the closed operation is not finite |
| division that discards a remainder | rejected because distinct inputs may collide |

Adding `coherent` could not convert information loss or an external effect into a unitary transformation. The modifier requested a
proof obligation. It did not excuse one.

For its calibration oracle, the far instrument needed more than a one-bit flip. It computed a temporary value, used that value to
mark a phase, and then had to remove the temporary state. Leaving the value behind would entangle the answer with workspace that later
interference expected to be clean.

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
through an exact coherent lookup. The use block consumed the computed value only as coherent control for the phase mark. Wheeler then generated the
inverse of the compute block, returning `value` to its declared clean zero before the scope ended.

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
and the point after which the compiler could reuse its physical allocation. For the first time since the homeward warning, the
phrase *workspace restored* named a contract precise enough to check.

Iona transferred the cleaned oracle into the instrument's algorithm rack. The rack accepted no prose about what the function was
supposed to know. It accepted an operation with an exact input-output contract and a coherent implementation.

Behind the interface sat no face, voice, or judgment. The machine answered one kind of query and nothing else.

In the field manual it became [The Contract Machine](09-the-contract-machine.md).
