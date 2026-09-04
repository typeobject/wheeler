# WIP-0492: Retained package-manifest target source-row traversal

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-04 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package manifests, source selectors |
| Depends on | WIP-0483, WIP-0486, WIP-0491 |
| Supersedes | Aggregate-parser source-row recognition and stride |
| Superseded by | None |

## Summary

Move source-row recognition and cursor advancement behind the retained collection boundary. The aggregate parser now asks `manifestTargetSourceFollowingRow` for the next token. It no longer imports source-row syntax or advances a source cursor directly.

## Contract

`manifestTargetSourceFollowingRow` receives the current candidate row token. It first calls `manifestTargetSourceRowValid` over the bounded token columns. A non-source row returns the negative tail marker without advancing. A valid source row calls `manifestTargetNextSourceRowToken` and returns the exact following token.

The parser invokes entry admission and publication only when the returned token is nonnegative. It publishes the current row, composes coverage, advances count and predecessor state, and then installs the retained following token. The row that terminates the collection remains untouched for target-tail parsing.

A malformed source row follows the same closed path as before: source traversal stops at that token, and target completion rejects it because it is not a valid required tail. An explicit empty collection reaches completion with zero rows and fails before tail parsing.

## Physical evidence

`NativeCompilerPackageManifestTargetSourceCollectionPhysicalProductExampleTest` compiles all six collection functions from the canonical archive and compares their complete function and instruction prefixes with stage 0. Eight imported-call relocations resolve exactly. The two new edges bind source-row syntax and source-row stride; the prior six bind selector projection, row capacity, strict order, root coverage, selector start, and selector length.

`NativeManifestExampleTest` compares parsed target and source products with stage 0. Valid first and later source rows advance to the exact required test tail. Malformed source keys, empty lists, duplicate or reversed selectors, and absent root coverage remain fail-closed.

The physical set remains 112 comparable products and 51 callable products. A fresh closure run retained 143 non-empty module products, 487 functions, and 16,900 forward-plus-inverse instructions. The linked closure contains 403,056 code bytes, 13,602 local-type rows, 813 source strings, and 651 unique strings. Its 516,056-byte executable has SHA-256 `4d22361d2cda600b7dca502f4826235fbf087bc1fc925edc1a1f1aec49830417`; the closure checksum is `1_294_087_709L`.

## Bootstrap identities

The compiler graph contains 440 modules, two externals, and 2,038 imports. Its 201,041-byte canonical manifest has SHA-256 `901808caf06330785c015aa36dc1d653a8a0bcba06f9d41e6be12d50f875a8a6`. Native validation halts after 85,732,164 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,479,512 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,287,189-byte compiler archive contains 517 entries and has SHA-256 `cbbe5903313b7703c0c9aa06fca300460fc87fdda70d3ce0a54f5681b2d29f58`. Every dependent lock names that archive.

## Failure boundary

Reject a malformed source row as a collection tail without advancing its token. Reject a negative following-row product before entry admission or mutation. Reject a malformed terminal token through retained target completion. Reject unresolved row-syntax or stride relocations before physical artifact publication. Reject stale graph, closure, archive, or dependent-lock identities before execution.

## Acceptance

- [x] One retained function composes row recognition and source stride.
- [x] Invalid rows return a tail marker without cursor advancement.
- [x] Valid rows return the exact following token.
- [x] The aggregate parser no longer imports source-row syntax.
- [x] The aggregate parser no longer advances source rows directly.
- [x] The terminal token remains available to target completion.
- [x] Eight imported calls resolve in the physical collection product.
- [x] Native and stage-0 manifest products remain identical.
- [x] Complete closure evidence includes retained row traversal.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the change.

## Rejected alternatives

### Return only a row-valid Boolean

That would leave stride ownership in the aggregate parser. Recognition and advancement describe one row boundary and belong in one retained product.

### Advance before validating the row

The terminal token belongs to the next grammar stage. Advancing it would turn a clean boundary into speculative parsing.

### Treat every invalid row as successful collection completion

Traversal reports only the boundary. Collection completion and the required target tail still decide whether that boundary is legal.

## References

- [WIP-0483](WIP-0483-retained-package-manifest-target-source-row.md)
- [WIP-0486](WIP-0486-retained-package-manifest-target-source-collection.md)
- [WIP-0491](WIP-0491-retained-package-manifest-target-source-entry-publication.md)
