# WIP-0497: Exact source-word admission

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-05 |
| Updated | 2026-09-09 |
| Area | Self-hosting, source admission |
| Depends on | WIP-0049, WIP-0051 |
| Supersedes | None |
| Superseded by | None |

## Boundary

[WIP-0049](WIP-0049-bounded-native-source-product-compilation.md) requires native
source products to agree with stage 0. Before this change, the declaration pass
accepted `modumF`, `imposU`, `classicbM`, `clatT`, `publjD`, and `contU` as keywords.
All six share polynomial hashes with real words. Stage 0 rejected them, but the
native pass published both modules' declaration names. Split prefix and suffix hashes also
fail to establish exact intrinsic spelling.

This record replaces source-token and primitive-type hash admission. It includes
compiler consumers and the native test-source discovery, metadata, and lowering
consumers of that API. It uses WIP-0051's existing source-coordinate and
primitive-type products, not its still-open complete frontend. It does not
approve a compiler fixed point.

## Change

`KeywordTokens.w` owns 70 shared keyword, type, intrinsic, and test-metadata
codes. `BooleanTokens.w` keeps the two Boolean literal codes and their predicate.
Each code has one owner. Existing values remain opaque identities, not evidence
that arbitrary text is a keyword. The inventory includes `enum` for
[WIP-0050's payload-free variant products](WIP-0050-native-aggregate-source-lowering.md).
Private copies and primitive-type magic numbers
disappear. Keeping Boolean codes with their predicate preserves the native
compiler suite's existing dependency graph. Shared member fronts add visibility,
method-kind, presence-type, reserved-value, register, and circuit-proof words.
The full vocabulary now has 72 spellings, including the two Boolean literals.

The declaration pass rejects unindexed fields before the next member's
parameters or body instead of silently ending its constant prefix. It consumes
every leading state declaration before indexing constants. These checks precede
declaration-name publication. They do not validate every member front or body.

`sourceWordCode` accepts a scanner-owned ASCII range and returns its exact code or
zero. It checks length and source containment before reading. Sentinel-prefixed
base-128 lanes retain eight and five ordered bytes without collisions or signed
overflow. Separate short and long tables keep lane matching distinct from range
admission. Their artifacts remain inside the existing module buffer. This
thirteen-byte vocabulary bound does not shorten identifiers or source leases.

`sourceTokenCode` checks both token-column windows before projecting the range.
Unknown words, invalid windows, and non-ASCII candidates return zero without
changing caller tables. Punctuation, number decoding, and identifier equality
keep their separate owners. Callers still validate token kinds and grammar.

Delete `tokenHash`, `rangeHash` in aggregate syntax, the rotate-name hash split,
the hash mask, and the redundant native test-token wrapper. Boolean predicates
consume admitted codes. Aggregate primitive resolution uses the same named codes,
including `byteview`, whose old magic value came from an obsolete hash mask.

## Evidence

- `NativeCompilerDeclarationNamesExampleTest` rejects every reproduced keyword
  alias before publishing any module or class name. The regression failed against
  the previous source.
- `NativeCompilerSourceWordsExampleTest` covers every spelling, character
  mutations, both lanes, leading NUL aliases, long unknown identifiers, UTF-8
  coordinates, signed extremes, unchanged token rows, and complete rewind.
- `NativeCompilerSourceKeywordRejectionExampleTest` checks complete unpublished
  output for malformed literals, types, and intrinsics. Aggregate-product tests
  check every caller row. `NativeCompiledTestRunnerExampleTest` rejects aliases
  against explicit descriptors without publishing reports.
- `NativeCompilerSourceWordsPhysicalProductExampleTest` compares complete Boolean
  and long-word artifacts plus every short-word and range-classifier body after
  two imported calls resolve. The enum milestone measured 752 and 5,312 bytes for
  the two complete artifacts. Those sizes are historical, not pins for the larger
  member-front vocabulary. The whole closure also compares these products before
  linking. Confirming archive and closure evidence must follow vocabulary changes.
- The wider closure reached the unchanged 65,535-buffer lifetime limit with only
  18.5 MiB live. Closure classification now reuses one scratch set rather than
  allocating it for every module. `NativeCompilerExecutableOwnerScratchExampleTest`
  consumes 524 buffers for 512 sources. Short scratch columns and rejected headers
  leave publication intact.

## Acceptance

- [x] The word inventory covers every consumer of the deleted hash APIs.
- [x] Shared codes and one exact range owner admit the inventory.
- [x] All compiler and test-source consumers use admitted codes.
- [x] Declaration, intrinsic, type, and explicit-descriptor aliases reject before publication.
- [x] Direct boundary and rewind tests pass without modifying caller rows.
- [x] Retained products match stage 0 and confirming closure checks pass.
- [x] Old implementations, wrappers, copied constants, and stale fixtures are gone.
- [x] Documentation, package identities, locks, and source gates agree.

## Remaining work

[WIP-0498](WIP-0498-native-test-member-front-admission.md) owns the demonstrated
automatic-discovery gap. Unknown declaration fronts can still disappear into a
zero-test report. Exact word classification does not validate a class body.

WIP-0049 still owns complete source lowering and compiler integration. Stage-1 and
stage-2 equality, generated inverses, native recovery, and Java-free operation
remain open. Byte-buffer metadata recognizers in native package-test helpers and
archive provenance do not use this source-token API. They need their own exact
prefix and line admission audit.
