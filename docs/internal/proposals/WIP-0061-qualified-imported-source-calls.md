# WIP-0061: Qualified imported source calls

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and module-product maintainers |
| Created | 2026-08-14 |
| Updated | 2026-08-14 |
| Area | Self-hosting compiler, module names, imported calls |
| Depends on | WIP-0045, WIP-0059, WIP-0060 |
| Supersedes | Qualified-call acceptance in WIP-0059 |
| Superseded by | None |

## Summary

Resolve `module.name::callable(...)` from closed module and callable products. Bind the written qualifier to one direct dependency rank before arity and type checks. Do not reopen dependency source or infer module ownership from packed callable order.

## Problem

The structured scanner currently recognizes the callable identifier immediately before `(`. This is enough for local shadowing and unambiguous imported calls. It cannot distinguish two direct dependencies that export the same name and arity.

The closure already owns canonical module names, direct dependency ranks, callable owners, signatures, and package-bound callable identities. Qualification must join those products. Copying a dependency name from source or treating target-table order as an owner would add a second module authority.

## Products

A qualified call request retains:

- the exact source range from the first module-name byte through the callable name
- the canonical qualifier range
- the callable name range and arity
- the selected direct dependency rank
- the selected package-bound callable identity
- the narrowest containing source statement

The selected target then enters the WIP-0059 dense table and WIP-0060 stub and relocation path.

## Syntax

The admitted form is:

```wheeler
module.name::callable(first, second)
```

The module name contains canonical lowercase identifier segments separated by one dot. Whitespace cannot split `::`. The callable and arguments follow the ordinary call grammar. A qualified spelling never resolves a local callable.

## Invariants

- Only direct dependency module products can satisfy a qualifier.
- Canonical module identity establishes the dependency rank.
- Equal callable names in other ranks do not create ambiguity.
- A missing, duplicate, indirect, stale-package, private, or malformed target publishes nothing.
- Qualified and unqualified scans share statement binding, argument products, typed layout, code windows, and relocation emission.
- Source-call publication remains atomic.

## Bounds

- 64 direct imports per source module
- 256 source calls per module
- 256 bytes per canonical module or callable name
- seven arguments per call
- 4,096 callable products in the admitted target view

## Implementation

`ImportedCallQualifierProducts.w` joins each imported target's callable owner to one canonical module-name product and retains the direct dependency rank. It rejects a rank that names callables from two module owners and stages complete names, starts, lengths, and ranks before publication. Dependency source is absent from the API.

## Plan

1. [x] Copy direct dependency module names beside their closure ranks.
2. Recognize the bounded `name(.name)*::name(` token shape.
3. Bind the qualifier to one exact direct rank.
4. Match name, arity, parameter types, result kind, effects, and visibility inside that rank.
5. Publish the same call and statement products used by unqualified calls.
6. Prove storage-order independence and atomic malformed-input rejection.

## Acceptance

- Two dependencies may export the same callable name and arity.
- Either canonical qualifier selects its exact package-bound target.
- The equivalent unqualified call remains ambiguous.
- A local callable does not shadow a qualified imported call.
- An indirect dependency qualifier publishes nothing.
- Malformed dots, colons, whitespace, and uppercase segments publish nothing.
- Shuffled dependency and callable storage leaves artifact and relocation bytes unchanged.
- Dependency source is absent from the compilation lifetime.

## Rejected alternatives

### Use import order as identity

Rejected. Source order is validation evidence, not a package or module identity.

### Match a qualified source suffix against callable names

Rejected. A callable name does not prove module ownership.

### Reparse dependency headers

Rejected. Closed module products are the dependency interface.

## References

- [WIP-0045](WIP-0045-counted-native-module-symbol-products.md)
- [WIP-0059](WIP-0059-imported-source-call-target-products.md)
- [WIP-0060](WIP-0060-imported-call-stub-and-relocation-products.md)
