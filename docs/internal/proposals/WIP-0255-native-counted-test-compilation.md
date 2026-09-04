# WIP-0255: Native counted test compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, native testing, source compilation |
| Depends on | WIP-0248, WIP-0254 |
| Supersedes | One-declaration native test compilation |
| Superseded by | None |
| Follow-up | WIP-0257 native parameter-row compilation |

## Summary

Compile zero-artifact transports containing up to 64 native-discovered parameterless tests.

Every descriptor in one transport must now use the same artifact mode. All artifact lengths are nonzero transported artifacts, or all artifact lengths are zero native source products. Mixed transports reject during complete framing before discovery, identity, sharding, compilation, verification, or execution.

## Selected declaration lowering

The fixed physical compiler admits one entry. For each selected descriptor, `TestSourceTests.w::copyParameterlessEntrySource` lowers its exact declaration to `entry void main()` and blanks every peer test declaration with ASCII spaces.

Blanking preserves the exact byte width of each peer declaration, including nested bodies. The lowering scanner finds the declaration body with balanced brace tokens. It does not leave ordinary helper functions, comment source bytes, or unsupported `test` tokens for the physical compiler.

The selected declaration changes only `test` to `entry` and its discovered name to `main`. The lowered source length remains:

```text
source_length + 5 - selected_name_length
```

Peer blanking does not change that length. Original line boundaries inside blanked declarations are private compiler trivia and do not enter diagnostics or package identity in this bounded profile.

## Exact selection

The lowering operation compares the selected descriptor suffix against exact lexer token bytes. It requires:

- discovered declaration count equals the previously authorized count
- exactly one declaration matches the selected name
- every peer body has a balanced closing brace
- output cursor equals the derived lowered source length

Descriptor order remains canonical unsigned name order. Source declaration order does not select compiler attempts.

## Scheduling

Complete test discovery and parameterless-kind validation precede sharding. For each descriptor assigned to the shard, the runner lowers and compiles that declaration exactly once with fresh recovery storage.

Unselected cases consume no lowered plan, compiler, verifier, metadata, interpreter, or report-row attempt. Their zero artifact fields carry no hidden Java product.

Each selected compiled artifact bypasses transported function and synthetic-entry authorization because the native compiler produced its direct entry from the validated source. It still consumes one verifier and one interpreter attempt.

## Evidence

`compilesMultipleDiscoveredParameterlessTestsNatively` supplies source declaring `beta` before `alpha`, canonical descriptors `test::alpha` then `test::beta`, and zero bytes for both artifacts.

The native runner discovers both declarations, lowers and compiles each selected source independently, executes each artifact once with fresh storage, and publishes two selected and two passed cases. No Java compiler artifact enters the transport.

The imported and seven-import fixtures retain fixed graph compilation. Transported counted tests retain exact function and synthetic-entry authorization.

The runtime archive contains 287,019 bytes with SHA-256 `c25d545d867a4ac5bba01e1f0cdb40f77ddfdc448c81b55342460dd5ea76758e` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,094 bytes with SHA-256 `b866164f0216db3c6b2e0662e0c36510863a4324a0481b4a4831b3890c0d5a3b` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Zero through 64 parameterless descriptors admit native compilation.
- [x] All descriptors use one artifact mode.
- [x] Mixed transported and zero-artifact frames reject before discovery.
- [x] Selected declaration matching uses exact lexer token bytes.
- [x] Peer declarations are blanked through balanced closing braces.
- [x] Peer blanking preserves source width.
- [x] Canonical descriptor order remains independent of declaration order.
- [x] Shard selection precedes every compiler attempt.
- [x] Each selected case compiles, verifies, and executes once.
- [x] Two zero-artifact declarations publish two passing cases.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Compile all tests into one artifact

Rejected for this slice. The fixed compiler has no native test descriptor section or multi-entry test product.

### Keep peer tests as ordinary functions

Rejected. The minimal physical profile does not admit the resulting source closure.

### Comment out peer declarations

Rejected. Raw `*/` bytes inside a body could terminate a synthetic comment.

### Compile unselected shard cases

Rejected. Discovery authorizes the suite, but scheduling owns compiler attempts.

## References

- [WIP-0248](WIP-0248-native-counted-test-discovery.md)
- [WIP-0254](WIP-0254-native-imported-test-compilation.md)
- [WIP-0256](WIP-0256-native-test-lowering-authority.md)
- [WIP-0257](WIP-0257-native-parameter-row-compilation.md)
