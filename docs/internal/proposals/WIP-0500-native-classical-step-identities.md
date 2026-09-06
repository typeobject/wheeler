# WIP-0500: Native classical step identities

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler runtime, testing, and conformance maintainers |
| Created | 2026-09-06 |
| Updated | 2026-09-06 |
| Area | Native execution, test reports, identity parity |
| Depends on | WIP-0018, WIP-0208, WIP-0209 |
| Supersedes | Zero-step classical identity and passing-report composition in WIP-0208 and WIP-0209 |
| Superseded by | None |

## Boundary

Native passing reports wrote zero into `workflowSteps`. Stage 0 uses that field for the complete VM transition count of a successful classical run. Even a lone `HALT` therefore produced a different execution identity. Earlier native fixtures repeated the zero instead of reading an actual `ExecutionResult`.

This record corrects the native producers. It does not rename the field, change the identity schemas, or claim complete native testing or Java-free execution. [WIP-0018](WIP-0018-integrated-deterministic-testing.md) retains those broader gates.

## Change

`ArtifactExecution.w` owns the completed native count in `ArtifactOutcome.steps`. `TestArtifactExecutionIdentity.w` serializes that count into the execution frame. `TestArtifactReport.w` writes the same count into a passing row. Neither consumer executes the artifact again.

The count belongs to the interpreted artifact. It includes that artifact's terminal instructions, caller transitions, callee bodies, and executed inverse bodies. It excludes the outer interpreter's work. It is not elapsed time, a proof bound, or evidence of quantum work. The native profile still carries no measurements, quantum jobs, or direct output.

Failure rows retain zero and no successful execution identity under WIP-0210. The change adds no allocation and widens no source, frame, artifact, history, or interpreter limit. Existing readers keep their schemas. Corrected successful outcomes produce new execution and report hashes, without a zero-count compatibility path.

## Evidence

`NativeArtifactStepIdentityExampleTest` compares native identities with actual stage-0 execution of terminal-only, assertion, void-call, value-call, and generated-inverse programs. The terminal-only program records one transition. Identity publication and malformed-artifact rejection fully rewind.

The locked `nativetestartifactexecutionidentity` package target also reproduces the independent one-transition identity. It consumes the measured runtime archive through the checked-in conformance lock.

`NativeCoverageRunExampleTest` now obtains passing execution counts and coverage from the stage-0 runtime rather than fixture constants. Its one-case and descriptor reports compare complete identities. Failure diagnostics and rejection publication remain covered.

`NativeTestReportOracle` owns the independent JVM encodings used by case, execution, and report identity tests. Those tests retain empty, sorted, duplicate, signed-value, complete-transcript, and 255/256-row checks.

`NativeTestCaseBoundaryExampleTest` compiles and executes all 255 discovered cases across four disjoint identity shards. Every invocation receives the complete source. Stage 0 independently admits all case names, derives the partitions, executes the fixture body, and supplies the complete expected report. Each native report matches all 39 bytes. The two-minute per-method deadline remains unchanged.

The same suite admits 255 parameter rows and rejects 256. These are native runner receipts, not a compiler fixed point or native recovery evidence.

## Acceptance

- [x] Both passing producers consume the retained native transition count.
- [x] Terminal, call, result, inverse, rejection, and rewind evidence passes.
- [x] Independent execution replaces the zero-count fixture assumptions.
- [x] Complete 255-case native reports match independent stage-0 transcripts.
- [x] Current documentation, source gates, archive identities, and affected locks agree.
- [x] The isolated change is committed and pushed without unfinished compiler work.

## Remaining work

WIP-0018 still owns full self-hosted testing and removal of duplicated semantic authorities. Full compiler composition, fixed-point evidence, recovery, and Java-free operation remain open.
