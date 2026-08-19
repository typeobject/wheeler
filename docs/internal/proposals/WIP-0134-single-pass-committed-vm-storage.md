# WIP-0134: Single-pass committed VM storage

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler VM and bootstrap maintainers |
| Created | 2026-08-17 |
| Updated | 2026-08-17 |
| Area | Virtual machine, committed execution, self-hosting evidence |
| Depends on | WIP-0044, WIP-0115, WIP-0125 |
| Supersedes | Duplicate committed storage validation and split local updates |
| Superseded by | None |

## Summary

Remove duplicate work from the committed root transition path without changing a transition, trap, snapshot, rewind record, observation, artifact, or linked-container identity.

The VM now:

- resolves operand-role positions through an instruction-form table
- writes a local and advances its frame in one immutable frame construction
- writes adjacent or paired locals in one register-tree update
- executes owned-storage mutations through the result of the immediately preceding preflight validation

The ordinary rewindable path uses the same preflight and execution split. It still records immutable prior state.

## Operand positions

`Instruction.operand` formerly searched the instruction form's role list for every access. A compiler transition can read several operands in preflight and read them again during execution.

`InstructionForm` now builds one ordinal-indexed role table when the enum initializes. A missing role retains index minus one and reaches the existing diagnostic. Form roles and encoded positions remain unchanged.

The table is not another instruction authority. `roles()` remains the canonical ordered form, and the constructor derives the index from that list.

## Frame updates

A scalar destination formerly constructed one frame for the local update and another frame for the program-counter advance. Paired result-slot and ownership moves constructed three frames and two register roots.

`Frame.withLocalAndAdvance`, `withLocals`, and `withLocalsAndAdvance` combine those operations. `LocalRegisters.withPair` clones the outer chunk table once and clones each touched chunk once. If both locals occupy one chunk, the method clones that chunk once.

The methods retain immutable frames. Rewind records and snapshots continue to share immutable prior roots.

## Owned storage

Every transition still runs `VmPreflight.validate` before mutation. The old execution helpers repeated registration, kind, range, liveness, capacity, map, and UTF-8 checks after preflight had succeeded and before any intervening state change.

`OwnedStore` keeps checked entry points for tests and direct store use. The VM calls narrowly named `AfterValidation` methods only after the same instruction's preflight succeeds. Those methods perform the mutation or read against the already admitted handles and coordinates. Map put and get still resolve their slots during execution because preflight does not return a slot product.

The split covers:

- region and buffer allocation
- word and byte reads and writes
- buffer length
- map membership
- UTF-8 freeze
- buffer and region drop

Validation failure still precedes every mutation. No task, observer, callback, or host effect runs between preflight and execution.

## Evidence

The complete core suite passes under Java 26. It includes invalid handles, wrong kinds, range failures, malformed UTF-8, allocation exhaustion, ownership drop failures, exact rewind, committed transition parity, result slots, calls, snapshots, and observations.

A same-host detached-worktree comparison used `NativeCompilerResolvedReturnCallKindsPhysicalProductExampleTest` as a 277-instruction physical compiler workload. Commit `2b031b10` completed in 286.44 seconds. The single-pass implementation completed in 273.59 seconds. Both produced the exact stage-0 artifact. The measured wall-time reduction is 4.5 percent, while user CPU fell from 323.20 to 299.25 seconds.

The benchmark includes Gradle process and compilation overhead. It therefore understates transition-loop savings and does not replace the fixed complete-closure deadline.

## Rejected transient-buffer experiment

A prototype replaced persistent output pages with a second mutable list implementation during committed execution. It retained snapshot immutability through freeze-on-snapshot copy-on-write.

The extra list shape made the dominant read path polymorphic. The same focused route regressed to 352.87 seconds. An earlier version also copied complete logical capacities and exceeded the task deadline. Both forms were removed. WIP-0158 later keeps one list representation and adds explicit committed chunk ownership inside it. Reads remain monomorphic. Only the admitted no-history write path enters committed ownership.

## Acceptance

- [x] Operand-role lookup has bounded direct indexing derived from canonical forms.
- [x] Single-local updates allocate one frame and one register root.
- [x] Paired updates clone each touched register chunk at most once.
- [x] Covered owned-storage checks run before mutation once per transition.
- [x] Checked `OwnedStore` entry points remain available outside VM dispatch.
- [x] No state change occurs between preflight and admitted execution.
- [x] Rewindable and committed executions retain equal final snapshots.
- [x] Observed committed transitions retain their exact event stream.
- [x] The complete core suite passes.
- [x] Focused physical compiler output remains byte-identical.
- [x] The focused physical route improves under a same-host comparison.
- [x] Every authored file remains below 1,000 lines.

## Rejected alternatives

### Skip preflight during committed execution

Rejected. Committed execution still fails closed before mutation.

### Keep execution checks as defense in depth

Rejected. No state or actor can intervene between preflight and execution. Repeating the same checks adds cost without another trust boundary.

### Mutate frames in place

Rejected. Snapshots, observations, and rewind records require immutable prior frames.

### Cache positions in each instruction

Rejected. Operand positions belong to instruction forms. Per-instruction caches duplicate static form data.

### Keep a transient buffer implementation

Rejected. The second list shape regressed the physical compiler workload and complicated snapshot ownership.

## References

- [WIP-0044](WIP-0044-counted-native-compiler-closure-execution.md)
- [WIP-0115](WIP-0115-root-committed-transition-dispatch.md)
- [WIP-0125](WIP-0125-lazy-committed-root-status-publication.md)
- [WIP-0158](WIP-0158-committed-owned-storage.md)
