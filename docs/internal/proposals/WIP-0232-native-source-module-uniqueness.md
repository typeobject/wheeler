# WIP-0232: Native source module uniqueness

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, compiler, and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Native testing, source plans, module graph |
| Depends on | WIP-0009, WIP-0018, WIP-0231 |
| Supersedes | Syntax-only native source module validation |
| Superseded by | None |
| Follow-up | WIP-0233 native local import resolution |

## Summary

Reject duplicate module identities in native target-source plans before hashing or execution.

WIP-0231 proved that every payload carries a canonical module declaration. A plan could still bind two paths to the same module. Such a plan has no deterministic module owner and cannot enter compilation, discovery, or case identity.

`TestSourcePlan.w` now compares each accepted module with all preceding plan entries and rejects an exact duplicate.

## Algorithm

For source entry `N`, the validator rescans the already validated entries `0..N-1` from the plan start. It derives both declaration ranges through the shared canonical preamble parser, compares lengths, then compares complete module bytes.

The algorithm retains no module table and allocates no storage. The validator bounds work to 64 sources, 255 module bytes, and the 32,768-byte plan limit. The quadratic comparison is deliberate at this recovery boundary. Sixty-four bounded scans are smaller and easier to audit than a second mutable index with its own ownership and collision rules.

Source path order remains independent of module order. The validator requires uniqueness, not lexical module sorting. Real package paths and module names do not always share the same ordering relation.

## Failure behavior

A duplicate module rejects during source-plan validation before manifest hashing, source hashing, lock validation, descriptor identity, shard selection, artifact verification, execution, or publication.

The validator compares source module bytes, not path stems. Renaming a file cannot create another owner for an existing module.

## Evidence

The accepted fixture maps three distinct paths to `pkg.fail`, `pkg.pass`, and `pkg.runtime`.

`NativeCoverageRunExampleTest` changes the non-root declaration `pkg.fail` to `pkg.pass` without changing any frame length or module syntax. The root source still matches the manifest. Only source-set module uniqueness fails, and output remains untouched.

The runtime archive contains 216,241 bytes with SHA-256 `e541cc79a1ee1d568616b34c15ba2e54dbe3d5fa573783bf25f4052f5c235be2` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Every module is compared with all prior source entries.
- [x] Duplicate complete module identities reject.
- [x] Module order remains independent of source path order.
- [x] Validation allocates no module table.
- [x] Work stays under existing source, module, and plan bounds.
- [x] A length-preserving duplicate fixture publishes no output.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Derive module identity from the source path

Rejected. Manifest module declarations are semantic coordinates. Paths only locate bytes.

### Require modules to sort with paths

Rejected. The package format does not impose that relation.

### Add a hash table

Rejected. The recovery bound is small. Exact bounded comparisons avoid collision and mutable-index authority.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0231](WIP-0231-native-source-module-declarations.md)
- [WIP-0233](WIP-0233-native-local-import-resolution.md)
