# WIP-0319: Native compiler void-call kind suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0317, WIP-0318 |
| Supersedes | Indirect void-call kind execution evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Compile and execute all three resolved void-call shape queries through independent native compiler package cases.

Other partitions use `VoidCallKinds.w`, but no package case called every public member directly. The new target checks resolved membership, exact arity, and the third source encoded in a three-argument identity. It keeps one physical three-member owner intact.

An attempted root that imported both `VoidCallKinds.w` and its `VoidCallOperands.w` dependent failed graph execution. That redundant-root experiment was reverted. The proven target carries only the direct physical owner and does not weaken graph validation to rescue a fixture.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one physical two-source graph that calls all three members. Its artifact matches stage 0 byte for byte and executes successfully.

`nativecompilervoidcallkindtests` publishes three native cases with source identity `0f9e7ed3afd6a3cf0440f408fb4d627da0cd67b5d11890ee4aa54195e6b84af1`.

The membership case has artifact identity `50752d8aab3a57bab2f04dbc60b02ec439ee5289fa5c45af8a7e468e23b27a7b` and coverage identity `656236e42b7ed1419119b63dcd5937a6468136a5c3aeb8ea00a1f1e706f7c3b1`. The arity case has artifact identity `8f6d2592af6b6a0d2fa513093db4c2e94b1dd584917e7a1ef2d96017664d169c` and coverage identity `d0c67f705053614282694c4c58f395ab30b3f5dc909334c13c2a6ab49292af79`. The encoded-source case has artifact identity `cb2d5a4e5c09d3dbbc6f740b2aae60d887d7566c5ffe9bd9ae793fff8d6f9782` and coverage identity `59304646a40e9742475ea2fd845b6f95dc5e661310cd69ab6c3af17ed6fb1f41`. All three share execution identity `9e4381b563728d2bcb97f073aed4bcc14901a7760571a043f26ee93c7ba8454a`.

`wheeler test wheeler-compiler --format json` publishes thirty-four selected, thirty-four passed, and zero failed cases with report identity `2a7369bf6601b09b3d66f22dabe133188e39e515b6d76aea2d86ffcc9da78951`.

## Acceptance

- [x] One canonical target carries the direct physical owner and test root.
- [x] Resolved seven-argument membership returns true.
- [x] Resolved identity 31,744 returns arity seven.
- [x] Three-argument identity 131,124 returns source 42.
- [x] The physical graph compiles byte for byte against stage 0.
- [x] The resulting combined artifact executes exactly once.
- [x] Three selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same thirty-four native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,044,772 bytes with SHA-256 `9171da0a298c45b006fab541522e53451d397be7602324f92befb894543a47a0`. Its root manifest identity is `f99545aa90a311976a80e5829233f0cf28420fbefa0abca67f54707a5967052e`.

## Rejected alternatives

### Count indirect calls as complete public-surface evidence

Rejected. `voidCallStatement` had no package execution path.

### Keep the redundant root after graph failure

Rejected. A fixture does not get to widen graph authority without complete evidence.

### Split the physical owner by function

Rejected. The three shape queries are a bounded owner already admitted by the compiler.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0317](WIP-0317-native-compiler-void-call-source-form-suite.md)
- [WIP-0318](WIP-0318-native-test-manifest-bound.md)
