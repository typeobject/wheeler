# WIP-0314: Native 255-transition coverage

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, compiler, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Runtime, semantic coverage, native testing |
| Depends on | WIP-0288 |
| Supersedes | WIP-0283 128-transition bound |
| Superseded by | None |
| Follow-up | Complete bounded semantic coverage |

## Summary

Raise the canonical native transition-coverage boundary from 128 to 255 rows.

The source execution contract already permits up to 512 interpreter steps. Coverage remained limited to 128 rows, so a passing artifact could execute within its declared step limit and then trap while constructing its report. Coverage is not an optional epilogue. An admitted passing execution must be reportable.

The profile uses one byte for the transition count. Its exact terminal value is therefore 255. A 256th row has no canonical framing and remains rejected.

## Runtime boundary

`BootstrapCoverageFragments.w` accepts one through 255 complete transition tuples. It measures the exact fragment prefix before publication and writes the count without truncation.

`CoverageReducer.w` accepts the same 255-row prefix. Its seven 255-word metadata columns use a 16,384-byte private arena. Keys, prefixes, suffixes, counts, sort order, duplicate reduction, and canonical report bytes are unchanged.

`TestArtifactReport.w` gives both the fragment stream and reduced report 65,536-byte buffers. Passing-report staging grows to 132,256 bytes. No case-result field, package-report row, source plan, manifest, lock, test count, or execution-step limit changes.

## Evidence

`NativeCoverageReducerExampleTest` sends 255 equal rows through the Wheeler reducer. The canonical report contains one point with count 255 and matches the stage-0 report byte for byte. Host framing rejects a 256th row rather than wrapping the count to zero.

The WIP-0313 physical void-call operand case executes 221 transitions. Its native report now completes through fragment construction, canonical reduction, coverage hashing, case publication, and package reduction.

Existing short traces retain byte-identical coverage reports and identities. The wider bound changes capacity, not ordering or identity semantics.

## Acceptance

- [x] Fragment measurement and emission share a 255-transition bound.
- [x] Canonical reduction accepts 255 complete rows.
- [x] The 255-row repeated point publishes count 255 byte for byte.
- [x] Host framing rejects row 256.
- [x] A 221-transition native package artifact publishes a passing coverage identity.
- [x] Existing coverage identities remain stable for unchanged traces.
- [x] Runtime, conformance, package, workspace, documentation, and file policy gates pass.

The runtime archive contains 435,970 bytes with SHA-256 `233ae7a0035f84955b904a615005cbeedd8282c3e2df08d2cb876127713dc260`. Its root manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Truncate coverage after 128 transitions

Rejected. The resulting identity would describe a prefix while the execution identity describes the complete run.

### Raise the count to 256

Rejected. The profile carries one unsigned count byte. Silent wrap is not a larger bound.

### Lower every test step limit to 128

Rejected. Execution bounds and evidence framing are separate contracts. The compiler package already has useful bounded paths above 128 transitions.

### Allocate for 512 rows

Rejected. The current canonical frame cannot represent that count. A wider frame belongs to a new profile.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0205](WIP-0205-native-test-coverage-identity.md)
- [WIP-0283](WIP-0283-bounded-native-bitwise-coverage.md)
- [WIP-0288](WIP-0288-native-inverse-coverage.md)
- [WIP-0313](WIP-0313-native-compiler-void-call-operand-suite.md)
