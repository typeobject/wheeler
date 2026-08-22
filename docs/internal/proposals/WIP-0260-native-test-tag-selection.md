# WIP-0260: Native test tag selection

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, selection |
| Depends on | WIP-0258, WIP-0259 |
| Supersedes | Native rejection of canonical test tags |
| Superseded by | Native package test descriptor construction |

## Summary

Move test-tag parsing and selection into the native runner.

The descriptor transport now carries one bounded selected-tag frame after the complete source plan and before the case count:

```text
u8 selected_tag_count
repeat selected_tag_count {
  u8 tag_byte_length
  u8 tag_bytes[tag_byte_length]
}
u8 case_count
```

Selected tags are strict lexical ASCII identifiers with optional dotted segments. They are unique, byte-sorted, at most 128 bytes each, and at most 64 per run. Empty selection retains every otherwise valid source case.

Native source metadata accepts `tags(...)` before optional `limits(...)`. A declaration is selected only when it contains every requested tag. Unknown selected tags reject the complete run. Java may encode the transport for differential evidence, but it neither parses source tags nor decides native case membership.

## Source metadata

`TestSourceMetadata.w` owns declaration metadata. It validates:

- One through 64 source tags.
- Identifier or dotted-identifier syntax through canonical lexer tokens.
- No duplicate source tag values.
- No tag value longer than 128 encoded bytes.
- Tags before limits.
- Exact limits syntax and bounds.
- An immediate body opening brace after metadata.

Whitespace between source tokens does not enter tag values. Matching compares token bytes and inserted dots against the selected transport value. Raw source search cannot create a tag.

`TestSourceTests.w` continues to own declaration and row discovery. It requests metadata validation for every declaration, including declarations excluded by tags. Malformed unselected declarations therefore reject rather than hiding behind a filter.

## Selection

Selection is conjunction. A request for `fast` and `unit.core` admits only declarations carrying both values.

Discovery counts and descriptor matching cover selected declarations and rows only. Name uniqueness, parameter-row validity, metadata validity, and selected-tag existence cover the complete root source before sharding.

Every selected tag must occur on at least one valid declaration. An unknown tag fails even when the descriptor count is zero. A known combination matching no declaration produces a valid empty selected suite only when each requested tag exists independently in the package. This preserves conjunction without redefining known-tag validation.

Tag selection precedes case identity, shard assignment, source lowering, artifact copying, compilation, verification, execution, and publication. Filtered cases consume none of those attempts.

## Module boundaries

`TestTagSelection.w` validates transport framing and lexical order. `TestSourceMetadata.w` validates source metadata and computes declaration membership. `TestSourceTests.w` binds only selected declarations to canonical descriptors. `TestRunner.w` owns frame order and scheduling.

Metadata modules live under `runtime/testing/runners/metadata`. The runner directory remains below the repository's ten-file source-layout ceiling.

## Evidence

`selectsCanonicalNativeTestTags` supplies two tagged declarations and requests sorted `fast` plus dotted `unit.core`. Only `test::alpha` enters the descriptor frame. Native discovery selects, lowers, compiles, verifies, executes, and passes that case while `test::beta` receives no artifact.

The selected declaration also carries canonical limits after tags, proving the fixed metadata order and direct-entry stripping boundary.

`rejectsUnknownNativeTestTags` supplies no descriptors and requests `missing`. Discovery rejects with all 39 output bytes untouched. `rejectsNoncanonicalNativeTagSelection` supplies descending transport tags and rejects during frame validation before source discovery.

The unfiltered parameterless, parameter-row, limit, imported-source, transported-artifact, and zero-artifact profiles remain green under an explicit zero-tag frame.

The runtime archive contains 319,314 bytes with SHA-256 `9407a3ccd6120f714e6069d713d69e3cb68b147ba27103e5ab2497c6278b2f1a` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,221 bytes with SHA-256 `c8225a24f2dc0c2d9cffe708b25e1fa662ba6a771d1a85fbc63d188c0ffc7ea5` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] The transport carries an explicit bounded tag selection.
- [x] Selected transport tags are canonical, unique, and sorted.
- [x] Source tags use canonical lexer tokens rather than raw search.
- [x] Dotted source tags match exact transport values.
- [x] Duplicate and malformed source tags reject.
- [x] Tags precede optional limits and the body brace.
- [x] Selection requires every requested tag.
- [x] Unknown selected tags reject an otherwise empty run.
- [x] Unselected cases receive no identity, shard, compiler, verifier, or interpreter attempt.
- [x] Malformed unselected declarations still reject.
- [x] Empty selection retains the existing complete discovery profile.
- [x] Runtime and conformance archives and dependent locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Let Java select descriptor names

Rejected. Host-side source parsing would remain semantic authority.

### Accept unsorted selected tags and sort them natively

Rejected. Canonical transports are not repair requests.

### Skip validation for filtered declarations

Rejected. Filters cannot conceal malformed package source.

### Include source whitespace in tag identity

Rejected. Tags are token values, not source slices.

### Place metadata parsing back in discovery

Rejected. Declaration discovery, metadata grammar, and transport framing have separate failure boundaries.

## References

- [WIP-0258](WIP-0258-native-bare-test-metadata-profile.md)
- [WIP-0259](WIP-0259-native-test-step-limits.md)
- [WIP-0197](WIP-0197-runtime-test-selection-authority.md)
