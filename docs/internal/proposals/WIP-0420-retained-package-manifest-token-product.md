# WIP-0420: Retained package-manifest token product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-09-05 |
| Area | Self-hosting, package manifests, structured source products |
| Depends on | WIP-0049, WIP-0052, WIP-0417, WIP-0418, WIP-0419 |
| Supersedes | Stage-0-only `ManifestTokens.w` product evidence |
| Superseded by | None |

## Summary

This milestone retained `wheeler.compiler.packages.manifest_tokens` as the 109th
physical compiler product. It lowered the original bounded hashes, token equality,
byte ordering, and punctuation predicates, with complete stage-0 artifact parity.
The current word policy below replaces those hashes.

## Problem

The package parser required `ManifestTokens.w`, but the module remained outside the physical product set. Its source combined several forms which the bounded product path deliberately does not guess about:

- UTF-8 projections and arithmetic nested inside assignment expressions.
- Indexed reads nested inside arithmetic and conditional relations.
- Early returns from loop bodies.
- Signed negative assignment behind a loop guard.
- Call results embedded directly in returned relations.
- Root conditionals whose child performed work rather than returning one value.

The first rejected statement stopped the whole source product. Keeping a parallel bootstrap implementation would have hidden the gap instead of advancing self-hosting.

## Current token policy

WIP-0049 replaced manifest hashing with exact word codes. `tokenHash`,
`quotedHash`, and `keywordAt` are gone. Length and two base-128 ASCII lanes
identify each fixed spelling without collisions or arithmetic overflow. Unknown
words return zero. This bound applies to the fixed vocabulary, not package names,
paths, quoted values, or source identifiers.

`PackageManifestWords.w` now owns fixed spellings. Token policy delegates through
two imported calls and retains equality, ordering, and punctuation. The split
keeps each artifact inside the existing 32,768-byte module buffer.

## Retained comparison source

`sameTokenText` compares equal-length ranges with a Boolean accumulator. Both local-right less-than guards clear the accumulator. The loop returns it after exhaustion.

`compareTokenText` initializes its result with `leftLength - rightLength` and scans the common prefix from the end toward the beginning. A later write therefore corresponds to an earlier source scalar and wins. Equal prefixes retain the length delta. Callers consume only its sign. `minimumLength` keeps the loop bound exact without an assignment-bearing root conditional.

Quoted and punctuation predicates materialize indexed values before their
conditionals. Their children are exact returns. Literal-left comparisons use
named signed locals, preserving the direct relation contract.

## Compiler change

`DirectLoopBodyProducts.w` now accepts every valid bounded signed-number width for a signed literal assignment. The old `width == 1` check rejected `-1` because its sign and magnitude occupy two semantic tokens. Parsing and range validation remain delegated to `signedNumberValid`. Malformed and overflowing values still fail before emission.

The emitted assignment opcode, local width, and type rows are unchanged. This is a source-recognition correction, not a bytecode extension.

## Evidence

[WIP-0049](WIP-0049-bounded-native-source-product-compilation.md#manifest-composition)
owns the combined exact-word physical pass. It replaces the standalone token
fixture. The following receipts describe the original hash-based product.

Focused structured-source fixtures cover:

- Two UTF-8 scalar projections with distinct signed index locals.
- Reverse UTF-8 comparison with local-right guards.
- Negative signed literal assignment behind a guard.
- Boolean literal assignment behind local-right equality and less-than.
- Rejection of a Boolean right operand.
- A value-returning local call before a root loop.

The package-manifest token module contributes nine retained functions. The selected set now contains 92 comparable products and 17 callable products. The linked closure retains 89 non-empty module products, 289 functions, and 11,210 forward-plus-inverse instructions.

## Historical bootstrap identities

The compiler graph remains at 387 modules, two externals, and 1,931 imports. Its 181,926-byte canonical manifest has SHA-256 `91a35e768288e0f090df2434f7edf23c82c607eb00a96d8eebce1463e12edc0c`. Native validation halts after 75,749,036 transitions. Wheeler SHA-256 consumes the same bytes in 34,817,790 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,204,975-byte compiler archive has SHA-256 `2cbd4f676db92196761fa99a48566de60e447548889fe5578df0959fb5c07754`. Every dependent lock names that archive.

## Failure boundary

Reject malformed UTF-8 calls, unresolved source or index locals, non-UTF-8 text, non-signed indices, coordinates above 255, malformed signed literals, failed physical mapping, over-bound loop locals, malformed conditional children, invalid call products, or a non-verifying artifact before publication. Negative assignment does not weaken signed overflow checks.

## Original acceptance

- [x] Hash loops contain only focused projections, arithmetic declarations, assignments, and updates.
- [x] Token equality and ordering preserve their bounded semantics without loop-body returns.
- [x] Signed negative guarded assignment emits the canonical literal assignment product.
- [x] Embedded call relations are split at the source-product ownership boundary.
- [x] The native artifact passes the Wheeler verifier.
- [x] The complete artifact matches stage 0 byte for byte.
- [x] The physical set contains 109 products and 289 retained functions.
- [x] Manifest, archive, SHA-256, and dependent locks name the retained source.

## Rejected alternatives

### Keep a bootstrap-only token implementation

That would leave the package parser dependent on code which the physical compiler cannot reproduce.

### Return from the comparison loop

Loop-body return products are not part of the bounded profile. Accumulating the result also makes the bound and final publication explicit.

### Treat `-1` as a one-token literal

The scanner exposes sign and magnitude separately. Width checks must follow the scanner contract rather than wish it away.

### Skip artifact verification for the new module

Byte equality is not a substitute for fail-closed publication. The native verifier remains on the publication path.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0417](WIP-0417-utf8-loop-projection-products.md)
- [WIP-0418](WIP-0418-focused-loop-arithmetic-declarations.md)
- [WIP-0419](WIP-0419-local-right-nested-loop-guards.md)
