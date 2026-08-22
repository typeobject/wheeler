# WIP-0266: Native multi-target tag gate

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package testing, tag selection |
| Depends on | WIP-0260, WIP-0265 |
| Supersedes | Empty-tag-only multi-target native gating |
| Superseded by | WIP-0267 native package tag existence |

## Summary

Apply selected command tags inside every native target invocation without treating target-local absence as a package error.

A package tag may occur on one test target and not another. WIP-0260 correctly rejects an unknown tag for one standalone target, but independent strict invocations cannot distinguish target-local absence from package-wide absence.

Mode 253 now requests module-qualified descriptor construction with relaxed target-local selected-tag existence. Source tag grammar, metadata validation, and conjunction remain unchanged. A target with no matching selected tag publishes an empty report and zero summary counts.

`wheeler test` uses mode 253 only when a package has more than one test target. Stage 0 continues to validate package-wide unknown tags before native invocation. Native package-wide unknown-tag reduction remains explicit follow-up work.

## Semantics

Mode 253 changes one condition after complete source discovery: a selected tag need not occur in that target. It does not change:

- Selected-tag transport grammar or lexical order.
- Source tag token parsing.
- Duplicate or malformed source-tag rejection.
- Conjunctive declaration membership.
- Complete declaration, row, limit, module, and manifest validation.
- Module-qualified case construction.
- Shard-before-compilation scheduling.

Malformed metadata in an unselected target still rejects. Only absence of an otherwise canonical selected tag stops being a target-local error.

Modes 254 and 255 retain strict selected-tag existence for standalone package and conformance invocation.

## Package boundary

`PackageProject.test` first builds the stage-0 rendering model and rejects tags absent from the complete package. It then invokes every native target with the same sorted selected-tag set.

Each target selects cases natively. The adapter aggregates target summaries and requires equality with the package rendering summary. Java does not send selected descriptor names or artifacts.

The remaining Java global unknown-tag check is named rather than hidden. Removing it requires a native package reducer that sees the union of available target tags before accepting the run.

## Evidence

`invokesEveryNativePackageTestTarget` declares `fast` only on target `alpha` and `slow` only on target `beta`.

An unfiltered native run publishes two target identities and two passes. A package-wide `fast` run invokes both targets: `alpha` selects and passes one case, while `beta` validates completely and publishes an empty target report. Aggregate native and stage-0 summaries both contain one selected and one passed case.

Single-target tag selection remains strict under mode 254. An unknown selected tag still rejects that profile.

## Acceptance

- [x] Mode 253 permits target-local selected-tag absence.
- [x] Mode 253 retains module-qualified descriptor construction.
- [x] Source metadata remains completely validated for empty target selections.
- [x] Tag conjunction remains native declaration authority.
- [x] Every target receives the same sorted selected-tag set.
- [x] Aggregate selected, passed, and failed counts retain parity checks.
- [x] Modes 254 and 255 retain strict unknown-tag rejection.
- [x] Two targets with disjoint tags select one package case correctly.
- [x] Documentation names the remaining Java package-wide unknown-tag check.
- [x] Runtime and conformance archives and dependent locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

The runtime archive contains 331,008 bytes with SHA-256 `85264846add92b533131e88bb11c66b5a9d012ca4353ee90c87be10e729be77e` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,221 bytes with SHA-256 `c8225a24f2dc0c2d9cffe708b25e1fa662ba6a771d1a85fbc63d188c0ffc7ea5` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the runtime archive exactly.

## Rejected alternatives

### Skip targets in Java when their tags do not match

Rejected. Native source metadata owns case membership.

### Treat every target-local absence as unknown

Rejected. Tag names have package scope.

### Disable malformed metadata checks for empty selections

Rejected. Filters cannot conceal invalid source.

### Claim package-wide native unknown-tag authority

Rejected. Mode 253 deliberately lacks the cross-target union.

## References

- [WIP-0260](WIP-0260-native-test-tag-selection.md)
- [WIP-0265](WIP-0265-native-multi-target-package-test-gate.md)
- [WIP-0197](WIP-0197-runtime-test-selection-authority.md)
- [WIP-0267](WIP-0267-native-package-tag-existence.md)
