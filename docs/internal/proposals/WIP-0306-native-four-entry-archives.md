# WIP-0306: Native four-entry archives

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, tools, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package archives, external source graphs |
| Depends on | WIP-0302 |
| Supersedes | Two-entry native archive authority |
| Superseded by | WIP-0307 native four-source archive import |

## Summary

Raise the bounded native package archive profile from two to four canonical source entries.

The package archive inspector now validates entries through one counted loop. It no longer carries first-entry and second-entry lengths in `ArchiveModel`. A separate `ArchiveEntry` projection names one validated path and source range by ordinal. Archive provenance retains its lock-bound projection type because the fixed compiler does not yet pass imported record results through that module boundary.

Native external source transport admits at most four archive entries in total across its existing one- or two-archive frame. The source compiler retains its eight-source and 32,768-byte plan limits.

## Canonical archive authority

`Archive.w` validates one through four entries under one code path. For every entry it checks:

- complete bounded framing.
- a nonempty canonical ASCII path.
- strict bytewise order after the prior path.
- source length bounds.
- the exact embedded source SHA-256.
- exact agreement with the corresponding canonical manifest source selector.

The inspector requires the final entry to end at the outer payload boundary. The outer archive SHA-256 still covers the complete envelope. A fifth entry rejects at the header before path or source processing.

`ArchiveModel` now carries only manifest length, entry count, package-name length, and target count. Entry-specific fields did not describe the four-entry domain and were deleted rather than extended with another numbered pair.

## External source policy

`LockedPackageSet.fixedNativeArchives` accepts complete library archives of up to four entries. Its import walk still permits at most four reached modules total and at most two selected archives. Every selected source must belong to its own library target and must be reached from a direct root import or admitted locked archive edge.

Wheeler source-plan authority validates each selected ordinal against the complete locked archive. Framing rejects a combined archive entry count above four before allocating archive projections. No loose source or archive subset enters compilation.

## Evidence

`NativeArchiveExampleTest` constructs one canonical four-entry archive. Wheeler validates all entry framing, ordering, digests, manifest selectors, and the final payload boundary. The same authority rejects a canonical five-entry archive at the declared count.

`invokesThreeLockedExternalImportsNatively` transports one complete three-entry dependency archive. The root imports all three modules. Native discovery compiles one case, executes it once, and publishes three assertions over three physical imported constants.

Existing one-entry, two-entry, two-package, and transitive archive fixtures continue through the counted implementation.

## Acceptance

- [x] Canonical archive authority accepts one through four entries.
- [x] One counted path owns framing, ordering, source digests, and payload completion.
- [x] `ArchiveModel` contains no numbered entry fields.
- [x] `ArchiveEntry` projects any validated ordinal through the four-entry bound.
- [x] A canonical four-entry archive passes native inspection.
- [x] A canonical five-entry archive rejects.
- [x] Native external source validation checks up to four complete entries.
- [x] Combined archive frames reject more than four entries.
- [x] The adapter requires every selected entry to be reached.
- [x] A three-entry locked archive compiles and executes one native case with three assertions.
- [x] Package, runtime, and conformance archives and locks are rebuilt exactly.
- [x] Package, runtime, conformance, tools, examples, documentation, workspace, and file-length policy pass.

The package archive contains 78,616 bytes with SHA-256 `5e81ede00d728c5c8a435786aea6683a9b69f198f0a6e5384562a554e3210e2c` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The runtime archive contains 435,968 bytes with SHA-256 `e8589d288f18816de39b2c1c7d8b2a81b00ed6b517885a0171e5f4688cb4324a` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

The conformance archive contains 148,757 bytes with SHA-256 `df096bf1fac18892290c2ba9ad268e1a35afdc03a279b6a6a9420271885c5d56` and root manifest identity `ab202adc76b1b66cebe525b30e464a30cc2f3ad9e09a4796916643a78601702f`.

## Rejected alternatives

### Add third and fourth fields to `ArchiveModel`

Rejected. Numbered fields turn a bounded sequence into an arity staircase and leave every consumer coupled to capacity.

### Accept four entries per archive without a combined bound

Rejected. Two four-entry archives plus one local source would cross the current eight-source compiler profile.

### Select only imported entries

Rejected. The archive and its canonical manifest are the provenance unit. Subsets cannot prove omitted bytes.

### Raise the source compiler limits too

Rejected. This change removes an archive-specific two-entry restriction. It does not justify more compiler input storage.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0299](WIP-0299-native-two-source-archive-import.md)
- [WIP-0302](WIP-0302-native-transitive-archive-closure.md)
- [WIP-0307](WIP-0307-native-four-source-archive-import.md)
