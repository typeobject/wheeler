# Bootstrap evidence

A compiler can reproduce its own bugs. That alone doesn't make it trustworthy. WIP-0007 requires two separate checks:

1. stage 0 builds stage 1, and stage 1 builds a byte-identical stage 2.
2. an independently derived trusted compiler produces the same bytes without first running code from the candidate compiler.

The bootstrap gate records successful evidence in `wheeler.bootstrap.yaml`. The repository does not contain that manifest yet because the bounded Wheeler compiler is not self-hosting. Creating the file early would not provide real evidence.

## Profile and module derivation

Publish the complete known feature contract. Callers cannot subtract an inconvenient feature or add one that neither compiler implements:

```text
wheeler bootstrap-features \
  --profile bootstrap-1 \
  --output wheeler.bootstrap-features.yaml
```

Unknown profile names fail without output. The command reparses its canonical bytes before atomic publication.

Derive the compiler target's graph from the canonical source archive rather than maintaining two opinions about its imports:

```text
wheeler bootstrap-modules \
  --source-archive wheeler.compiler.wpk \
  --output wheeler.bootstrap-modules.yaml
```

The command selects the modular `tool` target named `compiler`, parses every `.w` source entry selected by that target, derives external imports, hashes each source, validates the rooted local DAG, reparses the canonical result, and publishes atomically. Sources belonging only to another target, such as the entryless compiler library facade, do not enter this graph. A missing declaration, duplicate module, unsorted import list, dangling local import, cycle, unreachable selected source, link, malformed archive, or changing input produces no output.

The evidence gate derives the same graph independently and requires exact agreement. The generated file is evidence, not authority over source syntax.

## Evidence command

The final stage-0 gate is:

```text
wheeler bootstrap-manifest \
  --source-archive wheeler.compiler.wpk \
  --source-lock wheeler.package.lock.yaml \
  --feature-manifest wheeler.bootstrap-features.yaml \
  --module-manifest wheeler.bootstrap-modules.yaml \
  --options-manifest wheeler.compiler-options.yaml \
  --limits-manifest wheeler.compiler-limits.yaml \
  --ordinary-toolchain ordinary-toolchain.provenance \
  --ordinary-compiler stage0.compiler \
  --ordinary-runtime stage1.runtime \
  --ordinary-verifier verifier.wbc \
  --stage-1 compiler-stage1.wbc \
  --stage-2 compiler-stage2.wbc \
  --ordinary-diagnostics ordinary.diagnostics \
  --diverse-toolchain diverse-toolchain.provenance \
  --diverse-compiler trusted.compiler \
  --diverse-runtime trusted.runtime \
  --diverse-verifier trusted.verifier \
  --diverse-output compiler-diverse.wbc \
  --diverse-diagnostics diverse.diagnostics \
  --acceptance-artifacts acceptance \
  --output wheeler.bootstrap.yaml
```

Each file argument must point to a physical, nonsymlink file no larger than 16 MiB. Only the two diagnostics files may be empty.

The acceptance argument must point to a closed artifact tree. Its canonical `wheeler.artifact-set.json` must still match every `.wbc` file in that tree. The command checks each input before and after reading it, so a file that changes during hashing causes an error.

`NativeArtifactSetIdentity.w` independently reproduces the domain-separated identity for the bounded bootstrap slice: strict canonical JSON no larger than 4,096 bytes and one through eight sorted safe ASCII `.wbc` paths. It rejects forged embedded identities and publishes only the verified 32-byte digest. It does not open the named artifacts. Physical-file closure, bytecode verification, stable reads, and the 65,535-artifact production ceiling remain the stage-0 command's job until WIP-0032 file traversal and the native verifier replace that boundary. Hashing a shopping list does not prove the groceries exist.

Before it publishes anything, the command:

- strictly decodes the canonical `wheeler.compiler` package archive.
- parses the schema-3 snapshot-bound lock and requires its exact canonical YAML bytes.
- binds that lock to the source manifest.
- parses exact schema-1 feature, generated module, option, and limit manifests.
- requires every profile name to match the source package.
- requires the module graph to be closed, acyclic, rooted, and free of dead modules.
- rehashes every declared module source from the compiler archive, reparses its module header, and rejects undeclared `.w` entries.
- independently decodes and re-encodes stage 1, stage 2, and the diverse output.
- compares all three complete `.wbc` byte strings.
- compares the ordinary and diverse diagnostic bytes.
- requires different ordinary and diverse toolchain identities.
- requires different ordinary and diverse compiler identities.
- recomputes the closed acceptance artifact-set identity.
- requires that set to contain the compiler fixed point.
- parses its own output before replacing the destination atomically.

The command never runs a candidate artifact. A static manifest also cannot prove that an earlier build script followed the right order. The promotion job must show that the diverse comparison happened before candidate execution, bind both toolchain provenance files, and run acceptance only after the comparison gate.

Two copies of the same opaque compiler do not count as independent derivations, even when their filenames differ.

## Compiler input schemas

The accepted source profile is an exact `wheeler.bootstrap-features.yaml` vocabulary:

```yaml
schema: 1
profile: "bootstrap-1"
features:
  - name: "affine-borrows"
    version: 1
  - name: "boolean-scalars"
    version: 1
  - name: "bounded-loops"
    version: 1
  - name: "byte-output"
    version: 1
  - name: "byteview-input"
    version: 1
  - name: "checked-arithmetic"
    version: 1
  - name: "compile-time-constants"
    version: 1
  - name: "exhaustive-variants"
    version: 1
  - name: "fixed-scalar-array-fields"
    version: 1
  - name: "generated-inverse-proofs"
    version: 1
  - name: "module-linking"
    version: 1
  - name: "nominal-records"
    version: 1
  - name: "owned-regions"
    version: 1
  - name: "signed-scalars"
    version: 1
  - name: "static-calls"
    version: 1
  - name: "strict-utf8-input"
    version: 1
  - name: "word-buffers"
    version: 1
```

Feature names are sorted and unique. Schema 1 accepts exactly this seventeen-feature `bootstrap-1` set, all at version 1. `NativeBootstrapFeaturesIdentity.w` reconstructs those sole canonical bytes, requires exact complete consumption, and reproduces the stage-0 identity for manifests up to 2,048 bytes. A feature version names a semantic contract, not a marketing release. Unknown, duplicated, missing, reordered, empty, or oversized vocabularies fail closed. Adding a feature therefore requires a new reviewed profile contract and changes its identity even if somebody forgot to update a slide deck.

The exact compiler module closure uses `wheeler.bootstrap-modules.yaml`:

```yaml
schema: 1
profile: "bootstrap-1"
root: "wheeler.compiler"
externals:
  - "wheeler.core"
modules:
  - name: "wheeler.compiler"
    source: "src/main/wheeler/MinimalCompiler.w"
    identity: "<sha256>"
    imports:
      - "wheeler.compiler.backend"
      - "wheeler.core"
  - name: "wheeler.compiler.backend"
    source: "src/main/wheeler/compiler/backend/Codegen.w"
    identity: "<sha256>"
    imports:
      - "wheeler.core"
```

Modules, externals, and imports are sorted and unique. Every local import resolves, every external import is declared, every local module is reachable from the root, the local graph is acyclic, source paths are unique, and each source identity must match the file inside the canonical compiler archive. The bounds are 10,000 local modules, 10,000 external modules, and 100,000 direct imports. `NativeBootstrapModulesIdentity.w` now covers one through thirty-two sorted local modules, zero through thirty-two externals, and 128 imports with unique paths, complete binding, rooted reachability, and cycle detection. It also enforces strict names and paths, exact canonical bytes, and fail-closed identity publication. Its 16,384-byte input budget covers the current twenty-six-module, seventy-two-import, 7,861-byte compiler closure, whose stage-0 identity the native executable reproduces in 3,867,460 transitions. It does not claim the full graph ceiling. A bound written in a comment allocates no table. This manifest records the graph actually trusted for bootstrap. Directory enumeration is not a module system.

Bootstrap options use exact `wheeler.compiler-options.yaml` bytes:

```yaml
schema: 1
compiler:
  profile: "bootstrap-1"
  source-maps: false
```

Limits use exact `wheeler.compiler-limits.yaml` bytes:

```yaml
schema: 1
limits:
  source-bytes: 16777216
  tokens: 100000
  nesting: 256
  declarations: 10000
  symbols: 10000
  instructions: 1000000
  diagnostics: 1000
  heap-bytes: 268435456
  stack-depth: 1024
  steps: 10000000
```

Each limit is a positive canonical integer no larger than 1,073,741,824. The schema requires all ten limits and rejects unknown keys. A launcher must apply the same values to both derivations. `NativeCompilerLimitsIdentity.w` consumes the exact canonical field order and decimal spelling, checks all ten bounds, and reproduces the stage-0 identity for manifests up to 512 bytes. Hashing one limits file while using different limits would make the provenance false.

Source maps may be enabled only when their normalized logical source identities are part of the canonical output.

`NativeCompilerOptionsIdentity.w` accepts exactly the schema-1 canonical bytes, a 1--128 byte profile in the declared identifier alphabet, and canonical `true` or `false`. It reproduces the stage-0 SHA-256 only after complete validation and exact input consumption. The bounded fixture ceiling is 256 bytes. `BootstrapSyntax.w` owns the shared fail-closed fragment comparison used here and by native artifact-set validation. Duplicate tiny parsers become large disagreements remarkably quickly.

Each ordinary and diverse toolchain argument uses exact canonical `wheeler.toolchain.yaml`:

```yaml
schema: 1
toolchain:
  kind: "independent-stage0"
  source: "<sha256>"
  builder: "<sha256>"
  dependencies: "<sha256>"
  environment: "<sha256>"
```

`kind` is `recovery-seed`, `independent-stage0`, or `host-source`. The other fields bind the reviewed toolchain source, its builder, its closed dependency set, and its normalized build environment. `NativeToolchainIdentity.w` accepts only that exact field order, canonical quoted spelling, four lowercase SHA-256 values, and a final LF within its 512-byte budget. The stage-0 parser applies the same canonical-byte check. A map with the right facts in a different order is not the file named by the digest.

The kind is only an audit category. Promotion still requires distinct full provenance and compiler identities, plus a review that confirms the two derivations are truly independent.

## Canonical evidence schema

Schema 2 has one strict canonical `wheeler.bootstrap.yaml` form:

```yaml
schema: 2
source:
  archive: "<sha256>"
  manifest: "<sha256>"
  lock: "<sha256>"
  profile: "bootstrap-1"
  features: "<sha256>"
  modules: "<sha256>"
  options: "<sha256>"
  limits: "<sha256>"
ordinary:
  toolchain: "<sha256>"
  compiler: "<sha256>"
  runtime: "<sha256>"
  verifier: "<sha256>"
  stage-1: "<sha256>"
  stage-2: "<sha256>"
  diagnostics: "<sha256>"
diverse:
  toolchain: "<sha256>"
  compiler: "<sha256>"
  runtime: "<sha256>"
  verifier: "<sha256>"
  output: "<sha256>"
  diagnostics: "<sha256>"
acceptance:
  artifact-set: "<sha256>"
```

All identities are lowercase SHA-256 values. `source.archive` identifies the canonical package archive, `source.manifest` identifies the package manifest, and `source.lock` identifies the canonical lock. `source.features` fixes the accepted semantic vocabulary. `source.modules` fixes the rooted source graph and each source byte string.

Features, modules, options, and limits remain separate inputs. A changed resource limit must not look like the same compilation. Toolchain, compiler, runtime, and verifier identities describe both complete derivations instead of the host that ran them.

The schema constructor enforces these rules:

```text
ordinary.stage-1 == ordinary.stage-2
ordinary.stage-1 == diverse.output
ordinary.diagnostics == diverse.diagnostics
ordinary.toolchain != diverse.toolchain
ordinary.compiler != diverse.compiler
```

`NativeBootstrapManifestIdentity.w` applies the exact schema-2 field order, validates all twenty-one identities and the bounded source profile, enforces these five relationships, consumes the final LF, and only then publishes SHA-256. Its 2,048-byte ceiling is enough for the sole canonical form. Stage 0 now makes the same canonical-byte comparison. A permissive YAML parse is not provenance, however politely indented.

These checks are required for promotion, but they do not prove that source and output match by themselves. The trust case also depends on review, reproducible host builds, the strict verifier, source comparison, fixed-point evidence, and independent derivation.

## Publication and retention

A recovery candidate includes the compiler artifact, its canonical source archive and lock, `wheeler.bootstrap.yaml`, every referenced provenance input, and the closed acceptance artifact set. Publication is content-addressed and all-or-nothing.

Cache paths, repository aliases, download URLs, CI run numbers, wall-clock times, and usernames are transport details. They do not affect the artifact or bootstrap identity.

The manifest is generated and must not be hand-edited. A failed comparison produces no new manifest.

Deleting extra cache copies must not change the evidence graph. Losing a referenced provenance object makes the candidate impossible to verify, so the candidate cannot be promoted.

See [WIP-0007](../proposals/WIP-0007-self-hosting-compiler-and-bootstrap.md) for the bootstrap process. The [package and build reference](packages.md) defines canonical package, lock, repository, and artifact-set identities.
