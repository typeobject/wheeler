# WIP-0045: Counted native module symbol products

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, package, bootstrap, and conformance maintainers |
| Created | 2026-08-08 |
| Updated | 2026-08-08 |
| Area | Self-hosting, symbols, module linking, compiler products |
| Depends on | WIP-0007, WIP-0017, WIP-0028, WIP-0044 |
| Supersedes | None |
| Superseded by | None |

## Summary

The native compiler shall link counted module products instead of flattening a closure into one larger source. Each completed module publishes bounded declarations, types, values, callable signatures, aggregate layouts, and compiled bodies. Dependents consume those facts through validated import edges. The source lease is then destroyed.

WIP-0044 owns package evidence, closure planning, source leases, and leaf-first order. This WIP owns the semantic product transferred across an edge. The separation matters. A 512-module limit is useful. A 512-source concatenation is not.

## Problem

The seven-frame recovery compiler links scalar declarations by rewriting source text. That proves differential behavior for small graphs. It does not provide a production module format.

Text flattening fails for the physical compiler closure because it:

- repeats transitive declarations at every fan-out.
- makes linked size grow with topology instead of one module.
- ties symbol identity to insertion offsets.
- cannot retain broad dependency frontiers in eight source slots.
- conflates duplicate declarations, qualification, and ambiguity.
- offers no stable owner for records, variants, arrays, loans, or callable bodies.

Raising the linked-source byte limit would postpone the failure and make the bootstrap evidence dearer.

## Goals

- Publish one counted semantic product per validated local module.
- Keep declaration names as immutable archive ranges until an owned identity is required.
- Preserve dependent-header import rank.
- Distinguish local, public, private, qualified, ambiguous, and unresolved names.
- Resolve constants without copying dependency source.
- Carry callable signatures, ownership, and result-slot layouts across arbitrary depth.
- Carry records, variants, fixed arrays, and aggregate layouts without host objects.
- Compile each body against exact product identities.
- Publish a final `.wbc` only after every selected product verifies.

## Non-goals

- Change `.wbc` 1.0 or introduce a second semantic artifact.
- Raise WIP-0044 package or closure limits.
- Keep a compatibility source flattener in the production path.
- Treat a source lease, module product, object fragment, final artifact, or cache record as the same owner.
- Promote recovery bits before fixed-point and diverse-compilation evidence exists.

## Product model

A local module advances through these states:

```text
archive source
    -> staged source lease
    -> declaration product
    -> resolved product
    -> verified body product
    -> released source lease
```

The first product uses counted columns:

```text
ModuleProduct {
    first_symbol[module_count]
    symbol_count[module_count]
    imported_public_count[module_count]

    owner[symbol_count]
    kind[symbol_count]
    visibility[symbol_count]
    name_range[symbol_count]
    type[symbol_count]
    identity[symbol_count]
}
```

An edge does not own another copy of the symbols. It names a completed dependency module and records the visible product count at the dependent's import rank. External package products require the same representation plus a locked package identity.

## Symbol identity

A symbol receives an identity only after its owner module, kind, visibility, canonical name, and complete type shape validate. The identity input is length-delimited and domain-separated:

```text
SHA-256(
    "wheeler-module-symbol-1",
    package instance identity,
    module identity,
    symbol kind,
    canonical name,
    canonical type shape
)
```

Source offsets are evidence ranges, not identities. Declaration order breaks no tie. Equal names in different owners remain different symbols.

## Name resolution

Unqualified lookup checks the local product first, then public symbols from direct imports in dependent-header rank. One candidate resolves. No candidate is unresolved. Several candidates are ambiguous even when their declarations happen to be byte-identical.

Qualified lookup selects one exact imported module before selecting a public symbol. Private symbols never cross an edge. Repeated import paths retain one owner identity and do not create another declaration.

Resolution diagnostics identify the dependent module, source range, requested name, and sorted candidate owner identities. They do not depend on archive order, hash-table order, or allocation addresses.

## Scalar phase

The first phase indexes signed and Boolean constant declarations before the first executable member. It records public and private visibility, owner, source range, and scalar type. A source is copied through one generation-checked active lease, indexed, destroyed, and never retained for a dependent.

A dependent edge receives the completed dependency's public-symbol count only after leaf-first order proves that dependency complete. Values, references, qualification, duplicate candidates, and constant-expression evaluation remain later phases. A declaration index is not a resolved constant table.

## Callable and aggregate phases

Callable products add parameter and result types, loan modes, effects, helper identity, body range, local limits, result-slot layout, and compiled body identity. Aggregate products add ordered field or case identities and exact layout. Fixed-array length is part of type identity.

Primitive owners transfer through unqualified parameters. `borrow T` and `borrow mut T` remain nonescaping loans. A product cannot erase a loan, manufacture an owner, or derive an aggregate layout from a host type.

## Ownership and reversal

Archive and manifest inputs remain shared byte-view loans. An active source slot owns mutable source bytes under one generation. Product columns own copied scalar facts and immutable archive ranges. The final artifact owns no source or product loan.

Indexing and linking are forward compilation. VM rewind may restore machine state while history exists. Releasing a source lease destroys bytes. It is not source-level inverse execution or uncomputation.

No caller column changes until the complete indexing pass succeeds. A malformed declaration, stale lease, count overflow, unresolved owner, or invalid edge leaves publication untouched.

## Limits

The initial product profile admits:

- 512 local modules.
- 3,072 direct imports.
- 16,384 scalar symbol declarations across the closure.
- 256 scalar constants in one module prefix.
- 4,096 semantic source tokens per module.
- 32,768 source bytes per module or active lease.
- eight active source slots, with peak one during declaration indexing.

These are independent capacities. Sixteen thousand symbols do not allocate sixteen thousand source slots.

## Migration

1. Index scalar declaration products from counted closure sources.
2. Give every product and symbol a stable identity.
3. Resolve imported constant references from products.
4. Compile arbitrary counted constant closures without `BoundedGraphPlan`.
5. Add callable signatures and body products.
6. Add records, variants, fixed arrays, and aggregate layouts.
7. Add full ownership and loan checking across imported calls.
8. Compile the physical compiler closure one module product at a time.
9. Delete production source flattening and the small counted adapter.

The seven-frame executor remains differential conformance evidence until step 9. It does not define product capacity or topology.

## Progress

- [x] `ModuleSymbols.w` stages one validated source lease at a time and publishes only after the complete pass.
- [x] Scalar products carry owner, archive name range, kind, visibility, and signed or Boolean type.
- [x] Each local edge records its completed dependency's public-symbol count at header rank.
- [x] A 257-module chain publishes 257 symbols, root import count one, peak source count one, and root generation 257.
- [x] One module publishes exactly 256 scalar declarations. Declaration 257 fails before publication.
- [x] The 227-module physical compiler closure publishes 971 scalar declarations and reaches generation 227.
- [x] Malformed constant syntax leaves product and completion publication untouched.
- [x] `SymbolIdentities.w` gives every scalar product a package-archive-, module-source-, kind-, visibility-, type-, and name-bound SHA-256 identity after complete range validation. Chain endpoints match an independent Java digest.
- [x] Literal and same-module scalar expressions publish values through the existing bounded evaluator.
- [x] `ImportedConstantValues.w` resolves exact unqualified direct-import forwarding from completed products through a 257-module chain. The final value remains 41 without retaining dependency source.
- [ ] Stable compiled module identities publish.
- [ ] General imported constant expressions, qualification, and ambiguity resolve from products.
- [ ] Arbitrary counted constant closures compile without a seven-node plan.
- [ ] Callable products compile.
- [ ] Aggregate products compile.
- [ ] The complete physical compiler closure compiles.

## Acceptance

The WIP is complete when:

- direct, private, shared, redundant, chain, fork, diamond, and mixed scalar graphs match stage 0 without source flattening.
- archive permutation changes no product, diagnostic, transition count, or artifact byte.
- duplicate, private, qualified, ambiguous, and unresolved symbols have differential diagnostics.
- callable and aggregate products preserve exact type, ownership, and layout identities.
- the physical compiler closure compiles within declared product, source-slot, memory, and transition bounds.
- stage 1 compiles byte-identical stage 2, and diverse compilation confirms the promoted source.
- the seven-frame adapter has no production caller.

## Security and trust

Product tables are untrusted until complete validation. Bounds apply before allocation and mutation. Counts cannot wrap. Ranges must remain inside the validated archive. An edge cannot name an unfinished local product. External products must match the lock-selected package instance.

A product identity establishes exact facts. It does not establish source correctness, proof validity, publisher authority, completion durability, or bootstrap diversity.
