# WIP-0368: Platform ABI and native image identities

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime, package, native backend, and release maintainers |
| Created | 2026-08-24 |
| Updated | 2026-08-24 |
| Area | Native bootstrap, platform ABI, image identity, host effects |
| Depends on | WIP-0008, WIP-0025, WIP-0026 |
| Supersedes | Unversioned native host and image plans |
| Superseded by | None |

## Summary

Fix the first platform ABI descriptor and native image plan identity before a native backend becomes an execution authority.

The platform descriptor binds loader format, architecture, minimum OS ABI, scalar layout, page and alignment rules, hard resource bounds, CPU features, baseline libraries, and every admitted host service. The native image plan then binds the portable WBC, platform ABI, capsule, backend, runtime, compiler, sysroot, provider closure, options, and link arguments. Native output bytes and signatures remain later artifacts. They cannot alter either input identity.

This is the contract for building a backend. It is not a backend, executable capsule, C shim, or recovery release.

## Scalar and status ABI

Profile 1 is little-endian and uses 64-bit pointers. An ABI address is an unsigned 64-bit offset inside one reservation returned by `memory-reserve`. It is not a source pointer and cannot escape into persisted state. A byte span is `(address: u64, length: u64)`. A mutable span carries the same fields and requires write authority for the complete range. The shim checks address-plus-length arithmetic before touching memory.

Handles are nonzero unsigned 32-bit values owned by the Wheeler runtime. Closing or releasing a handle consumes it. Zero is invalid. A capability handle and an opened file handle are distinct domains even though both occupy 32 bits.

Host calls return one stable status instead of unwinding a host exception through Wheeler frames:

| Code | Name | Meaning |
| ---: | --- | --- |
| 0 | `OK` | The complete reported operation succeeded. |
| 1 | `INVALID` | Framing, range, flag, or handle validation failed. |
| 2 | `DENIED` | The supplied capability does not grant the operation. |
| 3 | `NOT_FOUND` | An exact capability-relative object does not exist. |
| 4 | `EXHAUSTED` | A declared handle, memory, byte, or platform bound is exhausted. |
| 5 | `IO` | The host reported an I/O failure not covered by another code. |
| 6 | `INTERRUPTED` | No completion was published and the operation may be retried. |
| 7 | `UNSUPPORTED` | The descriptor or platform cannot provide the requested operation. |
| 8 | `CHANGED` | A validated object changed before publication. |

A successful read or write reports its completed byte count. Short completion is explicit and never inferred from status. `process-exit` does not return. Unknown status values are fatal ABI violations.

## Service table

Schema 1 fixes these signatures:

| Service | Signature |
| --- | --- |
| `capability-file-open` | `(u32, byte-span, u32) -> (status, u32)` |
| `directory-manifest` | `(u32, mut-span) -> (status, u64)` |
| `file-atomic-replace` | `(u32, byte-span, byte-span) -> status` |
| `file-read-at` | `(u32, u64, mut-span) -> (status, u64)` |
| `memory-protect` | `(u32, u64, u64, u32) -> status` |
| `memory-release` | `(u32) -> status` |
| `memory-reserve` | `(u64, u64) -> (status, u32, u64)` |
| `monotonic-deadline` | `() -> (status, u64)` |
| `process-arguments` | `(u32, mut-span) -> (status, u64)` |
| `process-exit` | `(i32) -> noreturn` |
| `stderr-write` | `(byte-span) -> (status, u64)` |
| `stdin-read` | `(mut-span) -> (status, u64)` |
| `stdout-write` | `(byte-span) -> (status, u64)` |
| `target-submit` | `(u32, byte-span, mut-span) -> (status, u64)` |

The first twelve services, excluding `monotonic-deadline` and `target-submit`, form the required CLI and allocator baseline. The two optional calls enter the descriptor only when launch policy grants a matching implementation. Environment variables, wall-clock time, network sockets, random devices, unrestricted paths, dynamic loading, process creation, and host object references have no profile-1 service number.

File paths are strict UTF-8 capability-relative bytes. The descriptor bounds path bytes, one I/O operation, process arguments, handles, and total reserved memory. Directory manifests are canonical sorted records. Atomic replacement consumes two capability-relative paths and publishes no durability claim beyond the receipt owned by WIP-0032.

`memory-protect` cannot create writable executable memory in profile 1. The host shim reserves, releases, and changes page access. The Wheeler allocator owns allocation, object layout, regions, stacks, history, and reclamation policy.

## Canonical platform descriptor

`PlatformAbi` accepts only canonical lowercase target names, sorted distinct feature/library/service lists, profile-1 scalar layout, power-of-two page and alignment values, and bounded positive limits. Missing required services reject. Adding an optional service changes the identity.

The descriptor is canonical schema-1 YAML. Its identity is SHA-256 of the exact UTF-8 bytes. The maintained AArch64 ELF fixture is 691 bytes and has identity:

```text
3a5f3c8d56a3ce57b02d04cb4f8cbc55d38c5fc4355cb3bf851686f7ae332f6d
```

The fixture names no terminal, locale, environment, clock source, random source, network, current directory, executable path, user, or process identifier.

## Native image plan

`NativeImagePlan` is a build-input record, not an executable manifest. It binds:

- loader format and canonical target triple.
- embedded-VM or AOT runtime mode.
- sealed and stripping policy.
- portable WBC artifact identity.
- platform ABI and application capsule identities.
- backend, runtime, compiler, and sysroot identities.
- provider-closure, options, and canonical link-argument identities.

All content references are lowercase SHA-256 identities. The schema contains no timestamp, build directory, temporary path, job count, host name, user, locale, signing output, or native output digest. The maintained plan fixture is 946 bytes and has identity:

```text
4e944b6b0ce56e164f22bb079e867eb951b6f60de8b676d2216431d2d35603e9
```

The unsigned executable PREV is the digest of output bytes produced from this plan. Signing, notarization, and packaging bind that PREV under separate release records. These records do not feed back into the plan or capsule identity.

## Failure boundary

Construction rejects malformed identities, noncanonical targets, unsupported pointer width or endianness, invalid page geometry, misaligned memory bounds, excess lists, duplicate or unordered names, missing required services, and ambient service invention. No repair, sorting, default service insertion, target inference, or host probing occurs.

`PlatformAbiParser` and `NativeImagePlanParser` accept at most 16,384 strict-UTF-8 bytes, require exact schema and field sets, construct the same bounded records, and compare the complete input against canonical output. Comments, reordered fields or lists, unknown fields or enum values, malformed UTF-8, excess bytes, and numeric overflow reject instead of normalizing.

WIP-0372 consumes the parsed records and rejects a runtime, portable artifact, capsule, target, or ABI identity that differs from the plan before ELF publication.

## Evidence

`PlatformAbiTest` snapshots every canonical byte, recomputes SHA-256 independently, round-trips the strict parser, checks fixed status and service signatures, changes page and service inputs, and rejects incomplete, unordered, 32-bit, non-power-of-two, malformed-UTF-8, noncanonical, and oversized profiles. The parser retains the 64-bit memory bound without narrowing it through a host integer.

`NativeImagePlanTest` snapshots every canonical byte and identity and round-trips the strict parser. It proves that the portable artifact, runtime mode, sealing policy, and stripping policy enter identity and rejects malformed identities, targets, transports, and runtime modes.

The focused package-format suite performs no host calls and completes in two seconds.

## Acceptance

- [x] The first platform ABI fixes scalar width, endianness, status codes, spans, handles, services, and bounds.
- [x] Required and optional services are explicit and canonically ordered.
- [x] Ambient environment, network, randomness, clocks, paths, loading, and process creation are absent.
- [x] The platform descriptor has deterministic canonical bytes, strict parsing, and SHA-256 identity.
- [x] The native image plan binds portable semantics, ABI, capsule, tools, runtime, providers, options, and linkage through the same strict transport.
- [x] Unsigned output PREV and signing identities remain outside build-input identity.
- [x] Malformed, incomplete, unordered, duplicated, unsupported, and out-of-bound inputs reject.
- [x] Focused byte, identity, mutation, and negative evidence passes.

## Rejected alternatives

### Use the target triple as the ABI

Rejected. A triple does not bind page geometry, CPU baseline, loader contract, system libraries, host services, bounds, or status behavior.

### Expose `errno` and host pointers

Rejected. Their width, lifetime, thread behavior, and meaning belong to a host C runtime. Wheeler receives fixed status values, checked spans, and owned handles.

### Hash native output into the input plan

Rejected. That cycle cannot be constructed. The plan identifies inputs. PREV identifies unsigned output. Release signatures identify signed distribution artifacts.

### Add services when the host happens to provide them

Rejected. Host discovery would make authority and identity depend on the launch machine. Optional services must be named in the descriptor and granted by policy.

## References

- [WIP-0008](WIP-0008-java-free-runtime-and-native-bootstrap.md)
- [WIP-0025](WIP-0025-native-ffi-and-system-integration.md)
- [WIP-0026](WIP-0026-self-contained-native-executables.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [WIP-0372](WIP-0372-canonical-elf-capsule-images.md)
