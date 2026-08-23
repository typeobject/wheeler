# WIP-0308: Native external source-plan bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, tools, compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package commands, external source graphs |
| Depends on | WIP-0307 |
| Supersedes | Four-module native external source transport |
| Superseded by | WIP-0309 native transitive source-plan bound |

## Summary

Fill the native source compiler's eight-source plan with one local test root and seven imported modules from two complete locked archives.

The archive count remains two and each archive remains bounded to four entries. The transport now permits seven committed external entries in total, which is the largest possible external set while every test target retains at least one local source.

## Bounds

The package adapter accepts at most seven nonlocal module imports. Its locked import walk admits at most seven reached modules and still requires every selected archive entry to be reached. The native archive frame admits a combined committed entry count of seven.

The existing compiler gates remain authoritative:

- at most eight source-plan entries.
- at most 32,768 complete plan bytes.
- at most two locked archives.
- at most four entries in either archive.
- at most sixty-four modules in the native graph validator.

A target with two local sources therefore has room for six external entries, not seven. Java checks the complete count before framing, and Wheeler checks the complete plan again before compilation.

## Evidence

`NativeFullExternalFixture` constructs two direct normal dependencies. `demo.a` contributes four complete modules and `demo.b` contributes three. The root imports all seven in canonical module order.

`fillsNativeExternalSourcePlan` requires two selected archives and seven exact archive entries. Native framing validates both archive and manifest identities, both empty dependency-edge sequences, every package-qualified source path, and all source bytes. Module validation then admits one root plus seven imported modules at the eight-source boundary.

The native runner discovers one case, compiles it once, executes it once, and publishes seven independent constant assertions.

## Acceptance

- [x] Root source may request at most seven nonlocal modules.
- [x] Locked archive selection may reach at most seven modules.
- [x] Native framing admits at most seven committed external entries.
- [x] Per-archive count remains bounded to four.
- [x] Two complete archives contribute four and three entries.
- [x] The complete source plan contains exactly eight modules.
- [x] One native artifact executes exactly once.
- [x] Seven independent imported-constant assertions pass.
- [x] Runtime archive and conformance lock are rebuilt exactly.
- [x] Tools, package, runtime, conformance, documentation, workspace, and file-length policy pass.

The runtime archive contains 435,968 bytes with SHA-256 `8976b6f5efa3a8d9df713e888466e11c61efb57da22282aecad8e0a08f09df48` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

The package archive remains 78,616 bytes with SHA-256 `5e81ede00d728c5c8a435786aea6683a9b69f198f0a6e5384562a554e3210e2c` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

## Rejected alternatives

### Permit eight external entries

Rejected. Every native package test target has at least one local root, and the compiler accepts eight total sources.

### Count requested imports without archive closure

Rejected. Selected complete archives, not loose requested module names, determine the committed external source count.

### Merge both archives

Rejected. Separate archive, manifest, package, and lock-row identities remain part of provenance.

### Raise the source plan above eight entries

Rejected. This slice fills the existing compiler capacity. It does not allocate another compiler profile.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0245](WIP-0245-native-eight-source-test-compilation.md)
- [WIP-0307](WIP-0307-native-four-source-archive-import.md)
- [WIP-0309](WIP-0309-native-transitive-source-plan-bound.md)
