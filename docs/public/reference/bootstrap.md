---
title: Bootstrap and Trust
description: Fixed-point compilation, independent derivation, seed ancestry, and the evidence required for compiler promotion.
---

# Bootstrap and Trust

A compiler can reproduce its own mistake. Byte equality establishes a fixed point.
It does not establish a trustworthy ancestry.

Wheeler's promotion gate therefore requires two independent forms of evidence:

1. stage 0 builds stage 1, and stage 1 builds a byte-identical stage 2.
2. an independently derived trusted compiler produces the same bytes without first
   running candidate-produced code.

The repository does not yet contain `wheeler.bootstrap.yaml` because the Wheeler
compiler has not completed that self-hosting gate. Creating the manifest early
would give an absent event a convincing seal.

## Present stage-0 work

Ordinary acceptance begins by rebuilding the alternate Java seed from source:

```bash
./bootstrap/gradlew -p bootstrap :stage0:clean :stage0:build
```

This supplies routine reproduction of the current alternate implementation. It
is neither a Wheeler fixed point nor an independent derivation.

The current Wheeler-native path can parse, plan, and classify the complete
376-module compiler closure with 1,872 imports and a 176,197-byte module manifest.
Its native identity run completes in 73,615,774 transitions. The native compiler
package separately compiles 89 production modules through bounded physical source
graphs and executes 224 cases. Physical linker evidence produces an executable
classical subset, but the complete compiler has not reached a fixed point.

## Platform ABI and native image plans

The first native profile has a canonical platform descriptor. It fixes loader
format, architecture, minimum OS ABI, little-endian 64-bit pointers, page and
alignment rules, resource bounds, CPU features, baseline libraries, and an exact
host-service set. Required services cover process arguments and exit, standard
streams, capability-relative file access and atomic replacement, directory
manifests, and raw page reservation, release, and protection. Monotonic deadlines
and target submission are optional named services.

Host calls use fixed-width scalars, checked byte spans, owned handles, and stable
status codes. They do not pass host objects or exceptions through Wheeler frames.
Profile 1 has no environment, wall-clock, network, random-device, unrestricted
path, dynamic-loader, or process-creation service. A host cannot grant one by
quietly noticing that its operating system has it.

`PlatformAbi` emits canonical schema-1 bytes and their SHA-256 identity.
`NativeImagePlan` binds that identity beside the portable WBC, capsule, backend,
runtime, compiler, sysroot, provider closure, options, link arguments, target,
runtime mode, and sealing and stripping policy. The plan identifies build inputs.
Unsigned native bytes receive a separate PREV. `UnsignedNativeImageRecord`
binds complete adapter-verified format, target, plan, ABI, capsule, PREV, and byte
count. `NativeImageSigningRecord` separately binds ELF repository signatures,
Apple code signatures, or PE Authenticode distribution bytes and evidence.
Signing products cannot alter the plan or PREV. `image record-elf`,
`record-macho`, `record-pe`, and `record-signing` publish the strict records from
bounded physical inputs. These commands do not invoke a signer. The metadata
records do not perform cryptographic verification, notarization, or trust policy.

Platform ABI, image plan, output, and signing records have strict 16 KiB canonical
parsers. They reject malformed UTF-8, schema or field drift, unknown values,
reordered records, comments, trailing data, and numeric overflow rather than
repairing transport.

The format-neutral application capsule is also fixed. Its bounded binary header
carries exact lengths and counts. One root binds the package instance, selected
target, qualified entry function, WBC, runtime mode, required capabilities, and
runtime, bytecode, proof, target, platform, and limit profiles. Sorted package
receipts bind repository, package revision, build input, PREV, export, and package
instance evidence without performing runtime resolution.

A sorted entry table carries WBC, immutable resources, proof data, native provider
data, and provenance. Each uncompressed entry has one logical name, SHA-256
identity, checked absolute range, power-of-two alignment, and fixed flags. The
sole startup flag belongs to the root WBC. Padding is zero, the transport is
consumed exactly, and SHA-256 of the complete canonical bytes is the capsule
identity. Schema 1 admits at most 128 entries, 64 receipts, 32 capabilities, and
32 MiB in total.

`wheeler image inspect <application.capsule>` verifies this framing and renders
root, profile, receipt, and entry metadata without execution. `wheeler image
verify <application.capsule>` additionally verifies and canonically re-encodes
every WBC, then requires the startup WBC's entry function to match the root
exactly. Both commands consume one bounded physical file and perform no package
resolution, adjacent lookup, extraction, provider loading, or capability grant.

Format-neutral embedded startup accepts the retained capsule bytes and an explicit
launch context. Capsule, runtime, bytecode, proof, target, platform, and limit
identities must match. The sorted capability grant must equal the root request and
the verified entry's no-input, UTF-8, binary, output, or duplex signature. Startup
rejects AOT, nonclassical roots, and external proof or native-provider payloads,
then executes one fresh root exactly once. It never accepts a path.

The first native adapters emit position-independent ELF64 for x86-64 or AArch64
Linux, static Mach-O for arm64 Darwin, and PE32+ for x86-64 or arm64 Windows.
One R-X segment or section contains a fixed image-relative locator and exact
runtime text. A separate page-aligned R-- segment or section contains the capsule.
ELF keeps the stack nonexecutable and omits section headers. Mach-O fixes page-zero,
arm64 entry state, and platform-version commands. PE fixes DOS, COFF, optional,
data-directory, section, alignment, and padding fields. No format maps writable
executable bytes. Verification checks every loader field and identity, rebuilds
exact bytes, and publishes the unsigned PREV only after success. Runtime text is
an input bound by the image plan. Signing and notarization remain separate output
identities.

`wheeler image build-elf`, `wheeler image build-macho`, and `wheeler image
build-pe` consume exact physical capsule, runtime, plan, and ABI files. They verify
all WBC before construction, self-verify the selected image before atomic
publication, and print the unsigned PREV. Their matching `inspect-elf`,
`inspect-macho`, and `inspect-pe` commands report canonically verified structure,
identities, and ranges. The verify commands additionally check every WBC and the
exact root without execution.

`wheeler image runtime-elf-x86-64 -o <runtime.bin>` atomically publishes the
first maintained x86-64 Linux entry shim. Its 113 import-free bytes locate
mapped ELF capsule framing without reopening the image, check the locator and
capsule magic, complete one fixed standard-output write, and exit through the
kernel. This proves loader entry and two host-service leaves. It does not verify
WBC or execute the capsule root. No complete native runtime or recovery image
ships yet.

`wheeler image runtime-elf-x86-64-aot <root.wbc> -o <runtime.bin>` adds the
first native backend leaf. It accepts one canonical classical WBC containing one
zero-initialized `status` global and bounded acyclic constants, moves, checked
signed arithmetic, bitwise operations, comparisons, forward branches, status
stores, and halt. Computed
values 0 through 124 become distinct x86-64 Linux process statuses. Unsupported
programs reject without projection or fallback. The status-73 fixture launches as
a complete AOT ELF, but general bytecode execution and in-process verification
remain.

## Deriving the profile and graph

Publish the accepted feature contract:

```text
wheeler bootstrap-features \
  --profile bootstrap-1 \
  --output wheeler.bootstrap-features.yaml
```

Unknown profiles fail without output. Schema 1 contains exactly seventeen sorted
version-1 features:

```text
affine-borrows
boolean-scalars
bounded-loops
byte-output
byteview-input
checked-arithmetic
compile-time-constants
exhaustive-variants
fixed-scalar-array-fields
generated-inverse-proofs
module-linking
nominal-records
owned-regions
signed-scalars
static-calls
strict-utf8-input
word-buffers
```

Derive the compiler module graph from the canonical source archive:

```text
wheeler bootstrap-modules \
  --source-archive wheeler.compiler.wpk \
  --output wheeler.bootstrap-modules.yaml
```

The module manifest names schema, profile, root, external modules, and every local
module's canonical name, source path, source identity, and sorted imports. The
checker requires unique paths, closed local imports, declared externals, rooted
reachability, and an acyclic graph.

Schema ceilings are 10,000 local modules, 10,000 external modules, and 100,000
direct imports. The current native identity path accepts 512 local modules, 64
externals, 3,072 imports, and 262,144 input bytes, which covers the present
compiler graph.

## Options and limits

The accepted options record is:

```yaml
schema: 1
compiler:
  profile: "bootstrap-1"
  source-maps: false
```

Source maps may be enabled only when normalized logical source identities enter
canonical output.

The limits record is:

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

Every value is a positive canonical integer no greater than 1,073,741,824. Both
derivations must use the named limits. Hashing one file while executing another
policy would make the provenance false.

## Toolchain provenance

Each ordinary and diverse toolchain uses canonical
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

`kind` is `recovery-seed`, `independent-stage0`, or `host-source`. The remaining
fields bind reviewed source, builder, closed dependencies, and normalized
environment.

The category alone proves no independence. Promotion requires distinct complete
provenance and compiler identities, followed by review of the derivations.

## Seed ancestry

`wheeler.seed.yaml` binds one seed artifact to kind, target platform, output
identity and length, source revision and identity, build command, working
directory, builder, closed dependencies, environment, parent, and independent
attestations.

Accepted kinds are `alternate-stage0`, `recovery-release`, `system-toolchain`, and
`opaque-root`. An opaque root has no source or parent and must state origin,
transport, acquisition date, and reason. Other kinds require source
correspondence.

The seed-chain index uses SHA-256 identity of canonical record bytes. Every parent
and attestation must be present. Parent walks must be acyclic. An attestation names
the same source and output under a builder identity unused by the subject or
another attestation.

This forms a closed evidence graph. It cannot transform an opaque root into
source-derived bytes.

`wheeler.recovery.yaml` binds the graph, opaque-root totals, source archive, lock,
options, limits, fixed-point result, diverse-compilation result, acceptance set,
and parent recovery release. Validation rederives chain and opaque totals.

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

Every file argument names a physical nonsymlink file no larger than 16 MiB. Only
the two diagnostic files may be empty. The acceptance directory contains a closed
canonical artifact set and must include the compiler fixed point.

The command checks each input before and after reading, strictly decodes the
compiler archive and lock, validates profile and graph closure, hashes every
module source, independently decodes and re-encodes compiler artifacts, compares
complete bytes and diagnostics, verifies distinct derivations, and rederives the
acceptance-set identity. It never executes a candidate artifact.

## Canonical bootstrap manifest

Schema 2 binds twenty-one lowercase SHA-256 identities:

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

Construction enforces:

```text
ordinary.stage-1 == ordinary.stage-2
ordinary.stage-1 == diverse.output
ordinary.diagnostics == diverse.diagnostics
ordinary.toolchain != diverse.toolchain
ordinary.compiler != diverse.compiler
```

These relationships remain evidence components. Review, reproducible host builds,
strict verification, source comparison, and independent derivation complete the
trust case.

## Publication

A recovery candidate contains the compiler artifact, canonical source archive and
lock, bootstrap manifest, every provenance input, and the closed acceptance set.
Publication is content-addressed and all-or-nothing.

Cache paths, aliases, URLs, CI numbers, wall time, and usernames are transport
details outside artifact identity. The bootstrap manifest is generated and never
hand-edited. Losing a referenced provenance object makes the candidate
unverifiable and ineligible for promotion.

The [package appendix](packages.md) defines the archive, lock, repository, and
artifact-set identities used here.
