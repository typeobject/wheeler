# WIP-0046: Counted native aggregate layout products

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, bytecode, bootstrap, and conformance maintainers |
| Created | 2026-08-08 |
| Updated | 2026-08-08 |
| Area | Self-hosting, aggregates, layouts, compiler products |
| Depends on | WIP-0013, WIP-0028, WIP-0044, WIP-0045 |
| Supersedes | Aggregate-layout work in WIP-0045 |
| Superseded by | None |

## Summary

The native compiler shall transfer aggregate layouts as bounded semantic products. A product is decoded from canonical `.wbc` 1.0, not reconstructed from a retained source lease. Records, fixed arrays, slices, variants, cases, and fields retain their bytecode type codes and source-local owner. Publication occurs only after the complete container and layout tables validate.

WIP-0045 remains responsible for scalar and callable products. This WIP is separate because aggregate layout, recursive type resolution, field ownership, and loan projection form an independent verifier boundary. Putting both boundaries in one proposal made neither boundary easier to audit.

## Problem

A callable signature can name an aggregate without defining its storage. Linking that callable from name and result type alone would leave the backend to guess:

- field order and bytecode type codes.
- fixed-array element type and length.
- variant case order and payload shape.
- owner module and nominal type identity.
- whether a projected owner or loan may escape.

Source flattening appears to answer those questions, but only by retaining the dependency source. It also makes insertion offsets part of accidental identity. Neither property is acceptable in the recovery compiler.

## Requirements

An aggregate product shall:

- derive from a structurally valid canonical `.wbc` 1.0 product.
- bind every row to a nonnegative module owner.
- preserve bytecode type IDs and value type codes exactly.
- preserve record field, variant case, and case-field order.
- distinguish records, fixed arrays, slices, and variants.
- publish bounded counted windows, never sentinels as counts.
- reject malformed headers, directories, ranges, names, and table extents.
- receive an identity only after structural and semantic validation.
- remain usable after the source lease and source-local compiler arena are destroyed.

No aggregate product may introduce a second object format. `.wbc` remains the reversible typed semantic IR.

## Initial bounds

One source-local artifact admits:

- 64 aggregate rows.
- 128 variant case rows.
- 256 member rows.
- 64 bytecode sections.

The packed aggregate table has nine 64-row columns:

```text
kind | owner | type-id | name-index | first-case | case-count |
first-member | member-count | extra
```

Kinds are `1` record, `2` fixed array, `3` slice, and `4` variant. `extra` is the fixed-array length and `-1` for a slice. Anonymous structural types use `-1` as the name index.

The packed case table has four 128-row columns:

```text
aggregate | name-index | first-member | member-count
```

The packed member table has four 256-row columns:

```text
aggregate | case | name-index | value-type-code
```

A record field has case `-1`. An array or slice has one anonymous member carrying its element type. A variant field names its owning case.

These are per-module limits. Closure-wide products shall use counted windows and checked addition rather than multiplying these limits into one permanent arena.

## Validation order

The decoder checks:

1. `WHEELBC\0`, version 1.0, file length, directory width, and directory offset.
2. section count, sorted unique type IDs, required flags, alignment, reserved words, nonoverlap, and in-file ranges.
3. string-table presence and every aggregate, case, and field name index.
4. exact type-section consumption for globals, records, arrays, and slices.
5. exact variant-section consumption for variants, cases, and fields.
6. all product bounds and counted windows.
7. caller publication of counts and identity.

A trap before step 7 leaves the product unpublished. Scratch columns are not metadata and have no identity.

## Ownership and loans

Layout publication does not grant storage ownership. Later verification shall attach these facts:

- constructing an aggregate consumes each owned field exactly once.
- projecting an owned field consumes that field or transfers the enclosing owner according to the instruction form.
- `borrow T` projections retain the aggregate owner.
- `borrow mut T` projections require one exclusive live window.
- neither loan form may escape its caller, region, or aggregate lifetime.
- variant case changes consume the old payload before publishing the new tag.

Those checks operate on product identities and verified instructions. They must not reopen dependency source.

## Recovery consequences

Aggregate products are necessary but not sufficient for promotion. Recovery remains disabled until:

- closure-wide aggregate identities bind package, source-local artifact, owner module, and dependency products.
- callable body relocation consumes aggregate product identities.
- ownership and loan verification passes the complete physical compiler closure.
- stage 1 builds stage 2 byte for byte.
- diverse double compilation agrees with the promoted result.

No `wheeler.bootstrap.yaml` may be added before that evidence exists.

## Implementation status

- [x] A Wheeler-native decoder validates canonical container directories.
- [x] Record, fixed-array, slice, variant, case, and member rows decode into bounded packed columns.
- [x] Record, array, and variant fixtures execute through the native decoder.
- [x] Malformed container magic traps before publication.
- [ ] Every malformed directory and table boundary has atomic rejection evidence.
- [x] `AggregateIdentities.w` binds package, module, artifact, counts, and validated rows under `wheeler-aggregate-module-product-1`. An independent Java digest matches the native result, and an invalid row publishes no bytes.
- [ ] Closure-wide aggregate identities bind header-ranked dependency aggregate identities.
- [x] `CountedAggregateLayouts.w` appends one validated artifact at a time into 4,096 aggregate, 8,192 case, and 16,384 member rows. It rejects duplicate module owners and rebases case and member windows without source.
- [ ] Recursive and mutually recursive nominal layouts resolve or fail closed.
- [ ] Ownership and loan projections verify against aggregate products.
- [ ] Imported callable bodies relocate aggregate type references without dependency source.
- [ ] The complete physical compiler closure compiles from scalar, callable, and aggregate products.

## Rejected alternatives

**Retain the source range as the layout.** A range proves where syntax was found. It does not prove canonical field order, bytecode type codes, or verified storage semantics.

**Use Java `Program` objects as module products.** Java is replaceable stage 0 and cannot own recovery metadata.

**Copy dependency declarations into the root source.** This is source flattening with a smaller name.

**Assign an identity before decoding tables.** That gives malformed metadata a stable name. Validation must precede identity.
