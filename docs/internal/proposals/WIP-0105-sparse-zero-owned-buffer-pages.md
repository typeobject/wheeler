# WIP-0105: Sparse zero owned-buffer pages

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Virtual machine, owned storage, closure performance |
| Depends on | WIP-0013, WIP-0039, WIP-0083, WIP-0085 |
| Supersedes | Eager host zero lists for new owned buffers |
| Superseded by | None |

## Summary

Represent newly allocated zero-filled owned buffers with sparse immutable 64-word pages. Allocation records the full logical length and region charge but creates a physical page only when a write reaches it.

The change preserves buffer reads, writes, snapshots, rewind deltas, ownership, region quotas, host output, traps, and transition observations. The complete physical compiler closure falls from 16 minutes and 43 seconds to 16 minutes and 2 seconds under the unchanged deadline.

## Problem

`OwnedStore` initialized every byte and word buffer with `Collections.nCopies`. The first mutation converted that logical list into `PersistentLongList` by visiting every element and allocating every 64-word chunk.

Compiler product programs allocate large bounded workspaces but write only measured prefixes and selected columns. A first write near the start of a million-word buffer therefore materialized thousands of untouched zero pages. WIP-0087 stopped publishing those tails. The VM still paid to represent them.

## Sparse representation

`PersistentLongList.zeros(size)` records the logical size and an array of nullable page references. A null page denotes 64 logical zeros, or the shorter final zero page.

Reads from a null page return zero. A single-word update clones the page-reference array, creates or clones only the selected page, writes the new value, and returns a new list. A three-word map update creates at most two pages when it crosses a page boundary.

Generic `copyOf` retains eager value copying for externally supplied lists. Only VM-created zero buffers select the sparse constructor.

## Logical quotas

Sparse physical allocation does not change language-visible storage accounting. `RegionValue.usedBytes`, live object count, maximum region bytes, maximum total live bytes, buffer length, and element kind all use logical capacities.

A program cannot allocate a larger logical buffer because the host stores fewer pages. Region exhaustion and total live-storage traps occur at the same instruction as before.

## Rewind and observation

Every update remains copy-on-write. `OwnedStore.Change` retains the previous `BufferValue`, including its sparse page references. Rewind restores the exact prior list and region state.

No instruction becomes a no-op. Writes of zero still produce the same machine transition and observation path. The change alters backing representation only, so canonical and noncanonical observers receive unchanged event sequences.

Host byte output iterates the complete logical length. Unwritten sparse pages therefore publish exact zero bytes just as eager lists did.

## Evidence

`PersistentLongListTest` covers a one-million-word zero list, immutable update at its final element, a three-word update that crosses a 64-word page boundary, and invalid negative sizes.

`VirtualMachineTest` covers typed control flow, byte range checks, region exhaustion, ownership transfer, snapshots, commits, calls, result transfer, UTF-8 freezing, history, inverse execution, and rewind against the sparse representation.

`NativeCompilerPhysicalClosureExampleTest` compares every selected physical artifact, validates retained functions and relocations, links the exact 96-product subset, repeats publication, and rejects malformed footer and relocation products. It passes in 16 minutes and 2 seconds. The linked container remains byte-identical with SHA-256 `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] New host output buffers use sparse zero pages.
- [x] New region-owned buffers use sparse zero pages.
- [x] Logical lengths and storage quotas remain unchanged.
- [x] Reads from unwritten pages return zero.
- [x] Single-word updates clone only one selected page.
- [x] Three-word updates clone at most two selected pages.
- [x] Prior lists remain immutable after updates.
- [x] Snapshot and rewind semantics remain exact.
- [x] Host output retains unwritten zero tails.
- [x] Region and byte-value traps remain fail-closed.
- [x] Complete physical artifacts and linked identity remain unchanged.
- [x] Existing evidence deadlines remain unchanged.
- [x] Java, documentation, source-length, and layout policy pass.

## Rejected alternatives

### Reduce language-visible buffer capacities

Rejected. Capacity products and region quotas are part of program semantics. Sparse storage changes representation only.

### Use mutable shared zero pages

Rejected. Shared mutable pages would violate snapshot and rewind isolation.

### Skip writes whose new value is zero

Rejected. A write remains an observable machine transition even when its stored value is unchanged.

### Increase closure timeouts

Rejected. Sparse immutable pages remove host representation work while preserving complete evidence.

## References

- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0039](WIP-0039-deterministic-structured-task-machine-and-global-rewind.md)
- [WIP-0083](WIP-0083-zero-allocation-unobserved-transitions.md)
- [WIP-0085](WIP-0085-root-task-state-specialization.md)
