# WIP-0053: Auditable bootstrap seed chain

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler, build, package, security, and release maintainers |
| Created | 2026-08-13 |
| Updated | 2026-08-13 |
| Area | Bootstrap, provenance, recovery releases, build system |
| Depends on | WIP-0007, WIP-0008, WIP-0009, WIP-0023 |
| Supersedes | None |
| Superseded by | None |

## Summary

Define a walkable, reproducible chain from every required Wheeler bootstrap binary to source. Wheeler minimizes opaque binary roots, keeps a simple alternate stage-0 implementation in routine use, and requires the build driver to bootstrap without an opaque copy of itself.

Fixed-point compilation remains necessary. It is not source provenance.

## Problem

A content hash proves that two users received the same bytes. It does not explain who produced those bytes, which source they used, or how another user can reproduce them. A self-hosted compiler can reproduce a hidden change indefinitely. A self-hosted build driver can also require an unexplained binary copy of itself.

Wheeler already records fixed-point and diverse-compilation evidence. The remaining contract is the binary seed chain. Distributors and users need to walk each generation back to a small reviewed implementation whose source and ordinary toolchain are available.

## Requirements

Every required seed record contains:

1. artifact kind and target platform
2. output identity and canonical length
3. exact source revision and source identity
4. build command and working-directory contract
5. builder identity
6. closed dependency identities
7. normalized build environment identity
8. parent seed identity, if one was used
9. independent rebuild attestations required by policy
10. an explicit opaque-root marker when source reproduction is unknown

The record is canonical, content-addressed, and machine-readable. Release policy rejects missing fields rather than inferring provenance from filenames or CI logs.

## Seed classes

A seed is one of:

- `alternate-stage0`: the maintained implementation in another language
- `recovery-release`: a prior Wheeler compiler, runtime, verifier, and build driver set
- `system-toolchain`: a declared host compiler, assembler, or linker
- `opaque-root`: unavoidable binary bytes whose source derivation is not known

An opaque root records its download origin, transport identity, acquisition date, and reason. It cannot be relabeled as a reproducible seed. Policy tracks and reduces opaque-root count and byte size across releases.

## Build-driver bootstrap

The previous recovery release executes a bounded bootstrap plan to produce the first current `wheeler` build driver. The plan consumes only pinned local or vendored inputs. It has no live resolution, ambient network, clock, random source, or undeclared host path.

The first driver executes the complete current plan and rebuilds itself. The two current driver artifacts must match under the canonical output contract. This path may be slow and recovery-workspace-specific. It must not require the current driver before producing it.

## Compiler bootstrap

The alternate stage 0 remains simple and unoptimized. CI uses it routinely to build the compiler while it is the base of the auditable chain. Stage 1 rebuilds the same source as stage 2. Complete stage artifacts and diagnostics match.

A separate trusted derivation performs diverse double compilation without first executing candidate-produced code. Seed-chain reproduction, fixed-point equality, and diverse equality publish as separate evidence fields.

## Publication

A recovery release publishes:

- canonical seed records
- source archive and lock identities
- compiler options and limit identities
- ordinary fixed-point evidence
- diverse-compilation evidence
- acceptance artifact-set identity
- parent recovery-release identity
- opaque-root inventory

The release job reconstructs the chain before publishing. A signature grants release authority. It does not replace source reproduction or content identity.

## Failure behavior

Publication fails before replacing any release pointer when:

- a required seed lacks source or opaque-root classification
- a source, command, builder, dependency, environment, or parent identity is malformed
- the recorded output does not match the rebuilt bytes
- the parent chain is cyclic, missing, or exceeds policy depth
- an opaque root appears without explicit policy approval
- fixed-point, diverse, and seed-chain evidence are conflated
- the build driver requires itself before producing the first current driver

## Migration

1. Add canonical seed-record and chain schemas.
2. Record the present Java stage 0 and host JDK toolchains without overstating their provenance.
3. Make CI reproduce the stage-0 seed path routinely.
4. Add the bounded build-driver bootstrap plan.
5. Bind seed-chain identity into `wheeler.bootstrap.yaml` and release manifests.
6. Require independent rebuild attestations for recovery releases.
7. Reduce and report opaque-root bytes.
8. Remove Java and Gradle only after the native chain is complete and exercised.

## Progress

- [x] WIP-0007 separates fixed point, diverse compilation, and seed provenance.
- [x] WIP-0008 requires recovery generations to carry source derivations.
- [x] WIP-0009 requires a build-driver path that does not require itself.
- [x] WIP-0023 distinguishes reproducible package bytes from compiler source correspondence.
- [x] `BootstrapSeedRecord` and its strict parser define the canonical `wheeler.seed.yaml` schema. The identity binds artifact class, platform, output and length, source revision and identity, command, working directory, builder, dependencies, environment, parent, attestations, and explicit opaque acquisition data.
- [x] `BootstrapSeedChain` indexes records by their canonical SHA-256 identity, walks bounded ancestry, rejects missing parents and attestations, and rejects cycles. Attestations must reproduce the same source and output under a distinct builder. Promoted recovery-release records carrying attestations require at least two such witnesses. Opaque records cannot claim source correspondence, while reproducible records cannot carry opaque-root metadata.
- [x] Ordinary CI reproduces the alternate Java stage 0 from a clean module output using `:stage0:clean :stage0:build` before it admits command-adapter, workspace, or promotion evidence.
- [ ] The first current build driver is produced without a current driver binary.
- [x] `BootstrapRecoveryEvidence` binds the complete seed-chain identity and count, exact sorted opaque-root identities, opaque byte total, source archive, lock, compiler options and limits, fixed-point evidence, diverse-compilation evidence, acceptance artifact set, and parent recovery release. Its strict parser and chain validator reject changed inventories or evidence fields.
- [x] Recovery-release validation rejects a lone attestation. A promoted record must carry at least two attestations that reproduce the same source and output under builders distinct from the release builder and from each other. Unpromoted witness records carry no attestations.
- [ ] Two independent builders reproduce the first native recovery release and supply its accepted attestation records.

## Acceptance

- A clean worker can follow the documented chain and reproduce every nonopaque seed generation.
- The build fails when one command, source, builder, dependency, environment, or parent identity changes.
- An opaque binary remains visibly opaque in generated evidence.
- The current driver bootstraps without invoking an existing current driver.
- Fixed-point and diverse-compilation checks still operate independently.
- Current bootstrap reference documentation names the actual chain and remaining opaque roots.

## Rejected alternatives

### Treat hashes as provenance

Rejected. Hashes identify bytes. They do not connect bytes to source.

### Check in the latest compiler binary without ancestry

Rejected. That creates an opaque moving root and defeats review of the bootstrap chain.

### Delete the alternate stage 0 immediately after the first fixed point

Rejected. A fixed point can reproduce a compromised compiler. The alternate implementation remains useful until a smaller auditable derivation replaces it.

### Require the complete build system to build itself

Rejected. Build systems need an alternate bootstrap path just as self-hosted compilers do.

## References

- [Bootstrappable builds](https://www.bootstrappable.org/)
- [Bootstrappable best practices](https://www.bootstrappable.org/best-practices.html)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
