# Package format

Wheeler package metadata uses its own declarative syntax and canonical archive. The current stage-0 implementation parses `wheeler.package`, constructs immutable manifests, and reads and writes content-addressed `.wpk` archives. Dependency resolution, lockfiles, workspaces, build plans, registries, and the Wheeler-written `wheeler` command remain package-system work.

## Manifest

A manifest begins with exactly one package declaration:

```text
package "wheeler.compiler" version "0.1.0" profile "bootstrap-1";
```

It then contains target, dependency, and capability declarations in any source order:

```text
target tool "wheelc" root "src/compiler.w";
dependency build "wheeler.bytecode" version "^0.1.0";
capability "build.read" path "src/**";
capability "build.write" path "out/**";
```

Target kinds are `library`, `binary`, `tool`, `test`, and `example`. Dependency kinds are `normal`, `development`, and `build`. Versions are three-part semantic versions with an optional prerelease. Constraints currently accept exact, `=`, `^`, and `~` spelling as canonical data; resolution semantics are not implemented yet.

The grammar has words, quoted strings, semicolons, and `//` comments. Strings support only `\\` and `\"` escapes and cannot cross line boundaries. Unknown declarations and fields fail closed with line and column.

A manifest must declare at least one target. Package and dependency names use lower-case dotted namespaces. Duplicate target names, dependency names, and capability-name/path pairs are rejected.

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

## Security boundary

Manifest declarations do not grant capabilities. They are requests consumed by a root build policy. Credentials, environment variables, home paths, provider sessions, clocks, random state, and mutable calibration never enter canonical manifests or archives.

Archive signatures and registry namespace authorization are separate layers. Content identity establishes bytes, not code correctness or publisher authority.

## Implementation direction

The package parser and archive codec are stage-0 conformance implementations. Their malformed-input and ordering suites define executable schemas for the Wheeler implementation. The package manager, standard library, and self-hosted compiler will consume the same canonical records; the Java implementation is removed at native cutover rather than retained as a second resolver.
