# WIP-0288: Native inverse coverage

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, coverage, and reversible-semantics maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Semantic coverage, generated inverses, native execution |
| Depends on | WIP-0287 |
| Supersedes | Forward-only native coverage direction |
| Superseded by | None |
| Follow-up | Native rewind coverage |

## Summary

Carry canonical forward or inverse direction through native call frames and semantic coverage.

`CALL` enters a forward body. `UNCALL` enters its verified generated inverse. Result-slot inverse calls follow the same rule. Returns restore the caller's direction together with its function and instruction coordinate.

The interpreter packs direction and branch state into one bounded control octet per transition. Values 0 through 2 represent forward none, fallthrough, and taken. Values 4 through 6 represent the corresponding inverse states. The unused value 3 cannot enter reduction. This keeps the trace allocation fixed while preserving separate semantic dimensions.

## Coverage

`BootstrapCoverageFragments.w` writes `forward` or `inverse` from the traced control value. It sizes canonical keys and JSON suffixes from the selected spelling. Both names have seven bytes, but the encoder still validates the closed direction domain before publication.

The admitted runtime coverage profile now includes `ADD_CONST`, `SUB_CONST`, and `UNCALL`. Forward calls and their generated inverse bodies retain exact physical function and instruction coordinates from WIP-0287.

The raw opcode stream remains unchanged. Direction belongs to semantic event evidence, not the bytecode trace identity.

## Evidence

`nativeInverseDirectionMatchesStageZero` compiles a reversible increment, calls it forward, then invokes its generated inverse. Java stage-zero observation and Wheeler-native reduction publish byte-identical canonical coverage reports.

The report contains:

- a forward `CALL` in the entry function.
- a forward `ADD_CONST` and `RETURN` in the callee.
- a forward `UNCALL` in the entry function.
- an inverse `SUB_CONST` and `RETURN` in the callee.
- the terminal forward `HALT`.

The native compiler package remains seven selected and seven passed cases with report identity `bfa2de7a7819131f9a679d02bef8f83f0e44bde029878b02897c05ee0bb7cf2e` because all existing case transitions are forward.

## Acceptance

- [x] Native traces distinguish forward and inverse execution.
- [x] Calls select forward direction.
- [x] Uncalls select inverse direction.
- [x] Inverse result-slot calls select inverse direction.
- [x] Returns restore caller direction.
- [x] Direction composes with none, taken, and fallthrough branch states.
- [x] The reducer rejects values outside the closed direction and branch domains.
- [x] Generated-inverse coverage is byte-identical to stage zero.
- [x] Existing forward package report identities remain stable.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Focused inverse, VM, coverage, package, documentation, workspace, and file-length policy pass.

The runtime archive contains 389,416 bytes with SHA-256 `ed2893617ea87d8b6a7f90dc1aef84eeaef04f34de2b5d8504f4a213d7bae32c` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 134,876 bytes with SHA-256 `614ccf470315dc4fb6a06c616f97ad8a492441628799e95f0c209bd7ad223329` and root manifest identity `b9beb8697bb55c654a74476b69a5a21fbcded9791e04f771ab4b25186d2d1349`.

The compiler archive remains 3,024,011 bytes with SHA-256 `f368a20b722ed114247166df99f4a482fb099041d5ebfa4858a0c192429da70f` and root manifest identity `9b2cebe76654d6f2cb4d2ec3e3c2762bfc8e72009a796f7e28adf5903428bb99`.

## Rejected alternatives

### Infer inverse direction from opcode names

Rejected. Instructions inside inverse bodies use ordinary opcodes such as `SUB_CONST` and `RETURN`.

### Add a second direction buffer

Rejected. Direction and branch are closed small domains and fit one validated control octet.

### Rename inverse execution to backward

Rejected. `inverse` is the canonical runtime observation dimension and does not imply history rewind.

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0287](WIP-0287-native-call-branch-coverage.md)
