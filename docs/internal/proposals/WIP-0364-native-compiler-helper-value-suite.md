# WIP-0364: Native compiler helper-value suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests, helper syntax |
| Depends on | WIP-0363 |
| Supersedes | Product-only helper-value classifier evidence |
| Superseded by | None |
| Follow-up | WIP-0365 nested helper-owner graph execution |

## Summary

Execute the complete admitted helper-value statement families through the physical `HelperValueKinds.w` classifier.

One public query covers owned storage, void calls, borrowed mutation, local helper calls, arithmetic and Boolean return ranges, helper-call returns, and borrowed intrinsic returns and declarations. Ten independent native cases keep those semantic leaves visible instead of reducing the classifier to one favorable input.

## Graph

```text
NativeCompilerHelperValueKindTests
  -> HelperValueKinds
       -> BorrowedIntrinsicKinds
       -> StatementKinds
       -> VoidCallSourceKinds -> StatementKinds
```

The root imports only `HelperValueKinds`. The native graph preserves the shared `StatementKinds` owner without adding a redundant direct root edge.

`NativeCompilerHelperValueKindsPhysicalProductExampleTest` independently retains the complete physical callable product, resolves its `VoidCallSourceKinds.w` relocation, and checks function and instruction extents against stage 0.

## Cases

The suite admits:

- owned byte allocation,
- the seven-argument void-call boundary,
- borrowed map mutation,
- the seven-local scalar-call boundary,
- the terminal local-call range,
- the terminal local arithmetic-return range,
- the terminal Boolean-return range,
- helper-call returns,
- the final borrowed return, and
- the final borrowed local declaration.

Each case enters through the package runner, compiles one fresh lowered entry, executes once, and publishes one canonical row. Numeric statement identities remain owned by complete physical production modules. The test root does not project their declarations.

The complete compiler package publishes 220 selected, 220 passed, and zero failed cases across 68 native targets. The canonical workspace checks 174 targets. JSON, terminal, and JUnit adapters consume the same rows. The run finishes in thirty-four minutes and eight seconds under a forty-one-minute host guard.

The compiler manifest contains 36,283 bytes with identity `758a480478ca5416e1653ecc9990554bb00e1636b37a559a3c2418f573403155`. The compiler archive contains 3,123,200 bytes with SHA-256 `69407490107ef1d3fe57fb8d6524454a635c01ae8f50744ba13c8502847656d0`.

## Acceptance

- [x] The sole public query executes at ten distinct semantic leaves.
- [x] Owned, call, borrowed, local, and return families remain represented.
- [x] Seven-argument and seven-local terminal forms execute.
- [x] Complete constant and callable owners remain input.
- [x] The physical callable product matches stage-0 function and instruction extents.
- [x] Every selected case executes exactly once with fresh storage.
- [x] All report adapters consume the same 220 rows.
- [x] Compiler, package, workspace, documentation, archive, and file policy gates pass.

## Rejected alternatives

### Keep one terminal borrowed case

Rejected. One true result cannot distinguish the classifier's call, storage, arithmetic, and Boolean regions.

### Import every constant owner into the test root

Rejected. Numeric inputs avoid redundant graph edges while complete production sources retain identity authority.

### Split each statement family into a WIP

Rejected. One physical classifier and one evidence boundary own the work.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0170](WIP-0170-direct-helper-value-kind-physical-product.md)
- [WIP-0363](WIP-0363-native-compiler-borrowed-intrinsic-shape-suite.md)
- [WIP-0365](WIP-0365-nested-helper-owner-graph-execution.md)
