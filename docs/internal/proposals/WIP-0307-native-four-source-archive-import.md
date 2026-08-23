# WIP-0307: Native four-source archive import

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, tools, compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package commands, external source graphs |
| Depends on | WIP-0306 |
| Supersedes | Three-source native archive execution evidence |
| Superseded by | Broader native archive and source-plan profiles |

## Summary

Compile and execute a native package test against all four entries of one exact locked dependency archive.

WIP-0306 established the four-entry archive authority and carried three entries through the package command. This slice fills the declared archive and external-module boundary. It changes no capacity: one local test source plus four imported sources remains below the eight-source compiler ceiling.

## Evidence graph

`NativeMultiEntryExternalFixture` constructs one canonical `demo.dep` library archive with these modules:

- `demo.dep.a` exports `ANSWER_A = 40`.
- `demo.dep.b` exports `ANSWER_B = 41`.
- `demo.dep.c` exports `ANSWER_C = 42`.
- `demo.dep.d` exports `ANSWER_D = 43`.

The root manifest names `demo.dep` as one direct normal dependency. Its test root imports all four modules in canonical order and checks every value independently.

`LockedPackageSet.fixedNativeArchives` returns one archive with four reached entries. Native archive inspection validates all framing, path order, manifest selectors, inner digests, and outer digest. Archive provenance binds the complete bytes to the exact lock row. Source-plan authority then requires every package-qualified source path and exact source byte before native discovery.

The native runner discovers one case, compiles one artifact, executes it once, and publishes four passing assertions.

## Acceptance

- [x] One selected archive contributes exactly four canonical entries.
- [x] Every archive module is reached from a direct root import.
- [x] Native source-plan validation binds all four paths and source byte ranges.
- [x] The fixed compiler accepts one local root and four imported modules.
- [x] One case executes exactly once.
- [x] Four independent assertions pass.
- [x] One-, two-, two-package, and transitive archive fixtures remain covered.
- [x] Tools, package, runtime, conformance, documentation, workspace, and file-length policy pass.

The package archive remains 78,616 bytes with SHA-256 `5e81ede00d728c5c8a435786aea6683a9b69f198f0a6e5384562a554e3210e2c` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The runtime archive remains 435,968 bytes with SHA-256 `e8589d288f18816de39b2c1c7d8b2a81b00ed6b517885a0171e5f4688cb4324a` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Count archive inspection as compiler evidence

Rejected. Structural acceptance does not prove source planning, module linking, artifact compilation, or execution at the boundary.

### Check one aggregate sum

Rejected. Four independent assertions retain one observation for every physical module and make omissions visible.

### Add a fifth module

Rejected. Four is the reviewed archive and external-module capacity. A fifth belongs to a new source-plan profile.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0306](WIP-0306-native-four-entry-archives.md)
