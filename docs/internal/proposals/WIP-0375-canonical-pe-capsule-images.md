# WIP-0375: Canonical PE capsule images

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler native, runtime, package, platform, and security maintainers |
| Created | 2026-08-25 |
| Updated | 2026-08-25 |
| Area | Native bootstrap, PE32+, capsule sections, entry RVA, unsigned PREV |
| Depends on | WIP-0008, WIP-0026, WIP-0368, WIP-0369, WIP-0371, WIP-0372, WIP-0374 |
| Supersedes | Format-neutral PE/COFF placeholders |
| Superseded by | None |

## Summary

Define canonical Wheeler PE32+ images for `x86_64-pc-windows-msvc` and `aarch64-pc-windows-msvc`.

The image contains exact position-independent runtime text and one complete application capsule. A read-execute `.text` section contains a fixed Wheeler locator followed by runtime text. A separate read-only `.wheel` section contains exact capsule bytes and canonical file-alignment padding. The image contains no imports, exports, relocations, symbols, debug records, resources, exception table, CLR header, timestamp, checksum, certificate, source path, UUID, or adjacent-file lookup.

This WIP defines unsigned image construction and independent verification. It does not supply Wheeler runtime machine code, a Windows host-service shim, Authenticode, installation, or launch evidence.

## Profile

Schema 1 accepts only:

- PE32+ little-endian x86-64 or arm64.
- `windows-msvc` platform ABI and `pe-coff` image format.
- target `x86_64-pc-windows-msvc` or `aarch64-pc-windows-msvc` matching the ABI.
- embedded-VM runtime mode.
- stripped and sealed plans.
- 4,096-byte memory sections and 512-byte file sections.
- runtime text of one through 16,777,216 bytes.
- one application capsule under WIP-0369's 33,554,432-byte bound.
- a complete file no larger than 67,108,864 bytes and a mapped image no larger than the platform memory bound.

The DOS header occupies 64 bytes and names PE headers at byte 128. PE and section headers end before the fixed 512-byte header boundary. The locator begins at file byte 512 and runtime begins at byte 608.

## COFF and optional headers

The COFF header fixes:

| Field | Value |
| --- | --- |
| Machine | AMD64 `0x8664` or ARM64 `0xaa64` |
| Sections | 2 |
| Timestamp | 0 |
| Symbols | absent |
| Optional header | 240 bytes |
| Characteristics | executable, large-address-aware |

The PE32+ optional header fixes image base `0x140000000`, section alignment 4,096, file alignment 512, operating-system version 6.0, subsystem version 6.0, console subsystem, 1 MiB stack and heap reserves, 4 KiB commits, and sixteen zero data-directory entries. `HIGH_ENTROPY_VA`, `DYNAMIC_BASE`, and `NX_COMPAT` are set. Linker version, image version, checksum, loader flags, exports, imports, resources, exceptions, certificates, base relocations, debug rows, TLS, and CLR data remain zero.

`SizeOfCode`, `SizeOfInitializedData`, `SizeOfHeaders`, `SizeOfImage`, and entry RVA derive from checked canonical ranges. No host linker default enters these fields.

## Sections

`.text` begins at RVA `0x1000` and file byte 512. Its virtual bytes are the 96-byte locator plus exact runtime bytes. Its raw size rounds up to 512 bytes. Its only characteristics are code, execute, and read.

`.wheel` begins at the first 4,096-byte RVA after `.text` and at the first 512-byte file boundary after `.text` raw bytes. Its virtual size is exact capsule length. Its raw size rounds up to 512 bytes. Its only characteristics are initialized data and read.

The entry RVA is:

```text
0x1000 + 96 + runtime-entry-offset
```

The runtime entry offset must identify one retained runtime byte. Capsule padding remains in the PE file but outside capsule framing. Every padding byte is zero and enters PREV.

## Locator and identity

The fixed locator contains:

- magic `WHPLOC01`.
- native image plan identity.
- runtime file offset and length.
- capsule file offset and exact length.
- runtime entry offset.
- one zero reserved field.
- capsule identity.

All integers are unsigned little-endian 32-bit fields admitted through nonnegative host values. The whole unsigned PE file receives SHA-256 PREV. PREV remains distinct from the native image plan, capsule identity, Authenticode subject, and later system-package identity.

The plan must bind exact platform ABI, capsule, root portable WBC, runtime, target, mode, sealing policy, and stripping policy. The capsule root repeats the exact platform ABI and runtime mode.

## Verification

`PeImage.verify` consumes retained bytes, the exact parsed native image plan, and the exact parsed platform ABI. It performs these checks before returning evidence:

1. Enforce file, runtime, mapped-image, and profile bounds.
2. Check DOS magic, zero DOS fields, and fixed PE offset through canonical rebuilding.
3. Check PE signature and every COFF field.
4. Check every PE32+ optional-header field and all sixteen data directories.
5. Check both section names, ranges, alignments, permissions, counts, and flags.
6. Parse and bind the complete locator.
7. Check entry RVA and runtime and capsule file ranges with overflow-safe arithmetic.
8. Parse the exact capsule bytes and bind root WBC, runtime, capsule, target, and ABI identities.
9. Rebuild the complete file and require byte-for-byte equality.
10. Compute unsigned PREV and return owned runtime bytes plus the retained capsule.

Canonical rebuilding rejects nonzero DOS slack, header slack, section slack, capsule padding, reordered sections, alternate versions, populated data directories, extra sections, and trailing bytes without a repair path.

## Failure boundary

Reject malformed or excess bytes, another machine or operating system, PE32, another image format, unstripped or AOT plans, identity disagreement, empty runtime text, an out-of-range entry, wrong root WBC, writable or executable capsule data, writable text, populated import or certificate records, changed padding, malformed capsule framing, and failed canonical reproduction.

A failed construction or verification publishes no output artifact or PREV.

## Evidence

`PeImageTest` constructs the same 2,048-byte x86-64 image twice from independently owned runtime arrays. The fixture places its 556-byte capsule at file byte 1,024 and records unsigned PREV `6957c713e33f7d273b0b39e39d2e3136128468f2c6f6efefafd5adcdc2befca7`. A separate arm64 fixture checks machine identity and owned runtime bytes.

The test independently inspects DOS offset, PE signature, machine, section count, entry RVA, and section permissions. Separate mutations damage DOS magic, timestamp, text permission, capsule permission, locator, runtime, text padding, capsule, and terminal capsule padding. Plan runtime, stripping, root artifact, ABI, entry, and empty-runtime disagreement reject before output.

BSD `file` identifies the fixture as a PE32+ console executable for x86-64 Windows. Apple `objdump -x` accepts its COFF and optional headers, reports entry RVA `0x1060`, image base `0x140000000`, exact alignment and memory limits, all sixteen empty directories, and separate `.text` and `.wheel` sections.

## Acceptance

- [x] x86-64 and arm64 PE32+ machine profiles are explicit.
- [x] Every DOS, COFF, optional-header, and data-directory field is fixed.
- [x] Runtime and capsule occupy separate R-X and R-- sections.
- [x] File and memory ranges are aligned, bounded, and nonoverlapping.
- [x] Locator binds plan, runtime, capsule, and entry ranges.
- [x] Verification rebuilds and compares the complete file.
- [x] PREV identifies unsigned output separately from build inputs.
- [x] Returned runtime storage is owned.
- [x] The format contains no ambient host authority or adjacent path.

## Rejected alternatives

### Append the capsule after section data

Rejected. Authenticode, loaders, and audit tools would disagree about an opaque trailer. Capsule bytes occupy ordinary initialized section data.

### Put capsule bytes in `.text`

Rejected. Metadata must not inherit execute permission from runtime instructions.

### Add an import table before runtime linkage exists

Rejected. Imports must equal the explicit platform baseline and provider closure. Empty data directories avoid inventing linkage evidence.

### Use the COFF timestamp or checksum as identity

Rejected. The timestamp remains zero and the checksum remains outside the unsigned canonical profile. PREV identifies all bytes.

### Claim Windows launch from structural bytes

Rejected. Valid PE layout does not prove maintained runtime code, host ABI behavior, Authenticode policy, or Wheeler semantic parity.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0368](WIP-0368-platform-abi-and-native-image-identities.md)
- [WIP-0369](WIP-0369-canonical-application-capsules.md)
- [WIP-0371](WIP-0371-embedded-application-capsule-startup.md)
- [WIP-0372](WIP-0372-canonical-elf-capsule-images.md)
- [WIP-0374](WIP-0374-canonical-mach-o-capsule-images.md)
