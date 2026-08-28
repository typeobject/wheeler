# WIP-0422: Retained package-path product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-08-28 |
| Updated | 2026-08-28 |
| Area | Self-hosting, package paths, bounded state machines |
| Depends on | WIP-0049, WIP-0052, WIP-0417, WIP-0421 |
| Supersedes | Stage-0-only `Paths.w` product evidence |
| Superseded by | None |

## Summary

Retain `wheeler.compiler.packages.paths` as the 111th physical compiler product. Lower workspace and logical path validation through total bounded state machines. Preserve escape, component, and dot-component semantics without lookahead or loop-body returns.

## Problem

`Paths.w` mixed nested conditionals, an escaped-scalar lookahead, early loop returns, and several literal-left ranges. That shape was valid Wheeler but not a closed structured-source product. The physical compiler correctly rejected it rather than moving cursor updates or component checks across branches.

A path validator cannot discard state to fit the product boundary. Empty components, `.` and `..`, trailing separators, trailing escapes, NUL, and doubled backslashes must remain distinct failures.

## Workspace paths

Workspace validation uses signed state zero for invalid input, state one for a required value, and state two for a complete value. Slash and dot call one separator transition. A separator from state one is invalid. ASCII letters, digits, dash, and underscore move to state two. Invalid state is absorbing.

`workspacePathScalar` puts the scalar on the left of every half-open range. Dash and underscore are exact equality cases. The helper returns before entering the next range, so the accepted set is unchanged.

## Logical paths

Logical validation tracks three independent signed products:

- Mode zero for invalid input, one for normal input, and two after an escape.
- The current component length.
- The count of dots in that component.

A normal backslash enters escaped mode without changing component counters. The next non-backslash scalar returns to normal mode and contributes normally. A second backslash from escaped mode is invalid. Slash validates the completed component, rejects empty, `.` and `..`, then resets both counters. NUL enters invalid mode.

The loop computes next mode, next component length, and next dot count from the same prior row before assigning any of them. This preserves the former lookahead semantics while making update order explicit. Final validation requires normal mode, a nonempty component, and a component other than `.` or `..`.

`invalidDotComponent` names its length and dot relations before Boolean-source conditional returns. It no longer embeds a computed relation in a conditional child.

## Evidence

`NativeCompilerPackagePathsPhysicalProductExampleTest` compiles the archive source through the native physical pipeline. The Wheeler verifier accepts the result and every byte matches stage 0.

The selected set contains 94 comparable products and 17 callable products. The linked closure retains 91 non-empty module products, 317 functions, and 12,120 forward-plus-inverse instructions. It contains 286,600 code bytes, 8,993 local-type rows, 539 source strings, and 429 unique strings. The 359,712-byte executable closure has SHA-256 `2cbec7e1bedc1c39753c557b4bf38fc367e1fb72c904aaf1c6759ebc70b880df`.

## Bootstrap identities

The compiler graph remains at 387 modules, two externals, and 1,931 imports. Its 181,926-byte canonical manifest has SHA-256 `52fe57ace3db0aba7f283703f56357495f282af8175f5f5f7626e7d1f598f199`. Native validation halts after 75,749,054 transitions. Wheeler SHA-256 consumes the same bytes in 34,817,790 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,208,481-byte compiler archive has SHA-256 `f75c58d57937749ca0785a8b075c8093a1bbf63b2d93041f7b6afb886246cc72`. Every dependent lock names that archive.

## Failure boundary

Reject an empty path, invalid workspace scalar, empty component, `.` or `..` component, NUL, doubled backslash, trailing escape, trailing separator, malformed UTF-8 projection, unresolved transition call, coordinate above 255, invalid artifact, or stale source identity before publication. Invalid mode remains invalid through the loop tail.

## Acceptance

- [x] Workspace separators use one closed transition.
- [x] Logical escape mode replaces lookahead without changing cursor semantics.
- [x] Component length and dot count update from one prior row.
- [x] Invalid mode is absorbing.
- [x] Every loop iteration has one named scalar and width product.
- [x] The native artifact passes the Wheeler verifier.
- [x] The complete artifact matches stage 0 byte for byte.
- [x] The physical set contains 111 products and 317 retained functions.
- [x] Manifest, executable closure, archive, SHA-256, and locks name the new source.

## Rejected alternatives

### Keep escaped-scalar lookahead

Lookahead performs a second projection and cursor update inside one branch. Explicit mode gives each source scalar one iteration and one update.

### Flatten component checks into one packed integer

Packing would require division or another coordinate codec. Three signed locals are clearer and remain well inside the bounded frame.

### Accept a trailing escaped mode

A terminal backslash has no scalar to quote. Final validation requires normal mode.

### Treat all dots as separators

Logical paths permit ordinary dotted components. Only slash ends a component. Workspace paths retain their separate dot-separator rule.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0052](WIP-0052-bounded-native-structured-loop-products.md)
- [WIP-0417](WIP-0417-utf8-loop-projection-products.md)
- [WIP-0421](WIP-0421-retained-package-name-product.md)
