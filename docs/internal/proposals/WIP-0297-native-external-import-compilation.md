# WIP-0297: Native external import compilation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler package, runtime, compiler, and testing maintainers |
| Created | 2026-08-21 |
| Updated | 2026-08-21 |
| Area | Self-hosting, external imports, native test compilation |
| Depends on | WIP-0296 |
| Supersedes | Composed external source plans without runner authorization |
| Superseded by | Native package adapter archive transport |

## Summary

Compile and execute one native test root that imports one module from one exact locked package archive.

The native test transport now carries an explicit archive count after the package lock. Count zero proves that the source plan contains no `dependencies/` entry. Count one carries the locked package name and complete archive bytes. The runtime accepts that path only when native package authority validates the archive and the source plan contains exactly the archive's sole committed path and source bytes under package qualification.

Java does not supply the imported artifact. The native source compiler resolves the external module, lowers the selected test declaration, compiles it once, verifies it once, executes it once, and reduces the ordinary report row.

## First profile

This slice accepts at most one transported dependency archive. That archive must contain exactly one source entry under the bounded archive profile. The complete source plan may still contain package-local sources, but it may contain exactly one `dependencies/` path.

The runtime checks:

1. the physical manifest and complete lock under existing native policy.
2. the complete source-plan frame and canonical path order.
3. agreement between archive presence and external plan presence.
4. full archive, embedded manifest, package-name, and lock-row identities.
5. exact qualified path and source-byte equality between archive and plan.
6. exact local manifest source inclusion while admitting the checked external entry.
7. module uniqueness, import closure, import order, cycles, lowering, compilation, and execution.

A source plan cannot gain external authority from a package-like path alone. An archive cannot authorize a different path or altered source bytes.

## Manifest selection

A package manifest names its own target sources. It does not list dependency archive entries. `TestManifest.w` now matches each selected local source line against the complete plan and requires every remaining entry to carry the `dependencies/` prefix.

This changes no root authority. The selected root path and module must still come from the package manifest, and the root ordinal remains exact in the merged plan.

## Evidence

The focused runner fixture builds one canonical `demo.dep` archive containing `src/Constants.w`. The root test imports `demo.dep.constants`, reads `ANSWER`, and asserts that its value is 42.

The transport supplies no artifact or case name. Native discovery publishes one case, native compilation links the external constant, and execution publishes one pass. Sending the same external source plan without its archive traps before discovery or compilation.

Existing dependency-free, local-import, descriptor, parameter-row, tag, lock, and coverage-run transports now carry explicit archive count zero and retain their report identities.

## Acceptance

- [x] Test framing distinguishes zero and one dependency archives.
- [x] Zero archives reject every external source-plan path.
- [x] One archive requires exactly one package-qualified external path.
- [x] Native archive authority binds lock, package, manifest, path, and source bytes.
- [x] Root manifest validation admits only checked dependency-prefixed extras.
- [x] Native module validation resolves the external import.
- [x] Native lowering and compilation consume the merged source plan.
- [x] The selected external-import case executes exactly once and passes.
- [x] Omitting archive provenance traps before execution.
- [x] Existing zero-archive transports remain covered.
- [x] Runtime and conformance archives and locks are rebuilt exactly.
- [x] Focused runtime, package, conformance, examples, tools, documentation, workspace, and file-length policy pass.

The package archive remains 71,775 bytes with SHA-256 `53a8b719fc41c8eb37c005a75771daf2eb9f63024dea6317e3863bba92ca5f08` and root manifest identity `4321af51a08dbad7c95cfc255398f2ffe822084352fbe70a7a4b441e3e46e2c9`.

The runtime archive contains 430,019 bytes with SHA-256 `6dae160be8bff40b27937bb2dfbfea190b3998631bfbcc6d64e9f8edaef42383` and root manifest identity `42011c887d887364ca16bc2255bc28374882559192e9ab6dbf5f674ce0ae1f49`.

The conformance archive remains 148,351 bytes with SHA-256 `5f30ba02abe7eb01b41d7151143cfb62550dfbc68ea85518ea9f342492fbfcc4` and root manifest identity `ab202adc76b1b66cebe525b30e464a30cc2f3ad9e09a4796916643a78601702f`.

## Rejected alternatives

### Infer archive absence from source paths

Rejected. Framing declares transport mode before semantic source validation.

### Accept extracted source with a digest string

Rejected. The complete archive and its embedded manifest are provenance evidence.

### Let dependency paths satisfy manifest source lines

Rejected. A root manifest owns only its package-local target source set.

### Add Java-compiled external artifacts

Rejected. This boundary exists to move import compilation authority into Wheeler.

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0018](WIP-0018-integrated-deterministic-testing.md)
- [WIP-0296](WIP-0296-native-external-source-plan.md)
