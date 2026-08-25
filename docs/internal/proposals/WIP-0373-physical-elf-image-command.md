# WIP-0373: Physical ELF image command

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler native, runtime, package, tooling, and security maintainers |
| Created | 2026-08-24 |
| Updated | 2026-08-24 |
| Area | Native bootstrap, ELF commands, physical inputs, atomic publication |
| Depends on | WIP-0008, WIP-0026, WIP-0368, WIP-0370, WIP-0372 |
| Supersedes | In-memory-only ELF adapter demonstrations |
| Superseded by | None |

## Summary

Add physical build and verification commands for canonical ELF capsule images.

```text
wheeler image build-elf <application.capsule> --runtime <runtime.bin> --entry <offset> --plan <plan.yaml> --abi <abi.yaml> -o <application>
wheeler image verify-elf <application> --plan <plan.yaml> --abi <abi.yaml>
```

The build command reads each explicit physical input once, parses canonical plan and ABI transports, verifies every capsule WBC and root, builds WIP-0372 ELF bytes, verifies those bytes through the independent reader, and only then publishes one output atomically. The verify command checks the complete ELF, plan, ABI, capsule, every WBC, and root before printing success.

Neither command executes runtime text or the capsule.

## Physical input boundary

Capsule, runtime, plan, ABI, and ELF arguments must name regular nonsymlink files. The command opens each file with no-follow semantics, records its size on the open channel, performs one bounded read, and rejects a short or growing file. It does not reopen an input during the operation.

Bounds remain owned by their formats:

| Input | Maximum bytes |
| --- | ---: |
| Application capsule | 33,554,432 |
| Runtime text | 16,777,216 |
| Native image plan | 16,384 |
| Platform ABI | 16,384 |
| ELF image | 67,108,864 |

The entry offset is one nonnegative decimal integer. `ElfImage` performs the final runtime-range check.

The command reads no current project, package cache, repository, adjacent lock, environment value, executable path, locale, clock, network source, random source, linker defaults, or configuration file.

## Build order

`build-elf` performs these operations in order:

1. Read and frame the complete capsule.
2. Verify every WBC and exact qualified root through runtime authority.
3. Read the bounded runtime text.
4. Strictly parse the exact canonical native image plan and platform ABI.
5. Construct canonical ELF bytes from those retained inputs.
6. Independently verify ELF layout, permissions, locator, identities, capsule, runtime, and PREV.
7. Set deterministic executable permissions on the temporary file and atomically publish the complete new output.
8. Print output path, byte count, and unsigned PREV.

No output path is touched before step 7. A malformed WBC cannot be hidden inside a structurally valid image. A runtime or capsule identity mismatch fails before publication. Existing atomic-output policy rejects links and partial replacement.

The command does not invoke a linker. Runtime text is exact prebuilt input whose SHA-256 must equal the plan runtime identity.

## Verification order

`verify-elf` reads the image, plan, and ABI through the same physical boundary. WIP-0372 then verifies and canonically rebuilds the complete ELF. Runtime authority verifies every WBC extracted from the accepted capsule and binds its root. Only then does the command print:

```text
verified ELF <prev> (plan <plan-id>, capsule <capsule-id>, <count> WBC artifacts)
```

A damaged capsule, secondary WBC, runtime range, segment permission, locator, padding byte, plan, or ABI produces no success line.

## Failure boundary

Reject wrong command shape, nonphysical input, links, excess bytes, changing files, malformed entry offsets, malformed or noncanonical metadata, malformed capsule framing, invalid WBC, root disagreement, plan or ABI mismatch, invalid ELF layout, failed canonical reproduction, and atomic publication failure.

The output remains unsigned. Signing and notarization must consume the published unsigned PREV under separate release records.

## Evidence

`ImageCommandTest` compiles one Wheeler module, builds a canonical capsule, writes capsule, runtime, plan, and ABI to separate physical files, invokes `build-elf`, and compares published bytes against direct `ElfImage` construction. The command's PREV matches independent verification.

The test then invokes `verify-elf` and requires complete plan, capsule, and one-WBC evidence. A separately damaged ELF rejects. Existing command cases retain deterministic capsule inspection, malformed-WBC separation, wrong-root rejection, usage rejection, and nonphysical-input rejection.

Focused command evidence completes in one second.

## Acceptance

- [x] Build and verification consume only explicit bounded physical inputs.
- [x] Canonical plan and ABI parsers run before image construction.
- [x] Every WBC and the exact root verify before output publication.
- [x] The built ELF passes the independent canonical verifier before publication.
- [x] Atomic output contains exactly the verified bytes and executable permissions.
- [x] Verification composes ELF, capsule, WBC, and root authorities.
- [x] Success output binds PREV, plan, capsule, and WBC count.
- [x] Neither command links, executes, signs, resolves, searches, or repairs.

## Rejected alternatives

### Build from a package directory

Rejected. That would mix package resolution, compilation, runtime selection, and image layout in one command. This boundary accepts exact already identified inputs.

### Skip WBC verification because the capsule hash matches

Rejected. Content identity authenticates bytes, not executable semantics. Runtime verification precedes build and follows ELF verification.

### Publish before self-verification

Rejected. The output path must never expose bytes that the canonical ELF reader rejects.

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
