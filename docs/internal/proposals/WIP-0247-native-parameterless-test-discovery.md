# WIP-0247: Native parameterless test discovery

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, coverage, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, native testing, source discovery |
| Depends on | WIP-0205, WIP-0225, WIP-0231, WIP-0246 |
| Supersedes | Caller-provided names for one transported root test |
| Superseded by | None |
| Follow-up | WIP-0248 native counted test discovery |

## Summary

Discover one parameterless `test void` declaration from the validated root source and bind its descriptor name before execution.

`TestSourceTests.w` copies the manifest-selected root from the validated source plan, invokes the canonical Wheeler lexer, recognizes test declarations from semantic tokens, and requires the exact case name:

```text
<target-name>::<declaration-name>
```

The initial source-declared profile accepts exactly one parameterless declaration. Multiple declarations and parameterized declarations reject before case identity, shard assignment, artifact verification, execution, or publication. Sources without test declarations retain transported entry-artifact behavior, and zero-artifact source mode retains WIP-0246 `<target>::entry` derivation.

## Lexer authority

Discovery imports `wheeler.lexer.scanner`, compiler token limits, keyword tokens, source scalar constants, and token helpers. It does not search raw text for `test`, inspect comments, or trust Java parser output.

The scanner writes at most 4,096 semantic tokens into three bounded word columns. Discovery recognizes `test`, `void`, a name token, `(`, and `)`. It counts every `test void` candidate. Only an immediate close parenthesis enters the accepted parameterless profile.

Discovery copies the declaration name as exact UTF-8 scalar bytes from the scanner range. It compares target and descriptor bytes without normalization. General descriptor validation still owns the display-name alphabet and length ceiling.

## Ordering and completeness

The initial profile requires `discovery.count == 1` and `caseCount == 1`. A discovered declaration must match the first and only complete descriptor. An empty descriptor set cannot hide a declaration, and an unsupported parameter row cannot fall back to caller naming.

The runtime performs complete descriptor framing, source-plan validation, manifest selection, root selection, and lock-root validation before discovery. Discovery precedes source identity, case identity, shard assignment, artifact verification, and execution.

## Coverage closure

A stage-0 test artifact contains a synthetic entry with `CALL_VOID`, a test body ending in `RETURN`, and the ordinary `HALT`, `LOCAL_CONST`, and `EXPECT_TRUE` instructions.

`BootstrapCoverageFragments.w` previously named only the three direct-entry opcodes. That made a valid discovered test trap during report composition. The bounded coverage encoder now names `CALL`, `CALL_VOID`, and `RETURN` with their canonical opcode text. Existing direct-entry coverage bytes remain unchanged because no old trace contains those opcodes.

## Evidence

`discoversOneParameterlessRootTestNatively` compiles one source-declared test artifact independently with stage 0. The native runner scans the exact source plan, accepts `test::passes`, executes the artifact, and publishes a passing one-case summary.

The same test submits the identical artifact and source plan as `test::other`. The name remains generally valid but does not match discovery. The runtime traps and leaves all 39 output bytes zero.

The one-through-eight-source entry parity suite and both source-mode rejection fixtures remain green in the same combined compiler/runtime closure.

The runtime archive contains 258,206 bytes with SHA-256 `894a838b004dff774495e1bd5fa644a2d70a65297ca2facd609afd345c71058f` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1` and root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`. Its lock names the new runtime archive exactly.

## Acceptance

- [x] Discovery uses the canonical Wheeler semantic lexer.
- [x] Comments and string bytes cannot create declarations.
- [x] Exactly one parameterless root declaration is accepted.
- [x] Descriptor name is target plus exact declaration name.
- [x] Missing, duplicate, parameterized, or mismatched declarations reject closed.
- [x] Discovery follows manifest root selection rather than path position.
- [x] Discovery precedes identity, shard, verification, execution, and publication.
- [x] Native coverage names `CALL`, `CALL_VOID`, and `RETURN`.
- [x] A discovered passing artifact publishes a passing canonical summary.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Search source text for `test void`

Rejected. Comments, strings, and malformed tokens would become discovery authority.

### Accept the caller name after finding any test

Rejected. Discovery must bind the exact declaration to case identity.

### Ignore unsupported parameter rows

Rejected. Silent fallback would let Java retain discovery authority.

### Skip coverage for synthetic test entries

Rejected. Execution and coverage identities must describe the same attempt.

## References

- [WIP-0205](WIP-0205-native-test-coverage-identity.md)
- [WIP-0225](WIP-0225-native-case-discovery-order.md)
- [WIP-0231](WIP-0231-native-source-module-declarations.md)
- [WIP-0246](WIP-0246-native-entry-case-identity.md)
- [WIP-0248](WIP-0248-native-counted-test-discovery.md)
