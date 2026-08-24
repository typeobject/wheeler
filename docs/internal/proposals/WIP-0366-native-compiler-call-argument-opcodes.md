# WIP-0366: Native compiler call-argument opcodes

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-24 |
| Updated | 2026-08-24 |
| Area | Self-hosting, compiler package tests, call ABI |
| Depends on | WIP-0310, WIP-0323, WIP-0365 |
| Supersedes | Product-only typed call-argument opcode evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Execute the physical call-argument opcode authority through every admitted argument ownership kind.

`CallArguments.w` owns two public functions. The native fixed compiler retains both, including the eight-parameter source-column selector. One package case calls `callArgumentOpcode` over UTF-8, map, region, words, bytes, byte-view, and scalar types. This covers all four emitted opcode identities without recompiling the same physical owner seven times.

## Graph

```text
NativeCompilerCallArgumentTests
  -> CallArguments
       -> Opcodes
       -> StorageOpcodes
       -> TypeCodes
```

All four production owners remain complete. The test root carries numeric type inputs and expected bytecode identities so it does not add redundant direct edges to constant owners.

The source-column function remains in the compiled owner with all eight signed parameters. It is not projected away merely because the root exercises the opcode query. `NativeCompilerSelfSourceExampleTest` compiles the complete four-module graph through the native module compiler and compares the complete artifact with stage 0 byte for byte.

## Mapping

The package case requires:

- UTF-8 borrow to `OPCODE_UTF8_BORROW`,
- long-map borrow to `OPCODE_MAP_BORROW`,
- mutable region borrow to `OPCODE_REGION_BORROW`,
- words borrow to `OPCODE_BUFFER_BORROW`,
- bytes borrow to `OPCODE_BUFFER_BORROW`,
- byte-view borrow to `OPCODE_BUFFER_BORROW`, and
- ordinary scalar input to `OPCODE_LOCAL_MOVE`.

One selected artifact executes the seven calls and seven assertions once with fresh storage. Splitting this table into seven artifacts would spend compilation work without adding another owner, query, or report boundary.

The complete compiler package publishes 223 selected, 223 passed, and zero failed cases across 70 native targets. The canonical workspace checks 176 targets. The full run completes in thirty-five minutes and fifty-nine seconds under a forty-one-minute guard.

The canonical compiler manifest contains 37,404 bytes with identity `2c863b3bef2e3ecef2a7c4f670e46a3818bcc817348f054ff8827e37e3bea3c8`. The compiler archive contains 3,126,842 bytes with SHA-256 `38eb7156f9e3e3e6db8c3341510e1f660aecc59487839e8e587946eb7d88ac53`.

## Acceptance

- [x] Every admitted argument ownership kind executes through the physical query.
- [x] UTF-8, map, region, buffer, and scalar opcode identities remain distinct.
- [x] The complete eight-parameter sibling function remains in the owner.
- [x] Native and stage-0 complete source artifacts are byte-identical.
- [x] One selected artifact executes once with fresh storage.
- [x] All report adapters consume the same 223 rows.
- [x] Compiler, package, workspace, documentation, archive, and file policy gates pass.

## Rejected alternatives

### Project only `callArgumentOpcode`

Rejected. The physical source owns both call-argument queries, including the terminal fixed-compiler parameter profile.

### Import type and opcode constants into the test root

Rejected. Complete production owners already establish those identities. Extra root edges would test graph redundancy instead of argument selection.

### Publish seven package rows

Rejected. All branches belong to one public query and one immutable owner. One attempt retains the complete mapping with less repeated compilation.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0124](WIP-0124-direct-call-argument-encoding-adoption.md)
- [WIP-0310](WIP-0310-native-multi-helper-entry-programs.md)
- [WIP-0323](WIP-0323-native-compiler-helper-signature-suite.md)
- [WIP-0365](WIP-0365-nested-helper-owner-graph-execution.md)
