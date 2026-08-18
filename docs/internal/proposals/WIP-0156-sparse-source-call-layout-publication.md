# WIP-0156: Sparse source-call layout publication

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, source calls, local widths, bounded publication |
| Depends on | WIP-0056, WIP-0057, WIP-0148 |
| Supersedes | Full-capacity source-call and statement-width copies |
| Superseded by | None |

## Summary

Publish only active source-call layout rows. `SourceCallLayoutProducts.w` formerly copied all 4,096 statement widths into and out of private staging, all 1,024 resolved call words, and all 256 call-local widths.

The layout product changes only statements that own calls. It now stages and publishes those rows.

## Call rows

For `c` calls, four 256-row columns publish:

- owning callable row
- closed call kind
- source call start
- referenced target row

The product still validates target bounds, argument windows, exact arity, every argument type, result kind, forwarding shape, local width, and total local type count before publication.

## Width rows

Each call owns one source statement. The product stages that statement's measured physical width only after its complete call validates.

After every call validates, it publishes `c` call-local widths and updates only the `c` owning statement rows. Other statement widths retain their prior measured products.

## Atomicity

Target, signature, argument, statement, type, kind, forwarding, and capacity checks finish before caller mutation. Active rows replace prior contents through fixed-capacity coordinates. Any malformed call leaves resolved calls and all width tables unchanged.

## Bounds

No capacity changes:

- 256 source calls
- four resolved call columns
- 4,096 source statements
- seven arguments per call
- 4,096 local type rows

Worst-case work remains bounded by the same call and statement capacities. Modules with few calls no longer copy unrelated statement rows.

## Evidence

`NativeCompilerStructuredCallSourceProductExampleTest` covers local and imported value calls, forwarded calls, void calls, call conditions, declaration calls, qualified calls, reversible calls, loops, and malformed call publication.

`NativeCompilerPhysicalClosureExampleTest` compares every comparable artifact, validates every retained prefix and relocation, links the exact 97-product subset twice, and rejects malformed footer and relocation products. It passes in 19 minutes and 25 seconds under the unchanged twenty-minute deadline. All container counts and the linked identity `9a3fb81e4d75ad52d0ff22deefe636d58d56827ea1de80c1e87a2d96c8c60be9` remain unchanged.

The compiler archive contains 3,006,315 bytes with SHA-256 `a0bd0c9c8537a1f1e6cd21b58c299ce758f0916f03bf9cdf0ee9e94bc8e4fc11`. Exact dependent locks name that archive.

## Acceptance

- [x] Four resolved call columns publish exactly `callCount` rows.
- [x] Call-local widths publish exactly `callCount` rows.
- [x] Only call-owning statement widths are staged and updated.
- [x] Noncall statement widths retain prior measured products.
- [x] Every active row publishes after complete call validation.
- [x] Focused structured call tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] The 97-product linked subset publishes twice with identical bytes.
- [x] The complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Recompute every statement width

Rejected. Source value products already own noncall measurements.

### Publish each call immediately

Rejected. A later malformed call would expose partial layout state.

### Merge call and statement tables

Rejected. Calls and source statements have different ownership and capacities.

### Raise the evidence deadline

Rejected. Noncall statement capacity carries no call layout fact.

## References

- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0148](WIP-0148-sparse-referenced-call-target-publication.md)
