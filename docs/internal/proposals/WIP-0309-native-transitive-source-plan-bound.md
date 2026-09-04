# WIP-0309: Native transitive source-plan bound

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, tools, compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-09-04 |
| Area | Self-hosting, package commands, dependency graphs |
| Depends on | WIP-0308 |
| Supersedes | Two-module native transitive archive evidence |
| Superseded by | None |
| Follow-up | WIP-0353 native 40 KiB source-plan bound |

## Summary

Fill the eight-source native compiler plan through one locked transitive package edge.

The root imports four modules from one direct normal dependency. Three of those archive sources import one module each from that package's direct normal dependency. The package adapter follows those edges and selects a second complete three-entry archive. Wheeler validates and compiles the resulting one-local, seven-external module graph.

Root source still cannot import the transitive package directly.

## Graph

`NativeFullExternalFixture.createTransitive` constructs this bounded graph:

```text
demo.native.external.full.transitive -> demo.a -> demo.b
```

`demo.a` contains four complete source entries. Its first three sources import `demo.b.m0`, `demo.b.m1`, and `demo.b.m2`. Its fourth source has no external import. The archived `demo.a` manifest names `demo.b` as one normal dependency, and the schema-3 lock carries the exact `demo.a -> demo.b` edge.

`demo.b` contains the three imported modules. The root manifest names only `demo.a`, and the root source imports only the four `demo.a` modules.

The adapter starts from those four legal direct imports, follows three physical source imports, and reaches seven modules. A root selection containing `demo.b.m0` alone rejects before framing.

## Native evidence

Archive provenance binds both complete archives and manifests to their lock rows. Dependency binding requires the archived `demo.a` dependency name to equal its lock edge. Source-plan authority checks all seven package-qualified paths and exact source bytes. Module authority checks the four root edges and three external-to-external edges before compilation.

`fillsNativeTransitiveSourcePlan` requires two selected archives and seven reached entries. Native discovery compiles one case at the eight-source boundary, executes it once, and publishes four assertions over the directly visible constants. The transitive sources establish graph closure. They do not become root-visible names.

## Acceptance

- [x] Root imports remain limited to four modules from its direct package.
- [x] Three archive source imports reach the complete transitive package.
- [x] The archived dependency name equals the exact lock edge.
- [x] Two selected archives contribute four and three entries.
- [x] The complete native source plan contains eight modules.
- [x] A direct root request for a transitive module rejects.
- [x] Native module validation admits all seven import edges.
- [x] One native case compiles and executes exactly once.
- [x] Four root-visible assertions pass without granting transitive visibility.
- [x] Tools, package, runtime, conformance, documentation, workspace, and file-length policy pass.

The package archive remains 78,616 bytes with SHA-256 `5e81ede00d728c5c8a435786aea6683a9b69f198f0a6e5384562a554e3210e2c` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The runtime archive remains 435,968 bytes with SHA-256 `8976b6f5efa3a8d9df713e888466e11c61efb57da22282aecad8e0a08f09df48` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

## Rejected alternatives

### Import the transitive modules from the root

Rejected. Lock reachability is not root source visibility. The root manifest names only `demo.a`.

### Select `demo.b` from the lock edge alone

Rejected. Physical imports in reached `demo.a` sources drive selection. An unused lock edge grants no module.

### Check transitive constants from the root

Rejected. That would require an illegal root import and erase the visibility property under test.

### Flatten both packages into one archive

Rejected. Package, manifest, archive, and lock-edge identities remain separate evidence.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0302](WIP-0302-native-transitive-archive-closure.md)
- [WIP-0308](WIP-0308-native-external-source-plan-bound.md)
- [WIP-0353](WIP-0353-native-40k-source-plan-bound.md)
