# WIP-0403: Scalar global instruction AOT

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native backend maintainers |
| Created | 2026-08-26 |
| Updated | 2026-08-26 |
| Area | Native bootstrap, AOT lowering, scalar globals, checked updates |
| Depends on | WIP-0008, WIP-0026, WIP-0382, WIP-0390, WIP-0401 |
| Supersedes | Local-store-only scalar global mutation in AOT |
| Superseded by | WIP-0407 for status ownership |

## Summary

Lower canonical `ADD_CONST`, `SUB_CONST`, `XOR_CONST`, and `EXPECT_EQ` instructions over scalar globals. Checked updates trap on signed overflow. Equality expectations trap on mismatch. Exact immediate values remain signed 64-bit Wheeler operands.

This admits the direct global instruction forms used by stateful classical programs. It does not add inverse execution, rewind history, checkpoints, commits, logged replacement, or result slots.

## Validation

Each instruction carries one in-range global index and one signed immediate. All AOT globals already belong to the signed scalar profile.

Helpers may update and inspect any global. WIP-0407 removes the initial entry-only restriction on global zero. A writer must remain reachable from the entry.

`EXPECT_EQ` is read-only. It does not satisfy the entry's requirement to publish final process status.

## Evaluation

Independent static evaluation applies:

```text
ADD_CONST: addExact(global, immediate)
SUB_CONST: subtractExact(global, immediate)
XOR_CONST: global xor immediate
EXPECT_EQ: require global == immediate
```

Arithmetic overflow and expectation mismatch become build-time rejection for static-I/O programs. Dynamic-I/O programs retain the same generated trap paths.

The existing evaluation state remains shared across the entry and every helper call. Updates therefore preserve Wheeler global visibility and do not become frame-local substitutions.

## Machine lowering

Generated code loads the selected global through R14, loads the complete immediate into RCX, applies the matching 64-bit operation, and stores the result through R14. Addition and subtraction branch to status 126 on x86 overflow. XOR has no arithmetic trap.

`EXPECT_EQ` loads the global and immediate, compares all 64 bits, and branches to the current function's trap epilogue on inequality. Every instruction consumes the shared fuel cell before its check or mutation.

No immediate truncation, host relocation, source path, symbol lookup, or dynamic global table enters the runtime.

## Failure boundary

Reject an out-of-range global, malformed operands, signed overflow, expectation mismatch, fuel exhaustion, or any prior scalar-profile failure. Static failure returns no runtime text. Dynamic failure publishes no application output and exits with status 126.

This WIP executes only the forward instruction stream. Reversible inverse and rewind semantics remain outside scalar AOT.

## Evidence

`ScalarAotArtifacts.globalInstructionArtifact` starts global `value` at 40, adds four, checks 44, subtracts two, checks 42, XORs 99, checks 73, and publishes that global as process status. Separate maximum-add and minimum-subtract fixtures reject during independent evaluation.

`LinuxX8664ScalarAotCompilerTest.lowersScalarGlobalInstructions` binds the accepted WBC to a canonical capsule, native image plan, and ELF. On x86-64 Linux the image executes every update and expectation, exits with status 73, writes exact `Wheeler\n`, and writes no standard error.

| Product | Identity |
| --- | --- |
| WBC | `378b6b4441e29c95d7b32051d9b8820f59c7e68c9b230c5a6297649274ac6efb` |
| runtime | `229c253086efa6127072efaa32b203fdbbc27db11f5f29f6a6d695bb63cefafe` |
| capsule | `845dd69143793cba8301d6865688ace9b0ee60c7b8d241ace22643c7e1d0c112` |
| native plan | `839f02237e4890afdfcab9883d3deae78ccdbc08d57d201a3dc3f05fec334628` |
| unsigned PREV | `07c48c8eefa6ef31f243794aebb981cddf123a5d81a845d2c5774771f17797a6` |

## Acceptance

- [x] Checked global addition and subtraction retain signed overflow traps.
- [x] Global XOR retains exact 64-bit values.
- [x] Global equality expectation traps on mismatch.
- [x] Entry and helpers share global updates.
- [x] WIP-0407 admits reachable helper mutation of process status.
- [x] Every global instruction consumes shared fuel.
- [x] Overflow fixtures reject before publication.
- [x] WBC, runtime, capsule, plan, ELF, and PREV identities remain exact.
- [x] Native x86-64 Linux launch observes exact status and output.

## Rejected alternatives

### Rewrite global updates as local loads and stores

Rejected. Canonical WBC opcode identity is semantic input to AOT.

### Truncate immediates to x86 signed 32-bit fields

Rejected. Wheeler immediates are signed 64-bit values.

### Require an entry status copy

Rejected by WIP-0407. The checked entry epilogue already owns process exit.

### Claim rewind or inverse parity

Rejected. This leaf executes only the verified forward body.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0382](WIP-0382-x86-64-linux-scalar-state-checks.md)
- [WIP-0390](WIP-0390-x86-64-linux-shared-scalar-globals.md)
- [WIP-0401](WIP-0401-bounded-recursive-scalar-aot-calls.md)
- [WIP-0404](WIP-0404-scalar-global-replacement-aot.md)
- [WIP-0407](WIP-0407-helper-owned-process-status-aot.md)
