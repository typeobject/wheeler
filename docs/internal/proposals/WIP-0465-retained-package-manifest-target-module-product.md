# WIP-0465: Retained package-manifest target-module product

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-01 |
| Updated | 2026-09-01 |
| Area | Self-hosting, package manifests, target rows |
| Depends on | WIP-0049, WIP-0421, WIP-0463, WIP-0464 |
| Supersedes | Optional module-name validation in `PackageManifest.w` |
| Superseded by | None |

## Summary

Split optional target module-name validation into `PackageManifestTargetModule.w`. The parser retains optional-key presence and passes the projected value token to the new owner. The owner is retained as physical artifact 150 with two resolved policy calls.

## Module field

A target may omit `module`. Presence therefore remains a parser decision: a missing key advances directly to `test`, while a present but malformed field rejects the row. Once present, `manifestTargetModuleValid` requires a quoted token, projects its interior through named locals, and applies canonical module-name grammar.

The caller obtains the key and value coordinates from the WIP-0463 owner before any read. Passing the value coordinate avoids repeating unsupported large cursor additions in the callable product. `PackageManifest.w` no longer imports the broad name authority. Only the focused module owner does.

## Physical route

The module uses the direct imported structured-source route. Its explicit route entry is required because source synthesis is not an implementation of package policy. Quoted-token and module-name relocations resolve to the retained token and name owners before the artifact enters the closure archive.

Earlier signed-state, combined-presence, and inline-coordinate forms stopped at minimal-program publication. The final boundary carries one caller-validated coordinate and one Boolean verdict. It needs no synthetic state and no parser-projected source.

## Evidence

`NativeCompilerPackageManifestTargetModulePhysicalProductExampleTest` compares retained function and instruction counts with stage 0 and closes both policy relocations. `NativeManifestExampleTest` executes valid modular and nonmodular targets and rejects malformed module grammar through the composed parser.

The selected set contains 110 comparable products and 40 callable products. It retains 130 non-empty module products, 448 functions, and 15,995 forward-plus-inverse instructions. The linked closure contains 380,832 code bytes, 12,620 local-type rows, 748 source strings, and 599 unique strings. Its 484,544-byte executable has SHA-256 `5b91a999a69079ee1637ba214f3741e45e1b3781ba3b1cea175563ba58e2c73c`.

## Bootstrap identities

The compiler graph contains 427 modules, two externals, and 2,009 imports. Its 195,945-byte canonical manifest has SHA-256 `20ef9892048bb87fd9f7a806cfea8d5be0d6050ae4d61076739fa31b0194e95a`. Native validation halts after 83,146,794 transitions. The explicit evidence ceiling is 84,000,000. Wheeler SHA-256 consumes the same bytes in 37,499,640 transitions.

The package manifest identity remains `fa7fed6c0057fff3255316b8e027b5dc998d99f3a277f3d39be24431ee1dc7e9`. The 3,266,031-byte compiler archive has SHA-256 `df3394d1c4a72278a66190d22838352aa2dded8adb7dd3ce3794db7325ed5ef9`. Every dependent lock names that archive.

## Failure boundary

Reject a present nonquoted module value or invalid module name before source selectors or target publication. Reject unresolved token or name policy, a stage-0 mismatch, stale graph identity, archive mismatch, or linked-closure mismatch before bootstrap publication.

## Acceptance

- [x] Optional module-name validation has one callable owner.
- [x] Absence remains distinct from invalid presence.
- [x] The caller passes one retained value coordinate.
- [x] Quoted-token and module-name calls resolve exactly.
- [x] Complete target behavior executes through the split owner.
- [x] The retained library matches stage 0 byte for byte.
- [x] The linked closure contains 150 products and 448 functions.
- [x] Manifest, archive, executable, SHA-256, and locks name the split owner.

## Rejected alternatives

### Return signed optional state

Presence and validity have different callers and failure behavior. A signed sentinel obscures both and did not publish through the structured source path.

### Recompute the module token

WIP-0463 already owns target-row coordinates. Passing its result keeps cursor arithmetic out of policy.

### Move optional presence into the validator

A Boolean result cannot distinguish a missing optional field from an invalid present field. The parser needs that distinction to select the nonmodular path.

## References

- [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md)
- [WIP-0421](WIP-0421-retained-package-name-product.md)
- [WIP-0463](WIP-0463-retained-package-manifest-target-row-coordinates.md)
- [WIP-0464](WIP-0464-retained-package-manifest-target-test-product.md)
