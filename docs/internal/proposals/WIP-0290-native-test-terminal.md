# WIP-0290: Native test terminal

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, testing, package, and tool maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, report adapters, Java retirement |
| Depends on | WIP-0289 |
| Supersedes | Java terminal rendering for native package tests |
| Superseded by | Native JUnit XML adapter |

## Summary

Render the terminal test adapter from canonical native profile-2 rows.

`wheeler test` now writes runtime-produced terminal bytes for every admitted native package suite. The host no longer chooses case status, field order, assertion counts, coverage text, diagnostics, summary text, or report identity for that path.

WIP-0290 also moves common adapter framing out of the JSON renderer. `TestReportAdapter.w` owns the transport header, profile-2 row parsing, decimal encoding, and raw identity encoding used by both native presentation adapters.

## Shared framing

`validatedTestReportAdapter` validates:

- one bounded package subject.
- selected, passed, and failed counts.
- count agreement.
- the exact bounded row-stream boundary.

`validatedTestReportRow` fills the ten field spans and validates one status, assertion count, workflow count, and row boundary. JSON and terminal rendering no longer carry separate row parsers.

The shared module also owns canonical nonnegative decimal output and lowercase hexadecimal report identities. Presentation-specific escaping remains with each renderer.

## Terminal adapter

For every case, `TestReportTerminal.w` writes status, package and target, case identity, assertion count, optional coverage identity, and optional diagnostic. It then writes the selected, passed, failed, and report-identity summary.

The output remains byte-identical to the migration adapter for empty, passing, and failing suites. Printable ASCII remains the admitted native presentation profile.

`PackageProject.TestOutput` carries native terminal and JSON bytes defensively. `Wheeler.java` writes those arrays directly. JUnit XML remains on the Java migration adapter.

## Evidence

`testsThePhysicalCompilerSpineNatively` compares the seven-case native terminal and JSON documents byte for byte with stage zero. `publishesCompleteNativeFailureRows` checks the failing diagnostic path. `rendersAnEmptyNativeSelection` checks the summary-only document. The command test exercises direct terminal stdout and all JSON selection forms.

## Acceptance

- [x] One runtime module owns adapter header and row framing.
- [x] JSON and terminal adapters share that authority.
- [x] Runtime code owns terminal case and summary spelling.
- [x] Empty, passing, and failing terminal products match stage zero byte for byte.
- [x] `wheeler test` writes native terminal bytes for admitted packages.
- [x] Java performs no native terminal field rendering.
- [x] Native byte arrays cross the host boundary defensively.
- [x] The terminal renderer has a thin conformance publisher.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Focused adapter, command, package, documentation, workspace, and file-length policy pass.

The runtime archive contains 408,096 bytes with SHA-256 `6738e5ae79e3862d0357eb1d77f103a32bbfb929a60daef67c5ce6afee3c1614` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 136,610 bytes with SHA-256 `d5d117a46b3b79b9c88aafe7186256efbf03be44639efaf160b652004a710d31` and root manifest identity `59f3bf2ae0191d494f61833c57acdab2aea72aa535a06c42afad1ff42ef3a062`.

The compiler archive remains 3,024,011 bytes with SHA-256 `f368a20b722ed114247166df99f4a482fb099041d5ebfa4858a0c192429da70f` and root manifest identity `9b2cebe76654d6f2cb4d2ec3e3c2762bfc8e72009a796f7e28adf5903428bb99`.

## Rejected alternatives

### Keep one parser per renderer

Rejected. Adapter syntax is one authority, not a presentation choice.

### Reconstruct terminal lines in Java

Rejected. Parsed native rows are not native presentation authority.

### Return mutable native adapter arrays

Rejected. Host callers must not mutate retained products.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0289](WIP-0289-native-test-json.md)
