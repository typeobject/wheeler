# WIP-0026: Self-contained platform-native Wheeler executables

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler, runtime, bytecode, native, package, security, platform, and release maintainers |
| Created | 2026-07-19 |
| Updated | 2026-07-19 |
| Area | Native executable images, embedded WBC, startup, ELF, Mach-O, PE/COFF, reproducibility |
| Depends on | WIP-0001, WIP-0007, WIP-0008, WIP-0009, WIP-0022, WIP-0023 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler will produce one loader-recognized platform-native executable for an application target: ELF on ELF systems, Mach-O on macOS, and PE/COFF when implemented. It is not a script, self-extractor, or Wheeler file with a launcher glued to the front. Read-only format-native segments contain a canonical Wheeler application capsule.

The capsule carries exact WBC artifacts, root entry, package/lock receipts, runtime profile and limits, immutable resources, selected proof material, provider descriptors, bundled native data, provenance, and identities. The first image embeds a Wheeler VM/runtime, verifies capsule and every WBC, and runs one fixed entry. It needs no adjacent `.wbc`, Wheeler install, vendor tree, package cache, or network.

A later AOT mode still embeds the canonical WBC closure. AOT is an execution mode over the same reversible typed IR identity—classical inverse/log/barrier relations, workflows, ownership/effects, and quantum regions/adjoints—not an opportunity to misplace the semantics in a native optimizer.

Self-contained excludes the kernel and declared platform baseline. A sealed image bundles or statically links every nonbaseline dependency; a system-baseline image depends only on explicit WIP-0025 capabilities mapped by WIP-0024. Unsigned native bytes are reproducible WIP-0023 output with a PREV. Signing/notarization happens afterward under separate identity.

## Motivation

A launch directory containing launcher, VM, WBCs, lock, resources, and libraries permits partial updates, component substitution, path/cache influence, complicated signing, and brittle distribution. One native file gives direct launch, one atomic update, one signing subject, one content identity, offline execution, exact provenance, and simple system-package export.

The design rejects opaque appended trailers: loader tools, stripping, universal binaries, signing, antivirus, and reproducibility disagree about bytes outside native structure. Wheeler bytes belong in ordinary read-only segments before signing.

## Goals

- Produce valid loader-native files with one canonical format-neutral capsule.
- Embed exact WBC closure, fixed root entry, runtime/AOT support, resources, receipts, proofs, and provider metadata.
- Verify capsule and WBC before execution and expose no adjacent search path.
- Define sealed and system-baseline profiles.
- Reproduce complete unsigned bytes and separate signing identity.
- Keep capsule pages read-only and nonexecutable.
- Avoid reliance on debug/section-header metadata removed by normal stripping.
- Preserve WBC as semantic authority under AOT.
- Integrate exact WIP-0025 providers and WIP-0024 exports.
- Provide bounded inspect, verify, and audit extraction without execution.

## Non-goals

- Define FFI or OS package formats.
- Include kernels or promise one binary for every OS/CPU.
- Load adjacent WBC/resources/plugins or discover caches/environment modules.
- Append opaque archives, extract executable content for ordinary use, or load embedded dynamic libraries through temp files initially.
- Require AOT, JIT, writable-executable memory, or mutable embedded state.
- Store credentials or let native images bypass ordinary WBC verification.

## Semantic model

A platform-native executable begins with the target's native header. Its immutable capsule is conceptually:

```text
application_capsule {
    schema
    capsule_id
    root_package_instance
    root_target
    root_wbc
    entry_descriptor
    runtime_profile
    bytecode_profile
    proof_profile
    target_profile
    platform_baseline
    execution_limits
    required_capabilities[]
    package_receipts[]
    wbc_entries[]
    resource_entries[]
    proof_entries[]
    native_provider_entries[]
    provenance
}
```

A capsule entry records kind, logical name, content identity, offset, length, alignment, and flags. Entries are sorted by kind/name/identity and initially remain uncompressed. The capsule uses fixed magic/version/length/count, overflow-checked tables, per-entry SHA-256, whole digest, canonical padding, exact consumption, and no trailing bytes.

```text
capsule_id = hash(canonical capsule bytes)
```

The containing native file has a separate PREV because runtime code, headers, segments, relocations, and platform metadata add bytes.

The root descriptor fixes exact WBC, target, function, host I/O shape, capabilities, limits, and runtime mode. Command-line spelling cannot select another embedded artifact unless the package explicitly defines a multi-tool dispatch table.

Initial runtime mode is embedded VM. Later AOT includes native code plus exact WBC for provenance, verification, differential semantics, and debugging. Hybrid mode is future work.

A platform baseline records format/architecture, minimum OS ABI, CPU features, loader contract, permitted system libraries/frameworks, security requirements, and relevant page/alignment assumptions. It is variant/build-input identity.

A sealed image contains or statically links all nonbaseline code. A system-baseline image may depend only on manifest-declared capabilities whose native import closure is verified.

A package receipt records repository/snapshot, coordinate, RREV, variant, build-input ID, PREV, selected export, and instance ID. It is evidence, not a runtime resolver.

```text
native_image_plan {
    platform_format
    target_abi and cpu_baseline
    runtime_mode
    capsule_id
    runtime and provider artifacts
    compiler/assembler/linker/sysroot
    canonical link arguments/layout
    strip/debug/signing policy
    limits
}
```

The complete unsigned native file PREV is the output identity. Signing yields `signed_artifact_id -> unsigned PREV -> capsule_id`.

## Ownership and boundaries

Compiler/package linking owns exact WBC closure and entry. The bytecode verifier owns every embedded executable artifact. Capsule builder owns canonical bytes/ID. Native runtime owns startup and execution. Format adapters own platform layout. WIP-0023 owns exact tools, reproducibility, PREV, and publication. WIP-0025 owns providers/link groups. WIP-0024 owns installation and signing policy. The OS loader owns loading; host policy grants runtime authority.

## Design

A package derives an image from one runnable target without adding a new target kind. Image profile selects platform, embedded-VM mode, baseline, and sealed/system policy; exact tools and artifacts come from the lock/plan.

The WBC closure contains root and every exact runtime-loadable or inspectable WBC, with no unreachable package artifacts unless explicitly retained. Source-linked applications may contain one final WBC. Version resolution never occurs at startup.

Immutable resources use logical names and a read-only capability. Mutable configuration/state remains external explicit host data.

### Startup

Native entry performs minimal platform initialization, locates the loader-mapped capsule, validates segment bounds/permissions and canonical framing/digests, validates baseline/profile/receipts, verifies every WBC, constructs bounded runtime state, binds explicit capabilities, invokes the fixed root, and returns a deterministic declared exit status. Failure before entry emits a stable image diagnostic and executes no application bytecode.

The locator cannot depend on executable path, `/proc/self/exe`, current directory, environment, package caches, debug symbols, or section headers that stripping may remove. The adapter emits a small linker-visible locator in loadable read-only data and runtime cross-checks it against segment bounds.

### ELF

ELF uses ordinary code/data plus a dedicated read-only, nonexecutable `PT_LOAD` for capsule bytes and optionally a small note/locator. Logical sections may be `.note.wheeler`, `.wheeler.manifest`, `.wheeler.bundle`, and `.wheeler.resources`, but runtime depends on program headers/locator, not section headers. Stripping preserves startup. Alignment, file/VM ranges, permissions, and full import closure are verified.

### Mach-O

Mach-O uses a read-only nonexecutable `__WHEELER` segment containing manifest, bundle, and resources. It is mapped by normal load commands, located through generated symbols/locator, and embedded before code signing. Universal binaries initially duplicate the exact capsule in each architecture slice; all slices report one capsule ID while runtime/native code may differ.

### PE/COFF

PE uses read-only initialized-data sections and a generated locator. Section count/alignment, timestamp/debug normalization, and certificate/debug ranges are checked. Capsule embedding precedes Authenticode. Exact names are selected during adapter implementation because PE section names are not a place for literature.

Opaque appended trailers and nonloadable-only capsule sections are rejected. The runtime does not reopen its file.

The first runtime is statically linked or depends only on the declared baseline. It performs no plugin search. AOT is admitted only after reproducible native output and bytecode/native equivalence cover traps, effects, proof, inverse, adjoint, measurement, replay, CPU baseline, and debug behavior. WBC remains embedded.

WIP-0025 static providers are preferred for sealed images. Platform-baseline providers are explicit. Embedded dynamic providers are deferred because temp extraction creates filesystem, race, cleanup, signing, and antivirus semantics.

The final native import closure must equal baseline plus declared providers. Inspection may verify declarations; it cannot invent them.

Host arguments, streams, files, environment allowlist, and exit status are bound only through the entry capability contract. The image itself grants no ambient authority.

Proof and quantum metadata may be embedded, but credentials, calibration, queues, and live results remain external.

Debug companions are separate content-addressed artifacts tied to capsule ID/PREV and exact addresses/maps. Production stripping cannot remove required capsule or stable-trap metadata.

`image inspect` and `image verify` parse native structure, permissions, locator, capsule canonicality/digests, WBCs, receipts, imports, baseline, and optional signatures without execution. Audit extraction validates first, uses safe logical paths, writes a new explicit directory atomically, and is never normal execution.

Updates reconstruct and verify one complete new file before atomic replacement. Embedded bytes are never patched in place.

### Reproducibility and signing

The image plan pins capsule, runtime/objects, compiler/assembler/linker, sysroot, ABI/CPU, input order, arguments, layout, strip/debug policy, source epoch, and import closure. Adapters normalize paths, users/hosts, timestamps, notes, build IDs/UUIDs, load-command/section/symbol order, PE debug fields, padding, alignment, and linker randomization. IDs expected by platform ecosystems are domain-separated content derivations excluding the field itself.

Capsule and unsigned image construction finish before signing. ELF repository/distro signatures, Mach-O code signatures/notarization, PE Authenticode, app bundles, DMGs, installers, and system packages are linked release artifacts and do not change capsule ID.

## Embedded I/O boundary

The root receives one explicit WIP-0032 `Io` implementation plus exact granted resource capabilities. The image, capsule, runtime mode, or linked provider grants no ambient file, network, clock, credential, device, or target access.

WIP-0032 owns request and completion methods. This WIP records the required host-I/O shape and binds backends/providers into the image plan; it does not fork the API. Image replacement and update publication likewise claim no durability beyond an exact accepted receipt.

## Reversibility, concurrency, quantum, and proofs

Capsule/layout/hashing/verification are deterministic. Linking, writing, signing, notarization, and replacement are external effects. Embedded execution obeys ordinary Wheeler semantics; packaging does not make host effects reversible.

Image inputs are canonically ordered and linker concurrency is allowed only when bytes remain invariant. Runtime capsule pages are immutable/shareable.

Quantum and proof semantics remain in exact WBC. AOT must preserve proof/inverse/adjoint/measurement/replay/effect boundaries. Target credentials and mutable hardware state remain host capabilities.

## Compatibility and safety

Capsule schema and supported WBC profiles are versioned. Unsupported schema/profile/baseline fails before entry. Adapter changes may alter native PREV while preserving capsule ID across architectures.

Limits cover native/capsule size, entry counts/names/sizes, alignment, receipts, proofs/providers, verification work, runtime memory/steps, native imports, and diagnostics.

Reject malformed native structure, overlapping/escaping ranges, writable/executable capsule, bad/missing locator, unordered/duplicate entries, digest mismatch, trailing data, unsupported baseline, malformed WBC, undeclared imports, unequal universal capsule IDs, host variance, unsupported signing state, and output excess. Corruption never falls back to adjacent files or network.

## Migration and deletion

1. Define capsule schema and independent inspect/verify.
2. Build minimal native startup runtime.
3. Implement reproducible ELF segment/locator and import checks.
4. Implement Mach-O segment, signing separation, and universal identity.
5. Integrate static WIP-0025 providers and WIP-0024 install images.
6. Implement PE/COFF and separate debug companions.
7. Add AOT only after semantic equivalence.
8. Delete launcher-plus-adjacent-WBC release paths and all adjacent/cache/environment searches.

## Progress

- [ ] Capsule, entry, and receipt schemas accepted.
- [ ] Capsule inspect/verify and embedded-VM startup implemented.
- [ ] ELF and Mach-O images reproduce with signing separation.
- [ ] Sealed providers and system export integrate.
- [ ] PE/COFF implemented and AOT conformance defined.
- [ ] Adjacent-WBC release path deleted.

## Testing and acceptance

- [ ] Capsule ordering/digests/limits are canonical and malformed inputs fail.
- [ ] Startup locates mapped data without path/environment/cache/network and verifies every WBC.
- [ ] Root/capabilities/exit status are deterministic.
- [ ] ELF/Mach-O/PE structures, permissions, alignment, stripping, imports, signing order, and reproducibility pass.
- [ ] Universal slices share capsule ID.
- [ ] Build path, identity, locale, timezone, jobs, temp paths, IDs, and padding do not affect unsigned bytes.
- [ ] No WBC/resource mapping is writable or executable in embedded-VM mode.
- [ ] One sealed file runs without external Wheeler files and WIP-0024 installs only that image when selected.
- [ ] Stage 0 and Wheeler image tools agree.

## Alternatives

Adjacent launch directories permit substitution and partial updates. Opaque trailers have inconsistent loader/signing behavior. App bundles are useful wrappers but not the one-file profile. Requiring AOT increases compiler risk; omitting WBC loses semantic provenance. Reopening by path and storing only debug sections are brittle. Temp extraction of shared libraries is deferred. Signed bytes alone are not reproducible content identity. Runtime package resolution and in-place WBC updates violate the closed immutable graph. All are rejected.

## Open questions

- Which canonical capsule encoding and deterministic compression profile? — **Owner:** format maintainers — **Decide by:** schema freeze
- Exact ELF locator/note and first Linux baseline? — **Owner:** ELF/runtime maintainers — **Decide by:** ELF adapter
- First macOS versions/slices and universal duplication policy? — **Owner:** platform maintainers — **Decide by:** Mach-O adapter
- Which host-input capabilities are required for the first CLI? — **Owner:** standard-library maintainers — **Decide by:** startup
- Which conformance gate admits AOT, and is PE in first acceptance or successor? — **Owner:** compiler/platform maintainers — **Decide by:** acceptance

## References

- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
- [WIP-0024](WIP-0024-system-package-exports.md)
- [WIP-0025](WIP-0025-native-ffi-and-system-integration.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [ELF program loading](https://gabi.xinuos.com/elf/07-loading-intro.html)
- [Mach-O overview](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/CodeFootprint/Articles/MachOOverview.html)
- [Microsoft PE format](https://learn.microsoft.com/en-us/windows/win32/debug/pe-format)
