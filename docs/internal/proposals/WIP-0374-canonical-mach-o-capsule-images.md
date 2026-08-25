# WIP-0374: Canonical Mach-O capsule images

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler native, runtime, package, platform, and security maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, arm64 Mach-O, capsule segments, entry state, unsigned PREV |
| Depends on | WIP-0008, WIP-0026, WIP-0368, WIP-0369, WIP-0371, WIP-0372 |
| Supersedes | Format-neutral Mach-O placeholders |
| Superseded by | None |

## Summary

Define the first canonical Wheeler Mach-O image for `aarch64-apple-darwin`.

The image contains exact position-independent runtime text and one complete application capsule. Runtime text occupies the executable `__TEXT` segment. The capsule occupies a separate page-aligned, read-only `__WHEELER` segment. A static `LC_UNIXTHREAD` state enters the runtime at the plan-bound offset. The image has no writable load segment, dynamic loader command, section table, symbol table, relocation table, source path, timestamp, UUID, signature, entitlement, or adjacent-file lookup.

This WIP defines image construction and independent verification. It does not supply Wheeler runtime machine code, an Apple host-service shim, signing, notarization, or launch evidence.

## Profile

Schema 1 accepts only:

- 64-bit little-endian arm64.
- `darwin` platform ABI and `mach-o` image format.
- target `aarch64-apple-darwin`.
- embedded-VM runtime mode.
- stripped and sealed plans.
- a 4,096-byte platform page.
- runtime text of one through 16,777,216 bytes.
- one application capsule under WIP-0369's 33,554,432-byte bound.
- a complete image no larger than 67,108,864 bytes or the platform memory bound.

Runtime offset is fixed at byte 656. Capsule offset is the first platform page boundary after runtime text. Image length ends exactly after capsule bytes.

## Header and commands

The image begins with one little-endian `mach_header_64`:

| Field | Value |
| --- | --- |
| Magic | `MH_MAGIC_64` |
| CPU | `CPU_TYPE_ARM64`, `CPU_SUBTYPE_ARM64_ALL` |
| File type | `MH_EXECUTE` |
| Commands | 5 |
| Command bytes | 528 |
| Flags | `MH_NOUNDEFS` |
| Reserved | 0 |

Commands occur in this exact order:

1. `LC_SEGMENT_64 __PAGEZERO` covers virtual addresses below `0x100000000` and no file bytes.
2. `LC_SEGMENT_64 __TEXT` maps file offset zero at `0x100000000` with read and execute permission.
3. `LC_SEGMENT_64 __WHEELER` maps exact capsule bytes read-only at the file-offset-equivalent virtual address.
4. `LC_UNIXTHREAD` carries `ARM_THREAD_STATE64` with every register and status field zero except the exact program counter.
5. `LC_BUILD_VERSION` names macOS 13 as the fixed minimum and SDK profile and contains no tool rows.

Segment commands contain no sections. `__TEXT` file bytes end after runtime text while its virtual extent rounds to one page. `__WHEELER` file bytes equal exact capsule length while its virtual extent rounds to one page. Segment maximum and initial permissions agree. The capsule is never executable or writable.

The program counter is:

```text
0x100000000 + 656 + runtime-entry-offset
```

The runtime entry offset must identify one retained runtime byte.

## Locator and identity

A fixed 96-byte Wheeler locator follows load commands at byte 560. It contains:

- magic `WHMLOC01`.
- native image plan identity.
- runtime offset and length.
- capsule offset and length.
- runtime entry offset.
- one zero reserved field.
- capsule identity.

All integers are unsigned little-endian 32-bit fields admitted through nonnegative host values. The complete unsigned image receives SHA-256 PREV. PREV is distinct from the native image plan identity and from later signing or notarization records.

The plan must bind the exact platform ABI, capsule, root portable WBC, runtime text, target, mode, sealing policy, and stripping policy before construction. The capsule root must repeat the exact platform ABI and runtime mode.

## Verification

`MachOImage.verify` consumes retained bytes, the exact parsed native image plan, and the exact parsed platform ABI. It performs these checks before returning evidence:

1. Enforce image and profile bounds.
2. Check every header field.
3. Parse and bind the complete locator.
4. Check runtime and capsule ranges with overflow-safe arithmetic.
5. Check every segment name, address, extent, permission, count, and flag.
6. Check every arm64 entry-state field and the exact program counter.
7. Check the fixed build-version command.
8. Parse the complete capsule and bind root WBC, runtime, capsule, target, and ABI identities.
9. Rebuild the whole image and require byte-for-byte equality.
10. Compute unsigned PREV and return owned runtime bytes plus the retained capsule.

Canonical rebuilding rejects nonzero command slack, locator damage, runtime-to-capsule padding, reordered commands, alternate build versions, extra commands, and trailing bytes without a second normalization path.

## Failure boundary

Reject malformed or excess bytes, another CPU or operating system, another image format, unstripped or AOT plans, profile or identity disagreement, empty runtime text, an out-of-range entry, wrong root WBC, writable or executable capsule bytes, writable text, nonzero entry registers, changed padding, malformed capsule framing, and failed canonical reproduction.

A failed construction or verification publishes no output artifact or PREV.

## Evidence

`MachOImageTest` constructs the same 4,652-byte image twice from independently owned runtime arrays. The fixture places its 556-byte capsule at byte 4,096 and records unsigned PREV `d337a798bb86fce36afc69828a95affc454a884db7f156cdd33050858b50400d`.

The test inspects CPU, command count, command bytes, text and capsule permissions, and program counter independently. It checks returned-byte ownership. Separate mutations damage the header, text permission, capsule permission, entry state, locator, runtime, intersegment padding, and capsule. Plan runtime, stripping, root artifact, ABI, entry, and empty-runtime disagreement reject before output.

Apple `file` identifies the fixture as a 64-bit arm64 Mach-O executable. Apple `otool -hv` accepts its five commands and 528-byte command area. `otool -l` reports the exact page-zero, R-X `__TEXT`, R-- `__WHEELER`, zeroed arm64 state with PC `0x100000290`, and macOS 13 build record.

## Acceptance

- [x] arm64 Mach-O header and command bytes are fixed.
- [x] Runtime and capsule occupy separate R-X and R-- segments.
- [x] Capsule file and memory ranges are page-safe and nonoverlapping.
- [x] Static entry state contains only the exact runtime program counter.
- [x] Locator binds plan, runtime, capsule, and entry ranges.
- [x] Verification rebuilds and compares the complete image.
- [x] PREV identifies unsigned output separately from build inputs.
- [x] Returned runtime storage is owned.
- [x] The format contains no ambient host authority or adjacent path.

## Rejected alternatives

### Put capsule bytes in `__TEXT`

Rejected. Metadata must not inherit execute permission from runtime instructions.

### Use `LC_MAIN` and ambient dyld startup

Rejected for this static profile. It would introduce a dynamic-loader command graph before runtime linkage and library identities have independent evidence.

### Add sections and symbols for convenience

Rejected. Runtime text and the locator provide the only required entry and capsule coordinates. Debug and signing material belongs to separately identified profiles.

### Claim native launch from structural bytes

Rejected. Valid layout does not prove maintained runtime code, host ABI behavior, Apple signing policy, or Wheeler semantic parity.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0368](WIP-0368-platform-abi-and-native-image-identities.md)
- [WIP-0369](WIP-0369-canonical-application-capsules.md)
- [WIP-0371](WIP-0371-embedded-application-capsule-startup.md)
- [WIP-0372](WIP-0372-canonical-elf-capsule-images.md)
