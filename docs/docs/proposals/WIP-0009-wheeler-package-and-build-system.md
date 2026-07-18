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

Wheeler shall have a package manager and build system written in Wheeler and designed for Wheeler. The `wheeler` command owns workspaces, dependency resolution, compilation, testing, documentation, native lowering, content-addressed packaging, and registry operations. It ships in the native recovery release and replaces Gradle after WIP-0008 cutover.

The system borrows the useful shape of modern language package tools—a single command, declarative manifests, exact lockfiles, reproducible builds, workspaces, package registries, and hermetic tests—but it is not a Cargo front end. Wheeler packages carry language-profile, reversibility, quantum-region, proof, target-capability, effect, and native-ABI metadata that generic Java or Rust package systems cannot enforce.

A source manifest is declarative data, not an unrestricted build program. Build extensions are versioned Wheeler tool packages executed with explicit capabilities, bounded inputs, declared outputs, and no ambient filesystem or network access. Resolution and artifact construction are deterministic. Credentials, provider sessions, host paths, and mutable target calibration never enter package or lock identities.

## Motivation

Deleting Java while retaining Gradle would not remove the Java dependency. Replacing Gradle with Cargo would move Wheeler's build graph under another language's package semantics and bootstrap chain. Shell scripts and ad hoc download logic would make dependency identity, effects, and reproducibility unverifiable.

Wheeler also has package concerns that ordinary host tools do not model:

- a module may expose ordinary, reversible, coherent, unitary, and hybrid entry points;
- consumers may require a minimum source, bytecode, quantum-IR, proof, or platform-ABI profile;
- target adapters must advertise capabilities without embedding credentials or provider objects;
- native images are derived from canonical `.wbc` and must not replace portable artifact identity;
- compiler and runtime packages participate in the self-hosting and recovery trust chain;
- build tools must obey the same bounded effect and replay rules as other Wheeler programs.

The package system is therefore language infrastructure and a Wheeler acceptance program.

## User model

A repository contains one workspace manifest and one or more packages:

```text
wheeler.workspace
wheeler.lock
compiler/
  wheeler.package
  src/
runtime/
  wheeler.package
examples/
  wheeler.package
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
- Support offline, vendored, mirrored, and air-gapped operation.
- Bootstrap the compiler, runtime, and package manager from a prior native Wheeler recovery release.

## Non-goals

- Parse Cargo, Maven, Gradle, npm, or arbitrary shell build files as canonical manifests.
- Run unrestricted package install scripts.
- Put credentials, account IDs, provider sessions, calibration snapshots, or mutable hardware availability in lockfiles.
- Treat native images as portable package semantics.
- Resolve dependencies differently according to registry response order, wall-clock time, locale, or filesystem order.
- Guarantee that every package version builds on every target.
- Make live quantum jobs part of package publication.

## Names and files

`wheeler` is the Wheeler toolchain driver. `wheeler run <package-or-artifact>` executes a selected package target or verified artifact.

`wheeler.package` is a UTF-8 Wheeler package manifest. `wheeler.workspace` is the optional workspace manifest. `wheeler.lock` is the generated canonical resolution. `.wpk` is the canonical package archive. Names and suffixes are Wheeler contracts and do not alias host package formats.

A package identity contains:

```text
(namespace, name, version, source_identity, manifest_identity)
```

A resolved dependency additionally fixes its archive content hash and registry or path-source identity. A build identity includes the complete lock graph, compiler artifact, language profile, options, declared environment, build-tool artifacts, target triple when applicable, and platform ABI.

## Manifest language

The manifest is a small declarative grammar with source spans and a canonical data model. It is not general Wheeler source and has no loops, method calls, I/O, conditionals, interpolation, or hidden defaults dependent on the host.

The implemented stage-0 shape is:

```text
package "wheeler.compiler" version "0.1.0" profile "bootstrap-1";
target tool "compiler" root "src/compiler.w";
dependency build "wheeler.bytecode" version "^0.1.0";
capability "build.read" path "src/**";
capability "build.write" path "out/**";
```

The final grammar will use Wheeler lexical conventions, explicit semicolons, ordered records, and no whitespace-sensitive constructs. Unknown required fields fail closed. Extension fields are namespaced and preserved only when the schema declares that behavior.

Manifest canonicalization fixes Unicode normalization policy, key ordering, integer representation, path grammar, duplicate handling, and line-ending treatment. Logical package paths use `/`, reject traversal and absolute roots, and are case-sensitive independent of the host filesystem.

## Modules and visibility

WIP-0007 modules live inside packages. A package declares roots and exports; imports name modules, not files. Resolution maps module names through the package manifest and locked dependencies. Source code cannot walk directories or import undeclared relative host paths.

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
5. records every package, content hash, feature, source, and relevant schema identity in `wheeler.lock`;
6. verifies the complete graph before fetching or building code.

A locked build does not re-resolve. If a locked archive disappears or has different bytes, the build fails. It does not choose a convenient replacement.

The initial resolver may require one version of each package identity in a final graph. Multiple-version support requires explicit type and resource identity rules and is deferred until demonstrated necessary.

## Lockfile

`wheeler.lock` is generated canonical data. It is committed for applications, tools, and the Wheeler recovery workspace. Libraries may commit it for development reproducibility without forcing consumers to use that graph.

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

The plan is content-addressed. Cache hits are accepted only after output hash and schema verification. Remote caches are untrusted stores; signatures may establish provenance but never replace local structural verification.

Independent nodes may execute concurrently. Semantic output order, diagnostics, archive members, and lock updates are reduced in canonical graph order rather than task completion order.

## Build tools and capabilities

There are no ambient install scripts. A formatter, parser generator, documentation renderer, native linker driver, or other extension is a locked Wheeler tool package. The build engine launches it with a capability object containing only declared logical inputs and output destinations.

A tool cannot read the workspace, home directory, environment, network, clock, random device, target credentials, or prior undeclared output. Networked fetch is owned by the package manager before tool execution. Native system tool invocation, where temporarily required, is a separate named capability with executable identity and normalized arguments in the build record.

Generated files belong to declared output trees and are never silently written into source directories. Promotion of generated source or recovery seeds is an explicit reviewed command.

## Tests, examples, and quantum targets

Packages declare test targets and fixtures. `wheeler test` builds a deterministic test plan, isolates writable state, seeds declared simulators, and reports results in package and source order.

Test classes include:

- unit and compile-fail tests;
- bytecode and diagnostic golden tests;
- reversible-law and replay tests;
- ideal quantum simulation tests;
- target-capability planning tests;
- opt-in integration or live-hardware tests.

Default tests cannot submit live quantum work. A live test names a target capability profile, budget, and credential grant supplied by the host. Its result is operational evidence, not a reproducible package-build input.

Checked-in examples are normal workspace packages or example targets. They compile under the same lock graph and profile as user code; no special parser path exists for examples.

## Registry and publication

A registry stores immutable package archives by content identity and a signed append-only mapping from package names and versions to archive identities. Publication never mutates an existing `(namespace, name, version)` mapping.

Namespaces have explicit ownership and delegation. Clients verify archive hash, manifest identity, namespace authorization, and package limits before resolution. Registry mirrors and offline vendor stores preserve identities; changing the download location does not change the package.

`wheeler publish` performs, in order:

1. locked clean build and test under publication policy;
2. manifest and public-API validation;
3. secret and forbidden-file checks;
4. canonical archive construction;
5. local archive verification from bytes;
6. owner signing or authenticated upload;
7. immutable registry acknowledgement recording.

Yanking marks a version ineligible for new unlocked resolution but does not break existing lockfiles or delete the archive. Security advisories are separately signed metadata and never rewrite historical package bytes.

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

The initial package manager may be seeded by stage-0 build tasks. Once the Wheeler implementation passes differential lock, plan, archive, and failure tests, stage-0 package logic is deleted with Gradle rather than retained as a fallback.

## Reversibility, effects, and replay

Dependency resolution is deterministic computation over immutable manifests and an identified registry snapshot. Fetching, cache insertion, output replacement, publication, and yanking are external effects.

A failed build transaction discards private outputs. It does not claim to reverse network transfer or terminal output. Lockfile, archive, and artifact replacement use atomic host effects. Publication acknowledgement is a commit barrier; recovery reconciles by content and idempotency identity before retrying.

Build-event logs may be replayed for diagnostics and provenance, but replay cannot substitute unavailable package payloads or rerun a publication under an old identity. Clean removes caches only; it cannot make a committed package version cease to exist.

## Security and limits

Every manifest, lockfile, index, archive, graph, tool, and output has byte, count, nesting, path, dependency, feature, step, memory, and expansion limits. Resolution detects adversarial graphs before downloading package bodies where possible.

Package names and paths use fixed Unicode and confusable policies. Archive verification rejects links, devices, duplicate normalized paths, and decompression bombs. Registry and cache inputs are untrusted.

Capability grants are visible in build plans and diagnostics. A dependency cannot grant itself network, process, file, target, or credential authority. Capability expansion requires a root policy decision and changes build identity where it can affect output.

Secrets are opaque host-owned handles and are prohibited from canonical output, lockfiles, caches, traces, and package archives. Redaction is a last defense, not the ownership model.

## Migration and deletion

1. Specify executable schemas for `wheeler.package`, `wheeler.workspace`, `wheeler.lock`, `.wpk`, and build plans.
2. Add stage-0 readers and canonical writers with malformed-input and reproducibility suites.
3. Implement workspace module resolution and replace hard-coded Gradle project knowledge.
4. Implement locked local/path dependencies, then vendored and registry dependencies.
5. Implement check, build, test, run, doc, package, and clean over the Wheeler compiler and native runtime.
6. Implement the Wheeler package manager and compare every plan, lockfile, archive, diagnostic, and failure with stage 0.
7. Bootstrap the complete repository from a vendored recovery workspace with no network.
8. Switch ordinary CI and release jobs to native `wheeler`.
9. Delete Gradle files, wrappers, Java package tasks, host-language manifest readers, and duplicate shell orchestration.
10. Add registry publication only after local, vendored, and recovery builds are stable.

## Progress

- [x] Canonical `.wbc` provides a portable artifact identity for package outputs.
- [x] WIP-0007 and WIP-0008 define compiler and native recovery requirements.
- [ ] Workspace, package, lockfile, and archive schemas have strict stage-0 codecs; build plans cover compiler, source, package-input, output, capability-request, execution-limit, and explicit grant identities; sealed stage-0 execution derives and checks the executing compiler/core class identity, rederives plans, and publishes exact verified outputs atomically, while isolated native memory/work enforcement remains.
- [ ] Stage-0 manifests, resolution, lockfiles, build plans, and archives are content-addressed and reproducible; exact offline dependency targets now build in dependency-first order; exact manifest-bound module source sets now link in local, workspace, planned, archived, and locked offline builds, while cross-package exported APIs and native build execution remain.
- [x] The stage-0 in-memory resolver deterministically selects one version per package with bounded backtracking, explicit development scope, and cycle rejection.
- [ ] Physical catalogs, exact vendor trees, and immutable local registry publish/fetch transport are bounded, integrity-checked, and covered end to end; signed network registry snapshots remain.
- [x] The root `wheeler.workspace` and example package manifest form an executable stage-0 workspace.
- [x] The unified stage-0 `wheeler` command checks, builds, executes declared test targets, and safely cleans canonical local workspaces; packages and verifies local artifacts; resolves explicit verified archive catalogs, materializes exact offline vendor trees, publishes/fetches immutable local registry releases; emits, verifies, and executes source-bound plans with exact package inputs, bounded output/time policy, complete request-scoped grants, exact artifact sets, and atomic publication; verifies locks; and compiles, runs, disassembles, and emits OpenQASM.
- [ ] Stage 0 loads and validates exact locked offline dependency graphs for check, build, test, selected-target run, and planning; Wheeler-written execution, cross-package manifest/dependency binding for exported module APIs, and migration of the complete workspace remain.
- [ ] Native no-Java recovery uses only committed manifests, lockfile, and vendor inputs.
- [ ] Gradle and duplicate build paths are deleted.
- [ ] Local publication is content-addressed, immutable, idempotent, and fail-closed; authenticated network publication, signing, yanking, and namespace ownership remain.

## Testing and acceptance

- [ ] Manifest and lock parsers reject malformed UTF-8, duplicates, unknown required fields, traversal, excessive nesting, and oversized values; both stage-0 parsers fail closed and broader generative coverage remains.
- [ ] Resolution is identical under catalog and manifest insertion order with bounded backtracking; filesystem, registry transport, and task completion inputs remain to test.
- [x] Locked and offline stage-0 builds consume only a package-local exact vendor tree and never perform resolution, network access, or ambient cache lookup.
- [ ] Build-plan codecs are order-independent and reject corruption and forged node identities; direct and sealed-plan clean builds produce byte-identical `.wbc` and a forged executing-compiler identity is rejected, while complete lockfile, package archive, plan, and provenance reproduction remains.
- [ ] Vendor retries and relocation preserve exact locked bytes and reject poisoned files; cache deletion, remote cache poisoning, and mirror selection remain.
- [ ] Build tools cannot observe or mutate undeclared files, environment, network, clock, random state, credentials, or quantum targets.
- [ ] Cyclic package and source-module dependencies produce stable diagnostics; profile conflicts, feature conflicts, and ABI conflicts remain.
- [ ] Declared Wheeler test targets execute through `wheeler`; compiler, runtime, package manager, tools, docs, and negative fixtures still require package migration.
- [x] Package archives verify without extraction and reject duplicate, unordered, escaping, corrupt, oversized, malformed, and trailing members; links and special files are unrepresentable.
- [ ] Local publication is idempotent by content identity and cannot overwrite an existing version; authenticated remote acknowledgement and retry remain.
- [ ] Live target tests are opt-in, budgeted, capability-gated, and excluded from package output identities.
- [ ] A clean bootstrap with no Java, Gradle, Rust, Cargo, or network rebuilds and tests the recovery workspace.
- [ ] No second package resolver or build-graph authority remains after cutover.

## Alternatives

### Keep Gradle

Rejected. It preserves Java in Wheeler's bootstrap and makes host plugins an unrestricted semantic dependency.

### Use Cargo directly

Rejected. Cargo is a strong model for user experience, but Wheeler packages need Wheeler modules, effects, reversibility, quantum capabilities, `.wbc`, proof metadata, and native recovery identities. Depending on Cargo would also replace a Java bootstrap dependency with Rust's.

### Use arbitrary Wheeler build scripts

Rejected. General scripts make dependency discovery effectful, prevent static capability review, and reproduce unrestricted install-hook failures. Declarative plans plus capability-scoped Wheeler tools are sufficient.

### Make every dependency a source checkout

Rejected. It lacks immutable archive identity, offline verification, namespace ownership, and bounded extraction semantics.

### Put provider configuration in package features

Rejected. Credentials, queue selection, calibration, budgets, and hardware availability are deployment policy. Packages declare semantic target requirements only.

## Open questions

- Which signature and namespace transparency design should the first registry deploy? — **Owner:** registry and security maintainers — **Decide by:** before public publication
- Which documentation renderer belongs in the recovery graph without expanding the bootstrap excessively? — **Owner:** documentation and build maintainers — **Decide by:** before `wheeler doc` becomes required for recovery

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0004](WIP-0004-hybrid-jobs-history-and-replay.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
