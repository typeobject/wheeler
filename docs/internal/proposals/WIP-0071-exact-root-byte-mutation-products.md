# WIP-0071: Exact root byte-mutation products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, byte buffers, root statements |
| Depends on | WIP-0049, WIP-0054, WIP-0067, WIP-0070 |
| Supersedes | Parser projection for root `setByte` statements |
| Superseded by | None |

## Summary

Emit root `setByte` statements from exact source and physical-value products. The compiler now validates all three operands and the terminal punctuation, stages the three local reads, emits `BYTES_SET`, and publishes the matching local types atomically.

`LocalTypeEncoding.w` enters the physical archive through this route. Its three callables combine signed scalar declarations, exact assertions, module constants, root byte mutations, and scalar returns. The resulting 5,096-byte artifact matches stage 0 byte for byte.

## Problem

WIP-0067 closed byte mutations inside structured loops. Root statements still entered only the direct declaration, assertion, call, and return paths. A root `setByte(output, cursor, value);` therefore forced the module back through parser projection.

Simple declarations had a related constant gap. `long typeCode = TYPE_SIGNED;` names a compile-time scalar directly, with no binary right operand. The direct declaration path needed to preserve stage-0 constant precedence and emit `LOCAL_CONST` rather than reject the identifier or emit a local move.

## Source form

The admitted root mutation has one exact form:

```wheeler
setByte(owner, index, value);
```

The source product requires:

- the `setByte` token
- one opening parenthesis
- three identifier operands separated by two commas
- one closing parenthesis
- one semicolon

Extra arguments, expressions, literals, missing punctuation, and trailing tokens fail before emission. Other byte-mutation forms remain outside this proposal.

## Value and type products

`DirectByteMutationProducts.w` resolves each operand against the latest visible source value and maps it through `StructuredSourceCoordinates.w`.

- `owner` must retain `bytes` or borrowed `bytes` type
- `index` must retain signed type
- `value` must retain signed type

The product emits three `LOCAL_MOVE` instructions followed by one `BYTES_SET`. Its physical local window contains the retained buffer type followed by two signed types. The helper stages those type rows beside the instruction bytes and reports the next code and type extents together.

The destination window starts at the precomputed statement physical start. Local 253 is the highest admitted start for a three-local window.

## Constant initializer

A simple signed declaration now consults the closed constant product before a same-named local, matching stage 0:

```wheeler
long typeCode = TYPE_SIGNED;
```

The compiler requires the exact semicolon and emits one `LOCAL_CONST` followed by the named destination move. An unresolved, nonsigned, absent, ambiguous, or suffix-bearing product fails without publication.

## Publication

`DirectStatementProducts.w` delegates mutation validation and staging before it publishes any direct rows. The helper writes only into private code and type arenas. The caller commits statement rows, physical widths, result types, code, and local types after every root statement validates.

The direct statement authority remains below 32,768 bytes. Mutation logic lives in a dedicated source directory rather than widening the monolithic emitter.

## Acceptance

- [x] Root byte mutations emit three reads and one `BYTES_SET` in source order.
- [x] Buffer, index, and value products preserve exact physical locals and types.
- [x] Missing, extra, or expression operands publish no artifact.
- [x] Simple module and imported constants emit `LOCAL_CONST` with exact suffix validation.
- [x] Compile-time constant products retain precedence over same-named locals.
- [x] `LocalTypeEncoding.w` matches its 5,096-byte stage-0 artifact byte for byte.
- [x] The complete 96-product physical closure matches stage 0 byte for byte.
- [x] The linked 228-function container retains its canonical identity.
- [x] Authored source limits and source-directory width policy pass.

## Rejected alternatives

### Treat root mutations as one-statement loops

Rejected. A fabricated control window would change source coordinates, local ownership, and instruction prefixes.

### Emit `BYTES_SET` against existing locals directly

Rejected. Stage 0 emits three retained reads before the mutation, and the artifact local-type window must match those reads.

### Resolve a constant after a same-named local

Rejected. Stage 0 gives compile-time constants precedence during expression lowering.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0067](WIP-0067-exact-physical-loop-value-products.md)
- [WIP-0070](WIP-0070-exact-scalar-declaration-products.md)
