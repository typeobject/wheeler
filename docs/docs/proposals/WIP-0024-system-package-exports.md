# WIP-0024: Canonical install images and system-package export

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler package, release, distribution, runtime, security, and tooling maintainers |
| Created | 2026-07-19 |
| Updated | 2026-07-19 |
| Area | Install images, Debian, RPM, distribution tooling, reproducibility |
| Depends on | WIP-0008, WIP-0009, WIP-0022, WIP-0023, WIP-0026 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler will turn exact verified build outputs into a canonical, format-neutral install image. It will then convert that image into system packages such as `.deb` and `.rpm`.

System packages are deployment artifacts. They do not change source identity, dependency resolution, proof meaning, `.wbc` identity, IR ownership or effects, inverse or adjoint rules, or package PREV.

The pipeline creates an install image, applies one pinned distribution profile and dependency-mapping snapshot, runs one exact sealed adapter, and emits reproducible unsigned package bytes. Signing and publication are separate release effects. The first profile excludes arbitrary maintainer scripts and uses a small typed lifecycle model.

## Motivation

Operating systems control file layout, ownership and conflicts, distribution dependency names, configuration preservation, services, users, state directories, lifecycle behavior, architecture and version fields, signatures, and repository policy. Putting all of that in `wheeler.package.yaml` would mix upstream program meaning with downstream packaging policy.

Ad hoc scripts would bring back ambient tools, host queries, timestamps, and opaque scriptlets. One canonical intermediate keeps adapters mechanical, reproducible, and easy to review. A distribution packaging revision may change without claiming that Wheeler source or PREV changed.

## Goals

- Define a canonical target-platform-specific install image.
- Separate Wheeler package and distribution identities.
- Define explicit profiles and pinned system-dependency mappings.
- Produce reproducible unsigned Debian and RPM packages first.
- Express configuration, services, users/groups, directories, caches, and lifecycle through typed declarations.
- Normalize paths, ownership, modes, timestamps, ordering, compression, and adapter configuration.
- Test install, upgrade, local configuration preservation, remove, and purge in sealed roots.
- Link provenance to repository, RREV, variant, build-input ID, PREV, and native-image identity.
- Keep signing separate from reproducible construction.

## Non-goals

- Make an OS package manager the Wheeler resolver.
- Query installed host packages or heuristically invent dependencies.
- Permit arbitrary shell, Lua, PowerShell, spec, or maintainer fragments initially.
- Treat `.deb` or `.rpm` as portable Wheeler identity.
- Define FFI or native executable layout; WIP-0025 and WIP-0026 own them.
- Publish automatically into external distribution archives.

## Semantic model

```text
install_image {
    schema
    source_package_identity
    selected_target
    variant_id
    build_input_id
    PREV
    native_image_prev?
    entries[]
    lifecycle_declarations[]
    runtime_capabilities[]
    metadata
}
```

An entry records logical path, kind, content identity, mode, owner/group classes, role, configuration policy, and replacement policy. Initial kinds are regular files, directories, restricted symlinks, and canonical hard-link groups. Devices, sockets, FIFOs, and unsafe links are rejected.

Roles include executable, library, data, configuration, documentation, license, manual, service definition, completion, debug data, and metadata. Owner classes are root, declared service identity, or package-manager default; build-host UID/GID never enters.

Configuration is immutable data, administrator-preserved content, or a sample. Generated mutable state is declared as lifecycle state instead of shipped as stale bytes.

Typed lifecycle operations may create users/groups or state/cache/log/runtime directories, install service definitions, reload named manager metadata, apply explicit enable/restart policy, update a named cache, and purge declared generated state. Every action has target mapping, order, idempotency, failure behavior, and ownership. Unsupported behavior fails instead of becoming an opaque script.

A distribution profile fixes repository/snapshot, family/release/architecture, runtime baseline, filesystem policy, dependency namespace, version mapping, adapter package/variant, lifecycle policy, and reproducibility policy. It is never inferred from the build host.

A signed mapping snapshot translates logical capabilities into system dependencies. For example, `native:zlib/1` may map to one exact Debian profile package requirement. This is reviewed distribution policy, not the result of running `ldd` and hoping for the best.

```text
distribution_variant_id = hash(
    install image,
    distribution profile and mapping snapshot,
    metadata overlay and split layout,
    lifecycle policy and adapter identity
)

distribution_revision = hash(unsigned system package bytes)
```

One exact export input has one accepted distribution revision. Signing creates a linked release identity.

## Ownership and boundaries

The Wheeler build owns source, WBC, native image, tests, proofs, and PREV; package targets own generic install intent without adding a fourth target kind. Distribution profiles own layout, naming, mappings, service policy, and adapters. The mapping repository owns OS dependency policy. The adapter owns format encoding. The target package manager owns installation transactions. Release tooling owns signing and upload.

## Design

Generic declarations select roles, not absolute distro paths. Profiles map roles such as command, private library, configuration, state, cache, documentation, and manual to approved roots. Packages may request safe subpaths only.

Install-image construction selects an exact target/PREV, verifies referenced output, applies the profile, resolves explicit capability mappings, computes paths, checks conflicts/owners/modes/replacement, normalizes source-epoch timestamps, sorts entries, and emits canonical image/tree bytes.

Runtime dependencies are either bundled exact bytes, distribution-provided mapped capabilities, or small profile-defined platform primitives. Binary inspection verifies declarations; it cannot create dependencies. The adapter never consults package databases, `pkg-config`, CMake registries, default library paths, or a convenient nearby shared object.

A WIP-0026 one-file executable is one install entry. A sealed image needs no adjacent runtime or WBC. A system-baseline image's embedded requirements must exactly match distribution mappings.

The Debian adapter emits deterministic control/data archives, configuration policy, lifecycle metadata, dependencies, docs/licenses, and provenance under fixed compression and timestamp policy. Author `preinst`, `postinst`, `prerm`, and `postrm` scripts are excluded.

The RPM adapter maps equivalent semantics and may generate a canonical spec internally or drive a sealed exact toolchain. Author `%prep`, `%build`, `%install`, scriptlets, Lua, ambient macros, and dynamic fragments are excluded.

Stage 0 may use sealed exact distro tools; Wheeler-native encoders may replace them after conformance; any native tool, rootfs, support file, macro set, argument, and environment enters export build-input identity.

Normalization covers timestamps, locale/timezone, file/control order, owner/group, roots, modes/links, compression headers/threading, changelog dates, macros, random seeds, and debug/build paths. Temporary path, CPU count, user, mirror, and wall clock cannot affect unsigned bytes.

A system package records upstream repository/snapshot, coordinate/RREV, variant, build-input ID, PREV, capsule/image IDs, install-image ID, profile/mapping, adapter, and distribution revision.

Unsigned bytes are the reproducible revision. If a format embeds signatures, release metadata binds both unsigned payload and signed artifact identities.

## Installation I/O boundary

WIP-0032 owns any Wheeler-side requests used to write, verify, publish, or fetch an install image. This WIP defines distribution policy and package-manager lifecycle only; it does not introduce another file, network, completion, or durability API.

An adapter's successful write, rename, signing, upload, or package-manager transaction returns only its exact domain result. Stronger data, namespace, repository, or quorum stability requires the corresponding WIP-0032 receipt and failure model.

## Reversibility, concurrency, and proofs

Install-image construction and encoding are deterministic. Writing, signing, publishing, and installing are external effects. Installation rollback belongs to the OS package manager, not Wheeler `rev`.

Entry and lifecycle order is canonical; parallel work is permitted only when bytes remain invariant. Concurrent publication uses WIP-0023 no-replace semantics.

Proof certificates may be installed as verified files. Credentials, calibration, queue state, and hardware availability are deployment configuration. Installation success is not theorem evidence.

## Safety and compatibility

The install-image schema is canonical and versioned. Adapter or policy changes create new distribution outputs without changing Wheeler PREV.

Reject paths or links that escape, special files, duplicate ownership, undeclared native imports, missing mappings, host-derived dependencies, and arbitrary scriptlets. Also reject noncanonical output, divergent revisions, embedded host paths or timestamps, output escape, and signatures that do not bind the unsigned revision.

## Migration and deletion

1. Define install-image schema and generic roles.
2. Define profiles and mapping snapshots.
3. Implement canonical image construction.
4. Implement sealed Debian and RPM adapters.
5. Add reproducibility and typed lifecycle matrices.
6. Add provenance/signing separation.
7. Integrate WIP-0025 native mappings and WIP-0026 images.
8. Replace adapters with Wheeler encoders where appropriate.
9. Delete ad hoc packaging scripts.

## Progress

- [ ] Install-image, role, profile, and mapping schemas accepted.
- [ ] Debian and RPM output reproduce.
- [ ] Typed lifecycle and sealed-root suite pass.
- [ ] Provenance, native mappings, and signing separation are complete.
- [ ] Ad hoc paths are deleted.

## Testing and acceptance

- [ ] Equal inputs produce identical images independent of path/user.
- [ ] Modes, owners, configuration, splits, and services map correctly.
- [ ] Undeclared files, duplicate paths, and native imports fail.
- [ ] Dependencies come only from pinned mappings; host databases cannot alter output.
- [ ] Debian/RPM bytes reproduce independent of compression concurrency.
- [ ] Install/upgrade/remove/purge and local configuration preservation pass.
- [ ] Packaging-only changes preserve Wheeler PREV.
- [ ] Provenance reconstructs every exact input and signing binds unsigned bytes.

## Alternatives

Direct distro emission from package manifests mixes policy layers; arbitrary spec/control files and scripts are unbounded programs. Unpinned host tools and automatic dependency discovery are ambient inputs. Bundling everything is useful but not universal. Signed bytes alone are not a stable reproducibility target. Using the OS dependency graph as the Wheeler lock omits source, proofs, tools, and portable artifacts. All are rejected.

## Open questions

- Which canonical install-image encoding should be used (owner: format maintainers; decision point: adapters)?
- Which lifecycle operations form the first closed set (owner: distribution/security maintainers; decision point: acceptance)?
- Sealed native tools or Wheeler encoders first (owner: bootstrap maintainers; decision point: implementation)?
- Which split and virtual-provide conventions are generic (owner: distribution maintainers; decision point: split support)?

## References

- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
- [WIP-0025](WIP-0025-native-ffi-and-system-integration.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [Debian Policy](https://www.debian.org/doc/debian-policy/)
- [RPM spec format](https://rpm-software-management.github.io/rpm/manual/spec.html)
