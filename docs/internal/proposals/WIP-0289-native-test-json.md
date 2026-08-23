# WIP-0289: Native test JSON

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, testing, package, and tool maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, report adapters, Java retirement |
| Depends on | WIP-0288 |
| Supersedes | Java JSON rendering for native package tests |
| Superseded by | WIP-0290 native test terminal |

## Summary

Render the canonical test-report JSON adapter from native profile-2 rows.

Native package execution already owned discovery, compilation, execution, diagnostics, coverage, row ordering, summary counts, and report identity. The command still reconstructed JSON through `TestReportRenderer.java`. `TestReportJson.w` now consumes the native report identity, package subject, summary, and canonical row bytes and publishes the exact adapter document.

The host carries the rendered bytes to stdout. It does not choose field order, status spelling, decimal encoding, escaping, summary values, or report identity for a native package.

## Transport

The renderer accepts:

- the 32-byte native report identity.
- one bounded canonical package subject.
- selected, passed, and failed unsigned 16-bit counts.
- one bounded canonical profile-2 row stream.

The renderer parses all ten counted fields and the 17-byte outcome suffix in every row. It requires complete consumption, nonnegative assertion and workflow counts, a closed pass or fail status, summary agreement, and a maximum of 64 cases.

The native package profile admits printable ASCII metadata and emits fixed printable diagnostics. The renderer rejects bytes outside that domain. It escapes quotes and reverse solidi and emits every other accepted byte directly. This is exact for every row the native package runner can produce. Broader Unicode presentation remains outside the fixed bootstrap profile.

## Adapter

The output retains schema `wheeler.test-report-adapter/1` and the established field order. Empty, passing, and failing reports are byte-identical to the Java migration adapter.

`PackageProject.TestOutput` carries the optional native JSON product beside the host-side row view. `Wheeler.java` writes that product directly for `--format json`. Packages outside the admitted native profile continue through the stage-zero adapter during migration.

An empty selection reuses the natively published empty report identity and bypasses nonempty row sorting. No synthetic case or host hash enters that path.

## Evidence

`testsThePhysicalCompilerSpineNatively` compares the seven-case native document byte for byte with the migration adapter. `publishesCompleteNativeFailureRows` does the same for one assertion failure and its diagnostic. `rendersAnEmptyNativeSelection` proves a known conjunctive tag selection with no matching declaration.

The direct command test covers stdout publication through `Wheeler.java` rather than only the renderer executable.

## Acceptance

- [x] Runtime code owns canonical JSON field order and spelling.
- [x] Runtime code parses complete native profile-2 rows.
- [x] Runtime code validates status and summary agreement.
- [x] Empty, passing, and failing products match stage zero byte for byte.
- [x] `wheeler test --format json` uses native bytes for admitted packages.
- [x] Java performs no native JSON field rendering.
- [x] Empty selection introduces no host-derived identity.
- [x] The renderer has a thin conformance publisher.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Focused renderer, command, package, documentation, workspace, and file-length policy pass.

The runtime archive contains 402,166 bytes with SHA-256 `a59d1b918bb514cfbd8e020aaa39fd39e44c16b60b68011153ce04d698d8420e` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 135,728 bytes with SHA-256 `a835f622650e691d0cd7119915fb784a79858b1aeecc54349bb8440d13d7c877` and root manifest identity `d3b50132be96caa0d75494879a96ed35d8bb69022d9ce4241f03db5603c99124`.

The compiler archive remains 3,024,011 bytes with SHA-256 `f368a20b722ed114247166df99f4a482fb099041d5ebfa4858a0c192429da70f` and root manifest identity `9b2cebe76654d6f2cb4d2ec3e3c2762bfc8e72009a796f7e28adf5903428bb99`.

## Rejected alternatives

### Serialize the parsed Java row model

Rejected. That leaves presentation authority in the migration host.

### Pass Java-rendered JSON through a native identity check

Rejected. Validation does not transfer rendering authority.

### Accept arbitrary malformed Unicode

Rejected. The bootstrap profile is printable ASCII and must fail closed outside it.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0268](WIP-0268-native-package-test-report-identity.md)
- [WIP-0276](WIP-0276-native-package-case-rows.md)
- [WIP-0288](WIP-0288-native-inverse-coverage.md)
- [WIP-0290](WIP-0290-native-test-terminal.md)
