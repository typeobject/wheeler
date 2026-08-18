# WIP-0129: Native RNIC one-sided write completion

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native I/O maintainers |
| Created | 2026-08-17 |
| Updated | 2026-08-17 |
| Area | Native I/O, RNIC transfer, completion |
| Depends on | WIP-0032, WIP-0128 |
| Supersedes | Native writes outside the portable request lifecycle |
| Superseded by | WIP-0130 for one-sided reads, followed by atomic, peer, and persistence stages |

## Summary

Run bounded native one-sided writes through `IoRequest` and `IoScope`. The request captures one current write-capable registration, one registration-relative target range, one held source range, and the exact source-content identity.

Backend work starts only after lifecycle submission. A successful backend result becomes `NativeRnicRegistry.WriteCompleted` only when generation, range, byte count, progress, and evidence identity all match the request.

Native completion remains below peer acknowledgement, peer application, remote persistence, and durability receipt authority.

## Backend boundary

`NativeRnicRegistry.Backend.write` receives:

- the private current native handle
- the registration-relative target offset
- the held source owner
- the source offset
- the exact byte count

The backend returns an ordinary `IoProviderResult<NativeWriteCompletion>`. Failure, cancellation before effect, cancellation after partial effect, and uncertainty retain their existing lifecycle meanings and progress.

A success row carries registration generation, relative offset, completed bytes, and a lowercase SHA-256 evidence identity. The registry requires successful provider progress to equal the requested length.

## Request construction

`write` checks provider identity, current generation, write rights, target range, source range, and positive length before it captures the source. Read-only registrations and malformed ranges leave the source available and invoke no backend method.

The registry snapshots the admitted source range and hashes it before the hold. It then holds the source until terminal completion releases request resources. Request construction invokes no backend code.

The request identity binds registration identity, relative offset, and length. Work accounting charges the exact byte count.

## Races

Execution checks registration currency before backend entry and after backend completion. Revocation or disconnect before backend entry returns uncertainty with zero progress and invokes no backend write.

A generation that becomes stale while native work runs returns uncertainty even when the backend reports success. Native completion cannot revive revoked registration authority.

The registry does not serialize backend work beneath its monitor. Revocation can race native work, and the backend owns native deregistration coordination. The second generation check closes publication.

## Completion identity

A valid completion hashes this tuple under `wheeler-native-rnic-write-completion-1`:

```text
registration NUL relative-offset NUL bytes
NUL content-identity NUL backend-evidence-identity
```

`WriteCompleted` has a private constructor. It exposes the exact registration, relative offset, completed bytes, source-content identity, backend evidence identity, and canonical completion identity.

A malformed backend success publishes only `UNCERTAIN`. The registry bounds reported progress to the requested range. It publishes no `WriteCompleted` object.

## Authority boundary

`WriteCompleted` proves that the configured native backend completed one local RNIC write operation against the exact registration generation. It does not prove:

- remote CPU observation
- peer protocol acknowledgement
- application consumption
- cache or media persistence
- replicated persistence
- power-loss survival

No conversion to `RemoteMemory.PeerAcknowledgement`, `RemoteMemory.Persistence`, or `DurabilityReceipt` exists.

## Evidence

`NativeRnicRegistryTest` proves pure request construction, source ownership capture, exact source hashing, one backend invocation, and terminal owner return through the deterministic portable lifecycle.

The test rejects read-only targets before capture. It revokes a queued target and requires uncertainty without backend work. A backend success with the wrong byte count yields bounded uncertainty and no completion authority.

Focused and complete runtime suites pass under Java 26. Java compilation treats warnings as errors. Repository line and layout bounds remain unchanged.

## Acceptance

- [x] Request construction performs no backend write.
- [x] Target and source ranges validate before capture.
- [x] The source remains held until terminal resource release.
- [x] The request binds one exact current registration generation.
- [x] Read-only registration use fails before capture.
- [x] Pre-execution revocation invokes no backend work.
- [x] Post-backend revocation cannot publish completion authority.
- [x] Every nonsuccess provider result keeps its terminal kind and progress.
- [x] Successful generation, offset, bytes, progress, and evidence match exactly.
- [x] Malformed success becomes bounded uncertainty.
- [x] Completion binds the exact source-content identity.
- [x] Completion has no peer or persistence promotion.
- [x] Focused and complete runtime tests pass.
- [x] Every authored file remains below 1,000 lines.

## Rejected alternatives

### Call the backend during request construction

Rejected. `IoRequest` construction remains pure across every provider.

### Keep a copied staging owner instead of holding the source

Rejected. The native backend registers and reads the exact admitted owner range.

### Accept a shorter successful completion

Rejected. Partial native effects require a nonsuccess row with exact progress.

### Publish completion after revocation

Rejected. Completion authority names one current registration generation.

### Promote native completion to peer acknowledgement

Rejected. Local RNIC completion does not prove peer protocol or application state.

### Promote native completion to persistence

Rejected. Local completion carries no remote flush, replication, or power evidence.

## References

- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [WIP-0128](WIP-0128-native-rnic-registration-authority.md)
- [I/O lifecycle reference](../../public/reference/io-lifecycle.md)
