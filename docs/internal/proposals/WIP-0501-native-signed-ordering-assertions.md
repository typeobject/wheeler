# WIP-0501: Native signed ordering assertions

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and conformance maintainers |
| Created | 2026-09-07 |
| Updated | 2026-09-07 |
| Area | Native source resolution and scalar assertion lowering |
| Depends on | WIP-0013, WIP-0017, WIP-0021 |
| Supersedes | None |
| Superseded by | None |

## Boundary

[WIP-0021](WIP-0021-uniform-call-and-assertion-syntax.md) defines an assertion as one
Boolean expression evaluated once. The old recovery path required a prior local
on the left and a prior local or named constant on the right. It rejected
`assert(observed < 0)` even with an admitted signed state slot. Signed literal
decoding did not repair that resolution gap.

This stage lowers a direct signed less-than assertion over literals, scalar
constants, prior signed locals or parameters, and the existing class-state slot.
Each operand retains its own origin. It does not add another assertion spelling,
a state-only textual substitution, or an implicit temporary declaration in the
source.

Other comparisons, Boolean composition, arbitrary arithmetic operands, and call
arguments remain separate lowering work. Direct global literal-call arguments
remain outside this record. None of these exclusions changes the source language
or establishes full native compilation.

## Change

The syntax owner locates both scalar operand extents and the exact closing
punctuation. Signed magnitudes use the shared decoder, including both endpoints.
Syntax location does not choose a binding or evaluate a constant.

Resolution gives each operand a kind and a full signed word. A literal or folded
constant carries its value. A prior local carries its frame index. State carries
its admitted global index. Invalidity has a separate tag, not a value sentinel.
Exact lexical presence takes precedence over type filtering. A wrong-type or
ambiguous local cannot fall through to a constant or global of the same name.
Boolean literals and `new` retain their expression meaning even when an admitted
declaration uses that spelling. This is value admission, not an identifier ban.

Prior-declaration markers distinguish Boolean parameters from other parameters.
They do not prove that an untagged parameter is signed. Helper admission checks
both operand coordinates against the retained sixteen-slot type column before
emission. It neither guesses types from names nor waits for artifact verification.

The existing two statement operand columns retain those words. Nine internal
identities describe the ordered pair of literal, local, or global origins. This
replaces the two local-index-encoded less-than assertion ranges. There is no
parallel legacy resolver or encoder and no new per-statement allocation.

Encoding evaluates the left operand, then the right, into two signed locals.
`LOCAL_LT` writes one Boolean local and `EXPECT_TRUE` checks it. Literal values
use `LOCAL_CONST`, locals use `LOCAL_MOVE`, and state uses `LOCAL_LOAD_GLOBAL`.
Frames, instruction counts, byte widths, helper admission, and operand consumers
use the same resolved pair. The encoder checks both operand domains, prior-local
precedence over its temporaries, three available frame slots, and all 96 output
bytes before writing. A false assertion compiles normally and traps during
execution before any following mutation.

The existing source, token, statement, frame, helper, global, evaluator, and
publication limits remain independent. Direct global literal equality retains
its compact `EXPECT_EQ` encoding. Compiler rejection leaves caller artifact bytes
and publication unchanged.

## Evidence

`NativeCompilerSignedOrderingExampleTest` preserves the exact original minimum
source and its minus-one control. It compares complete artifacts for all nine
origin pairs, all nine false pairs, both endpoints, radices, forward constants,
parameters, and vocabulary names. False assertions trap before the following
state mutation. Accepted and trapped executions rewind completely.

Compiler checks retain zero artifact bytes and unchanged publication fields on
malformed syntax, wrong types, unresolved names, and overflow. Small accepted,
wrong-right-operand, and short-artifact runs also rewind the compiler. A retained
counterexample caught a constant named `true` impersonating a signed operand.
A second caught UTF-8 parameter comparison reaching the writer and leaving
artifact bytes behind. Exact parameter-type admission now rejects all six loan
forms on either side before writing. Unused loan signatures remain admitted.
Signed, Boolean, and void helper bodies retain ordering assertions.

The syntax and binding fixtures preserve every scanner column. They distinguish
counted short backing from implicit 4,096-row columns. The full-window fixture
checks count 4,097 against spare backing without widening the scanner. It runs
without history. Wrong-type and ambiguous locals cannot bypass lexical presence.

The encoder compares all four instructions with independent stage-0 output at a
nonzero cursor. It checks untouched sentinels, allocation-free emission, local
255, first excess, temporary overlap, invalid origins, and complete rewind.
Source integrations retain 64 statements, 23 helpers, and 16 signature parameters,
then reject each first excess. The signature test does not widen call arguments.

The complete seven-function `SignedOrderingKinds.w` library matches stage 0.
Its helpers use checked bounded offsets and explicit intermediate values. This
does not repair general conditional arithmetic-return lowering.

One digest-bound archive pass compares the complete ordering classifier and both
Boolean assertion owners with independent libraries. Archive admission also
checks all 451 compiler modules and their declaration products. Neither result
compiles the complete syntax, value-resolution, or encoding owner natively.
Their focused fixtures execute stage-0-produced Wheeler code and compare the
emitted programs separately.

The renamed package target passes all three native cases. It uses admitted named
call arguments and separate Boolean-local negation. It does not widen Boolean
assertion syntax. The seven spine cases pass too. Their case and source identities
match the complete canonical manifest, not a substituted one-target manifest.
The complete 255-case package still requires same-commit hosted acceptance.

The original minimum source also passes through the locked compiler and coverage
consumer. All 568 artifact bytes and 772 coverage bytes match the independent
oracle, with seven tested transitions and `observed = 7`. Restoring wrong-type
fallback, skipping parameter types, or loading state as a local fails the retained
fixtures. Raw workspace manifests now match the bytes bound by their locks.

## Acceptance

- [x] One syntax owner locates both operands and rejects malformed tails.
- [x] Kind-tagged resolution preserves all signed values and name precedence.
- [x] The two old local-index less-than ranges and their copied dispatch are gone.
- [x] Widths, frames, helper admission, and encoding consume the resolved pair.
- [x] Complete artifacts, execution, traps, publication, and rewind pass.
- [x] Independent resource boundaries and first-excess cases pass.
- [x] Restored binding or load-opcode defects fail the retained counterexamples.
- [ ] Physical scope, locked consumers, package identities, and current docs agree.

## Remaining work

This is a recovery-compiler lowering stage. It does not complete general Boolean
expressions, nominal test execution, compiler closure, stage equality, recovery,
or Java-free operation. Those gates remain on the [roadmap](roadmap.md).
