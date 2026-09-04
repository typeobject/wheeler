# WIP-0133: Native RNIC peer and persistence evidence

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native I/O maintainers |
| Created | 2026-08-17 |
| Updated | 2026-09-04 |
| Area | Native I/O, RNIC peer protocol, persistence |
| Depends on | WIP-0032, WIP-0128, WIP-0129, WIP-0132 |
| Supersedes | Native RNIC completion used as peer or persistence evidence |
| Superseded by | None |
| Follow-up | Qualified concrete RNIC backends and power-interruption conformance |

## Summary

Add three ordered native RNIC evidence stages above one exact write completion:

1. peer protocol acknowledgement
2. peer application acceptance
3. profile-bound remote persistence

Every stage runs through `IoRequest`. Request construction performs no backend work. Generation, predecessor identity, provider progress, and backend evidence must match before the registry publishes a private-constructor authority.

Remote persistence remains distinct from `DurabilityReceipt`. A release issuer still needs named hardware, software, replication, and power-interruption conformance.

## Completion authority split

`NativeRnicCompletion` now owns local read, write, and atomic completion authorities. `NativeRnicPeerEvidence` owns peer acknowledgement, application acceptance, and remote persistence.

Both classes keep constructors private and expose narrow package factories to the trusted registry. `NativeRnicRegistry` no longer carries hundreds of lines of passive completion records. The registry remains the sole validator and publisher.

This split keeps the registry at 801 lines while making the authority boundary visible in the Java type system.

## Backend rows

The backend receives one fresh operation identity, private native handle, and exact predecessor identity for each stage.

`acknowledge` consumes the native write-completion identity. `apply` consumes the acknowledgement identity. `persist` consumes the application identity and an exact profile identity.

Each backend action returns `IoProviderResult<NativePeerEvidence>` with:

- registration generation
- predecessor identity
- lowercase SHA-256 evidence identity

Successful provider progress must equal one semantic evidence row.

## Publication

The registry checks registration currency before and after backend work. Revocation before backend entry returns zero-progress uncertainty without a peer call. Revocation during provider work blocks evidence publication.

The backend generation and predecessor must match exactly. A stale generation, changed predecessor, malformed evidence identity, or wrong successful progress yields bounded uncertainty.

Nonsuccess provider rows preserve failure, cancellation, and uncertainty semantics through the portable lifecycle.

## Identities

Acknowledgement hashes this tuple under `wheeler-native-rnic-peer-acknowledgement-1`:

```text
write-completion NUL backend-evidence
```

Application hashes this tuple under `wheeler-native-rnic-peer-application-1`:

```text
acknowledgement NUL backend-evidence
```

Persistence hashes this tuple under `wheeler-native-rnic-remote-persistence-1`:

```text
application NUL profile-identity NUL backend-evidence
```

The profile identity must be lowercase SHA-256. It names the exact remote memory, cache, DMA, flush, replication, power-protection, firmware, and software assumptions qualified by a concrete backend.

## Authority boundary

Acknowledgement proves only the backend's named peer protocol stage. Application proves the peer accepted the exact acknowledged write. Persistence proves the concrete backend supplied evidence under one exact profile.

`NativeRnicPeerEvidence.Persistence` does not implement, extend, contain, or convert to `DurabilityReceipt`. It cannot satisfy file, namespace, quorum, or power-loss receipt stages.

WIP-0032 keeps concrete hardware qualification and power-cut acceptance open.

## Evidence

`NativeRnicRegistryTest` writes one exact range, prepares acknowledgement without backend work, and then executes acknowledgement, application, and persistence in order. Backend operation identities are two, three, and four after the write. The test checks the complete object chain and profile identity.

A malformed application predecessor yields uncertainty. A prepared application whose registration is revoked before execution invokes no backend stage and yields uncertainty. Reflection checks private constructors for all three peer authorities.

Focused runtime tests pass under Java 26. Java compilation treats warnings as errors. Completion records moved to their own 236-line file, and the registry remains below 1,000 lines.

## Acceptance

- [x] Local completion, peer acknowledgement, application, and persistence use distinct types.
- [x] Every stage enters through a pure `IoRequest`.
- [x] Every stage receives one fresh native operation identity.
- [x] Acknowledgement names one exact write completion.
- [x] Application names one exact acknowledgement.
- [x] Persistence names one exact application and profile.
- [x] Generation and predecessor identity validate twice around backend work.
- [x] Malformed success publishes only uncertainty.
- [x] Revocation prevents backend entry or later publication.
- [x] Nonsuccess provider rows keep terminal kind and progress.
- [x] Peer and persistence authorities have private constructors.
- [x] Remote persistence has no durability-receipt promotion.
- [x] Focused tests and Java compilation pass.
- [x] Every authored file remains below 1,000 lines.

## Rejected alternatives

### Treat local write completion as acknowledgement

Rejected. Local RNIC completion does not prove peer protocol observation.

### Treat acknowledgement as application

Rejected. Protocol receipt does not prove application acceptance.

### Omit the persistence profile

Rejected. Remote persistence depends on exact hardware, cache, flush, replication, firmware, and software assumptions.

### Return `DurabilityReceipt` from the RNIC backend

Rejected. RNIC evidence alone cannot establish the accepted durability chain or power behavior.

### Put every authority in the registry class

Rejected. Completion and peer evidence are separate type owners, and the registry must remain readable and bounded.

### Publish evidence after revocation

Rejected. Every stage names one current registration generation.

## References

- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [WIP-0128](WIP-0128-native-rnic-registration-authority.md)
- [WIP-0129](WIP-0129-native-rnic-one-sided-write-completion.md)
- [WIP-0132](WIP-0132-native-rnic-operation-cancellation.md)
- [I/O lifecycle reference](../../public/reference/io-lifecycle.md)
