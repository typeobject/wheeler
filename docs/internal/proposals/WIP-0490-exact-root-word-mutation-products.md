# WIP-0490: Exact root word-mutation products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-04 |
| Updated | 2026-09-04 |
| Area | Self-hosting compiler, word buffers, root statements |
| Depends on | WIP-0049, WIP-0054, WIP-0071 |
| Supersedes | Byte-only root buffer-mutation owner |
| Superseded by | None |

## Summary

Emit exact root `set(words, index, value);` statements from direct structured source products. Generalize the byte-only mutation owner into `DirectBufferMutationProducts.w`; byte and word writes now share syntax, value resolution, physical-local planning, type publication, and instruction emission.

## Source form

The direct root statement path admits two exact forms:

```wheeler
set(words, index, value);
setByte(bytes, index, value);
```

The dispatcher hashes the mutation name once and passes an exact word-or-byte verdict to the mutation owner. The owner requires an opening parenthesis, three identifier operands, two commas, a closing parenthesis, and a semicolon. Expressions, literals, extra operands, missing punctuation, and unresolved names fail before staging.

## Type and instruction products

`set` requires an owned or mutable-borrowed word buffer. `setByte` requires an owned or mutable-borrowed byte buffer. Both index and value operands must resolve to signed locals visible before the statement. A word operation with a byte owner, or a byte operation with a word owner, publishes nothing.

Both forms preserve the stage-0 shape: three `LOCAL_MOVE` instructions followed by one ternary storage mutation. The selected storage opcode is `WORDS_SET` or `BYTES_SET`. The physical window retains the exact buffer type followed by two signed types. Local base 253 is the last admitted three-local start, and 104 bytes is the exact code extent.

The caller commits direct rows, function instruction counts, physical widths, code, and local types only after the complete mutation product succeeds.

## Refactoring

The former `DirectByteMutationProducts.w` and `direct_byte_mutation_products` identity are removed. `DirectBufferMutationProducts.w` is the sole root buffer-write owner. The byte path does not survive as a wrapper or duplicate implementation.

## Evidence

`NativeCompilerStructuredComparisonSourceProductExampleTest` compiles root word and byte mutations through both stage 0 and the Wheeler direct source-product compiler, then compares complete artifacts byte for byte. A word write against a byte owner is rejected before artifact publication. Existing malformed byte-mutation evidence remains active.

The selected 163-product physical closure is unchanged because the generalized emitter is compiler machinery rather than a selected artifact. Its prior 486-function, 16,845-instruction executable identity remains pinned by the closure test.

The compiler graph contains 440 modules, two externals, and 2,038 imports. Its 201,041-byte canonical manifest has SHA-256 `fc70880cb958fd2d1e9ed150731c20ad2bb372b618a4e4336b485f5b8f008f03`. Native validation halts after 85,732,525 transitions. Wheeler SHA-256 halts after 38,479,512 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,286,665-byte compiler archive contains 517 entries and has SHA-256 `7c3456b488c574fdfc9d74a88bdaaced053790ced25b1ab36a1c303f37ab73e7`. Every dependent lock names that archive.

## Failure boundary

Reject an unknown mutation hash in the direct-statement dispatcher. Reject malformed syntax, an unresolved operand, a mismatched owner type, a nonsigned index or value, an exhausted local window, or an exhausted code arena before direct-product publication. Reject stale graph, archive, or dependent-lock identities before execution.

## Acceptance

- [x] Root `set` emits exact word-buffer mutation products.
- [x] Root `setByte` retains byte-identical behavior.
- [x] Word and byte owner types remain disjoint.
- [x] Index and value operands require prior signed locals.
- [x] Both forms emit three moves and one typed storage mutation.
- [x] Malformed and type-mismatched forms publish no artifact.
- [x] One generalized owner replaces the byte-only owner.
- [x] Stage-0 and Wheeler-produced artifacts match byte for byte.
- [x] Manifest, archive, SHA-256, and dependent locks reflect the change.

## Rejected alternatives

### Add a second word-only emitter

That would duplicate token, value, local, type, capacity, and publication logic. The storage type and opcode are the only semantic differences.

### Re-hash the mutation token inside the owner

The dispatcher already owns exact keyword classification. Passing its word verdict avoids another graph edge and another scan of the same token.

### Accept arbitrary index and value expressions

The direct root product resolves exact prior locals. Expression lowering belongs in a separate bounded product, not a mutation syntax loophole.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0054](WIP-0054-native-source-product-artifact-integration.md)
- [WIP-0071](WIP-0071-exact-root-byte-mutation-products.md)
