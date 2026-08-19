# WIP-0189: Sparse aggregate-operation staging

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-18 |
| Updated | 2026-08-18 |
| Area | Self-hosting compiler, aggregate operations, private staging, bounded work |
| Depends on | WIP-0176, WIP-0181, WIP-0183 |
| Supersedes | Full-capacity aggregate target and owner sentinel initialization |
| Superseded by | None |

## Summary

Initialize private aggregate operation staging only for active operations. Four paths formerly wrote sentinel values through the 256-operation capacity:

- source aggregate owner and case rows
- constructor target rows
- projection target rows
- aggregate body slice descriptor rows

Each path now initializes through `operationCount`.

## Sentinel products

Source owner staging starts aggregate and variant case rows at signed minus one.

Constructor target staging starts aggregate target and variant case tag rows at signed minus one.

Projection target staging starts owner aggregate, variant case tag, and member index rows at signed minus one.

Slice descriptor staging starts each operation descriptor at signed minus one before structural value resolution.

The zero-initialized opcode columns remain unchanged. Every active operation either receives a valid target or retains the sentinel admitted by its operation kind.

## Atomicity

These arrays remain invocation-owned private staging. No caller row changes during initialization.

Each downstream producer validates every active operation and publishes only after its full join succeeds. Inactive staging rows are never read because `operationCount` bounds all consumers.

## Bounds

No capacity changes:

- 256 aggregate operations
- two source owner sentinel rows
- two constructor target sentinel columns
- three projection target sentinel columns
- one slice descriptor sentinel row

Worst-case work remains identical.

## Evidence

Aggregate source-owner, constructor target, projection target, indexed-owner, slice-descriptor, resolved-operand, aggregate-aware source product, and whole-artifact suites cover active sentinels, target resolution, wrong kinds, missing owners, and atomic failure.

The compiler archive contains 3,020,055 bytes with SHA-256 `5354dba091b853d9647fcefa3c749707bebc3f113e110e0a887a565e89ad45c6`. Exact dependent locks name that archive.

`NativeCompilerPhysicalClosureExampleTest` compares all 97 selected artifacts, retained prefixes, and relocations. It links the 233-function, 8,556-instruction subset twice, retains 5,987 local types and 200,384 code bytes, and reproduces SHA-256 `08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac`. Complete evidence passes in 16 minutes and 26 seconds under the unchanged twenty-minute deadline.

## Acceptance

- [x] Source owner sentinels initialize exactly `operationCount` rows.
- [x] Constructor target sentinels initialize exactly `operationCount` rows.
- [x] Projection target sentinels initialize exactly `operationCount` rows.
- [x] Slice descriptor sentinels initialize exactly `operationCount` rows.
- [x] Every consumer remains bounded by `operationCount`.
- [x] Focused target, owner, slice, and artifact tests pass.
- [x] Every selected physical artifact and retained prefix match stage 0.
- [x] Complete evidence remains below twenty minutes.
- [x] Exact dependent locks name the rebuilt compiler archive.
- [x] Documentation, source, line, and layout policy pass.

## Rejected alternatives

### Depend on zero as the absent target

Rejected. Aggregate row zero is valid.

### Remove sentinels after target resolution

Rejected. Operation kinds with absent fields require an explicit value.

### Initialize complete capacities

Rejected. Inactive operations carry no product.

## References

- [WIP-0176](WIP-0176-sparse-aggregate-target-publication.md)
- [WIP-0181](WIP-0181-sparse-aggregate-body-product-transfer.md)
- [WIP-0183](WIP-0183-sparse-aggregate-owner-publication.md)
