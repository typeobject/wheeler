# Proposal workflow

[Proposal guide](index.mdx) · [Open work](roadmap.md)

## Choose the right record

A WIP records a decision that crosses an observable contract or an ownership
boundary. Write one for changes to syntax, types, effects, proofs, machine state,
bytecode, persistence, package identity, capabilities, determinism, or failure
behavior. Name the affected owner and acceptance gate before designing an API.

A patch does not need a WIP just because it helps self-hosting. Ordinary helper
extraction, private cleanup, focused tests, and documentation maintenance belong
in the owning WIP's checklist. Keep commit-by-commit history in Git.

Use the [design template](TEMPLATE.md) for a new contract. Use the shorter
[implementation record](RECORD-TEMPLATE.md) for a stage that needs its own
reviewable boundary. Link its parent and state what remains outside that stage.
Neither template requires boilerplate about unchanged subsystems.

## Status

| Status | Meaning |
| --- | --- |
| Draft | The problem or design still needs decisions. |
| Review | The contract, migration, and acceptance suite are ready for review. |
| Accepted | Maintainers approved the decision. Implementation has not started. |
| Implementing | Work is underway. The remaining checklist names verifiable outcomes. |
| Implemented | The stated tests, docs, migration, and required deletion are complete. |
| Superseded | A later numbered decision replaces the whole contract. |
| Withdrawn | The proposal will not proceed. |

Only maintainers approve acceptance, completion, replacement, or withdrawal.
A material semantic change returns an accepted decision to Review. A Draft may
contain working experiments or completed child records without claiming approval
of the whole design. Do not change statuses merely to tidy the catalog.

## Metadata and links

Every numbered record has a title, status, owners, created and updated dates,
area, dependencies, and replacement fields. Dates use `YYYY-MM-DD`.

- `Depends on` names hard prerequisites. Keep the graph closed and acyclic.
  A dependency on an umbrella WIP may mean its named substrate, not completion
  of every future clause. State that narrower dependency in the design.
- `Supersedes` names a replaced contract or implementation. Whole-WIP replacement
  links back to a Superseded record.
- `Superseded by` names the replacement of the entire decision. Otherwise use
  `None`.
- Optional `Follow-up` names extensions, scoped replacements, or remaining work.
  It does not change status or add a hard dependency.
- References connect related but nonblocking work.

Once a record leaves Draft, its number and filename stay fixed. Preserve those
paths when reorganizing navigation. A Draft may split or move, but update all
links in the same patch and leave no redirect copy. Never reuse an allocated or
removed number. Choose the next number after the highest allocated number.

Add each record to exactly one [topic catalog](index.mdx#catalog). Open records
also appear in [the roadmap](roadmap.md), with a short remaining gate rather than
a duplicate checklist. Catalog entries use the exact title and status from the
record. Tests check this agreement.

## Review and implementation

1. State current behavior, the problem, and the proposed observable result.
2. Assign one owner to each mutable state and semantic boundary.
3. Specify validation order, resource bounds, atomic publication, and failure.
4. Define applicable forward, inverse, rewind, replay, and proof laws separately.
5. Name old code, formats, and adapters that the change deletes.
6. Define positive, negative, boundary, and end-to-end acceptance evidence.
7. Split independent decisions before implementation, not after the checklist
   becomes a changelog.
8. Update the owning checklist, current manuals, examples, and tests in the patch
   that supplies the evidence.
9. Mark completion only within the verified scope. An executable subset does
   not prove full self-hosting.

Keep completed evidence attached to its original milestone. Later changes may
correct errors or add a scoped follow-up link. Do not repin every old WIP when a
compiler archive changes. Current identities belong in tests and locks, with one
status page pointing to them.

## Shared IR invariant

Canonical `.wbc` 1.0 is Wheeler's sole semantic artifact. It contains the closed
typed IR required by the selected target: classical register and region bodies,
reversible relations and inverse bodies, hybrid workflows, backend-neutral
quantum regions, effects, ownership, proofs, and bounds.

WIP-0029 may add non-executable generic typed bodies as a versioned library
section inside `.wbc`. It does not create a source-template or host-object
authority.

Every operation declares the relation it actually supports:

- an intrinsic or checked inverse for information-preserving classical work
- bounded logged history for destructive work that permits VM rewind
- a barrier for irreversible host observation
- an exact finite permutation for coherent classical lifting
- an adjoint-bearing semantic region for unitary quantum work
- an explicit measurement, reset, target, or workflow transition across domains

Do not treat rewind as inverse, replay as physical reversal, compensation as
uncomputation, a provider circuit as semantic IR, or an annotation as proof.
Host ASTs, JVM bytecode, LLVM IR, native objects, and provider payloads are derived
implementation data. Verified Wheeler IR remains authoritative.
