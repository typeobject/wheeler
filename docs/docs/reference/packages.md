# Package format

Wheeler package metadata uses its own declarative syntax and canonical archive. The current stage-0 implementation parses `wheeler.workspace` and `wheeler.package`, resolves an immutable package catalog, reads and writes canonical `wheeler.lock`, loads exact offline dependencies, emits, verifies, and executes source-bound build plans, and reads and writes content-addressed `.wpk` archives. A physical local registry supports immutable publish/fetch transport. Network transport, namespace authorization, source module imports, and the Wheeler-written native implementation remain package-system work.

## Workspace manifest

A workspace manifest names one profile and one or more package directories:

```text
workspace "wheeler" profile "bootstrap-1";
member "examples" path "wheeler-examples";
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
target example "module-demo" root "src/Main.w" module "demo.main"
    source "src/Arithmetic.w" source "src/Main.w";
dependency build "wheeler.bytecode" version "^0.1.0";
capability "build.read" path "src/**";
capability "build.write" path "out/**";
```

Target kinds are `library`, `binary`, `tool`, `test`, and `example`. A single-source target has only `root`. A module target additionally declares its root module and every source path with repeated `source` fields. Source paths are canonicalized lexically, must be unique, must include `root`, and are capped at 1,024. Compilation derives and verifies each file's `module` declaration, then applies the closed module-graph rules in the [language profile](language-profile.md); paths never imply module names. Dependency kinds are `normal`, `development`, and `build`. Versions are three-part semantic versions with an optional prerelease. Constraints accept exact, `=`, `^`, and `~` spelling; the resolver applies the semantics described below.

The grammar has words, quoted strings, semicolons, and `//` comments. Strings support only `\\` and `\"` escapes and cannot cross line boundaries. Unknown declarations and fields fail closed with line and column.

A manifest must declare at least one target. Package and dependency names use lower-case dotted namespaces. Duplicate target names, dependency names, and capability-name/path pairs are rejected.

## Resolution and lockfiles

`PackageResolver` operates only on an application-supplied immutable catalog of manifests and verified archive identities. `wheeler resolve` supplies that catalog from physical `.wpk` files in one explicit directory, sorted by file name and strictly decoded before resolution. It ignores unrelated file suffixes and rejects archive symlinks. Neither layer reads a network, registry, clock, environment, or implicit host package cache. It sorts package names and candidate releases, tries the highest compatible release, and performs bounded deterministic backtracking when transitive requirements conflict.

Exact requirements select one version. Caret requirements remain below the next compatible major boundary, with the usual narrower `0.x` boundaries. Tilde requirements remain within one major/minor pair. Stable releases sort after prereleases for an equal release tuple. Duplicate catalog versions, missing solutions, root self-dependencies, cyclic selected graphs, and graphs over 10,000 packages fail closed. Development dependencies enter the graph only when explicitly requested.

The generated `wheeler.lock` records the schema, root manifest identity, exact selected versions, archive identities, manifest identities, and dependency edges:

```text
lock 1 root "0000000000000000000000000000000000000000000000000000000000000000";
package "wheeler.bytecode" version "0.1.0" archive "1111111111111111111111111111111111111111111111111111111111111111" manifest "2222222222222222222222222222222222222222222222222222222222222222";
package "wheeler.compiler" version "0.1.0" archive "3333333333333333333333333333333333333333333333333333333333333333" manifest "4444444444444444444444444444444444444444444444444444444444444444";
edge "wheeler.compiler" "wheeler.bytecode";
```

Package records and edges are sorted. `PackageLockParser` accepts only the canonical UTF-8 encoding with a final newline, known records, valid identities, and edges whose endpoints exist. Lock identity is SHA-256 over those canonical bytes.

## Build plan

A `wheeler.plan` file fixes the workspace identity, compiler artifact identity, profile, target source identities, output paths, exact package inputs, requested capabilities, execution limits, and explicit capability grants. The stage-0 command derives this identity from the sorted class bytes of the executing compiler and canonical bytecode implementation. Planning therefore cannot label ambient compiler code with a caller-supplied digest, and execution rejects a plan produced by different stage-0 bits.

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

A string is a `u32` byte length followed by strict UTF-8 and is limited to 4,096 bytes. Lists carry bounded `u32` counts. Target kind codes 1 through 5 denote library, binary, tool, test, and example. The complete plan is limited to 16 MiB. Decoding verifies the payload digest, every embedded identity and invariant, complete consumption, and byte-for-byte canonical re-encoding.

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
wheeler resolve <package-directory> --catalog <archive-directory> [-o wheeler.lock] [--development]
wheeler verify-lock <wheeler.lock>
wheeler vendor <wheeler.lock> --catalog <archive-directory> -o <vendor-directory>
wheeler publish <package.wpk> --registry <directory>
wheeler fetch <package> <version> --registry <directory> -o <package.wpk>
wheeler plan <workspace-directory> [--grant-requested] [-o wheeler.plan]
wheeler verify-plan <wheeler.plan>
wheeler execute-plan <workspace-directory> <wheeler.plan> -o <new-output-directory>
wheeler compile <source.w> [-o program.wbc]
wheeler run <program.wbc>
wheeler run <package-directory> --target <target>
wheeler disassemble <program.wbc>
wheeler qasm <program.wbc> <output.qasm>
```

`check` compiles and verifies every declared target without writing outputs. `build` writes one canonical `.wbc` per target, named from the target. Locked dependency outputs reside under `dependencies/<package-name>/`; workspace builds place each root package and its dependency tree in the member-named output directory. `test` compiles and executes only targets declared with kind `test`, in canonical workspace/package/target order, using the same ideal state-vector target as ordinary deterministic CI. A package with no test targets succeeds with a zero-target report. `clean` removes only the default physical `out` tree and rejects files or symbolic links at any level before deleting anything. `package` includes canonical manifest data and every declared target source. `verify` performs strict archive decoding before printing identity. `resolve` selects from an explicit verified archive catalog and atomically writes canonical lock data; development dependencies enter only with `--development`. `verify-lock` accepts only canonical lock encoding before printing identity. `vendor` materializes exactly the locked archive set plus the canonical lockfile from an explicit verified catalog. `publish` validates an archive and idempotently installs its content plus one immutable name/version mapping in an explicit physical local registry. `fetch` verifies that mapping and the complete archive before atomically writing output. `plan` hashes declared workspace sources and emits a canonical build plan with a content-derived stage-0 compiler identity, fixed conservative per-node limits, separated capability requests and grants, and no ambient authority. Grants are empty unless the caller explicitly supplies `--grant-requested`; that switch grants exactly the declared requests and nothing else. `verify-plan` validates all structural and content identities before printing plan identity. `execute-plan` accepts only a plan whose compiler identity, workspace identity, profile, sources, exact dependency archives, outputs, limits, requests, and complete grants rederive byte-for-byte from the current physical workspace. It builds into a new sibling staging tree, verifies that every declared output and no other file is canonical `.wbc` within its output/time limits, and publishes the directory with an atomic move; stale plans, partial grants, symlinks, preexisting destinations, extra files, missing files, and partial failures are rejected. `run` accepts either a verified artifact or an explicitly selected binary, tool, or example package target; `--input <utf8-file>` binds one explicitly requested physical nonsymlink file when the entry declares an UTF-8 borrow. `--output <file> --output-bytes <count>` binds a bounded zeroed byte output and atomically replaces the destination with the program-selected prefix only after successful execution; missing, unexpected, oversized, or partial effect options fail closed. Library and test targets use their dedicated operations. Output replacement uses a sibling temporary file and atomic move when the host supports it.

## Vendored inputs

A vendor tree is a flat, relocatable offline input set. Archive names contain package name, exact version, and full archive SHA-256; `wheeler.lock` is copied byte-for-byte. Catalog entries not present in the lock are excluded.

Vendoring verifies archive and manifest identities against every lock entry. An existing output directory is accepted only when its complete file-name set and every byte already match the expected tree, making retries idempotent. Missing, extra, corrupt, linked, nonregular, or duplicate-version inputs fail without being treated as a cache hit. A new tree is assembled and verified in a sibling temporary directory before an atomic directory move when supported. The output directory path does not enter any content identity.

## Locked dependency compilation

A package with dependencies must contain a physical `vendor/` directory produced by `wheeler vendor`. The loader verifies its canonical lock against the root manifest, requires exactly one correctly named archive per lock entry and no extra files, decodes every archive, checks package/version/archive/manifest/profile identities, validates constraints and complete dependency edges, rejects unreachable entries and cycles, and then compiles dependencies in canonical dependency-first order. `check`, `build`, `test`, selected-target `run`, and workspace `plan` all use this path; none resolve, fetch, consult an ambient cache, or silently omit dependencies. Development edges are loaded only when present in the canonical lock generated with `--development`.

Wheeler source does not yet expose package module imports, so this slice validates and builds each locked package as an independently verified target graph. WIP-0007 module names and visibility will connect exported APIs without changing archive or lock identity.

The local host adapter requires a physical package directory, manifest, and target files. A target path that crosses a symbolic link or resolves outside the package fails before compilation. It reads only the manifest and declared target sources; capability requests remain policy data and do not grant broader host access.

From a source checkout, invoke it through the stage-0 Gradle launcher:

```bash
./gradlew :wheeler-tools:wheeler --args='check .'
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

## Wheeler-native header slice

`NativeManifest.w` imports `packages/Manifest.w` and the shared Wheeler scanner. It accepts explicit UTF-8, requires `package STRING version STRING profile STRING ;` followed by zero or one bounded `target TARGET_KIND STRING root STRING ;` and zero or one `dependency DEPENDENCY_KIND STRING version STRING ;` and zero or one `capability STRING path STRING ;`, and returns quote-free typed source ranges without allocating host strings. `Names.w` enforces lowercase dotted package and dependency names with a letter at each segment start, `Paths.w` rejects absolute, trailing-slash, backslash, empty-component, and `.`/`..` logical paths, and the manifest parser rejects empty quoted fields. `Semver.w` accepts bounded three-part releases, SemVer prerelease identifiers, and exact, caret, or tilde constraints. It rejects leading zeroes in release components and numeric prerelease identifiers, empty identifiers, invalid identifier bytes, and components above `Long.MAX_VALUE`; build metadata remains outside this slice. `ManifestEmitter.w` copies validated token values into canonical single-space records, suppresses spaces before semicolons, selects the exact output prefix only after a successful parse, and never treats skipped input trivia as semantic data. The executable fixture records header lengths `11`, `10`, and `11` plus target lengths `3` and `9` and dependency lengths `9` and `6` plus capability lengths `7` and `9` for `demo.native`, `1.2.3-rc.1`, `boot\"strap`, `app`, `src/App.w`, `demo.base`, `^1.0.0`, `fixture`, and `test-data`, normalizes surplus input whitespace, rewinds exactly, and rejects a substituted declaration keyword, an uppercase or malformed package/dependency name, a leading-zero release or numeric prerelease, an overflowing component, traversal, a decoded backslash path, or an unsupported string escape. Repeated records, module/source lists, other capability kinds, escape decoding, duplicate detection, and general sorting remain stage-0 work. The accepted target kinds are `app`, `library`, `tool`, `test`, and `example`; dependency kinds are `normal`, `development`, and `build`. `runtime` is not a dependency kind, however earnestly named. This is the first parser rivet, not the whole bridge.

## Implementation direction

The workspace and package parsers, resolver, lock codec, build-plan codec, and archive codec are stage-0 conformance implementations. Their malformed-input, resolution, and ordering suites define executable schemas for the Wheeler implementation. The package manager, standard library, and self-hosted compiler will consume the same canonical records; the Java implementation is removed at native cutover rather than retained as a second resolver.
