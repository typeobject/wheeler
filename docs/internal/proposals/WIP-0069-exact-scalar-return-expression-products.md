# WIP-0069: Exact scalar return-expression products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-15 |
| Updated | 2026-08-15 |
| Area | Self-hosting compiler, scalar lowering, return products |
| Depends on | WIP-0049, WIP-0054, WIP-0067 |
| Supersedes | First-token projection of ordinary return expressions |
| Superseded by | None |

## Summary

Lower complete ordinary scalar return expressions from source products. The compiler now emits exact read, constant, binary-operation, result, and terminal-return windows before it publishes a callable artifact.

`TypeKinds.w` enters the physical archive through this route. Its imported descriptor mask resolves from one exact local source-use coordinate. The resulting 568-byte artifact matches stage 0 byte for byte.

## Problem

The first direct return product accepted `return value;`. It also accepted the prefix of `return value & MASK;` and emitted only the read and return. Canonical artifact verification could not detect that semantic omission because the truncated artifact remained structurally valid.

A direct compiler must either lower every token in the statement or publish nothing. Imported constants also need closed name, type, value, resolution, owner, and source-use products. The compiler cannot reopen dependency source to recover a spelling.

## Source product

An ordinary scalar return admits one of these complete forms:

```wheeler
return left;
return left + right;
return left & 268435455;
return left & TYPE_DESCRIPTOR_MASK;
```

The binary operation set is:

- signed add, subtract, multiply, divide, and remainder
- signed or Boolean XOR with equal operand types
- signed AND

The relation parser requires the exact semicolon after the admitted expression. It rejects extra tokens, absent operands, unsupported operators, unresolved names, type disagreement, ambiguous products, and out-of-range coordinates.

Void returns and signed literal returns retain their separate measured forms. Reversible result relations retain result-slot emission and homogeneous reversible effects.

## Physical coordinates

`SourceValueProducts.w` measures return width before callable coordinates publish.

| Relation | Physical locals | Instructions |
| --- | ---: | ---: |
| source | 1 | 2 |
| source and immediate | 3 | 4 |
| source and source | 3 | 4 |
| source and imported constant | 3 | 4 |

A binary return reads the left operand into the first local. It reads or materializes the right operand into the second local, writes the operation result into the third local, and returns that third local. The type table covers the same exact window.

`StructuredSourceCoordinates.w` remains the sole logical-to-physical value authority. `DirectStatementProducts.w` no longer carries its duplicate statement and value mapping implementation.

## Imported constants

`DirectReturnEncoding.w` resolves an imported constant only when one symbol product matches all of:

- the selected physical module owner
- the right operand's exact local source start
- the right operand's exact source length
- a resolved signed scalar type

The archive compiler creates those source-use coordinates before it freezes the local module. The return product never reads dependency source and never compares a reconstructed dependency spelling.

A local value shadows an imported constant. The compiler first resolves the latest visible source value. It consults the imported product only when no local value owns that token.

## Publication

The direct return encoder writes into the private direct-statement staging arena. It reports the next byte, instruction count, local count, and validity as one product. The caller publishes code, local types, result types, physical widths, and statement rows only after every return validates.

The helper rejects destinations above local 255, three-local windows above local 253, unsupported operations, invalid source locals, malformed symbol products, and code extents beyond 262,144 bytes.

## Acceptance

- [x] Ordinary source returns retain their canonical read and terminal return.
- [x] Source-immediate and source-source binary returns publish exact three-local windows.
- [x] Imported signed constants resolve from exact local source-use products.
- [x] Unsupported or truncated binary returns publish no artifact.
- [x] Reversible source, binary-immediate, and binary-source relations retain byte parity.
- [x] `TypeKinds.w` matches its 568-byte stage-0 artifact byte for byte.
- [x] The complete 96-product physical closure matches stage 0 byte for byte.
- [x] The linked 228-function container retains its canonical identity.
- [x] One source-ordered authority maps logical values to physical locals.

## Rejected alternatives

### Accept the first value token

Rejected. A structurally valid artifact can still omit source semantics.

### Recover imported names from dependency source

Rejected. The archive already carries resolved constant products and exact local use coordinates.

### Treat an imported constant as a source local

Rejected. Stage 0 materializes the constant with `LOCAL_CONST`. A source-local move would change both ownership and bytecode.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0067](WIP-0067-exact-physical-loop-value-products.md)
