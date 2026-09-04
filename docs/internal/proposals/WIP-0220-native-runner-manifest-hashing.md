# WIP-0220: Native runner manifest hashing

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, package manifests, identity provenance |
| Depends on | WIP-0009, WIP-0018, WIP-0219 |
| Supersedes | Host-supplied runner manifest digests |
| Superseded by | None |
| Follow-up | WIP-0221 native test-target selection |

## Summary

Replace the raw manifest digest in the runner frame with the exact canonical package manifest bytes.

`TestRunner.w` now hashes the bounded manifest range with `wheeler.crypto.sha256`. The resulting raw digest feeds every WIP-0195 case transcript. A host can no longer pair arbitrary manifest bytes with an unrelated case-identity digest.

## Frame

The package header carries a four-byte little-endian manifest length and 1 to 4,096 manifest bytes after package name, version, and target. The descriptor count follows the exact range.

The preflight pass validates the manifest range before reading the count or any descriptor. It still validates the complete descriptor stream before execution.

## Canonical input

The package layer supplies canonical schema-1 YAML. The current runtime boundary hashes bytes but does not parse package fields from YAML. It therefore closes digest provenance, not full manifest interpretation.

Native package parsing must next prove that header name, version, target, test selection, and lock policy agree with these bytes. Until then the stage-0 package layer constructs the canonical manifest and descriptor frame.

## Identity

SHA-256 over the exact manifest bytes yields the package manifest identity used by stage 0. The runtime writes its lowercase hexadecimal form into every case transcript. Source identities remain SHA-256 over exact source bytes.

Changing whitespace, target policy, dependency declarations, capabilities, or any other manifest byte changes every case identity and shard assignment. Empty runs retain the manifest bytes in their invocation frame, while the profile-2 empty report remains runner-only.

## Bounds

Manifest bytes are limited to 4,096. SHA-256 uses the existing bounded three-allocation scratch set. The 700,000-byte outer region and 32-allocation cap remain sufficient.

Descriptor rows lose no information. The former 32-byte digest becomes one length-prefixed source document.

## Evidence

`NativeCoverageRunExampleTest` uses a canonical schema-1 manifest for package `pkg` version `1.0.0` and test target `test`. `PackageManifestParser` independently round-trips the fixture to identical canonical text.

Java derives SHA-256 over those bytes and feeds the hexadecimal result into every independent case transcript. The changed digest reorders the canonical two- and three-case reports and moves the three semantic cases to distinct `1/4` shards. Native output matches every recomputed product.

The 65-case rejection test locates the count after the variable manifest range. Truncation and empty package metadata still publish nothing.

The runtime archive contains 186,592 bytes with SHA-256 `9eff816c2c5d8f6d39e1023ba5989e0558d1e12855edb7ca33c4f39727e9329d` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] The runner receives exact manifest bytes instead of a digest.
- [x] Wheeler derives the shared package manifest identity.
- [x] Independent stage-0 parsing proves fixture canonicality.
- [x] Independent report transcripts use the byte-derived identity.
- [x] Shard assignments change with the complete manifest digest.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Trust a host digest beside manifest bytes

Rejected. Two purported authorities create a mismatch state with no useful meaning.

### Hash package name and version only

Rejected. Test targets, dependencies, capabilities, and policy are semantic package inputs.

### Claim byte hashing validates YAML

Rejected. Identity provenance and manifest interpretation are separate checks.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0219](WIP-0219-shared-runner-manifest-identity.md)
- [WIP-0221](WIP-0221-native-test-manifest-selection.md)
