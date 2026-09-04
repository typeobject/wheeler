# WIP-0072: Exact root byte-projection products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-16 |
| Updated | 2026-09-04 |
| Area | Self-hosting compiler, byte buffers, calls, scalar returns |
| Depends on | WIP-0049, WIP-0054, WIP-0057, WIP-0069, WIP-0070 |
| Supersedes | Parser projection for root byte reads and forwarded result calls |
| Superseded by | None |
| Follow-up | WIP-0139 generalizes the product to byte and word buffers |

## Summary

Emit root `long value = owner[index];` declarations from exact source and physical-value products. The compiler requires a byte-backed owner, a signed index, exact square brackets, and the terminal semicolon. It emits the two retained reads, `BYTES_GET`, and the final named-destination move as one four-local product.

`ResultSlotVerifier.w` exercises the complete path. Its seven source callables combine root byte projections, signed arithmetic, ordinary signed comparisons, borrowed byte-view call arguments, and direct result-call forwarding. The resulting 6,040-byte artifact matches stage 0 byte for byte.

## Problem

The direct statement path admitted scalar declarations and root byte mutations, but it rejected a byte read that initialized a root local. The measured source-value product also assigned the old three-local aggregate projection width. A direct emitter could not repair that mismatch after coordinate publication.

The first useful compiler module exposed two adjacent gaps. `ResultSlotVerifier.w` returns signed comparisons and forwards byte-view helper calls directly:

```wheeler
long value = artifact[offset];
return readResultSlotField(artifact, field);
```

The scalar relation product admitted arithmetic only. Source-call arguments retained signed and Boolean types only, and the call layout treated every value call as an assignment with a final destination move. Routing the module without fixing those products would either reject valid source or produce a noncanonical artifact.

## Projection product

The original `DirectByteProjectionProducts.w` accepted only this initializer:

```wheeler
owner[index];
```

Both operands must be identifiers. The owner resolves to `byteview`, `bytes`, or borrowed `bytes`. The index resolves to a signed value. The product maps both defining values through `StructuredSourceCoordinates.w` and emits:

1. `LOCAL_MOVE` for the byte owner
2. `LOCAL_MOVE` for the signed index
3. `BYTES_GET` for the projected octet
4. `LOCAL_MOVE` for the declared destination

The local types are the exact retained owner type followed by three signed types. Local 252 is the highest admitted start for this four-local window. Any missing delimiter, trailing expression, wrong type, unresolved value, or out-of-range coordinate fails before publication.

`SourceValueProducts.w` measures the same four-local window before physical coordinates publish. WIP-0139 removes the byte-only owner. `DirectBufferProjectionProducts.w` retains this byte relation and adds exact owned and borrowed word projections through `WORDS_GET`.

## Signed declaration authority

`DirectStatementProducts.w` no longer carries signed declaration lowering inline. `DirectLongDeclarationProducts.w` owns literal, constant, local, binary, buffer-length, and byte-projection initializers. The split leaves the root dispatcher small and keeps each physical compiler source below 32,768 bytes.

The declaration helper validates `long`, the destination identifier, `=`, the complete initializer, and the semicolon before it accepts an emitted extent. It delegates relation, mutation, and projection details to their single-purpose products.

## Ordinary comparison returns

The shared scalar relation parser admits exact signed `<` and `==` suffixes in addition to arithmetic. Equality requires both adjacent `=` tokens and a complete right operand through the semicolon.

Ordinary comparison returns emit signed left and right locals followed by one Boolean result local. Reversible result products reject comparison operations. A `long` declaration also rejects a comparison initializer until a Boolean declaration product owns that form.

## Forwarded call results

A source return call uses one fewer local than an assignment call. For arity `n`, the canonical product contains `2n + 1` locals:

- `n` retained source reads
- `n` typed transfers or reborrows
- one call result

The final instruction is `RETURN_VALUE`, not a fabricated destination move. `SourceCallLayoutProducts.w` derives this form from the exact measured statement width and publishes bounded call kinds for signed and Boolean forwarding. Code length, local width, instruction windows, local types, and callable return coordinates consume that same kind.

Byte-view arguments retain `TYPE_BYTE_VIEW` and emit `BUFFER_BORROW`. Mutable and borrowed byte or word buffers retain their exact transfer type. The target signature still validates every argument before code publication.

## Failure products

`SourceValueProductPlan` retains the first failing function, statement, and bounded failure code. A successful plan carries minus-one function and statement coordinates and zero failure code. The plan publishes no value or local rows after a failure.

Malformed projection and type fixtures assert that artifact length and publication remain zero. Forwarded calls and comparisons use byte-for-byte stage-0 comparison rather than opcode-only evidence.

## Bootstrap closure

The compiler archive contains 2,926,040 bytes and has identity `c15d6dba12ef7c9525ebf8f0c803ba49fe523fed1f347e7610da572a8756ed15`. The unchanged package manifest identity is `e83091ee70e165f76eefcb2135d2b9620af0906f39affb8a0013e9e60bf894c2`. All four dependent locks name both identities.

The bootstrap module manifest contains 171,396 bytes, 371 modules, two externals, and 1,799 imports. Native validation halts after 71,115,166 transitions under a 73,000,000-transition ceiling.

The 96-product physical subset still contains 228 functions and 8,286 instructions in 246,040 bytes. Its identity is `3d6e88c426f12d34912a1b14120cd59de093c243e101edf9c05efb30b5d6b679`.

## Acceptance

- [x] Root byte projections emit two reads, `BYTES_GET`, and one destination move.
- [x] Byte owner, signed index, exact punctuation, and exact physical coordinates validate before emission.
- [x] Projection code and four local types publish atomically.
- [x] Malformed suffixes, nonbyte owners, and nonsigned indexes publish no artifact.
- [x] Signed `<` and `==` return products match stage 0 byte for byte.
- [x] Forwarded signed call results use `2n + 1` locals and end in `RETURN_VALUE`.
- [x] Byte-view call arguments retain typed reborrow products.
- [x] `ResultSlotVerifier.w` matches its 6,040-byte stage-0 artifact byte for byte.
- [x] The complete physical closure matches stage 0 byte for byte.
- [x] Bootstrap identities, dependent locks, and a fresh workspace build are current.
- [x] Source, documentation, layout, and directory-width policy pass.

## Rejected alternatives

### Reuse aggregate projection widths

Rejected. Root byte reads have one owner read, one index read, one projection result, and one named destination. A three-local window overwrites the next statement coordinate.

### Lower a return call as an assignment followed by a return

Rejected. That form adds one local and eight code bytes. It changes function descriptors, code offsets, and the canonical container identity.

### Treat byte views as signed call arguments

Rejected. The verifier would accept a scalar transfer where stage 0 emits a borrow. Argument type and ownership effects must survive source-product lowering.

### Parse comparisons only in the direct emitter

Rejected. Source-value measurement and direct emission would disagree on the statement width before physical coordinate publication.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
- [WIP-0069](WIP-0069-exact-scalar-return-expression-products.md)
- [WIP-0070](WIP-0070-exact-scalar-declaration-products.md)
- [WIP-0139](WIP-0139-structured-imported-call-product-foundations.md)
