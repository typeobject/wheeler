# WIP-0513: Immutable source lease ranges

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-12 |
| Updated | 2026-09-12 |
| Area | Self-hosting, source leases, lifetime storage |
| Depends on | WIP-0044, WIP-0045, WIP-0054 |
| Supersedes | None |
| Superseded by | None |

## Failure

The WIP-0511 and WIP-0512 selected physical check exhausts the VM's 65,535
lifetime-buffer identities after physical product compilation, during
`stageClosureSources`. The snapshot retains physical owner 337 from the preceding
phase. It has 13,859 regions, 65,535 buffers, and 20,962,242 live bytes. Dropping
storage does not reclaim its identity. More live memory would not fix this limit.

Archive intake passes separately in 234.960 seconds. The combined three-method
selection fails after nine minutes and 39 seconds. Do not count that command as
a physical acceptance pass or reduce its source set to avoid the failure.

## Contract

1. Publish a current lease from an exact immutable archive byte range. Keep the
   existing nonempty ASCII profile and 32,768-byte bound. Validate the whole range,
   backing columns, selected lease, and previous length before changing storage.
2. Copy directly into the slot. Remove the temporary archive buffer and UTF-8
   freeze from symbol intake, callable intake, and scheduling. Keep the separate
   immutable active-source copy that the declaration scanner consumes.
3. Keep one publication authority. Migrate every caller of `publishActiveSource`
   to the byte-view/start/length signature. Do not retain the old UTF-8 adapter.
4. Validate the complete schedule permutation and output extents. A late bad
   source, duplicate owner, or short generation column cannot publish earlier
   module rows. Construct lease, schedule, and intake results before public
   metadata writes.
5. Keep eight slots, 512 module rows, and the VM lifetime-buffer limit unchanged.
   Derive bytes and allocation counts from their column and element widths.

This does not admit non-ASCII source, retain dependency bodies across product
boundaries, or establish native compilation of every physical compiler body.

## Allocation account

The slot contains `8 * 32,768 = 262,144` bytes and four eight-word metadata
columns. Its arena needs `262,144 + 4 * 8 * 8 = 262,400` bytes and five buffers.
The previous declaration reserved a fifth metadata column that no caller used.

A schedule adds two 512-word staging columns. It therefore owns two regions and
`5 + 2 = 7` buffers, independent of the module count. It no longer allocates a
source region or buffer per owner. Remove the unused manifest argument too.

Symbol and callable intake each retain one source buffer instead of two. Their
source arenas shrink from 65,536 bytes and two buffers to 32,768 bytes and one
buffer. Across both intake passes and scheduling, a closure with `M` modules
avoids `3 * M` lifetime-buffer identities. For 480 modules, that saves 1,440.
UTF-8 freezing preserves the original buffer identity, so it adds no second
identity to this calculation.

## Evidence

The range fixture compares every input and storage cell, inactive bytes, metadata,
region extents, and buffer identities. It exercises first and last slots, NUL and
DEL, non-ASCII bytes outside the selected window, stale or forged leases, invalid
previous lengths, short columns, and overflowing ranges. Rewind and replay cover
publication and rejection. Publication creates no owned storage.

The schedule fixture publishes two and 512 owners with the same seven buffers.
It checks every active output row and inactive tail. Duplicate and out-of-range
owners, late invalid source ranges, non-ASCII source, invalid counts, and short
outputs preserve all caller buffers. The two-owner case retains full replay.
The capacity case runs history-free. Both methods pass after removing unused
binary-module inputs from the development fixture.

The migrated frontier/capacity cases and counted closure/dependency adapters also
pass. The final short selection has 18 examples, 25 source checks, and twelve
documentation checks, with no failures, errors, or skips. The longest example
takes 4.580 seconds.

The original three-method physical selection now passes in ten minutes and
31 seconds. Archive intake takes 254.584 seconds, selected physical compilation
370.053 seconds, and malformed transport rejection 1.045 seconds. The checked
source set and VM limits are unchanged. This still does not compile every
physical compiler body.

Independent reconstruction finds 480 modules, 2,368 constants, 1,894 callables,
and 2,306 imports in 223,688 manifest bytes. Archive and graph measurements agree
with separate package commands. Four locks now name the refreshed compiler
archive. A locked consumer publishes a 952-byte recursive call/store artifact
with a canonical global/literal assertion. Complete bytes, digest, inactive tail,
retained intake, execution, cleanup, and replay agree with an independent oracle.
The final affected-adapter selections pass. Workspace check and build cover all
181 targets. Source, documentation, and six-root syntax gates pass. Exact-tree
and hosted gates remain open.

## Acceptance

- [x] One immutable-range publisher replaces the temporary UTF-8 publication path.
- [x] All three native callers use the same bounded source range contract.
- [x] Complete range/schedule rejection, allocation counts, cleanup, and replay pass.
- [x] The original physical check passes with the unchanged VM and source limits.
- [x] Source budgets, packages, locks, adapters, and documentation agree.
- [ ] An exact verified feature tree is committed, pushed, and checked remotely.
