# WIP-0322: Native compiler helper-parameter suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0321 |
| Supersedes | Standalone helper-signature parameter evidence |
| Superseded by | WIP-0323 native compiler helper-signature suite |

## Summary

Compile the complete physical helper-signature owner and execute its parameter-count map through the native compiler package suite.

`HelperSignatures.w` owns nine public scalar queries. This first package partition calls `parameterCountForHelper` at the sixteen-parameter upper bound. The compiler retains all nine members under one owner and resolves 53 imported ABI constants from `HelperAbi.w`. Remaining result and kind queries stay explicit follow-up work.

## Graph

The target carries three physical sources:

```text
NativeCompilerHelperSignatureTests -> HelperSignatures -> HelperAbi
```

The test root sees only the signature owner. ABI declarations remain a separate constant owner. No dummy function, copied helper kind, or source rewrite enters the graph.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles the physical three-source graph byte for byte against stage 0 and executes the artifact.

`nativecompilerhelpersignaturetests` publishes one native case with source identity `3eaa9ea723af0e8dd4ba2509016ad28188cadf6f9d1144e732abeead93d6cd79`, artifact identity `94fae90781f268f435b6f8508464a1d2704eca10068136bc02d0f95620405cd4`, execution identity `0d2d8e763f024a30b147dbafa4fb3e9e9c2e6051f489a5cb517c09b54c4bd445`, and coverage identity `92f0dd90b46732e5ab8a32f5ce6256f38667d060046e57043f3123799ee31df4`.

`wheeler test wheeler-compiler --format json` publishes forty-one selected, forty-one passed, and zero failed cases with report identity `e8a8da0cba5eebfe7575b0fdeffb4b68009839eef92fcb01b027e560caa373f1`.

## Acceptance

- [x] One canonical target carries the complete three-source graph.
- [x] The physical signature source retains all nine public members.
- [x] All 53 imported ABI constants resolve from one owner.
- [x] Helper kind 48 publishes parameter count sixteen.
- [x] The physical graph compiles byte for byte against stage 0.
- [x] The resulting artifact executes exactly once.
- [x] JSON, terminal, and JUnit adapters consume the same forty-one native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,048,407 bytes with SHA-256 `45ac4f9342b093c0d8826fd32bfac11f5c6d1fc78f7178c9550cc75b07603411`. Its root manifest identity is `b4500bc737b4fd4ae8b25a65607230d410e825c2f4c1c352a3f034c928d7f083`.

## Rejected alternatives

### Copy helper kind 48 into a fixture owner

Rejected. The physical ABI declaration edge is part of the evidence.

### Add eight ceremonial assertions

Rejected. A later partition must select meaningful upper-bound behavior for each remaining public query.

### Split the nine-member physical owner

Rejected. The bounded native compiler already retains it byte for byte.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0137](WIP-0137-direct-helper-signature-adoption.md)
- [WIP-0310](WIP-0310-native-multi-helper-entry-programs.md)
- [WIP-0321](WIP-0321-native-compiler-call-kind-suite.md)
- [WIP-0323](WIP-0323-native-compiler-helper-signature-suite.md)
