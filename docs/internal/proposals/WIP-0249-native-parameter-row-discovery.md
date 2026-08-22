# WIP-0249: Native parameter-row discovery

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, coverage, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, source discovery |
| Depends on | WIP-0205, WIP-0225, WIP-0248 |
| Supersedes | WIP-0248 parameterless declaration bound |
| Superseded by | Native test metadata discovery |

## Summary

Discover bounded `long` and `boolean` parameter rows from the validated root source.

The native lexer now accepts either of these test forms:

```wheeler
test void plain()
test void rows(long value) cases(-1, 0, 2)
test void flags(boolean value) cases(false, true)
```

One parameterized declaration contributes one discovered case per source row. Its canonical descriptor suffix is the zero-based row ordinal, not the row value:

```text
<target>::<declaration>[<row-ordinal>]
```

The complete discovered case count must equal the complete descriptor count. Declaration and row order do not replace the strict unsigned descriptor order established by WIP-0225.

## Row grammar

`TestSourceTests.w` accepts exactly one named `long` or `boolean` parameter, a closing parenthesis, the `cases` token, an opening parenthesis, one through 64 scalar rows, and a closing parenthesis.

Long rows use the compiler's canonical signed-number width, validation, and decoder. Boolean rows accept only exact `false` and `true` token hashes. The runtime rejects empty rows, trailing commas, unsupported parameter types, malformed values, duplicate values, and rows beyond the 64-case runner bound.

The scanner's token columns remain the syntax authority. Comments, strings, and raw source substrings cannot create rows.

## Name binding

The runtime compares each row against every completely framed descriptor. It requires exact target bytes, `::`, exact declaration bytes, `[`, one or two canonical decimal ordinal digits, and `]`.

The 64-case profile makes every ordinal one or two digits. Leading zeroes and value-derived suffixes fail the exact length and byte checks. Each discovered row must match exactly one descriptor.

Parameterless declarations retain the unsuffixed name from WIP-0248. Duplicate declaration names reject before row matching.

## Coverage closure

Stage 0 emits `LOCAL_MOVE` in the synthetic entry that installs one parameter value before `CALL_VOID`. `BootstrapCoverageFragments.w` now emits the canonical ten-byte `LOCAL_MOVE` opcode name. Existing coverage products remain byte-identical when their traces do not contain this opcode.

## Atomicity

Complete descriptor framing, source-plan validation, manifest and root selection, and lock-root validation precede row discovery. Discovery precedes source identity, case identity, shard assignment, artifact verification, execution, and publication.

A malformed, duplicate, missing, extra, or mismatched row traps with all 39 output bytes untouched.

## Evidence

`discoversCanonicalLongAndBooleanParameterRows` declares three long rows before two Boolean rows. Stage 0 independently compiles the five transported artifacts. The descriptors arrive in canonical name order, the native scanner binds all five row ordinals, each artifact executes once with fresh storage, and the runner publishes five selected and five passed cases.

`rejectsDuplicateNativeParameterRows` changes the source plan from `cases(false, true)` to `cases(false, false)` while retaining the otherwise valid five-artifact transport. Native row validation traps before publication and leaves the output zeroed.

The parameterless one-case, counted-case, and one-through-eight-source entry suites remain green.

The runtime archive contains 265,303 bytes with SHA-256 `c5f08d34b273ff096d409f626fe4025699ceea5156ca688dab1515bcfe69ee7a` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] One `long` or `boolean` parameter is discovered natively.
- [x] Signed long and exact Boolean row tokens are validated canonically.
- [x] One through 64 rows receive canonical ordinal suffixes.
- [x] Empty, malformed, duplicate, or excessive rows reject closed.
- [x] Every row matches exactly one complete descriptor.
- [x] Descriptor order remains independent of declaration order.
- [x] Discovery precedes identity, shard, verification, execution, and publication.
- [x] Native coverage names `LOCAL_MOVE` exactly.
- [x] Five mixed scalar rows execute once and publish one canonical summary.
- [x] Duplicate-row rejection leaves all output bytes untouched.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Put row values in descriptor names

Rejected. Stage 0 defines stable ordinal names, and values may be negative or Boolean.

### Trust transported artifact arguments

Rejected. The source plan, not Java argument construction, owns discovered row cardinality and identity.

### Deduplicate repeated rows

Rejected. Canonical source rejects duplicate parameter cases instead of changing their ordinals.

### Admit arbitrary scalar expressions

Rejected. The current language profile defines literal `long` and `boolean` rows only.

## References

- [WIP-0205](WIP-0205-native-test-coverage-identity.md)
- [WIP-0225](WIP-0225-native-case-discovery-order.md)
- [WIP-0248](WIP-0248-native-counted-test-discovery.md)
