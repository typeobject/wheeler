# Bootstrap evidence

Wheeler promotes no recovery compiler merely because it can reproduce its own
bad habits. WIP-0007 requires two separate checks:

1. stage 0 produces stage 1, and stage 1 produces byte-identical stage 2;
2. an independently derived trusted compiler produces the same bytes without
   first executing candidate-produced code.

The checked bootstrap gate records successful evidence in
`wheeler.bootstrap.yaml`. The repository does not contain such a manifest yet:
the bounded Wheeler compiler is not self-hosting, and a manifest fabricated in
advance would be a YAML-shaped pep talk.

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

Every file argument must name a physical, nonsymbolic file of at most 16 MiB.
Only either diagnostics file may be empty. The acceptance argument must name a closed artifact tree whose canonical
`wheeler.artifact-set.json` still matches every contained `.wbc`. Inputs are
read with before-and-after file checks; changing a file while it is hashed is an
error, not an exciting new build mode.

Before publishing anything, the command:

- strictly decodes the canonical `wheeler.compiler` package archive;
- parses the schema-3 snapshot-bound lock, requires its exact canonical YAML bytes, and binds it to the source manifest;
- parses exact schema-1 compiler options and limits, and requires the option profile to match the source package;
- independently decodes and re-encodes stage 1, stage 2, and the diverse output;
- compares all three complete `.wbc` byte strings;
- compares ordinary and diverse diagnostic bytes;
- requires distinct ordinary and diverse toolchain identities;
- requires distinct ordinary and diverse compiler identities;
- recomputes the closed acceptance artifact-set identity and requires that set to contain the compiler fixed point; and
- parses its own output before atomically replacing the destination.

The command never executes a candidate artifact. Pipeline ordering still has to
show that diverse comparison preceded candidate execution; a static file cannot
prove what an earlier shell script did. The eventual promotion job therefore
binds the independently produced toolchain provenance files and runs acceptance
only after this comparison gate. Two copies of one opaque compiler with
slightly different filenames remain one opaque compiler.

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

Every limit is a positive canonical integer no larger than 1,073,741,824. The
schema requires all ten ceilings and rejects unknown keys. A launcher must apply
these exact values to both derivations; hashing an attractive limits file while
using other limits is provenance fraud, not an implementation technique. Source
maps may be enabled only when their normalized logical source identities are
part of canonical output.

Each ordinary and diverse toolchain argument is exact canonical
`wheeler.toolchain.yaml`:

```yaml
schema: 1
toolchain:
  kind: "independent-stage0"
  source: "<sha256>"
  builder: "<sha256>"
  dependencies: "<sha256>"
  environment: "<sha256>"
```

`kind` is one of `recovery-seed`, `independent-stage0`, or `host-source`.
`source` binds reviewed toolchain sources, `builder` binds the compiler that
built the toolchain, `dependencies` binds its closed dependency set, and
`environment` binds the normalized build environment. The kind is an audit
category, not diversity dust: promotion still requires distinct complete
provenance and compiler identities plus review that the derivations are
actually independent.

## Canonical evidence schema

The sole schema-1 `wheeler.bootstrap.yaml` representation is strict canonical YAML:

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

All identities are lowercase SHA-256. `source.archive` is the canonical package
archive identity; `source.manifest` is the package-manifest identity;
`source.lock` is the canonical lock identity. Options and limits are separate
inputs so that changing a resource ceiling cannot masquerade as the same
compilation. Toolchain, compiler, runtime, and verifier identities describe the
complete two derivations rather than the hostname on which they happened to
run.

The schema constructor itself enforces:

```text
ordinary.stage-1 == ordinary.stage-2
ordinary.stage-1 == diverse.output
ordinary.diagnostics == diverse.diagnostics
ordinary.toolchain != diverse.toolchain
ordinary.compiler != diverse.compiler
```

These are necessary promotion conditions, not a theorem of source
correspondence. Review, reproducible host builds, the strict verifier, source
comparison, fixed-point evidence, and diverse derivation remain separate legs
of the trust argument. Sawing off five legs because one hash looked sturdy is
not simplification.

## Publication and retention

A recovery candidate consists of the compiler artifact, its canonical source
archive and lock, `wheeler.bootstrap.yaml`, the referenced provenance inputs,
and the closed acceptance artifact set. Publication is content-addressed and
all-or-nothing. Cache location, repository alias, download URL, CI run number,
wall clock, and username are transport or commentary; none enters artifact or
bootstrap identity.

The manifest is generated, never hand-edited. A failed comparison emits no new
manifest. Deleting disposable cache copies must not change the evidence graph;
losing a referenced provenance object does make the candidate unverifiable and
therefore unpromotable. This is deliberate. Trust data that can disappear
without consequence was decoration.

See [WIP-0007](../proposals/WIP-0007-self-hosting-compiler-and-bootstrap.md)
for the bootstrap procedure and [package and build reference](packages.md) for
canonical package, lock, repository, and artifact-set identities.
