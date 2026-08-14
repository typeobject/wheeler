# WIP-0047: Counted native callable bytecode products

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, bytecode, bootstrap, and conformance maintainers |
| Created | 2026-08-08 |
| Updated | 2026-08-08 |
| Area | Self-hosting, callable bodies, relocation, compiler products |
| Depends on | WIP-0038, WIP-0041, WIP-0044, WIP-0045, WIP-0046 |
| Supersedes | Callable bytecode relocation work in WIP-0045 |
| Superseded by | Final artifact emission moved to WIP-0048 |

## Summary

The native compiler shall link callable bodies from canonical bytecode products. Each source-local `.wbc` product is decoded into bounded function descriptors, local type windows, and instruction ranges. Calls and type references are then relocated against completed scalar, callable, and aggregate identities. Dependency source is neither retained nor flattened.

WIP-0045 owns source callable signatures and source-local compilation. WIP-0046 owns aggregate layouts and ownership products. This WIP owns validated callable products and relocation. WIP-0048 owns final ID assignment and canonical `.wbc` emission.

## Problem

A digest of a source-local artifact proves what was compiled. It does not expose enough structure to link that artifact. A linker needs exact answers for:

- function flags, parameter counts, local counts, and type windows.
- forward and inverse code ranges.
- instruction boundaries, opcodes, operand counts, and operands.
- local call targets and imported callable identities.
- aggregate descriptor references.
- result-slot and ownership conventions.

Reading dependency source again would avoid relocation by recreating one large compilation unit. That is the source flattener this work is intended to remove.

## Requirements

A callable bytecode product shall:

- derive only from canonical `.wbc` 1.0.
- validate the complete container directory before publishing a row.
- admit at most 64 functions and 4,096 instructions per source-local module.
- preserve exact forward and inverse ranges.
- use `InstructionForms.w` as the sole Wheeler-native operand-count owner.
- reject unknown executable opcodes.
- preserve exact local type windows and result-slot flags.
- bind relocation targets to stable callable or aggregate identities.
- reject ambiguous, private, missing, and stale imported products.
- emit the same canonical artifact as stage 0 for the same linked module set.

A source range is not a body product. A body digest is not a relocation table. A linked artifact is not a module product.

## Initial product tables

One function table has ten 64-row columns:

```text
id | flags | forward-start | forward-length | inverse-start |
inverse-length | parameter-count | local-count | type-start | type-count
```

One instruction table has six 4,096-row columns:

```text
function | direction | artifact-start | opcode | operand-count | encoded-length
```

`direction` is zero for forward code and one for inverse code. Operands remain in the immutable artifact range until relocation publishes an owned value. The decoder requires contiguous canonical code and exact type-section consumption.

## Relocation order

The linker shall process a module only after all direct dependency products exist:

1. validate and decode the source-local artifact.
2. bind local function IDs to stable signature identities.
3. resolve imported call sites in dependent-header rank.
4. resolve aggregate descriptor references through WIP-0046 products.
5. verify owner moves, loans, and result slots.
6. assign final function and type IDs in canonical order.
7. rewrite operands into owned code bytes.
8. emit sections, directory entries, alignment, and padding canonically.
9. verify the complete result and publish its identity.

A failure before step 9 cannot publish a linked artifact.

## Bounds

The first implementation keeps the existing recovery bounds:

- 64 source-local functions per module.
- 64 parameters per function.
- 256 locals per function product.
- 4,096 source-local instructions per module.
- 512 local modules and 64 direct imports.
- 16 MiB canonical artifact input.

Closure-wide function and instruction storage shall use counted append windows. It shall not reserve 512 complete artifacts.

## Recovery consequences

Callable bytecode products do not set a bootstrap bit. Promotion still requires the complete physical compiler closure, byte-identical stage 2, diverse double compilation, and provenance evidence. No `wheeler.bootstrap.yaml` may be checked in before those facts exist.

## Implementation status

- [x] WIP-0045 compiles one callable and one complete source-local callable module to canonical `.wbc`.
- [x] `CompiledFunctionProducts.w` validates canonical directories, function descriptors, type windows, contiguous code, and instruction framing.
- [x] Unknown opcodes and noncontiguous function code trap before publication.
- [x] Native function, instruction, and maximum-local counts match independent Java program objects.
- [x] `FunctionProductIdentities.w` binds signature, ordered direct dependencies, aggregate product, ownership product, exact local types, forward code, inverse code, flags, parameters, and locals under `wheeler-callable-body-product-1`. An independent Java digest matches.
- [x] `LocalCallRelocations.w` resolves every source-local call and uncall operand to a validated function and copies its stable signature identity. Unknown local targets publish no relocations or body identity.
- [x] `ImportedCallRelocations.w` distinguishes cross-module calls in a linked product, requires a public target, and copies its stable signature identity. Private targets publish nothing.
- [x] `RelocationIdentities.w` canonicalizes each function's ordered local and imported targets. Callable body identities bind that relocation identity. Inconsistent tables publish nothing.
- [x] `SourceCallProducts.w` resolves bounded unqualified imported names and arities before linking. Local products shadow imports, and equal imported name/arity products remain ambiguous.
- [x] Exact pre-link matches require ordered parameter types and loan modes, result type, and effect product equality. Equal exact candidates remain ambiguous.
- [x] Qualified pre-link calls bind the written dependency rank before exact signature matching. Packed views resolve exact local and locked external products without dependency source.
- [x] `AggregateOperandRelocations.w` resolves record, fixed-array, slice, and variant construction operands to unique WIP-0046 rows and copies the aggregate module-product identity.
- [x] `AggregateCodegen.w` emits all canonical aggregate construction and projection instruction forms after complete operand and extent validation. `AggregateInstructionProducts.w` lowers a counted semantic operation window through those forms only after validating every opcode, operand, and output extent. Record construction and field projection match stage 0 byte for byte.
- [x] `CompiledCallableBodies.w` compiles either counted callable ranges or a complete primitive local class against imported signature products by rewriting resolved call ranges to deterministic, collision-free, self-recursive stubs. Calls type-check from source-independent primitive type, loan, effect, and parameter-window products. Stub generation accepts no dependency-source argument. `retainLocalFunctionProduct` validates the instruction prefix and excludes both stub and synthetic entry suffixes before counted body publication.
- [x] `CompiledBodyArchive.w` copies validated source-local artifacts into a bounded 16 MiB closure archive and publishes stable artifact ranks. Duplicate module owners fail before copying.
- [x] `CountedFunctionProducts.w` appends one validated artifact at a time, rebases instruction owners, preserves artifact ranks, and rejects duplicate module owners before publication.
- [x] `LinkedInstructionCode.w` emits closure-ordered instruction bytes and rebases local call targets by the owning module's final function base.
- [x] WIP-0048 emits complete canonical multi-module `.wbc` fixtures byte for byte, including mixed-owner calls, aggregates, globals, proofs, and reversible result slots.
- [ ] WIP-0049 compiles every physical source-local body and excludes all compile-time scaffolding.
- [ ] The complete physical compiler closure compiles from semantic products.

## Rejected alternatives

**Keep whole Java `Program` objects.** Java remains replaceable stage 0 and cannot own recovery products.

**Patch arbitrary byte offsets.** Canonical code, descriptor, type, section, and alignment changes must be emitted as one verified artifact.

**Treat unknown opcodes as opaque.** Executable unknowns fail. Extension semantics require the explicit WIP-0038 registry.

**Compile all dependency bodies as source again.** That is source flattening even when performed one helper at a time.
