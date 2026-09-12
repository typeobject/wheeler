# WIP-0500: Native classical step identities

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler runtime, testing, and conformance maintainers |
| Created | 2026-09-06 |
| Updated | 2026-09-12 |
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

`NativeTestCaseBoundaryExampleTest` compiles and executes all 255 discovered cases across eight disjoint identity shards. Every invocation receives the complete source. Stage 0 independently admits all case names, derives the partitions, executes the fixture body, and supplies the complete expected report. Each native report matches all 39 bytes. A separate assertion bounds each invocation to 48 selected cases. The two-minute per-method deadline remains unchanged.

The same suite admits 255 parameter rows and rejects 256. These are native runner receipts, not a compiler fixed point or native recovery evidence.

## Bounded host work

Hosted runs 34421714092 and 34463263370 hit the terminal-case method deadline with four shards. A later pass did not repair that workload. Profiling the unchanged 255-case input found repeated vocabulary classification in duplicate-name discovery and repeated ASCII whitespace classification while projecting and compiling selected entries.

`TestSourceTests.w` now records recognized declaration-name tokens once. Duplicate checks compare only those names. The directory is populated before selection, so hidden duplicate names still reject. It occupies one private `MAX_COMPILER_TOKENS` word column. Region storage is derived from source bytes, token and tag columns, row values, and that name index. No source or case limit changes.

For `n` declarations, name uniqueness still requires at most `n * (n - 1) / 2` text comparisons. It no longer reclassifies every token in every earlier source prefix. This is not the member-front admission work in WIP-0498. The existing discovery profile and its remaining restrictions are unchanged.

`Scanner.w` classifies ASCII before consulting Unicode whitespace. The whitespace set is unchanged. An exhaustive native check compares the complete code-point domain with the independent host predicate, then checks negative and out-of-range values. The large check runs without rewind history. The ASCII check verifies that the Unicode helper is never entered and rewinds the complete machine state.

Eight identity partitions reduce the remaining selected-entry compilation work per method without truncating source or omitting cases. The partition union must contain all 255 cases. Every partition must be nonempty and stay within its work budget. These host batches are not native implementation limits or fixed-point evidence.

Final focused verification covers 123 examples and 25 source documentation and formatter tests. Terminal shard methods took 42 to 64 seconds locally. The complete terminal and scanner task took 8m25s. The earlier run with excessive recorded wall times is not deadline evidence.

The native archive test passes for 461 physical compiler modules, 2,244 constants, and 1,857 callables. Independent archive and graph reconstruction agrees with packaging. The selected linked reference remains 603,784 bytes with identity `bbe15beb804ccc7b6a02dc87da8ed30dbab985cd9be8f57fea08eec5258e6eb7`. This check does not compile every physical body. The locked scanner consumer checks all ASCII values and whitespace boundaries, then halts after 5,663 transitions.

## Acceptance

- [x] Both passing producers consume the retained native transition count.
- [x] Terminal, call, result, inverse, rejection, and rewind evidence passes.
- [x] Independent execution replaces the zero-count fixture assumptions.
- [x] Complete 255-case native reports match independent stage-0 transcripts.
- [x] Current documentation, source gates, archive identities, and affected locks agree.
- [x] The step-identity correction is committed and pushed without unfinished compiler work.

## Remaining work

WIP-0018 still owns full self-hosted testing and removal of duplicated semantic authorities. Full compiler composition, fixed-point evidence, recovery, and Java-free operation remain open.
