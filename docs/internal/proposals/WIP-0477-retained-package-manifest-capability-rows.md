# WIP-0477: Retained package-manifest capability rows

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-02 |
| Updated | 2026-09-02 |
| Area | Self-hosting, package manifests, capability rows |
| Depends on | WIP-0049, WIP-0434, WIP-0471 |
| Supersedes | Direct capability prefix and path composition in `PackageManifest.w` |
| Superseded by | None |

## Summary

Retain complete capability-row validation outside the package-manifest parser. `PackageManifestCapability.w` composes canonical prefix and path policy into one Boolean verdict.

## Row contract

`manifestCapabilityRowValid` first validates the dash, `name`, quoted name, and `path` key sequence. It then validates the quoted capability path. A row is valid only when both retained owners accept it.

The parser keeps row iteration, capacity, adjacent name-and-path ordering, coordinate projection, publication, and diagnostics. It no longer imports capability-prefix policy directly. It retains the path owner for adjacent-row ordering.

## Physical route

The row owner has one function and two imported calls. It takes the direct imported structured-source path and enters the callable product suffix. Prefix and path calls resolve to retained products.

## Evidence

`NativeCompilerPackageManifestCapabilityPhysicalProductExampleTest` compares the retained function and instructions with stage 0 and closes both relocations. `NativeManifestExampleTest` executes canonical capability rows and rejects malformed names, paths, prefixes, and ordering through the composed verdict.

The selected set contains 112 comparable products and 46 callable products. It retains 138 non-empty module products, 477 functions, and 16,524 forward-plus-inverse instructions. The linked closure contains 393,864 code bytes, 13,226 local-type rows, 793 source strings, and 636 unique strings. Its 503,896-byte executable has SHA-256 `d3f642dffffe10df2ca614339619361f1f451bf85596cdbd9ebd868d31bdf175`.

## Bootstrap identities

The compiler graph contains 435 modules, two externals, and 2,023 imports. Its 198,824-byte canonical manifest has SHA-256 `b87f67af5a26e17873c5fb132d500dc19e2557d8fb1266f849fd2a1026e18bc9`. Native validation halts after 84,469,529 transitions under the 85,000,000-transition evidence ceiling. Wheeler SHA-256 consumes the same bytes in 38,050,718 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,280,351-byte compiler archive has SHA-256 `208e16b1656ce20518f9c5361f69b7d2b7deba42bfd3f1115d514f3969de375a`. Every dependent lock names that archive.

## Failure boundary

Reject the row before extracting coordinates when its prefix or path fails. Reject an unresolved field-policy call, stage-0 mismatch, stale graph identity, archive mismatch, linked-closure mismatch, or lock mismatch before bootstrap publication.

## Acceptance

- [x] Complete capability-row validation has one owner.
- [x] The parser no longer imports capability-prefix policy.
- [x] The verdict composes prefix and path checks without mutation.
- [x] Both imported policy calls resolve exactly.
- [x] Valid and malformed capability rows execute through the owner.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 158 products and 477 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the row owner.

## Rejected alternatives

### Fold adjacent ordering into row validation

Ordering needs a previous name and path. One-row grammar has neither and must remain independently reusable.

### Duplicate path validation in the parser

That would preserve the split-brain policy this slice removes and bypass physical relocation evidence.

### Move publication into the validator

Caller-owned tables and counters are parser state. Mutating them would couple grammar to storage layout.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0434](WIP-0434-isolated-package-canonical-row-projections.md)
- [WIP-0471](WIP-0471-retained-package-manifest-capability-coordinates.md)
- [WIP-0476](WIP-0476-retained-package-manifest-dependency-rows.md)
