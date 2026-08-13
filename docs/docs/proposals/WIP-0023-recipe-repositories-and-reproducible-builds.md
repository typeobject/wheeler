# WIP-0023: Recipe repositories and reproducible package revisions

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler package, repository, build, security, provenance, and release maintainers |
| Created | 2026-07-19 |
| Updated | 2026-08-13 |
| Area | Recipe repositories, revisions, source acquisition, reproducible builds, publication |
| Depends on | WIP-0007, WIP-0008, WIP-0009, WIP-0022 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler repositories are immutable trust domains built from signed, content-addressed snapshots. A deployment may place the reviewed recipe index, source store, binary store, attestations, and advisories in one service or several services. Mirrors must preserve repository and snapshot identity.

The model uses a useful separation from Conan: semantic version, recipe revision (`RREV`), configuration-based variant, and package revision (`PREV`). Wheeler does not import unrestricted Python recipes or mutable package-ID functions.

Recipes are canonical declarative data. Exact sources, patches, dependencies, tools, exports, tests, and compatibility metadata contribute to RREV. A complete `build_input_id` records every declared cause of an output, including the Wheeler compiler and IR profile. PREV hashes the exact unsigned package bytes.

One build-input identity may have at most one accepted PREV. A rebuild that produces different bytes is quarantined, not published as another valid result. Reproducibility also cannot approve invalid ownership, effects, inverses, proofs, or quantum metadata. Each rebuilt `.wbc` is verified again.

## Motivation

A public package ecosystem needs reviewed recipe ownership, immutable patches, exact source acquisition, explicit variants, resistance to dependency confusion, offline rebuilds, safe publication, and byte-level reproducibility. A lock can reproduce the dependency graph while output bytes still change because of timestamps, paths, locale, file order, random seeds, scheduling, undeclared tools, headers, libraries, archive metadata, or signing.

The package system must identify repository state, recipe closure, semantic variant, all build inputs, and exact output as separate facts. A version number plus an unknown build machine is not useful provenance.

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
- Make recovery-seed provenance walkable and reproducible across generations.
- Label unavoidable opaque roots instead of laundering them through a content hash.

## Non-goals

- Run arbitrary Python, shell, or unrestricted Wheeler recipes.
- Treat a branch, mutable directory, tag, URL, or mirror order as identity.
- Accept divergent PREVs and select whichever was uploaded last.
- Hide undeclared native tools or system libraries inside captured environment metadata.
- Define graph semantics, OS packages, FFI, or native image layout. WIP-0022, WIP-0024, WIP-0025, and WIP-0026 own those.
- Let signatures replace digest and canonical decoding.

## Identity model

A repository descriptor contains stable ID, genesis identity, namespace roots, signature policy, key delegations, object algorithms, and limits. Key rotation preserves identity through signed delegation.

A snapshot is an immutable canonical view of coordinate-to-RREV mappings, variants/PREVs, yanks, delegations, advisories, and schema identities:

```text
snapshot_id = hash(canonical snapshot bytes)
```

Sequence numbers support audit but are not content identity. A mirror can serve exact snapshot objects. It cannot add candidates or alter namespaces.

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

Recipes declare sources, patches, targets, features, dependencies, locked tools, typed build/test/export operations, capabilities, limits, exports, and compatibility. Complex behavior lives in a locked Wheeler tool package with a typed interface. There is no generic canonical `run shell string`.

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

Reproducibility has four distinct levels: graph, build plan, exact bytes, and independently verified bytes from separately provisioned builders. An attestation binds the build-input ID, PREV, builder/policy, snapshot, checks, deviations, comparison result, and signer without changing PREV.

A quarantine record binds expected and observed PREVs, build-input ID, attestations, diff-summary identity, and disposition. Quarantined bytes are not resolver candidates.

## Bootstrap seed provenance

A repository snapshot may distribute bootstrap binaries, but it cannot make them self-explanatory. Every recovery seed carries a canonical derivation record with its source coordinate and identity, recipe revision, build-input identity, builder, closed dependencies, normalized environment, exact invocation, output identity, and parent seed. Rebuilders can walk generations backward and reproduce each edge. A binary imported from upstream without a known source derivation is marked as an opaque root with its origin URL and transport identity. Policy must not blur that exception into ordinary trusted provenance.

Wheeler minimizes opaque roots and requires independent rebuild attestations for recovery seeds. Recipe reproducibility and compiler diverse double compilation remain distinct checks. Matching package bytes show that declared inputs reproduced an output. They do not show that a compiler seed corresponds to its source unless the seed chain and independent compiler path also agree.

## Ownership and boundaries

The recipe index owns reviewed packaging intent. Snapshot services own immutable availability and namespace authorization. Source stores own exact bytes. WIP-0022 resolves graphs. The planner owns build-input identity. The executor owns sealed operations. The codec owns canonical package bytes/PREV. Rebuild services compare independent output and quarantine divergence. Publication owns immutable mappings, signatures, yanks, advisories, and acknowledgements. Mirrors own transport only.

## Design

A contribution validates one package directory, verifies sources, builds declared variants under sealed policy, runs consumption tests, checks API/ABI compatibility, receives review, enters a candidate snapshot, and publishes only after required matching attestations.

A semantic version may map to several historical RREVs. Locks pin one. Explicit unlocked policy may select a newer approved RREV. Locked builds never select an unpinned latest revision.

Typed recipe operations can unpack verified archives, apply exact patches, copy declared files, and invoke locked tools. They can also compile Wheeler or native source, run declared tests, construct an install tree, emit interface metadata, package outputs, and build a WIP-0026 image.

Root policy binds repository aliases to IDs and namespace allowlists. Overlap is explicit. Public and private repositories never compete by convenience. WIP-0009 owns the canonical ordered alias list and lookup algorithm: the first authoritative repository with an admissible release owns one unlocked package-instance lookup, and lower entries do not leak versions into it.

### XDG local objects and reusable artifacts

WIP-0009 owns user-facing placement and commands. Repository data lives below `${XDG_DATA_HOME:-$HOME/.local/share}/wheeler/repository`. Reusable build artifacts go under `${XDG_CACHE_HOME:-$HOME/.cache}/wheeler/artifacts`. The policy lives at `${XDG_CONFIG_HOME:-$HOME/.config}/wheeler/wheeler.repositories.yaml`. Journals and quarantine state use `${XDG_STATE_HOME:-$HOME/.local/state}/wheeler`. These adapter paths do not affect RREV, variant, build-input, PREV, snapshot, or repository identity.

The data repository is an immutable trust domain and the default `local` publication target. The artifact cache is not a repository and contributes no resolver candidates. It may reuse outputs acquired from any repository, workspace, vendor closure, recipe build, mirror, or independent builder only when the complete `build_input_id`, output kind, canonical length, and PREV match. Every hit is decoded and verified under current limits before use. A source label records provenance. Two causes cannot share a key merely because their filenames match.

Cache corruption or deletion causes a miss, quarantine, or rebuild and cannot alter selected instances or canonical output. GC is bounded reachability over disposable cache entries. Durable repository GC separately respects snapshots, locks, yanks, quarantine, and holds. Neither operation silently promotes cached bytes into publication.

A complete vendor closure may contain snapshots, recipes, sources, packages, attestations, and the lock. Extra objects are inert, not candidates.

### Sealed environment

Wheeler tools receive typed inputs. Native adapters receive a canonical allowlist equivalent to UTC, `C` locale, explicit source epoch, exact tool paths, empty private home, and a private deterministic-class temporary directory. The host clock and random devices are unavailable for output.

Virtual roots are content-derived logical paths such as `/wheeler/source/<RREV>/` and `/wheeler/output/<build_input_id>/`. Host paths are adapter details and debug paths are remapped.

Canonical output fixes path encoding/order, timestamps, ownership, modes, safe links, extended attributes, compression, archive metadata, locale, timezone, deterministic seeds, and scheduling-independent order. Every compiler, linker, archiver, generator, stripper, sysroot, standard library, macro set, and support file that can affect bytes is an exact input. Version text is not a toolchain identity.

The package codec consumes only declared output, validates allowlists, normalizes metadata, sorts paths, uses deterministic compression, excludes transient logs/signatures, embeds RREV/variant/build-input references, and hashes complete unsigned bytes.

### PREV uniqueness and publication

The immutable mapping is conceptually:

```text
(repository, coordinate, RREV, variant_id, build_input_id) -> PREV
```

A differing PREV enters quarantine, cannot replace canonical output, emits a reproducibility diagnostic, and may suspend eligibility until inputs or implementation are corrected. Publication verifies snapshot, recipes/sources, build-input identity, canonical decode/re-encode, PREV, tests, compatibility, and attestations before no-replace content and mapping writes. Equal concurrent publication is idempotent. Conflicting bytes fail.

Yanks affect new unlocked resolution but preserve bytes and exact locks. Advisories are signed and may bind coordinate, RREV, variant, PREV, or capability profile. Garbage collection is a separate audited reachability operation over retained snapshots, locks, quarantines, and holds.

Patch or minor publication rejects removed exports, incompatible parameters, results, or layouts, stronger ownership, added effects, and lost reversible, coherent, or unitary status. It also rejects incompatible proof, target, or native ABI profiles unless the version changes or a reviewed exception allows the break.

## Sealed build I/O

WIP-0032 may implement the build driver's acquisition, output publication, and backend scheduling, but it does not relax the sealed recipe contract. Build programs receive immutable declared inputs and explicit output capabilities only. Live network, clock, random, host discovery, and undeclared filesystem access remain forbidden.

Publication acknowledgement and exact persistence evidence are separate external effects. A content digest identifies bytes but neither grants authority nor proves those bytes survived a named failure.

## Reversibility and determinism

Canonicalization, planning, hashing, and verification are deterministic. Fetch, signing, publication, yanking, and GC are external effects. Publication acknowledgement is a commit barrier. Retry reconciles immutable identities. Worker concurrency cannot alter bytes or mapping order.

## Quantum and proof implications

Proof artifacts and kernels are exact inputs. Mutable calibration, credentials, queue state, and hardware results do not enter canonical package identity. Empirical evidence remains explicitly empirical metadata and cannot become theorem evidence.

## Persistence and safety

Descriptors, snapshots, recipes, sources, attestations, quarantine records, and packages are canonical versioned schemas. Schema migration creates new identity instead of silently reinterpreting bytes.

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
- [ ] Recipe RREV and variant identities remain. Stage-0 source-package plans implement a narrower `wheeler-build-input-1` over workspace/compiler/profile/node closure and PREV over exact canonical `.wbc` bytes.
- [x] Stage-0 fetch and vendor commands materialize exact locked archives before build. Locked offline builds consume only the verified vendor closure and perform no repository resolution. Native recipe fetch remains.
- [x] XDG path resolution, canonical ordered file-repository policy, immutable local publication, canonical release mappings, and exact first-authoritative fetch are implemented in stage 0.
- [x] Unlocked stage-0 resolution honors namespace authority and first-admissible configured repository order without candidate mixing.
- [x] Canonical schema-1 local repository snapshots bind the complete sorted coordinate/archive/manifest view, live under immutable content-derived names, and are materialized on publication and resolution without a mutable `latest` authority. Lock schema 3 binds each selected package to both that snapshot and its owning repository trust-domain identity without binding aliases, URLs, order, or physical paths. Strict detached Ed25519 envelopes sign the domain-separated repository identity and complete canonical snapshot bytes and bind snapshot and X.509 key identities. Repository-policy schema 2 pins up to sixteen canonical trusted keys per trust domain. `repository trust`, `untrust`, `sign`, and `verify` manage explicit local authority. Configured resolution and exact fetch reject an unsigned current view or malformed trusted envelope before consulting candidates or signed-domain cache objects. Substitution, forgery, wrong key pairs, malformed DER, noncanonical base64, and noncanonical YAML fail closed. Delegations, threshold policy, yanks, advisories, and network acquisition remain. One key is a root, not a committee, however impressive its lanyard.
- [x] Authoritative exact package fetches populate and reverify a disposable XDG package-object cache. Corruption becomes a miss, cache bytes never become candidates, and bounded GC removes malformed regular objects without following links. A repository with trusted signing keys verifies its current complete snapshot before either repository or cache bytes may satisfy an exact fetch.
- [x] The complete current plan input identity keys stage-0 source-package build outputs. The cache reverifies every hit and admits one PREV per input. Divergent verified output enters deterministic XDG quarantine and cannot replace the accepted mapping. Bounded GC removes malformed and unreachable disposable cache objects.
- [x] Wheeler parses strict schema-1 repository snapshots into caller-owned coordinate rows, reproduces empty and populated canonical bytes, and agrees with stage 0 on package order plus stable and prerelease semantic-version precedence. The executable fixture publishes eight rows and rejects a ninth at its declared table bound.
- [x] Wheeler validates bounded immutable snapshot input before computing and publishing its complete SHA-256 identity. Empty and three-release identities match stage 0. Malformed, fourth-release, and oversized inputs leave output untouched. Ed25519 envelope verification and trusted-key policy remain on the native path.
- [x] Wheeler computes a final archive identity only after payload digest, entry digest, embedded canonical manifest, and exact source closure all pass. The bounded one-file result agrees with stage 0. Damaged or oversized input publishes no identity.
- [x] Wheeler computes a final build-plan identity only after the payload digest and exact node identity rederive. The bounded one-node result agrees with stage 0. Damage or oversized input leaves output untouched.
- [ ] Recipe-complete build-input axes and identity-preserving mirrors remain. Local locks are snapshot-bound, but public signed snapshots are not implemented.
- [ ] Reproducibility normalization passes.
- [x] Divergent verified build output enters deterministic XDG quarantine and cannot replace the accepted PREV. Canonical bootstrap seed attestations independently bind source, output, and distinct builder identities. Recipe-level attestation policy remains.
- [x] Signed snapshot authorization and automatic configured-repository enforcement implemented.
- [ ] Compatibility checks, delegation, and threshold signature policy implemented.
- [ ] Recovery build consumes vendored snapshots/objects.
- [ ] Duplicate authorities deleted.

## Testing and acceptance

- [ ] Checkout path/order does not affect RREV or snapshot bytes.
- [ ] Every identity-bearing change moves the corresponding identity.
- [ ] Recipes cannot erase relevant variant axes.
- [x] Sealed execution rederives the complete workspace plan and compares it with the signed-off plan before creating staging output or consulting build products. Replacing a planned source makes the plan stale and fails before build.
- [x] Locked `check`, `build`, and `run` consume only the physical vendor closure and exact lock. They do not invoke resolution or catalog access. A damaged vendored archive fails identity validation before compilation.
- [ ] Mirrors yield identical objects and never compete as repositories.
- [x] Ordered repository lookup stops at the first enabled authoritative namespace containing the release. The repository fixture publishes conflicting bytes under one coordinate, proves the higher private domain wins unqualified fetch and resolution, and proves an explicit `local` alias selects local bytes.
- [x] XDG overrides and fallback paths change placement only. Relative overrides are rejected with stable diagnostics. Package-object hits reverify complete release and archive identity, cache deletion changes no package bytes, and build-output hits bind the complete stage-0 build-input key. Native recipe origins remain.
- [ ] Path, identity, locale, timezone, order, timestamp, and job count do not alter bytes.
- [x] Repeating an exact build-input identity with equal verified bytes is idempotent. A different canonical PREV is retained under its observed identity with immutable bytes and a canonical quarantine record, while the accepted mapping remains authoritative.
- [x] Publishing the same canonical archive and coordinate twice is idempotent. Reusing that package/version for changed bytes raises a format error before replacement, and exact fetch revalidates stored archive identity before publication.
- [ ] Yanks preserve locks and incompatible patch/minor APIs are rejected.
- [ ] Stage 0 and Wheeler implementations agree.

## Alternatives

Upstream-only packaging cannot carry reviewed downstream fixes. Conan's review layout is useful, but Python recipes and arbitrary package-ID policy are not. Git commits are provenance, not the canonical snapshot protocol. Arbitrary Wheeler recipes recreate ambient build programs. Several newest-selected PREVs normalize nondeterminism. Embedded signatures conflate authorization with reproducible bytes. Capturing an uncontrolled environment explains variance without removing it. All are rejected.

## Open questions

- Separate versions/recipe/source files or one canonical record (owner: repository maintainers. Decision point: schema implementation)?
- Which digest-agility and transparency-witness policy follows SHA-256 (owner: security maintainers. Decision point: public launch)?
- Which independent-builder level applies to each package class (owner: release maintainers. Decision point: binary publication)?
- How is source epoch derived (owner: reproducibility maintainers. Decision point: native adapters)?
- Should source, built, and native-image containers be distinct formats or explicit kinds (owner: format maintainers. Decision point: publication)?

## References

- [WIP-0022](WIP-0022-package-instances-and-resolution.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [Conan revisions](https://docs.conan.io/2/tutorial/versioning/revisions.html)
- [Conan package ID](https://docs.conan.io/2/reference/binary_model/package_id.html)
- [SOURCE_DATE_EPOCH](https://reproducible-builds.org/specs/source-date-epoch/)
- [Reproducible Builds](https://reproducible-builds.org/docs/)
