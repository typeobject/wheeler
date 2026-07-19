# WIP-0023: Recipe repositories and reproducible package revisions

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler package, repository, build, security, provenance, and release maintainers |
| Created | 2026-07-19 |
| Updated | 2026-07-19 |
| Area | Recipe repositories, revisions, source acquisition, reproducible builds, publication |
| Depends on | WIP-0007, WIP-0008, WIP-0009, WIP-0022 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler repositories are immutable trust domains with signed content-addressed snapshots. A deployment may expose a Git-reviewed recipe index, source store, binary store, attestations, and advisories through one service or several, but mirrors preserve repository and snapshot identity.

The model adopts Conan's useful distinction among semantic version, recipe revision (`RREV`), configuration-derived variant, and package revision (`PREV`) without importing unrestricted Python recipes or mutable package-ID functions. Recipes are canonical declarative data. Exact sources, patches, dependencies, tools, exports, tests, and compatibility metadata enter RREV. A complete `build_input_id` records every declared cause of output, including the Wheeler reversible-IR/compiler profile. PREV hashes exact unsigned package bytes. One build-input identity has at most one accepted PREV; a differing rebuild is quarantined rather than promoted as a newer flavor of nondeterminism. Reproducibility never blesses malformed inverse, effect, ownership, proof, or quantum metadata; every rebuilt `.wbc` is independently verified.

## Motivation

A public ecosystem needs reviewable recipe ownership, immutable packaging patches, exact source acquisition, explicit build variants, dependency-confusion resistance, offline rebuilding, race-safe publication, and byte-level reproducibility. A lock can reproduce a graph while bytes still vary through timestamps, physical paths, locale, filesystem order, random seeds, scheduling, undeclared tools, headers, libraries, archive metadata, or signing.

The package system must therefore identify repository state, recipe closure, semantic variant, complete build inputs, and exact output independently. “Version 1.2.3 built somewhere on Tuesday” is provenance in the same way fog is a map.

## Goals

- Define repository identity, signed snapshots, namespace authority, key rotation, and mirrors.
- Support ordered public, private, XDG-local, vendored, and air-gapped trust domains.
- Define declarative recipes and exact digest/length-bound source objects.
- Define RREV, `variant_id`, `build_input_id`, and PREV.
- Permit immutable recipe revisions under one semantic version.
- Make locked builds independent of repository availability.
- Normalize common sources of byte variance.
- Enforce one accepted PREV per build-input identity.
- Separate content identity, authorization, signatures, and attestations.
- Quarantine divergent rebuilds.
- Enforce mechanically decidable source/API/ABI semantic compatibility.
- Keep fetch separate from sealed build execution.

## Non-goals

- Run arbitrary Python, shell, or unrestricted Wheeler recipes.
- Treat a branch, mutable directory, tag, URL, or mirror order as identity.
- Accept divergent PREVs and select whichever was uploaded last.
- Hide undeclared native tools or system libraries in a “captured environment.”
- Define graph semantics, OS packages, FFI, or native image layout; WIP-0022, WIP-0024, WIP-0025, and WIP-0026 own those.
- Let signatures replace digest and canonical decoding.

## Identity model

A repository descriptor contains stable ID, genesis identity, namespace roots, signature policy, key delegations, object algorithms, and limits. Key rotation preserves identity through signed delegation.

A snapshot is an immutable canonical view of coordinate-to-RREV mappings, variants/PREVs, yanks, delegations, advisories, and schema identities:

```text
snapshot_id = hash(canonical snapshot bytes)
```

Sequence numbers support audit but are not content identity. A mirror can serve exact snapshot objects; it cannot add candidates or alter namespaces.

A reviewable recipe index may use:

```text
wheeler.repository
recipes/org.example.library/
    wheeler.versions
    all/
        wheeler.recipe
        wheeler.sources
        patches/
        tests/
```

Recipes declare sources, patches, targets, features, dependencies, locked tools, typed build/test/export operations, capabilities, limits, exports, and compatibility. Complex behavior lives in a locked Wheeler tool package with a typed interface; there is no generic canonical `run shell string`.

A source object is `(name, digest, length, media_type, transport_hints)`. URLs are hints. Only verified bytes enter a build.

```text
RREV = hash(canonical recipe closure)
```

The closure includes exact sources, patches, version mapping, dependencies/features, tools, build/test/export rules, and compatibility/provenance metadata.

```text
variant_id = hash(
    selected target/export,
    features/options,
    source and bytecode profiles,
    build and target platform classes,
    portable/native ABI,
    linkage and optimization policy,
    declared compatibility axes
)
```

A recipe cannot execute code to erase identity axes. Any compatibility relaxation is declarative, RREV-bound, and verifier-checked.

```text
build_input_id = hash(
    repository and snapshot,
    coordinate and RREV,
    variant_id,
    exact active lock subgraph,
    source and patch objects,
    compiler/runtime/kernel/tool artifacts,
    canonical plan,
    grants and limits,
    virtual paths and normalized environment,
    source epoch and deterministic seed policy
)
```

```text
PREV = hash(canonical unsigned package bytes)
```

For one build-input ID, accepted PREV count is at most one.

Reproducibility has four distinct levels: graph, build plan, exact bytes, and independently verified bytes from separately provisioned builders. An attestation binds build-input ID, PREV, builder/policy, snapshot, checks, deviations, comparison result, and signer without changing PREV.

A quarantine record binds expected and observed PREVs, build-input ID, attestations, diff-summary identity, and disposition. Quarantined bytes are not resolver candidates.

## Ownership and boundaries

The recipe index owns reviewed packaging intent. Snapshot services own immutable availability and namespace authorization. Source stores own exact bytes. WIP-0022 resolves graphs. The planner owns build-input identity. The executor owns sealed operations. The codec owns canonical package bytes/PREV. Rebuild services compare independent output and quarantine divergence. Publication owns immutable mappings, signatures, yanks, advisories, and acknowledgements. Mirrors own transport only.

## Design

A contribution validates one package directory, verifies sources, builds declared variants under sealed policy, runs consumption tests, checks API/ABI compatibility, receives review, enters a candidate snapshot, and publishes only after required matching attestations.

A semantic version may map to several historical RREVs. Locks pin one. Explicit unlocked policy may select a newer approved RREV; locked builds never follow “latest.”

Typed recipe operations include unpacking verified archives, applying exact patches, copying declared files, invoking locked tools, compiling Wheeler/native source, running declared tests, constructing an install tree, emitting interface metadata, packaging outputs, and building a WIP-0026 image. Every operation declares inputs, outputs, arguments, limits, and capabilities.

Root policy binds repository aliases to IDs and namespace allowlists. Overlap is explicit. Public and private repositories never compete by convenience. WIP-0009 owns the canonical ordered alias list and lookup algorithm: the first authoritative repository with an admissible release owns one unlocked package-instance lookup, and lower entries do not leak versions into it.

### XDG local objects and reusable artifacts

WIP-0009 owns user-facing placement and commands. Repository data lives below `${XDG_DATA_HOME:-$HOME/.local/share}/wheeler/repository`, reusable build artifacts below `${XDG_CACHE_HOME:-$HOME/.cache}/wheeler/artifacts`, policy below `${XDG_CONFIG_HOME:-$HOME/.config}/wheeler/wheeler.repositories.yaml`, and journals/quarantine state below `${XDG_STATE_HOME:-$HOME/.local/state}/wheeler`. The paths are adapter state, not RREV, variant, build-input, PREV, snapshot, or repository identity.

The data repository is an immutable trust domain and the default `local` publication target. The artifact cache is not a repository and contributes no resolver candidates. It may reuse outputs acquired from any repository, workspace, vendor closure, recipe build, mirror, or independent builder only when the complete `build_input_id`, output kind, canonical length, and PREV match. Every hit is decoded and verified under current limits before use. A source label records provenance; it does not let two causes share a key because their filenames looked friendly.

Cache corruption or deletion causes a miss, quarantine, or rebuild and cannot alter selected instances or canonical output. GC is bounded reachability over disposable cache entries. Durable repository GC separately respects snapshots, locks, yanks, quarantine, and holds. Neither operation silently promotes cached bytes into publication.

A complete vendor closure may contain snapshots, recipes, sources, packages, attestations, and the lock. Extra objects are inert, not candidates.

### Sealed environment

Wheeler tools receive typed inputs. Native adapters receive a canonical allowlist equivalent to UTC, `C` locale, explicit source epoch, exact tool paths, empty private home, and a private deterministic-class temporary directory. The host clock and random devices are unavailable for output.

Virtual roots are content-derived logical paths such as `/wheeler/source/<RREV>/` and `/wheeler/output/<build_input_id>/`; host paths are adapter details and debug paths are remapped.

Canonical output fixes path encoding/order, timestamps, ownership, modes, safe links, extended attributes, compression, archive metadata, locale, timezone, deterministic seeds, and scheduling-independent order. Every compiler, linker, archiver, generator, stripper, sysroot, standard library, macro set, and support file that can affect bytes is an exact input. Version text is not a toolchain identity.

The package codec consumes only declared output, validates allowlists, normalizes metadata, sorts paths, uses deterministic compression, excludes transient logs/signatures, embeds RREV/variant/build-input references, and hashes complete unsigned bytes.

### PREV uniqueness and publication

The immutable mapping is conceptually:

```text
(repository, coordinate, RREV, variant_id, build_input_id) -> PREV
```

A differing PREV enters quarantine, cannot replace canonical output, emits a reproducibility diagnostic, and may suspend eligibility until inputs or implementation are corrected. Publication verifies snapshot, recipes/sources, build-input identity, canonical decode/re-encode, PREV, tests, compatibility, and attestations before no-replace content and mapping writes. Equal concurrent publication is idempotent; conflicting bytes fail.

Yanks affect new unlocked resolution but preserve bytes and exact locks. Advisories are signed and may bind coordinate, RREV, variant, PREV, or capability profile. Garbage collection is a separate audited reachability operation over retained snapshots, locks, quarantines, and holds.

Patch/minor publication mechanically rejects removed exports, incompatible parameters/results/layouts, stronger ownership, added effects, lost reversible/coherent/unitary status, and incompatible proof/target/native ABI profiles unless versioning or an explicit reviewed exception permits it.

## Sealed build I/O

WIP-0032 may implement the build driver's acquisition, output publication, and backend scheduling, but it does not relax the sealed recipe contract. Build programs receive immutable declared inputs and explicit output capabilities only; live network, clock, random, host discovery, and undeclared filesystem access remain forbidden.

Publication acknowledgement and exact persistence evidence are separate external effects. A content digest identifies bytes but neither grants authority nor proves those bytes survived a named failure.

## Reversibility and determinism

Canonicalization, planning, hashing, and verification are deterministic. Fetch, signing, publication, yanking, and GC are external effects. Publication acknowledgement is a commit barrier; retry reconciles immutable identities. Worker concurrency cannot alter bytes or mapping order.

## Quantum and proof implications

Proof artifacts and kernels are exact inputs. Mutable calibration, credentials, queue state, and hardware results do not enter canonical package identity. Empirical evidence remains explicitly empirical metadata and cannot become theorem evidence.

## Persistence and safety

Descriptors, snapshots, recipes, sources, attestations, quarantine records, and packages are canonical versioned schemas. Schema migration creates new identity rather than silently reinterpreting bytes.

Reject noncanonical snapshots, invalid delegations, conflicting mappings, source mismatch, unsafe extraction, undeclared effects, output escape, host paths/timestamps, divergent PREV, overwrite publication, mirror substitution, namespace confusion, unverifiable compatibility exceptions, and exhausted limits.

## Migration and deletion

1. Define repository/snapshot/recipe schemas and RREV.
2. Add variant and build-input identities.
3. Split fetch from build and add local identified snapshots.
4. Add immutable object stores and no-replace publication.
5. Normalize environment/filesystem and canonical package output.
6. Enforce PREV uniqueness and quarantine.
7. Add independent rebuild attestations and compatibility checks.
8. Add signed snapshots, delegation, mirrors, and recovery-package migration.
9. Delete mutable catalog and latest-output authority.
10. Delete stage-0 authority after Wheeler conformance.

## Progress

- [ ] Repository, snapshot, and recipe schemas accepted.
- [ ] RREV/variant/build-input/PREV implemented.
- [ ] Fetch separated from build.
- [x] XDG path resolution, canonical ordered file-repository policy, immutable local publication, canonical release mappings, and exact first-authoritative fetch are implemented in stage 0.
- [ ] Unlocked repository resolution, repository-bound locks, reusable artifact cache, quarantine state, and identity-preserving mirrors remain.
- [ ] Reproducibility normalization passes.
- [ ] Quarantine and independent attestations implemented.
- [ ] Compatibility checks and signed snapshots implemented.
- [ ] Recovery build consumes vendored snapshots/objects.
- [ ] Duplicate authorities deleted.

## Testing and acceptance

- [ ] Checkout path/order does not affect RREV or snapshot bytes.
- [ ] Every identity-bearing change moves the corresponding identity.
- [ ] Recipes cannot erase relevant variant axes.
- [ ] Source replacement fails before build.
- [ ] Vendored locked builds use no network.
- [ ] Mirrors yield identical objects and never compete as repositories.
- [ ] Ordered repository lookup stops at the first authoritative admissible trust domain; lower repositories cannot inject a newer release, while an explicit alias selects the intended domain.
- [ ] XDG overrides and fallback paths change placement only; cache hits from every supported origin reverify complete build-input identity and bytes, and cache deletion changes no result.
- [ ] Path, identity, locale, timezone, order, timestamp, and job count do not alter bytes.
- [ ] Independent builds produce one PREV; divergence is quarantined.
- [ ] Equal publication is idempotent and conflicts cannot overwrite.
- [ ] Yanks preserve locks and incompatible patch/minor APIs are rejected.
- [ ] Stage 0 and Wheeler implementations agree.

## Alternatives

Upstream-only packaging cannot carry reviewed downstream fixes. Conan's review layout is useful, but Python recipes and arbitrary package-ID policy are not. Git commits are provenance, not the canonical snapshot protocol. Arbitrary Wheeler recipes recreate ambient build programs. Several newest-selected PREVs normalize nondeterminism. Embedded signatures conflate authorization with reproducible bytes. Capturing an uncontrolled environment explains variance without removing it. All are rejected.

## Open questions

- Separate versions/recipe/source files or one canonical record? — **Owner:** repository maintainers — **Decide by:** schema implementation
- Which digest-agility and transparency-witness policy follows SHA-256? — **Owner:** security maintainers — **Decide by:** public launch
- Which independent-builder level applies to each package class? — **Owner:** release maintainers — **Decide by:** binary publication
- How is source epoch derived? — **Owner:** reproducibility maintainers — **Decide by:** native adapters
- Should source, built, and native-image containers be distinct formats or explicit kinds? — **Owner:** format maintainers — **Decide by:** publication

## References

- [WIP-0022](WIP-0022-package-instances-and-resolution.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [Conan revisions](https://docs.conan.io/2/tutorial/versioning/revisions.html)
- [Conan package ID](https://docs.conan.io/2/reference/binary_model/package_id.html)
- [SOURCE_DATE_EPOCH](https://reproducible-builds.org/specs/source-date-epoch/)
- [Reproducible Builds](https://reproducible-builds.org/docs/)
