# Package format

Wheeler packages use a closed canonical-YAML profile and a canonical archive format.

Stage 0 currently supports these operations:

- parse `wheeler.workspace.yaml` and `wheeler.package.yaml`;
- resolve an immutable package catalog;
- read and write canonical `wheeler.package.lock.yaml`;
- load exact offline dependencies;
- emit, verify, and execute source-bound build plans;
- read and write content-addressed `.wpk` archives.

A physical local registry provides immutable publish and fetch transport. Locked source modules can link through direct dependencies. Network transport, repository-bound locks, unlocked solving, reusable build-output caching, signed namespace authority, and complete Wheeler-native package execution remain future work.

Package, workspace, and lock files use the canonical-YAML profile from [WIP-0009](../proposals/WIP-0009-wheeler-package-and-build-system.md#manifest-language). Stage 0 rejects duplicate or unknown keys, implicit types, aliases, tags, merge keys, invalid indentation, and unbounded structures. Wheeler-native recovery examples parse the files and emit the same canonical bytes. The retired extensionless records and parser are gone, and format sniffing remains unsupported.

Stage 0 resolves XDG config, data, cache, and state paths. It diagnoses relative overrides, ignores them, and updates the ordered repository policy atomically. The default policy contains the stable `local` trust domain under the XDG data directory, and publication uses it unless the caller chooses another repository.

Exact fetch checks enabled authoritative repositories in policy order without merging them. A caller may select one alias directly. Physical `--registry` transport remains available for sealed bootstrap fixtures. Unlocked resolution uses configured order, an explicit ordered set of repeated `--repository` aliases, or one sealed `--catalog`.

Exact fetch keeps a disposable verified package-object cache under the XDG artifact root. Build-output caching is not implemented yet. [WIP-0023](../proposals/WIP-0023-recipe-repositories-and-reproducible-builds.md#xdg-local-objects-and-reusable-artifacts) owns repository, build-input, and PREV semantics. A path under `$HOME` is not provenance by itself.

## Workspace manifest

A workspace manifest names one profile and one or more package directories:

```yaml
schema: 1
workspace:
  name: "wheeler"
  profile: "bootstrap-1"
members:
  - name: "wheeler-compiler"
    path: "wheeler-compiler"
  - name: "wheeler-core"
    path: "wheeler-core"
  - name: "wheeler-examples"
    path: "wheeler-examples"
  - name: "wheeler-package"
    path: "wheeler-package"
  - name: "wheeler-runtime"
    path: "wheeler-runtime"
```

Members are canonicalized by member name. Names and logical paths must be unique, and member roots cannot nest. Paths use `/`, reject absolute paths and `.` or `..` components, and contain only portable letters, digits, `_`, `-`, and `.`. The local workspace adapter also rejects symbolic-link components, members outside the physical workspace root, missing package manifests, and package profiles that differ from the workspace profile.

`wheeler check` processes members and their targets in canonical order. `wheeler build` isolates member outputs under `<output>/<member-name>/` so equal target names cannot collide. The checked-in root [`wheeler.workspace.yaml`](../../../wheeler.workspace.yaml) contains the core, compiler, package codec, runtime, and executable example packages.

## Package manifest

A manifest has one schema header and one package mapping. Targets, dependencies, and capabilities are explicit sequences:

```yaml
schema: 1
package:
  name: "wheeler.compiler"
  version: "0.1.0"
  profile: "bootstrap-1"
targets:
  - kind: "tool"
    name: "compiler"
    root: "src/compiler.w"
    test: false
  - kind: "deployable"
    name: "module-demo"
    root: "src/Main.w"
    module: "demo.main"
    sources:
      - "src/Arithmetic.w"
      - "src/Main.w"
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

Target kinds are exactly `deployable`, `library`, and `tool`. Examples use ordinary deployable targets. A deployable or tool target may set `test: true`, which includes it in `wheeler test` while keeping it available to `wheeler run`. This flag is not another target kind. Entryless libraries cannot use it until Wheeler has a separate library test harness.

A single-source target declares only `root`. A module target also declares its root module and a sorted `sources` list. Each selector names one file or one physical directory. A directory contributes regular nonsymlink `.w` files recursively in canonical logical-path order. It must contribute at least one file, and the expanded target may contain at most 1,024 files.

Selectors must be unique and must include `root`. The compiler derives and checks the `module` declaration in each selected file. It then applies the closed module-graph rules in the [language profile](language-profile.md). File paths never imply module names.

A `library` target must be modular, and its root must have no entry point. Stage 0 emits a verified library `.wbc` with one inert internal `$library` entry so the normal container remains valid. Consumers never call that entry.

Locked builds check each import against the package's own modules and its direct declared dependencies before reading private transitive source. A direct dependency may use its own dependencies, but the root package cannot import those modules by accident. The linker keeps only modules reachable from the consuming root. It also requires every local target module to be reachable, rejects module shadowing, cycles, and private exports, and binds all candidate bytes to exact archive and lock identities. Unused modules in a locked library remain possible inputs; they are not ambient imports. Wheeler does not use a process-wide classpath.

Dependency kinds are `normal`, `development`, and `build`. Versions use three-part semantic versions with an optional prerelease. Constraints accept exact values and the `=`, `^`, and `~` forms described below.

The YAML profile permits one UTF-8 document, LF endings, two-space indentation, block mappings and sequences, quoted strings, canonical decimal integers, booleans, `[]`, and full-line `#` comments. It rejects duplicates, unknown keys, implicit strings, nulls, floats, timestamps, tabs, anchors, aliases, tags, merge keys, flow mappings, block scalars, and multiple documents.

Each manifest must declare at least one target; package and dependency names use lowercase dotted namespaces. A target name starts with a lowercase letter and uses lowercase alphanumeric parts separated by single `.` or `-` characters. The same validated name controls artifact paths and terminal test coordinates. Duplicate target names, dependency names, and capability name/path pairs are rejected.

## Resolution and lockfiles

`PackageResolver` reads ordered immutable repository catalogs containing verified manifests and archive identities; configured file repositories are scanned through canonical release mappings and namespace authority. An explicit alias list keeps caller order, while `--catalog` supplies one sealed bootstrap domain.

When an output lock already exists, `wheeler resolve` first tries its exact repository, archive, and manifest choices. Each preference is checked again against current authority, version requirements, profile, bytes, and transitive dependencies. An invalid preference falls back to normal candidate order.

Physical enumeration is sorted; archive symlinks are rejected; resolution reads no network, clock, or artifact cache. Releases sort within one repository, but the first repository with an admissible release owns that package lookup. Lower-trust repositories cannot replace it with a newer release. Stage 0 requires an exact profile match. WIP-0022 defines wider compatibility rules for source, bytecode, proofs, targets, platforms, and ABIs.

An exact requirement selects one version. A caret range stays below the next compatible major boundary, with narrower boundaries for `0.x`. A tilde range stays within one major and minor pair. A stable minimum rejects prerelease candidates. A requirement that names a prerelease may select a compatible prerelease or stable release. For an equal release tuple, stable releases sort after prereleases.

Duplicate catalog versions, missing solutions, root self-dependencies, selected cycles, and graphs above 10,000 packages fail closed; the solver also allows at most 10,000 deterministic state and candidate visits across the whole search. Exhaustion reports a work-limit error. It does not report `No package solution` unless the solver actually proved that result.

Development dependencies enter the graph only when the caller requests them for the root; development edges from selected dependencies never propagate into solving, cycle checks, or lock output.

The generated `wheeler.package.lock.yaml` schema 3 stores the root manifest identity and each exact repository, snapshot, version, archive, manifest, and dependency choice:

```yaml
schema: 3
root: "0000000000000000000000000000000000000000000000000000000000000000"
packages:
  - name: "wheeler.bytecode"
    version: "0.1.0"
    repository: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    snapshot: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    archive: "1111111111111111111111111111111111111111111111111111111111111111"
    manifest: "2222222222222222222222222222222222222222222222222222222222222222"
    dependencies: []
  - name: "wheeler.compiler"
    version: "0.1.0"
    repository: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    snapshot: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    archive: "3333333333333333333333333333333333333333333333333333333333333333"
    manifest: "4444444444444444444444444444444444444444444444444444444444444444"
    dependencies:
      - "wheeler.bytecode"
```

Package records and each dependency list are sorted. `repository` is a stable trust-domain identity. It is never an alias, URL, list position, or XDG path. `snapshot` identifies the full canonical coordinate view that supplied the candidate, so every entry chosen from one repository view carries the same snapshot identity.

Adding an unrelated release changes the snapshot in a newly generated lock, but it does not invalidate a still-admissible exact version preference. A locked build keeps its earlier snapshot and archive identities and does not need a live repository. `PackageLockParser` accepts only exact canonical schema-3 bytes, lowercase identities, and dependency names that appear in the package table. Lock identity is SHA-256 over the canonical bytes.

## Build plan

A `wheeler.workspace.plan` binds the workspace identity, compiler artifact identity, profile, source identities, output paths, exact package inputs, requested capabilities, execution limits, and explicit grants.

The same locked dependency target may appear in several workspace-member closures. These nodes stay distinct because the canonical output path is part of node identity. Duplicate output paths and duplicate complete node identities remain errors.

Stage 0 derives the compiler identity from the sorted class bytes of the running compiler and canonical bytecode implementation. A caller cannot label ambient compiler code with a chosen digest. Execution rejects a plan produced by different stage-0 bits.

For current source builds, the input identity is:

```text
build_input_id = SHA-256(
  "wheeler-build-input-1",
  workspace identity,
  compiler identity,
  profile,
  node identity
)
```

The node already binds package name, version, manifest, target kind, exact source, output path, package archive inputs, capability requests, limits, and grants. The XDG cache stores one canonical `build-input -> PREV,length` record plus a content-addressed `.wbc` object.

Plan execution reuses the cache only when every node has a complete hit. It decodes and canonically re-encodes each object, rebuilds the exact closed staging tree, and runs normal output checks before atomic publication. One miss rebuilds the full tree. Each rebuilt output is compared with any accepted PREV before insertion.

A different verified PREV stops publication. The observed bytes and deterministic evidence go under `${XDG_STATE_HOME:-$HOME/.local/state}/wheeler/quarantine/build-outputs/`. The new output does not become a second valid choice.

Corrupt, malformed, oversized, missing, or unreferenced regular cache files become misses or bounded garbage-collection removals. Symbolic links and special files fail closed. `wheeler cache gc` visits at most 10,000 build-record and object entries. It keeps only reverified reachable pairs and never touches quarantine or durable repository objects.

Deleting the disposable cache forces a rebuild but changes no plan, lock, artifact, or diagnostic identity. Recipe RREV, variants, native toolchains, attestations, and other WIP-0023 build-input fields are not part of this narrower stage-0 key.

Each node identity hashes length-prefixed canonical fields; nodes sort by package and target name. Package inputs sort by package name. Requests and grants sort by name and path. Grants must be a subset of requests, limits must be positive and bounded, and output paths must be unique. Duplicate coordinates, outputs, node identities, inputs, or capabilities fail closed.

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

1. `schema`, `package`, `targets`, `dependencies`, then `capabilities`;
2. package fields as `name`, `version`, then `profile`;
3. targets by target name and fields in schema order;
4. dependencies by package name;
5. capabilities by name and path pattern.

The canonical form uses UTF-8, two-space indentation, quoted strings, lowercase booleans, block collections except for empty `[]`, and one final newline. Input mapping order and comments do not affect manifest identity. Identity is SHA-256 over canonical manifest bytes.

Logical paths use `/`, are case-sensitive, and reject absolute roots, empty components, `.`, `..`, backslashes, and NUL; they never depend on host path normalization; capability patterns permit `*` and `**` without allowing traversal.

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

Entries are ordered by logical path. The manifest is stored separately and `wheeler.package.yaml` is reserved as an entry name. Every declared target source must be present. Duplicate, unordered, escaping, oversized, malformed UTF-8, truncated, trailing, entry-corrupt, and archive-corrupt data is rejected.

The current ceiling is 16 MiB, 10,000 entries, and 4,096 path bytes. Archive identity is SHA-256 over the complete encoded archive, including its payload digest. Manifest identity and archive identity are deliberately different.

Decoded entry byte arrays are defensively copied. A caller cannot mutate verified package state through a retained host buffer.

## Stage-0 command

The unified command executes local package operations:

```text
wheeler check <package-or-workspace-directory>
wheeler build <package-or-workspace-directory> [-o output-directory]
wheeler test <package-or-workspace-directory>
wheeler clean <package-or-workspace-directory>
wheeler cache gc
wheeler package <package-directory> [-o package.wpk]
wheeler verify <package.wpk>
wheeler resolve <package-directory> [--repository <alias> ... | --catalog <archive-directory>] [-o wheeler.package.lock.yaml] [--development] [--update <package> ... | --update-all]
wheeler verify-lock <wheeler.package.lock.yaml>
wheeler vendor <wheeler.package.lock.yaml> --catalog <archive-directory> -o <vendor-directory>
wheeler repository list
wheeler repository add <alias> <identity> <absolute-directory> [namespace ...]
wheeler repository remove <alias>
wheeler repository enable|disable <alias>
wheeler repository move <alias> <before-alias|last>
wheeler publish <package.wpk> [--repository <alias> | --registry <directory>]
wheeler fetch <package> <version> [--repository <alias> | --registry <directory>] -o <package.wpk>
wheeler plan <workspace-directory> [--grant-requested] [-o wheeler.workspace.plan]
wheeler verify-plan <wheeler.workspace.plan>
wheeler execute-plan <workspace-directory> <wheeler.workspace.plan> -o <new-output-directory>
wheeler compile <source.w> [-o program.wbc]
wheeler run <program.wbc>
wheeler run <package-directory> --target <target>
wheeler disassemble <program.wbc>
wheeler qasm <program.wbc> <output.qasm>
```

### Check, build, and outputs

`check` compiles and verifies every declared target without writing output. `build` writes one canonical `.wbc` for each target and names it from the target.

A workspace groups output under `<repository>/build/<member>/...`, such as `build/wheeler-runtime/runtime.wbc`. Running a member package directly finds the adjacent physical `wheeler.workspace.yaml` and uses the same repository-level group. A standalone package uses its own `build/` directory.

`manifest-artifacts` accepts only verified `.wbc` files plus one canonical `wheeler.artifact-set.json`. The set records sorted paths, byte lengths, SHA-256 identities, and a domain-separated set identity. Any unrelated file is an error. Locked dependency outputs live under `dependencies/<package-name>/`, and each workspace member keeps its root package and dependency tree in that member's output directory.

`clean` removes only the default physical `build` tree. It rejects files or symbolic links at any level before deletion begins.

### Tests

`test` runs only deployable or tool targets marked with `test`, in canonical workspace, package, and target order. A selected nonmodular source or modular root source with `test void name()` declarations creates one compiled case per declaration. A bounded scalar `cases(...)` row creates one case per row; names use lexical qualified-name order, and rows keep declaration order. Modular cases link the exact reachable target and locked dependency graph.

Each artifact contains only its selected test, and every case gets a fresh runtime. A selected target with no declarations uses the entry program as a fallback. Quantum entry cases receive an ideal state-vector target.

The stage-0 runner binds separate case, source, artifact, execution, compiler, and report identities. It sorts terminal records by case identity. Compile rejection is `WTEST001`, a nonassertion VM trap is `WTEST002`, and a failed Wheeler assertion is `WTEST003`. One failed case does not hide the others.

Test-report profile 2 includes a bounded count of assertion attempts. A failed assertion counts the attempted check, while a runtime trap does not invent one. Classical cases also include a typed transition-coverage identity. Quantum cases omit that classical field. Repeating an unchanged run produces the same semantic status and report identity; a package with no selected test targets succeeds with a zero-case report.

Multi-parameter products, fixtures, non-root test modules, richer descriptors, and report adapters remain WIP-0018 work.

### Packages, locks, and vendors

`package` writes canonical manifest data and every declared target source. Without `-o`, the `.wpk` goes into the package's grouped build directory. `verify` strictly decodes an archive before printing its identity.

`resolve` uses configured repositories, an explicit ordered alias subset, or one sealed archive catalog. Configured lookup chooses the first authoritative repository with an admissible profile and range. Lower entries cannot replace it with a newer version. The command keeps valid choices from an existing output lock and writes canonical lock data atomically.

`--update <package>` restores normal highest-compatible ordering for each named reachable package. It may repeat for distinct packages and rejects unknown or duplicate names. `--update-all` discards every lock preference. The two forms cannot be combined. Development dependencies enter only with `--development`, and only from the root.

`verify-lock` accepts canonical lock encoding before printing identity. `vendor` writes the exact locked archive set and canonical lockfile from an explicit verified catalog.

### Repository and cache commands

`repository` reads or atomically updates the ordered XDG policy. `repository list` does not create configuration as a side effect.

`cache gc` scans at most 10,000 package objects in lexical order. It keeps only canonical archives whose filename and content identity match; it deletes malformed regular objects and rejects links or special files.

`publish` validates an archive and installs its content with one immutable canonical-YAML name and version mapping. Repeating the same publication is safe. The default repository is `local`.

`fetch` verifies that mapping and the full archive before atomic output; it uses an explicit alias or the first authoritative configured repository.

### Plans

`plan` hashes declared workspace sources and emits a canonical plan. The plan binds a content-derived stage-0 compiler identity, fixed per-node limits, separate requests and grants, and no ambient authority. Grants are empty unless the caller passes `--grant-requested`. That option grants exactly the declared requests.

`verify-plan` checks every structural and content identity before printing the plan identity.

`execute-plan` rederives the compiler identity, workspace identity, profile, sources, dependency archives, outputs, limits, requests, and complete grants from the physical workspace. The values must match the plan byte for byte. The command builds in a new sibling staging tree, confirms that every declared output and no other file is canonical `.wbc`, enforces output and time limits, and publishes with an atomic move. It rejects stale plans, partial grants, symlinks, existing destinations, extra or missing files, and partial failures.

### Running artifacts and package targets

`run` accepts a verified artifact or a selected deployable or tool target. `--input <utf8-file>` binds one physical nonsymlink file when the entry expects a strict UTF-8 borrow. `--input-bytes <binary-file>` binds the same boundary as an immutable `byteview` without decoding it. The options cannot be combined, and the entry type determines which form is valid.

`--output <file> --output-bytes <count>` binds a bounded zeroed output buffer. After successful execution, the command atomically replaces the destination with the prefix selected by the program. Missing, unexpected, oversized, or partial effect options fail closed.

Libraries participate in `build`. Selected runnable targets may also participate in `test`. Output replacement uses a sibling temporary file and atomic move when the host supports it. This gives the command an all-or-nothing publication boundary. It is not a claim about data, metadata, or namespace durability; WIP-0032 defines future persistence receipts.

## Future hardening boundaries

The current schema is name-global, source-package-only, and local. It does not yet support coexisting package instances, repository snapshots, recipe revisions, byte-reproducible PREVs, system-package exports, native FFI providers, or self-contained platform images. WIP-0022 through WIP-0026 define those contracts under WIP-0009.

Later WIPs add more public metadata:

- WIP-0028 defines ownership, regions, and disposal contracts.
- WIP-0029 binds generic declarations and closed instances.
- WIP-0030 binds classes, associated members, defaults, laws, and direct-package evidence.
- WIP-0031 binds callable kinds, effects, inverse and adjoint characteristics, and limits.

The current schema implements none of these fields; a hash proves byte identity, not missing semantics.

The planned `Io` fabric in [WIP-0032](../proposals/WIP-0032-unified-io-fabric-and-durability-receipts.md) keeps I/O scheduling separate from package authority. Future file, network, direct-storage, persistence, RDMA, and target capabilities remain scoped to a target and phase. A runtime backend does not give build programs ambient live I/O.

Until that work lands, three rules remain fixed. Only direct manifest intent may create future source visibility. Locked builds perform no ambient resolution. Native and distribution work must not discover host libraries or package databases.

## Vendored inputs

A vendor tree is a flat, relocatable offline **input** set, not generated build output. `wheeler vendor` materializes it from an explicit catalog when a standalone or air-gapped package needs one; repository `vendor/` directories are ignored instead of checked in. Archive names contain package name, exact version, and full archive SHA-256; `wheeler.package.lock.yaml` is copied byte-for-byte. Catalog entries not present in the lock are excluded.

Vendoring verifies archive and manifest identities against every lock entry. An existing output directory is accepted only when its complete file-name set and every byte already match the expected tree, making retries idempotent. Missing, extra, corrupt, linked, nonregular, or duplicate-version inputs fail without being treated as a cache hit. A new tree is assembled and verified in a sibling temporary directory before an atomic directory move when supported. The output directory path does not enter any content identity.

## Locked dependency compilation

A standalone package with dependencies uses a physical `vendor/` directory produced by `wheeler vendor`. A workspace member instead rebuilds canonical archives for all physical members in memory, requires every locked dependency to name one of those exact archive/manifest/version/profile identities, and rejects a stale lock before compilation. Both paths validate constraints and complete dependency edges, reject unreachable entries and cycles, and compile dependencies in canonical dependency-first order. `check`, `build`, `test`, selected-target `run`, and workspace `plan` neither resolve, fetch, consult an ambient cache, nor silently omit dependencies. Development edges are loaded only when present in the canonical lock generated with `--development`.

Wheeler source does not yet expose package module imports, so this slice validates and builds each locked package as an independently verified target graph. WIP-0007 module names and visibility will connect exported APIs without changing archive or lock identity.

The local host adapter requires a physical package directory, manifest, and target files. A target path that crosses a symbolic link or resolves outside the package fails before compilation. It reads only the manifest and declared target sources; capability requests remain policy data and do not grant broader host access.

From a source checkout, invoke it through the stage-0 Gradle launcher:

```bash
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='check .'
```

## Local registry transport

A file repository is a physical directory with two internal trees:

```text
archives/<archive-sha256>.wpk
releases/<package-name>/<version>.release.yaml
snapshots/<snapshot-sha256>.snapshot.yaml
```

A release record is strict canonical UTF-8 containing schema, package, version, archive SHA-256, and manifest SHA-256. A schema-1 snapshot is a canonical package/semantic-version-sorted list of every release mapping; duplicate coordinates, malformed identities, noncanonical order, and more than ten thousand releases fail closed. Snapshot identity is SHA-256 over complete canonical snapshot bytes. Publication decodes the archive first, stores bytes by complete content identity, creates the version mapping atomically, then materializes the resulting immutable snapshot object. Resolution scans one bounded mapping view, verifies every referenced archive, materializes that exact snapshot, and binds its identity into every selected schema-3 lock entry. There is no mutable `latest` file. The exact snapshot supplies the authority and identity. Repeating the same publication or snapshot write is idempotent. Reusing a package/version or snapshot identity for different content fails without rewriting existing bytes. An unreferenced content object left by an interrupted or conflicting publication is inert and may be garbage-collected only by a separate audited operation.

Fetch parses the authoritative mapping, then accepts a cached object only after strict archive decoding and exact package, version, archive, and manifest comparison. A miss reads the named repository object, performs the same checks, and inserts it atomically. A missing or malformed authoritative mapping fails before cache lookup. A missing or corrupt repository object succeeds only when the expected cache object independently verifies; otherwise fetch fails before output replacement. The default local publication creates physical XDG directories component by component and rejects symbolic links; explicit physical registry roots must already exist. The cache contributes no resolver candidates; corrupt or oversized regular entries are deleted and refetched, while links fail closed. This transport intentionally has no network, build-output cache, credentials, mutable overwrite, yanking, signing, or namespace-ownership proof; those remain requirements for a public registry.

## Security boundary

Manifest declarations do not grant capabilities. They are requests consumed by a root build policy. Credentials, environment variables, home paths, provider sessions, clocks, random state, and mutable calibration never enter canonical manifests or archives.

Archive signatures and registry namespace authorization are separate layers. Content identity establishes bytes, not code correctness or publisher authority.

## Wheeler-native manifest slice

The Wheeler-written codecs live under canonical `wheeler.packages`. Its entryless library locks `wheeler.compiler` for the shared scanner and `wheeler.core` for binary and SHA-256 tools. Executable roots remain in `wheeler-examples`, which consumes every required exact archive. Fixtures may read canonical source for differential compilation, but package-codec authority stays in the canonical library.

`NativeManifest.w` imports `packages/manifest/Manifest.w`, the focused `ManifestTokens.w` comparison layer, and the shared scanner. It parses strict canonical YAML into four caller-owned tables:

- ten-word target rows;
- two-word source-selector rows;
- five-word dependency rows;
- four-word capability rows.

The result keeps quote-free ranges for package name, version, and profile, plus exact collection counts. It does not allocate host strings. Targets, selectors, dependencies, and capability name/path pairs must arrive in canonical lexical order. A duplicate therefore fails at the same boundary as disorder.

Each modular target may have a bounded nonempty source list. Every selector is checked, and at least one selector must equal or contain the root. A nonmodular target uses the root as its only source. `deployable` and `tool` targets may be selected for tests; `library` targets may not. Dependency kinds remain `normal`, `development`, and `build`. `runtime` is not a dependency kind.

`Names.w` checks lowercase dotted package and dependency names plus Java-style dotted root modules. `Paths.w` rejects absolute paths, trailing slashes, backslashes, empty parts, and `.` or `..`. `Semver.w` accepts bounded three-part releases, prerelease identifiers, and exact, caret, or tilde constraints. It rejects leading zeroes, malformed or overflowing parts, and empty identifiers. Build metadata is outside this slice.

`ManifestEmitter.w` publishes the exact validated canonical bytes and emits no prefix after failure. The `demo.native` fixture covers two targets, a modular source pair, two dependencies, two capabilities, all three header ranges, and exact rewind. A generated manifest with empty dependency and capability sections fills all eight target slots and passes the independent stage-0 parser. A ninth target fails before publication.

Wrong schemas or kinds, test-selected libraries, bad names or paths, unsorted selectors, and selector sets that miss the root also fail closed. The parser loops allow at most 512 targets, dependencies, or capabilities and 1,024 selectors under the 4,096-byte native recovery input profile. The wider stage-0 limits still need larger scanner and I/O buffers, owned decoded values, and computed identities.

## Wheeler-native lock slice

`NativeLock.w` uses the shared scanner and name/version checks. It parses schema-3 YAML into caller-owned package columns, per-package edge windows, and a flat dependency-target table.

The parser accepts canonical empty locks and any sorted package or dependency that fits those tables. It checks lowercase root, repository, snapshot, archive, and manifest identities plus releases. It rejects duplicates and unsorted names. After reading the full package table, it resolves every dependency edge, including forward references.

Shared `LineEmitter.w` publishes the exact validated bytes, and the independent stage-0 lock parser accepts them. The executable fixture provides six package slots and sixteen edge slots; the two-package forward-edge case and generated empty and six-package cases pass. A seventh package, schema drift, uppercase hex, duplicate or unsorted package or dependency names, and an unknown target fail before publication.

The fixture remains below the VM history ceiling. Under the 4,096-byte recovery input profile, parser loops cap packages at 512 and edges at 1,024. Schema 3 allows 10,000 packages, which needs wider scanner and I/O limits. Hash computation also remains future work. Syntax checking validates the digest field; computing and comparing the digest establishes identity.

## Wheeler-native workspace slice

`NativeWorkspace.w` and `packages/workspace/Workspace.w` parse a checked workspace and profile header into four caller-owned range tables. Names use the stage-0 lowercase dot and hyphen profile. Paths use nonempty dotted segments made from letters, digits, underscores, and hyphens.

Names must arrive in lexical order. Each path must be unique and must not nest under a prior path. Shared `LineEmitter.w` writes exact canonical bytes with a final newline, and the independent stage-0 parser accepts them.

The executable fixture has sixteen slots. Five named members cover normal parsing, all sixteen pass in a generated differential case, and a seventeenth member fails before publication. Duplicate names, duplicate or nested paths, traversal, malformed names, capacity exhaustion, and noncanonical input order all fail closed.

The parser loop allows at most 512 records under the 4,096-byte recovery profile. The caller's table size is often the tighter limit. Supporting the schema's 10,000-member ceiling requires wider scanner and I/O limits.

## Wheeler-native plan slice

`NativePlan.w`, `packages/resolution/Plan.w`, and `PlanIdentity.w` read a binary `byteview`. They require `WPLN` schema 1 framing, exact payload and file lengths, and all 32 bytes of the trailing digest. Wheeler-written `crypto/Sha256.w` hashes only the declared payload.

The bounded decoder accepts exactly one node. That node may have zero or one checked package input, zero or one requested capability, and an optional grant that exactly matches the request and cannot exceed it. The decoder checks ASCII profile, package, and target names; a numeric three-part release; one logical output path; target kind 1 through 3; and five bounded execution limits.

It consumes the payload exactly and rebuilds the length-prefixed `wheeler-build-node-1` identity input. That input includes lowercase content identities and decimal limits. Wheeler SHA-256 must match the encoded node identity.

Independent stage-0 fixtures cover an empty policy and one package input with one requested and granted capability. The empty-policy run rewinds to the caller-owned input baseline. The suite rejects payload or digest damage, an invalid target kind, and a forged node identity even when the test recomputes the payload digest.

This slice does not decode multiple nodes, larger input or capability lists, prereleases, or Unicode strings. It also does not canonically re-encode the model. It is a digest-checked structural inspector, not permission to execute a plan. SHA-256 protects meaning only when the expected digest comes from a trusted source.

## Wheeler-native archive slice

`NativeArchive.w` and `packages/archive/Archive.w` read one binary `.wpk`. They check the trailing payload digest, schema-1 magic, bounded manifest length, one or two sorted entry headers, printable ASCII logical paths, exact file consumption, and each entry-data digest.

The decoder copies the manifest into bounded region storage, freezes it as strict UTF-8, invokes the shared scanner and manifest parser, and publishes the exact validated canonical-YAML bytes. The full entry-path set must equal the parsed target source set, or just the root for a nonmodular target.

Both digests use Wheeler `crypto/Sha256.w`; stage 0 independently accepts the encoded fixture. Damage to the outer digest fails. Changing an entry path or its data also fails after the test recomputes the outer digest. A successful run rewinds all scratch and caller-visible state.

The current manifest check covers one bounded native target, not every stage-0 declaration. It also omits more than two entries, reserved `wheeler.package.yaml` rejection, the wider manifest profile, UTF-8 paths, and final archive identity. The slice can inspect one integrity-checked archive, but it cannot install one yet. An extractor needs closure checks before it's more than a file copy.

## Implementation direction

The workspace and package parsers, resolver, lock codec, build-plan codec, and archive codec are stage-0 conformance implementations. Their malformed-input, resolution, and ordering suites define executable schemas for the Wheeler implementation. The package manager, standard library, and self-hosted compiler will consume the same canonical records; the Java implementation is removed at native cutover instead of retained as a second resolver.
