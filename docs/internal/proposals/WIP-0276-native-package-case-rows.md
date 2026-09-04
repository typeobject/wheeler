# WIP-0276: Native package case rows

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package testing, reports |
| Depends on | WIP-0268, WIP-0275 |
| Supersedes | Native summary parity followed by Java package discovery and execution |
| Superseded by | None |
| Follow-up | WIP-0277 canonical target rows, then external import binding and compiler suite migration |

## Summary

Publish complete native profile-2 case rows and use them as the package command's semantic report for every eligible target.

The runtime already built ten-field case rows before reducing report identity and summary. It discarded them after publication. The expanded output profile now returns those exact rows after the 39-byte identity and summary product.

`NativePackageTestRunner` validates framing, decodes each row into the existing immutable report model, reconstructs the target report identity with the native runner identity, and rejects any disagreement. `PackageProject.test` returns that native report immediately. It no longer runs Java discovery, compilation, execution, coverage, or outcome policy for an eligible package.

Java remains a host adapter for terminal, JSON, and JUnit XML rendering. It does not decide eligible case semantics.

## Output profile

A caller may retain the compact 39-byte output buffer. Existing conformance targets and metadata probes remain byte-identical.

A caller requesting the fixed 342,123-byte publication capacity receives:

1. 32 raw report-identity bytes.
2. The seven-byte selected, passed, and failed summary.
3. One little-endian 32-bit case-row byte length.
4. The complete concatenated profile-2 rows.

The host observes only the actual published prefix. The row length must consume it exactly.

Each row carries ten little-endian 16-bit framed UTF-8 fields:

- Package name.
- Package version.
- Module-qualified case name.
- Case identity.
- Source identity.
- Artifact identity.
- Diagnostic code.
- Diagnostic message.
- Execution identity.
- Coverage identity.

The runner appends one status byte, one little-endian signed 64-bit assertion count, and one little-endian signed 64-bit workflow-step count.

## Validation

The host adapter checks every field boundary, terminal row boundary, status, case count, report model invariant, and target report identity. It cannot substitute a row while retaining native identity.

The report constructor now accepts an explicit validated runner identity. Stage-0 reports still derive their content identity from `Stage0CompilerIdentity`. Native rows use the canonical native runner identity that entered Wheeler reduction.

Multi-target package evidence remains the WIP-0268 reduction over target report products. The command's rendered report combines the native target rows under the same native runner identity. Workspace reduction preserves a common runner identity and rejects mixed-runner reports instead of relabeling them.

## Cutover

For an eligible package, `PackageProject.test` invokes native selection first. A native result is final. No stage-0 `testRun`, unknown-tag registry, artifact build, runtime execution, or summary comparison follows it.

Packages outside the fixed profile retain the stage-0 path during migration. This is a profile cutover, not a silent fallback after native execution begins.

## Evidence

`invokesEveryNativePackageTestTarget` runs two targets and obtains the report twice: once through the direct native adapter and once through `PackageProject.test`. Complete case records and native report identities are equal. The report carries native artifact, execution, coverage, assertion, workflow, source, case, and package fields.

`publishesCompleteNativeFailureRows` executes a failing declaration. The package command returns one native failed row with `WTEST003`, one assertion attempt, and one native report identity. Java does not execute a second case to decide that outcome.

The local-import, tag, multi-target, locked-dependency, package-reduction, compact-output, and metadata-only profiles remain green.

## Acceptance

- [x] The runtime may publish exact retained profile-2 rows.
- [x] Compact 39-byte callers remain supported.
- [x] Extended row publication has one exact terminal boundary.
- [x] The adapter validates every field and outcome frame.
- [x] Parsed rows reproduce the native target report identity.
- [x] Multi-target rows combine under the native runner identity.
- [x] Mixed-runner report combination rejects.
- [x] Passing rows retain every profile-2 identity and count field.
- [x] Failing rows retain native diagnostics and assertion attempts.
- [x] Eligible package commands skip Java discovery and execution.
- [x] Java remains presentation-only for eligible package reports.
- [x] Superseded summary-parity code is deleted.
- [x] Runtime and conformance locks are rebuilt exactly.
- [x] Focused runtime, examples, tools, documentation, package, workspace, and file-length policy pass.

The runtime archive contains 372,215 bytes with SHA-256 `8a8aeacbb2146e5e448b4e3093e1e77fa5609de9b8287686347aed0a4f0be73d` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 132,064 bytes with SHA-256 `6e266b64bacfe415c957fcaae5f697656a708af06d2e8f271b25d0417778341e` and root manifest identity `e15c8483d406c7367d5c5e38867909304aeee418444112f0de10dab47a6a9e11`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Keep native summary parity and Java rows

Rejected. Counts do not make Java-discovered artifacts, outcomes, and diagnostics native authority.

### Recompute row identities in Java

Rejected. The adapter reconstructs only the enclosing report identity as a transport check. Wheeler supplies every semantic row field.

### Publish JSON from the runner

Rejected. JSON is an adapter encoding, not the semantic report transport.

### Fall back after a native trap

Rejected. Once an eligible transport enters native execution, failure is final.

## References

- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0268](WIP-0268-native-package-test-report-identity.md)
- [WIP-0275](WIP-0275-native-locked-package-test-gate.md)
- [WIP-0277](WIP-0277-canonical-native-target-rows.md)
