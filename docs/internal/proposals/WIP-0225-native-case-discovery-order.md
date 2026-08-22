# WIP-0225: Native case discovery order

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, case discovery, canonical order |
| Depends on | WIP-0018, WIP-0195, WIP-0224 |
| Supersedes | Unordered native descriptor inputs |
| Superseded by | WIP-0226 native root lock provenance |

## Summary

Validate complete discovered case names and their canonical order before native execution.

`wheeler.runtime.testing.runners.test_descriptors` admits bounded package-scoped case names and compares them by unsigned UTF-8 bytes. `TestRunner.w` requires a strictly increasing descriptor sequence during the complete preflight pass.

## Names

Case names contain 1 to 255 ASCII bytes drawn from letters, digits, dot, hyphen, underscore, colon, and square brackets. They cannot begin or end with a colon.

The accepted set covers target-qualified declaration names and indexed scalar rows such as:

```text
test::addition
test::signedIdentity[0]
```

Source discovery remains responsible for constructing these names from declarations and parameter rows. The runtime validates the package transport and does not invent display names.

## Canonical order

Descriptors sort by complete unsigned name bytes. Each name must compare strictly less than its successor. Equal names and descending names reject before any case identity, shard assignment, artifact verification, or execution.

The profile-2 report reducer still sorts selected rows by case identity. Discovery order and report order are distinct canonical relations. Requiring both prevents host filesystem or reflection order from becoming scheduling input while preserving the report identity contract.

## Implementation

The preflight pass retains only the previous name range. Validation is allocation-free and bounded by 64 descriptors and 255 bytes per comparison.

The execution pass copies one active name into owned storage. That same name enters the WIP-0195 transcript and complete report row.

## Evidence

`NativeCoverageRunExampleTest` supplies `test::fail`, `test::pass`, and `test::runtime` in canonical discovery order. Independent case-identity sorting still yields the accepted profile-2 report.

The test submits duplicate `test::same` descriptors and a descending `test::pass`, `test::fail` sequence. Both transports reject before output publication.

The runtime archive contains 202,062 bytes with SHA-256 `2ed941b94d630fe73c3d5f18cd44211f2f4d42be6a2fb7d331244625c3d6414c` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Native code validates the complete case-name alphabet and length.
- [x] Descriptor names are strictly increasing and unique.
- [x] Validation completes before identity derivation or execution.
- [x] One owned case name feeds identity and report composition.
- [x] Duplicate and descending fixtures publish no output.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Sort descriptors inside the runtime

Rejected. Discovery must supply canonical order. Repair would hide a nondeterministic or malicious package producer.

### Rely on report-identity sorting

Rejected. Report order cannot prove that discovery and scheduling received a canonical descriptor set.

### Accept arbitrary UTF-8 display names

Rejected. The accepted stage-0 declaration and scalar-row grammar has a smaller portable name alphabet.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0195](WIP-0195-native-test-case-identity.md)
- [WIP-0224](WIP-0224-native-target-source-utf8.md)
- [WIP-0226](WIP-0226-native-root-lock-provenance.md)
