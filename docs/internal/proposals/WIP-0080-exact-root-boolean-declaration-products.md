# WIP-0080: Exact root Boolean declaration products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-09-04 |
| Area | Self-hosting compiler, Boolean values, declaration products |
| Depends on | WIP-0054, WIP-0056, WIP-0069, WIP-0070 |
| Supersedes | Parser projection for root Boolean declarations |
| Superseded by | None |
| Follow-up | WIP-0082 for Boolean source-source equality |

## Summary

Emit exact root Boolean declarations from a literal, preserved Boolean source, or signed comparison relation. The declaration retains the source expression result and moves it into the named destination, matching stage 0 byte for byte.

`DirectBooleanDeclarationProducts.w` owns syntax, value resolution, physical coordinates, encoding, and local types. `DirectStatementProducts.w` only dispatches the root statement and retains the closed extent.

## Problem

The direct statement path emitted signed declarations but rejected `boolean` at a callable root. Structured loop products could lower several Boolean forms, yet their loop-local coordinates and opcodes cannot serve a root declaration.

A root comparison has four physical values:

```wheeler
boolean before = length < sourceStart;
```

The compiler retains both signed operands, computes a Boolean result, and moves that result into the named local. Omitting the final move changes the named destination identity and every later local coordinate.

Literal and preserved-source declarations use two values rather than four. One broad fixed width would either leave a gap or overwrite the next statement.

## Admitted forms

The product accepts:

```wheeler
boolean ready = true;
boolean copy = ready;
boolean before = left < right;
boolean same = left == right;
```

The declaration requires the `boolean` token, one destination identifier, `=`, one complete initializer, and the exact semicolon. The destination must resolve to the next declared value at the statement ordinal.

Literal initializers accept only `true` and `false`. Preserved-source initializers require a Boolean source. Comparison initializers currently require signed operands and `<` or `==`. Signed arithmetic, signed sources, incomplete relations, and trailing tokens fail before publication.

Boolean equality over two Boolean sources remains outside this product's initial scope. WIP-0082 extends the shared ordinary comparison validator with exact Boolean source-source equality.

## Encoding and widths

A literal declaration emits:

1. `LOCAL_CONST` for the retained Boolean literal
2. `LOCAL_MOVE` into the named destination

A preserved-source declaration emits two `LOCAL_MOVE` instructions. Both forms use two Boolean locals.

A signed comparison declaration emits:

1. `LOCAL_MOVE` for the signed left operand
2. `LOCAL_MOVE` or `LOCAL_CONST` for the signed right operand
3. `LOCAL_LT` or `LOCAL_EQ` for the Boolean expression result
4. `LOCAL_MOVE` into the named destination

The four local types are signed left, signed right, Boolean expression result, and Boolean destination.

`writeDirectScalarDeclaration` now accepts the expected result type. It validates that the operation and left source produce that type before encoding the shared four-local window. Signed declarations pass `TYPE_SIGNED`. Boolean comparisons pass `TYPE_BOOLEAN`. This keeps one binary declaration encoder without letting a `long` declaration accept a comparison.

## Atomicity

The helper stages code and type rows in the enclosing direct statement transaction. It reports no extent after any syntax, type, value, coordinate, or encoding failure. The outer plan then publishes no direct rows, result changes, physical widths, local types, or artifact bytes.

The product checks the two-local and four-local coordinate ceilings separately. It never widens a literal or source declaration to the comparison width.

## Evidence

Focused fixtures compare literal, preserved-source, and signed less-than root declarations with stage 0 byte for byte. Each fixture reads the named Boolean through a following assertion, so the comparison covers the destination move and later local coordinates.

A signed arithmetic initializer publishes no artifact. The complete physical product closure compiles after the helper enters the compiler module graph and preserves every selected artifact and linked subset byte.

## Bootstrap closure

The compiler archive contains 2,967,798 bytes and has identity `1ea503d30c771404d1bfdbaccb71e469d3cfbc3e1c17e31c32bce50f46833445`. The package manifest identity remains `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`. All four dependent locks name both identities.

The bootstrap module manifest contains 173,585 bytes with 373 modules, two externals, and 1,832 imports. Native validation halts after 72,194,794 transitions under the 73,000,000-transition ceiling.

The 96-product physical subset remains unchanged. It contains 228 functions and 8,286 instructions in 246,040 bytes. Its identity is `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] Boolean literal declarations emit two instructions and two Boolean locals.
- [x] Preserved Boolean declarations emit two moves and two Boolean locals.
- [x] Signed less-than and equality declarations emit four instructions and four exact local types.
- [x] The final move preserves the named destination identity.
- [x] Signed arithmetic initializers publish no artifact.
- [x] Signed declaration encoding still rejects comparison results.
- [x] Code, type rows, widths, and failure products publish atomically.
- [x] Focused declarations match stage 0 byte for byte.
- [x] The complete physical product closure matches stage 0 byte for byte under its existing deadline.
- [x] Compiler archive identities, dependent locks, and bootstrap budgets are current.
- [x] A fresh locked workspace build passes.
- [x] Source, documentation, line, and directory-width policy pass.

## Rejected alternatives

### Reuse loop-body Boolean opcodes

Rejected. Loop frames own different local bases, branch windows, and rebasing products.

### Drop the named-destination move

Rejected. The expression result and declared local are distinct source products in stage 0.

### Give every Boolean declaration four locals

Rejected. Literal and preserved-source forms have exact two-local windows. Artificial gaps break contiguous callable type products.

### Let signed declarations consume comparisons

Rejected. A `long` declaration cannot publish a Boolean local. The shared encoder validates an explicit expected result type.

## References

- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0070](WIP-0070-exact-scalar-declaration-products.md)
