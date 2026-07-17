# Executable language profile

Wheeler's executable profile grows only when a construct has parser, verifier, runtime, negative, and end-to-end tests. The current profile is classical and implements the first WIP-0001 slice.

## File structure

A source file contains:

```text
wheeler 1
program <Identifier>
kind classical
state <Identifier> = <i64>
...
<function declarations>
entry { ... }
```

Comments begin with `//`. Statements may end in a semicolon. Integers are signed 64-bit decimal, hexadecimal (`0x`), or binary (`0b`) values and may contain underscores.

## Functions

```text
fn helper {
  ...
}

rev update {
  ...
}

rev coherent permutation {
  ...
}
```

A normal `fn` has only a forward body. A `rev` function receives a compiler-generated inverse body. A `rev coherent` declaration additionally requires the current coherent subset; WIP-0002 will lower eligible functions to unitary quantum operations.

Non-entry functions return automatically. The single `entry` block must halt explicitly.

## Operations

| Source | Meaning |
| --- | --- |
| `add state value` | Checked signed addition; inverse is subtraction. |
| `sub state value` | Checked signed subtraction; inverse is addition. |
| `xor state value` | Bitwise XOR; self-inverse. |
| `swap left right` | Swap two state locations; self-inverse. |
| `set state value` | Logged overwrite; valid in non-reversible functions. |
| `call function` | Invoke a forward body. |
| `uncall function` | Invoke a verified inverse body. |
| `expect state value` | Trap without data mutation when unequal. |
| `checkpoint` | Add a reversible checkpoint marker. |
| `commit` | Advance the rewind horizon and clear prior step records. |
| `nop` | No operation. |
| `halt` | Halt the entry function. |

Generated inverse bodies reverse statement order and pair each operation with its declared inverse. Logged overwrite, commit, halt, and other operations without generated inverses are rejected in `rev` functions.

## Three meanings that must stay separate

- `uncall f` is new execution of `f`'s inverse body.
- VM rewind consumes existing step records.
- A future quantum adjoint reverses a live unitary region.

External observations and measurement require replay, compensation, or retry rather than pretending they can always be undone.
