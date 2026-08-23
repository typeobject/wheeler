# WIP-0302: Native transitive archive closure

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, tools, compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package commands, dependency graphs |
| Depends on | WIP-0301 |
| Supersedes | Direct-only native archive selection |
| Superseded by | Broader native dependency closure transport |

## Summary

Compile one native package test through a locked two-archive dependency chain.

The root may name modules only from its direct normal dependencies. A source in one selected archive may import a module from that archive's direct normal dependency. The adapter follows those source imports, selects the complete second archive, and transports both archives. Wheeler validates archive identities, manifest identities, manifest-to-lock edges, complete source plans, module reachability, compilation, and execution.

This closes the first transitive source path without granting transitive visibility to root source.

## Closure selection

`LockedPackageSet.fixedNativeArchives` now walks module imports instead of partitioning root imports only.

The bounded walk:

1. resolves every root import against a direct normal dependency.
2. reconstructs each candidate archive exactly.
3. admits only complete library source sets of one or two entries.
4. maps each declared module to one locked package.
5. follows an archive source import only when the provider package appears in that archive manifest's normal dependency list.
6. rejects more than two selected archives or four needed modules.
7. requires the root import closure to reach every source in each selected archive.
8. returns archives in canonical package-name order.

An archive entry cannot borrow eligibility from an identical source string in another package. Selection now checks the entry's exact path against its own exported library target.

## Native authority

The adapter finds physical bytes. It does not authorize them.

Wheeler receives both complete archives and the complete lock. WIP-0301 requires `demo.a`'s archived manifest dependency `demo.b` to equal the `demo.a -> demo.b` lock edge. Archive provenance binds both manifests and both archives. Source-plan authority binds every package-qualified path and byte sequence. Module-graph authority then requires the root-to-`demo.a` and `demo.a`-to-`demo.b` import edges.

A root request for `demo.b` still rejects because `demo.b` is not a root dependency. The second archive becomes visible only while resolving the admitted `demo.a` source.

## Evidence

`invokesOneTransitiveLockedImportNatively` builds this graph:

```text
demo.native.external.transitive -> demo.a -> demo.b
```

The root imports `demo.a.constants`. That source imports `demo.b.constants`. The adapter selects two exact archives while a direct root request for `demo.b.constants` returns no selection.

The native runner validates three source modules, discovers one case, compiles it once, executes it once, and publishes one passing assertion. Removing the second archive, changing the lock edge, or treating the transitive module as a root import fails before execution through existing closure gates.

## Acceptance

- [x] Root imports remain limited to direct normal dependencies.
- [x] Archive imports resolve only through that archive's normal dependency names.
- [x] Candidate entries belong to exact exported library paths in their own package.
- [x] Module providers are unique across the bounded locked graph.
- [x] Every selected archive contributes its complete reached source set.
- [x] Selected archives publish in canonical package-name order.
- [x] One direct archive import reaches one transitive archive.
- [x] A direct root request for the transitive package rejects.
- [x] Native framing, provenance, dependency binding, and source-plan closure admit the graph.
- [x] One native case executes once and publishes one assertion.
- [x] Tools, package, runtime, conformance, example, documentation, workspace, and file-length policy pass.

The package archive contains 77,890 bytes with SHA-256 `11303ca1002c26f5f96485a014ebba8477c540c2fb5552ce8876450dd02d30c9` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The runtime archive remains 435,911 bytes with SHA-256 `556819d5f48d4cfbbb945d9ded434be760bada98eba99c45911df35bf88dbf46` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

The conformance archive remains 148,423 bytes with SHA-256 `d59402f860dfcdab293921586004e84987e37f436a0729e5914860004dbbaf8e` and root manifest identity `ab202adc76b1b66cebe525b30e464a30cc2f3ad9e09a4796916643a78601702f`.

## Rejected alternatives

### Expose every locked module to the root

Rejected. Lock closure is not source visibility. Root imports remain constrained by direct manifest dependencies.

### Select dependencies from lock edges alone

Rejected. A lock edge permits resolution but does not prove that a selected source imports the provider module.

### Scan every source in a selected archive as a root

Rejected. That would make unused archive entries create new dependency visibility. Each module enters the walk through one actual import edge.

### Transport loose transitive source files

Rejected. Complete archives are the provenance unit. A subset cannot prove the manifest or omitted entries.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0300](WIP-0300-native-two-package-import.md)
- [WIP-0301](WIP-0301-native-archive-dependency-binding.md)
