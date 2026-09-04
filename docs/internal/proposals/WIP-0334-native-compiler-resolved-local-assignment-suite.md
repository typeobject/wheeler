# WIP-0334: Native compiler resolved local-assignment suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0333 |
| Supersedes | Product-only resolved local-assignment evidence |
| Superseded by | None |
| Follow-up | WIP-0335 native compiler resolved local-operation suites |

## Summary

Execute every public query in `ResolvedLocalAssignments.w` through an independent native compiler package case.

The four cases cover complete assignment membership, prior-local source classification, Boolean value classification, and target decoding. `ResolvedStatements.w` remains complete physical input.

## Graph

```text
NativeCompilerResolvedLocalAssignmentTests
  -> ResolvedLocalAssignments
       -> ResolvedStatements
```

Boundary values select the last assignment opcode, the first signed prior-local column, the first Boolean literal column, and the first Boolean prior-local target.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that calls all four physical functions. The native artifact matches stage 0 byte for byte and executes successfully.

`nativecompilerresolvedlocalassignmenttests` publishes four cases with source identity `490d3d56a2f92493819e0eb653a5e4417d1ffdc8786907f9fa364fa80421ffa3` and execution identity `24757deac725e6d96c3ea2db1d4ab4aef91ff1d93d7c2a218b8b1580f6788b87`.

| Query | Artifact identity | Coverage identity |
| --- | --- | --- |
| Assignment membership | `41770fc4ad5424ce4ae83c998a4f52c25647e78b38f22b854f0c546b9476c651` | `d99bf6424b7cd1db9441af329ec639b4fe0bbcbbc89af26b65f7e532340b52a3` |
| Prior-local membership | `72ca15cc3c318ac0d6f969a7222e11413cd818c3cb384f77292db9bc007059c2` | `8d0996084f4ae0c3ae8f781e912da2254747a8be5e7d4ed01f0c9c4ee25aa7f4` |
| Boolean membership | `d6664d5eaa0ff6758f454a4154ca32a6f816a338c0b94e5b371b8bc6d1447d31` | `b832e6feea4e470d0c8913d42479e36be389e8bb85e0bcf4ba3406b130b47d30` |
| Target decoder | `ce49401502e6c23ea24efce30f0d6cf1700186209338af97f309792ea928af27` | `e3819a2b8daff7ae685350d34d98f3d24d03ccbc58230d2dc227885374931578` |

`wheeler test wheeler-compiler --format json` publishes seventy-seven selected, seventy-seven passed, and zero failed cases with report identity `a7f36883d051c14a7747be4d180993531a7fae99275b3cdf05abb854ae0e515a`. The canonical workspace checks 129 targets.

## Acceptance

- [x] Every public resolved local-assignment query has an independent native case.
- [x] The complete statement-opcode owner remains physical input.
- [x] All four assignment columns contribute boundary evidence.
- [x] Target decoding reaches the Boolean prior-local column.
- [x] One combined physical artifact matches stage 0 byte for byte.
- [x] The combined artifact executes exactly once.
- [x] Four selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same seventy-seven rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The complete integration run now has a six-minute host timeout. A proven run completed in five minutes and three seconds. The guard bounds host scheduling, not Wheeler steps or history.

The compiler manifest contains 13,456 bytes. The compiler archive contains 3,060,483 bytes with SHA-256 `78c5cf8756964dfc86ced18a83ebab6ef94bf6c3a69b1916b24d24e45dd544b3`. Its root manifest identity is `08d5347743f1f59f4a282181e57bb74e4e0db152b00c85201d12e13db85df3cf`.

## Rejected alternatives

### Cover only aggregate membership

Rejected. Named-source and Boolean classifiers drive separate lowering decisions, while the target decoder owns all four packed columns.

### Copy statement bases into the test source

Rejected. The suite must retain the physical opcode owner and its archive provenance.

### Remove the host timeout

Rejected. The complete package run remains bounded. Native artifacts retain their own semantic step and history limits.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0333](WIP-0333-native-compiler-resolved-local-inequality-suite.md)
- [WIP-0335](WIP-0335-native-compiler-resolved-local-operation-suites.md)
