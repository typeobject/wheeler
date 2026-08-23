---
title: Packages, Locks, and Builds
description: Canonical manifests, archives, repositories, plans, tests, and offline execution.
---

# Packages, Locks, and Builds

A ship may carry source farther than its first compiler survives. Wheeler packages
therefore bind names, bytes, dependencies, authority, and build work in canonical
forms that can cross a closed link without consulting the place they came from.

Stage 0 accepts canonical workspace and package manifests, schema-3 locks,
content-addressed `.wpk` archives, immutable repository snapshots, source-bound
build plans, disposable verified caches, and offline locked builds.

## Canonical YAML

Workspace, package, lock, release, and snapshot records use one strict YAML
profile: UTF-8, LF endings, two-space indentation, block mappings and sequences,
quoted strings, decimal integers, booleans, full-line comments, and one final
newline.

The codec rejects duplicate or unknown keys, implicit strings, nulls, floats,
timestamps, tabs, anchors, aliases, tags, merge keys, flow mappings, block
scalars, and multiple documents.

Canonical output orders `schema`, `package`, `targets`, `dependencies`, and
`capabilities`. Package fields are `name`, `version`, and `profile`. Targets sort
by name, dependencies by package name, and capabilities by name then path.
Comments and input mapping order do not affect identity.

Canonical identity is SHA-256 over canonical bytes. A digest identifies accepted
bytes. Schema validation gives those bytes their type.

## Workspaces

A workspace names one profile and one or more package directories:

```yaml
schema: 1
workspace:
  name: "wheeler"
  profile: "bootstrap-1"
members:
  - name: "wheeler-compiler"
    path: "wheeler-compiler"
  - name: "wheeler-runtime"
    path: "wheeler-runtime"
```

Members sort by canonical name. Names and paths are unique. Member roots cannot
nest. Logical paths use `/`, remain case-sensitive, and reject absolute roots,
empty components, `.`, `..`, backslashes, NUL, and symbolic-link crossings.

`wheeler check` visits members and targets in canonical order. `wheeler build`
places member outputs under `<output>/<member-name>/`.

## Package manifests

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
dependencies:
  - kind: "build"
    name: "wheeler.bytecode"
    version: "^0.1.0"
capabilities:
  - name: "build.read"
    path: "src/**"
```

Target kinds are `deployable`, `library`, and `tool`. Deployable and tool targets
may set `test: true`. A library is modular and entryless. Its inert internal
`$library` entry keeps the container structurally valid.

A single-source target declares `root`. A modular target also declares its root
module and sorted source selectors. A selector names one file or one physical
directory. Directory selection walks regular nonsymlink `.w` files in canonical
logical-path order. A target may contain at most 1,024 files.

Dependency kinds are `normal`, `development`, and `build`. Names use lowercase
dotted namespaces. Versions use three numeric parts with an optional prerelease.
Constraints accept exact, `=`, `^`, and `~` forms.

Capabilities in a manifest are requests. They grant no ambient authority.

## Resolution and locks

Resolution examines immutable repositories in caller or policy order. The first
authoritative repository with an admissible profile and version owns that lookup.
A lower-trust source cannot replace it with a newer release.

Exact requirements select one version. Caret ranges remain below the next
compatible major boundary, narrowed appropriately for `0.x`. Tilde ranges remain
inside one major and minor pair. A stable minimum excludes prereleases unless the
requirement names one.

The solver permits at most 10,000 packages and 10,000 deterministic state and
candidate visits. Development dependencies enter only when requested for the
root, and never propagate from selected dependencies.

When an output lock exists, resolution first tries its exact still-authorized
choices. `--update <package>` restores normal highest-compatible ordering for one
named reachable package and may repeat for distinct names. `--update-all` drops
all preferences. The forms cannot be combined.

A schema-3 lock binds the root manifest and every selected repository, snapshot,
version, archive, manifest, and dependency edge:

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
```

Package and dependency rows sort by name. Repository identity denotes a trust
domain rather than an alias, URL, path, or policy position. A locked build reads
its exact archives and performs no ambient resolution or fetch.

## Package archives

A `.wpk` is little-endian:

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

Entries sort by logical path. The manifest is stored separately, and
`wheeler.package.yaml` is reserved as an entry name. Every target source must be
present.

An archive may contain at most 16 MiB, 10,000 entries, and 4,096 bytes in one
path. The decoder rejects unordered, duplicate, escaping, malformed, truncated,
trailing, or digest-damaged input. Archive identity covers the complete encoded
archive, including its trailing payload digest.

## Build plans

A `wheeler.workspace.plan` binds workspace identity, compiler identity, profile,
sources, output paths, exact package inputs, capability requests and grants, and
execution limits.

```text
byte[8] magic = "WPLN\0\0\0\1"
u32 schema = 1
u32 payload_length
payload {
    byte[32] workspace_sha256
    byte[32] compiler_sha256
    string profile
    u32 node_count
    repeated node { ... }
}
byte[32] payload_sha256
```

Each node has this canonical payload shape:

```text
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
```

The node binds package and target coordinates, manifest and source identities,
output path, direct archive inputs, capabilities, and five limits. Stage-0 defaults
are 10,000,000 steps, 256 MiB memory, 64 MiB input, 64 MiB output, and 60 seconds.
Strings may contain at most 4,096 bytes. A complete plan may contain at most
16 MiB.

The executor rederives compiler, workspace, source, dependency, output, and policy
identities from the physical workspace. Every value must match. Publication uses
a new sibling staging tree and rejects existing destinations, symbolic links,
stale plans, partial grants, missing outputs, and extra files.

The current host enforces output and elapsed-time limits. Hard process-memory and
compiler-work isolation await the Wheeler-native build engine and receive no
implied guarantee from the plan.

## Cache and quarantine

`wheeler-build-input-1` binds workspace, compiler, profile, and node identity. The
XDG cache stores one accepted prior verified output for that input plus a
content-addressed artifact.

A cache hit is decoded, canonically re-encoded, and rebuilt into the exact closed
output tree. One miss rebuilds the whole tree. If a new verified output differs
from the accepted prior output, Wheeler places the observed bytes and evidence in
quarantine and stops publication.

Deleting the disposable cache changes no lock, plan, artifact, or diagnostic
identity. Garbage collection examines at most 10,000 entries and never removes
quarantine or repository objects.

## Repository authority

A file repository contains:

```text
archives/<archive-sha256>.wpk
releases/<package-name>/<version>.release.yaml
snapshots/<snapshot-sha256>.snapshot.yaml
signatures/<snapshot-sha256>.<key-sha256>.snapshot-signature.yaml
```

Release mappings and snapshots are immutable. One snapshot lists at most 10,000
package-version coordinates in canonical order. Publication stores content by
identity, creates the release mapping, and materializes the resulting snapshot.
There is no mutable `latest` file.

A repository policy may trust 0 through 16 Ed25519 keys. Detached signatures bind
the stable repository identity and complete canonical snapshot. If a policy names
trusted keys, resolution and exact fetch require a valid trusted signature. Every
present envelope for a considered trusted key must also verify.

The unsigned default `local` repository remains available until its operator adds
trust. The current transport has no public-network namespace delegation, yanking,
threshold signing, or mirror protocol.

## Commands

```text
wheeler check <package-or-workspace-directory>
wheeler build <package-or-workspace-directory> [-o output-directory]
wheeler test <package-or-workspace-directory> [--format terminal|json|junit-xml] [--shard INDEX/COUNT] [--tag NAME]...
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
wheeler repository trust <alias> <public-x509-der>
wheeler repository untrust <alias> <key-identity>
wheeler repository sign <alias> <private-pkcs8-der> <public-x509-der>
wheeler repository verify <alias>
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

`check` compiles and verifies without output. `build` publishes canonical target
artifacts. `clean` removes only the default physical build tree after proving it
contains no links or unexpected file kinds.

`run --input` supplies one strict UTF-8 file. `--input-bytes` supplies an immutable
binary view. `--output <file> --output-bytes <count>` supplies a zero-filled owner
and publishes the selected prefix only after success. Each effect path must be a
physical nonsymlink file and must agree with the entry signature.

Atomic replacement controls which complete userspace tree becomes visible. It
alone does not prove survival through power loss.

## Tests

`wheeler test` selects deployable and tool targets marked for tests. Each selected
source declaration becomes a separate artifact and runs in a fresh VM. Cases sort
by lexical qualified name. Inline case rows retain declaration order. Quantum
entries use the ideal target.

Diagnostics are `WTEST001` for compile rejection, `WTEST002` for a runtime trap,
and `WTEST003` for a failed Wheeler assertion. One failed case does not hide later
cases.

Report profile 2 binds case, source, artifact, execution, compiler, assertion
count, transition coverage where applicable, and final report identity. Terminal,
canonical JSON, and JUnit XML are presentation forms outside the semantic identity.

`--shard INDEX/COUNT` assigns cases by complete case-identity digest. Shards are
disjoint and reduce to the serial report in any arrival order. The
The native conformance targets reproduce case identity, shard assignment, canonical outcome order, summaries, execution and coverage identities, failure diagnostics, and report identities for up to 255 cases.

`nativetestrunner` validates a canonical package manifest of at most 28,672 bytes, schema-3 root lock, runnable target, root module, ordered case names, descriptors, and one manifest-selected source plan before execution. Nonempty lock entries receive structural, lowercase-identity, and ordering validation. Every direct manifest dependency name must occur in the lock package set. Exact, caret, and tilde constraints must accept the locked semantic version. Prerelease precedence is native, and stable minima never select preview candidates. Every lock dependency edge must name another package entry. Native graph reduction rejects cycles and packages unreachable from direct manifest dependencies. The native package authority validates bounded complete archives against exact lock-row archive, manifest, and package-name identities. It projects exact checked entry paths and source bytes by ordinal. Runtime source-plan authority qualifies each projected path as `dependencies/<package>/<path>` and merges it under canonical byte order. For standalone vendored packages, `wheeler test` transports exact direct normal dependency archives and runs admitted cases natively. The bounded profile accepts one or two direct archives, permits one through four entries in each archive, limits the combined entry count to seven, and rejects archive subsets. One local root plus seven external modules fills the eight-source compiler plan. Each archive manifest's canonical normal dependency names must equal its selected lock-row edges. Source plans require strict UTF-8, unique modules, resolved acyclic ordered local imports, and exact source identity. Shard selection precedes verification, compilation, and execution.

A one-case descriptor over one root and up to seven local imported sources may carry zero artifact bytes. An entry case name must be the selected target plus `::entry`. The runtime compiles the validated source set natively and feeds the exact committed artifact into the same profile-2 path as transported bytes. A target with up to 128 root test cases and up to seven local imports may instead submit zero artifact bytes for every descriptor. Parameterless cases use `<target>::<declaration>`. Canonical `long` and `boolean` rows use `<target>::<declaration>[<ordinal>]`. Native source mode enforces canonical `limits(steps = N, history = N)` step bounds for transported and native-compiled artifacts. A sorted selected-tag frame filters canonical `tags(...)` declarations by conjunction before identity, sharding, or compilation. Unknown selected tags reject. Case-count byte 255 asks the runtime to construct declaration-only conformance names and execute the complete selected descriptor set without caller-supplied names or artifacts. Byte 254 derives module-qualified package case names from the validated root source before the same sort, compile, and execution path. In a checked-out workspace, `wheeler test` requires native selected, passed, and failed count parity for every eligible test-selected target. Each target may carry one root and up to seven local scalar-import modules in a complete source plan of at most 40,960 bytes. Each physical source remains bounded to 32,768 bytes. An imported source may expose up to 256 public signed constants and twenty-three public signed or Boolean functions. Packages with dependencies send their physical lock through native graph and version validation when all selected test imports remain package-local. External dependency imports remain outside this fixed compiler profile. Bounded archive provenance, entry projection, package-qualified source-plan composition, one-archive native import compilation, and standalone package-command transport are complete. The native package path fills the eight-source plan from two direct package namespaces or from one direct package followed by one locked normal dependency. Root source cannot import the transitive package directly. Broader dependency graphs remain. Multi-target tag conjunction runs inside each native target. Metadata-only native probes reject tags absent from the package-wide union before stage-0 discovery. Actual selected cases still compile and execute once. Native target report identities and summaries reduce into one sorted, domain-separated package evidence identity without host hashing. Up to 128 selected package rows also reduce into one native case-ordered profile-2 report and combined report identity. The compiler package uses this path for its checked-in seven-module physical compiler spine suite. The runner publishes complete profile-2 case rows in strict case-identity order. Eligible package commands return those rows without Java discovery, compilation, execution, or outcome policy. The runtime adapts native semantic rows to terminal text, canonical JSON, and JUnit XML. Native discovery lowers and compiles each declaration without a Java-supplied artifact.

For transported artifacts, the native runner discovers up to 128 root `test void` cases through the canonical lexer. Parameterless declarations use `<target>::<declaration>`. One `long` or `boolean` parameter with canonical literal `cases(...)` rows uses `<target>::<declaration>[<ordinal>]`. The runner requires complete, unique descriptors in canonical order before identity or execution. Each selected artifact is verified exactly once. For discovered tests, the runtime requires artifact function zero to equal `<root-module>::<declaration>` before interpretation. Parameterized artifacts must install the exact native-discovered row value through the canonical synthetic entry. The interpreter runs only the accepted immutable bytes, and failure diagnostics reuse the retained verifier outcome. Case identity, execution, diagnostics, report reduction, and summary reduction remain `wheeler.runtime` operations. Conformance targets only publish results and make no Java semantic callback.

Package source discovery, descriptor construction, and rendering still use the stage-0 runner. Native execution hashes the canonical discovered source plan once for every selected case. Repeated `--tag` arguments select their intersection.

## Vendored and locked work

A vendor tree is a flat relocatable input set made from one explicit catalog. It
contains the exact schema-3 lock and one archive per selected package. Existing
output counts as success only when every filename and byte already matches.

Workspace members rebuild physical member archives in memory and require the lock
to name those exact identities. Standalone packages use a vendor tree. Check,
build, test, selected-target run, and plan neither resolve nor fetch while loading
locked dependencies.

Direct package imports may see only declared public modules. Private and
transitive source remains unavailable. There is no process-wide classpath.

## Present boundary

The accepted package graph is source-package based and uses one selected instance
of each package name. Coexisting instances, complete recipe revisions, variants,
system-package exports, native FFI providers, network mirrors, and self-contained
platform images have no accepted schema fields.

Credentials, environment variables, home paths, clocks, mutable calibration, and
provider sessions never enter canonical manifests or archives. Content identity
establishes bytes, rather than correctness or publisher authority.
