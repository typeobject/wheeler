# WIP-0305: Native compiler call-arity suite

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, runtime, package, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, compiler testing, imported callables |
| Depends on | WIP-0304 |
| Supersedes | Eighteen-case native compiler package suite |
| Superseded by | None |
| Follow-up | Additional native compiler source partitions |

## Summary

Add a fifth native compiler package-test partition for the physical call-assignment arity decoder.

`nativecompilercallaritytests` compiles `AssignmentCallIdentities.w`, `AssignmentCallArities.w`, and one test root. The test executes `assignmentCallArity(long)` over the seven-argument source identity, then checks that physical source identity separately.

The target raises the checked-in suite from eighteen to nineteen production compiler modules and from eighteen to nineteen native cases.

## Source graph

`AssignmentCallArities.w` exports one scalar function and no public constant. Its direct import, `AssignmentCallIdentities.w`, exports the twenty-one bounded source and resolved call-assignment identities.

The package gate admitted by WIP-0304 accepts both modules without dummy declarations. Native module linking resolves the decoder's constant references against the physical identity table. The independently lowered test artifact then executes the imported decoder with decimal literal `933`.

The function checks every source identity and every resolved target column in canonical order. This case reaches the final source branch and returns the production maximum of seven. A separate assertion binds `STATEMENT_ASSIGN_CALL_SEVEN_NAMED` to 933 without passing an imported constant as an imported-call argument.

## Evidence

`testsThePhysicalCompilerSpineNatively` requires nineteen selected and nineteen passed cases and names the call-arity case explicitly. Its native result also reproduces JSON, terminal, and JUnit XML from the same reduced rows.

`wheeler test wheeler-compiler --format json` publishes report identity `267bf85781b3ee2f2c511743fc2b1004e3e8fbe2fac1b22a37857ffd04a05cb0`. The new target has source identity `e7c764fd246c304f804697b4d46724ab8eaf17cf894f5a9a5aecf6828f9dfa7f`, artifact identity `d6fc597d63c73ccb2e05ca91340defa73664bb0211e03a772856d015039200b0`, and two passing assertions.

## Acceptance

- [x] A fifth canonical compiler test target is checked in.
- [x] `AssignmentCallArities.w` enters the native package suite as a physical module.
- [x] Native linking resolves its physical assignment-call identity dependency.
- [x] The imported decoder executes over the seven-argument source identity.
- [x] The physical source identity is checked separately.
- [x] Nineteen package cases execute exactly once.
- [x] The native JSON adapter publishes the exact combined report identity.
- [x] Compiler archive and consumer locks are rebuilt exactly.
- [x] Compiler package, tools, documentation, workspace, and file-length policy pass.

The compiler archive contains 3,029,737 bytes with SHA-256 `d12b17c87c439e6aae7617025d44438ca1a5d242b91e248d5bdf8ce7c33cbfb1` and root manifest identity `bbeb1cd8d20d8e5b95b1533d63ad2c952ce38ec1b2f6c1c33dfacebe5cdd1b06`.

## Rejected alternatives

### Check only the maximum constant

Rejected. The suite needs executable classifier evidence, not another constant row.

### Pass the imported source identity into the imported function

Rejected. A literal call argument and a separate constant assertion retain the WIP-0293 fail-closed boundary.

### Add width functions in the same partition

Rejected. Those functions call the imported arity decoder from another imported function. That nested imported-call graph failed complete native execution evidence and remains outside this slice.

### Merge the target into call syntax

Rejected. The call-syntax target already contains its own bounded source graph. A separate partition keeps source identity, artifact identity, and failure attribution exact.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0293](WIP-0293-native-compiler-call-syntax-suite.md)
- [WIP-0304](WIP-0304-native-compiler-type-kind-suite.md)
