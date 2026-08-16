# WIP-0082: Exact Boolean equality products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-08-16 |
| Area | Self-hosting compiler, Boolean values, scalar relations |
| Depends on | WIP-0069, WIP-0080 |
| Supersedes | Signed-only equality validation in ordinary direct scalar products |
| Superseded by | None |

## Summary

Admit exact equality between two preserved Boolean sources in ordinary direct return and declaration products. Equality emits two retained Boolean reads, `LOCAL_EQ`, and either `RETURN_VALUE` or the named declaration move.

The product keeps Boolean ordering invalid and keeps every reversible comparison invalid.

## Problem

`DirectScalarRelations.w` already retained exact source types for both operands. The ordinary type validator rejected every comparison whose left source was not signed. That rule correctly rejected Boolean less-than, but it also rejected Boolean equality:

```wheeler
boolean same = left == right;
return left == right;
```

A caller could express the same operation through stage 0 or structured loop products, leaving duplicate behavior at a callable root.

## Type rule

An ordinary Boolean equality relation requires:

- `OPCODE_LOCAL_EQ`
- `RESULT_RELATION_BINARY_SOURCES`
- `TOKEN_BOOLEAN` on the left
- `TOKEN_BOOLEAN` on the right

No immediate form enters this product. Boolean literals remain declaration products or source values, not fabricated signed immediates.

Signed equality keeps its existing source-source, source-constant, and source-literal forms. Boolean less-than and mixed signed/Boolean equality fail before encoding.

`directReturnTypesValid` checks the reversible callable count before the Boolean branch. Reversible equality therefore remains invalid until a reversible Boolean comparison product supplies result-slot and inverse evidence.

## Encoding

A Boolean equality return uses three locals:

1. retained left Boolean
2. retained right Boolean
3. Boolean equality result

It emits two `LOCAL_MOVE` instructions, `LOCAL_EQ`, and `RETURN_VALUE`.

A Boolean equality declaration uses the four-local binary declaration window from WIP-0080. It adds one final `LOCAL_MOVE` from the expression result into the named destination. All four local types are Boolean.

`writeDirectScalarDeclaration` accepts an expected result type. It admits Boolean operand types only for equality with a Boolean expected result. Signed declarations still reject the relation because they pass `TYPE_SIGNED`.

## Atomicity

The relation resolver publishes exact left and right physical locals before type validation. A type mismatch, unsupported operation, malformed semicolon, coordinate overflow, or reversible use leaves direct rows, code, local types, result kinds, and artifact bytes unchanged.

The declaration helper retains its two-local literal and source paths. This product changes only the four-local equality path.

## Evidence

Focused fixtures compare a root Boolean equality declaration and a root Boolean equality return with stage 0 byte for byte. Both operands come from the same preserved Boolean parameter, which still produces two distinct retained local reads.

A Boolean less-than return publishes no artifact. The existing Boolean XOR return fixture remains valid through its separate noncomparison rule.

The complete physical product closure compiles and preserves every selected artifact and linked subset byte after the validator change.

## Bootstrap closure

The compiler archive contains 2,968,247 bytes and has identity `8a9561a333c2614b077f44ab670cf29243cbf7e2692ac99ed839f6159c1ad8ad`. The package manifest identity remains `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`. All four dependent locks name both identities.

The bootstrap module manifest remains 173,585 bytes with 373 modules, two externals, and 1,832 imports. Native validation halts after 72,194,806 transitions under the 73,000,000-transition ceiling.

The 96-product physical subset remains unchanged. It contains 228 functions and 8,286 instructions in 246,040 bytes. Its identity is `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] Ordinary Boolean source-source equality passes exact type validation.
- [x] Boolean equality returns use three Boolean locals and four instructions.
- [x] Boolean equality declarations use four Boolean locals and the named destination move.
- [x] Mixed-type equality and Boolean less-than fail before publication.
- [x] Reversible Boolean equality remains invalid.
- [x] Focused return and declaration fixtures match stage 0 byte for byte.
- [x] The complete physical product closure matches stage 0 byte for byte.
- [x] Compiler archive identities, dependent locks, and bootstrap budgets are current.
- [x] A fresh locked workspace build passes.
- [x] Source, documentation, line, and directory-width policy pass.

## Rejected alternatives

### Treat Boolean values as signed zero and one

Rejected. Boolean and signed locals retain distinct type identities even when their encodings overlap.

### Admit Boolean less-than

Rejected. The language defines Boolean equality and XOR, not an ordering relation.

### Reuse signed immediate comparison

Rejected. A Boolean literal is not a signed immediate product.

### Permit reversible equality through ordinary code

Rejected. Reversible results require explicit presence and payload slots plus inverse evidence.

## References

- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0080](WIP-0080-exact-root-boolean-declaration-products.md)
