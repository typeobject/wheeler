# WIP-0131: Native RNIC compare-and-swap completion

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native I/O maintainers |
| Created | 2026-08-17 |
| Updated | 2026-08-17 |
| Area | Native I/O, RNIC atomics, completion |
| Depends on | WIP-0032, WIP-0128, WIP-0129, WIP-0130 |
| Supersedes | Native RNIC atomics outside the portable request lifecycle |
| Superseded by | Native cancellation, peer, and persistence evidence stages |

## Summary

Run native 64-bit compare-and-swap through `IoRequest` and `IoScope`. One request binds a current read-write registration, an aligned eight-byte range, expected value, and replacement value.

A successful completion publishes the exact value observed by the backend. `exchanged` derives only from equality between observed and expected values. The registry never accepts a provider-supplied success flag.

Native atomic completion remains distinct from peer acknowledgement and persistence.

## Backend boundary

`NativeRnicRegistry.Backend.compareAndSwap64` receives the private native handle, registration-relative offset, expected value, and replacement value. It returns `IoProviderResult<NativeAtomicCompletion>`.

A backend success carries generation, relative offset, expected value, replacement value, observed value, and a lowercase SHA-256 evidence identity. Successful provider progress must equal eight bytes.

No backend method runs during request construction.

## Admission

The registry requires `REMOTE_READ_WRITE`. Read-only and write-only registrations cannot issue atomics.

The selected range must contain eight bytes. The effective native address plus relative offset must align to eight bytes. Rights, bounds, and alignment fail before request authority or backend work.

The request identity binds registration identity, relative offset, expected value, and replacement value. Work accounting charges eight bytes.

## Completion

Execution checks registration currency before and after backend work. Revocation before backend entry returns zero-progress uncertainty and invokes no atomic operation. Revocation during native work prevents completion publication.

A success row must preserve generation, offset, expected value, replacement value, exact progress, and evidence syntax. The observed value may hold any signed 64-bit pattern.

`AtomicCompleted.exchanged()` returns `observed == expected`. If the comparison fails, completion remains successful and exposes the observed value. The registry does not claim a write occurred.

Malformed success returns bounded uncertainty and no `AtomicCompleted` object.

## Identity

The registry hashes this tuple under `wheeler-native-rnic-cas64-completion-1`:

```text
registration NUL relative-offset NUL expected
NUL update NUL observed NUL backend-evidence-identity
```

`AtomicCompleted` has a private constructor. It exposes the exact registration, range, requested values, observed value, derived exchange result, backend evidence, and canonical identity.

## Authority boundary

Atomic completion proves one backend atomic result under the current registration generation. It does not prove peer application above the RNIC, durable cache flush, replicated acceptance, or power survival.

The API provides no promotion to remote persistence or `DurabilityReceipt`.

## Evidence

`NativeRnicRegistryTest` executes one successful exchange from 11 to 19 and checks the observed value, derived exchange result, backend evidence, and final backend state. A second request expects 11, observes 19, reports no exchange, and leaves state unchanged.

The test rejects insufficient rights and unaligned handles before backend work. It revokes a queued aligned request and requires zero-progress uncertainty without an atomic backend call.

Focused runtime tests pass under Java 26. Java compilation treats warnings as errors. Both the registry and its test remain below 1,000 lines.

## Acceptance

- [x] Request construction performs no backend atomic operation.
- [x] Atomics require `REMOTE_READ_WRITE`.
- [x] The selected native range is exactly eight bytes and aligned.
- [x] The request binds generation, offset, expected value, and replacement value.
- [x] Pre-execution revocation invokes no backend work.
- [x] Post-backend revocation cannot publish completion authority.
- [x] Every nonsuccess provider result keeps its terminal kind and progress.
- [x] Successful generation, operands, progress, and evidence match exactly.
- [x] Completion publishes the exact observed value.
- [x] Exchange success derives from `observed == expected`.
- [x] A failed comparison remains a valid completion without a write claim.
- [x] Malformed success becomes bounded uncertainty.
- [x] Completion has no peer or persistence promotion.
- [x] Focused tests and Java compilation pass.
- [x] Every authored file remains below 1,000 lines.

## Rejected alternatives

### Accept atomics under write-only rights

Rejected. Compare-and-swap both observes and may replace remote state.

### Trust a backend exchange flag

Rejected. The observed value and requested expected value determine the result exactly.

### Permit unaligned atomics

Rejected. The portable provider cannot infer safe hardware behavior for an unaligned native range.

### Treat comparison failure as operation failure

Rejected. A completed compare-and-swap may validly observe a different value and perform no replacement.

### Publish completion after revocation

Rejected. Atomic authority names one current registration generation.

### Promote atomic completion to persistence

Rejected. RNIC atomic completion supplies no media, replication, or power evidence.

## References

- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [WIP-0128](WIP-0128-native-rnic-registration-authority.md)
- [WIP-0129](WIP-0129-native-rnic-one-sided-write-completion.md)
- [WIP-0130](WIP-0130-native-rnic-one-sided-read-completion.md)
- [I/O lifecycle reference](../../public/reference/io-lifecycle.md)
