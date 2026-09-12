# WIP-0510: Root scalar assertion products

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler, runtime, and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, scalar predicates, global reads |
| Depends on | WIP-0049, WIP-0507, WIP-0509 |
| Supersedes | None |
| Superseded by | None |

## Boundary

[WIP-0509](WIP-0509-root-scalar-global-locations.md) supplies declared scalar
locations. This task joins them to root assertions. It does not close the wider
[WIP-0507](WIP-0507-native-source-global-access-products.md) access contract.
Helper-result stores, global conditions, nested accesses, full scope precedence,
entry and nominal composition, and source-independent instruction relocation
remain required joins.

The first three archive cases compare a global with a parameter, another global,
or a signed literal. Two store before comparing. Stage 0 accepts the intact
sources. Native compilation originally rejected their value plan before direct
instruction emission. Assertion width planning tried to bind the predicate
through local-only `resolveLoopAssertion`.

## Shape before binding

`SourceReversibleResultRelations.w` owns the shared scalar syntax. Its relation
carries an explicit terminating token. Callers select a semicolon or a closing
parenthesis. The assertion front checks the keyword, both parentheses, and final
semicolon before binding any operand. Equality requires adjacent `=` bytes.

The profile covers one Boolean scalar or
one binary relation with supported scalar operands. It does not add nested
expressions, call operands, nominal projections, or general constant-expression
predicates.

A left signed literal retains its position rather than reversing the comparison
or swapping the emitted loads. This join admits literal-left assertion predicates,
not literal-left declarations or reversible result slots. Those unjoined forms
must reject instead of entering an encoder that lacks their operand representation.

`SourceValueProducts.w` reserves frame coordinates from this syntax. A scalar
needs one result local. A binary predicate needs two operand locals and one
Boolean result. Frame-plan validity does not claim that every operand name has
bound. The instruction phase owns that check. No global becomes a named local,
and no initializer substitutes for runtime state.

`DirectAssertionProducts.w` uses the same scalar value binder as returns and
stores. Named operands still resolve through `DirectScalarLocations.w`. Constants
still use the existing counted lookup. The assertion requires a Boolean result
and compatible operand types before emission. A signed global alone is not a
Boolean predicate.

## Emission and publication

The shared scalar destination emitter now accepts `EXPECT_TRUE` as well as
return and store destinations. Its separate measurement operation validates
complete opcode, operand, frame, and byte windows without publishing code.
The assertion owner also checks the complete type window. It constructs its
result before the first code or type write.

Comparisons emit both operand loads in source order, the comparison, and
`EXPECT_TRUE`. Every global operand emits `LOCAL_LOAD_GLOBAL` at that use site.
The declaration ordinal remains independent of local coordinates and sorted
string IDs. The raw encoder checks representation and extent. The bound assertion
owner checks Boolean semantics. Neither check replaces final artifact verification.

The old root loop-opcode adapter and its five-column, 4,096-row scratch table are
gone. Nested loops still own their separate loop products. Removing that root
scratch saves `5 * 4096 * 8 = 163840` bytes and one lifetime buffer. The direct arena
now holds 58,048 words and 262,144 code bytes, or 726,528 bytes in twelve buffers.
The words comprise three scanner columns, seven statement columns, three type
columns, three function columns, two call columns, and statement widths. No
scanner, frame, source-global, interpreter, or publication limit increases.

All statement code and types remain private until the complete statement batch
passes. A bad later predicate cannot publish an earlier valid store, artifact
prefix, digest, or inactive tail.

## Evidence and remaining checks

Fourteen accepted bodies cover the original cases, both operand orders, repeated
global reads, signed minimum, a literal-left comparison, a counted right constant,
and ordinary local and Boolean assertions. Eight invalid bodies cover signed
predicates, mixed types, shadowing, unknown names, arithmetic predicates, separated
equality bytes, and extra operands after an earlier store. The complete native
artifacts and their digests match independent stage 0. Retained globals and
unchanged callable execution with arguments 5 and 8 also agree.

The first adapter selection passes 81 example methods with no failures or skips.
Its longest method took 1.819 seconds. This includes existing comparison, loop,
conditional, and reversible-return checks. It is not whole-compiler acceptance.

Four false predicates now compile, then reject at `EXPECT_TRUE` with arguments
5 and 8. Each failing instruction leaves the complete machine snapshot and
history unchanged. Both native and independent executions rewind and replay.
Eleven direct assertion cases check complete type/code windows, exact terminal
counts, first excess, malformed late backing, inactive cells, cleanup, and replay.
Ten raw assertion cases check operand order and terminal code/frame windows.
Five declaration cases reject relation kinds without a declaration encoding.

The broader selection passes 172 examples, fourteen source checks, and eleven
documentation checks. Its longest example method took 15.704 seconds. Native
scanner measurements keep every changed source below 4,096 raw tokens. The direct
statement owner falls to 29,408 bytes and 3,156 tokens. The final delta adds an
explicit declaration rejection and checks its unsupported raw relation kinds.
No changed source exceeds 1,000 lines.

Archive intake and both selected physical checks pass. They report 477 modules,
2,344 constants, and 1,885 callables. The independently reconstructed graph has
2,279 imports and 221,455 bytes. Native graph and separate SHA work measure
78,959,915 and 42,386,002 transitions. The selected linked reference remains
603,784 bytes. Intake took 233.759 seconds and selected physical compilation
353.488 seconds. These checks do not compile every physical body.

Independent packaging and all four dependent locks agree. A locked and vendored
consumer compiles a store, a global/local assertion, a global/counted-constant
assertion, and a later load from an immutable source range. Its 904-byte artifact
matches stage 0 completely. It retains three globals, one step claim, nine locals,
and twelve instructions. Publication takes 1,799,759 native transitions. Native
global intake and callable execution replay also pass. The 181-target workspace,
source documentation, formatter, and six-root Tree-sitter checks pass.

Commit `13164625a` contains this implementation. Bootstrap run `34692581246`
passes all 52 jobs, including `compare-bootstrap-outputs`. README, site, and
CodeQL workflows also pass for that exact commit. Local publication produces
identical documentation sites. These results do not change the proposal status.

## Acceptance

- [x] The original three global assertion sources compile without member projection.
- [x] Shared syntax reserves widths without early local-only predicate binding.
- [x] Shared locations and scalar emission retain source order and actual global loads.
- [x] Later malformed or mistyped predicates preserve complete artifact publication.
- [x] False predicates, terminal windows, and phase replay have complete evidence.
- [x] Affected adapters and physical source budgets pass against the final tree.
- [x] Archive, graph, locks, and locked-consumer artifacts independently agree.
- [x] Documentation and hosted verification agree with the exact committed tree.

These checks do not establish native entry lowering, every physical compiler
body, a compiler fixed point, or the parent access contract.
