# WIP-0130: Native RNIC one-sided read completion

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native I/O maintainers |
| Created | 2026-08-17 |
| Updated | 2026-09-04 |
| Area | Native I/O, RNIC transfer, completion |
| Depends on | WIP-0032, WIP-0128, WIP-0129 |
| Supersedes | Native reads outside the portable request lifecycle |
| Superseded by | None |
| Follow-up | WIP-0131 for compare-and-swap, followed by peer and persistence stages |

## Summary

Run bounded native one-sided reads through `IoRequest` and `IoScope`. A read names one current read-capable registration, one registration-relative source range, and one caller-owned destination range.

Request construction holds the destination and performs no backend work. Exact native completion publishes only after generation, source range, byte count, provider progress, and backend evidence match. The registry then hashes the bytes that the backend placed in the held destination.

The completion proves one native read operation. It grants no peer, persistence, or durability authority.

## Backend boundary

`NativeRnicRegistry.Backend.read` receives the private current native handle, registration-relative source offset, held destination owner, destination offset, and exact length. It returns `IoProviderResult<NativeReadCompletion>`.

A native success carries registration generation, relative offset, completed bytes, and a lowercase SHA-256 evidence identity. The lifecycle preserves every nonsuccess terminal kind and exact progress.

The backend writes only through the held destination range. The registry does not expose its native handle through `Registration`.

## Request construction

`read` validates provider identity, current generation, remote-read rights, source range, destination range, and positive length before capture. A write-only registration or malformed range leaves the destination available and invokes no backend method.

After validation, the registry holds the destination until terminal resource release. It charges the exact requested byte count as work. The request identity binds registration identity, relative source offset, and length.

## Completion

Execution checks generation currency before and after backend work. Revocation before backend entry returns zero-progress uncertainty without one native call. Revocation during backend work prevents completion publication.

A successful backend result must match:

- registration generation
- registration-relative offset
- requested byte count
- successful provider progress
- lowercase SHA-256 evidence syntax

The registry copies the exact completed destination range while ownership remains held and hashes it. `NativeRnicCompletion.Read` binds registration, range, count, received-content identity, backend evidence identity, and its own domain-separated identity.

A malformed success returns bounded uncertainty and publishes no `NativeRnicCompletion.Read` object.

## Identity

The registry hashes this tuple under `wheeler-native-rnic-read-completion-1`:

```text
registration NUL relative-offset NUL bytes
NUL received-content-identity NUL backend-evidence-identity
```

`NativeRnicCompletion.Read` has a private constructor. Destination ownership returns only through ordinary terminal resource release and reap.

## Authority boundary

A native read completion says that the backend filled the requested destination range under the current registration generation. It does not prove that another machine acknowledged a protocol message, applied a write, persisted media, replicated state, or survived power loss.

The API has no conversion from `NativeRnicCompletion.Read` to peer or durability evidence.

## Evidence

`NativeRnicRegistryTest` constructs a read request and requires zero backend calls before await. The backend fills one interior destination range. The test checks exact bytes, content identity, completion fields, and owner return through the portable lifecycle.

The test rejects a read through write-only registration before destination capture. Existing generation-race and malformed-completion tests cover the shared publication gates.

Focused runtime tests pass under Java 26. The complete runtime suite passed after WIP-0129 and exercises the same provider, lifecycle, ownership, and completion machinery.

## Acceptance

- [x] Request construction performs no backend read.
- [x] Source and destination ranges validate before capture.
- [x] The destination remains held until terminal resource release.
- [x] A write-only registration fails before destination capture.
- [x] The request binds one exact current registration generation.
- [x] Pre-execution revocation invokes no backend work.
- [x] Post-backend revocation cannot publish completion authority.
- [x] Every nonsuccess provider result keeps its terminal kind and progress.
- [x] Successful generation, offset, bytes, progress, and evidence match exactly.
- [x] The registry hashes the exact received destination range while held.
- [x] Malformed success becomes bounded uncertainty.
- [x] Completion has no peer or persistence promotion.
- [x] Focused tests and Java compilation pass.
- [x] Every authored file remains below 1,000 lines.

## Rejected alternatives

### Read into an internal staging owner

Rejected. The backend and lifecycle retain the caller's exact admitted destination range.

### Hash the destination before backend work

Rejected. Read completion binds received bytes, not prior destination contents.

### Release the destination before hashing

Rejected. Caller mutation could race completion identity publication.

### Accept a short successful read

Rejected. Partial native effects require a nonsuccess row with exact progress.

### Treat read completion as peer evidence

Rejected. A local RNIC read completion says nothing about peer protocol state.

### Treat read completion as persistence

Rejected. Reading bytes does not prove cache flush, media stability, replication, or power survival.

## References

- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [WIP-0128](WIP-0128-native-rnic-registration-authority.md)
- [WIP-0129](WIP-0129-native-rnic-one-sided-write-completion.md)
- [I/O lifecycle reference](../../public/reference/io-lifecycle.md)
