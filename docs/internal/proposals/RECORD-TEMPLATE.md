# WIP-XXXX: Bounded implementation decision

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Name or team |
| Created | YYYY-MM-DD |
| Updated | YYYY-MM-DD |
| Area | One primary concern |
| Depends on | Parent WIP and hard prerequisites |
| Supersedes | Replaced implementation or None |
| Superseded by | None |

Use this form only when a stage needs its own reviewable contract, failure
boundary, or acceptance gate. A helper extraction or focused test usually needs
a patch to the parent instead. See the [workflow](workflow.md).

## Boundary

Link the parent contract. State the precise missing behavior this stage closes,
who owns it, and what remains outside the stage. Do not redefine the parent's
completion gate around a smaller fixture.

## Change

Describe inputs, outputs, validation order, publication, and required deletion.
Explain any changed bounds, representation, or failure behavior. Reference the
parent for unchanged semantics rather than repeating its design.

## Evidence

Name focused tests, negative and first-excess cases, and the end-to-end fixture.
State what each proves. Record measured identities only with their exact input
scope. These are milestone receipts, not pins to refresh after unrelated work.

## Acceptance

- [ ] The stated boundary has one implementation owner.
- [ ] Positive, negative, boundary, and integration evidence passes.
- [ ] Required old code is deleted.
- [ ] Docs, examples, identities, and affected locks agree.

Replace generic items with concrete requirements before review.

## Remaining work

Name the still-open parent gate or follow-up decision. Do not imply that this
record completes the compiler, runtime, or language unless its evidence does.
