# WIP-XXXX: Short decision title

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Name or team |
| Created | YYYY-MM-DD |
| Updated | YYYY-MM-DD |
| Area | One primary concern |
| Depends on | None or hard prerequisite WIP numbers |
| Supersedes | None or the replaced contract |
| Superseded by | None |

Follow the [proposal workflow](workflow.md). Remove these instructions before
review. Keep only sections that help explain this decision. Use the shorter
[implementation record](RECORD-TEMPLATE.md) for a bounded stage of an existing
contract, and an ordinary patch for routine maintenance.

## Summary

State the observable decision in one paragraph. Distinguish current behavior
from the proposed result.

## Problem and scope

Name the real failure or missing capability, who encounters it, and why a local
fix is insufficient. Give concrete use cases and explicit non-goals.

## Contract

Define the state, inputs, results, invariants, and canonical ordering. Specify
behavior before encodings or APIs. Name one owner for each mutable state and
semantic boundary.

Explain only the affected relations: forward execution, language inverse,
logged rewind, irreversible effects, coherent permutation, unitary adjoint,
measurement, replay, and proof. Never substitute one for another.

## Design

Describe the chosen representation and data flow. State which facts cross module
boundaries, which remain private, and when results become visible. Cover
concurrency and nondeterministic inputs if they affect this contract.

## Failures and limits

Specify malformed input, arithmetic failure, resource exhaustion, cancellation,
and atomic publication. Say what remains unchanged after rejection. Name the
boundary and unit for each limit.

## Compatibility and bootstrap

Describe artifact, persisted-state, package, and source compatibility changes.
Name required seeds and source provenance when this change enters the recovery
chain. Separate fixed-point, diverse-compilation, and seed-traceability evidence.

## Implementation and deletion

List independently reviewable stages in dependency order. Name the old files,
formats, adapters, or authorities removed by each stage. Link a separate record
only when that stage needs its own decision or acceptance boundary.

## Acceptance

- [ ] Positive behavior crosses the changed module boundary.
- [ ] Malformed input and first-excess bounds reject before publication.
- [ ] Applicable inverse, rewind, replay, or proof laws pass.
- [ ] Independent implementations agree on canonical bytes and diagnostics.
- [ ] Current docs and examples describe the implemented contract.
- [ ] The replaced path is deleted.

Replace these generic items with this proposal's exact tests and deliverables.
Keep each item short and verifiable. Put execution history in the implementing
patch or child record, not inside a growing checkbox.

## Alternatives and open decisions

Explain serious rejected options. Give each unresolved decision an owner and a
review or implementation gate. Write `None` when no design question remains.

## References

Link the parent contract, related decisions, current reference manuals, and
executable evidence. Public reference pages must not rely on an unfinished WIP.
