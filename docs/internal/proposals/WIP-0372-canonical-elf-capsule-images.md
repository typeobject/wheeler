# WIP-0372: Canonical ELF capsule images

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler native, runtime, package, security, and release maintainers |
| Created | 2026-08-24 |
| Updated | 2026-08-24 |
| Area | Native bootstrap, ELF64, capsule segments, locators, unsigned PREV |
| Depends on | WIP-0008, WIP-0023, WIP-0026, WIP-0368, WIP-0369, WIP-0371 |
| Supersedes | Appended capsule trailers and section-header locators |
| Superseded by | None |

## Summary

Add the first canonical ELF64 adapter for one position-independent runtime text and one WIP-0369 application capsule.

`ElfImage` emits an `ET_DYN` image with one read-execute load segment, one read-only nonexecutable capsule segment, a nonexecutable stack declaration, and one fixed locator inside the first load segment. It binds exact WIP-0368 plan, platform ABI, portable WBC, runtime-text, and capsule identities. Verification parses all loader fields, verifies the capsule, recomputes the unsigned PREV, and reproduces every output byte.

This WIP implements image layout and verification. It does not provide runtime machine code, a Wheeler-to-native compiler, a Linux system-call shim, process startup, signing, or a claim that arbitrary supplied text launches Wheeler. WIP-0371 remains the format-neutral startup authority that eventual runtime text must invoke.

## Accepted profile

Schema 1 accepts these targets:

| Architecture | ELF machine | Target |
| --- | ---: | --- |
| `x86_64` | 62 | `x86_64-unknown-linux-gnu` |
| `aarch64` | 183 | `aarch64-unknown-linux-gnu` |

The ABI must be schema-1 ELF, little-endian, 64-bit, and `linux-gnu`. `PlatformAbi` already enforces pointer width and byte order. The plan must select ELF, embedded-VM mode, stripping, the exact ABI identity, exact capsule identity, exact runtime-text identity, and the ABI-derived target. The capsule must select the same platform ABI and runtime mode.

The plan's portable artifact is the root WBC entry identity. This first profile does not choose another WBC at load time.

## ELF layout

The image has no section-header table, interpreter, dynamic table, relocation table, symbol table, writable data segment, build ID, timestamp, path, or appended trailer. All integers use ELF64 little-endian encoding.

```text
file offset 0
    ELF64 header                         64 bytes
    PT_LOAD R-X program header           56 bytes
    PT_LOAD R-- program header           56 bytes
    PT_GNU_STACK RW program header       56 bytes
    Wheeler locator                      96 bytes
    zero alignment padding                8 bytes
file offset 336
    position-independent runtime text
    zero page padding
page-aligned offset
    canonical application capsule
end of file
```

`ET_DYN` uses virtual addresses equal to file offsets. The loader chooses the image base. The ELF entry is `336 + runtime_entry_offset`. Runtime text therefore must be position-independent and contain its own verified WIP-0368 host shim.

The first `PT_LOAD` spans headers, locator, padding, and runtime text. Its flags are read and execute. The second spans exactly the capsule and is read-only. It starts at the platform page alignment and is not executable. `PT_GNU_STACK` is read-write without execute and carries no bytes. No segment is writable and executable.

The runtime/capsule page gap is file padding outside either load segment. Every padding byte is zero.

## Locator

The 96-byte locator begins at file offset 232:

| Offset | Width | Field |
| ---: | ---: | --- |
| 0 | 8 | `WHLLOC01` magic |
| 8 | 32 | Native image plan identity |
| 40 | 4 | Runtime file offset, fixed at 336 |
| 44 | 4 | Runtime bytes |
| 48 | 4 | Capsule file offset |
| 52 | 4 | Capsule bytes |
| 56 | 4 | Entry offset inside runtime text |
| 60 | 4 | Zero reserved field |
| 64 | 32 | Capsule identity |

The runtime can reach the locator through its fixed image-relative layout. It does not reopen `/proc/self/exe`, inspect `argv[0]`, search section names, use debug symbols, or consult the current directory. A later native startup entry must cross-check the loader-mapped ranges and page permissions before passing capsule bytes to WIP-0371.

## Construction

Construction receives one native image plan, resolved platform ABI, verified capsule object, runtime text, and entry offset. It rejects before output unless:

- format, target, ABI, runtime mode, and stripping policy agree.
- ABI and capsule identities agree with the plan.
- capsule root ABI and runtime mode agree.
- runtime SHA-256 equals the plan runtime identity.
- root WBC SHA-256 equals the plan portable artifact.
- entry offset names one runtime byte.
- runtime, capsule, padding, and complete image fit their bounds.

Runtime text admits at most 16,777,216 bytes. The complete image admits at most 67,108,864 bytes and may not exceed the platform memory bound. The capsule retains its 33,554,432-byte bound.

Construction writes no source epoch or other timestamp. It performs no host ELF probing, linker invocation, filesystem access, environment read, locale conversion, randomization, signing, or native code generation.

## Verification

Verification accepts retained image bytes plus the exact plan and ABI. It checks:

1. ELF magic, class, byte order, version, OSABI, machine, and `ET_DYN` type.
2. entry address, header widths, three program headers, and absent section headers.
3. exact segment offsets, virtual addresses, file and memory sizes, flags, and alignment.
4. nonexecutable stack and absence of writable-executable load segments.
5. locator magic, reserved field, plan identity, ranges, entry, and capsule identity.
6. runtime text SHA-256 and all plan, ABI, capsule, mode, and root-WBC bindings.
7. complete WIP-0369 capsule framing and identity.
8. byte-for-byte reproduction through the canonical encoder.

The final unsigned PREV is SHA-256 of the complete ELF bytes. `VerifiedImage` has no public constructor and owns its runtime array. Signing remains a later artifact identity.

The maintained x86-64 fixture contains 4,652 bytes. Runtime text starts at offset 336 and the capsule at offset 4,096. Its unsigned PREV is:

```text
9a8db1ccd58cc43beb78394bcfa4f4c710ff7639acc1a8d57dc9764071ce6a58
```

## Failure boundary

Reject malformed identification, noncanonical header widths, unknown machine, section tables, changed entry, changed flags, writable-executable loading, executable stack, locator damage, reserved bits, range escape, misalignment, nonzero padding, runtime damage, capsule damage, plan disagreement, ABI disagreement, unsupported target, unstripped policy, AOT mode, wrong portable artifact, empty runtime, bad entry offset, and excess output.

A structurally valid ELF and valid capsule do not prove that runtime text implements Wheeler startup. Runtime code identity is bound, not interpreted. Recovery release policy must name an independently reproduced runtime implementing WIP-0371 and the WIP-0368 service ABI before treating the image as runnable Wheeler output.

## Evidence

`ElfImageTest` builds the same image from independent runtime arrays, checks ELF type, machine, entry, program-header count, exact R-X, R--, and nonexecuting-stack flags, page-aligned capsule placement, plan and capsule identities, owned runtime output, fixed byte count, and fixed PREV.

Independent mutations damage ELF class, locator magic, segment permissions, runtime text, zero padding, and capsule content. Every image rejects. Construction also rejects changed runtime and portable-artifact identities, unstripped policy, ABI disagreement, an out-of-range entry, and empty runtime text. A second fixture emits and verifies ELF machine 183 for AArch64.

`ApplicationCapsuleExampleTest` threads one compiled Wheeler artifact through capsule verification, image-plan binding, canonical ELF construction, ELF verification, and the separate format-neutral startup authority. The supplied ELF text is treated only as bound native input and is not executed as Wheeler runtime code.

Focused package-format evidence completes in one second and invokes no linker or platform loader.

## Acceptance

- [x] ELF64 headers and program headers are canonical and bounded.
- [x] Runtime text is position-independent input bound by the native image plan.
- [x] Capsule bytes occupy one page-aligned read-only nonexecutable load segment.
- [x] Runtime text occupies one read-execute, nonwritable load segment.
- [x] The stack declaration is nonexecutable.
- [x] Locator ranges and identities do not depend on paths or section headers.
- [x] Verification rebuilds exact bytes and publishes unsigned PREV only after success.
- [x] x86-64 and AArch64 Linux machine profiles are explicit.

## Rejected alternatives

### Append the capsule after an ordinary executable

Rejected. A trailer is not a loader mapping and has ambiguous stripping, signing, and replacement behavior.

### Depend on `.wheeler` section names

Rejected. Section headers are not required for loading and stripping may remove them. Startup uses load segments and a fixed locator.

### Make the capsule segment executable

Rejected. WBC and resources are data. The runtime interpreter reads them from nonexecutable pages.

### Put runtime and capsule in one R-X segment

Rejected. That grants execute authority to attacker-controlled resource and metadata pages and prevents direct permission auditing.

### Claim arbitrary runtime bytes implement Wheeler

Rejected. The adapter binds bytes and layout. Recovery policy must separately establish the runtime identity and its startup semantics.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0368](WIP-0368-platform-abi-and-native-image-identities.md)
- [WIP-0369](WIP-0369-canonical-application-capsules.md)
- [WIP-0371](WIP-0371-embedded-application-capsule-startup.md)
- [WIP-0373](WIP-0373-physical-elf-image-command.md)
