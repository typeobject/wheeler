# WIP-0363: Native compiler borrowed-intrinsic shape suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests, borrowed storage |
| Depends on | WIP-0362 |
| Supersedes | Product-only borrowed-intrinsic shape evidence |
| Superseded by | None |
| Follow-up | WIP-0364 native compiler helper-value suite |

## Summary

Execute all four public borrowed-intrinsic shape queries through native package tests.

`BorrowedIntrinsicShapes.w` owns local widths, result slots, instruction widths, and instruction counts for borrowed buffers, byte views, UTF-8 values, signed maps, and mutable borrowed writes. Its three private classifiers remain part of the complete physical owner.

## Graph

```text
NativeCompilerBorrowedIntrinsicShapeTests
  -> BorrowedIntrinsicShapes
       -> BorrowedIntrinsicKinds
```

The test root imports only `BorrowedIntrinsicShapes`. It does not create a redundant direct edge to `BorrowedIntrinsicKinds`. The package source plan retains both complete production modules and lets the compiler graph establish constant authority.

`NativeCompilerBorrowedIntrinsicShapesPhysicalProductExampleTest` independently compiles the complete eight-function library artifact against stage 0 byte for byte.

## Boundary cases

The suite executes one case per public query:

- resolved local buffer length maps to three locals,
- its result occupies local offset two,
- resolved local UTF-8 width emits 104 code bytes, and
- the same form emits four instructions.

The final two cases traverse the terminal indexed-read branch. The first two retain the smaller direct length branch. Numeric inputs are physical opcode identities, not projected test declarations.

The complete compiler package publishes 210 selected, 210 passed, and zero failed cases across 67 native targets. The canonical workspace checks 173 targets. JSON, terminal, and JUnit adapters consume the same rows. The run finishes in twenty-seven minutes and forty-five seconds under a thirty-one-minute host guard.

The compiler manifest contains 35,679 bytes with identity `916101453445c9ef80024b293e1d8b2d6029ed3072affe522274b26118a9b27a`. The compiler archive contains 3,120,969 bytes with SHA-256 `5a74b67b3903c1e05020d3b83885064bd1bdef02dee05483d6eaf25955bc924b`.

## Acceptance

- [x] Every public shape query has an independent native case.
- [x] The complete private-helper owner remains input.
- [x] The physical constant dependency remains input.
- [x] No redundant root-to-constant edge enters the graph.
- [x] The production library artifact matches stage 0 byte for byte.
- [x] Every selected case executes exactly once with fresh storage.
- [x] All report adapters consume the same 210 rows.
- [x] Compiler, package, workspace, documentation, archive, and file policy gates pass.

## Rejected alternatives

### Import intrinsic constants into the test root

Rejected. A redundant root edge obscures the production dependency graph and proves a different topology.

### Project private classifiers into the test source

Rejected. Public shapes depend on the complete physical private-helper prefix.

### Merge the shape owner into intrinsic kinds

Rejected. Opcode identity and lowering layout have separate semantic ownership.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0138](WIP-0138-direct-borrowed-intrinsic-shape-adoption.md)
- [WIP-0362](WIP-0362-native-40k-test-manifest-bound.md)
- [WIP-0364](WIP-0364-native-compiler-helper-value-suite.md)
