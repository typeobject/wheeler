# WIP-0261: Native test descriptor construction

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, descriptor authority |
| Depends on | WIP-0248, WIP-0249, WIP-0260 |
| Supersedes | Caller-supplied descriptor names for native source mode |
| Superseded by | WIP-0262 package gate and WIP-0263 package case names |

## Summary

Construct selected zero-artifact test descriptors from validated source inside the native runner.

The case-count byte now reserves `255` for native descriptor construction. In this mode no descriptor rows follow the byte. The runtime discovers selected declarations and parameter rows, constructs qualified case names, sorts them canonically, carries case kind, scalar value, and step limit through the same permutation, then enters the existing shard, compilation, execution, report, and summary path.

Java supplies no case names and no artifacts in construction mode.

## Transport

The runner places one byte after the selected-tag frame from WIP-0260:

```text
u8 case_count_or_mode
```

Values zero through 64 retain explicit descriptor mode. Value 255 requests native construction. Values 65 through 254 reject.

Construction mode requires the transport to end after the mode byte. The complete preflight therefore rejects trailing names, artifact lengths, or artifact bytes before source discovery.

The mode is distinct from an explicit zero-case frame. An explicit zero still means that the caller selected no descriptors. Construction asks native discovery to derive the complete tag-selected set.

## Name construction

`TestDiscoveredDescriptors.w` writes each selected name into fixed 255-byte storage:

- parameterless: `<target>::<declaration>`
- scalar row: `<target>::<declaration>[<ordinal>]`

The declaration token comes from the canonical lexer. Row ordinals come from validated canonical `cases(...)` parsing. Target bytes come from the manifest-authorized transport field.

At most 64 names occupy 16,320 bytes. A name longer than 255 bytes rejects. No truncation or repaired spelling is possible.

## Canonical order

Discovery order is not descriptor order. The runtime sorts names by unsigned byte order. Every swap moves:

- All 255 fixed name bytes.
- Exact name length.
- Case kind.
- Scalar case value.
- Effective step limit.

A final strict-order pass rejects duplicates. Declaration order and tag filtering therefore cannot detach executable metadata from a case name.

The bounded sort uses at most 64 passes over 64 items. Capacity bytes never enter case identity or report framing.

## Scheduling

Construction and sorting occur after complete manifest, lock, source-plan, module-graph, declaration, row, tag, and limit validation. Case identity then uses the same manifest identity, source identity, and constructed name as explicit descriptor mode.

Shard assignment still precedes source lowering, compiler dispatch, verifier work, metadata projection, interpretation, and report publication. A filtered or unassigned constructed descriptor receives none of those attempts.

All constructed artifacts have zero transport length. Each assigned case receives one fresh native compiler product and one verifier and interpreter attempt.

## Evidence

`selectsCanonicalNativeTestTags` compares explicit `test::alpha` transport against mode 255 with no descriptor rows. The source declares `alpha` before `beta`, carries dotted tags and limits, and selects one conjunction. Both paths publish byte-identical report identity and summary bytes.

`constructsCanonicalNativeParameterRowDescriptors` compares five explicit zero-artifact rows against mode 255. Source order declares `longs` before `flags`. Canonical descriptor order places both `flags` rows first. Native construction preserves each Boolean or signed value through sorting, compiles all five cases, and publishes byte-identical output.

Existing explicit transported-artifact tests remain unchanged apart from the new framing byte. Construction cannot be used to smuggle a transported artifact.

The runtime archive contains 327,027 bytes with SHA-256 `871ba740ba48d829966d40ce02b28a69df77e9846d16b06923c15197eea6fc46` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,221 bytes with SHA-256 `c8225a24f2dc0c2d9cffe708b25e1fa662ba6a771d1a85fbc63d188c0ffc7ea5` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Mode 255 requests native descriptor construction without descriptor rows.
- [x] Explicit zero through 64 descriptor frames retain their semantics.
- [x] Values 65 through 254 reject.
- [x] Parameterless names derive from exact target and declaration tokens.
- [x] Parameter-row names derive exact canonical ordinals.
- [x] Names, kinds, values, and limits sort as one product.
- [x] Strict duplicate and 255-byte bounds reject closed.
- [x] Tag selection precedes constructed descriptor publication.
- [x] Shard selection precedes each constructed compiler attempt.
- [x] Constructed parameterless and five-row outputs match explicit mode byte for byte.
- [x] Construction transports no Java case name or artifact.
- [x] Runtime and conformance archives and dependent locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Treat explicit zero as a construction request

Rejected. Empty selected suites and source-derived suites are different commands.

### Retain declaration order

Rejected. Source order cannot become report-order authority.

### Sort names without metadata

Rejected. A detached row value would execute the wrong case under a valid name.

### Ask Java to send zero-length rows after discovery

Rejected. Their names would still be host-side semantic input.

### Construct only assigned shard names

Rejected. Complete discovery and canonical case identity precede scheduling.

## References

- [WIP-0248](WIP-0248-native-counted-test-discovery.md)
- [WIP-0249](WIP-0249-native-parameter-row-discovery.md)
- [WIP-0260](WIP-0260-native-test-tag-selection.md)
- [WIP-0262](WIP-0262-native-one-source-package-test-gate.md)
- [WIP-0263](WIP-0263-native-package-case-names.md)
