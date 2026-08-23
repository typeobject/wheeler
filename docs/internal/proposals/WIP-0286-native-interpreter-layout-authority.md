# WIP-0286: Native interpreter layout authority

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and self-hosting maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native runtime, interpreter maintenance |
| Depends on | WIP-0285 |
| Supersedes | Interpreter-local layout helpers |
| Superseded by | WIP-0287 native call and branch coverage |

## Summary

Move canonical section, descriptor, frame, parameter-type, ownership-transfer, and instruction-coordinate calculations out of the native execution loop.

`Interpreter.w` had reached 984 lines. Adding branch and call evidence there would have crossed the repository limit and mixed artifact layout with execution policy. `InterpreterLayout.w` now owns those bounded calculations. The execution loop imports one authority and keeps its existing call sites.

## Authority

`InterpreterLayout.w` owns:

- section payload offsets.
- function descriptor offsets.
- call-frame local coordinates.
- transferred parameter-type classification.
- parameter-type table offsets.
- bounded instruction-ordinal resolution.

The module imports canonical opcode bounds, type codes, and binary decoding directly. It does not duplicate numeric limits. All methods remain allocation-free.

`Interpreter.w` owns execution state, control transfer, storage, aggregates, result slots, trace publication, limits, and terminal outcomes. Moving layout helpers changes no public runtime signature.

## Evidence

The compiler package still publishes seven selected and seven passed native cases with report identity `e1e34a0b79920ede1b4b1041bf30a9ea63c99ea4c75c3391c55d9be89ded272f`. This exercises section lookup, entry and imported descriptors, frame locals, callable parameter types, ownership classification, and instruction cursor resolution through the refactored authority.

## Acceptance

- [x] Interpreter layout has one focused module.
- [x] The execution loop contains no duplicate layout helper.
- [x] Public execution signatures and outcomes are unchanged.
- [x] Native imported calls cross the refactored frame boundary.
- [x] `Interpreter.w` remains below 1,000 lines.
- [x] Runtime archive and conformance lock are rebuilt exactly.
- [x] Focused runtime, compiler package, documentation, workspace, and file-length policy pass.

The runtime archive contains 381,466 bytes with SHA-256 `f9cc668e244651b90517725f584e0823582cef4652be3cd6b905aca013ea786d` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The compiler archive remains 3,024,011 bytes with SHA-256 `f368a20b722ed114247166df99f4a482fb099041d5ebfa4858a0c192429da70f` and root manifest identity `9b2cebe76654d6f2cb4d2ec3e3c2762bfc8e72009a796f7e28adf5903428bb99`.

## Rejected alternatives

### Leave the helpers in the execution loop

Rejected. Artifact layout and instruction execution change for different reasons.

### Copy helpers into coverage code

Rejected. Coverage must consume execution evidence rather than reinterpret artifact layout.

### Raise the file-length limit

Rejected. The limit exposes missing module boundaries.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0285](WIP-0285-native-compiler-callable-suite.md)
- [WIP-0287](WIP-0287-native-call-branch-coverage.md)
