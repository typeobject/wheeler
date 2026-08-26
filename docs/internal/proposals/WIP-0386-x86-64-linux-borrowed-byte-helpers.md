# WIP-0386: x86-64 Linux borrowed byte helpers

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and native runtime maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, AOT lowering, byte borrows, helper calls |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0379, WIP-0385 |
| Supersedes | Entry-only native byte access |
| Superseded by | WIP-0387 for whole-execution bounds, WIP-0395 for argument width |

## Summary

Scalar AOT helper calls may carry borrowed input and output buffers. Source lowering retains canonical `BUFFER_BORROW` instructions, call argument types, borrow windows, and affine call consumption. Machine lowering carries native buffer handles through the same six-register helper ABI as scalar arguments.

Helpers may inspect input length, read input bytes, and write output bytes. Canonical WBC keeps `OUTPUT_LENGTH` in the entry. The entry commits output length before a helper consumes its reborrowed output handle.

## Handle representation

A dynamic input handle points at the retained input-length cell. A dynamic output handle points at the committed output-length cell. Data begins at a fixed checked displacement from each cell. The handle therefore gives one authority for both active bounds and bytes without embedding an absolute image or stack address in runtime text.

The entry constructs both handles after complete input admission and output zeroing. `BUFFER_BORROW` copies a handle into a fresh local. Calls transfer up to six exact signed, Boolean, `byteview`, or mutable `bytes` values in the existing register order. A helper stores those values in its own frame before executing. Nested prior-helper calls may pass another canonical reborrow. WIP-0387 bounds the complete selected call tree to 65,536 instructions. WIP-0389 extends this handle ABI to immutable UTF-8 reborrows.

The machine never converts a handle to an application scalar. Borrowed values cannot be returned, stored in status, or escape the bounded prior-call graph. The complete WBC verifier remains authoritative for local assignment, borrow windows, call consumption, and exact argument types.

Constant-output AOT uses the same source form. Its independent evaluator carries the canonical output token through `BUFFER_BORROW` and helper calls while retaining bytes. Generated machine code receives a deterministic token, but byte writes remain absent because the enclosing shim publishes the already verified constant output.

## Admitted helper operations

A helper in a dynamic-I/O program may execute:

- `BUFFER_BORROW` for an input view or mutable output borrow.
- `BUFFER_LENGTH` over its input view.
- `BYTES_GET` over its input view with the retained runtime bound.
- `BYTES_SET` over its output borrow with the 4,096-byte and byte-value bounds.
- Existing scalar operations, assertions, bounded loops, and prior helper calls.

`OUTPUT_LENGTH` remains an entry operation. This is not an arbitrary pointer ABI, owned allocation, slice construction, UTF-8 decoding, or host-memory import.

A representative source boundary is:

```wheeler
module example.echo;

classical class Echo {
  state long status = 0;

  void writeFirst(
    borrow byteview input,
    borrow mut bytes output
  ) {
    assert(bufferLength(input) == 1);
    setByte(output, 0, input[0]);
  }

  entry void main(
    borrow byteview input,
    borrow mut bytes output
  ) {
    setOutputLength(output, 1);
    writeFirst(input, output);
    status = 81;
  }
}
```

## Native lowering

Input loads fetch the active length through the passed handle, reject a negative or terminal index, and address the retained input arena through the fixed data displacement. Output stores reject a negative index, index 4,096, negative byte, and byte 256 before addressing the output arena.

Native helper calls use caller-saved registers only. A helper trap returns a separate trap flag to its caller. The caller reaches process status 126 before entry output publication. Successful helper writes remain private until final status validation and the entry's one complete standard-output write.

## Failure boundary

Reject a helper byte operation without an input or output entry profile, a mismatched handle argument, a handle in a scalar result, a call to a non-prior helper, more than six arguments, a stale reborrow, an overlapping borrow window, an uncommitted output length, an out-of-range input or output access, and every prior scalar-profile failure.

Do not infer authority from a 64-bit local. Only verifier-admitted `byteview` and mutable `bytes` locals reach handle lowering.

## Evidence

`LinuxX8664ScalarAotCompilerTest` builds a two-function canonical WBC artifact. A signed-result helper accepts input and output borrows, reads and writes byte zero, and returns the byte as process status. Complete ELF verification precedes native-host launch evidence.

`ImageCommandTest` compiles source containing a borrowed `writeFirst` helper. The physical dynamic program also executes status state, signed and void helpers, assertions, a bounded loop, seven output writes, and one entry-owned output-length commitment before complete capsule construction and ELF verification. A second source program proves constant output through one borrowed helper and exact retained output.

An independent Alpine 3.22 x86-64 guest launched the physical source artifact with input `Q`. It produced exact `Q` and status 81. The 5,728-byte ELF identities are:

| Product | Identity |
| --- | --- |
| WBC | `c6cbade4dfbaf4c76ccb6752593817948cac90f47b77f9d1d3a6f8d32a338c8d` |
| runtime | `5d6996406e66fd847a4ad2137acf78052768dd52f2462713b5f7718933cf1079` |
| capsule | `fe813be654414ab5525070eb4895b2cff3138af85adbfb359c0ae04b6afd2b85` |
| native plan | `80a886f12b44c37d4809df1ff1202378c65065c55d87ae10434451e7393bddc8` |
| unsigned PREV | `b45dd47c7a136f35832b93ef0a661bc43462e6b90a20265ff55caf79c52d15db` |

## Acceptance

- [x] Physical source lowering retains input and output reborrows.
- [x] Exact borrowed argument types pass through the native helper ABI.
- [x] Helpers read retained input and write retained output.
- [x] Constant-output evaluation carries borrowed helper authority.
- [x] Helper traps prevent output publication.
- [x] Independent Linux evidence observes source-derived output and status.
- [x] Handles cannot escape as scalar values or ambient pointers.

## Rejected alternatives

### Give every helper the entry frame implicitly

Rejected. Hidden frame authority would bypass call signatures and admit byte access without a borrow.

### Copy byte arenas for each helper call

Rejected. Copies break mutable output identity, obscure bounds, and make nested calls depend on host scratch allocation.

### Lower borrows as integer constants

Rejected. Dynamic helpers require retained byte identity. Constant tokens are valid only inside the independent constant-output evaluator.

### Let helpers commit process output length

Rejected for this profile. Canonical WBC assigns that host-effect boundary to the output entry.

WIP-0395 carries one seventh exact scalar or handle value in the aligned private stack slot.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0379](WIP-0379-x86-64-linux-scalar-helper-calls.md)
- [WIP-0385](WIP-0385-x86-64-linux-dynamic-byte-io.md)
- [WIP-0395](WIP-0395-x86-64-linux-seventh-scalar-argument.md)
- [WIP-0387](WIP-0387-x86-64-linux-scalar-execution-bound.md)
- [WIP-0389](WIP-0389-x86-64-linux-strict-utf8-input.md)
