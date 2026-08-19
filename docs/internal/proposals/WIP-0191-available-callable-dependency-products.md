# WIP-0191: Available callable dependency products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-19 |
| Updated | 2026-08-19 |
| Area | Self-hosting compiler, callable products, dependency views, nominal isolation |
| Depends on | WIP-0045, WIP-0139, WIP-0180 |
| Supersedes | Unfiltered public callable dependency packing |
| Superseded by | None |

## Summary

Publish direct dependency callables only when their complete signature is available to the consuming compiler path. Visibility and availability are separate products.

`CallableDependencyProducts.w` formerly packed every public callable. A primitive source-product compiler could then receive a public function with a nominal parameter or another unsupported signature even when the source never called it. Target-view construction rejected the complete dependency set before call resolution.

The packer now consumes explicit local and external availability columns. It publishes callables that are both public and available.

## Availability

Availability is established before dependency packing. The primitive profile requires a source-independent result type and one source-independent type for every parameter. A nominal peer remains a valid callable product for aggregate compilation, but it is not available to the primitive target view.

A zero availability row means absent from this view. One means available. Other values trap before publication.

The external and local tables remain distinct. Their callable indices occupy separate coordinate spaces, so one mutable availability buffer cannot stand for both.

## Visibility

Private callables remain excluded regardless of availability. Public unavailable callables remain excluded regardless of signature metadata retained elsewhere.

Filtering does not hide a referenced unsupported call. Call resolution sees no matching target and fails before artifact publication. It only prevents unrelated public declarations from poisoning the target view.

## Ordering

Dependency rank, callable identity, and source declaration order remain unchanged among retained products. Filtering removes rows. It does not reorder survivors.

The count pass and publication pass apply the same visibility-and-availability predicate. Their exact counts must agree.

## Bounds

No capacity changes:

- 4,096 local callables
- 4,096 external callables
- sixty-four direct imports
- 512 local modules
- sixty-four external modules

The physical closure fixture owns separate 4,096-row local and external primitive availability columns.

## Evidence

`NativeCompilerCallableDependencyProductsExampleTest` covers available public local and external callables, a public unavailable local callable, a private external callable, dependency ranks, target coordinates, and missing external publication.

The compiler archive contains 3,020,906 bytes with SHA-256 `868ea498445381e20222b3419af1365ac50d69e5ed470619075ca09b03ce2159`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 16 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Local dependency packing requires public visibility and local availability.
- [x] External dependency packing requires public visibility and external availability.
- [x] Count and publication passes use the same predicate.
- [x] Public unavailable callables do not enter primitive target views.
- [x] Local and external availability use distinct owned columns.
- [x] Focused dependency and target-view tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Reject any dependency containing a nominal callable

Rejected. Unreferenced declarations do not invalidate the usable primitive subset.

### Treat visibility as availability

Rejected. Public API and compiler-profile support are different facts.

### Share one mutable availability column

Rejected. Local and external indices are independent and mutable aliases are forbidden.

### Filter during call resolution

Rejected. Target construction must receive a closed, internally valid view.

## References

- [WIP-0045](WIP-0045-counted-native-module-symbol-products.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
- [WIP-0180](WIP-0180-sparse-nominal-projection-publication.md)
