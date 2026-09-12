# WIP-0514: Counted executable entry products

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, target binding, source artifacts |
| Depends on | WIP-0049, WIP-0054, WIP-0498, WIP-0511, WIP-0515 |
| Supersedes | None |
| Superseded by | None |

## Missing join

Before this change, the counted source artifact publisher always appended a
synthetic `$library` function and selected it in the manifest. Its callable
composer appended `RETURN` to ordinary void bodies. Neither operation compiled
a declared executable entry.
The test runner still reaches `requireMinimalProgram` for the intact WIP-0498
mixed-member source. Selecting and renaming that test does not fix compilation.

Add target binding and entry emission to the counted path. Do not patch a
verified library artifact, keep `$library` under a different name, or add another
minimal compiler family. Nominal instruction composition remains required by
WIP-0498 and WIP-0054. This proposal does not replace either contract.

## Contract

1. Carry an explicit deployable, library, or tool target kind. Use the package
   manifest kind values rather than infer intent from a callable spelling.
2. Bind an executable target to exactly one counted `entry void main`. Its
   source-local ordinal need not be zero. Library targets forbid entry effects
   and retain the canonical synthetic library entry. Empty libraries remain legal.
3. Admit the existing entry ABI: no parameters, one borrowed UTF-8 or byte-view
   input, one mutable borrowed byte output, or input followed by output. Reject
   owned inputs, mutable input loans, read-only output loans, scalar parameters,
   output-before-input order, results, repeated entries, and unsupported effects.
4. Validate the whole selected callable window, copied names, parameter windows,
   and backing columns before publishing a binding. A malformed later row cannot
   expose an earlier entry. Return minus one when binding fails. Do not mutate
   input tables or allocate owned buffers or regions.
5. Compose the selected entry with its actual `HALT` termination. Ordinary helper
   returns must not change. Plan names, descriptors, code, and manifest together.
   Executable artifacts must contain no synthetic library string or function.
6. Join ordinary classical claims to the actual composed entry and helper code.
   Keep generated-inverse policy separate. Reject unjoined body or effect forms
   rather than flatten them into an ordinary entry.
7. Verify the complete private artifact before hashing or publishing it. Preserve
   all caller-visible bytes, identities, metadata, and relocations on rejection.
   Construct results before publication. Do not pass dependency bodies through
   the counted compilation boundary.
8. Migrate the source compilation callers to the explicit target contract. Remove
   obsolete target inference and library-only publication assumptions. This is
   not permission to retain a second executable emitter or compatibility path.

The structured statement profile remains bounded by its existing lowering
owners. Entry binding alone does not admit nested stores, nominal instructions,
quantum effects, or mixed generated-inverse composition. The intact mixed-member
runner must still compile through the complete composition path before its
parent proposal can close.

## Bounds

A source-local window contains at most 64 callables within the existing 4,096
closure rows. Each signature contains at most 64 parameters within 16,384
parameter rows. Check ranges with subtraction before adding offsets. The empty
window may begin at the backing-table end.

The binding fixture supplies six callable columns and two parameter columns.
It needs `(6 * 4,096 + 2 * 16,384) * 8 = 458,752` bytes and eight buffers. The
binding itself adds no owned storage. Its result record still allocates. Scan
at most 64 copied identifiers, each bounded by the shared 256-byte name limit.
Each entry ABI check inspects at most two parameter rows. A repeated entry
rejects after the second candidate, so binding reads at most four such rows.

Do not grow scanner, source, frame, artifact, VM, or manifest limits to add this
join. Derive changed string, function, and code extents from the selected target
and the canonical encoding widths. The final orchestration owner uses 31,735
source bytes and 4,063 raw tokens, including comments. Entry binding uses 6,267
bytes and 1,121 tokens. The shared IR signature owner uses 1,135 bytes and 170
tokens. All retain the 32,768-byte and 4,096-token limits.

## Evidence so far

`SourceEntryProducts.w` binds target kinds and counted entry signatures. The
package manifest decoder exports the same named target kinds used by the binder
and compiler-tool selector. Archive compilation now carries the binding through
name planning, claim coverage, callable composition, and canonical emission.
The entry gets `HALT`. Its artifact has no synthetic library string or function.

Four binding methods cover all six entry ABI shapes for deployable and tool
targets, empty and nonempty libraries, nonzero entry ordinals, invalid target and
effect values, reversed or mistyped loans, results, overflowing windows, and
malformed later rows. All eight short backing columns reject. The full terminal
window places its entry at callable 63, closure row 4,095. Checks compare complete
input buffers and regions. Representative cases rewind and replay. The capacity
case runs history-free.

Complete source artifacts now match stage 0 for deployable and tool entries with
real helper calls, global stores, and a helper step claim. Execution compares the
unchanged declared entry and complete VM state, then rewinds and replays. Both
passing and failing assertions execute. All six host-loan shapes retain their
canonical descriptors and host bindings. The fixtures compare every artifact
and digest byte, inactive tails, unchanged input, and owned-storage cleanup.

Putting the entry before its helper exposed the last-function fences recorded in
[WIP-0515](WIP-0515-manifest-selected-entry-verification.md). The unchanged
regression passes after those verifier repairs. Invalid target intent and a false
actual-code step claim preserve every prepared caller buffer and region. Four
artifact/control methods initially passed in 34 seconds. Entry claims now also
verify against the actual `HALT` code.

Imported-entry fixtures reuse the existing counted call driver. They compare
complete transient artifacts, digests, relocation rows, identities, inactive
tails, input, cleanup, and retained descriptors. Entries call detached ordinary
signatures with zero or one argument and repeated global stores. Oracle-side
dependency binding exercises passing and failing assertions with full rewind and
replay. It does not establish native retained instruction linking.

Relocation counts now reach the canonical publisher before it constructs the
result record. The structured compiler returns that record instead of allocating
a replacement after publication. This adds no owned storage. Reports cover one
and 256 actual calls. Negative, excess, and overflowing counts preserve publication.

The affected selection passes 182 examples and twelve documentation tests in
three minutes and sixteen seconds, with no failures, errors, or skips. The longest
method takes 17.054 seconds. A separate 56-example adapter and identity selection
passes in one minute and 35 seconds, together with source and Tree-sitter gates.

Archive intake passes in 245.232 seconds. The physical product fixture initially
omitted its new manifest-kind import. After that fixture repair, physical product
comparison and malformed-transport rejection pass in 381.336 and 1.102 seconds.
The selected 603,784-byte linked reference remains unchanged. This is still a
selected physical check, not compilation of every physical compiler body.

The current inventory has 482 modules, 2,386 constants, 1,900 callables, and 2,323
imports. The 224,981-byte graph takes 80,313,726 native transitions. Separate
SHA-256 takes 43,059,484 transitions. Independent package and inventory archives
agree, as do independently generated graph bytes. Four dependent locks refresh
from those archives. The 181-target workspace checks and builds.

A locked tool-target consumer publishes an 872-byte executable with entry zero,
a later helper, three globals, and one helper step claim. Its entry has five
locals and eight instructions. Complete bytes, digest, inactive tails, input,
cleanup, retained descriptors, unchanged entry execution, rewind, and replay
match independent stage 0. Publication takes 1,838,920 transitions and completion
takes 1,838,942, below the unchanged command bound.

The compiler archive identity is
`e4818f50b801e279d6ab20c9e2a2b00839df6c70159fb7da0938a988103d9207`.
The graph identity is
`fe58dce27a1a516b7a69e97f335a35d606a117857e46f086523fd7888d25521d`.
The consumer artifact identity is
`87ff0ec188dc7c33c720c6f80f63dbd326d888d0a7701826417aaff5bec91732`.
Two independent documentation sites contain the same 34 files and bytes. The
literal repository audit finds no overlong text files, but nineteen source
directories and 45 physical directories still exceed ten files. Narrow source
gates do not close that repository-wide requirement.

Commit `c540db0f1` publishes entry support. Follow-up
`fd496b110b422db39d2e67b3eb21443b30603773` repairs the stale verifier target test
recorded in WIP-0515, without changing compiler source or native identities.
Bootstrap run `34715602116` passes all 52 jobs, including output comparison.
README quickstart `34715602154`, documentation site `34715602093`, and CodeQL
`34715601865` also pass on that exact commit. Later callable-front and aggregate
work needs its own evidence.

## Acceptance

- [x] Binding tests cover complete capacity, backing, signature, and range boundaries.
- [x] Counted compilation consumes explicit target bindings without a second path.
- [x] Complete deployable and tool artifacts match independent stage-0 references.
- [x] Library bytes remain unchanged for the same source and semantic products.
- [x] Entry/helper execution, failing assertions, full rewind, and replay agree.
- [x] Late malformed inputs preserve output bytes, identities, metadata, and relocations.
- [x] Actual-code claims verify after entry composition, including rejection cases.
- [x] A locked consumer exercises the public entry compilation API without dependency source.
- [x] Source budgets, affected physical evidence, archives, locks, and documentation agree.
- [x] The exact verified feature tree is committed, pushed, and checked remotely.
