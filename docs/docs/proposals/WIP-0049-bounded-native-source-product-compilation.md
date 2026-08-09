# WIP-0049: Bounded native source-product compilation

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, module-product, aggregate, ownership, and bootstrap maintainers |
| Created | 2026-08-09 |
| Updated | 2026-08-09 |
| Area | Self-hosting, source lowering, module products, aggregate products, bootstrap |
| Depends on | WIP-0013, WIP-0028, WIP-0044, WIP-0045, WIP-0046, WIP-0047, WIP-0048 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler compiles each scheduled source-local module from its own source, resolved scalar products, imported callable signatures, and nominal aggregate products. It does not read dependency source. The temporary compile artifact is canonical `.wbc`. synthetic signature stubs form a checked suffix and never enter the retained local function window.

This proposal owns the missing lowering boundary between counted semantic products and WIP-0047 body products. WIP-0050 owns aggregate-aware parsing, descriptor construction, ownership projection, and temporary nominal declarations. WIP-0048 remains the owner of closure-wide IDs and final container emission.

## Motivation

The native compiler can publish symbols, signatures, aggregate layouts, identities, ownership events, and final sections. Those products do not by themselves compile the complete physical compiler. The current native core accepts a bounded primitive source profile. Imported primitive calls now type-check against signature-only recursive stubs, but local aggregate declarations and imported nominal types still exceed that profile.

Copying a dependency class into the local source would make the test pass and the architecture fail. It would restore source flattening under a shorter name, make private declarations observable, and bind body identity to irrelevant dependency text.

The source-product compiler needs one explicit rule: local source may be read while its work-slot lease is live. dependency source may not. Everything crossing an edge is a counted product.

## Goals

- Compile a complete source-local class rather than isolated callable fragments.
- Substitute resolved scalar products without copying declarations.
- Compile imported calls from exact signature products.
- Lower local record, variant, fixed-array, and slice declarations.
- Materialize imported nominal descriptors from WIP-0046 products, not source.
- Preserve ownership, loan modes, effects, result slots, proofs, and exact diagnostics.
- Publish only local functions, instructions, types, globals, proofs, and identities.
- Keep every phase bounded, deterministic, and independent of allocation addresses.
- Compile all physical compiler modules before bootstrap promotion.

## Non-goals

- Define final function, string, aggregate, or proof IDs. WIP-0048 owns them.
- Introduce another semantic IR. Canonical `.wbc` 1.0 remains authoritative.
- Execute synthetic stubs.
- Admit unknown opcodes, unresolved calls, or opaque aggregate descriptors.
- Keep generated source, temporary artifacts, or work-slot storage after publication.
- Change the public source language merely to simplify bootstrap compilation.

## Product boundary

One module compilation consumes:

- the leased local source range and its stable module identity.
- local scalar, callable, aggregate, and ownership products.
- ordered direct dependency ranks.
- public imported scalar values and callable signatures.
- imported aggregate module identities and layouts.
- fixed compiler options and recovery limits.

It publishes:

- one canonical source-local `.wbc` product artifact.
- the retained local function and instruction prefix.
- local string, global, aggregate, proof, relocation, and ownership rows.
- stable callable body and aggregate identities.
- exact diagnostic identity on failure.

The publication does not retain dependency source ranges. A caller may archive the validated artifact under `CompiledBodyArchive.w` and release the source lease.

## Signature-only call compilation

An imported callable body is not needed to type-check a call. The compiler appends one deterministic temporary function per resolved imported signature. A nonreversible value stub calls itself with its own parameters and returns that call. A void stub calls itself and falls through. These bodies are valid typed bytecode and are never executed.

Stub order follows callable-product order. Duplicate exact signatures fail before generation. The compile result reports the synthetic suffix. `retainLocalFunctionProduct` requires all local instructions to precede every synthetic instruction and excludes both stubs and a compiler-added inert entry.

Qualified and overloaded calls shall be rewritten to deterministic private stub names from resolved call rows. The written dependency rank and stable signature identity remain relocation authority. Source spelling is not final identity.

## Nominal lowering

Local aggregate declarations are parsed and lowered by the native compiler core. Imported nominal types use generated private declarations derived from WIP-0046 products. Generation uses stable product order and synthetic names that cannot collide with source identifiers.

Generated descriptors preserve:

- aggregate kind and source-local descriptor identity.
- ordered record fields.
- ordered variant cases and payload fields.
- fixed-array element type and length.
- slice element type and loan restrictions.
- recursive record and variant edges.
- owner module identity for every nominal reference.

The generated declaration is compile-time scaffolding. Final emission resolves its descriptor through `AggregateDescriptorRows.w`. no synthetic name or temporary descriptor ID survives.

## Ownership and loans

Temporary stubs do not transfer ownership at runtime because final code cannot target them. Their signatures still undergo ordinary type and loan checking.

Local body publication maps each owner-bearing local to a local or imported aggregate projection. Moves, drops, shared loans, mutable loans, and function-boundary releases must agree with instruction-derived ownership products. A projection mismatch invalidates the body before artifact archival or identity publication.

## Ordering and determinism

For one module:

1. validate the leased local source and product windows.
2. substitute scalar products.
3. generate imported nominal declarations in dependency-product order.
4. generate callable stubs in signature-product order.
5. compile and verify the temporary canonical artifact.
6. resolve local, imported, and aggregate relocations by stable identity.
7. exclude every synthetic function and instruction.
8. publish local products atomically.
9. archive the artifact and release the source lease.

Archive entry order, source arrival order, allocation addresses, hash-table probes, and work-slot reuse do not affect bytes or identities.

## Limits

The recovery profile keeps the accepted bounds:

- 512 local modules and 64 direct dependencies.
- 64 local callables and 64 parameters per callable.
- 256 locals per function.
- 4,096 source-local instructions.
- 64 source-local aggregate descriptors.
- 128 source-local variant cases.
- 256 source-local aggregate members.
- 32,768 generated source bytes.
- 32,768 source-local product artifact bytes.
- 16 MiB closure artifact archive.

Generated declarations and stubs count against the source and temporary function limits. They do not increase retained closure counts.

## Failure behavior

The compiler traps before product publication for:

- missing, private, ambiguous, or mismatched imported signatures.
- qualified calls whose dependency rank does not match the selected product.
- missing or duplicate aggregate products.
- generated-name collision.
- recursive descriptor kinds outside the accepted record and variant graph.
- escaping loans or ownership mismatch.
- a local instruction after the synthetic suffix begins.
- a synthetic target left in retained code.
- any source, function, instruction, aggregate, or artifact limit breach.

Scratch source and temporary artifacts have no identity. Failed compilation leaves no counts, bytes, artifact rank, or body identity published.

## Recovery consequences

Source-product compilation does not set the bootstrap bit. Promotion still requires complete physical closure compilation, byte-identical stage 2, diverse double compilation, and provenance evidence. No `wheeler.bootstrap.yaml` may be checked in before those facts exist.

## Implementation status

- [x] `ProductRootSource.w` substitutes imported scalar products without dependency source.
- [x] `ImportedCallableStubs.w` generates deterministic primitive signature stubs.
- [x] `compileSourceModuleProductWithImports` compiles one complete primitive local class from local source and imported products.
- [x] `compileCallableModuleProductWithImports` compiles counted primitive callable ranges.
- [x] `retainLocalFunctionProduct` excludes stub and compiler-added function suffixes.
- [x] Imported call ranges, including qualified spelling, rewrite to `__wheeler_import_<product-row>` stub names. Any local use of the reserved prefix fails before output mutation.
- [x] `CallableTypeProducts.w` resolves primitive source ranges while local source is leased. Stub generation consumes only type codes, loan modes, effect masks, and parameter windows. Its API has no dependency-source argument.
- [x] WIP-0050 starts aggregate-aware lowering with atomic record, variant, case, and member products, including mutually recursive local nominal types and deduplicated scalar fixed arrays. Descriptor-compatible rows and copied immutable source-string products now cross the source-release boundary without a temporary artifact.
- [x] Complete primitive bodies compile after validated local aggregate declarations are blanked at stable source offsets.
- [x] `compileAggregateSourceModuleProductWithImports` compiles primitive body portions after local-declaration projection and imported nominal validation. Temporary signed carriers and generated descriptors do not enter the retained artifact. Nominal and exact function-local carrier projections publish only after compilation succeeds.
- [ ] WIP-0050 completes local aggregate declaration and instruction lowering.
- [x] Imported nominal names resolve from public WIP-0046 rows and counted artifact-string products without dependency source.
- [x] Imported nominal record and variant compile declarations generate in target-row order and publish owner-scoped temporary source-code projections.
- [x] Resolved imported nominal ranges rewrite after imported calls. Call-name width changes adjust later type ranges without moving or rereading dependency source.
- [x] Counted aggregate archival validates retained descriptor ranges, then removes exact generated aggregate, case, and member suffixes before closure publication.
- [x] Instruction-local create, move, loan, release, and drop owner rows map atomically to aggregate and member projections.
- [x] Final callable local types consume validated temporary nominal projections and exact function-local carrier projections. Aggregate construction operands consume stable aggregate projections.
- [ ] Proof and result-slot products compile with imported callables.
- [ ] Every physical compiler module publishes one source-local product artifact. The counted physical closure now compiles `wheeler.compiler.boolean_tokens`, `wheeler.compiler.identifier_starts`, `wheeler.compiler.resolved_local_returns`, `wheeler.compiler.void_call_kinds`, and `wheeler.compiler.void_call_source_kinds` directly from immutable local archive ranges. Their ordered artifacts match stage 0 byte for byte. Closure-wide iteration remains.
- [ ] WIP-0048 emits the complete physical compiler closure from those products.

## Acceptance

- Primitive imported-call fixtures compile without dependency bodies.
- Stub order and temporary bytes are invariant under source arrival order.
- No retained instruction targets a stub or compiler-added entry.
- Local recursive aggregates and imported nominal signatures compile byte for byte with stage 0.
- Private and ambiguous products fail before output mutation.
- Ownership and loan failures publish no artifact or identity.
- Every physical compiler module compiles within the recovery profile.
- The complete closure passes WIP-0048 emission and native semantic verification.
- No authored file reaches 1,000 lines.
- No Wheeler source directory exceeds ten files.

## Rejected alternatives

**Copy dependency source.** That is source flattening and destroys the product boundary.

**Keep stubs in final bytecode.** Unreachable implementation debris still changes IDs, proofs, costs, and identity.

**Use host AST or `Program` objects.** Java is replaceable stage 0 and cannot own recovery products.

**Invent an unresolved bytecode format.** `.wbc` remains the sole semantic IR. temporary stubs are ordinary verified functions removed before publication.

**Assign nominal IDs from generated names.** Names are scaffolding. Stable aggregate identities and final descriptor rows are authority.
