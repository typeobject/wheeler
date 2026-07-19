# WIP-0009: Wheeler package and build system

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler package, build, compiler, security, and release maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Packages, modules, builds, registry, tooling |
| Depends on | WIP-0007, WIP-0008 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler will have its own package manager and build system, written in Wheeler. The `wheeler` command manages workspaces, dependency resolution, compilation, testing, documentation, native lowering, content-addressed packages, and repositories. It ships with the native recovery release and replaces Gradle after the WIP-0008 cutover.

The tool uses familiar ideas from modern package systems: one command, declarative manifests, exact lockfiles, reproducible builds, workspaces, repositories, and hermetic tests. It is not a Cargo wrapper. Wheeler packages must preserve the language's full typed IR profile, including ownership, inverse and history classes, coherent permutations, quantum regions, adjoints, proofs, effects, target capabilities, limits, and native ABI data.

A source manifest is declarative data. It is not an unrestricted build script. Build extensions are versioned Wheeler tool packages that run with explicit capabilities, bounded inputs, declared outputs, and no ambient file or network access. Resolution and artifact creation are deterministic. Credentials, provider sessions, host paths, and changing target calibration never enter package or lock identities.

## Motivation

Keeping Gradle would leave a Java dependency after Java was supposed to be gone. Replacing Gradle with Cargo would move Wheeler's build graph under another language's package rules and bootstrap chain. Shell scripts and ad hoc downloads would make dependency identity, effects, and reproducibility hard to verify.

Wheeler also needs package rules that general host tools do not model:

- A module may expose ordinary, reversible, coherent, unitary, and hybrid entry points.
- Consumers may require minimum source, bytecode, quantum IR, proof, or platform ABI profiles.
- Target adapters must describe capabilities without storing credentials or provider objects.
- Native images derive from canonical `.wbc`; they do not replace its portable identity.
- Compiler and runtime packages belong to the self-hosting and recovery trust chain.
- Build tools follow the same bounded effects and replay rules as other Wheeler programs.

The package system is core language infrastructure. It is also a major Wheeler acceptance program.

## User model

A repository contains one workspace manifest and one or more packages:

```text
wheeler.workspace.yaml
wheeler.package.lock.yaml
build/
  wheeler-compiler/
  wheeler-runtime/
compiler/
  wheeler.package.yaml
  src/
runtime/
  wheeler.package.yaml
examples/
  wheeler.package.yaml
```

The command surface begins with:

```text
wheeler new
wheeler check
wheeler build
wheeler test
wheeler run
wheeler doc
wheeler format
wheeler package
wheeler publish
wheeler fetch
wheeler vendor
wheeler clean
wheeler explain
```

Commands operate on the workspace graph by default and accept explicit package, target, profile, offline, locked, and capability-policy selections. Ordinary commands do not execute provider hardware. Hardware tests require an explicit named target grant and remain outside deterministic default CI.

## Goals

- Implement package resolution, builds, and registry clients in Wheeler.
- Replace Gradle and per-module host-language build logic after native cutover.
- Give one command coherent check, build, test, run, documentation, package, and publish behavior.
- Define Wheeler-native workspace, package, lock, archive, registry, and build-plan formats.
- Make dependency and build output identity deterministic and content-addressed.
- Model source profile, bytecode version, effects, quantum capabilities, proofs, native ABI, and target requirements explicitly.
- Execute build tools under least authority with declared inputs, outputs, limits, and network policy.
- Support offline, vendored, mirrored, air-gapped, and XDG-local repository operation.
- Bootstrap the compiler, runtime, and package manager from a prior native Wheeler recovery release.

## Non-goals

- Parse Cargo, Maven, Gradle, npm, or arbitrary shell build files as canonical manifests.
- Run unrestricted package install scripts.
- Put credentials, account IDs, provider sessions, calibration snapshots, or mutable hardware availability in lockfiles.
- Treat native images as portable package semantics.
- Resolve dependencies differently according to registry response order, wall-clock time, locale, or filesystem order.
- Guarantee that every package version builds on every target.
- Make live quantum jobs part of package publication.
- Treat a local artifact cache as package authority, provenance, or a substitute for verification.

## Names and files

`wheeler` is the Wheeler toolchain driver. `wheeler run <package-or-artifact>` executes a selected package target or verified artifact.

`wheeler.package.yaml` is a UTF-8 Wheeler package manifest. `wheeler.workspace.yaml` is the optional workspace manifest. `wheeler.package.lock.yaml` is the generated canonical resolution. `.wpk` is the canonical package archive and `wheeler.workspace.plan` remains the canonical binary build plan. Names and suffixes are Wheeler contracts and do not alias host package formats. The retired extensionless metadata names have no fallback lookup; one package graph does not need two front doors.

Generated target artifacts and default package archives live below `<repository>/build/<workspace-member>/`; `wheeler clean` owns that tree. A directly invoked member discovers the adjacent workspace and uses the same group, while a standalone package uses its own `build/`. A package-local `vendor/` is different: it is a generated, content-addressed dependency input closure for standalone offline builds and is ignored by Git. The recovery workspace keeps exact locks and canonical member sources; workspace commands reconstruct matching dependency archives in memory. An exported air-gap bundle may still carry a verified vendor set. The source repository doesn't need to contain that generated closure.

A package identity contains:

```text
(namespace, name, version, source_identity, manifest_identity)
```

A resolved dependency also fixes its archive content hash and registry or path-source identity. A build identity includes the complete lock graph, compiler artifact, language profile, options, declared environment, build-tool artifacts, target triple when applicable, and platform ABI.

## Manifest language

Package metadata uses a closed, canonical YAML 1.2 profile. The sectioned shape borrows the useful part of `pyproject.toml`: one clear project header followed by targets, dependencies, and capability authority. Schema 1 deliberately leaves feature selection out until the resolver can bind it into identities end to end. It does not borrow executable build hooks or arbitrary extension tables. Unknown keys fail instead of becoming implicit extension namespaces.

```yaml
schema: 1
package:
  name: "wheeler.compiler"
  version: "0.1.0"
  profile: "bootstrap-1"
targets:
  - kind: "tool"
    name: "compiler"
    root: "src/main/wheeler/MinimalCompiler.w"
    module: "wheeler.compiler.driver"
    sources:
      - "src/main/wheeler/MinimalCompiler.w"
      - "src/main/wheeler/compiler"
      - "src/main/wheeler/lexer"
    test: false
  - kind: "tool"
    name: "compiler-laws"
    root: "test/compiler_laws.w"
    test: true
dependencies:
  - kind: "build"
    name: "wheeler.bytecode"
    version: "^0.1.0"
capabilities:
  - name: "build.read"
    path: "src/**"
  - name: "build.write"
    path: "build/**"
```

The target kind set is closed: `deployable`, `library`, and `tool`. The `test` field selects a runnable target; it is not a separate kind. A later schema may add named feature lists. Schema 1 rejects `features`. Ignoring an option that could change reproducibility is unsafe. Future features may enable optional dependencies or declared target facets. They cannot remove checks, grant capabilities, select credentials, or run code. Unknown keys fail unless a later schema defines them.

Wheeler accepts a closed YAML profile. It allows one UTF-8 document, LF endings, two-space indentation, plain mapping keys, block mappings and sequences, quoted strings, canonical decimal integers, booleans, and full-line comments.

The parser rejects duplicate keys, tabs, implicit scalar types, nulls, floats, timestamps, anchors, aliases, merge keys, tags, directives, flow collections, block scalars, multiple documents, and unknown fields. Canonical output fixes key order, unordered-list order, escaping, normalization, and one final newline. Standard YAML 1.2 readers can inspect the result, but Wheeler implements only this bounded subset.

Logical package paths use `/`, reject traversal and absolute roots, and stay case-sensitive on every host. A modular source selector may name one file or one directory. Directory expansion includes only physical nonsymlink `.w` files, sorts logical paths, rejects empty or oversized results, and must include the declared root. Selection never expands outside the package boundary.

## Modules and visibility

WIP-0007 modules live inside packages. A package declares roots and exports; imports name modules, not files; resolution maps module names through the package manifest and locked dependencies. Source code cannot walk directories or import undeclared relative host paths.

Package boundaries participate in visibility and effect checking. Public APIs include type, effect, reversibility, coherent eligibility, affine-resource, and target-requirement signatures. A package's API identity changes when one of those observable contracts changes even if method names do not.

Cyclic module imports and cyclic normal dependencies are rejected. Development and build-tool dependency edges have separate acyclic phases so tools cannot observe outputs they are currently producing.

## Versions, features, and resolution

Versions use a specified semantic version grammar for human compatibility policy. Exact content hashes, not version text alone, establish fetched identity. The resolver is deterministic for a registry snapshot and lock input.

Feature selection is additive and namespaced. Features cannot silently remove checks, weaken reversibility, grant capabilities, or select credentials. Target-specific optional code uses explicit profile and target predicates evaluated against declared build inputs, not ambient host probing.

Resolution:

1. parses all workspace manifests;
2. verifies names, versions, source identities, and dependency phases;
3. obtains a signed or content-addressed registry index snapshot unless offline;
4. selects one deterministic solution under the version and profile constraints;
5. records every package, content hash, feature, source, and relevant schema identity in `wheeler.package.lock.yaml`;
6. verifies the complete graph before fetching or building code.

A locked build does not re-resolve. If a locked archive disappears or has different bytes, the build fails. It does not choose a convenient replacement.

The initial resolver may require one version of each package identity in a final graph; multiple-version support requires explicit type and resource identity rules and is deferred until demonstrated necessary.

## Lockfile

`wheeler.package.lock.yaml` is generated canonical YAML data. It is committed for applications, tools, and the Wheeler recovery workspace. Libraries may commit it for development reproducibility without forcing consumers to use that graph.

```yaml
schema: 2
root: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
packages:
  - name: "wheeler.core"
    version: "0.1.0"
    repository: "89abcdef0123456789abcdef0123456789abcdef0123456789abcdef01234567"
    archive: "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210"
    manifest: "76543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba98"
    dependencies: []
```

The lock uses the same closed YAML profile and canonical writer as the manifest. It is data for review and merge tooling, but the resolver remains its only author; hand-edited hashes still fail structural and graph verification.

The lockfile records:

- schema and resolver versions;
- root manifest identities;
- exact package identities and archive hashes;
- dependency kinds and selected features;
- language, bytecode, proof, and ABI profiles;
- registry snapshot or vendored-source identities;
- build-tool packages and declared output schemas.

It excludes credentials, tokens, home directories, temporary paths, clocks, random seeds not explicitly semantic, provider queue state, and mutable calibration data.

Lockfile updates are atomic. A failed resolution leaves the prior lockfile untouched. Merge conflicts are resolved by rerunning the resolver from reviewed manifests, not hand-editing package hashes.

## Package archive

A `.wpk` archive is a canonical, bounded, content-addressed container. It includes:

- the canonical package manifest;
- declared source and resource files in logical path order;
- public API metadata;
- license and provenance records;
- optional canonical `.wbc` library or tool artifacts built under the declared compiler identity;
- optional proof or certificate artifacts with explicit schemas;
- checksums for every member and the package root.

Native images may be distributed as target-qualified attachments or separate derived packages. Their identities point back to canonical `.wbc`; a native image cannot replace missing portable semantics.

Archives reject duplicate paths, traversal, links escaping the package root, special devices, unknown required records, excessive expansion, and noncanonical member order. Extracting an archive is not required to verify or compile it.

## Build graph

`wheeler` converts the locked package graph into a deterministic build plan. Nodes declare:

- tool artifact and entry point;
- canonical input identities;
- output names and schemas;
- target and language profiles;
- granted capabilities;
- CPU-step, memory, file-byte, output-byte, and deadline policy limits;
- cacheability and reproducibility requirements.

The plan is content-addressed. Cache hits are accepted only after complete build-input-key matching plus output hash and schema verification. XDG-local and remote caches are equally untrusted stores; signatures may establish provenance but never replace local structural verification.

Independent nodes may execute concurrently. Semantic output order, diagnostics, archive members, and lock updates are reduced in canonical graph order instead of task completion order.

## Build tools and capabilities

There are no ambient install scripts. A formatter, parser generator, documentation renderer, native linker driver, or other extension is a locked Wheeler tool package. The build engine launches it with a capability object containing only declared logical inputs and output destinations.

A tool cannot read the workspace, home directory, environment, network, clock, random device, target credentials, or prior undeclared output. Networked fetch is owned by the package manager before tool execution. Native system tool invocation, where temporarily required, is a separate named capability with executable identity and normalized arguments in the build record.

Generated files belong to declared output trees and are never silently written into source directories. Promotion of generated source or recovery seeds is an explicit reviewed command.

## Tests, examples, and quantum targets

Packages attach the `test` selector to deployable or tool targets and declare their fixtures. `wheeler test` builds a deterministic plan from those runnable targets alone. It isolates writable state, seeds declared simulators, and reports in package and source order. An entryless library needs a separate runnable harness.

Test classes include:

- unit and compile-fail tests;
- bytecode and diagnostic golden tests;
- reversible-law and replay tests;
- ideal quantum simulation tests;
- target-capability planning tests;
- opt-in integration or live-hardware tests.

Default tests cannot submit live quantum work. A live test names a target capability profile, budget, and credential grant supplied by the host. Its result is operational evidence, not a reproducible package-build input.

Checked-in examples are normal workspace packages with deployable or tool targets. They compile under the same lock graph and profile as user code; no special parser path or target kind exists for examples.

## Registry and publication

A registry stores immutable package archives by content identity and a signed append-only mapping from package names and versions to archive identities. Publication never mutates an existing `(namespace, name, version)` mapping.

Namespaces have explicit ownership and delegation. Clients verify archive hash, manifest identity, namespace authorization, and package limits before resolution. Registry mirrors and offline vendor stores preserve identities; changing the download location does not change the package.

### XDG local repository and artifact cache

The default developer repository follows the XDG base-directory contract. Wheeler does not create `/.wheeler`, a dot directory directly below `$HOME`, or a repository in whichever directory the shell happened to enter:

| Purpose | Physical root | Semantics |
|---|---|---|
| Ordered repository policy | `${XDG_CONFIG_HOME:-$HOME/.config}/wheeler/wheeler.repositories.yaml` | Canonical alias, repository identity, transport, trust, and lookup order |
| Durable local publication | `${XDG_DATA_HOME:-$HOME/.local/share}/wheeler/repository` | Immutable package objects and no-replace name/version mappings for the default `local` repository |
| Disposable artifact reuse | `${XDG_CACHE_HOME:-$HOME/.cache}/wheeler/artifacts` | Verified build outputs indexed by complete build-input identity |
| Local journals and quarantine state | `${XDG_STATE_HOME:-$HOME/.local/state}/wheeler` | Retry records, quarantine decisions, and bounded GC/accounting state |

An XDG variable participates only when it is an absolute physical path, as the XDG specification requires. A missing variable uses the listed fallback; a relative value is ignored with a stable diagnostic instead of reinterpreted beneath the workspace. Repository-policy bytes and selected repository/snapshot identities are deterministic resolver inputs, but their physical XDG location is not. These physical roots never enter `wheeler.package.lock.yaml`, package identity, plan identity, diagnostics intended for comparison, or canonical provenance. The selected object, repository trust domain, snapshot, build-input identity, and bytes do.

The repository policy is an ordered list, in the useful Conan 2 sense instead of an unordered bucket of URLs. `wheeler repository add`, `remove`, `enable`, `disable`, `move`, and `list` update or print one canonical file atomically; aliases are unique, repository identities are stable, and physical transports are not identities. The default list contains the XDG data repository as `local`. Command-line repository selections may choose one alias or an explicit ordered subset, but they do not mutate policy behind the user's back.

Unlocked lookup visits enabled repositories in declared order. For one package instance, the first repository with namespace authority and an admissible release owns the lookup. Lower-priority repositories cannot add newer versions to that candidate set. WIP-0022 aliases may select another repository or allow a separate instance. Locks store stable repository and snapshot identities, never aliases, positions, URLs, or XDG paths; a locked lookup contacts only the bound repository or an identity-preserving mirror or cache. Equal-looking bytes in another repository do not authorize a switch.

Without an explicit repository argument, `publish` targets `local`, while `fetch` and unlocked developer resolution use the configured order. An explicit repository may select local or remote transport without changing object identity. Local publication verifies canonical bytes, stages the object and mapping privately, rejects a conflicting `(name, version)`, and publishes with no-replace semantics. Equal publication is idempotent. Atomic visibility is not a durability receipt. WIP-0032 defines any stronger evidence separately from `rename(2)`.

The cache may hold verified outputs produced from workspace source, vendored packages, local publication, recipe builds, mirrors, or independent builders. Origin is provenance, not a cache key shortcut. A hit requires the complete compiler/tool/kernel identities, source and package inputs, profile, target, options, grants, limits that affect bytes, canonical plan node, output schema, length, and digest to match. Wheeler then re-verifies the artifact as untrusted input. Missing, corrupt, divergent, oversized, or schema-wrong entries are deleted or quarantined and rebuilt. Cache location alone never makes an entry a resolver candidate.

Cache insertion is bounded and atomic. Eviction and `wheeler cache gc` are external maintenance effects over disposable objects and cannot alter resolution, output bytes, diagnostics, or lock data. `wheeler clean` removes the repository build tree, not vendored inputs, durable local publications, or the XDG cache. Credentials, provider output, coherent quantum state, raw loans, descriptors, registered addresses, and remote keys are forbidden cache payloads.

`wheeler publish` performs, in order:

1. locked clean build and test under publication policy;
2. manifest and public-API validation;
3. secret and forbidden-file checks;
4. canonical archive construction;
5. local archive verification from bytes;
6. owner signing or authenticated upload;
7. immutable registry acknowledgement recording.

Yanking marks a version ineligible for new unlocked resolution but does not break existing lockfiles or delete the archive. Security advisories are separately signed metadata and never rewrite historical package bytes.

## Hardening and distribution series

The implemented stage-0 archive and locked-build core remains the foundation: declarative manifests, exactly three target kinds, canonical bounded archives, immutable publication, explicit vendor sets, source-bound plans, and no ambient lookup. Before a broad third-party ecosystem, five follow-up WIPs close graph, repository, distribution, native, and image boundaries:

1. [WIP-0022](WIP-0022-package-instances-and-resolution.md) replaces name-global resolution and flat transitive module candidates with target-scoped package instances, direct aliases, build/target contexts, bounded incompatibility solving, minimal updates, one workspace graph, and scoped capabilities.
2. [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md) defines repository trust domains, signed snapshots, declarative recipes, RREV/variant/build-input/PREV identities, sealed reproducibility, independent attestations, quarantine, and no-replace publication.
3. [WIP-0024](WIP-0024-system-package-exports.md) derives Debian, RPM, and later deployment formats from one canonical install image and typed lifecycle policy.
4. [WIP-0025](WIP-0025-native-ffi-and-system-integration.md) defines exact native ABI descriptors, affine foreign ownership, irreversible effects, package-visible providers, and explicit system capabilities without ambient loading.
5. [WIP-0026](WIP-0026-self-contained-native-executables.md) defines one loader-native ELF, Mach-O, or PE file containing a verified read-only Wheeler capsule and embedded runtime.

[WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md) makes public ownership, region relations, and disposal obligations package API. [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md) binds generic body and closed-instantiation identities. [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md) binds class declarations, defaults, associated members, laws, and selected evidence: ordinary instances come from exact class/principal-type packages, adapters require direct dependency plus explicit activation, and no transitive package changes selection. [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md) binds callable kind, effect row, inverse/adjoint/control evidence, and resource bounds. Together they extend the graph without inventing a parallel artifact or a fourth target kind.

The series preserves these rules:

- a package name is not an instance, and only direct declared dependencies are importable;
- target edges retain normal/build/development kind and build/target context;
- repository identity participates in dependency meaning, while mirrors remain transport;
- locks pin realizable graphs and updates preserve valid instances by default;
- recipes and revisions are immutable and one build-input identity admits at most one PREV;
- system packages remain derived policy artifacts;
- native calls are explicit irreversible effect boundaries;
- native images contain format-native read-only capsules instead of adjacent or appended ambient payloads;
- no resolver, builder, FFI loader, image launcher, or distribution adapter performs ambient discovery.

The shared identity chain is coordinate → RREV → variant → build-input ID → PREV, with separate capsule, native-image, signed-release, and distribution identities. Each arrow adds declared information; none is allowed to erase inconvenient inputs using a callback named `packageId()` and a hopeful expression.

A public-ecosystem release waits for direct imports, profile-aware and prerelease-aware bounded solving, lock-preserving updates, repository snapshots, namespace authority, PREV uniqueness with independent rebuilds, and native closure checks. Archive integrity is required, but it does not cover the rest of the supply chain.

## Self-hosting and recovery

The package manager, build planner, manifest parser, resolver, archive codec, registry client, and command driver are Wheeler packages. They are built by the WIP-0007 compiler and execute on the WIP-0008 native runtime.

A recovery release contains:

- native `wheeler` for each supported host;
- canonical compiler, runtime, and package-manager `.wbc` artifacts;
- the recovery workspace manifests and lockfile;
- all bootstrap package archives or a verified vendor set;
- native ABI and backend identities;
- reproduction and trust metadata.

A clean recovery build runs with network disabled and Java, Gradle, Rust, and Cargo absent. It rebuilds the current package graph, proves the compiler fixed point, runs conformance tests, and emits the next candidate recovery release.

The initial package manager may be seeded by stage-0 build tasks. Once the Wheeler implementation passes differential lock, plan, archive, and failure tests, stage-0 package logic is deleted with Gradle instead of retained as a fallback.

## Reversibility, effects, and replay

Dependency resolution is deterministic computation over immutable manifests and an identified registry snapshot. Fetching, cache insertion, output replacement, publication, and yanking are external effects.

A failed build transaction discards private outputs. It does not claim to reverse network transfer or terminal output. Lockfile, archive, and artifact replacement use atomic host effects. Publication acknowledgement is a commit barrier; recovery reconciles by content and idempotency identity before retrying.

Build-event logs may be replayed for diagnostics and provenance, but replay cannot substitute unavailable package payloads or rerun a publication under an old identity. `wheeler clean` removes only the selected repository build tree; explicit cache GC cannot erase a durable local or remote package version.

## Security and limits

Every manifest, lockfile, index, archive, graph, tool, and output has byte, count, nesting, path, dependency, feature, step, memory, and expansion limits. Resolution detects adversarial graphs before downloading package bodies where possible.

Package names and paths use fixed Unicode and confusable policies. Archive verification rejects links, devices, duplicate normalized paths, and decompression bombs. Registry and cache inputs are untrusted.

Capability grants are visible in build plans and diagnostics. A dependency cannot grant itself network, process, file, target, or credential authority. Capability expansion requires a root policy decision and changes build identity where it can affect output.

Secrets are opaque host-owned handles and are prohibited from canonical output, lockfiles, caches, traces, and package archives. Redaction is a last defense, not the ownership model.

## I/O capabilities and builds

Package capability requests may name WIP-0032 resource domains and operation classes, including file read/write, network connect/listen, direct storage, persistence evidence, RDMA registration/remote access, and target submission.

The `Io` fabric grants scheduling only. Resource authority remains target- and phase-scoped under root policy. A reproducible build program receives no ambient live I/O. Runtime support for sockets does not grant that capability.

## Migration and deletion

1. Specify executable schemas for `wheeler.package.yaml`, `wheeler.workspace.yaml`, `wheeler.package.lock.yaml`, `.wpk`, and build plans.
2. Add stage-0 readers and canonical writers with malformed-input and reproducibility suites.
3. Implement workspace module resolution and replace hard-coded Gradle project knowledge.
4. Implement locked local/path dependencies, then vendored and registry dependencies.
5. Add the XDG data repository, content-keyed artifact cache, quarantine state, and explicit cache maintenance.
6. Implement check, build, test, run, doc, package, and clean over the Wheeler compiler and native runtime.
7. Implement the Wheeler package manager and compare every plan, lockfile, archive, diagnostic, and failure with stage 0.
8. Bootstrap the complete repository from a vendored recovery workspace with no network.
9. Switch ordinary CI and release jobs to native `wheeler`.
10. Delete Gradle files, wrappers, Java package tasks, host-language manifest readers, and duplicate shell orchestration.
11. Add remote registry publication only after local, vendored, cached, and recovery builds are stable.

## Progress

- [x] The project replaced extensionless package, workspace, and lock metadata with `wheeler.package.yaml`, `wheeler.workspace.yaml`, and `wheeler.package.lock.yaml`. Stage-0 and native parsers moved in the same change; the old grammar and format detection paths are gone.
- [x] Canonical `.wbc` provides a portable artifact identity for package outputs.
- [x] WIP-0007 and WIP-0008 define compiler and native recovery requirements.
- [ ] Workspace, package, lock, and archive schemas have strict stage-0 codecs. Build plans bind compiler, source, package input, output, capability request, execution limit, and explicit grant identities. Sealed stage-0 execution checks the active compiler and core class identity, rederives the plan, and publishes exact verified outputs atomically. Isolated native memory and work enforcement remains.
- [ ] Stage-0 manifests, resolution, locks, plans, and archives are content-addressed and reproducible. Exact offline dependencies build in dependency-first order.
  - Entryless `library` targets emit a verified inert-entry artifact.
  - Consumers link only reachable public modules from exact locked archives.
  - Linked APIs include qualified functions, records, closed variants, fixed arrays, slices, and exhaustive matches.
  - Root shadowing, private APIs, cycles, and unreachable local source fail closed.
  - Native build execution and stable binary-library linkage remain.
- [x] The stage-0 resolver selects one version per package with deterministic backtracking. A 10,000-unit total-work budget bounds the search. Root and dependency profiles must match exactly. Still-valid exact lock selections are preferred, while targeted and full update modes are explicit. Development dependencies apply only to the root and never propagate. Cycles are rejected. Stable ranges ignore prereleases unless the requirement names one.
- [x] Physical catalogs, exact vendor trees, and immutable local file publication and fetch are bounded and integrity-checked. The closed YAML repository policy records trust order, identity, enabled state, file transport, and sorted namespace authority. XDG fallback and override paths are explicit. Relative overrides are diagnosed and ignored. Policy updates are atomic, publication defaults to `local`, and exact fetch uses the first authoritative match.
- [x] Unlocked stage-0 resolution scans canonical release mappings in configured repository order, filters namespace authority, chooses the first repository with a profile/range-admissible release, and never merges its candidates with lower trust domains.
- [x] Lock schema 3 binds each package to the repository identity that owned its candidates and the complete snapshot used for selection. Aliases, URLs, list positions, and paths never enter lock identity. A valid existing exact choice remains preferred, but a new lock records the current snapshot even when only an unrelated release changed. Sealed catalogs use one domain-separated bootstrap repository identity and a content-derived snapshot.
- [x] Exact fetch uses the XDG artifact root as a disposable package-object cache only after an authoritative release mapping supplies expected package/archive/manifest identities. Every hit is fully decoded and compared; corrupt or oversized regular objects are deleted and refetched, cache deletion changes no bytes, and cached objects never become resolver candidates. `wheeler cache gc` performs bounded lexical verification, removes malformed regular objects, and refuses links or special files.
- [x] Stage-0 plan execution derives `wheeler-build-input-1` from the workspace, compiler, profile, and complete node. Output is reused only when every node has an exact verified schema-1 input, PREV, and length record. Each cached `.wbc` is decoded independently. Any miss rebuilds the full closed tree. A different verified PREV goes to deterministic quarantine and stops publication; bounded cache collection removes malformed or unreferenced records without following links. Cache state cannot become resolver or build authority. Recipe revisions, variants, and native tool axes remain for WIP-0023.
- [ ] Identity-preserving mirrors and signed network snapshots remain; local locks are snapshot-bound.
- [x] The root workspace, canonical core, compiler, runtime, package-codec packages, and examples form an executable stage-0 workspace; workspace commands rebuild member archives in memory and require each identity to match the committed lock. No checked-in vendor tree or undeclared source path is used.
- [x] Wheeler-written `crypto/Sha256.w` now matches independent digest vectors over bounded binary input and supplies the content-identity primitive required by native lock/plan/archive verification.
- [x] `wheeler.core.encoding.binary` owns bounded little-endian reads and ASCII name, version, and path checks for binary package codecs. `Plan.w` no longer keeps a private copy of those rules. One shared module now defines that security boundary.
- [x] `NativeArchive.w` and `packages/archive/Archive.w` verify a Wheeler-computed outer SHA-256 digest and one entry-data digest. They also check schema framing, exact lengths, complete consumption, and stage-0 decode compatibility.
  - The manifest is copied, frozen, parsed by shared scanner and manifest modules, and re-emitted as exact canonical lines.
  - One or two sorted ASCII logical paths must match the declared target source set.
  - Outer corruption, re-signed data corruption, traversal, undeclared source paths, and noncanonical manifest text fail.
  - Successful runs rewind exactly. Reserved-path checks, the wider manifest, Unicode paths, and more than two entries remain.
- [x] `NativePlan.w`, `packages/resolution/Plan.w`, and `PlanIdentity.w` read canonical binary plans. They verify framing, schema, payload length, and a Wheeler-computed payload SHA-256.
  - The current slice decodes one node with at most one package input and one requested capability. An optional grant must equal that request.
  - It validates bounded ASCII names, a three-part numeric version, output path, target kind, and all five execution limits.
  - It rederives the node identity from the exact length-prefixed fields and rejects a forged identity, even when the payload digest is recomputed.
  - The run rewinds exactly. Multiple nodes, larger lists, Unicode, prereleases, and canonical re-encoding remain.
  - A payload digest checks bytes, while field validation checks meaning.
- [x] `NativeWorkspace.w` and `packages/workspace/Workspace.w` parse bounded canonical-YAML workspaces into caller-owned name and path range tables. They check schema, keys, names, paths, lexical name order, path uniqueness, and pairwise nonnesting before exact publication through `LineEmitter.w`.
  - Five normal members and a generated sixteen-member limit pass the independent stage-0 parser.
  - A seventeenth member, bad schema or key, malformed name, duplicate or unsorted name, duplicate or nested path, and traversal fail before publication.
  - Rewind restores the input-effect baseline.
  - Native recovery still limits input to 4,096 bytes and the parser loop to 512 members, below the stage-0 limit of 10,000.
- [x] `NativeLock.w`, `packages/resolution/Lock.w`, and `LineEmitter.w` parse canonical schema-3 YAML into caller-owned package columns, dependency windows, and flat edge tables.
  - Empty, two-package forward-edge, and generated six-package locks publish exact bytes, rewind, and pass the stage-0 parser.
  - A seventh package exceeds the fixture table before publication.
  - The parser checks sorted unique names, valid versions, lowercase 64-nybble identities, and every dependency target against the full package set.
  - Bad schemas, uppercase digests, duplicate or unsorted names, and unknown targets fail closed.
  - Native package and edge loops remain capped at 512 and 1,024 under the 4,096-byte scanner. Schema 3 allows up to 10,000 packages.
- [x] `NativeManifest.w` and the `packages` modules scan canonical YAML in Wheeler. They store targets, source selectors, dependencies, and capabilities in caller-owned fixed-width tables.
  - Each modular target may have a sorted nonempty selector list that covers its root.
  - Target and dependency names plus capability pairs must be sorted and unique. Empty dependency and capability sections are valid.
  - Target kinds, test selectors, names, modules, paths, versions, and constraints use closed checked profiles.
  - The normal two-target fixture and a generated eight-target manifest publish exact bytes, rewind, and pass the stage-0 parser.
  - A ninth target exceeds the fixture table. Bad schemas or kinds, tests on libraries, malformed names or paths, unsorted selectors, and missing root coverage fail.
  - Native loops remain capped at 512 collection rows and 1,024 selectors under the 4,096-byte scanner. Build metadata, owned decoded values, and computed manifest identity remain.
- [x] The unified stage-0 `wheeler` command now covers the full local workflow. It checks, builds, tests runnable targets, and cleans canonical workspaces. It packages and verifies local artifacts, resolves verified catalogs, creates exact offline vendor trees, manages XDG repository policy, and publishes or fetches immutable local releases. It emits, verifies, and executes source-bound plans with exact package inputs, bounded output and time policy, request-scoped grants, exact artifact sets, and atomic publication. It also verifies locks, compiles, runs, disassembles, and emits OpenQASM.
- [x] Stage 0 loads and validates exact locked offline dependency graphs for check, build, test, selected-target run, and planning; exported library modules source-link dependency-first from verified archive bytes, and direct/sealed builds retain package input identities.
- [x] The Wheeler compiler slice is promoted into `wheeler.compiler` with canonical tool and entryless library targets. Example roots import it from the exact locked archive; no second compiler source tree remains.
- [x] The bounded manifest, lock, workspace, plan, archive, canonical-line, and name/path/version modules are promoted into the entryless `wheeler.packages` library. It locks its scanner dependency to `wheeler.compiler` and its binary/SHA-256 primitives to `wheeler.core`; examples lock the exact graph and retain only executable roots.
- [ ] Wheeler-written package execution, binary-library linkage, and migration of the complete workspace remain.
- [ ] Native no-Java recovery uses only committed manifests, locks, and workspace sources or an exported verified vendor closure.
- [ ] Gradle and duplicate build paths are deleted.
- [x] Local file-repository publication is content-addressed, immutable, idempotent, and fail-closed.
- [ ] Authenticated network publication, signing, yanking, and namespace ownership remain.

## Testing and acceptance

- [x] Manifest, workspace, and lock parsers accept only the closed YAML profile. They reject malformed UTF-8, duplicate or unknown keys, implicit types, aliases, tags, merges, bad indentation, traversal, deep nesting, and oversized values. Stage 0 and Wheeler recovery fixtures emit the same canonical bytes.
- [x] Ordered repository policy and immutable release mappings use the same closed YAML profile; duplicate aliases, bad identities/transports/namespaces, relative file locations, unsafe XDG components, malformed release mappings, and conflicting publication fail closed.
- [x] Resolution is unchanged by catalog or manifest insertion order, and backtracking is bounded. Configured repository order is exact. The first authoritative repository with an admissible release wins, without cross-repository version mixing. Filesystem entries are sorted before they reach the solver.
- [x] Locked and offline stage-0 builds consume either exact in-memory workspace-member archives or a package-local generated vendor tree and never perform resolution, network access, or ambient cache lookup.
- [ ] Build-plan codecs are order-independent and reject corruption or forged node identities. Direct and sealed clean builds produce byte-identical `.wbc`, and a forged active-compiler identity is rejected. Full reproduction of locks, archives, plans, and provenance remains.
- [ ] Vendor retries and relocation preserve exact locked bytes and reject poisoned files; XDG repository paths are identity-neutral, and package/build-output cache poisoning, deletion, PREV divergence, quarantine, and GC are tested, while identity-preserving mirrors remain.
- [ ] Build tools cannot observe or mutate undeclared files, environment, network, clock, random state, credentials, or quantum targets.
- [x] Cyclic package and source-module dependencies, dependency module shadowing, private exports, unreachable local modules, and profile conflicts fail closed; feature and future binary ABI conflicts remain.
- [ ] Test-selected Wheeler tools execute through `wheeler`; compiler, runtime, package manager, tools, docs, and negative fixtures still require package migration.
- [x] Package archives verify without extraction and reject duplicate, unordered, escaping, corrupt, oversized, malformed, and trailing members; links and special files are unrepresentable.
- [x] Local publication is idempotent by content identity, uses canonical YAML mappings, and cannot overwrite an existing version; authenticated remote acknowledgement and retry remain.
- [ ] Live target tests are opt-in, budgeted, capability-gated, and excluded from package output identities.
- [ ] A clean bootstrap with no Java, Gradle, Rust, Cargo, or network rebuilds and tests the recovery workspace.
- [ ] No second package resolver or build-graph authority remains after cutover.

## Alternatives

### Keep Gradle

Rejected. It preserves Java in Wheeler's bootstrap and makes host plugins an unrestricted semantic dependency.

### Use Cargo directly

Rejected. Cargo is a strong model for user experience, but Wheeler packages need Wheeler modules, effects, reversibility, quantum capabilities, `.wbc`, proof metadata, and native recovery identities. Depending on Cargo would also replace a Java bootstrap dependency with Rust's.

### Accept arbitrary YAML

Rejected. Familiar indentation is useful, but implicit typing, aliases, merge keys, tags, multiple documents, and duplicate keys are outside the package format. Wheeler accepts one closed YAML 1.2 subset that standard readers can inspect. The recovery seed does not need a general YAML implementation.

### Use arbitrary Wheeler build scripts

Rejected. General scripts make dependency discovery effectful, prevent static capability review, and reproduce unrestricted install-hook failures. Declarative plans plus capability-scoped Wheeler tools are sufficient.

### Make every dependency a source checkout

Rejected. It lacks immutable archive identity, offline verification, namespace ownership, and bounded extraction semantics.

### Put provider configuration in package features

Rejected. Credentials, queue selection, calibration, budgets, and hardware availability are deployment policy. Packages declare semantic target requirements only.

## Open questions

- Which signature and namespace transparency design should the first registry deploy (owner: registry and security maintainers; decision point: before public publication)?
- Which documentation renderer belongs in the recovery graph without expanding the bootstrap excessively (owner: documentation and build maintainers; decision point: before `wheeler doc` becomes required for recovery)?

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0016](WIP-0016-nonconfigurable-source-formatter.md)
- [WIP-0022](WIP-0022-package-instances-and-resolution.md)
- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
- [WIP-0024](WIP-0024-system-package-exports.md)
- [WIP-0025](WIP-0025-native-ffi-and-system-integration.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [YAML 1.2.2](https://yaml.org/spec/1.2.2/)
- [Python packaging: `pyproject.toml`](https://packaging.python.org/en/latest/specifications/pyproject-toml/)
- [Conan 2 remotes](https://docs.conan.io/2/reference/commands/remote.html)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/)
