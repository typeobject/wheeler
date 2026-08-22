# WIP-0231: Native source module declarations

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, compiler, and package maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Native testing, source plans, module syntax |
| Depends on | WIP-0009, WIP-0018, WIP-0224, WIP-0230 |
| Supersedes | Root-only native module declaration checks |
| Superseded by | WIP-0232 native source module uniqueness |

## Summary

Require every source-plan payload to carry a canonical dotted module declaration before native hashing or test execution.

WIP-0230 bound the selected root module. Non-root sources remained arbitrary UTF-8. `TestSourcePlan.w` now validates one bounded canonical module preamble in every framed source payload and exports the same parser for root-to-manifest comparison.

## Canonical preamble

A source may begin with zero or more line comments and blank lines. Its first semantic line must be:

```text
module lower.segment_1;
```

Each segment starts with lowercase ASCII. Later bytes may be lowercase ASCII, digits, or underscore. Dots separate nonempty segments. The declaration ends with semicolon and LF.

The accepted comment preamble covers repository `//!` documentation because it is a line comment. Block comments, spaces before `module`, uppercase module segments, CRLF, empty segments, and missing final delimiters reject. This layer validates package module identity, not general source formatting.

## Shared authority

`validCanonicalSourceModule` owns declaration syntax for every plan entry. `sourceModuleMatches` uses the same preamble scanner to compare the selected root declaration with the manifest module range.

`TestManifest.w` no longer carries a second fixed-offset module parser. Deleting that duplicate also permits documented root modules without weakening exact declaration matching.

## Bounds

The preamble scan cannot cross the framed payload. The validator bounds module comparison to 255 bytes and allocates no storage. The existing 32,768-byte total plan limit bounds comments and source text.

A malformed module fails source-plan validation before manifest hashing, source hashing, lock validation, descriptor identity, shard selection, artifact verification, execution, or publication.

## Evidence

The accepted three-module fixture validates `pkg.fail`, `pkg.pass`, and `pkg.runtime`. Root-to-manifest matching still requires exact `pkg.pass` bytes.

`NativeCoverageRunExampleTest` replaces the dot in non-root `module pkg.fail;` with slash. UTF-8, framing, path order, and manifest selection remain valid. Native module syntax owns rejection and leaves output untouched.

The runtime archive contains 214,220 bytes with SHA-256 `6842c27ddad3932d756e94f4eb40535e88bbf16b5609275594c0a2adb3dddb74` and root manifest identity `42cb579e63bea46fd92ce5da3789f9b491b35537a43d50d07fca8139657c3ad5`.

The conformance archive remains 131,032 bytes with SHA-256 `4d5f0721d19dec0bf92e2638f1a72634b4d41a7d92299db914b0b7b26152f2a1`. Its lock names the new runtime archive exactly and retains root manifest identity `e61b80b4bda0b85796342a6cfc66c1a19414ab78d92701ad20b9ac2c7080e1d2`.

## Acceptance

- [x] Every source payload receives canonical module-declaration validation.
- [x] Documenting line comments and blank lines are skipped within the payload.
- [x] Dotted names enforce nonempty lowercase segments.
- [x] Root matching reuses the source-plan parser.
- [x] The old duplicate root parser is deleted.
- [x] A malformed non-root module publishes no output.
- [x] Runtime and dependent archives and locks are rebuilt exactly.
- [x] Package, workspace, documentation, source, and layout policy pass.

## Rejected alternatives

### Validate only the root declaration

Rejected. Every selected source contributes module products and source identity.

### Let compilation discover malformed modules

Rejected. Package source-plan validity precedes compiler syntax and artifact identity.

### Keep a second root parser

Rejected. Two declaration grammars will drift at comments, line endings, or name bounds.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0224](WIP-0224-native-target-source-utf8.md)
- [WIP-0230](WIP-0230-native-root-module-binding.md)
- [WIP-0232](WIP-0232-native-source-module-uniqueness.md)
