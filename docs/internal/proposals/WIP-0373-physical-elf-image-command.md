# WIP-0373: Physical native image commands

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler native, runtime, package, tooling, and security maintainers |
| Created | 2026-08-24 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, ELF, Mach-O, and PE commands, physical inputs, atomic publication |
| Depends on | WIP-0008, WIP-0026, WIP-0368, WIP-0370, WIP-0372, WIP-0374, WIP-0375 |
| Supersedes | In-memory-only native image adapter demonstrations |
| Superseded by | None |

## Summary

Add physical build and verification commands for canonical ELF, Mach-O, and PE capsule images.

```text
wheeler image runtime-elf-x86-64 -o <runtime.bin>
wheeler image build-elf <application.capsule> --runtime <runtime.bin> --entry <offset> --plan <plan.yaml> --abi <abi.yaml> -o <application>
wheeler image inspect-elf <application> --plan <plan.yaml> --abi <abi.yaml>
wheeler image verify-elf <application> --plan <plan.yaml> --abi <abi.yaml>
wheeler image build-macho <application.capsule> --runtime <runtime.bin> --entry <offset> --plan <plan.yaml> --abi <abi.yaml> -o <application>
wheeler image inspect-macho <application> --plan <plan.yaml> --abi <abi.yaml>
wheeler image verify-macho <application> --plan <plan.yaml> --abi <abi.yaml>
wheeler image build-pe <application.capsule> --runtime <runtime.bin> --entry <offset> --plan <plan.yaml> --abi <abi.yaml> -o <application.exe>
wheeler image inspect-pe <application.exe> --plan <plan.yaml> --abi <abi.yaml>
wheeler image verify-pe <application.exe> --plan <plan.yaml> --abi <abi.yaml>
```

WIP-0376's runtime command atomically publishes the maintained import-free x86-64 Linux entry text used by the first loader probe. It performs no discovery or native execution.

Each build command reads its explicit physical inputs once, parses canonical plan and ABI transports, verifies every capsule WBC and root, invokes the selected WIP-0372, WIP-0374, or WIP-0375 adapter, verifies those bytes through the independent reader, and only then publishes one output atomically. Each inspect command verifies complete native structure and capsule framing before returning deterministic JSON. Each verify command additionally checks every WBC and the exact root before printing success.

Neither command executes runtime text or the capsule.

## Physical input boundary

Capsule, runtime, plan, ABI, and native image arguments must name regular nonsymlink files. The command opens each file with no-follow semantics, records its size on the open channel, performs one bounded read, and rejects a short or growing file. It does not reopen an input during the operation.

Bounds remain owned by their formats:

| Input | Maximum bytes |
| --- | ---: |
| Application capsule | 33,554,432 |
| Runtime text | 16,777,216 |
| Native image plan | 16,384 |
| Platform ABI | 16,384 |
| ELF, Mach-O, or PE image | 67,108,864 |

The entry offset is one nonnegative decimal integer. The selected image adapter performs the final runtime-range check.

The command reads no current project, package cache, repository, adjacent lock, environment value, executable path, locale, clock, network source, random source, linker defaults, or configuration file.

## Build order

`build-elf`, `build-macho`, and `build-pe` perform these operations in order:

1. Read and frame the complete capsule.
2. Verify every WBC and exact qualified root through runtime authority.
3. Read the bounded runtime text.
4. Strictly parse the exact canonical native image plan and platform ABI.
5. Construct canonical bytes through the selected ELF, Mach-O, or PE adapter.
6. Independently verify native layout, commands, permissions, locator, identities, capsule, runtime, and PREV.
7. Set deterministic executable permissions on the temporary file and atomically publish the complete new output.
8. Print output path, byte count, and unsigned PREV.

No output path is touched before step 7. A malformed WBC cannot be hidden inside a structurally valid image. A runtime or capsule identity mismatch fails before publication. The shared atomic-output boundary rejects an existing link or nonregular path before staging. Replacement accepts only an existing physical file or an absent leaf. A failed publication removes its private temporary file.

The command does not invoke a linker. Runtime text is exact prebuilt input whose SHA-256 must equal the plan runtime identity.

## Inspection and verification order

`inspect-elf`, `inspect-macho`, and `inspect-pe` read the image, plan, and ABI through the same physical boundary. The selected adapter verifies and canonically rebuilds the complete image before inspection reports format, PREV, plan, capsule, image bytes, runtime bytes, runtime entry offset, and capsule offset. Inspection authenticates structure and capsule framing. It does not claim WBC validity.

`verify-elf`, `verify-macho`, and `verify-pe` perform the same structural work. Runtime authority then verifies every WBC extracted from the accepted capsule and binds its root. Only then does the command print one format-named result:

```text
verified <ELF|Mach-O|PE> <prev> (plan <plan-id>, capsule <capsule-id>, <count> WBC artifacts)
```

A damaged capsule, secondary WBC, runtime range, segment command, permission, entry state, locator, padding byte, plan, or ABI produces no success line.

## Failure boundary

Reject wrong command shape, nonphysical input, links, excess bytes, changing files, malformed entry offsets, malformed or noncanonical metadata, malformed capsule framing, invalid WBC, root disagreement, plan or ABI mismatch, invalid native layout, failed canonical reproduction, and atomic publication failure.

The output remains unsigned. Signing and notarization must consume the published unsigned PREV under separate release records.

## Evidence

`ImageCommandTest` compiles one Wheeler module and builds independently ABI-bound ELF, Mach-O, and PE capsules. It writes each capsule, runtime, plan, and ABI to separate physical files, invokes all three build commands, and compares published bytes against direct adapter construction. Every command PREV matches independent verification.

The test invokes all three inspect commands and requires their deterministic format and range records to match direct adapter evidence. It then invokes all three verify commands and requires complete plan, capsule, and one-WBC evidence. A separately damaged ELF rejects. An output link rejects without replacing the link or changing its target bytes. Existing command cases retain deterministic capsule inspection, malformed-WBC separation, wrong-root rejection, usage rejection, and nonphysical-input rejection.

Focused command evidence completes in one second.

## Acceptance

- [x] Maintained x86-64 Linux runtime publication is exact and atomic.
- [x] Build, inspection, and verification consume only explicit bounded physical inputs.
- [x] Canonical plan and ABI parsers run before image construction.
- [x] Every WBC and the exact root verify before output publication.
- [x] Each built ELF, Mach-O, or PE image passes its independent canonical verifier before publication.
- [x] Atomic output contains exactly the verified bytes and executable permissions.
- [x] Inspection reports selected native format, PREV, plan, capsule, and exact ranges after canonical reconstruction.
- [x] Verification composes the selected native format, capsule, WBC, and root authorities.
- [x] Verification output binds PREV, plan, capsule, and WBC count.
- [x] No command links, executes, signs, resolves, searches, or repairs.

## Rejected alternatives

### Build from a package directory

Rejected. That would mix package resolution, compilation, runtime selection, and image layout in one command. This boundary accepts exact already identified inputs.

### Skip WBC verification because the capsule hash matches

Rejected. Content identity authenticates bytes, not executable semantics. Runtime verification precedes build and follows native-format verification.

### Publish before self-verification

Rejected. The output path must never expose bytes that the selected canonical image reader rejects.

### Infer the ABI from the target triple

Rejected. WIP-0368 binds page geometry, baseline, services, and limits outside the triple.

### Run the output as a smoke test

Rejected. Arbitrary runtime text remains untrusted input. Native execution begins only after maintained runtime code and host-shim evidence exist.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0368](WIP-0368-platform-abi-and-native-image-identities.md)
- [WIP-0370](WIP-0370-application-capsule-inspection.md)
- [WIP-0372](WIP-0372-canonical-elf-capsule-images.md)
- [WIP-0374](WIP-0374-canonical-mach-o-capsule-images.md)
- [WIP-0375](WIP-0375-canonical-pe-capsule-images.md)
- [WIP-0376](WIP-0376-x86-64-linux-native-entry-shim.md)
