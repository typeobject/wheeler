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
| Superseded by | None |

## Summary

The native compiler shall link callable bodies from canonical bytecode products. Each source-local `.wbc` product is decoded into bounded function descriptors, local type windows, and instruction ranges. Calls and type references are then relocated against completed scalar, callable, and aggregate identities. Dependency source is neither retained nor flattened.

WIP-0045 owns source callable signatures and source-local compilation. WIP-0046 owns aggregate layouts and ownership products. This WIP owns the bytecode boundary between those products and the final linked `.wbc`.

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
- [ ] Imported call operands resolve privacy, ambiguity, arity, type, and effect rules.
- [ ] Aggregate descriptor operands relocate through WIP-0046 identities.
- [ ] Closure-wide function and instruction windows append one artifact at a time.
- [ ] The canonical linker emits a multi-module `.wbc` without dependency source.
- [ ] Linked local, imported, reversible, result-slot, aggregate, owner, and loan fixtures match stage 0 byte for byte.
- [ ] The complete physical compiler closure compiles from semantic products.

## Rejected alternatives

**Keep whole Java `Program` objects.** Java remains replaceable stage 0 and cannot own recovery products.

**Patch arbitrary byte offsets.** Canonical code, descriptor, type, section, and alignment changes must be emitted as one verified artifact.

**Treat unknown opcodes as opaque.** Executable unknowns fail. Extension semantics require the explicit WIP-0038 registry.

**Compile all dependency bodies as source again.** That is source flattening even when performed one helper at a time.
