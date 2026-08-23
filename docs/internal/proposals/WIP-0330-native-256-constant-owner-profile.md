# WIP-0330: Native 256-constant owner profile

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, package, and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, package tests, compiler limits |
| Depends on | WIP-0017, WIP-0329 |
| Supersedes | Native 64-constant dependency admission |
| Superseded by | Wider profiles backed by terminal boundary evidence |

## Summary

Admit the full 256-constant Wheeler compiler owner through the native package-test source profile.

The compiler already parses, evaluates, links, and bounds 256 class constants. The package adapter retained an older sixty-four-constant eligibility gate. That mismatch excluded physical owners such as `ResolvedStatements.w` before Wheeler could validate them.

## Profile

A dependency source may expose:

- zero through 256 public signed constants,
- zero through twenty-three public signed or Boolean functions,
- no test declarations, and
- no entry declaration.

At least one constant or function is required. Source count, source bytes, function count, imports, cases, artifacts, manifests, locks, archives, and report bounds do not change.

The Java check decides only whether a target enters the fixed native path. Wheeler still parses declarations, resolves visibility and types, evaluates constants, links imports, compiles each selected case, verifies the artifact, executes it once with fresh storage, and publishes the report.

## Boundary evidence

`NativePackageTestRunnerTest` constructs one canonical owner with exactly 256 public signed constants. The eligibility gate accepts it and rejects a 257th declaration.

The local-import package test then imports the same complete owner, reads `VALUE_255`, compiles the test natively, executes it once, and reports one passing assertion. This prevents a widened host predicate from standing in for native compilation evidence.

## Acceptance

- [x] The fixed package profile accepts exactly 256 public signed constants.
- [x] A 257th public signed constant rejects eligibility.
- [x] The twenty-three-function ceiling remains unchanged.
- [x] An imported reference to the 256th constant resolves natively.
- [x] The selected case compiles, verifies, and executes exactly once.
- [x] Unrelated source, transport, execution, and report bounds remain unchanged.
- [x] Focused package, documentation, and file policy gates pass.

## Rejected alternatives

### Keep the sixty-four-constant adapter ceiling

Rejected. It is narrower than the compiler's canonical class-constant bound and blocks physical compiler owners without testing Wheeler semantics.

### Raise every nearby bound

Rejected. Constant declarations do not consume more source slots, functions, cases, report rows, archives, or dependency edges.

### Trust the host eligibility count as compilation evidence

Rejected. The terminal imported constant must pass native parsing, constant evaluation, linking, lowering, verification, and execution.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0329](WIP-0329-native-compiler-resolved-local-return-suite.md)
