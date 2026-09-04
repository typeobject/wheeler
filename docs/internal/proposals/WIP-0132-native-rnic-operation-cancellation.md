# WIP-0132: Native RNIC operation cancellation

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler runtime and native I/O maintainers |
| Created | 2026-08-17 |
| Updated | 2026-09-04 |
| Area | Native I/O, RNIC cancellation, lifecycle |
| Depends on | WIP-0032, WIP-0128, WIP-0129, WIP-0130, WIP-0131 |
| Supersedes | Association-wide cancellation without operation identity |
| Superseded by | None |
| Follow-up | WIP-0133 for peer and persistence evidence |

## Summary

Give every prepared native RNIC read, write, and compare-and-swap a fresh operation identity. The registry passes that identity to backend execution and to the started-work cancellation hook.

Queued cancellation invokes neither backend execution nor backend cancellation. Running cancellation names exactly one started operation. The backend's terminal `IoProviderResult` remains the sole authority for whether cancellation preceded effect, followed partial effect, lost to completion, or left an uncertain outcome.

## Operation identity

`NativeRnicRegistry` owns one monotonic 64-bit operation counter per connected registry. Request construction consumes the next identity after rights, range, alignment, and ownership preflight succeeds.

The registry never reuses an operation identity. Exhaustion rejects before request publication.

Request identities include the operation number before the registration identity and operation coordinates. Backend `read`, `write`, and `compareAndSwap64` calls receive the same number.

## Cancellation hook

Each RNIC request supplies `IoRequest` with `backend.cancel(operation)`. The portable lifecycle calls this hook only after provider work has started.

A queued cancellation consumes the request, releases its captured owner, and publishes `CANCELED_BEFORE_EFFECT` without backend execution or cancellation calls. This preserves the common queue contract.

A running cancellation invokes the backend hook with the exact operation number. The hook does not fabricate a terminal result. Provider work still returns one typed result through the ordinary action.

## Outcome authority

The registry carries backend failure, cancellation-before-effect, cancellation-after-partial-effect, and uncertainty without changing kind or progress.

A backend may report success after a cancellation request when completion won the race. The lifecycle records that relation. A backend may report uncertainty when native cancellation cannot establish effect boundaries.

Registration revocation remains separate. Revocation invalidates generation authority. Operation cancellation asks a current backend operation to stop. Neither operation grants the other semantic meaning.

## Disconnect

Disconnect first revokes registrations, as WIP-0128 requires. Backends must settle or classify live operations through their own completion queues before association teardown. This WIP adds no silent cancellation during `close` and no fabricated operation result.

A later provider may reject close while live operation rows remain. The current registry delegates live native queue accounting to its backend and keeps portable request ownership in `IoScope`.

## Evidence

`NativeRnicRegistryTest` starts a write on `ThreadedIo`, waits for backend entry, requests cancellation, and requires the backend to receive operation identity one. The backend returns cancellation before effect. The portable completion records `CANCELED_BEFORE_EFFECT`, and terminal reap returns the source owner.

A second test occupies the sole worker, queues a native write, and cancels it before backend entry. It requires zero RNIC write calls, zero native cancellation hooks, and exact owner return.

Focused tests pass under Java 26. Java compilation treats warnings as errors. Registry and test files remain below 1,000 lines.

## Acceptance

- [x] Reads, writes, and atomics receive monotonic operation identities.
- [x] Request and backend execution use the same operation identity.
- [x] Started cancellation names exactly one operation.
- [x] Queued cancellation invokes no backend action or cancellation hook.
- [x] Queued cancellation returns captured owners.
- [x] Running cancellation keeps backend terminal kind and progress authoritative.
- [x] Cancellation creates no completion, peer, or persistence authority.
- [x] Registration revocation and operation cancellation remain distinct.
- [x] Operation identity exhaustion fails before request publication.
- [x] Focused tests and Java compilation pass.
- [x] Every authored file remains below 1,000 lines.

## Rejected alternatives

### Cancel by registration handle

Rejected. One registration may carry several operations, and association-wide cancellation cannot identify one effect.

### Call the cancellation hook for queued work

Rejected. The backend has not received that operation.

### Let the hook publish a terminal result

Rejected. The provider action owns one terminal `IoProviderResult` under the common lifecycle.

### Treat cancellation request as cancellation success

Rejected. Native completion may win, partial effects may exist, or outcome may remain uncertain.

### Reuse operation numbers after cancellation

Rejected. Backend logs and late completion evidence must retain one stable identity.

### Alias cancellation with revocation

Rejected. Cancellation addresses one operation. Revocation removes one registration generation.

## References

- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [WIP-0128](WIP-0128-native-rnic-registration-authority.md)
- [WIP-0129](WIP-0129-native-rnic-one-sided-write-completion.md)
- [WIP-0130](WIP-0130-native-rnic-one-sided-read-completion.md)
- [WIP-0131](WIP-0131-native-rnic-compare-and-swap-completion.md)
