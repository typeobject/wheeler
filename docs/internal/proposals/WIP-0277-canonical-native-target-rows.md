# WIP-0277: Canonical native target rows

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package testing, reports |
| Depends on | WIP-0276 |
| Supersedes | Descriptor-order native row publication |
| Superseded by | Native package-wide row reduction |

## Summary

Publish each native target's profile-2 rows in strict case-identity order.

WIP-0276 exposed native semantic rows, but the retained buffer followed descriptor execution order. Report identity already sorted by case identity. Publication now applies the same native ordering rule before the adapter sees a row.

The host rejects nonincreasing row identities. It does not sort a malformed target transport into shape.

## Runtime reduction

After execution and report-identity reduction, `TestRunner.w` reuses three completed descriptor metadata arrays as row starts, row lengths, and insertion-sort order. No second maximum-size row buffer is allocated.

The reducer parses each retained row boundary, locates its fourth framed field, requires a 64-byte case identity, and compares exact lowercase identity bytes. Duplicate identities already fail report reduction and also fail the publication-order assertion.

Compact output does not pay for row ordering. Extended output sorts only the selected rows it will publish.

## Host execution bound

The package adapter performs a metadata-only count pass before execution. It requests 43 bytes plus the maximum 5,345-byte row capacity for each selected declaration, rather than reserving the 64-case maximum for every target.

The adapter executes conformance programs through committed transitions without retaining host rewind history. Each invocation still creates a fresh VM and runtime-owned case storage. Retaining hundreds of kilobytes of identical host output in every outer rewind snapshot is not test semantics.

The count pass may overestimate a shard because sharding follows metadata discovery. It cannot underestimate the row capacity.

## Evidence

`publishesTargetRowsInCaseIdentityOrder` executes two declarations in one target. Their descriptor names arrive lexically, while publication is accepted only when their case identities increase strictly. The package report contains both passing rows.

The complete native package test suite checks ordering on every decoded target, including passing, failing, tagged, multi-target, local-import, and locked-dependency profiles.

The two-row fixture also proves bounded no-history host execution. The previous fixed maximum output reservation exhausted the test JVM before publication. Count-sized output and committed stepping complete the same native work.

## Acceptance

- [x] Native target rows publish in strict case-identity order.
- [x] Row boundaries are parsed before sorting.
- [x] Duplicate or noncanonical identity order rejects.
- [x] Sorting reuses completed descriptor arrays.
- [x] Compact output remains unchanged.
- [x] Metadata discovery determines bounded output capacity.
- [x] Capacity may overestimate but cannot underestimate selected rows.
- [x] Host execution retains no outer rewind history.
- [x] Every native invocation still receives a fresh VM.
- [x] A two-case extended target completes under the focused test heap.
- [x] Runtime and conformance locks are rebuilt exactly.
- [x] Focused runtime, examples, tools, documentation, package, workspace, and file-length policy pass.

The runtime archive contains 375,274 bytes with SHA-256 `1e2381f42a8761838bbc76c0faa26894616723853e61f60863446c38fad2f168` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,064 bytes with SHA-256 `6e266b64bacfe415c957fcaae5f697656a708af06d2e8f271b25d0417778341e` and root manifest identity `e15c8483d406c7367d5c5e38867909304aeee418444112f0de10dab47a6a9e11`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Sort rows in Java

Rejected. Semantic report order belongs to the runtime reducer.

### Allocate another maximum row buffer

Rejected. The retained rows and completed metadata arrays already contain the required information.

### Keep outer rewind history

Rejected. The package adapter never exposes or consumes host VM rewind. Retaining it multiplies output storage by transition count without adding evidence.

### Trust descriptor order

Rejected. Case identities, not names or completion order, define report order.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0276](WIP-0276-native-package-case-rows.md)
