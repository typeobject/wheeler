# WIP-0420: Retained package-manifest token product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-28 |
| Area | Self-hosting, package manifests, structured source products |
| Depends on | WIP-0049, WIP-0052, WIP-0417, WIP-0418, WIP-0419 |
| Supersedes | Stage-0-only `ManifestTokens.w` product evidence |
| Superseded by | None |

## Summary

Retain `wheeler.compiler.packages.manifest_tokens` as the 109th physical compiler product. Lower its bounded hashes, token equality, byte ordering, and punctuation predicates through the closed structured-source profile. Match the stage-0 artifact byte for byte before publication.

## Problem

The package parser required `ManifestTokens.w`, but the module remained outside the physical product set. Its source combined several forms which the bounded product path deliberately does not guess about:

- UTF-8 projections and arithmetic nested inside assignment expressions.
- Indexed reads nested inside arithmetic and conditional relations.
- Early returns from loop bodies.
- Signed negative assignment behind a loop guard.
- Call results embedded directly in returned relations.
- Root conditionals whose child performed work rather than returning one value.

The first rejected statement stopped the whole source product. Keeping a parallel bootstrap implementation would have hidden the gap instead of advancing self-hosting.

## Source shape

Token hashes now name scalar, width, multiplication, and addition products independently. Every update consumes one resolved local. Indexed lengths and starts are read once before use.

`sameTokenText` compares equal-length ranges with a Boolean accumulator. Both local-right less-than guards clear the accumulator. The loop returns it after exhaustion.

`compareTokenText` initializes its result with `leftLength - rightLength` and scans the common prefix from the end toward the beginning. A later write therefore corresponds to an earlier source scalar and wins. Equal prefixes retain the length delta. Callers consume only its sign. `minimumLength` keeps the loop bound exact without an assignment-bearing root conditional.

Quoted-token hashing follows the same focused projection and arithmetic form. Quoted and punctuation predicates materialize indexed values before their conditionals. Their children are exact returns. Literal-left comparisons use named signed locals, preserving the direct relation contract.

`keywordAt` names the `tokenHash` result before comparing it with the requested hash. The call product owns the signed result local. The following direct relation owns its Boolean result. No instruction is asked to publish two unrelated result types.

## Compiler change

`DirectLoopBodyProducts.w` now accepts every valid bounded signed-number width for a signed literal assignment. The old `width == 1` check rejected `-1` because its sign and magnitude occupy two semantic tokens. Parsing and range validation remain delegated to `signedNumberValid`. Malformed and overflowing values still fail before emission.

The emitted assignment opcode, local width, and type rows are unchanged. This is a source-recognition correction, not a bytecode extension.

## Evidence

`NativeCompilerPackageManifestTokensPhysicalProductExampleTest` compiles the archive source through the native physical pipeline, verifies the produced container, and compares all artifact bytes with stage 0.

Focused structured-source fixtures cover:

- Two UTF-8 scalar projections with distinct signed index locals.
- Reverse UTF-8 comparison with local-right guards.
- Negative signed literal assignment behind a guard.
- Boolean literal assignment behind local-right equality and less-than.
- Rejection of a Boolean right operand.
- A value-returning local call before a root loop.

The package-manifest token module contributes nine retained functions. The selected set now contains 92 comparable products and 17 callable products. The linked closure retains 89 non-empty module products, 289 functions, and 11,210 forward-plus-inverse instructions.

## Bootstrap identities

The compiler graph remains at 387 modules, two externals, and 1,931 imports. Its 181,926-byte canonical manifest has SHA-256 `91a35e768288e0f090df2434f7edf23c82c607eb00a96d8eebce1463e12edc0c`. Native validation halts after 75,749,036 transitions. Wheeler SHA-256 consumes the same bytes in 34,817,790 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,204,975-byte compiler archive has SHA-256 `2cbd4f676db92196761fa99a48566de60e447548889fe5578df0959fb5c07754`. Every dependent lock names that archive.

## Failure boundary

Reject malformed UTF-8 calls, unresolved source or index locals, non-UTF-8 text, non-signed indices, coordinates above 255, malformed signed literals, failed physical mapping, over-bound loop locals, malformed conditional children, invalid call products, or a non-verifying artifact before publication. Negative assignment does not weaken signed overflow checks.

## Acceptance

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
