# WIP-0428: Retained semantic-version core comparison product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-29 |
| Updated | 2026-08-29 |
| Area | Self-hosting, semantic versions, precedence |
| Depends on | WIP-0048, WIP-0049, WIP-0426, WIP-0427 |
| Supersedes | Core precedence inside `Semver.w` |
| Superseded by | None |

## Summary

Split semantic-version precedence into core, prerelease, and release owners. Retain `SemverCoreComparison.w` as the 116th physical compiler product. Resolve all six component calls to the retained coordinate owner and preserve major, minor, then patch precedence.

## Problem

After WIP-0427, `Semver.w` still owned complete release precedence. A direct extraction put the core loop and prerelease identifier loop in one function with 172 locals. The physical source compiler composed the expected instruction count but rejected the generated artifact. A smaller core loop also failed when imported component calls appeared inside the loop.

Precedence has three separate boundaries:

1. Fixed core-triplet order.
2. Variable prerelease sequence order.
3. Selection of core order before prerelease order.

Retaining all three in one step hid which boundary failed and made the evidence unnecessarily broad.

## Source split

`SemverCoreComparison.w` owns major, minor, and patch precedence. `SemverPrereleaseComparison.w` owns stable-release and identifier-sequence order. `SemverReleaseComparison.w` selects the first nonzero result. `Semver.w` delegates through the release owner and retains only its public validation and comparison facade. All eight semantic-version owners move under `compiler/packages/semver/`. The parent package directory falls from thirteen files to five.

This WIP retains only the core owner. The next WIPs can admit prerelease and release products independently without changing the public behavior.

## Core order

The owner projects patch, minor, and major pairs through `semverCoreComponent`. It computes each scalar comparison and selects minor before patch, then major before that result. The source names component coordinates zero, one, and two as signed locals before any call. Literal call arguments do not enter an imported argument window.

The fixed three-component surface is deliberately unrolled. Imported calls inside the first bounded loop produced an invalid artifact. Unrolling makes the closed semantic-version arity explicit and gives each relocation a stable source statement.

The owner retains three functions and 128 forward-plus-inverse instructions. Six imported call sites resolve to `SemverCoordinates.w`. Local scalar and first-result calls remain owner-local.

## Evidence

`NativeCompilerSemverPrecedenceCorePhysicalProductExampleTest` retains the callable core owner, compares exact function and instruction totals with stage 0, and requires every coordinate relocation to resolve. Its executable release fixture covers major, minor, patch, stable-versus-prerelease, the canonical prerelease sequence, and equality through the three-owner split.

The selected set contains 96 comparable products and 20 callable products. The linked closure retains 96 non-empty module products, 375 functions, and 13,780 forward-plus-inverse instructions. It contains 326,896 code bytes, 10,506 local-type rows, 607 source strings, and 492 unique strings. The 412,728-byte executable closure has SHA-256 `8b1889aa1b4ad55ec9c2b80c133934d1008d3a690ad482bf537054230b85f09c`.

## Bootstrap identities

The compiler graph contains 394 modules, two externals, and 1,940 imports. Its 184,153-byte canonical manifest has SHA-256 `d5067313ab67176b0ef4419b2f09939ba4b70979a68a63621b5a3f97efebfb8c`. Native validation halts after 77,042,073 transitions. The explicit closure budget rises from 77,000,000 to 78,000,000 transitions. Wheeler SHA-256 consumes the same bytes in 35,246,504 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,227,145-byte compiler archive has SHA-256 `75572a28c3ec73200cb302f4291d0a86eb0a1492dc42d08f0ba824f67311921b`. Every dependent lock names that archive.

## Failure boundary

Reject an invalid component coordinate, literal imported argument, imported call inside the unsupported loop shape, unresolved coordinate identity, signature mismatch, wrong first-result order, coordinate above 255, invalid artifact, or stale graph identity before closure publication. The public comparison contract still requires releases that passed canonical validation.

## Acceptance

- [x] Core, prerelease, and final release precedence have separate owners.
- [x] `Semver.w` contains no comparison policy.
- [x] The package and semantic-version directories stay below ten files.
- [x] Major precedes minor and minor precedes patch.
- [x] Component call arguments are named signed locals.
- [x] Six imported coordinate calls resolve exactly once.
- [x] The core artifact retains three functions and 128 instructions.
- [x] Canonical release precedence executes through the complete split.
- [x] The physical set contains 116 products and 375 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the split source.

## Rejected alternatives

### Retain complete release precedence in one artifact

The composed artifact failed verification and did not isolate the failing loop-call boundary.

### Keep an imported core loop

The component count is fixed at three. The loop adds a source-product limitation without reducing policy or code size.

### Pass component literals directly

The current physical imported-call argument product expects source locals. Naming three constants is explicit and exact.

### Compare patch before major

Patch values may be projected first for straight-line composition, but first-nonzero selection restores major, minor, then patch precedence.

## References

- [WIP-0048](WIP-0048-canonical-native-product-linker.md)
- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0426](WIP-0426-retained-semver-coordinate-product.md)
- [WIP-0427](WIP-0427-retained-semver-identifier-comparison-product.md)
