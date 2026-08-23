# WIP-0336: Native compiler resolved local-loop form suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0335 |
| Supersedes | Product-only resolved local-loop form evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Execute every public decoder in `ResolvedLocalLoopForms.w` through an independent native compiler package case.

The suite retains `LoopKinds.w` as physical input. It covers condition-source, limit-source, reversal, direction, and update bits without copying the form constants into test source.

## Graph

```text
NativeCompilerResolvedLocalLoopFormTests
  -> ResolvedLocalLoopForms
       -> LoopKinds
```

The selected forms isolate the named condition bit, named limit pair, reversal bit, and combined low update bits under a reversed condition.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that calls all four physical functions. The native artifact matches stage 0 byte for byte and executes successfully.

`nativecompilerresolvedlocalloopformtests` has source identity `317f9a1b56ca202b5580d1f5847b610ce8ac8564dc598ebcbc5e37a597ebd9a2` and execution identity `b2c2722cdbe96098e4b4288b8492d04bf614e9f5d31d98db0f022f13ead7460a`.

| Query | Artifact identity | Coverage identity |
| --- | --- | --- |
| Condition bit | `39eadf2dce124e67f24b07a073e551b8638b2362a014026d4c18c56d202108b1` | `07e2100fcb79a946dd83770419cf4667bbb7b868909b4779ed093bf81e2f0aa8` |
| Limit pair | `c634043488cf07f4071c219ff6f026f0868ee3636cb1543c4246051af9e4a47c` | `70c866a6b8f8a2230227836eb25244d44ad022eb8e11a279a30d8f4bc4694d3a` |
| Reversal | `03845108c7d0d8e086a5cd0bdc8aa360431243f7a089f00491c4b3f2d260da02` | `98e2a23d7f167896c2c0824eea6464daf268d90614228240ef1b54684f69950f` |
| Update bits | `fff227e5d39ed06521a326f91b40e7568aae4032931b0166e122b9750ada237e` | `66ef5d5303ea9a472e823b84c5775c790d86ea23e028701be88847465a03c9ed` |

`wheeler test wheeler-compiler --format json` publishes eighty-nine selected, eighty-nine passed, and zero failed cases with report identity `3db93cb3377df426ad5f1938ce75d0c8b236624d9afecfe87829884ef17ca5bc`. The canonical workspace checks 132 targets.

## Acceptance

- [x] Every public local-loop form decoder has an independent native case.
- [x] The physical loop-kind constants remain imported input.
- [x] Named condition and limit forms execute.
- [x] Reversed and combined update forms execute.
- [x] One combined artifact matches stage 0 byte for byte.
- [x] The combined artifact executes exactly once.
- [x] Four selected cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same eighty-nine rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete package run finished in six minutes and five seconds under its seven-minute host guard.

The compiler manifest contains 14,889 bytes. The compiler archive contains 3,064,705 bytes with SHA-256 `f9451d171b151db59d5ef10fe8a576185ddf7aece91db8f7a929b8a0248e4a10`. Its root manifest identity is `fd4115bc2c0a4fbd5b524e95b1d3968aa518f23cf8f3859fb0a86ff8e90e9c80`.

## Rejected alternatives

### Duplicate the six form constants

Rejected. Physical imports preserve module and archive authority.

### Infer update bits from reversal evidence

Rejected. Modulo decoding and threshold classification are separate public functions.

### Keep only one combined package case

Rejected. Each public query retains an independent artifact and coverage identity.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0335](WIP-0335-native-compiler-resolved-local-operation-suites.md)
