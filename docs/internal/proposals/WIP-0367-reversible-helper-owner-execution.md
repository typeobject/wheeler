# WIP-0367: Reversible helper-owner execution

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, testing, and proof maintainers |
| Created | 2026-08-24 |
| Updated | 2026-08-24 |
| Area | Self-hosting, module graphs, generated inverses, proof names, native coverage |
| Depends on | WIP-0001, WIP-0276, WIP-0310, WIP-0365 |
| Supersedes | Product-only reversible-token coordinate evidence |
| Superseded by | Broader physical compiler package suites |

## Summary

Link and execute a physical reversible scalar-helper owner through the native compiler package suite.

A reversible helper is not an ordinary function with an extra token. Its generated inverse changes the function descriptor and code sections. A signed result uses the result-slot ABI. An attached theorem adds a qualified string and proof certificate. Graph filtering must keep the theorem beside its owner, and native coverage must encode the result-slot transitions produced by execution.

This WIP closes that slice without broadening source, manifest, case, target, or transition bounds.

## Owner graph

```text
NativeCompilerReversibleTokenTests
  -> ReversibleTokenCoordinates
  -> SourceScalars
```

`ReversibleTokenCoordinates.w` remains complete. The graph retains `nextSourceToken`, its generated inverse, and the optional `nextSourceTokenInverse` theorem. The test calls the reversible helper with `SCALAR_DIGIT_ONE` and requires the signed result `50`.

The extra constant owner forces the general graph executor rather than hiding the feature behind the one-dependency path. Focused evidence also checks that the one-dependency linker accepts the same reversible owner.

## Attached proof authority

`HelperProofs.w` owns three lexical facts:

- the exact helper name token,
- whether the declaration carries `rev`, and
- the end of an optional adjacent `theorem ... proves inverse(...)` declaration.

Executable-owner classification, imported-helper validation, and helper-owner filtering consume that authority. A matching theorem travels with its helper through owner filtering and reordering. A wrong subject, malformed terminator, or theorem attached to an ordinary helper rejects before linked source or artifact publication. A reversible helper without a theorem remains valid and still receives its generated inverse.

The fixed package preflight counts `public rev long` declarations against the existing twenty-three-function owner bound. Writing `rev` no longer makes an otherwise admitted signed physical owner fall through to Java package execution.

## Canonical proof strings

An imported proof name belongs to the module that owns its reversible subject. `LibraryStrings.w` therefore adds one proof candidate only when the parsed program carries a proof. It sorts that candidate with the class, helper, and entry strings and qualifies it through the first helper owner's exact module range.

The prior helper-library path reused the root-only proof index. It emitted an out-of-range string ID, and after adding a bare proof string it still lost the module qualifier. Both products failed byte-for-byte comparison. The library plan now publishes the proof index explicitly. The final certificate name is:

```text
wheeler.compiler.closure.reversible_token_coordinates::nextSourceTokenInverse
```

No renderer, linker caller, or test root reconstructs that name.

## Native coverage

The executed helper introduces three opcodes to the admitted classical transition fragment profile:

- `CALL_RESULT_SLOT`,
- `RESULT_FILL_BINARY`, and
- `RETURN_RESULT_SLOT`.

`BootstrapCoverageFragments.w` writes their exact registry names. The native report still compares byte-for-byte with stage 0 and remains under the 255-transition bound. Unsupported opcodes continue to trap before coverage or report publication.

## Evidence

The physical graph compiles to the same complete artifact as stage 0. The comparison covers function names, generated inverse code, result-slot locals, entry calls, qualified proof strings, the proof certificate, and every section byte.

Focused negative cases reject a wrong inverse subject, an attached theorem on an ordinary helper, and a missing theorem terminator. The optional-proof case compiles byte-for-byte and carries no certificate.

The native package case executes once with fresh storage. Its row reports one assertion and the stage-0-matching result-slot coverage identity `e82ca99236a0f912e51fd38d32f7fe60a2fb497906d8718eff67a0406f450e5e`.

The complete compiler package publishes 224 selected, 224 passed, and zero failed cases across 71 native targets. The full suite completes in thirty-five minutes and fifty-four seconds under the unchanged forty-one-minute guard. The canonical workspace contains 177 targets.

The canonical compiler manifest contains 37,898 bytes with identity `e8ef9c50c22e015fa55b2bb7c65fc2146c57d5482538fabc9c9536f66028218b`. The compiler archive contains 3,135,221 bytes with SHA-256 `a3f1d054c1df4ad2adb64c2c7fea8ca1ae96c71995ccac7211d724f5658ee25c`.

The runtime archive contains 438,628 bytes with SHA-256 `266b444d4337159fcb49f5cb7c16d74e5444f0a7dbc2b85b314ddfc738b3e1d5`. Its manifest identity remains `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Acceptance

- [x] Reversible executable owners retain their exact helper count across an attached theorem.
- [x] The one-dependency linker and general graph executor both admit the physical owner.
- [x] Helper filtering keeps a matching theorem with its subject.
- [x] Optional proof absence remains valid.
- [x] A wrong subject, ordinary-helper attachment, or malformed proof fails before publication.
- [x] Helper-library string planning emits the exact qualified proof name and index.
- [x] Native and stage-0 artifacts match byte-for-byte.
- [x] Native coverage matches stage 0 for all three result-slot opcodes.
- [x] The package preflight counts reversible scalar functions against the existing bound.
- [x] The complete compiler package publishes 224 passing rows across 71 targets.
- [x] Compiler, runtime, package, workspace, documentation, archive, and file policy gates pass.

## Rejected alternatives

### Strip the theorem before linking

Rejected. The proof certificate is part of the physical owner's canonical artifact. Removing it would turn graph compilation into dependency-source projection and lose the subject's qualified evidence.

### Leave proof names unqualified

Rejected. Bare proof names collide across modules and disagree with stage 0. Proof and function ownership use the same module authority.

### Exclude result-slot transitions from coverage

Rejected. The package case executed those transitions. A report that omits them would not describe the retained attempt.

### Add a test-only ordinary wrapper

Rejected. An ordinary wrapper would exercise a different function descriptor, call opcode, return ABI, and proof surface. The package must execute the production `rev` owner.

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0020](WIP-0020-semantic-coverage-and-evidence-accounting.md)
- [WIP-0310](WIP-0310-native-multi-helper-entry-programs.md)
- [WIP-0365](WIP-0365-nested-helper-owner-graph-execution.md)
- [WIP-0366](WIP-0366-native-compiler-call-argument-opcodes.md)
