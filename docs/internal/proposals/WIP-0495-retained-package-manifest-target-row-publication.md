# WIP-0495: Retained package-manifest target-row publication

| Field | Value |
|---|---|
| Status | Implemented |
| Scope | Self-hosting, package manifests, target rows |
| Supersedes | Aggregate target-row mutation in `PackageManifest.w` |
| Superseded by | None |

## Motivation

The retained target parser validates every field but still copied all ten target columns in the aggregate manifest owner. That left fixed row layout, optional-module encoding, and count advancement outside the physical target products.

Target publication must follow complete parsing, source admission, coverage, capacity, and target-name ordering. A rejected row must not become visible.

## Design

`manifestTargetHeadRowProduct` projects and publishes the kind, name range, and root range. It returns the admitted row index for the tail product.

The tail owner separates modular and nonmodular publication. `manifestModularTargetTailRowProduct` projects the module range and publishes the source window and test bit. `manifestNonmodularTargetTailRowProduct` publishes zero module coordinates and the same required tail. Each function advances the target count only after all five tail columns are written.

The split keeps each retained callable within the established eight-parameter profile and removes conditional coordinate projection from direct source lowering. `PackageManifest.w` retains grammar, failure ordering, and caller-owned table allocation; it no longer knows the target column layout.

## Evidence

`NativeCompilerPackageManifestTargetHeadPhysicalProductExampleTest` compiles the head owner from its physical archive range and resolves seven imported calls. `NativeCompilerPackageManifestTargetTailPhysicalProductExampleTest` compiles both tail products and resolves six imported calls. `NativeManifestExampleTest` covers modular and nonmodular rows, source windows, test bits, ordering failures, and malformed input against stage 0.

The compiler graph contains 440 modules, two externals, and 2,041 imports. Its 201,241-byte canonical manifest has SHA-256 `bed7f66b032cb5d043401cfaf5b6ce865f7cd96ba30ee76fa38d9c7d2fe3796f`. Native validation halts after 85,833,470 transitions under the 86,000,000-transition evidence ceiling. Wheeler SHA-256 halts after 38,516,186 transitions.

The physical set remains 112 comparable products and 51 callable products. A fresh closure run retained 143 non-empty module products, 492 functions, and 17,212 forward-plus-inverse instructions. The linked closure contains 411,160 code bytes, 13,923 local-type rows, 818 source strings, and 656 unique strings. Its 526,056-byte executable has SHA-256 `b1690da2b44c4580bf783671cda6cd8d190d3c089663dfb8bc9a4600125c94a8`; the closure checksum is `2_976_452_002L`.

The compiler archive contains 517 entries and 3,289,733 bytes. Its SHA-256 is `e6a0d670ecd399de00f59cbcd78206876e76ddfa9cac16d06fbf4f8d9b3d5762`. Every dependent lock names that archive.
