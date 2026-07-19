# WIP-0013: Typed frames, control flow, and bounded storage

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler language, compiler, bytecode, verifier, VM, and library maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-18 |
| Area | Types, functions, locals, control flow, storage, bootstrap |
| Depends on | WIP-0001, WIP-0005, WIP-0007, WIP-0012 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler adds typed parameters, return values, local slots, expressions, bounded control flow, records, tagged variants, arrays, borrowed slices, and region-owned storage. These features run on a verified register-frame machine. That machine is the classical execution base for Wheeler's typed IR, self-hosted compiler, and standard library.

WIP-0028 later turns these concrete operations into public rules for affine owners, structural capabilities, non-lexical shared and exclusive loans, and regions. WIP-0029 applies those rules to generic types. Neither proposal replaces this bytecode and verifier layer.

Each function declares parameter, result, local-slot, effect, and reversibility metadata. Bytecode uses typed frame-local registers and explicit control-flow targets. The verifier builds a control-flow graph, checks register types and definite assignment, validates calls and returns, proves stack and storage limits, and rejects forms that are irreducible or unbounded outside an allowed profile.

Ordinary deterministic functions receive control flow first. A `rev` function may branch or loop only when Wheeler can generate and verify the inverse without guessing lost control data. The first reversible profile stays with straight-line intrinsic operations and calls. Later conditionals and loops need protected predicates, loop witnesses, or explicit bounded history.

Storage is owned and bounded. Fixed values live in frames or inline aggregates. Dynamic values live in regions or allocators passed through explicit capabilities. Raw host pointers, JVM objects, ambient garbage collection, and native object serialization are not allowed.

## Motivation

A compiler cannot work with zero-argument methods and global integers alone. It needs local values, function composition, bounded loops, syntax variants, diagnostics, byte buffers, maps, and phase-owned allocation. The package manager, proof kernel, native runtime, and application portfolio need the same base.

Parser syntax without matching bytecode and verifier rules would create an unenforced language. A general heap without effects and limits would make rewind, recovery, native lowering, and proof claims depend on hidden runtime behavior. This WIP defines the full vertical contract.

## Goals

- Add typed parameters, results, locals, expressions, and static calls.
- Use verified register frames with no untyped operand stack.
- Add `if`, exhaustive variant selection, bounded `while` and `for`, `break`, `continue`, and early return.
- Check control-flow target validity, type flow, definite assignment, call signatures, and return completeness before execution.
- Preserve exact VM rewind for local and control mutations above the commit horizon.
- Add value records, tagged variants, fixed arrays, and borrowed slices.
- Add region-owned bounded dynamic storage sufficient for compiler arenas and standard collections.
- Make allocation, drop, copy, move, borrow, trap, and external effects visible to type and effect checking.
- Keep canonical `.wbc`, disassembly, source maps, native lowering, and self-hosting deterministic.

## Non-goals

- Inherit JVM stack frames, object layout, exceptions, reflection, monitors, or garbage collection.
- Permit an unbounded source loop because the VM has a global emergency step limit.
- Make arbitrary control flow automatically reversible.
- Expose native addresses or allocator internals as source values.
- Stabilize general shared-memory concurrency in this profile.
- Add unrestricted dynamic dispatch before static calls and package interfaces are complete.

## Source profile

### Functions

Functions use familiar typed declarations:

```java
long tokenLength(Token token, long remaining) {
  long width = token.end - token.start;
  if (width > remaining) {
    return remaining;
  }

  return width;
}
```

Parameters and locals are immutable unless declared mutable by the accepted binding syntax. Return type `void` has no value. All other functions return on every reachable path.

Default arguments, varargs, reflection, implicit numeric narrowing, and ambient null are absent. Overload resolution uses declared static types and effects.

### Expressions

The first expression set includes literals, local and state references, calls, record construction, field access, variant construction and tests, array/slice indexing, checked arithmetic, bit operations, comparisons, Boolean operations, and explicit conversions.

Evaluation order is left to right; traps and effects follow that order; optimizers cannot reorder potentially trapping or effectful expressions without a checked equivalence.

### Conditionals

`if` evaluates one Boolean expression and executes one branch. The verifier joins local types and assignment state at the merge. A local read after the merge is valid only when every predecessor assigns a compatible value.

Exhaustive selection over tagged variants requires every case or a statically checked remainder. Case payload bindings have lexical scope.

### Loops

A loop carries a semantic bound:

```java
while (cursor.hasNext()) limit input.length + 1 {
  consume(cursor.next());
}
```

The limit is evaluated once from bounded values before entry and cannot increase during the loop. Exceeding it traps before another body iteration. A `for` over an array, slice, finite range, or deterministic collection inherits that value's bounded length when the compiler can prove it.

The artifact stores a verified loop descriptor or equivalent control metadata. The global VM step ceiling remains defense in depth, not the source loop contract.

### Reversible control

A reversible conditional must retain or reconstruct its branch decision without observing state destroyed by the chosen branch. Accepted forms require a protected predicate theorem, an explicit branch witness, or a logged-control contract.

A reversible loop requires a finite iteration witness and an inverse traversal law. The compiler rejects ordinary `if`, `while`, early return, allocation, and mutation from a `rev` body until the corresponding form is implemented and verified.

## Bytecode frame model

Each function descriptor declares:

- function identity and name;
- parameter count and types;
- optional result type;
- local register count and types;
- maximum call depth contribution;
- effects and reversibility flags;
- forward and optional inverse bodies;
- control-flow and loop descriptors.

A frame contains function, direction, program counter, typed register values, caller return destination, and region/borrow scope metadata. Frame values are semantic VM state and appear in snapshots and rewind records through canonical typed representations.

The register instruction families include:

- constants and moves;
- state/global load and checked/logged store;
- checked, modular, bitwise, comparison, and Boolean operations;
- record, variant, array, and slice construction/access;
- static call, inverse call, return value, and void return;
- conditional and unconditional branch;
- loop entry, back edge, and bound check;
- region allocation, move, borrow, drop, and canonical byte access;
- explicit assertion, trap, checkpoint, and commit.

Numeric opcode identities and operand forms are fixed only when the corresponding vertical slice is accepted. Variable-length signatures live in bounded metadata tables instead of ad hoc instruction payloads.

## Verification

The verifier performs:

1. structural decoding and table identity checks;
2. function-signature and register-table validation;
3. instruction operand and register bounds;
4. control-flow graph construction;
5. reachable-block and target validation;
6. definite assignment and type dataflow to a fixed point;
7. call, inverse-call, effect, and result compatibility;
8. return completeness and unreachable-result rejection;
9. loop shape and bound validation;
10. ownership, move, borrow, drop, region, and escape checks;
11. reversible-body and coherent-subset checks;
12. maximum frame, call, step, region, and artifact bounds.

Malformed control flow fails before VM construction. Native lowering consumes verified typed IR and does not repeat source inference.

## Rewind and inverse execution

A successful register instruction records the minimal prior local, state, frame, or control value needed for VM rewind. Rewind restores exact frame registers, program counter, call depth, ownership state, and machine status.

A function inverse remains new execution. Its generated inverse body uses language laws and contracts, not `StepRecord`. Local compiler temporaries that are absent from observable state still obey inverse generation and clean-workspace rules inside `rev` bodies.

Commit clears rewind records and advances the semantic horizon. Region reclamation after commit cannot be undone through stale bytes.

## Calls and recursion

Static calls identify one function signature. Arguments are evaluated left to right, moved or borrowed according to type, and copied into callee parameter registers. A non-void return moves or copies into the declared caller destination; a void argument call has no synthetic result register.

Recursion requires a configured call-depth ceiling and a termination measure for proof or bootstrap profiles; tail-call lowering is permitted only when traps, effects, source traces, and rewind semantics remain equivalent.

Inverse calls require an inverse body and compatible inverse signature. Coherent calls require a finite encoding and approved effects.

## Value records and variants

A record has ordered named fields and structural value semantics; a tagged variant has a stable tag and typed payload. Canonical type metadata stores field/tag names, types, visibility, ownership, and version identity.

Field order in source APIs is semantic for construction and canonical encoding but native layout is derived. Padding, address, and backend ABI do not enter equality.

Pattern selection is exhaustive. Unknown required tags in persisted or bytecode data fail closed. Extension records require an explicit versioning policy.

## Arrays and slices

Fixed arrays own inline or region-backed elements under one type and length. Borrowed slices carry origin, start, length, mutability, and lifetime identity. Index operations check bounds before access.

Mutable slices cannot overlap. Split operations establish disjointness; join validates common origin and adjacency; a slice cannot outlive or escape its owner or region.

Quantum register views use affine resource rules from WIP-0012 and are not represented as copyable classical slices.

## Regions and dynamic storage

A region is an owned bounded allocation domain. Its capability declares byte and object ceilings. Allocation returns a typed owned handle or `Result` failure. A region can be dropped only when no borrow or escaping owned value remains.

The initial compiler uses phase regions:

- source bytes;
- token stream;
- syntax tree;
- resolved semantic model;
- lowered artifact;
- diagnostics/output.

A phase may move selected immutable values into a longer-lived region. Reclaiming a region is an ordinary effect. Logged or transactional region APIs state retained history explicitly.

A tracing collector is absent from the bootstrap and ordinary source-value model. Any future explicit traced region requires a separate WIP under WIP-0028; collection timing cannot alter source semantics, diagnostics, limits, canonical output, finalization, or FFI stability, and user finalizers remain excluded.

## Exceptions and failure

Recoverable failures use `Result`; optional values use `Option`. Assertions, arithmetic violations selected by operator semantics, verified unreachable states, and exhausted hard artifact limits may trap with stable codes.

Stack unwinding does not run arbitrary hidden user effects. Resource cleanup follows ownership and explicit scope rules. External compensation uses explicit hybrid effect contracts.

## Determinism

Register numbering, block order, local type tables, diagnostics, region identities used in canonical output, and source maps are deterministic. Compiler hash tables and allocation addresses cannot alter artifacts.

Parallel compilation reduces diagnostics and declarations in canonical module/source order. Native optimization preserves specified evaluation, trap, effect, and result behavior.

## Bootstrap applications

This profile is accepted against Wheeler implementations of:

- UTF-8 lexer with token records and a bounded loop;
- recursive-descent parser with tagged syntax variants;
- deterministic symbol table and dependency graph;
- bytecode decoder with slices and `Result` diagnostics;
- canonical byte builder and artifact writer;
- proof-term checker over records and variants;
- package manifest parser and graph resolver.

A feature that cannot express or simplify one of these modules needs separate justification.

## I/O operation ownership

WIP-0032 operations hold WIP-0013 and WIP-0028 buffer loans until final resource-release completion. Live operations are must-consume values; a scope verifies that each operation is terminal and reaped before releasing its storage.

Registered and provided buffers remain bounded affine resources. Native queue entries, descriptors, addresses, and remote keys never become portable region addresses.

## Migration and deletion

1. Add function signature and typed local metadata while preserving canonical zero-local functions.
2. Add constant, move, arithmetic, comparison, branch, call-value, and return-value instructions.
3. Extend frames, snapshots, rewind records, disassembly, and verifier dataflow.
4. Add source parameters, results, locals, expressions, `if`, and bounded loops with Tree-sitter and negative tests.
5. Add records, variants, fixed arrays, and borrowed slices.
6. Add regions and owned dynamic values.
7. Port lexer, parser, bytecode codec, and verifier application fixtures.
8. Add reversible branch/loop forms only with exact inverse and proof contracts.
9. Add native lowering and cross-runtime trace parity.
10. Delete field-oriented workarounds, synthetic-global temporaries, permissive unbounded forms, and any duplicate AST/control-flow implementation.

## Progress

- [x] Stage-0 VM has explicit immutable call frames, checked calls, bounded steps, snapshots, and rewind records.
- [x] Source and bytecode distinguish state fields from function control.
- [x] Signed and Boolean parameter, local, and optional result signatures are canonically encoded and verified.
- [x] Register metadata uses bounded 32-bit scalar or aggregate references; canonical nominal record descriptors reject duplicate, forward, cyclic, and unresolved type IDs.
- [x] Local constants, state load/store, move, checked add/subtract/multiply/divide/remainder, comparison, branches, loop checks, value/void argument calls, and value returns execute and rewind.
- [x] Typed signed/Boolean parameters, returns, local bindings, expressions, static calls, `if`/`else`, and bounded `while` compile end to end.
- [x] Immutable nominal records, closed tagged variants, fixed immutable arrays, and nonescaping immutable slices execute with canonical descriptors, typed construction/calls, structural equality, exhaustive selection, checked ranges/indexing, snapshots, and rewind.
- [ ] Bounded regions now enforce byte/object ceilings, affine moves, leak-free exits, mutable signed-word/byte buffers, immutable validated UTF-8 owners with read-only parameter borrows, exclusive region scratch-allocation borrows, and word/byte/map mutable borrows. Primitive region, word, byte, UTF-8, and map owners may transfer into callees or return across frames; owner relays, caller-region factories, explicit drop order, use-after-call rejection, snapshots, and rewind are differential-tested. Returned loans, split/join borrowing, typed collections, recoverable allocation, capabilities, and compiler-scale arenas remain.
- [ ] Reversible protected control forms generate checked inverses.
- [ ] A bounded manifest-linked Wheeler scanner and parser now read explicit UTF-8 source input. The scanner writes identifier, number, punctuation, ASCII literal, and comment metadata into owned buffers. Signed-decimal overflow is checked. A dependency parser validates one typed local declaration through simultaneous exclusive borrows and returns a closed value-or-error result. The entry publishes the parsed token through a bounded output borrow with a checked rewindable length. A separate writer expands bounded ASCII literals into checked output for the canonical string table. Complete literals, diagnostics, parsing, codecs, verification, and package-graph fixtures remain.
- [ ] The Wheeler-written verifier and interpreter now compare bounded owned storage against stage 0. Coverage includes region, word-buffer, and byte-buffer allocation; mutation; lengths; reads; byte ranges; strict UTF-8 validation and decoding; freezing; and nested read-only UTF-8 borrows. It also covers mutable region, word, byte, and map borrows, owner-carrying parameters and results, signed-map operations, drop order, malformed index locals, and exact outer rewind. Returned loans and general native trace parity remain.

## Testing and acceptance

- [ ] Bytecode rejects unknown register types, mismatched operands or calls, invalid Boolean values, uninitialized reads, escaped targets, bad joins, bad returns, and malformed loop descriptors. Scalar types, local bounds, definite assignment, branch targets, and fallthrough are covered.
- [x] VM tests cover the initial signed-local instruction set forward and rewind, including loop and arithmetic traps before mutation.
- [ ] Calls cover exact signed/Boolean argument transfer, primitive owner parameters/results, recursive execution, 1,024-frame exhaustion, and rewind; returned loans, aggregate move/loan, inverse signatures, and nested trap behavior remain.
- [ ] Branch tests cover both paths, join assignment, early typed return, and source diagnostics; unreachable-block diagnostics remain.
- [x] `while` and counted `for` tests cover zero and exact bounds, exceeded bounds, update-on-continue, innermost `break`, nested loops, and the independent global step defense.
- [ ] Reversible methods reject unprotected branch/loop forms and accept only forms with checked inverse laws.
- [ ] Record and variant tests cover canonical encoding, nested fields and payloads, nominal structural equality, exhaustive selection, malformed descriptors, source type errors, deterministic interning, and rewind. A manifest-linked FIFO now returns immutable cursor records through explicit `Push`/`Pop` variants over a borrowed word buffer; native layout parity and generic queue ownership remain.
- [x] Fixed-array and immutable-slice tests cover typed construction, dynamic boundaries, calls, structural equality, canonical encoding, interning, nonescape, and rewind.
- [ ] Region tests cover word, byte, and map allocation and mutation. They also cover byte ranges, UTF-8 boundaries, borrow kind and aliasing, scratch cleanup, capacity failures, drop order, moved values, leaks, ownership joins, canonical encoding, snapshots, and rewind. Dangling borrows, output-address independence, recoverable failure, and commit remain.
- [ ] Stage-0 and Wheeler compilers produce identical typed metadata, code, diagnostics, and artifacts for the shared profile.
- [ ] The self-host compiler modules and package resolver run under declared frame, region, stack, and step ceilings.
- [ ] No source construct lowers to a synthetic global or unverified host object.

## Alternatives

### Use a JVM operand stack and object references

Rejected. It imports host verification, object, exception, and runtime assumptions and obstructs native and self-hosted semantics.

### Lower locals to hidden globals

Rejected. It breaks recursion, reentrancy, ownership, isolation, rewind scope, and canonical source semantics.

### Permit loops under only a global step limit

Rejected. It gives no local resource contract, weakens target planning and proofs, and turns ordinary bound mistakes into whole-program exhaustion.

### Add a general tracing heap first

Rejected. Compiler phase regions and owned aggregates are sufficient for bootstrap and provide a smaller deterministic runtime and proof surface.

### Record every branch automatically for reversible code

Rejected as the default. Hidden history changes effect and space semantics. Logged control may exist as an explicit type or contract.

## Open questions

- Which borrow representation keeps verification, native lowering, and proof terms small (owner: language, VM, and library maintainers; decision point: before slice mutation)?
- Which reversible branch and loop witnesses should enter the first non-straight-line `rev` profile (owner: reversibility and proof maintainers; decision point: after ordinary control flow executes)?

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
