# WIP-0057: Source call, relocation, and ownership coordinate products

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, linker, and ownership maintainers |
| Created | 2026-08-14 |
| Updated | 2026-08-14 |
| Area | Self-hosting compiler, calls, relocation, ownership, callable layout |
| Depends on | WIP-0045, WIP-0047, WIP-0055, WIP-0056 |
| Supersedes | Call and ownership coordinate work embedded in WIP-0055 and WIP-0056 |
| Superseded by | None |
| Follow-up | WIP-0058, WIP-0059 |

## Summary

Carry source calls, call arguments, relocation sites, and ownership effects through the source-ordered callable coordinate plan. Call code and ownership evidence must name the same statement, local, instruction, and callable product as direct and loop code.

This WIP separates cross-product linking from statement-width measurement. It does not add another call resolver or ownership verifier.

## Problem

The compiler already resolves imported call names without dependency source. `LoopCallProducts.w` emits typed call code, local types, stable target identities, and relocation rows. Instruction ownership products derive effect events from canonical artifacts.

Those products still meet too late. Source call rows retain token and target data but not a statement product. Call arguments carry raw callable-local numbers. Relocation rows derive their instruction coordinates from a caller-supplied base. Ownership events begin from decoded instruction rows after artifact emission.

A single root loop hides most disagreement. Sequential roots do not. A call after a retained loop frame can give its code, local types, relocation, and ownership event four different coordinates unless each product consumes the same callable plan.

WIP-0056 owns measured statement widths. This WIP owns the call and effect joins that use them.

## Products

### Call statement rows

Every admitted call retains:

- callable owner
- narrowest containing statement product
- source token range
- call kind and result kind
- ordered argument window
- stable target callable identity

The join uses exact source containment. Parent controls may contain a call statement, but they cannot replace its narrower row. Detached or equal-width ambiguous rows fail before publication.

### Call local rows

Each argument retains its defining value product and offset. The callable plan maps that pair to a physical source local. Each call statement owns its evaluation, transfer, result, and result-copy locals. `LoopCallProducts.w` publishes the exact physical statement width before coordinate planning and consumes the planned start during code emission.

Zero-argument void calls own no local row. They still own an instruction and relocation row.

### Relocation rows

A relocation retains:

- source callable product
- source statement product
- callable-local planned instruction row
- stable target callable identity
- call or uncall direction

The emitter validates the planned instruction row against the encoded call opcode. It does not add an instruction base after emission.

### Ownership rows

Source ownership effects retain the statement and planned local that created, moved, borrowed, released, or dropped an owner. Aggregate construction and loan temporaries publish exact statement widths through WIP-0056. Function-boundary synthetic releases retain a boundary product rather than pretending to be source statements.

Decoded instruction ownership remains independent verification evidence. It must agree with the source product before the artifact enters the compiled body archive.

## Invariants

- Every source call belongs to one callable and one narrowest statement.
- Every call local belongs to that statement's planned physical row.
- Argument locals resolve through defining value products.
- Every relocation names the encoded call instruction in the callable plan.
- Ownership effects use planned locals and instructions.
- Synthetic releases remain distinct from source effects.
- Stable target identities remain authoritative until final linking.
- Dependency source never enters call matching, relocation, or ownership APIs.
- Validation completes before width, code, type, relocation, ownership, or artifact publication.

## Bounds

- 64 source callables per module
- 256 calls per body
- seven arguments per call
- 4,096 source statements
- 256 locals per callable
- 32,768 instructions per callable
- 8,192 ownership events per module

All rows use fixed caller-provided buffers. No pass allocates per call or per event.

## Migration

1. Bind copied source call tokens to exact statement products.
2. Merge exact call widths into WIP-0056 statement rows.
3. Replace raw argument locals with defining value and offset products.
4. Emit call code and local types from planned statement starts.
5. Publish relocation instruction rows from the callable instruction plan.
6. Bind source ownership effects to statement, local, and instruction products.
7. Compare source ownership with decoded artifact ownership before archive publication.
8. Integrate source-root local calls into `StructuredSourceModuleCompiler.w`.
9. Delete caller-supplied call local and instruction bases.
10. Continue nested windows under WIP-0058 and imported targets under WIP-0059.

## Progress

- [x] `SourceCallProducts.w` binds each copied call token to the narrowest containing statement for its callable owner. Detached and equal-width ambiguous rows leave caller storage unchanged.
- [x] Local and imported product-call discovery now share one bounded scanner over copied source and callable-name products. The local API publishes exact target, arity, source, and statement rows without allocating a dependency table. The imported API preserves local shadowing and rejects equal imported matches.
- [x] `LoopCallProducts.w` atomically merges each call's exact local width into its bound statement row. Invalid statements, targets, or argument types preserve existing call and statement widths.
- [x] `SourceCallArgumentProducts.w` parses zero through seven ordered identifier arguments, chooses the latest exact visible defining value, retains signed or Boolean type and source-local evidence, and publishes value-product plus offset rows atomically. Unknown values and unsupported argument forms preserve caller rows. `LoopCallProducts.w` then maps each retained value product and offset through its planned value start. Raw source-local cells are no longer an emission authority.
- [x] `LoopCallProducts.w` takes every call-local base from its bound statement's planned physical start. Caller-populated local-base cells are no longer an authority. Typed argument transfers, result slots, code, types, and statement-width publication share that start.
- [x] `LoopCallProducts.w` takes each relocation instruction from the call's planned instruction start plus its exact argument-transfer width. The caller-supplied instruction base is deleted. Invalid planned rows leave code, type, width, identity, and relocation outputs untouched.
- [x] `InstructionOwnershipProducts.w` atomically joins each nonboundary effect to its source statement, planned instruction, destination local, and source local. Synthetic loan releases retain `-1` as the statement and the exact function-boundary instruction. Invalid source or planned rows preserve caller storage.
- [x] `SourceOwnershipProducts.w` independently authorizes source ownership kind, statement, instruction offset, destination offset, defining source value, and source offset before mapping them through planned statement and value coordinates. Creation, movement, and destruction fixtures publish exact rows. An out-of-range destination publishes nothing.
- [x] `ownershipCoordinatesAgree` requires exact source and decoded statement, instruction, destination, and source rows. The native fixture covers moves, balanced loans, creation, destruction, boundary releases, and explicit disagreement.
- [x] `OwnershipCheckedBodyArchive.w` compares independent source and decoded event counts and all four coordinate rows before it calls the sole bounded archive append. Event-count or coordinate disagreement publishes no rank, table row, or artifact byte. The native ownership fixture archives a real canonical artifact only after agreement and retains sentinels on malformed planned rows or source disagreement.
- [x] `SourceModuleCallProducts.w` scans retained callable body ranges directly, publishes absolute call ranges in callable order, and binds every local call to one exact statement without another source copy.
- [x] `SourceCallableResultProducts.w` establishes signed, Boolean, and void result kinds before call layout. Direct return emission checks the same retained table.
- [x] `SourceCallLayoutProducts.w` validates target arity, ordered parameter types, result kinds, and exact source-measured statement widths before callable coordinate publication. Shared layout functions now define the sole call instruction, byte, and local widths.
- [x] `CallableInstructionPrefixes.w` includes preceding root calls when it plans loop instructions. `SourceCallInstructionProducts.w` then publishes root-call instruction and code windows from direct, loop, and call products in source order.
- [x] `LoopCallProducts.w` now consumes preplanned statement widths, publishes owner-local-type rows, and cannot add a second width after coordinate publication. `CallableReturnProducts.w` includes calls before it places implicit void returns.
- [x] `CallableSourceComposition.w` consumes root call code and local types beside direct and loop products. Signed, Boolean, void, one-argument, and two-argument recursive fixtures match stage 0 byte for byte after a completed root loop.
- [x] WIP-0058 composes calls nested inside structured control windows and publishes exact nested relocation rows after recursive measurement.
- [x] WIP-0059 admits imported callable products and stable external target identities without dependency source.

## Acceptance

- A call after a completed root loop uses the planned physical locals.
- Calls in nested and second-root windows retain contiguous type and code coordinates.
- Value and Boolean results own exact result slots.
- Void calls own no fabricated local.
- Local call relocations name exact planned instructions. WIP-0059 owns imported, qualified, and external relocation publication.
- Ownership events name exact planned locals and instructions.
- Reordered call, relocation, and ownership storage rows do not change artifact bytes.
- Missing target identities, detached statements, malformed widths, and ownership disagreement publish nothing.
- The complete fixture matches stage 0 byte for byte.

## Rejected alternatives

### Keep instruction bases in call emission

Rejected. A later direct or loop product can change the prefix while leaving relocation rows stale.

### Infer call statements from emitted code

Rejected. Emitted code has no source statement identity and cannot publish statement widths.

### Treat decoded ownership as the source product

Rejected. Decoded ownership verifies an artifact. It cannot replace the source product that authorized local allocation and relocation.

## References

- [WIP-0045](WIP-0045-counted-native-module-symbol-products.md)
- [WIP-0047](WIP-0047-counted-native-callable-bytecode-products.md)
- [WIP-0055](WIP-0055-source-ordered-callable-coordinate-products.md)
- [WIP-0056](WIP-0056-measured-source-statement-local-products.md)
