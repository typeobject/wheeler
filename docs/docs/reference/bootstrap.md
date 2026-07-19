# Bootstrap evidence

A compiler can reproduce its own bugs. That alone doesn't make it trustworthy. WIP-0007 requires two separate checks:

1. stage 0 builds stage 1, and stage 1 builds a byte-identical stage 2;
2. an independently derived trusted compiler produces the same bytes without first running code from the candidate compiler.

The bootstrap gate records successful evidence in `wheeler.bootstrap.yaml`. The repository does not contain that manifest yet because the bounded Wheeler compiler is not self-hosting. Creating the file early would not provide real evidence.

## Evidence command

The stage-0 command is:

```text
wheeler bootstrap-manifest \
  --source-archive wheeler.compiler.wpk \
  --source-lock wheeler.package.lock.yaml \
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

Before it publishes anything, the command:

- strictly decodes the canonical `wheeler.compiler` package archive;
- parses the schema-3 snapshot-bound lock and requires its exact canonical YAML bytes;
- binds that lock to the source manifest;
- parses exact schema-1 compiler options and limits;
- requires the option profile to match the source package;
- independently decodes and re-encodes stage 1, stage 2, and the diverse output;
- compares all three complete `.wbc` byte strings;
- compares the ordinary and diverse diagnostic bytes;
- requires different ordinary and diverse toolchain identities;
- requires different ordinary and diverse compiler identities;
- recomputes the closed acceptance artifact-set identity;
- requires that set to contain the compiler fixed point;
- parses its own output before replacing the destination atomically.

The command never runs a candidate artifact. A static manifest also cannot prove that an earlier build script followed the right order. The promotion job must show that the diverse comparison happened before candidate execution, bind both toolchain provenance files, and run acceptance only after the comparison gate.

Two copies of the same opaque compiler do not count as independent derivations, even when their filenames differ.

## Compiler input schemas

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

Each limit is a positive canonical integer no larger than 1,073,741,824. The schema requires all ten limits and rejects unknown keys; a launcher must apply the same values to both derivations. Hashing one limits file while using different limits would make the provenance false.

Source maps may be enabled only when their normalized logical source identities are part of the canonical output.

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

`kind` is `recovery-seed`, `independent-stage0`, or `host-source`. The other fields bind the reviewed toolchain source, its builder, its closed dependency set, and its normalized build environment.

The kind is only an audit category. Promotion still requires distinct full provenance and compiler identities, plus a review that confirms the two derivations are truly independent.

## Canonical evidence schema

Schema 1 has one strict canonical `wheeler.bootstrap.yaml` form:

```yaml
schema: 1
source:
  archive: "<sha256>"
  manifest: "<sha256>"
  lock: "<sha256>"
  profile: "bootstrap-1"
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

All identities are lowercase SHA-256 values. `source.archive` identifies the canonical package archive, `source.manifest` identifies the package manifest, and `source.lock` identifies the canonical lock.

Options and limits remain separate inputs. A changed resource limit must not look like the same compilation. Toolchain, compiler, runtime, and verifier identities describe both complete derivations instead of the host that ran them.

The schema constructor enforces these rules:

```text
ordinary.stage-1 == ordinary.stage-2
ordinary.stage-1 == diverse.output
ordinary.diagnostics == diverse.diagnostics
ordinary.toolchain != diverse.toolchain
ordinary.compiler != diverse.compiler
```

These checks are required for promotion, but they do not prove that source and output match by themselves. The trust case also depends on review, reproducible host builds, the strict verifier, source comparison, fixed-point evidence, and independent derivation.

## Publication and retention

A recovery candidate includes the compiler artifact, its canonical source archive and lock, `wheeler.bootstrap.yaml`, every referenced provenance input, and the closed acceptance artifact set. Publication is content-addressed and all-or-nothing.

Cache paths, repository aliases, download URLs, CI run numbers, wall-clock times, and usernames are transport details. They do not affect the artifact or bootstrap identity.

The manifest is generated and must not be hand-edited. A failed comparison produces no new manifest.

Deleting extra cache copies must not change the evidence graph. Losing a referenced provenance object makes the candidate impossible to verify, so the candidate cannot be promoted.

See [WIP-0007](../proposals/WIP-0007-self-hosting-compiler-and-bootstrap.md) for the bootstrap process. The [package and build reference](packages.md) defines canonical package, lock, repository, and artifact-set identities.
