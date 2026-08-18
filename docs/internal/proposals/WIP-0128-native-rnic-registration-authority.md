# WIP-0128: Native RNIC registration authority

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native I/O maintainers |
| Created | 2026-08-17 |
| Updated | 2026-08-17 |
| Area | Native I/O, RNIC registration, ownership |
| Depends on | WIP-0032 |
| Supersedes | Unbounded host-owned RNIC registration handles |
| Superseded by | A complete native RNIC transfer and persistence provider |

## Summary

Add a bounded native RNIC registration registry. `NativeRnicRegistry` holds an `OwnedIoBuffer` while a backend registration exists and publishes one unforgeable authority containing the provider, owner range, remote rights, generation, native address, local key, and remote key.

Revocation removes authority before backend teardown and releases the owner even when teardown fails. Disconnect revokes all registrations in generation order before it disconnects the native association.

This WIP does not add one-sided transfer, completion, peer acknowledgement, peer application, or remote persistence. WIP-0032 keeps those rows open.

## Interface

A registry fixes one visible provider identity, one backend, and a bound from one through 4,096 live registrations. It accepts three closed rights:

- `REMOTE_READ`
- `REMOTE_WRITE`
- `REMOTE_READ_WRITE`

The backend receives the held owner, exact range, rights, and fresh generation. It returns a `NativeHandle` with address, length, local key, remote key, and the same generation.

The registry rejects zero addresses, negative keys, mismatched lengths, and mismatched generations before it publishes a `Registration`. A failed attempt consumes its generation so no backend-observed generation can be reused.

## Ownership

Registration calls `OwnedIoBuffer.hold()` before entering the backend. Caller reads, writes, snapshots, and duplicate holds fail while the registration remains current.

A successful revoke removes the registration from the current table first. Backend failure cannot restore authority. The registry releases the owner in a `finally` path.

A failed registration asks the backend to tear down any returned handle and releases the owner. Neither a malformed handle nor teardown failure publishes registration authority.

## Identity

The registry hashes this canonical tuple under `wheeler-native-rnic-registration-1`:

```text
provider NUL generation NUL offset NUL length NUL rights
NUL address NUL local-key NUL remote-key
```

Registration constructors remain private. `isCurrent` requires object identity, matching provider identity, a live generation row, and a connected association. Reconstructed field values do not recreate authority.

## Revocation and disconnect

`revoke` rejects registrations from another provider and stale generations. It erases the generation before native deregistration.

`close` first marks the association disconnected, snapshots registrations in generation order, and clears the current table. It then deregisters each native handle, releases every owner, and disconnects the backend. It reports the first backend failure and suppresses later failures. A second close performs no work.

No close failure leaves a current registration or held owner.

## Evidence

`NativeRnicRegistryTest` covers exact range, rights, generation, handle, and identity publication. It checks private registration construction and proves that owner access remains unavailable until revocation.

Capacity exhaustion, wrong-provider use, stale generations, malformed backend handles, out-of-range registration, deregistration failure, and disconnect all fail closed. Disconnect evidence requires generation-ordered teardown and owner release after backend failure.

The focused runtime test passes under Java 26. Java compilation treats warnings as errors. Source length and repository layout remain within policy.

## Acceptance

- [x] Live registrations have a fixed bound no greater than 4,096.
- [x] Every backend-observed registration receives a fresh monotonic generation.
- [x] Registration binds exact owner range, rights, native handle, and provider identity.
- [x] Malformed native handles publish no authority.
- [x] The owner remains held for the complete registration lifetime.
- [x] Revocation removes authority before backend teardown.
- [x] Disconnect revokes registrations in generation order.
- [x] Teardown failure releases every held owner and restores no authority.
- [x] Wrong-provider and stale registration use fail closed.
- [x] The API makes no transfer, completion, peer, or persistence claim.
- [x] Focused tests and Java compilation pass.
- [x] Every authored file remains below 1,000 lines.

## Rejected alternatives

### Expose backend handles directly

Rejected. Native keys and addresses do not identify provider, rights, owner range, or revocation generation.

### Reuse failed generations

Rejected. A backend may have observed the attempted generation before returning malformed data or failing.

### Release owners before deregistration

Rejected. A backend may still hold native access while teardown runs.

### Restore authority after deregistration failure

Rejected. Host failure cannot mint a current registration after revocation started.

### Treat registration as placement

Rejected. Registration transfers no bytes and establishes no remote observation.

### Treat deregistration as persistence

Rejected. Teardown says nothing about peer processing, media flush, replication, or power survival.

## References

- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [I/O lifecycle reference](../../public/reference/io-lifecycle.md)
