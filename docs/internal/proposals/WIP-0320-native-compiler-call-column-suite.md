# WIP-0320: Native compiler call-column suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0319 |
| Supersedes | Standalone assignment-call column evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Compile and execute both physical assignment-call identity maps through the native compiler package suite.

`AssignmentCallColumns.w` maps source arity to unresolved identity and resolved arity to target-column base. The two independent cases select the seven-argument upper bound and require source identity 933 and resolved base 41,792.

## Graph

The target carries three physical sources:

```text
NativeCompilerCallColumnTests -> AssignmentCallColumns -> AssignmentCallIdentities
```

The linker retains both map functions as one owner and resolves all imported constants from one separate declaration owner. Each selected test lowers independently and calls one map.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that calls both physical maps. Its artifact matches stage 0 byte for byte and executes successfully.

`nativecompilercallcolumntests` publishes two native cases with source identity `65368c789d91eafe66095e8ff7e87bdf3e1134239514edabbbeae474bb6dd7d7`.

The source-kind case has artifact identity `9111f4dc24dfa959accc9db630d6a4412e8ef5c90f64eac4b15d8810b0d78566`, execution identity `fac3b23a94f4e93b41548d16acdccbad46a9101dcf603f61d048c3e8d4270afd`, and coverage identity `2fdabfc7f59492e745e7dd8063832920ef0f493d0c9774b7a15c695e774f113d`.

The resolved-base case has artifact identity `26b618a1d7ce7846d9b596d4f2bc21c9ad8fdcccd362643760fd7eb7b049ca81`, the same execution identity, and coverage identity `332fdebb5d36e984465cb9de7f95c37d267bfb96cd79fdb1b1415c66cf89c29a`.

`wheeler test wheeler-compiler --format json` publishes thirty-six selected, thirty-six passed, and zero failed cases with report identity `a82a2f8af5bb5e358e649468d18698bc4d46a7c580d392bff398c40b643f1c7b`.

## Acceptance

- [x] One canonical target carries the complete three-source graph.
- [x] Arity seven maps to source identity 933.
- [x] Arity seven maps to resolved base 41,792.
- [x] Both physical functions retain one owner.
- [x] The physical graph compiles byte for byte against stage 0.
- [x] The resulting combined artifact executes exactly once.
- [x] Two selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same thirty-six native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,045,864 bytes with SHA-256 `c6f9c61871da6611ceb70d08cef6576224aacb0a04b0e65a9d167ec4d11fbb04`. Its root manifest identity is `bf4e66e9ce2ee527797e85a245ffad665d703f471b839648e7c61fa3002fc0ca`.

## Rejected alternatives

### Derive one map from the other in the test

Rejected. Source identities and resolved column bases are distinct compiler contracts.

### Copy imported constants into the test

Rejected. The physical declaration edge belongs in the compiled graph.

### Merge the selected cases

Rejected. Independent artifacts retain exact function and coverage evidence.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0311](WIP-0311-native-compiler-call-width-suite.md)
- [WIP-0319](WIP-0319-native-compiler-void-call-kind-suite.md)
