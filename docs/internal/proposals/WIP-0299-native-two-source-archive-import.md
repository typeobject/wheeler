# WIP-0299: Native two-source archive import

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, tools, compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package commands, external module graphs |
| Depends on | WIP-0298 |
| Supersedes | Single-entry native package import transport |
| Superseded by | Multi-package native import transport |

## Summary

Compile one native package test against both source entries of one exact locked dependency archive.

The archive count remains one. Archive provenance now requires every committed entry to occur exactly once in the package-qualified source plan with exact path and source bytes. The first profile accepts one or two entries, matching the bounded canonical archive inspector.

The package adapter resolves up to two nonlocal imports. The same direct normal dependency must own both modules, its library target must export both modules, and the archive entry set must equal the requested module set. The adapter does not cherry-pick one file from a larger archive.

## Archive closure

For a two-entry archive, native validation repeats complete archive and lock binding for both ordinals. It then derives both qualified paths and checks both source payloads against the merged plan. The number of `dependencies/` plan entries must equal the committed archive entry count.

This makes omission and substitution terminal:

- omitting one archive entry rejects the plan.
- adding an unrelated dependency-prefixed source rejects the plan.
- swapping source bytes between committed paths rejects the plan.
- selecting only one module from a two-entry archive remains outside this profile.

The native compiler still owns module reachability and import cycles after provenance validation.

## Adapter closure

`LockedPackageSet.fixedNativeArchiveSources` replaces the single-source selector. It accepts one or two requested module names and returns one archive only when:

1. one direct normal dependency owns every requested module.
2. the dependency archive has exactly the requested number of entries.
3. every entry is strict UTF-8 and belongs to an exported library target.
4. every entry declares one unique requested module.
5. canonical reconstruction preserves the locked archive identity.

A match split across dependencies rejects. Transitive, development, and build-only sources remain ineligible.

## Evidence

`invokesTwoLockedExternalImportsNatively` builds `demo.dep` with `src/A.w` and `src/B.w`. Module `demo.dep.a` imports `demo.dep.b`. The root imports both in canonical order. The selected test reads `ANSWER_A` and `ANSWER_B` and publishes two passing assertions.

The package command transports one complete two-entry archive, not two source claims. Native execution publishes one selected, one passed, and zero failed.

The one-entry fixture remains covered and passes through the same archive-set selector and native validator.

## Acceptance

- [x] One archive may commit one or two external sources.
- [x] The requested module set must equal the archive entry set.
- [x] Every source belongs to one direct exported library target.
- [x] Native validation binds every entry path and payload to the archive.
- [x] The external plan count equals the archive entry count.
- [x] Two imported modules retain canonical import and path order.
- [x] Native compilation resolves an external-to-external import edge.
- [x] One case executes once and publishes two assertions.
- [x] The one-source package path remains covered.
- [x] Runtime and conformance locks are rebuilt exactly.
- [x] Focused tools, package, runtime, conformance, examples, documentation, workspace, and file-length policy pass.

The package archive remains 71,775 bytes with SHA-256 `53a8b719fc41c8eb37c005a75771daf2eb9f63024dea6317e3863bba92ca5f08` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The runtime archive contains 430,755 bytes with SHA-256 `fba03ad15dc117bc5d0baec0672fd8c448ae4b1a2e9c0114935fbf4e5cd0b586` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

The conformance archive remains 148,351 bytes with SHA-256 `5f30ba02abe7eb01b41d7151143cfb62550dfbc68ea85518ea9f342492fbfcc4` and root manifest identity `ab202adc76b1b66cebe525b30e464a30cc2f3ad9e09a4796916643a78601702f`.

## Rejected alternatives

### Select a subset from a larger archive

Rejected. Omitted committed sources would leave provenance and module closure ambiguous.

### Transport each source as an independent archive

Rejected. Archive membership is semantic package evidence and must remain intact.

### Resolve the two modules from different direct packages

Rejected. The transport profile carries one archive and one package name.

### Preserve the single-source selector as an alias

Rejected. One archive-set selector owns both bounded cases.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0298](WIP-0298-native-package-external-import.md)
