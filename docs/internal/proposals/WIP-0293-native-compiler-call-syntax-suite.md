# WIP-0293: Native compiler call syntax suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, compiler testing, imported callables |
| Depends on | WIP-0292 |
| Supersedes | Fourteen-case native compiler package suite |
| Superseded by | Additional native compiler source partitions |

## Summary

Add a third native compiler package-test partition for call syntax and loop layout source.

`nativecompilercallsyntaxtests` compiles three additional production modules and one test root. Every selected declaration invokes the physical `voidCallSourceStatement(long)` classifier so the callable import remains live in every independently lowered artifact.

## Call syntax graph

The target imports:

- `AssignmentCallIdentities.w`.
- `LoopBodyLayouts.w`.
- `VoidCallSourceKinds.w`.

Three independent cases check the seven-argument assignment-call ceiling, the direct loop-body row count, and the zero-argument void-call identity. The first two combine an imported callable assertion with an imported constant assertion. The third checks both properties of `VoidCallSourceKinds.w`.

The callable receives literal 900. Passing an imported constant directly as the imported call argument produced a valid artifact whose runtime value did not satisfy the classifier. The suite does not retain that unproven argument-binding path. It checks the constant separately and keeps the callable evidence exact.

## Evidence

`wheeler test wheeler-compiler --format json` publishes seventeen selected and seventeen passed native cases. The combined report identity is `fdc704da15c83196de59a52286fc0c1f3827cf885a0bd0de68cc558f8619d9aa`.

The call-syntax target has source identity `1f0974036ac05f516a2bea2b01777bf01e4e9808d322766f6af279254a69dc19`. Each of its three rows records two assertions, physical imported-call coverage, and an independent artifact identity.

## Acceptance

- [x] A third canonical compiler test target is checked in.
- [x] Three additional physical compiler modules compile natively.
- [x] Every case executes a physical imported compiler function.
- [x] Every added module owns one checked constant or callable result.
- [x] Seventeen package cases execute exactly once.
- [x] All target rows reduce in package-wide case-identity order.
- [x] All three native adapters render the combined report.
- [x] Compiler archive and consumer locks are rebuilt exactly.
- [x] Focused compiler package, tools, adapters, documentation, workspace, and file-length policy pass.

The compiler archive contains 3,027,665 bytes with SHA-256 `711634ebb81a85c188b925a7b7db92d792f36afc932603d32e9bebf747c0d8ea` and root manifest identity `89ccb652094cf90c13bc8c0f7adda913157523c7da26340b6fa35c9e0d7c809c`.

The runtime archive remains 415,390 bytes with SHA-256 `8d209a6e58ca4c8091f4b12e2f651d8e4825e179c42e17c4c3c77de8523c6b60` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

## Rejected alternatives

### Pass the imported constant directly into the imported classifier

Rejected. The observed result failed. A suite is evidence, not a request to reinterpret a value.

### Leave callable imports unreferenced in constant cases

Rejected. Unreferenced executable dependencies do not prove call graph composition.

### Fold the target into an existing eight-source graph

Rejected. The fixed source boundary is already full in both existing partitions.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0285](WIP-0285-native-compiler-callable-suite.md)
- [WIP-0292](WIP-0292-native-compiler-syntax-suite.md)
