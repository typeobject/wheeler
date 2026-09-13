# WIP-0518: Detached source claim origins

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Source claims, private projections, self-hosting |
| Depends on | WIP-0011, WIP-0049, WIP-0514 |
| Supersedes | None |
| Superseded by | None |

## Why this split exists

The aggregate primitive compiler cannot verify an original claim against
placeholder code. It also cannot discard that claim. WIP-0516 needs the original
claim facts and declaration ranges before it rewrites a private source view.

`SourceClassicalProofs.w` already binds names, subjects, rules, and full signed
arguments through shared member fronts. Before this change, it kept declaration
windows private. A second theorem parser would create another authority for
syntax, modifiers, source positions, and claim subjects.

Retain those coordinates at the existing binding boundary. Keep primitive
compilation, final nominal composition, and final-code proof verification in
WIP-0516 and its remaining joins.

## Contract

1. Preserve the existing five semantic claim columns. Add a separate counted
   origin window with source-relative byte start and byte length columns.
   The claim ordinal joins both tables. No dependency source enters the binder.
2. Derive each origin from the same admitted `SourceMemberFront` as its claim.
   Include every visibility modifier through the terminating semicolon. Start
   at the member cursor, not the theorem token or name token. Otherwise removing
   a public theorem could change the visibility of the following callable.
3. Validate all borrowed backing and active windows before publication. Invalid
   later declarations preserve every caller name byte, semantic cell, origin
   cell, and inactive tail. Rejection returns zero counts and false. Construct
   result records before publication.
4. Keep original names, subjects, effects, and signed arguments unchanged. A byte
   origin records provenance, not proof truth. No primitive instruction count
   may certify or reject a bound intended for final nominal code.
5. Project only from validated counted origins. Check the complete ordered,
   nonoverlapping range batch before changing private bytes. Blank claim bytes
   while preserving line endings, source length, and every other byte. Do not
   rescan body words or bind a claim through another parser.
6. Reject missing, overlapping, out-of-range, or malformed later origins without
   changing the destination. The projection does not make a claim-free artifact
   the final artifact. Its caller must retain the original bound claim products.

The ordinary and homogeneous inverse adapters still enforce their existing
policies. Their callers do not need an origin output. Reuse the shared binder and
account for private origin storage in those adapters. Do not keep an older
binder or copy its resolver under another name.

## Storage

Keep 64 claims and the existing five semantic columns. The separate two-column
origin window contains `64 * 2 = 128` words, or `128 * 8 = 1,024` bytes.

The binder can extend its existing private staging table by those 128 words
without adding a staging buffer. A caller that retains origins needs one output
buffer. Name capacities and semantic claim capacities do not grow. Calculate
adapter regions from their live columns and count lifetime buffer identities
separately. Preserve allocation-free ordinary absence detection.

The implemented binder reserves 13,058 words plus 16,384 name bytes:

```text
words = 4096*3 + 2 + 64*2 + 64*(5+2) + 64*3 = 13058
bytes = words*8 + 64*256 = 120848
buffers = 3 + 1 + 2 + 1 + 3 + 1 = 11
```

For `S` step claims, the shared evaluator adds one eight-byte counter at a time.
The binder therefore uses `11 + S` lifetime buffers and `1 + S` regions, with
at most `120848 + 8` owned buffer bytes live. Parser and result records allocate
separately. Inverse claims add no evaluator counter.

The coverage adapter reserves `(64 + 320 + 128)*8 + 16384 = 20480` bytes in four
buffers. It binds privately once, checks the shared inverse policy when needed,
constructs its report, then copies the complete result. The direct inverse
adapter adds one empty constant row: 20,488 bytes in five buffers. Both adapters
give the shared binder private outputs. Ordinary absence still creates no
owned buffers. Origin projection creates no owned storage.

## Evidence

Compare semantic products and byte origins against independent stage-0 lexical
coordinates. Include visibility sequences, comments, CRLF, UTF-8 before and
inside claim ranges, contextual names, qualified subjects, repeated subjects,
full signed bounds, and both classical rules.

Check zero and 64 claims, the first excess, short backings, malformed later
windows, and complete inactive tails. Observe output buffers before dropping
storage. Representative success and rejection cases must rewind and replay.
Capacity cases run history-free.

Retain a claim whose decision differs between primitive placeholders and final
nominal code. Origin projection must neither decide that claim nor lose it.
Final-code verification remains a separate acceptance requirement.

## Local implementation evidence

The shared binder publishes origins from the admitted member cursor through the
semicolon. Its existing staging buffer carries the two extra private columns.
Both adapters and the binder construct their result records before copying caller
outputs. The coverage adapter stages ordinary claims too, so its own report
allocation cannot follow a visible nested publication.

`projectSourceClaimOrigins` shares the existing source-claim owner. It checks
all counts, exact backings, ordered ranges, and UTF-8 boundaries before erasing
bytes. It preserves CR, LF, and inactive tails.
An empty origin window is a no-op, not a source-absence assertion. The caller must
use the bound claim count and retain its semantic products.

The 59 binder cases compare every semantic cell, origin cell, name byte, inactive
tail, and borrowed input. They check short and excess origins, zero and 64 claims,
the first excess claim, full signed arguments, visibility, UTF-8, lifetime buffer
counts, exact reservations, cleanup, and replay. Six projection methods check
native-bound origins, malformed later ranges, UTF-8 splits, all 64 origins, the
full 32,768-byte source window, cleanup, and replay. Capacity runs retain no
history.

One regression independently measures primitive and nominal instruction counts.
The same bound passes the placeholder body and fails the actual nominal body.
Native binding retains that claim unchanged, and projection erases only its
source origin. This does not compile or verify the nominal body natively.

The final direct selection passes 81 cases. A separate adapter and identity
selection passes 109 cases, including archive claims, artifact publication,
inverse coverage, and physical graph identities. Twelve documentation checks,
source gates, and Tree-sitter pass. These selections do not run the full test
suite.

The original physical selection passes in eleven minutes and fourteen seconds.
Archive intake checks 483 modules, 2,424 constants, and 1,901 callables. The native
graph takes 80,693,888 transitions. SHA takes 43,194,286. Independent package and
graph reconstruction agree, as do four refreshed locks and the 181-target
workspace. The selected 603,784-byte, 527-function reference remains unchanged.
This is not native compilation of every physical compiler body.

A locked consumer independently matches its complete 479,280-byte driver. It
binds at transition 676,640 and halts at 681,286 under the unchanged command
bound. Its intact input retains state, a constant, a record, a variant, an enum,
both callable effects, both claim rules, and UTF-8. A four-step claim passes the
placeholder body but fails the seven-instruction nominal body. The consumer
retains that claim rather than deciding it. Every claim, origin, name, input,
inactive tail, and retained buffer matches. Publication rewinds and replays
99,234 transitions. A malformed later claim preserves all caller storage.

Both 34-file documentation sites match byte for byte. The literal review-tree
audit finds no text file over 1,000 lines, but 19 source directories and 44
physical directories still exceed ten files. Repository-wide layout compliance
remains open.

Commit `ccd5dbc089` is on remote master. Bootstrap run
[34726855062](https://github.com/typeobject/wheeler/actions/runs/34726855062)
passes all 52 jobs, including output comparison. README, site, and CodeQL also
pass on that commit. This acceptance covers the claim-origin tree, not later
aggregate changes. The aggregate adapter still uses its old primitive boundary.

## Acceptance

- [x] Shared binding publishes complete semantic and origin products atomically.
- [x] Modifier-inclusive origins match the original immutable source coordinates.
- [x] Projection preserves every nonclaim byte and rejects an invalid complete batch.
- [x] Ordinary and inverse adapters retain their policies without another binder.
- [x] Bounds, storage, tails, cleanup, rewind, and replay have direct evidence.
- [x] Primitive and final proof decisions remain separate, with retained claim facts.
- [x] Affected source products, archives, locks, examples, and documentation agree.
- [x] The exact verified feature tree is committed, pushed, and checked remotely.
