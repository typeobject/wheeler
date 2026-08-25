# WIP-0389: x86-64 Linux strict UTF-8 input

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and native runtime maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, AOT lowering, UTF-8, application input |
| Depends on | WIP-0007, WIP-0008, WIP-0026, WIP-0386, WIP-0387, WIP-0388 |
| Supersedes | Raw-byte-only scalar AOT input inspection |
| Superseded by | None |

## Summary

Scalar AOT accepts an exact `borrow utf8 input, borrow mut bytes output` entry and lowers strict RFC 3629 analysis to x86-64. `UTF8_VALID`, `UTF8_COUNT`, `UTF8_SCALAR`, and `UTF8_WIDTH` operate over retained application input. Canonical `UTF8_BORROW` values pass the same input authority through bounded prior helper calls.

This is byte-preserving strict decoding. It does not normalize text, consult locale, replace malformed sequences, admit CESU-8, or convert source to host strings.

## Entry and borrow profile

The first dynamic entry parameter may be a raw `byteview` or an immutable UTF-8 borrow. Both point at the retained input-length cell and share the 4,096-byte transport boundary. Their WBC types remain distinct. Raw `BYTES_GET` requires `byteview`. UTF-8 operations require `UTF8_BORROW`.

`UTF8_BORROW` copies the checked native handle into a fresh local. It follows the existing borrow-window and call-consumption rules. A UTF-8 handle cannot return as a scalar, enter status state, become output, or escape the acyclic eight-function graph.

## Decoder contract

The native decoder implements these RFC 3629 forms:

- ASCII bytes `00` through `7f` with width one.
- Leading bytes `c2` through `df` with one continuation byte.
- Leading bytes `e0` through `ef` with two continuation bytes, excluding overlong forms and UTF-16 surrogates.
- Leading bytes `f0` through `f4` with three continuation bytes, excluding overlong forms and values above `U+10FFFF`.

Continuation bytes must be `80` through `bf`. A scalar access index is a byte offset and must identify the first byte of a complete scalar.

`UTF8_VALID` scans the complete retained input and returns Boolean false for malformed bytes. `UTF8_COUNT` scans the complete input, returns the scalar count for valid input, and traps malformed input. `UTF8_SCALAR` returns the decoded scalar value at one byte offset. `UTF8_WIDTH` returns its width from one through four. Indexed operations trap a negative offset, terminal offset, continuation-byte offset, truncated scalar, or malformed scalar.

The decoder is emitted once in runtime text and called by each selected UTF-8 opcode. Its internal byte scan does not mint WBC instructions. One selected UTF-8 opcode consumes one WIP-0387 fuel unit and at most the independently bounded 4,096-byte transport work.

## Machine state

Decoder calls receive the immutable input handle in `r10` and a byte index in `r8`. They return scalar value in `rax`, width in `rcx`, and validity in `rdx`. Whole-input scans retain byte offset in `r8` and scalar count in `r12`. All addresses use the checked input length and fixed frame-relative data displacement.

The decoder has no imports, tables, heap allocation, mutable global state, host callbacks, locale, or replacement policy. It does not read beyond the retained length for a truncated two-, three-, or four-byte sequence.

Malformed count or indexed access reaches execution status 126. An application assertion over false `UTF8_VALID` reaches the same trap path. Final status validation precedes output, so malformed evidence publishes no application bytes.

## Source boundary

Physical source may retain UTF-8 analysis across helpers:

```wheeler
long emojiWidth(borrow utf8 input) {
  assert(utf8Valid(input));
  assert(utf8Count(input) == 4);
  assert(utf8Scalar(input, 6) == 0x1f642);
  return utf8Width(input, 6);
}
```

The source compiler emits exact UTF-8 reborrows and typed opcodes. A host-side string conversion is neither required nor admitted.

## Failure boundary

Reject UTF-8 opcodes in a raw-byte profile, raw byte loads from a UTF-8 borrow, mismatched helper parameters, stale reborrows, unsupported mutable UTF-8 ownership, and every prior AOT profile failure.

Return false from `UTF8_VALID` for isolated continuation bytes, `c0` or `c1` overlong leaders, truncated sequences, surrogate encodings, leaders above `f4`, and scalar values above `U+10FFFF`. Trap those forms when count, scalar, width, or an application assertion requires validity.

## Evidence

`LinuxX8664ScalarAotCompilerTest.decodesStrictUtf8ApplicationInput` builds and verifies a complete UTF-8 capsule ELF. Valid input `A🙂` proves whole validity, scalar count two, byte-offset scalar `U+1F642`, width four, process status four, and exact computed output. Overlong input traps with empty output.

`ImageCommandTest.lowersStrictUtf8ThroughBorrowedHelpers` compiles physical source with one validation helper and separate one-, two-, three-, and four-byte scalar helpers. The entry proves width sum ten, publishes width four, and reports input-dependent native I/O.

An independent Alpine 3.22 x86-64 guest launched the 12,024-byte physical image. Valid input `A¢€🙂` exercised all four decoder widths, returned status four, and emitted one byte with value four. Overlong `c0 80`, surrogate `ed a0 80`, above-range `f4 90 80 80`, and truncated `f0 9f` inputs each returned status 126 with zero output bytes.

| Product | Identity |
| --- | --- |
| WBC | `ebcf0dadaddb1fa4799a519fbb5da6440d367cc80d2962ff5d47e71fb73b9638` |
| runtime | `bfe446cb9e07d8d5f490341f5d18e75d7845f595258b26dc8aad3a4eed51416f` |
| capsule | `336e9f0ed4c7c375a0f3f59ace009ceb01b5076b9978c352b34834977d5a5011` |
| native plan | `79a08d70e962dd74cc5be389703ce27a7b1b8f3c16d962af7d55a3e9a20ff327` |
| unsigned PREV | `92405c90867160cce81f6d225a34cb2e8bcc407108f9248d2fe2868f4aa18de4` |

## Acceptance

- [x] UTF-8 entry and helper borrows retain exact WBC types.
- [x] Native decoding covers widths one through four.
- [x] Whole validity and scalar count inspect the complete retained input.
- [x] Scalar and width use checked byte offsets.
- [x] Overlong, surrogate, above-range, and truncated forms reject.
- [x] Malformed input publishes no application output.
- [x] Physical source and independent Linux evidence agree.

## Rejected alternatives

### Validate UTF-8 while reading stdin

Rejected. Raw-byte entries must retain arbitrary bytes, and validation belongs to selected typed WBC operations.

### Use a libc multibyte decoder

Rejected. Locale, replacement policy, dynamic linkage, and process-global state would enter semantics.

### Replace malformed sequences with `U+FFFD`

Rejected. Wheeler's strict UTF-8 operations reject malformed evidence rather than repair it.

### Count Unicode code units

Rejected. Wheeler counts Unicode scalar values and indexes UTF-8 operations by retained byte offset.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0386](WIP-0386-x86-64-linux-borrowed-byte-helpers.md)
- [WIP-0387](WIP-0387-x86-64-linux-scalar-execution-bound.md)
- [WIP-0388](WIP-0388-x86-64-linux-4096-iteration-byte-loops.md)
