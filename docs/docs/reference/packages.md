# Package format

Wheeler package metadata uses its own declarative syntax and canonical archive. The current stage-0 implementation parses `wheeler.workspace` and `wheeler.package`, resolves an immutable package catalog, reads and writes canonical `wheeler.package.lock`, loads exact offline dependencies, emits, verifies, and executes source-bound build plans, and reads and writes content-addressed `.wpk` archives. A physical local registry supports immutable publish/fetch transport. Network transport, namespace authorization, source module imports, and the Wheeler-written native implementation remain package-system work.

## Workspace manifest

A workspace manifest names one profile and one or more package directories:

```text
workspace "wheeler" profile "bootstrap-1";
member "wheeler-examples" path "wheeler-examples";
```

Members are canonicalized by member name. Names and logical paths must be unique, and member roots cannot nest. Paths use `/`, reject absolute paths and `.` or `..` components, and contain only portable letters, digits, `_`, `-`, and `.`. The local workspace adapter also rejects symbolic-link components, members outside the physical workspace root, missing package manifests, and package profiles that differ from the workspace profile.

`wheeler check` processes members and their targets in canonical order. `wheeler build` isolates member outputs under `<output>/<member-name>/` so equal target names cannot collide. The checked-in root [`wheeler.workspace`](../../../wheeler.workspace) currently contains the executable Wheeler example package.

## Package manifest

A manifest begins with exactly one package declaration:

```text
package "wheeler.compiler" version "0.1.0" profile "bootstrap-1";
```

It then contains target, dependency, and capability declarations in any source order:

```text
target tool "compiler" root "src/compiler.w";
target deployable "module-demo" root "src/Main.w" module "demo.main"
    source "src/Arithmetic.w" source "src/Main.w";
dependency build "wheeler.bytecode" version "^0.1.0";
capability "build.read" path "src/**";
capability "build.write" path "build/**";
```

Target kinds are exactly `deployable`, `library`, and `tool`. Examples are ordinary deployable targets; giving a demo its own ontology would not improve the demo. A deployable or tool target may carry the trailing `test` selector, as in `target tool "laws" root "src/Laws.w" test;`. The selector admits the target to `wheeler test` without removing ordinary execution through `wheeler run`; it is not a fourth target kind. Entryless libraries cannot carry it until a separate test harness exists. A single-source target has only `root`. A module target additionally declares its root module and every source path with repeated `source` fields. Source paths are canonicalized lexically, must be unique, must include `root`, and are capped at 1,024. Compilation derives and verifies each file's `module` declaration, then applies the closed module-graph rules in the [language profile](language-profile.md); paths never imply module names.

A `library` target must be modular and its root must be entryless. Stage 0 emits a verified library `.wbc` with one inert internal `$library` entry so the ordinary canonical container remains usable; consumers do not call through that entry. Locked package builds validate every target source import against that package's own modules and direct declared dependencies before traversing the private transitive source closure. A direct dependency may compile against its own dependencies; the root cannot import them by accident. The linker then retains only modules reachable from the consuming root, requires every local target module to be reachable, rejects module shadowing/cycles/private exports, and binds all candidate bytes through exact archive and lock identities. Unused modules in a locked library are harmless candidates, not ambient imports. This is source linking, not an excuse for a process-wide classpath.

Dependency kinds are `normal`, `development`, and `build`. Versions are three-part semantic versions with an optional prerelease. Constraints accept exact, `=`, `^`, and `~` spelling; the resolver applies the semantics described below.

The grammar has words, quoted strings, semicolons, and `//` comments. Strings support only `\\` and `\"` escapes and cannot cross line boundaries. Unknown declarations and fields fail closed with line and column.

A manifest must declare at least one target. Package and dependency names use lower-case dotted namespaces. Target names begin with a lower-case letter and contain lower-case alphanumeric components separated by single `.` or `-` characters; the same validated name owns artifact paths and terminal test coordinates. Duplicate target names, dependency names, and capability-name/path pairs are rejected.

## Resolution and lockfiles

`PackageResolver` operates only on an application-supplied immutable catalog of manifests and verified archive identities. When the output lock already exists, `wheeler resolve` strictly decodes it and tries each exact archive/manifest selection first. Every preferred selection is rechecked against current requirements, profiles, catalog bytes, and transitive dependencies; invalid preferences fall back to ordinary canonical candidate order. `wheeler resolve` supplies that catalog from physical `.wpk` files in one explicit directory, sorted by file name and strictly decoded before resolution. It ignores unrelated file suffixes and rejects archive symlinks. Neither layer reads a network, registry, clock, environment, or implicit host package cache. It sorts package names and candidate releases, tries the highest version satisfying both the range and the root's exact source profile, and performs bounded deterministic backtracking when transitive requirements or profiles conflict. Exact profile matching is the current bootstrap rule; WIP-0022 owns richer source, bytecode, proof, target, platform, and ABI compatibility.

Exact requirements select one version. Caret requirements remain below the next compatible major boundary, with the usual narrower `0.x` boundaries. Tilde requirements remain within one major/minor pair. A requirement whose minimum is stable rejects every prerelease candidate, even one with a higher release tuple; a requirement that explicitly names a prerelease may select compatible prerelease or stable candidates. Stable releases sort after prereleases for an equal release tuple. Duplicate catalog versions, missing solutions, root self-dependencies, cyclic selected graphs, and graphs over 10,000 packages fail closed. The current solver additionally permits at most 10,000 deterministic solver-state and candidate visits across the complete search; exhaustion reports a work-limit error, never `No package solution` with its pockets turned out. Development dependencies enter the graph only when explicitly requested for the root. A selected dependency's development edges never propagate into solving, cycle checks, or lock output; otherwise one test helper could recruit another test helper until the lockfile resembled a conference badge.

The generated `wheeler.package.lock` records the schema, root manifest identity, exact selected versions, archive identities, manifest identities, and dependency edges:

```text
lock 1 root "0000000000000000000000000000000000000000000000000000000000000000";
package "wheeler.bytecode" version "0.1.0" archive "1111111111111111111111111111111111111111111111111111111111111111" manifest "2222222222222222222222222222222222222222222222222222222222222222";
package "wheeler.compiler" version "0.1.0" archive "3333333333333333333333333333333333333333333333333333333333333333" manifest "4444444444444444444444444444444444444444444444444444444444444444";
edge "wheeler.compiler" "wheeler.bytecode";
```

Package records and edges are sorted. `PackageLockParser` accepts only the canonical UTF-8 encoding with a final newline, known records, valid identities, and edges whose endpoints exist. Lock identity is SHA-256 over those canonical bytes.

## Build plan

A `wheeler.workspace.plan` file fixes the workspace identity, compiler artifact identity, profile, target source identities, output paths, exact package inputs, requested capabilities, execution limits, and explicit capability grants. A locked dependency target may occur in more than one member closure; those nodes are distinct because the canonical output path participates in node identity, while duplicate output paths and duplicate complete node identities remain errors. The stage-0 command derives this identity from the sorted class bytes of the executing compiler and canonical bytecode implementation. Planning therefore cannot label ambient compiler code with a caller-supplied digest, and execution rejects a plan produced by different stage-0 bits.

Each node identity is SHA-256 over length-prefixed canonical fields. Nodes sort by package and target name. Package inputs sort by package name; capability requests and grants each sort by name and path; grants must be a subset of requests; execution limits are positive and hard-bounded; output paths must be unique. Duplicate coordinates, outputs, node identities, inputs, and capabilities fail closed.

The binary encoding is little-endian and bounded:

```text
byte[8] magic = "WPLN\0\0\0\1"
u32 schema = 1
u32 payload_length
payload {
    byte[32] workspace_sha256
    byte[32] compiler_sha256
    string profile
    u32 node_count
    repeated node {
        byte[32] node_sha256
        string package_name
        string package_version
        byte[32] manifest_sha256
        string target_name
        u32 target_kind
        byte[32] source_sha256
        string output_path
        u32 package_input_count
        repeated package_input { string name; byte[32] archive_sha256; }
        u32 capability_request_count
        repeated capability_request { string name; string path_pattern; }
        u64 max_steps
        u64 max_memory_bytes
        u64 max_input_bytes
        u64 max_output_bytes
        u64 timeout_millis
        u32 capability_grant_count
        repeated capability_grant { string name; string path_pattern; }
    }
}
byte[32] payload_sha256
```

The stage-0 default records 10,000,000 steps, 256 MiB memory, 64 MiB input, 64 MiB output, and a 60-second timeout for each node. The sealed stage-0 executor rederives the entire plan before compilation and enforces exact capability grants, declared output sets, per-output byte ceilings, elapsed timeout checks, and ordinary compiler/artifact limits. Hard process memory and compiler-work accounting require the Wheeler-native isolated build engine; the command does not claim those two host controls.

A string is a `u32` byte length followed by strict UTF-8 and is limited to 4,096 bytes. Lists carry bounded `u32` counts. Target kind codes 1 through 3 denote library, deployable, and tool. The complete plan is limited to 16 MiB. Decoding verifies the payload digest, every embedded identity and invariant, complete consumption, and byte-for-byte canonical re-encoding.

The workspace planner hashes each single source directly and each module target as a canonical length-delimited sequence of sorted logical paths and exact source bytes, both for physical roots and locked archives. Dependency nodes precede their consumers, use isolated output paths, and identify their immediate archive inputs. Root nodes identify their immediate locked inputs. Capability records are requests for root policy, not grants.

## Canonicalization

`PackageManifest.canonicalText()` orders:

1. the package declaration;
2. targets by target name;
3. dependencies by package name;
4. capabilities by name and path pattern.

The canonical form uses UTF-8, one declaration per line, fixed keywords, escaped strings, and a final newline. Source declaration order and comments do not affect manifest identity. Identity is SHA-256 over canonical manifest bytes.

Logical paths use `/`, are case-sensitive, and reject absolute roots, empty components, `.`, `..`, backslashes, and NUL. They never depend on host path normalization. Capability patterns permit `*` and `**` without allowing traversal.

## Package archive

A `.wpk` archive is little-endian and bounded:

```text
byte[8] magic = "WPKG\0\0\0\1"
u32 manifest_length
u32 entry_count
byte[] canonical_manifest
repeated entry {
    u32 path_length
    u64 data_length
    byte[] strict_utf8_logical_path
    byte[32] data_sha256
    byte[] data
}
byte[32] archive_payload_sha256
```

Entries are ordered by logical path. The manifest is stored separately and `wheeler.package` is reserved as an entry name. Every declared target source must be present. Duplicate, unordered, escaping, oversized, malformed UTF-8, truncated, trailing, entry-corrupt, and archive-corrupt data is rejected.

The current ceiling is 16 MiB, 10,000 entries, and 4,096 path bytes. Archive identity is SHA-256 over the complete encoded archive, including its payload digest. Manifest identity and archive identity are deliberately different.

Decoded entry byte arrays are defensively copied. A caller cannot mutate verified package state through a retained host buffer.

## Stage-0 command

The unified command executes local package operations:

```text
wheeler check <package-or-workspace-directory>
wheeler build <package-or-workspace-directory> [-o output-directory]
wheeler test <package-or-workspace-directory>
wheeler clean <package-or-workspace-directory>
wheeler package <package-directory> [-o package.wpk]
wheeler verify <package.wpk>
wheeler resolve <package-directory> --catalog <archive-directory> [-o wheeler.package.lock] [--development] [--update <package> ... | --update-all]
wheeler verify-lock <wheeler.package.lock>
wheeler vendor <wheeler.package.lock> --catalog <archive-directory> -o <vendor-directory>
wheeler publish <package.wpk> --registry <directory>
wheeler fetch <package> <version> --registry <directory> -o <package.wpk>
wheeler plan <workspace-directory> [--grant-requested] [-o wheeler.workspace.plan]
wheeler verify-plan <wheeler.workspace.plan>
wheeler execute-plan <workspace-directory> <wheeler.workspace.plan> -o <new-output-directory>
wheeler compile <source.w> [-o program.wbc]
wheeler run <program.wbc>
wheeler run <package-directory> --target <target>
wheeler disassemble <program.wbc>
wheeler qasm <program.wbc> <output.qasm>
```

`check` compiles and verifies every declared target without writing outputs. `build` writes one canonical `.wbc` per target, named from the target. A workspace repository groups outputs as `<repository>/build/<member>/...`—for example, `build/wheeler-runtime/runtime.wbc`. Invoking a member package directly discovers the adjacent physical `wheeler.workspace` and uses the same repository-level group; a standalone package uses its own `build/`. `manifest-artifacts` closes an output tree over only verified `.wbc` files plus one canonical `wheeler.artifact-set.json`, recording sorted paths, byte lengths, SHA-256 identities, and a domain-separated set identity; unrelated files are errors rather than souvenirs. Locked dependency outputs reside under `dependencies/<package-name>/`; workspace builds place each root package and its dependency tree in the member-named output directory. `test` compiles and executes only deployable or tool targets carrying the `test` selector, in canonical workspace/package/target order. A selected nonmodular source or modular root source with `test void name()` declarations becomes one independently compiled case per declaration, or per bounded scalar `cases(...)` row, in lexical qualified-name and declared row order; modular cases link the exact reachable target and locked dependency graph. Each artifact enters only its selected test, and each case receives a fresh runtime. A selected target without declarations retains the entry-program fallback. Quantum entry cases receive an ideal state-vector target. The stage-0 runner binds domain-separated case, source, artifact, execution, compiler, and report identities; sorts terminal case records by case identity; and reports compile rejection as `WTEST001`, a nonassertion VM trap as `WTEST002`, or a failed Wheeler assertion as `WTEST003` instead of losing the remaining selected cases. Every case prints a bounded assertion-attempt count bound into test-report profile 2; a failed assertion contributes its attempted check while a runtime trap does not invent one. Classical cases also print a typed transition-coverage identity bound into the test report; quantum cases omit that classical dimension. Repeating an unchanged run prints the same semantic status and report identity. A package with no test-selected targets succeeds with a zero-case report. Multi-parameter products, fixtures, non-root test modules, richer descriptors, and report adapters remain WIP-0018 work. `clean` removes only the default physical root `build` tree and rejects files or symbolic links at any level before deleting anything. `package` includes canonical manifest data and every declared target source; without `-o`, its `.wpk` lands in that package's grouped build directory. `verify` performs strict archive decoding before printing identity. `resolve` selects from an explicit verified archive catalog, preserves still-valid selections from an existing output lock, and atomically writes canonical lock data. `--update <package>` restores ordinary highest-compatible ordering for each named reachable package; it may repeat for distinct packages and rejects unknown or duplicate names. `--update-all` discards all lock preferences. The two forms are mutually exclusive. Development dependencies enter only with `--development` and only from the root. `verify-lock` accepts only canonical lock encoding before printing identity. `vendor` materializes exactly the locked archive set plus the canonical lockfile from an explicit verified catalog. `publish` validates an archive and idempotently installs its content plus one immutable name/version mapping in an explicit physical local registry. `fetch` verifies that mapping and the complete archive before atomically writing output. `plan` hashes declared workspace sources and emits a canonical build plan with a content-derived stage-0 compiler identity, fixed conservative per-node limits, separated capability requests and grants, and no ambient authority. Grants are empty unless the caller explicitly supplies `--grant-requested`; that switch grants exactly the declared requests and nothing else. `verify-plan` validates all structural and content identities before printing plan identity. `execute-plan` accepts only a plan whose compiler identity, workspace identity, profile, sources, exact dependency archives, outputs, limits, requests, and complete grants rederive byte-for-byte from the current physical workspace. It builds into a new sibling staging tree, verifies that every declared output and no other file is canonical `.wbc` within its output/time limits, and publishes the directory with an atomic move; stale plans, partial grants, symlinks, preexisting destinations, extra files, missing files, and partial failures are rejected. `run` accepts either a verified artifact or an explicitly selected deployable or tool package target; `--input <utf8-file>` binds one explicitly requested physical nonsymlink file when the entry declares a strict UTF-8 borrow; `--input-bytes <binary-file>` binds the same physical boundary as an immutable `byteview` without decoding it. The switches are mutually exclusive and the artifact's entry type settles the argument rather than file extensions, locale, or astrology. `--output <file> --output-bytes <count>` binds a bounded zeroed byte output and atomically replaces the destination with the program-selected prefix only after successful execution; missing, unexpected, oversized, or partial effect options fail closed. Libraries use `build`; selected runnable targets additionally participate in `test`. Output replacement uses a sibling temporary file and atomic move when the host supports it. That is an all-or-nothing publication boundary for this stage-0 command, not a data, metadata, or namespace durability claim; WIP-0032 owns future typed persistence receipts.

## Future hardening boundaries

The implemented schema remains name-global, source-package-only, and deliberately local. It does not yet claim package-instance coexistence, repository snapshots, recipe revisions, byte-reproducible PREVs, system-package export, native FFI providers, or self-contained platform images. Those contracts are split across WIP-0022 through WIP-0026 under the WIP-0009 umbrella. WIP-0028 makes ownership/region/disposal contracts public API; WIP-0029 binds generic declarations and closed instances; WIP-0030 binds classes, associated members, defaults, laws, and selected direct-package evidence; WIP-0031 binds callable kind, effects, inverse/adjoint characteristics, and bounds. The current schema implements none of that metadata yet. Exact locks do not acquire semantics merely because their hashes look serious. [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md) likewise keeps `Io` scheduling separate from package resource authority: future file, network, direct-storage, persistence, RDMA, and target capabilities remain target- and phase-scoped. Build programs do not gain ambient live I/O from the runtime's choice of backend.

The accepted constraints remain in force while that work is pending: only direct manifest intent should become future source visibility, no locked build performs ambient resolution, and native/distribution work must not introduce host library or package-database discovery.

## Vendored inputs

A vendor tree is a flat, relocatable offline **input** set, not generated build output. Its committed archives are the exact dependency closure needed for network-free recovery and survive `wheeler clean`; moving them under ignored `build/` would turn a reproducible bootstrap into a scavenger hunt. Archive names contain package name, exact version, and full archive SHA-256; `wheeler.package.lock` is copied byte-for-byte. Catalog entries not present in the lock are excluded.

Vendoring verifies archive and manifest identities against every lock entry. An existing output directory is accepted only when its complete file-name set and every byte already match the expected tree, making retries idempotent. Missing, extra, corrupt, linked, nonregular, or duplicate-version inputs fail without being treated as a cache hit. A new tree is assembled and verified in a sibling temporary directory before an atomic directory move when supported. The output directory path does not enter any content identity.

## Locked dependency compilation

A package with dependencies must contain a physical `vendor/` directory produced by `wheeler vendor`. The loader verifies its canonical lock against the root manifest, requires exactly one correctly named archive per lock entry and no extra files, decodes every archive, checks package/version/archive/manifest/profile identities, validates constraints and complete dependency edges, rejects unreachable entries and cycles, and then compiles dependencies in canonical dependency-first order. `check`, `build`, `test`, selected-target `run`, and workspace `plan` all use this path; none resolve, fetch, consult an ambient cache, or silently omit dependencies. Development edges are loaded only when present in the canonical lock generated with `--development`.

Wheeler source does not yet expose package module imports, so this slice validates and builds each locked package as an independently verified target graph. WIP-0007 module names and visibility will connect exported APIs without changing archive or lock identity.

The local host adapter requires a physical package directory, manifest, and target files. A target path that crosses a symbolic link or resolves outside the package fails before compilation. It reads only the manifest and declared target sources; capability requests remain policy data and do not grant broader host access.

From a source checkout, invoke it through the stage-0 Gradle launcher:

```bash
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='check .'
```

## Local registry transport

A local registry is an explicit physical directory with two internal trees:

```text
archives/<archive-sha256>.wpk
releases/<package-name>/<version>.release
```

A release record is strict canonical UTF-8 containing schema, package, version, archive SHA-256, and manifest SHA-256. Publication decodes the archive first, stores bytes by complete content identity, and creates the version mapping atomically. Repeating the same publication is a cache hit. Reusing a package/version for different content fails without rewriting the existing mapping. An unreferenced content object left by a conflicting publication is harmless and may be garbage-collected only by a separate audited operation.

Fetch parses the mapping, reads only the named content object, strictly decodes it, and rechecks package, version, archive, and manifest identities. Missing, linked, nonregular, malformed, corrupt, or mismatched paths fail before output replacement. Registry roots must already exist and be physical directories. This transport intentionally has no network, ambient cache, credentials, mutable overwrite, yanking, signing, or namespace-ownership policy; those remain requirements for a public registry.

## Security boundary

Manifest declarations do not grant capabilities. They are requests consumed by a root build policy. Credentials, environment variables, home paths, provider sessions, clocks, random state, and mutable calibration never enter canonical manifests or archives.

Archive signatures and registry namespace authorization are separate layers. Content identity establishes bytes, not code correctness or publisher authority.

## Wheeler-native manifest slice

The Wheeler-written package codecs live under canonical `wheeler.packages`. Its entryless library is locked to `wheeler.compiler` for the shared scanner and to `wheeler.core` for binary and SHA-256 primitives. The executable roots remain in `wheeler-examples`, which consumes every required exact archive; fixtures may read canonical source for differential compilation, but there is no example-side package-codec authority hiding behind the curtains.

`NativeManifest.w` imports `packages/manifest/Manifest.w`, its focused `ManifestTokens.w` comparison/keyword boundary, and the shared Wheeler scanner. It accepts explicit UTF-8 and requires `package STRING version STRING profile STRING ;`, one or two target-name-sorted unique `target TARGET_KIND STRING root STRING (module STRING source STRING{1,4})? ;` records, zero to two sorted unique dependencies, and zero to two name/path tuple-sorted unique capabilities. Only the first target may be modular in this slice. The parser returns quote-free typed source ranges without allocating host strings. `Names.w` enforces lowercase dotted package/dependency names and Java-style dotted root-module names. A modular target accepts one to four strictly sorted unique sources and requires the root among them; `Paths.w` semantically decodes the scanner's quote/backslash escape pairs and rejects absolute, trailing-slash, backslash, empty-component, and `.`/`..` logical paths, and the manifest parser rejects empty quoted fields. `Semver.w` accepts bounded three-part releases, SemVer prerelease identifiers, and exact, caret, or tilde constraints. It rejects leading zeroes in release components and numeric prerelease identifiers, empty identifiers, invalid identifier bytes, and components above `Long.MAX_VALUE`; build metadata remains outside this slice. `ManifestEmitter.w` copies validated token values into canonical single-space records, detects semicolon tokens from source rather than declaration ordinals, suppresses spaces before them, selects the exact output prefix only after a successful parse, and never treats skipped input trivia as semantic data. The executable fixture records header lengths `11`, `10`, and `11` plus target lengths `3`, `11`, `4`, and `10`, test-selection flags `1` and `1`, module/source lengths `8`, `11`, and `12`, and dependency lengths `9`, `6`, `10`, and `6` plus capability lengths `7`, `9`, `4`, and `4` for `demo.native`, `1.2.3-rc.1`, `boot\"strap`, `app`, `src/A\"pp.w`, `tool`, `src/Tool.w`, `demo.app`, `src/A\"pp.w`, `src/Helper.w`, `demo.base`, `^1.0.0`, `demo.extra`, `~2.1.0`, `fixture`, `test-data`, `logs`, and `logs`, normalizes surplus input whitespace, rewinds exactly, and rejects a substituted declaration keyword, an uppercase or malformed package/dependency name, a leading-zero release or numeric prerelease, an overflowing component, traversal, a decoded backslash path, or an unsupported string escape. Target lists beyond two entries and modular secondary targets, capability lists beyond two entries, dependency lists beyond two entries, source lists beyond four entries, other capability kinds, owned decoded field values, automatic sorting, and duplicate detection beyond the bounded lists remain stage-0 work. The accepted target kinds are `deployable`, `library`, and `tool`; both manifest implementations accept the trailing `test` selector on deployable and tool targets, expose its presence in the typed target model, preserve it during canonical emission, and reject it on an entryless library. Dependency kinds are `normal`, `development`, and `build`. `runtime` is not a dependency kind, however earnestly named. This is the first parser rivet, not the whole bridge.

## Wheeler-native lock slice

`NativeLock.w` uses the shared scanner, name/version checks, and token boundary to parse schema 1, one or two sorted package records, lowercase 64-nybble root/archive/manifest identities, and one edge from the first package to the second. Shared `LineEmitter.w` emits one canonical record per line, including the final newline; the independent stage-0 lock parser accepts those bytes. The fixture rejects schema drift, uppercase hex, duplicate or unsorted packages, and unknown or reversed edges. Larger package sets and complete edge lists remain, as does hashing the bytes rather than merely checking that a digest has dressed correctly for dinner.

## Wheeler-native workspace slice

`NativeWorkspace.w` and `packages/workspace/Workspace.w` parse a checked workspace/profile header and one or two member-name-sorted records. Names follow the stage-0 lowercase dot/hyphen profile, paths use strict alphanumeric/underscore/hyphen components with nonempty dotted segments, and two members must have distinct nonnested paths. Shared `LineEmitter.w` normalizes trivia to canonical records with a final newline; the independent stage-0 workspace parser accepts the result. Duplicate names, duplicate or nested paths, traversal, malformed names, and input order masquerading as canonical order all fail closed. Larger workspaces remain, because manually enumerating ten thousand record fields would be technically bounded and morally unhelpful.

## Wheeler-native plan slice

`NativePlan.w`, `packages/resolution/Plan.w`, and `PlanIdentity.w` consume a binary `byteview`, require `WPLN` schema 1 framing and exact payload/file lengths, hash only the declared payload through Wheeler-written `crypto/Sha256.w`, and compare all 32 trailing digest bytes. The bounded decoder accepts exactly one node with zero or one checked package input, zero or one requested capability, and an optional byte-identical grant that cannot exceed the request, validates ASCII profile/package/target names, a numeric three-part release, a logical output path, target-kind code 1 through 3, and the five hard-bounded execution limits, consumes the payload exactly, reconstructs the `wheeler-build-node-1` length-prefixed identity preimage—including lowercase hexadecimal content identities and decimal limits—and checks its Wheeler SHA-256 against the encoded node identity. Independent stage-0 fixtures cover both an empty policy and one package input with one requested/granted capability; the empty-policy run rewinds to its caller-owned input baseline. The suite rejects payload or digest damage plus an invalid kind or forged node identity even after the test recomputes the payload digest.

This slice does not yet decode multiple nodes or larger input/request/grant lists, prereleases, or Unicode strings, or canonically re-encode the model. Consequently it is a digest-checked structural inspector, not authorization to execute the plan. SHA-256 detects accidental and unauthenticated changes only when the expected digest is itself trusted; cryptography remains stubbornly unimpressed by optimistic variable names.

## Wheeler-native archive slice

`NativeArchive.w` and `packages/archive/Archive.w` consume one binary `.wpk`, verify the trailing whole-payload SHA-256, schema-1 magic, bounded manifest length, one or two sorted entry headers, checked printable-ASCII logical paths, exact file consumption, and the entry-data SHA-256. It copies the manifest into bounded region storage, strictly freezes UTF-8, invokes the shared Wheeler scanner and manifest parser, re-emits canonical newline records byte-for-byte, and requires the complete entry-path set to equal the parsed target source set (or the root for a nonmodular target). Both digests come from Wheeler `crypto/Sha256.w`; the fixture is encoded and independently accepted by stage 0. Damage to the outer digest fails, and changing either entry data or path still fails after the test deliberately recomputes the outer digest. The successful run rewinds all scratch and caller-visible state.

The current manifest check covers the bounded native one-target profile, not every stage-0 declaration. The slice also omits entry sets beyond two, reserved `wheeler.package` rejection, the wider manifest profile, UTF-8 paths, and archive identity over the final bytes. It therefore inspects one integrity-checked archive; it does not yet install one. An extractor without closure checks is just `cp` with better stationery.

## Implementation direction

The workspace and package parsers, resolver, lock codec, build-plan codec, and archive codec are stage-0 conformance implementations. Their malformed-input, resolution, and ordering suites define executable schemas for the Wheeler implementation. The package manager, standard library, and self-hosted compiler will consume the same canonical records; the Java implementation is removed at native cutover rather than retained as a second resolver.
