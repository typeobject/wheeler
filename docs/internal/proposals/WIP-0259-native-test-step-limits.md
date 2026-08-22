# WIP-0259: Native test step limits

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, native testing, bounded execution |
| Depends on | WIP-0258 |
| Supersedes | Rejection of canonical `limits(...)` metadata |
| Superseded by | Native test tag selection |

## Summary

Parse and enforce canonical source test limits in the native runner.

Native discovery accepts either an immediate body brace or this exact suffix:

```wheeler
limits(steps = 100, history = 90) {
```

Both values must be canonical positive integers no greater than 4,000,000. Field order, punctuation, and body placement are fixed. Unknown metadata and `tags(...)` still reject closed.

The source step limit now reaches the interpreter for transported and native-compiled artifacts. Exhausting the limit produces the existing stable execution-failure row. It is report data, not a runner trap.

## Bound composition

The physical interpreter retains its 512-transition ceiling. The effective test limit is:

```text
min(declared steps, 512)
```

An omitted limit uses 512. A declared limit above 512 remains valid but cannot enlarge the physical runtime profile.

`executeVerifiedArtifact` receives the effective positive bound and retains the 512-transition static loop limit. Generic conformance operations pass 512. Test reports pass the source-derived value through `ArtifactExecution`.

The native interpreter retains no rewind history while executing test artifacts. Its live history consumption is therefore zero. Discovery still validates `history` against the source language's positive 4,000,000-entry range. No host VM history setting enters native report semantics.

## Discovery

`TestSourceTests.w` parses limits after either a parameterless declaration header or canonical scalar `cases(...)` rows. It publishes one effective step limit by descriptor ordinal beside case kind and scalar value.

Complete discovery validates every declaration before sharding. The descriptor loop reads the selected ordinal only after shard assignment. The limit therefore causes no compiler, verifier, or interpreter work for an unselected case.

Malformed limits reject before source identity, compilation, artifact authorization, or publication. Limits attach to source declarations and apply equally to nonempty transported artifacts. Java cannot bypass a low source limit by supplying precompiled bytes.

## Lowering

Both parameterless and parameter-row lowering remove the complete declaration header through its opening body brace. The generated direct entry begins with exact canonical text, and original body bytes resume after the brace.

`parameterlessEntrySourceLength` now derives the selected header width from canonical lexer tokens rather than assuming that `)` and `{` are adjacent. Peer declarations remain blanked at exact original width.

## Evidence

`enforcesNativeSourceStepLimits` runs the same one-step declaration through both artifact modes. Native discovery accepts the limit, the native compiler or transported artifact reaches the bounded interpreter, and each attempt publishes one selected and zero passed cases.

`enforcesNativeParameterRowStepLimits` attaches a one-step limit to two Boolean rows while three long rows retain the default. The canonical report publishes five selected and three passed cases.

`rejectsInvalidNativeSourceLimits` supplies zero steps. Discovery traps with all 39 output bytes untouched. `rejectsUnsupportedNativeTestTags` preserves the closed tag boundary.

The runtime archive contains 306,211 bytes with SHA-256 `3f61ee9ef8de6ceabe2664e643ef794dfcc6755bab626b8ba40388450f7336a8` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive contains 131,221 bytes with SHA-256 `c8225a24f2dc0c2d9cffe708b25e1fa662ba6a771d1a85fbc63d188c0ffc7ea5` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Parameterless and scalar-row declarations accept exact `limits(...)` syntax.
- [x] Step and history values require canonical positive bounded integers.
- [x] Omitted limits retain the physical 512-transition bound.
- [x] Declared steps compose with the physical bound by minimum.
- [x] Transported and native-compiled artifacts use the same source limit.
- [x] Limit exhaustion publishes a stable failed case row.
- [x] Complete validation precedes sharding and execution.
- [x] Invalid limits leave output untouched.
- [x] Parameterless lowering removes accepted metadata exactly.
- [x] Parameter-row lowering removes accepted metadata exactly.
- [x] Runtime and conformance archives and dependent locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Pass the declared value directly to the interpreter

Rejected. Source metadata cannot expand the fixed physical profile.

### Enforce limits only for native-compiled artifacts

Rejected. Source authorization binds transported artifacts too.

### Stop after execution and compare transition counts

Rejected. An over-limit transition must never execute.

### Treat exhaustion as a runner trap

Rejected. Bounded test failure belongs in the canonical report.

### Map host VM rewind history into test limits

Rejected. Host execution machinery is not native test semantics.

## References

- [WIP-0258](WIP-0258-native-bare-test-metadata-profile.md)
- [WIP-0206](WIP-0206-complete-native-artifact-outcomes.md)
