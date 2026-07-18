# Package format

Wheeler package metadata uses its own declarative syntax and canonical archive. The current stage-0 implementation parses `wheeler.workspace` and `wheeler.package`, resolves an immutable package catalog, reads and writes canonical `wheeler.lock`, emits verified build plans, and reads and writes content-addressed `.wpk` archives. Locked dependency loading, registry transport, and the Wheeler-written native implementation remain package-system work.

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
dependency build "wheeler.bytecode" version "^0.1.0";
capability "build.read" path "src/**";
capability "build.write" path "out/**";
```

Target kinds are `library`, `binary`, `tool`, `test`, and `example`. Dependency kinds are `normal`, `development`, and `build`. Versions are three-part semantic versions with an optional prerelease. Constraints accept exact, `=`, `^`, and `~` spelling; the resolver applies the semantics described below.

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

A `wheeler.plan` file fixes the workspace identity, compiler artifact identity, profile, target source identities, output paths, exact package inputs, and requested capabilities. The stage-0 command requires the compiler SHA-256 explicitly; an ambient compiler installation never enters a plan by implication.

Each node identity is SHA-256 over length-prefixed canonical fields. Nodes sort by package and target name. Package inputs sort by package name, capabilities sort by name and path, and output paths must be unique. Duplicate coordinates, outputs, node identities, inputs, and capabilities fail closed.

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
        u32 capability_count
        repeated capability_request { string name; string path_pattern; }
    }
}
byte[32] payload_sha256
```

A string is a `u32` byte length followed by strict UTF-8 and is limited to 4,096 bytes. Lists carry bounded `u32` counts. Target kind codes 1 through 5 denote library, binary, tool, test, and example. The complete plan is limited to 16 MiB. Decoding verifies the payload digest, every embedded identity and invariant, complete consumption, and byte-for-byte canonical re-encoding.

The current workspace planner accepts packages without dependencies and hashes only declared physical target roots. A package with dependencies fails until exact locked archive inputs can be attached; dependencies are never silently omitted. Capability records are requests for root policy, not grants.

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

Entries are ordered by logical path. The manifest is stored separately and `wheeler.package` is reserved as an entry name. Every declared target root must be present. Duplicate, unordered, escaping, oversized, malformed UTF-8, truncated, trailing, entry-corrupt, and archive-corrupt data is rejected.

The current ceiling is 16 MiB, 10,000 entries, and 4,096 path bytes. Archive identity is SHA-256 over the complete encoded archive, including its payload digest. Manifest identity and archive identity are deliberately different.

Decoded entry byte arrays are defensively copied. A caller cannot mutate verified package state through a retained host buffer.

## Stage-0 command

The unified command executes local package operations:

```text
wheeler check <package-or-workspace-directory>
wheeler build <package-or-workspace-directory> [-o output-directory]
wheeler test <package-or-workspace-directory>
wheeler package <package-directory> [-o package.wpk]
wheeler verify <package.wpk>
wheeler resolve <package-directory> --catalog <archive-directory> [-o wheeler.lock] [--development]
wheeler verify-lock <wheeler.lock>
wheeler plan <workspace-directory> --compiler <sha256> [-o wheeler.plan]
wheeler verify-plan <wheeler.plan>
wheeler compile <source.w> [-o program.wbc]
wheeler run <program.wbc>
wheeler disassemble <program.wbc>
wheeler qasm <program.wbc> <output.qasm>
```

`check` compiles and verifies every declared target without writing outputs. `build` writes one canonical `.wbc` per target, named from the target. Workspace builds place each package in its member-named output directory. `test` compiles and executes only targets declared with kind `test`, in canonical workspace/package/target order, using the same ideal state-vector target as ordinary deterministic CI. A package with no test targets succeeds with a zero-target report. `package` includes canonical manifest data and every declared target root. `verify` performs strict archive decoding before printing identity. `resolve` selects from an explicit verified archive catalog and atomically writes canonical lock data; development dependencies enter only with `--development`. `verify-lock` accepts only canonical lock encoding before printing identity. `plan` hashes declared workspace sources and emits a canonical build plan with an explicit compiler identity. `verify-plan` validates all structural and content identities before printing plan identity. Output replacement uses a sibling temporary file and atomic move when the host supports it.

The local host adapter requires a physical package directory, manifest, and target files. A target path that crosses a symbolic link or resolves outside the package fails before compilation. It reads only the manifest and declared target roots; capability requests remain policy data and do not grant broader host access.

From a source checkout, invoke it through the stage-0 Gradle launcher:

```bash
./gradlew :wheeler-tools:wheeler --args='check .'
```

## Security boundary

Manifest declarations do not grant capabilities. They are requests consumed by a root build policy. Credentials, environment variables, home paths, provider sessions, clocks, random state, and mutable calibration never enter canonical manifests or archives.

Archive signatures and registry namespace authorization are separate layers. Content identity establishes bytes, not code correctness or publisher authority.

## Implementation direction

The workspace and package parsers, resolver, lock codec, build-plan codec, and archive codec are stage-0 conformance implementations. Their malformed-input, resolution, and ordering suites define executable schemas for the Wheeler implementation. The package manager, standard library, and self-hosted compiler will consume the same canonical records; the Java implementation is removed at native cutover rather than retained as a second resolver.
