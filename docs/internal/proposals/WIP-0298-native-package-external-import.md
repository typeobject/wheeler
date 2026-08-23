# WIP-0298: Native package external import

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, tools, compiler, runtime, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, package commands, external imports |
| Depends on | WIP-0297 |
| Supersedes | Package-local-only native package test invocation |
| Superseded by | WIP-0299 native two-source archive import |

## Summary

Run `wheeler test` natively for one package test target importing one module from one exact vendored dependency archive.

The package adapter now distinguishes local and external module imports before building a source plan. One external module may select one direct normal dependency whose canonical archive contains exactly one exported library source. The adapter transports the complete archive and package name. Wheeler validates every semantic identity, authorizes the qualified source plan, compiles the import, executes the case, and renders all report formats.

The adapter does not trust a loose dependency source file. `LockedPackageSet` loads the exact physical vendor closure, verifies archive and manifest identities against the lock, verifies graph closure, and reconstructs byte-identical canonical archive bytes. The native runner then repeats archive, manifest, package-name, path, and source-byte validation.

## Eligibility

The first package-command profile requires:

- one canonical modular test target with no more than seven package-local sources when one external source is present.
- at most one nonlocal imported module.
- one direct normal dependency exporting that module from a library target.
- one canonical dependency archive containing exactly one source entry.
- one through 64 public signed constants and at most one public scalar function in that source.
- a physical nonsymbolic `vendor/` directory containing the exact lock and archive set.

A workspace without an exported vendor closure remains on the stage-0 package path for external imports. Package-local native tests remain independent of vendor material and preserve the existing workspace path.

## Adapter boundary

Java performs physical input work that the native runtime cannot perform without host capabilities:

1. open the exact vendor directory.
2. read and decode the locked archive.
3. find the direct exported source declaring the requested module.
4. reconstruct canonical archive bytes and require the same archive identity.
5. frame package name, archive bytes, and the package-qualified source entry.

It does not authorize the lock, archive identity, manifest identity, source path, source bytes, module graph, test declaration, artifact, outcome, or report. Wheeler owns those decisions.

## Evidence

`invokesOneLockedExternalImportNatively` constructs a standalone package with a physical vendor closure. `demo.dep` exports `demo.dep.constants` from `src/Constants.w`. The root test imports `ANSWER` and asserts 42.

The native package adapter returns one selected, one passed, zero failed, and one assertion. No Java artifact or case name enters the transport.

The test also asks `LockedPackageSet` for the selected source and requires the complete locked direct-export boundary before native invocation. Missing, extra, symbolic, corrupt, identity-mismatched, and graph-mismatched vendor inputs already reject in canonical locked-package tests.

## Acceptance

- [x] The package adapter identifies one external module import without filesystem discovery.
- [x] Only a direct normal locked dependency may supply the module.
- [x] The selected source belongs to an exported library target.
- [x] The physical vendor set equals the complete lock package set.
- [x] Canonical archive reconstruction preserves the locked archive identity.
- [x] The source plan uses `dependencies/<package>/<path>`.
- [x] The transport carries the complete archive, not a digest claim.
- [x] Wheeler repeats archive and source provenance validation.
- [x] Wheeler discovers, compiles, verifies, executes, and reduces one case.
- [x] One selected case passes with one assertion.
- [x] Package-local native workspace tests retain archive count zero.
- [x] Focused tools, package, runtime, conformance, examples, documentation, workspace, and file-length policy pass.

The package archive remains 71,775 bytes with SHA-256 `53a8b719fc41c8eb37c005a75771daf2eb9f63024dea6317e3863bba92ca5f08` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The runtime archive remains 430,019 bytes with SHA-256 `6dae160be8bff40b27937bb2dfbfea190b3998631bfbcc6d64e9f8edaef42383` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

The conformance archive remains 148,351 bytes with SHA-256 `5f30ba02abe7eb01b41d7151143cfb62550dfbc68ea85518ea9f342492fbfcc4` and root manifest identity `ab202adc76b1b66cebe525b30e464a30cc2f3ad9e09a4796916643a78601702f`.

## Rejected alternatives

### Read dependency source beside the root package

Rejected. Only source committed by the exact locked archive is admissible.

### Pass decoded source without the archive

Rejected. Native authority must bind path and bytes to the complete archive and manifest.

### Admit transitive imports

Rejected. Direct package visibility remains mandatory.

### Fall back after a malformed vendor closure

Rejected. Once external native eligibility selects physical provenance, malformed evidence is an error.

## References

- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0275](WIP-0275-native-locked-package-test-gate.md)
- [WIP-0297](WIP-0297-native-external-import-compilation.md)
- [WIP-0299](WIP-0299-native-two-source-archive-import.md)
