# WIP-0323: Native compiler helper-signature suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-08-23 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler package tests |
| Depends on | WIP-0322 |
| Supersedes | Partial native helper-signature package coverage |
| Superseded by | None |
| Follow-up | WIP-0324 native compiler wide-return source suite |

## Summary

Execute every public query in the physical helper-signature owner through an independent native compiler package case.

The suite checks parameter count, signed kind, Boolean kind, UTF-8 kind, reversible classification, result-slot classification, UTF-8 result classification, Boolean result classification, and Boolean-parameter classification. Upper-bound scalar forms use sixteen parameters. UTF-8 uses its ten-parameter form. Reversible and result classifiers use their final admitted variants.

## Graph

All nine cases retain the same three physical sources:

```text
NativeCompilerHelperSignatureTests -> HelperSignatures -> HelperAbi
```

Independent lowering leaves one selected test in each root artifact. The complete nine-member production owner and its 53-constant ABI dependency remain byte-identical across those artifacts.

## Evidence

`NativeCompilerNestedHelperEntryExampleTest` compiles one entry that calls all nine physical members. The artifact matches stage 0 byte for byte and executes successfully.

`nativecompilerhelpersignaturetests` publishes nine native cases with source identity `2f07cfcbc93553068780e64f526565a8bce75bfbb33fc920b4236334e0d65e3f` and execution identity `0d2d8e763f024a30b147dbafa4fb3e9e9c2e6051f489a5cb517c09b54c4bd445`.

| Query | Artifact identity | Coverage identity |
| --- | --- | --- |
| Parameter count | `94fae90781f268f435b6f8508464a1d2704eca10068136bc02d0f95620405cd4` | `92f0dd90b46732e5ab8a32f5ce6256f38667d060046e57043f3123799ee31df4` |
| Signed kind | `0088eccbcfada3cf11570b49629daf41b0aced2ceeaebceb6a3a0e6797607c30` | `1a6d0bb0ebefc0abf4a071d28ed714b2ed522c14571cebefc2a6d09da6509587` |
| Boolean kind | `65501071ee88923feeb9bfb246ace17fb371d893f1169c0b5764eaed01d24687` | `5f369d36081fa5933b303f31cce752c06bba001327ea6d7c014d1d74d819604a` |
| UTF-8 kind | `cd7a7bdd6d2ea3429d6b8b9a604a457eba725aaf3070b3e4c8b378bab398d154` | `a82cb78fbf33f0f0b52c39f3c68203bda51f2613fb84c22961eaefed1b319717` |
| Reversible | `abb75d66da080e4c2d4ec78ce1ac123d48fd43f0ad623e85843b300350bfcd86` | `75074123ded77c861acb052448b0e70ec3c9334a81228dd1fd65e2e1823c4791` |
| Result slot | `584fe2fb34ff4bd09d8eb6618cdbee597b28e45aefa744f3883650342194cafb` | `e658bad7d9eacbaf7b7ea4b137327fae4a78f265e45b553a3a5360381c6e5bee` |
| UTF-8 result | `d9ae9d80743ae67a4e3e68b5e814c799de01abb1a9ed10101a81567aa14aea1d` | `4df076a0f3117ae8b49a8ac5a4c2937bbd92358b46180b36f62038532a869205` |
| Boolean result | `db4000f8bb3372a9d7144cc8e6273df79bee64dda2756b85fc85060884d47e70` | `976d2cf3cd183c42436ef6ceb7606c5d71ffe6a817d3acea627a49a91b8d2028` |
| Boolean parameter | `e06139dd455f4df7ba5f9f0e84b0b171cb586eb742b9c38ab2e1aafedad30388` | `2221a916acd68133decaeef34bb4af5680397295f76789171b0251fad1734abe` |

`wheeler test wheeler-compiler --format json` publishes forty-nine selected, forty-nine passed, and zero failed cases with report identity `76b41027c66ef42bfd1eb48cab673d04eb3632e6a338e638058d2cc6a6386ee4`.

## Acceptance

- [x] Every public helper-signature query has an independent native case.
- [x] Scalar parameter and kind maps reach sixteen.
- [x] The UTF-8 kind map reaches ten.
- [x] Reversible, result-slot, result-kind, and parameter-kind classifiers execute.
- [x] One combined physical artifact matches stage 0 byte for byte.
- [x] The combined artifact executes exactly once.
- [x] Nine selected native cases compile and execute independently.
- [x] JSON, terminal, and JUnit adapters consume the same forty-nine native rows.
- [x] Compiler, package, workspace, documentation, and file policy gates pass.

The compiler archive contains 3,049,337 bytes with SHA-256 `f979d9f70fbc6d6c7c88d08b141b88fd7837873105c85babd4efa6962ddb9ab9`. Its root manifest identity remains `b4500bc737b4fd4ae8b25a65607230d410e825c2f4c1c352a3f034c928d7f083`.

## Rejected alternatives

### Infer classifiers from helper kind arithmetic

Rejected. The physical functions own the accepted sets and exceptions.

### Combine all checks into one package artifact

Rejected. Independent cases retain exact coverage identities for each public query.

### Duplicate the ABI constants

Rejected. The imported declaration owner is canonical input.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0137](WIP-0137-direct-helper-signature-adoption.md)
- [WIP-0322](WIP-0322-native-compiler-helper-parameter-suite.md)
- [WIP-0324](WIP-0324-native-compiler-wide-return-source-suite.md)
