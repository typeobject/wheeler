# WIP-0414: Bounded signed helper-result ownership

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and native-test maintainers |
| Created | 2026-08-27 |
| Updated | 2026-08-28 |
| Area | Self-hosting, helper syntax, compiler package tests, physical closure |
| Depends on | WIP-0007, WIP-0018, WIP-0245, WIP-0353, WIP-0364, WIP-0412 |
| Supersedes | Broad signed-result ownership in `HelperResultKinds.w` |
| Superseded by | None |

## Summary

Give signed helper-result classification one physical owner. Split statement identities from broad registries where the package boundary requires it. Compile every signed family through a 13,366-byte, six-source native plan.

`HelperResultKinds.w` retains Boolean and owned UTF-8 results. It carries no signed facade. `SignedHelperResultKinds.w` classifies signed literals, named arithmetic, resolved signed locals, forwarded calls, borrowed reads, map reads, and two-local arithmetic.

## Problem

The old `HelperResultKinds.w` mixed three result types behind seven imports. A native package case needed the test root, the mixed owner, and more source than the fixed eight-source and 40,960-byte plan admits.

Moving only the function did not close the graph. `StatementKinds.w` and `ResolvedStatements.w` remained broad constant authorities. Linking several executable classifier owners into an intermediate helper also exceeded the recovery compiler's admitted graph shape. Raising the plan bound or retaining a forwarding facade would hide both defects.

## Ownership cuts

The implementation leaves one authority at each boundary:

- `SignedReturnStatements.w` owns unresolved signed literal, local, arithmetic, XOR, and AND return identities.
- `ResolvedLocalReturnStatements.w` owns the two resolved local-return columns.
- `ResolvedLocalResultKinds.w` owns signed membership. `ResolvedLocalReturns.w` retains aggregate membership and source decoding.
- `ForwardedHelperResultStatements.w` owns zero- through seven-argument forwarding identities.
- `ForwardedHelperResultKinds.w` owns forwarding membership. `ResolvedReturnCallKinds.w` retains arity and source decoding.
- `SignedHelperResultKinds.w` owns the aggregate signed-result verdict.

This WIP removes the old constants and predicates from `StatementKinds.w`, `ResolvedStatements.w`, `ResolvedLocalReturns.w`, and `ResolvedReturnCallKinds.w`. Maintained callers import the focused owners directly. No compatibility module or copied test predicate remains.

The aggregate signed classifier consumes constant products only. It does not drag three executable classifier owners through an intermediate graph node. `ScalarHelperLibraries.w` imports the signed owner directly.

## Native package evidence

`NativeCompilerSignedHelperResultKindTests.w` publishes eleven cases. They cover direct and arithmetic results, resolved locals, forwarding, borrowed length and indexed reads, UTF-8 scalar and width reads, map reads, local-pair arithmetic, and negative Boolean and unknown opcodes. Each case stays inside the 255-transition coverage profile.

`NativeCompilerForwardedHelperResultKindTests.w` separately checks forwarding membership and the four-argument upper boundary. The resolved local-result case also has its own target. Splitting those roots avoids an unrelated multi-owner test graph.

The compiler package now has 75 native targets, 97 directly exercised production modules, and the complete 255-case report profile. All sixteen preselected shards pass. The signed tag selects eleven native cases and publishes report identity `cfc314edc24b88864e602964ab48b799e2a0181e9da5bd603d0383ced5b37071`.

## Physical closure

The five new focused owners and the signed aggregate owner compile from immutable archive ranges and match stage 0 byte for byte. The selected closure contains 89 comparable products and 17 imported-call products, for 106 framed artifacts. The signed aggregate has no callable relocation after constant-owner splitting.

A fresh complete run retains 278 functions, 10,751 instructions, 7,851 local types, and 253,560 code bytes. It carries 490 source-local strings into 385 canonical rows. The resulting 318,304-byte classical container has SHA-256 `c37056e2e794aa00e72fc7c607b05c844183906eb87777ffcb8a3f32b2f44b30` and prefix `c37056e2`. The stage-0 reader accepts the container and its `$library` entry halts. The complete method passes in 19 minutes 39 seconds under the fixed 24-minute limit.

## Bootstrap identities

The compiler graph contains 385 modules and 1,919 imports. Its 180,786-byte canonical manifest has SHA-256 `bb4d223beb29b96a759a98262b5b82147bfde462115df939ff9d7e44d9a39621`. Native validation halts after 75,383,013 committed transitions. Wheeler SHA-256 consumes the same bytes in 34,597,266 transitions.

The package manifest identity is `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,179,964-byte compiler archive has SHA-256 `409273de3bedd95100a4da5495f82aabb635a0da4850b7021165482fb8d6e93f`. Every dependent lock names both identities.

## Failure boundary

Reject a missing focused identity owner, detached source, duplicate module, stale lock, malformed opcode, unselected tag, exhausted case profile, or over-bound source plan before compilation or report publication. A negative classifier verdict remains an ordinary Boolean result. It does not trap and does not repair an unknown opcode.

## Acceptance

- [x] Signed classification is separate from the shared Boolean and owned UTF-8 owner.
- [x] Statement identities and decoder predicates have one focused authority each.
- [x] No forwarding facade or copied test predicate remains.
- [x] Eleven signed cases and two forwarding cases cover every family and negative boundary.
- [x] The signed target uses six sources and 13,366 plan bytes.
- [x] Focused native products match stage 0.
- [x] A complete physical link reproduces the container identity under the fixed method limit.
- [x] Manifest, SHA-256, archive, package, and dependent-lock evidence passes.
- [x] All sixteen compiler package shards pass at the complete 255-case bound.

## Rejected alternatives

### Raise the source-plan bound

The old owner crossed the bound because it imported broad registries. Raising the bound would retain the wrong ownership graph.

### Copy the predicate into tests

A test-local predicate proves only itself.

### Keep a compatibility facade

All callers live in the maintained source tree. A facade would preserve a second public authority and another relocation.

### Link every classifier as an executable dependency

The recovery compiler admits bounded helper graphs, not arbitrary intermediate fan-in. Constant-owner cuts keep the aggregate classifier inside the supported graph without changing its verdicts.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0245](WIP-0245-native-eight-source-test-compilation.md)
- [WIP-0353](WIP-0353-native-40k-source-plan-bound.md)
- [WIP-0364](WIP-0364-native-compiler-helper-value-suite.md)
- [WIP-0412](WIP-0412-preselected-compiler-package-shards.md)
