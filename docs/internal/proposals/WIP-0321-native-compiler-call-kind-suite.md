# WIP-0321: Native compiler call-kind suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0320 |
| Supersedes | Standalone assignment-call kind evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Compile and execute all four physical assignment-call identity queries through independent native compiler package cases.

`AssignmentCallKinds.w` classifies source and resolved identities, constructs one resolved identity from arity and target, and recovers the target from a resolved identity. The upper-bound cases use source identity 933, resolved identity 41,834, arity seven, and target 42.

## Graph

The target carries five physical sources:

```text
NativeCompilerCallKindTests -> AssignmentCallKinds -> AssignmentCallArities
                                                  -> AssignmentCallColumns
                                                  -> AssignmentCallIdentities
AssignmentCallArities -> AssignmentCallIdentities
AssignmentCallColumns -> AssignmentCallIdentities
```

The graph retains the four-function root owner, the one-function arity owner, the two-function column owner, and one shared constant owner. Shared declaration edges collapse once. Executable owners remain in canonical import order.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that calls all four physical queries. Its five-source artifact matches stage 0 byte for byte and executes successfully.

`nativecompilercallkindtests` publishes four native cases with source identity `cbc58925654201286f576e929677711954beed4b2c44e51a8b241f30f2857af4`. All four share execution identity `2cf192475876f1a8ae6e93caa931ad8039b57e482ed39d80bd4fa534d6b79f91`.

| Case | Artifact identity | Coverage identity |
| --- | --- | --- |
| Source membership | `0d9456a573e727f52c0813fc7507b74a12d2f1b7fe8d2d8ee20ff65312c44495` | `002d323ec874504d324faa54a30a817f39ab478fbd22f219ed77fe62efd546c9` |
| Resolved membership | `1f330f1349c3aab3c008639fab18164827d8ad397ab30ed3cf612fd261034e78` | `28d097c503bf67d92a731ad4e5fef32eae77c496db904c065f51954057410e1f` |
| Resolved identity | `921be001ef644b721fa546400d76de209b4fddd0f40e99b0c5ef8937a0933436` | `53b34f9e2ee8e161b955e510e9f7762cde8b4e10e641e0344aaa046cbb2594b2` |
| Resolved target | `74edc7605cc0529ba97c56497fb68cbd5cec7e214518d0e1908039f274255d24` | `de5987f1add36019ff96daad2cceb5c5c368a677470dabe6e970fa5a9db857d7` |

`wheeler test wheeler-compiler --format json` publishes forty selected, forty passed, and zero failed cases with report identity `27a280b80b80cb704fde11cedaac19d3a5953f60f50a2ceb4e0d973c01bbbadb`.

## Acceptance

- [x] One canonical target carries the complete five-source graph.
- [x] Source and resolved upper-bound identities classify correctly.
- [x] Arity seven and target 42 construct resolved identity 41,834.
- [x] Resolved identity 41,834 recovers target 42.
- [x] Shared constant ownership collapses exactly once.
- [x] The physical graph compiles byte for byte against stage 0.
- [x] The resulting combined artifact executes exactly once.
- [x] Four selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same forty native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,047,421 bytes with SHA-256 `d9bf6e392614321331ad8bb63c9c1b28891f2a1b3a9fced9bd53d2c58d9ea754`. Its root manifest identity is `922beda885aa3356b8f3aa59a7d38529e92c073b23d2ce994e422dbf1006d078`.

## Rejected alternatives

### Test only identity construction

Rejected. Both classifiers and inverse target projection own separate public behavior.

### Duplicate imported constants in executable owners

Rejected. Shared declaration identity belongs to the graph linker.

### Flatten the graph into one fixture source

Rejected. The physical edges are the evidence.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0310](WIP-0310-native-multi-helper-entry-programs.md)
- [WIP-0320](WIP-0320-native-compiler-call-column-suite.md)
