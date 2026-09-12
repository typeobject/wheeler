# WIP-0517: Counted callable-front staging

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, source fronts, callable products |
| Depends on | WIP-0045, WIP-0049, WIP-0498 |
| Supersedes | None |
| Superseded by | None |

## Boundary

WIP-0516 needs callable coordinates for a private primitive view. The counted
closure index already produces those columns, but its scanner lives inside
`ModuleCallables.w`. It finds delimiters and guesses which declarations describe
methods. Reusing that code through a fabricated closure would hide the missing
source-local boundary. Copying it would create another parser.

Move source staging into `SourceCallableFrontProducts.w`. Use the shared member,
modifier, parameter, and type fronts. Keep closure scheduling and whole-batch
publication in `ModuleCallables.w`. The aggregate adapter can then consume the
same source-local producer without calling the minimal compiler.

## Contract

1. Stage one UTF-8 class into existing callable and parameter columns. Preserve
   source order, visibility, effects, parameter modes, result-slot width, and
   exact signature, name, type, and body byte ranges. Include nested reverse
   blocks in the enclosing body. Reject a trailing reverse block outside a
   callable, which the old delimiter scanner incorrectly admitted.
2. Add the supplied source start to callable and parameter byte coordinates.
   Keep the module-name pair source-relative. Callable indices begin at the
   supplied closure row. Parameter indices begin at the private total cursor.
3. Dispatch members through `sourceMemberFront`. Do not rediscover declaration
   kinds from punctuation or words inside bodies. Preserve nominal declarations,
   constants, globals, claims, contextual names, and UTF-8 comments at this input.
4. Reuse canonical modifier and type owners. Duplicate modifiers remain
   idempotent, and any public visibility occurrence exports the member. Distinct
   method kinds remain mutually exclusive. Staging does not resolve names,
   execute bodies, decide claims, or admit a later compilation profile.
5. Validate source, coordinate arithmetic, owner, initial cursors, and every
   backing column before staging. Return a negative count for a malformed later
   front or an exhausted active window. Private scratch may change on rejection.
6. Never expose those partial rows as closure products. The closure owner keeps
   staging private until every module passes, constructs its result, and then
   publishes. A later failure preserves all public columns and report fields.
7. Remove the private delimiter scanner and the unused manifest argument. Do not
   leave forwarding wrappers, a second signature parser, or per-source owned
   workspaces in their place.

## Bounds

The source front admits at most 32,768 UTF-8 bytes and 4,096 raw tokens. It retains
64 callables per source, 4,096 closure callable rows, 64 parameters per callable,
16,384 closure parameter rows, and owner indices below 512. A zero-count window
may begin at either terminal cursor. Byte-coordinate addition must fit a signed
64-bit value.

The producer borrows three token columns, a two-cell module pair, fourteen
4,096-cell callable columns, three 16,384-cell parameter columns, and a one-cell
parameter cursor. It allocates no owned buffers or regions. Front result records
still allocate. Its caller owns and reuses the mutable workspace.

The closure arena contains:

- Four 512-cell module columns, including the processed bitmap.
- One 3,072-cell edge column.
- Fourteen 4,096-cell callable columns.
- Three 16,384-cell parameter columns.
- The two-cell module pair and one-cell parameter cursor.

That is 111,619 words, or 892,952 bytes, in 24 buffers. The scanner uses
`3 * 4,096 * 8 = 98,304` bytes in three buffers per active source. These replace
unexplained reservations of 898,000 and 98,320 bytes. Staging adds no lifetime
buffer identities. At `moduleCount` owners, callable intake uses
`5 + 24 + moduleCount * (1 + 3)` lifetime buffers and `2 + 2 * moduleCount`
regions. The two-module test checks all 37 buffer identities and six regions.
Lease and copied-name capacities remain unchanged.

## Evidence

Direct native fixtures compare every active product and inactive cell for an
intact mixed-member class, both entry orders, copied UTF-8 coordinates, ordinary
loans, repeated visibility, and reversible results. Capacity cases fill the last
64-callable window and the last 64-parameter window without retaining history.
Malformed later fronts, first excess rows, wrong backing columns, and invalid
initial cursors reject. Exact source-byte and raw-token frontiers pass, including
comments. The next byte or token rejects. Signed coordinate endpoints and owner
bounds have direct cases.

A two-module closure fixture uses a real imported helper. Its success compares
all callable columns, module and edge counts, untouched tails, and borrowed
input, then rewinds and replays publication. A malformed member in the second
module leaves every prepared public buffer and report field unchanged. Private
staging is not a public artifact or a claim of body compilation.

Commit `d55adee5e50b0caf94a9aa26398f703d0497b30c`, tree
`541e9cb9793ad07347600734c874caca5f82d2da`, contains this staging feature. All 52
hosted bootstrap jobs pass, including output comparison. README, site, and
CodeQL pass on that commit. This does not certify later aggregate compiler work.

The final focused command passes 28 example methods, twelve documentation
methods, source header/length/layout gates, and Tree-sitter. The longest example
method takes 6.288 seconds. Source budgets are 5,271 bytes and 802 raw tokens for
`CallableSignatureProducts.w`, 19,460 bytes and 2,758 tokens for
`ModuleCallables.w`, and 8,929 bytes and 1,305 tokens for the new front owner.

The original physical selection passes in thirteen minutes and 22 seconds.
Archive intake checks 483 modules, 2,405 constants, 1,898 callables, and 2,331
imports. It takes 351.339 seconds. Selected body comparison takes 443.918 seconds,
and malformed-transport rejection takes 1.358 seconds. These are archive and
selected-body checks, not native compilation of every compiler body.

Independent compiler archives and the 225,673-byte graph agree byte-for-byte.
Archive identity is `131658c37defe7ce7748335534ce093eb1340cf09953bd7eff3bf6f7bed91a61`.
Graph identity is `2406d527e7b6ddb72c133d849b6405e89fe4d6b0eca9861bfcf9f11cd4b771b1`.
Native graph validation takes 80,693,870 transitions, and separate hashing takes
43,194,286. The independently reconstructed selected container remains 603,784
bytes, 527 functions, and 19,917 instructions. Four dependent locks and the
181-target workspace check and build agree.

A locked public-API consumer resolves, vendors, builds, and runs the intact
mixed-member source through this staging boundary. Independent execution checks
all seventeen product columns and inactive cells, input bytes, the module pair,
parameter cursor, unchanged owned storage, cleanup, rewind, and replay. A later
malformed member rejects. Staging completes after 1,465,479 transitions, and the
consumer halts after 1,465,507, below the unchanged command bound. Its independently
matched 457,936-byte driver has identity
`642e54a41460f97145b46c87a5614d7121b3d16410d79e6f718f08ec5935f50e`.
That driver is not a natively compiled artifact of the mixed-member source.

The literal audit finds no overlong text files. Nineteen source directories and
44 physical directories still exceed ten files. Narrow source gates do not
establish repository-wide layout compliance.

## Acceptance

- [x] Source staging uses the shared member, modifier, parameter, and type fronts.
- [x] The closure owner uses the extracted producer without a compatibility path.
- [x] Complete mixed-member coordinates, inactive cells, and capacity windows agree.
- [x] A later closure failure preserves public products and reports.
- [x] Representative staging and publication rewind and replay exactly.
- [x] All resource boundaries and final source budgets have direct evidence.
- [x] Physical archive intake, selected-body regression, graphs, packages, and locks agree.
- [x] Examples and documentation describe the implemented boundary.
- [x] The verified feature tree is committed, pushed, and checked remotely.
