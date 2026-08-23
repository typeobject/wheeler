# WIP-0317: Native compiler void-call source-form suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-08-23 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0316 |
| Supersedes | Standalone void-call source-form evidence |
| Superseded by | WIP-0319 native compiler void-call kind suite |

## Summary

Compile and execute all three unresolved void-call form queries through the native compiler package suite.

`VoidCallSourceForms.w` owns membership, identity-to-arity, and arity-to-identity functions. The seven-argument form forces membership past the imported narrow-form classifier and checks both inverse scalar maps at their admitted upper bound.

## Graph

The target carries four physical sources:

```text
NativeCompilerVoidCallSourceFormTests -> VoidCallSourceForms -> VoidCallKinds
                                                           -> VoidCallSourceKinds
```

The linker retains the three form queries as one owner, the imported narrow classifier with its constants as another, and the resolved-call constants and shape queries as a third. The test root sees only the three public form queries.

The test source lives in `src/test/wheeler/compiler/calls`. The parent compiler test directory remains at its ten-file policy limit. New call partitions do not turn that limit into a suggestion.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that executes all three physical queries. Its four-source artifact matches stage 0 byte for byte and executes successfully.

`nativecompilervoidcallsourceformtests` publishes three native cases with source identity `74e25ddd9de5a74402c97e66229df0a38642aaee266d6ab98729c3a3ee5d865e`.

The membership case has artifact identity `8e00ed293a4522b9e174613043a846e220c1182d503494c75eeeb56c90e01705` and coverage identity `af8c1bc3f5ebd893113a1f66e0a9bf233a3a112789050505771d8e5db9e5f2af`. The arity case has artifact identity `da1123adc3c77c46bdfd11eb0b7eab6a8cb13afd495d3885b10b5dab5bce9848` and coverage identity `99f242c10c00c6e50f729d50efc9f45cde0193f8fed6d4841876fac7dcbdff4f`. The kind case has artifact identity `abe3e63f3a90942d18dc6df773d96f91c4d64556e55350dd8d8c119beb4a7774` and coverage identity `5c83ac76c324b8d1cc96df00afe60e5371bb5fee4e1597b35748aa3b23a948bd`. All three share execution identity `584f1a8296940f6c9f14b62fdbe63907302578c5909a16afb13ec853c63647a6`.

`wheeler test wheeler-compiler --format json` publishes thirty-one selected, thirty-one passed, and zero failed cases with report identity `a6bcbf89d4847bcb665456886fc8bb8e1fd6c3c5f1531bcfecbc2776eec4b142`.

## Acceptance

- [x] One canonical target carries the complete four-source graph.
- [x] Seven-argument source membership executes the imported narrow classifier.
- [x] Source identity 925 maps to arity seven.
- [x] Arity seven maps to source identity 925.
- [x] The physical graph compiles byte for byte against stage 0.
- [x] The resulting combined artifact executes exactly once.
- [x] Three selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same thirty-one native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,043,623 bytes with SHA-256 `ed0536681da951cc7c4eebdb4126746317cfca2dfb681f7291af92db46f29dae`. Its root manifest identity is `7080a44437271e34412699d5a9edda4e5fbf219e9d5a986d44772ac459f4d7e0`.

## Rejected alternatives

### Test one convenient direction

Rejected. Membership and both scalar maps are separate public contracts.

### Copy the narrow classifier

Rejected. The imported function edge is part of the physical graph.

### Add an eleventh file to the parent test directory

Rejected. Bounded directory shape keeps source ownership visible.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0293](WIP-0293-native-compiler-call-syntax-suite.md)
- [WIP-0316](WIP-0316-native-compiler-void-call-source-width-suite.md)
- [WIP-0319](WIP-0319-native-compiler-void-call-kind-suite.md)
