# WIP-0028: Deterministic ownership, borrowing, regions, and no implicit tracing GC

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, compiler, verifier, VM, runtime, library, native, quantum, and proof maintainers |
| Created | 2026-07-19 |
| Updated | 2026-07-19 |
| Area | Type system, ownership, borrowing, memory, regions, deterministic destruction |
| Depends on | WIP-0001, WIP-0002, WIP-0005, WIP-0011, WIP-0012, WIP-0013 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler uses deterministic ownership and region-based storage as its ordinary memory model. The language neither requires nor silently supplies a tracing garbage collector.

Dynamic mutable values have one owner unless an explicit sharing abstraction says otherwise. Copy, move, borrow, mutation, destruction, and escape are statically checked and represented in verified bytecode. The access law is pleasantly short:

```text
one exclusive mutable borrow
or
any number of shared immutable borrows
```

The referent must remain alive and unmoved for the complete loan. Wheeler adopts that safety invariant and Rust-like move discipline without cloning Rust's syntax, complete lifetime calculus, auto-trait menagerie, interior-mutation conventions, arbitrary `unsafe`, or effectful destructor behavior.

Ordinary storage consists of inline values, unique dynamic owners, bounded lexical or dynamic regions, phase arenas with typed IDs, and nonescaping loans. Explicit immutable `Shared<T>` may be a library feature. Host capabilities and foreign resources obey separate effect contracts.

Memory reclamation is deterministic. Automatic destruction may release Wheeler-owned memory and internal accounting; it cannot quietly perform file, network, process, target, provider, clock, random, or other external effects. Those complete through explicit typed operations.

Quantum resources use the same ownership framework in a stricter must-consume affine mode. Qubits and registers cannot be copied, implicitly dropped, reference counted, serialized, or tucked into an ordinary shared graph and forgotten behind the sofa.

## Motivation

The implemented machine already has bounded affine regions, move/drop state, exclusive mutable buffer and map borrows, immutable UTF-8 borrows, primitive owner-returning calls, disjoint slices, affine quantum resources, exact ownership rewind, and hard byte/object ceilings.

The next profile needs compiler-scale arenas, owners crossing calls, borrowed results, package/runtime resource types, and the generic collections specified by WIP-0029. Starting with a general object heap would make reachability an implicit lifetime rule, couple VM/native behavior to collector policy, complicate rewind and FFI pinning, invite finalizers, and make compiler bounds depend on heap weather.

Wheeler's smaller contract is ownership modes, places, origins, loans, regions, deterministic memory reclamation, explicit external cleanup, and bounded compiler/verifier dataflow. VM rewind and source inverse remain distinct; quantum values are affine semantic resources; and the compiler and package manager are acceptance programs rather than toy linked lists with excellent public relations.

## Representative source

This proposal fixes the source spelling `borrow T` for a shared loan and `borrow mut T` for an exclusive loan. Public borrowed results use `returns borrow from name` when the origin is not otherwise unique. WIP-0005 and WIP-0006 own grammar placement and formatting, not alternate ownership dialects.

### Unique owner and loans

```wheeler
Vec<Token> tokens = new Vec<Token>(borrow mut arena, capacity);
tokens.push(token);
consumeTokens(tokens);              // moves tokens

long countKinds(borrow Slice<Token> tokens) {
  ...
}

void normalize(borrow mut Vec<Token> tokens) {
  ...
}

borrow Token first(borrow Slice<Token> tokens)
  returns borrow from tokens;
```

Using `tokens` after the move fails. Shared loans may coexist. An exclusive loan suspends overlapping owner and loan access. The returned token cannot outlive the slice origin.

### Arena graph

```wheeler
Arena<SyntaxRegion> syntax = new Arena<SyntaxRegion>(limits);
NodeId root = parse(source, borrow mut syntax);
check(root, borrow syntax);
drop(syntax);
```

Nodes form graphs or cycles through typed IDs. The arena owns the graph and releases it without tracing individual reachability.

### External and quantum resources

```wheeler
Result<File, OpenError> opened = files.open(path);
File file = opened.value();
Result<void, CloseError> closed = file.close();

borrow mut Qubit left = q.borrowMut(0);
borrow mut Qubit right = q.borrowMut(1);
CNOT(left, right);
```

`File` must close, move, or return on every successful path; scope exit cannot invent a successful host close. Close releases the resource and provides no WIP-0032 durability receipt. Quantum loans must be disjoint and end before measurement or register movement.

### Native pinning

A bounded `Pin<T>` may stabilize storage for one exact WIP-0025 call scope. Pinning is explicit, creates no portable pointer identity, and is not the representation of ordinary loans.

## Goals

- Define copy, move, shared/exclusive borrow, reborrow, drop, must-consume, region, arena, and pin semantics.
- Make mutable dynamic ownership unique by default and derive aggregate ownership structurally.
- Infer deterministic local last-use loan scopes and encode public borrow origins.
- Move owned values across function and module boundaries and return safe owner-tied loans.
- Provide bounded lexical/dynamic regions, unique allocation, and arena graphs with typed IDs.
- Reclaim memory deterministically without an implicit collector, finalizer, or hidden host cleanup.
- Specify optional immutable sharing without making it ambient object semantics.
- Integrate ownership with VM rewind, commit, proof evidence, native lowering, FFI, packages, closures, and quantum resources.
- Give `.wbc` verification enough canonical metadata to reject aliasing, escape, use after move, double drop, and leaked must-consume resources.
- Keep diagnostics source-located, bounded, and useful to somebody who did not write the checker yesterday.

## Non-goals

This WIP does not copy every Rust lifetime, coercion, trait, or `unsafe` rule; require tracing collection; add Java object identity, reflection, finalizers, resurrection, or weak-finalization queues; expose pointers or addresses; permit arbitrary pointer arithmetic; fall back to GC after a failed ownership proof; reference-count every value; run user code during automatic destruction; hide fallible resource cleanup; make allocation/drop intrinsically reversible; persist raw loans; stabilize shared-memory concurrency; or permit quantum resources to be copied or casually dropped by generic containers.

General self-referential owners remain rejected. Cycles use one region/graph owner and typed IDs. Advanced abstractions may retain bounded checks; “zero runtime checks” is not a sacrament.

## Semantic model

### Value modes

Every closed type has compiler-derived canonical properties:

- **Copy:** duplication preserves value and ownership. Bounded scalars, small immutable enums, admitted proof-irrelevant evidence, and all-`Copy` immutable records qualify.
- **Owned:** one binding or aggregate place owns the value. Assignment, passing, and return move unless `Copy` applies.
- **Affine:** the value may be consumed at most once; copying is forbidden. Ordinary unique allocations are affine but may be droppable.
- **Must-consume:** every successful path moves, returns, transforms, or explicitly consumes the value. Live qubits, registers, capabilities, transactions, and external handles may use this mode.
- **Droppable:** deterministic memory-only destruction is valid under the sealed `Drop` contract. A must-consume type may deliberately lack it.
- **Borrowed:** a scoped permission referring to an owner or shorter reborrow; it owns nothing.

`Copy`, `Drop`, and must-consume status are compiler-derived or admitted by sealed evidence. An ordinary WIP-0030 instance cannot make a socket copyable or teach a dirty qubit to disappear.

### Places, origins, and loans

A **place** is a statically identified location: local, state or record field, checked array element, buffer/slice range, region handle, or quantum subrange. Operations apply to places, not untyped addresses.

A **loan** records canonical owner origin, shared/exclusive mode, start, deterministic last use or lexical end, allowed projections, region relation, and optional disjointness evidence. Reborrowing preserves the origin and narrows lifetime/permission. A parent exclusive loan is suspended while a child reborrow lives.

```text
moved(o) => no read, borrow, drop, or second move of o

exclusiveLoan(p) =>
    no overlapping loan and no overlapping owner access

sharedLoans(p) =>
    no overlapping exclusive loan or mutation

lifetime(b) <= lifetime(origin(b))

drop(o) =>
    no live originating loan and no unconsumed must-consume child
```

Simultaneous exclusive loans to `p` and `q` require static proof or a checked prepublication test of `disjoint(p, q)`. A failed dynamic range test publishes neither loan.

Initial loans are second-class. They cannot enter ordinary owned aggregates, persisted state, package archives, certificates, workflow events, retained FFI state, escaping closures, an unrelated task, target submission, measurement transition, or `commit`. A public return or borrowed ABI names its origin explicitly.

WIP-0032 supplies the one suspension exception: an affine operation may own a verifier-visible loan across asynchronous suspension while the continuation cannot access the overlapping place. That loan still cannot enter persisted continuation state; process suspension first completes, cancels and reconciles, or converts the operation to canonical owned resumable state.

### Partial moves and captures

Complete locals and statically representable aggregate fields may move independently. A dynamically indexed element moves only through a collection operation that updates initialized-element state.

A closure copies `Copy` captures, moves owned captures, and may borrow only within the origin lifetime. Exclusive capture is exclusive. A must-consume capture makes the closure must-consume; closure drop is legal only when every capture is droppable. WIP-0031 adds callable characteristics and effects.

## Allocation and reclamation

### Inline and unique storage

Scalars and bounded aggregates may live in frames or inline aggregate storage. Native layout is derived and is never source identity.

A `Box<T>`-like owner stores one `T` in allocator-owned memory. Moving moves ownership; borrowing reaches the contained place; drop destroys `T` under its sealed contract and releases storage.

Owned `Vec<T>`, `String`, builders, maps, sets, and queues expose mutation through unique ownership or exclusive loans. Capacity, allocator, and hard bounds are explicit values or declared execution policy.

### Regions and arenas

A lexical region belongs to one scope. A dynamic region is an affine owner that may cross calls. Both carry unique identity, byte/object limits, allocation policy, child relation, allocation table, and open/closed state.

A region closes only with no live loan, escaped allocation, unfinished child owner, or outstanding explicit resource transition. Successful lexical exit satisfies those rules statically. Trap cleanup follows the separate failure contract below rather than pretending an unclosed file became closed through positive thinking.

Compiler/package phases allocate immutable or phase-owned nodes in arenas and refer to them through nominal `NodeId`, `TypeId`, or `SymbolId`. IDs are meaningful only with access to their arena and are never persisted as addresses.

### Explicit immutable sharing

`Shared<T>` is an optional library owner, not universal representation. Its accepted profile requires immutable fully constructed `T`, no interior mutation, no external resource/finalizer, deterministic bookkeeping, memory-only release, and an API unable to construct strong cycles. Reference-count changes and allocation remain visible effects. General mutable reference-counted graphs are out of scope.

A future traced `GcRegion` requires its own WIP. A runtime may privately trace host implementation objects only when they are not Wheeler values and cannot affect semantics, diagnostics, limits, bytes, finalization, or FFI stability.

## Deterministic destruction

At normal scope exit, memory-only droppable owners are destroyed in canonical order:

1. inner scopes before outer scopes;
2. reverse declaration order within one scope;
3. aggregate fields and collection elements in their declared deterministic order;
4. never allocation-address or hash-bucket order.

Automatic `Drop` is bounded, infallible, nonblocking, nontrapping for valid input, address-blind, and free of host, network, process, target, provider, clock, random, FFI, or user callback effects. External owners use explicit consuming operations such as `close`, `finish`, `commit`, `abort`, or `releaseTarget`, usually returning `Result`.

On a trap, the runtime deterministically reclaims private frame/region memory without invoking arbitrary user code. External resources follow their declared host/runtime failure contract; committed effects remain committed. Must-consume obligations are required on successful paths, not retroactively declared successful after a trap.

## Reversibility, history, and commit

Move marking and loan lifetime changes are often compile-time facts and may appear in `rev` code when the ownership relation remains invertible. Swapping or permuting complete owners may be intrinsically reversible.

Allocation and deallocation are ordinary effects. A `rev` body may use caller-owned clean workspace or a certified reversible allocator protocol; it may not allocate and discard. Drop is valid in intrinsic reversal only for a statically clean/empty value or when exact owned evidence recreates it. Logged history makes rollback possible, not intrinsic inverse.

The VM records allocation, mutation, move, loan, and drop state above the commit horizon and can restore it during rewind. WIP-0001 rewind still does not make allocation/drop legal in a generated inverse. Commit permanently discards older history and permits source-unreachable memory reclamation; no loan spans that horizon.

## Quantum ownership

`Qubit`, `Qreg`, quantum views, ancillas, and target-session resources are must-consume affine values. They implement neither `Copy` nor `Shared` and cannot be serialized as ordinary data.

Shared borrows permit metadata operations only. Gates use disjoint exclusive borrows or an owning register operation. Split creates disjoint affine views with origin/index maps; join checks common origin, nonoverlap, required coverage, and absence of child loans. Measurement consumes or transitions the old quantum identity. Ancillas return clean, transition under an accepted measurement/reset contract, or return to the caller; scope exit does not sweep dirty state under the amplitude rug.

An ordinary `Vec<Qubit>` is valid only if every operation preserves affinity, origin, and consumption; it is not automatically a `Qreg`.

## Capabilities, concurrency, and native calls

Capabilities and external resources are affine or scoped. Importing a package grants no capability. Automatic wrapper-memory release cannot claim an external operation succeeded.

This WIP defines no shared-memory synchronization. Moving immutable owners between structured tasks and sharing immutable values require future `Send`/`Share` evidence. `borrow mut` is not a memory model.

WIP-0025 may lower a loan to one bounded native span when the exact descriptor permits it, storage is pinned or copied for the call, mutability/aliasing agree, and callbacks or retention cannot outlive the scope. Retention requires transfer to an affine foreign owner.

## Asynchronous I/O loans

WIP-0032 requests capture owners or loans without submitting an effect. Submission moves those obligations into an affine `Operation<T>`: reads hold an exclusive destination loan, writes hold a shared source loan, and moved buffers return through terminal results. The loan ends only at final resource-release completion, not at a convenient earlier transport notification.

Provided-buffer leases, registered regions, remote advertisements, tier allocations, and target sessions are bounded affine resources. A live operation is must-consume; scope exit must cancel or complete, reconcile uncertainty, release every held loan, and reap exactly once.

## Reversible IR, proof, bytecode, and packages

Ownership is part of Wheeler's reversible typed IR rather than a source-only lint. Every move, initialization, mutation, loan boundary that survives lowering, release, and resource transition has an exact forward state rule plus its WIP-0001 inverse, logged-rewind, or barrier classification. `rev` bodies may contain only ownership transitions whose inverse relation is checked; coherent and unitary bodies additionally satisfy WIP-0002/WIP-0031 affine resource rules. Native lowering consumes these facts and cannot rediscover weaker alias rules from machine pointers.

Compiler/verifier evidence covers use-after-move, double drop, borrow escape, shared/exclusive compatibility, disjoint split, must-consume completion, region nonescape, and no live loan at destruction. WIP-0011 may expose stronger propositions, but a theorem never disables verifier safety.

Canonical function/type metadata records value mode, structural properties, passing mode, result origin, region/outlives relations, place layout/projections, captures, and disposal obligations. Ownership dataflow assigns each place a state such as:

```text
uninitialized | owned | partially moved | shared borrowed
exclusive borrowed | moved | dropped
```

The verifier derives compatibility across branches and loops and need not keep runtime counts for statically bounded shared loans. Metadata is source-order-independent; native lowering may not weaken verified alias assumptions.

Public ownership is package API. Changes from copy to move, droppable to must-consume, shared to exclusive borrow, result origin, lifetime, disposal, allocator/region requirement, or quantum consumption are compatibility changes.

## Limits and failures

Compiler limits cover owners, regions, loans, projections, control-flow states, disjointness tests, lifetime relations, captures, generic ownership derivations, diagnostics, memory, and total checking work. Runtime limits cover bytes, objects, pins, shared owners, call depth, and cleanup work.

Exhaustion is a deterministic diagnostic, never permission to compile unsafely. Forged ownership metadata, invalid state joins, escape, overlap, or cleanup obligations fail before execution and before any partial artifact is published.

## Migration and deletion

1. Define value modes and canonical ownership metadata.
2. Extend current local owner/borrow checks through call parameters and results.
3. Add deterministic last-use inference and public origin declarations.
4. Add unique allocation and dynamic region owners.
5. Add arena/typed-ID substrate and port compiler syntax and semantic graphs.
6. Add WIP-0029 generic owned collections.
7. Add canonical memory-only destruction and explicit must-consume disposal.
8. Add quantum split/join and ancilla obligations.
9. Add optional acyclic immutable `Shared<T>`.
10. Add WIP-0025 pinning and native conformance.
11. Delete host-GC-backed source values, hidden finalizers, duplicate manual owner flags, and pointer-like bootstrap shortcuts rather than maintaining an ownership museum.

## Progress

- [x] Function-local affine regions and owned buffers execute.
- [x] Nonescaping shared and exclusive parameter borrows execute for bootstrap storage.
- [x] VM snapshots and rewind preserve current owner/drop state.
- [ ] Canonical value modes and public metadata are accepted.
- [x] Primitive `region`, `words`, `bytes`, `utf8`, and `longmap` owners return across calls through canonical typed result metadata. The callee consumes the returned local, every other callee owner must be dead, and storage factories allocate through a nonescaping caller-region borrow; the stage-0 VM and Wheeler-written verifier/interpreter agree and rewind the transfer exactly. `OwnedReturns.w` exercises all five owner kinds. The caller gets one owner, not two handles and a motivational poster.
- [x] Unqualified primitive owner parameters transfer `region`, `words`, `bytes`, `utf8`, or `longmap` ownership into the callee. Definite-ownership flow rejects caller use after the call and requires the callee to drop, forward, or return the owner; bytecode verification, stage-0 execution, Wheeler-native interpretation, and exact rewind agree.
- [ ] Public borrowed results with explicit origins execute.
- [ ] Local last-use inference is deterministic.
- [ ] Unique dynamic allocation executes.
- [ ] Generic arenas and typed IDs support compiler-scale graphs.
- [ ] Deterministic destruction executes without finalizers.
- [ ] Effectful disposal is explicit and must-consume.
- [ ] Quantum split/join and ancilla obligations execute.
- [ ] Optional immutable sharing satisfies acyclicity.
- [ ] Native lowering and FFI preserve ownership.
- [ ] No source-level traced path remains or is required.

## Testing and acceptance

- [ ] `Copy` values duplicate; owned values move; use after move, double move/drop, and forgotten must-consume values fail.
- [ ] Shared loans coexist and block mutation; exclusive loans reject overlap; reborrows suspend and restore parent permissions.
- [ ] Local loans end at deterministic last use; returned loans cannot outlive owners; ambiguous public origins require metadata.
- [ ] Dynamic split rejects overlap before publishing loans.
- [ ] Region drop rejects live loans and escapes; cyclic arena graphs release without tracing.
- [ ] `Box<T>` and collections derive element ownership correctly.
- [ ] Trap cleanup invokes no user finalizer and external failure remains explicit.
- [ ] VM rewind restores ownership/storage above the horizon; generated inverse rejects arbitrary allocation/drop.
- [ ] Qubit/register copy, implicit drop, sharing, and serialization fail; split/join/ancilla obligations pass.
- [ ] `Shared<T>` cannot form a strong cycle through its accepted API.
- [ ] Pinning is bounded and creates no portable address identity.
- [ ] Forged lifetime, loan, move, and drop metadata fails verification.
- [ ] VM and native execution agree on successful and failing ownership transitions.
- [ ] Self-hosted compiler and package-manager acceptance programs run without a tracing collector.

## Alternatives

### Adopt Rust wholesale

Rejected as a specification shortcut. Wheeler keeps the central alias/lifetime laws but has different source ergonomics, rewind, quantum resources, bounded execution, proof boundaries, and explicit effects.

### Use tracing collection or universal reference counting

Rejected as ordinary semantics. Tracing adds implicit liveness, pauses, root/pinning policy, finalization temptation, and VM/native parity work. Universal reference counting adds hidden mutations, cycle policy, and awkward reversible behavior. Explicit future library/region types may propose either without becoming ambient.

### Require manual `free`

Rejected. Static moves, must-consume rules, and regions preserve control without admitting leaks, use-after-free, and double-free as an API style.

### C++-style effectful destructors

Rejected. Hidden fallible I/O during unwinding composes badly with traps, rewind, proofs, and deterministic builds. External cleanup remains source-visible.

### Keep every compiler value forever

Useful for a milestone, not a language contract. Long-lived applications and reusable libraries need bounded nested release.

### Add `unsafe` now

Rejected. WIP-0025 already names the native trust boundary. An unnamed escape hatch is not a substitute for finishing the checker.

## Open questions

- Is `Shared<T>` required for this WIP's first acceptance or its immediate library milestone? — **Owner:** runtime and library maintainers — **Decide by:** standard collection stabilization
- Which must-consume resources receive runtime-managed abort on trap, if any? — **Owner:** runtime and workflow maintainers — **Decide by:** external resource type states
- Are named regions visible in ordinary collection types or only ambiguous public signatures? — **Owner:** type-system and library maintainers — **Decide by:** cross-function borrow support
- Which ownership facts are stored in `.wbc` and which are rederived? — **Owner:** bytecode and verifier maintainers — **Decide by:** ownership section freeze

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0002](WIP-0002-unified-classical-quantum-semantics.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0013](WIP-0013-typed-frames-control-flow-and-storage.md)
- [WIP-0025](WIP-0025-native-ffi-and-system-integration.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [Rust ownership and borrowing](https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html)
- [Linear Haskell](https://doi.org/10.1145/3158093)
- [Region-Based Memory Management in Cyclone](https://doi.org/10.1145/512529.512563)
- [Safe and Flexible Memory Management in Cyclone](http://hdl.handle.net/1903/1304)
