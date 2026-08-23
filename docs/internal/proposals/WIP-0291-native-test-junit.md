# WIP-0291: Native test JUnit XML

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, testing, package, and tool maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, CI adapters, Java retirement |
| Depends on | WIP-0290 |
| Supersedes | Java JUnit XML rendering for native package tests |
| Superseded by | Java-free workspace report composition |

## Summary

Render JUnit XML from canonical native profile-2 rows.

All three public test presentation formats now have runtime implementations for admitted native package suites. `Wheeler.java` writes the native byte array selected by `--format terminal`, `--format json`, or `--format junit-xml`. It invokes the Java renderer only for packages and workspaces still outside the native execution profile.

## XML adapter

`TestReportJunit.w` consumes the shared framing from WIP-0290. It writes:

- one XML 1.0 UTF-8 declaration.
- one suite with subject, selected, failed, skipped, and report identity attributes.
- one case element per canonical profile-2 row.
- one failure element for each failed row.
- source, artifact, execution, coverage, assertion, workflow, and case identities.

The renderer escapes ampersand, less-than, greater-than, quotation-mark, and apostrophe bytes. It rejects bytes outside the printable ASCII native profile. Empty attribute values remain explicit, preserving the established migration format.

The renderer verifies complete row consumption and summary agreement through `TestReportAdapter.w`. XML syntax cannot alter semantic ordering or identities.

## Host boundary

`NativePackageTestRunner.Result` and `PackageProject.TestOutput` return defensive copies of native JSON, JUnit XML, and terminal products. The command writes those bytes directly. Java neither reparses nor reconstructs a native adapter document.

`TestReportRenderer.java` remains only for stage-zero package profiles and workspace composition. It is no longer a presentation authority for the checked-in native compiler suite or other admitted package tests.

## Evidence

The seven-case compiler suite, one assertion failure, and one empty conjunctive selection each require byte identity between native JUnit XML and the migration adapter. The existing command test exercises `--format junit-xml` through the direct native package route.

## Acceptance

- [x] Runtime code owns JUnit XML structure and field order.
- [x] Runtime code escapes the complete admitted XML character profile.
- [x] Empty, passing, and failing products match stage zero byte for byte.
- [x] Every profile-2 identity and count reaches the XML product.
- [x] `wheeler test --format junit-xml` writes native bytes for admitted packages.
- [x] Java performs no native JUnit XML field rendering.
- [x] All three native adapters share one framing authority.
- [x] The JUnit XML renderer has a thin conformance publisher.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Focused adapter, command, package, documentation, workspace, and file-length policy pass.

The runtime archive contains 415,390 bytes with SHA-256 `8d209a6e58ca4c8091f4b12e2f651d8e4825e179c42e17c4c3c77de8523c6b60` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 137,466 bytes with SHA-256 `b9fd97a6ed879e0d764394af43eb2a4b45dfda9a6d029e31ad52db0a981f8dc7` and root manifest identity `28666332534b671c8b11fdba27be509349295c89d58200178b7fe0c2965b3450`.

The compiler archive remains 3,024,011 bytes with SHA-256 `f368a20b722ed114247166df99f4a482fb099041d5ebfa4858a0c192429da70f` and root manifest identity `9b2cebe76654d6f2cb4d2ec3e3c2762bfc8e72009a796f7e28adf5903428bb99`.

## Rejected alternatives

### Emit a reduced CI-only XML subset

Rejected. Existing consumers require the complete profile-2 adapter fields.

### Let Java escape XML values

Rejected. Escaping is part of deterministic adapter rendering.

### Remove the migration renderer immediately

Rejected. Non-native package profiles and workspace composition still require a temporary adapter.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0289](WIP-0289-native-test-json.md)
- [WIP-0290](WIP-0290-native-test-terminal.md)
