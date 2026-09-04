# WIP-0300: Native two-package import

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, tools, compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package commands, dependency graphs |
| Depends on | WIP-0299 |
| Supersedes | One-archive native external import transport |
| Superseded by | None |
| Follow-up | WIP-0301 native archive dependency binding |

## Summary

Compile one native package test against exact sources from two direct locked dependency archives.

The archive frame now carries zero, one, or two complete archives. Each frame binds one package name to one canonical archive. Native transport authority parses their ranges, counts all package-qualified plan sources, validates each archive independently, and requires the sum of committed archive entries to equal the complete external source count.

`TestRunner.w` no longer owns archive frame mechanics. `TestExternalSourceTransport.w` owns framing and archive-set validation, leaving the runner focused on package policy, discovery, compilation, execution, and report reduction.

## Archive-set policy

Each archive retains the WIP-0299 one- or two-entry bound. The first multi-package profile therefore permits up to two archives and four external modules, subject to the existing eight-source compiler-plan ceiling.

For each archive, native authority requires:

- one distinct lock package name.
- exact archive and manifest identities.
- exact manifest package name.
- every committed entry under `dependencies/<package>/<path>`.
- exact source bytes for every committed path.
- no extra plan source under that package prefix.

The transport then compares the total dependency-prefixed plan count with the sum of both archive entry counts. An unframed third package cannot hide behind a valid prefix.

## Adapter selection

`LockedPackageSet.fixedNativeArchives` replaces the one-archive selector. It partitions up to four requested external modules across at most two direct normal dependencies. Each selected archive must contribute its complete exported entry set.

The selector rejects:

- a requested module absent from the direct dependency set.
- a module exported by more than one selected package.
- an archive containing an unrequested source.
- a source outside an exported library target.
- more than two selected archives.
- canonical reconstruction that changes an archive identity.

No compatibility alias remains for the retired single-archive selector.

## Evidence

`invokesTwoLockedExternalPackagesNatively` constructs direct packages `demo.a` and `demo.b`, each with one constant module and one exact archive. The root imports both modules in canonical order and publishes two passing assertions.

The package adapter selects two complete archives. Native framing validates both lock rows and both source paths before discovery. The native compiler then emits and executes one test artifact without Java case names or artifact bytes.

One-package one-entry and one-package two-entry fixtures remain covered through the same archive-list interface.

## Acceptance

- [x] Native framing accepts zero, one, or two complete archives.
- [x] A dedicated runtime module owns archive frame parsing and validation.
- [x] Every archive binds to its own exact lock package row.
- [x] Package-prefix entry counts reject omissions and extras per archive.
- [x] Total external plan count equals the sum of committed entries.
- [x] The adapter partitions requested modules across at most two direct packages.
- [x] Each selected package contributes its complete archive source set.
- [x] Native compilation resolves modules from two package namespaces.
- [x] One case executes once and publishes two assertions.
- [x] Zero- and one-archive transports remain covered.
- [x] `TestRunner.w` remains below 1,000 lines after the framing split.
- [x] Runtime and conformance locks are rebuilt exactly.
- [x] Focused tools, package, runtime, conformance, examples, documentation, workspace, and file-length policy pass.

The package archive remains 71,775 bytes with SHA-256 `53a8b719fc41c8eb37c005a75771daf2eb9f63024dea6317e3863bba92ca5f08` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The runtime archive contains 435,805 bytes with SHA-256 `7575d3d0b4658d8429d2905f9a40ad4fb1bd8dc9f2938839d3b5acec1a194c52` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

The conformance archive remains 148,351 bytes with SHA-256 `5f30ba02abe7eb01b41d7151143cfb62550dfbc68ea85518ea9f342492fbfcc4` and root manifest identity `ab202adc76b1b66cebe525b30e464a30cc2f3ad9e09a4796916643a78601702f`.

## Rejected alternatives

### Keep archive parsing in `TestRunner.w`

Rejected. Framing and execution are separate authorities, and the runner was growing toward the file limit.

### Validate only the total source count

Rejected. Each package prefix must equal its archive entry set.

### Merge the two archives before transport

Rejected. That would erase package, manifest, and lock-row identities.

### Preserve the one-archive selector

Rejected. One archive is the size-one case of one archive-list authority.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0299](WIP-0299-native-two-source-archive-import.md)
- [WIP-0301](WIP-0301-native-archive-dependency-binding.md)
