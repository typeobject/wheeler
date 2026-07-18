# WIP-0013: Typed frames, control flow, and bounded storage

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler language, compiler, bytecode, verifier, VM, and library maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-17 |
| Area | Types, functions, locals, control flow, storage, bootstrap |
| Depends on | WIP-0001, WIP-0005, WIP-0007, WIP-0012 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler gains typed parameters, return values, local slots, expressions, bounded control flow, records, tagged variants, arrays, borrowed slices, and region-owned storage through a verified register-frame machine. This is the execution substrate for the self-hosted compiler and standard library.

Functions declare parameter, result, local-slot, effect, and reversibility metadata. Bytecode uses typed frame-local registers and explicit control-flow targets. The verifier constructs a control-flow graph, checks register types and definite assignment, validates calls and returns, proves stack and storage bounds, and rejects irreducible or unbounded forms outside an explicitly permitted profile.

Ordinary deterministic functions receive control flow first. A `rev` function may use a branch or loop only when Wheeler can generate and verify the inverse without guessing discarded control information. The initial reversible profile therefore keeps straight-line intrinsic operations and calls; later reversible conditionals and loops require protected predicates, loop witnesses, or explicit bounded history contracts.

Storage is owned and bounded. Fixed values live in frames or inline aggregates. Dynamic values live in regions or allocators passed through explicit capabilities. Raw host pointers, JVM objects, ambient garbage collection, and native object serialization are excluded.

## Motivation

A compiler cannot be written with zero-argument methods and global integers. It needs source-local values, function composition, loops over bounded input, syntax variants, diagnostics, byte buffers, maps, and phase-owned allocation. The package manager, proof kernel, native runtime, and application portfolio need the same substrate.

Adding parser syntax without bytecode and verifier ownership would recreate an unenforced language. Adding a generic heap without effects and bounds would make rewind, recovery, native lowering, and proof claims dependent on hidden runtime behavior. This WIP defines the complete vertical boundary.

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

Evaluation order is left to right. Traps and effects follow that order. Optimizers cannot reorder potentially trapping or effectful expressions without a checked equivalence.

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

Numeric opcode identities and operand forms are fixed only when the corresponding vertical slice is accepted. Variable-length signatures live in bounded metadata tables rather than ad hoc instruction payloads.

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

Static calls identify one function signature. Arguments are evaluated left to right, moved or borrowed according to type, and copied into callee parameter registers. A non-void return moves or copies into the declared caller destination.

Recursion requires a configured call-depth ceiling and a termination measure for proof or bootstrap profiles. Tail-call lowering is permitted only when traps, effects, source traces, and rewind semantics remain equivalent.

Inverse calls require an inverse body and compatible inverse signature. Coherent calls require a finite encoding and approved effects.

## Value records and variants

A record has ordered named fields and structural value semantics. A tagged variant has a stable tag and typed payload. Canonical type metadata stores field/tag names, types, visibility, ownership, and version identity.

Field order in source APIs is semantic for construction and canonical encoding but native layout is derived. Padding, address, and backend ABI do not enter equality.

Pattern selection is exhaustive. Unknown required tags in persisted or bytecode data fail closed. Extension records require an explicit versioning policy.

## Arrays and slices

Fixed arrays own inline or region-backed elements under one type and length. Borrowed slices carry origin, start, length, mutability, and lifetime identity. Index operations check bounds before access.

Mutable slices cannot overlap. Split operations establish disjointness; join validates common origin and adjacency. A slice cannot outlive or escape its owner or region.

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

A tracing collector is not required for the first bootstrap. If added, collection timing cannot be source-observable or alter canonical output, and finalizers are not implicit external effects.

## Exceptions and failure

Recoverable failures use `Result`. Optional values use `Option`. Assertions, arithmetic violations selected by operator semantics, verified unreachable states, and exhausted hard artifact limits may trap with stable codes.

Stack unwinding does not run arbitrary hidden user effects. Resource cleanup follows ownership and explicit scope rules. External compensation uses hybrid effect contracts rather than exception folklore.

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
- [x] Local constants, state load/store, move, arithmetic, comparison, branches, loop checks, value calls, and value returns execute and rewind.
- [ ] Typed signed/Boolean parameters, returns, local bindings, expressions, static calls, `if`/`else`, and bounded `while` compile end to end; `for` and aggregate types remain.
- [ ] Records, variants, arrays, and slices execute with ownership checks.
- [ ] Region storage supports compiler arenas under hard limits.
- [ ] Reversible protected control forms generate checked inverses.
- [ ] Lexer, parser, codec, verifier, and package graph fixtures run in Wheeler.
- [ ] Native execution traces match interpreted typed-frame traces.

## Testing and acceptance

- [ ] Bytecode rejects unknown register types, type-mismatched operands and calls, invalid Boolean constants and conditions, uninitialized reads, target escapes, bad joins, bad returns, and malformed loop descriptors; scalar types, local bounds, definite assignment, branch targets, and fallthrough are covered.
- [x] VM tests cover the initial signed-local instruction set forward and rewind, including loop and arithmetic traps before mutation.
- [ ] Calls cover exact signed/Boolean argument and result transfer, recursive execution, 1,024-frame exhaustion, and rewind; aggregate copy, move, borrow, inverse signatures, and nested trap behavior remain.
- [ ] Branch tests cover both paths, join assignment, early typed return, and source diagnostics; unreachable-block diagnostics remain.
- [x] Loop tests cover zero and exact bounds, exceeded bounds, innermost `break`, `continue`, nested loops, and the independent global step defense.
- [ ] Reversible methods reject unprotected branch/loop forms and accept only forms with checked inverse laws.
- [ ] Record and variant tests cover layout-independent equality, exhaustive selection, malformed tags, and canonical encoding.
- [ ] Array/slice tests cover boundaries, split/join, overlap, escape, move, and borrow lifetime.
- [ ] Region tests cover exhaustion, drop, escape, dangling borrow, canonical output independence, and commit.
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

- Which borrow representation keeps verification, native lowering, and proof terms small? — **Owner:** language, VM, and library maintainers — **Decide by:** before slice mutation
- Which reversible branch and loop witnesses should enter the first non-straight-line `rev` profile? — **Owner:** reversibility and proof maintainers — **Decide by:** after ordinary control flow executes

## References

- [WIP-0001](WIP-0001-reversible-bytecode-and-machine-state.md)
- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0010](WIP-0010-executable-application-portfolio.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
