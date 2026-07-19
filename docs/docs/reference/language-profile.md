# Wheeler source language profile

Wheeler uses familiar classes, fields, methods, calls, assignments, and blocks. It adds explicit rules for reversibility and quantum resources.

Accepted source lowers to one typed `.wbc` IR. That IR keeps function inverses, logged rewind, effect barriers, coherent permutations, unitary adjoints, measurements, and workflow transitions separate.

The source profile grows only after a feature has parser, verifier, runtime, negative, editor-grammar, and end-to-end tests.

Whitespace and line breaks do not change meaning. Simple statements end with semicolons; Wheeler supports both `//` and `/* ... */` comments.

## Classes and state

A source file contains one computation-domain class:

```java
classical class Counter {
  state long count = 0;
}
```

The available domains are `classical`, `quantum`, and `hybrid`. Format 1.0 supports signed 64-bit classical state and affine logical quantum registers:

```java
state long measured = 0;
qreg q = new qreg(3);
```

Raw provider qubits are never Wheeler source values.

## Methods

```java
long add(long left, long right) { return left + right; }
void helper() { ... }
rev void increment() { ... }
coherent rev void flip() { ... }
unitary void qft() { ... }
test void startsAtZero() { assert(count == 0); }
test void signed(long value) cases(-1, 0, 1) { ... }
entry void main() { ... }
```

A normal classical method may take supported scalar, aggregate, slice, owner, or loan parameters. It returns a supported value or `void`.

A `rev` method gets a compiler-checked inverse. A `coherent rev` method must also fit the exact finite subset that can become a unitary operation. A `unitary` method lowers to provider-neutral quantum region IR and gets a generated adjoint.

A `test` method is a classical `void` method. It has no parameters, or one `long` or `boolean` parameter.

A parameterized test must include an inline `cases(...)` list with 1 through 1,024 unique values of the right type. There is no hidden generator or ambient random seed.

When a runnable target has the package `test` selector, each nonmodular test or root-module test compiles into its own verified entry artifact. Tests run in fresh VMs and in lexical qualified-name order. Normal build and run artifacts omit test methods.

Exactly one `entry` method defines ordinary execution. It may borrow an optional `utf8` input followed by an optional mutable `bytes` output.

`public`, `private`, `protected`, and `static` are accepted where they make sense. Normal classical methods support signed and Boolean parameters, return values, local bindings, and bounded control flow.

For now, `rev`, `coherent rev`, and `unitary` methods take no arguments and return `void`. Their parameter ownership and inverse-signature rules are still being built.

## Classical statements

| Source | Meaning |
| --- | --- |
| `count += 1;` | Checked signed addition; inverse is subtraction. |
| `count -= 1;` | Checked signed subtraction; inverse is addition. |
| `bit ^= 1;` | Bitwise XOR; self-inverse and coherently eligible. |
| `count = 7;` | Logged overwrite; rejected from generated-inverse methods. |
| `increment();` | Invoke a forward method or unitary region. |
| `reverse increment();` | Invoke a method inverse or unitary adjoint. |
| `assert(count == 2);` | Trap before mutation when unequal. |
| `checkpoint();` | Add a reversible checkpoint marker. |
| `commit();` | Advance the local rewind horizon. |

`assert(condition);` is the only direct assertion form. Classical entries, normal methods, and tests accept the current Boolean expression profile.

The condition is evaluated once. The result lowers to checked `EXPECT_TRUE`. Direct equality between a signed global and a literal keeps the smaller `EXPECT_EQ` form.

A false assertion traps before any later mutation. Current quantum and hybrid entries support only the compact global-and-literal equality form.

Wheeler does not define `assertTrue`, `assertFalse`, `assertEquals`, `expectEqual`, matcher objects, or bare `assert condition;` aliases. Typed reversible, quantum, workflow, and proof assertions remain work for WIP-0021 and WIP-0018.

A reverse block calls supported inverses in reverse source order:

```java
reverse {
  first();
  second();
}
```

This runs `reverse second();` and then `reverse first();`.

## Local expressions and bounded control

Normal classical methods support `long` and `boolean` locals. Expressions include checked `*`, `/`, `%`, `+`, and `-`; signed or Boolean `^`; Boolean `!`; `<`; and `==`.

Multiplication binds before addition and subtraction. Logical negation binds before multiplication and associates to the right.

Arithmetic and ordering require signed operands. Addition, subtraction, and multiplication trap before changing the destination when signed 64-bit overflow would occur.

Division truncates toward zero, and remainder follows that quotient. A zero divisor traps. `Long.MIN_VALUE / -1` also traps before any write.

Equality requires both operands to have the same type and returns a Boolean; XOR accepts either two signed values or two Booleans, then preserves that type. Logical `!` accepts only Boolean input and evaluates it once.

Conditions must be Boolean. Integer values are never treated as true or false.

```java
long i = 0;
while (i < 5) limit 5 {
  sum += i;
  i += 1;
}

boolean complete = sum == 10;
if (complete) {
  branch = 1;
} else {
  branch = 2;
}
```

A counted loop uses the same required bound:

```java
for (long i = 0; i < 5; i += 1) limit 5 {
  sum += i;
}
```

The initializer runs once, and the limit is evaluated once. Wheeler checks that limit before each body iteration. It traps before an iteration that would exceed the bound.

In a `while`, `continue;` goes back to the condition. In a `for`, it runs the update first and then checks the condition again. It cannot skip the next bound check.

`break;` exits the nearest bounded loop. Both `break` and `continue` are invalid outside a loop. Nested loops keep separate targets and counters. The whole-program step limit remains an independent safeguard.

Calls evaluate arguments from left to right and move them through one verified, contiguous type window.

A plain affine-owner parameter consumes its argument. `borrow T` creates a shared nonescaping loan, while `borrow mut T` creates an exclusive nonescaping loan. Definite-ownership flow rejects later use of an owner passed to an owning call.

A value call writes one exact declared result into a caller register. A `void` call may use the same value, owner, and loan parameter types without creating or dropping a result register.

A value-returning method may return early from a branch. Every reachable path must still end with `return expression;` of the declared type.

Static recursion is allowed under the VM limit of 1,024 frames and the program step limit.

Local control lowers to typed frame registers and explicit branch targets; each function descriptor stores one canonical type code for every register.

The verifier rejects unknown type codes, bad targets, invalid local indexes, reads without definite assignment, type mismatches, non-Boolean conditions, invalid Boolean constants, and functions that fall through without returning.

Control flow is not yet allowed in `rev` or `coherent rev` methods. Reversible branches and loops will need exact branch or iteration witnesses. Wheeler does not create hidden history for them.

## Compile-time constants and finite enums

A scalar constant is evaluated during parsing and lowering; it adds no global, initializer function, or runtime lookup:

```java
const long BASE = 0x0200;
public const long OPCODE_CALL = BASE;
const boolean ENABLED = OPCODE_CALL == 512;
```

The current profile supports `long` and `boolean`, parentheses, checked numeric negation and arithmetic, Boolean `!`, `^`, `&`, `==`, `<`, and checked `rotateRight32`.

A constant may refer to another same-module constant regardless of declaration order. It may also use a directly imported public constant or canonical `module::NAME` qualification.

Arithmetic follows VM trap rules. The compiler evaluates the bounded dependency graph in canonical name order. A cycle reports its complete canonical path. Reordering independent constants does not change semantic `.wbc`.

Constant expressions may appear in scalar constants, signed state initializers, qreg sizes, static theorem step bounds, and normal local expressions. Private, missing, ambiguous, duplicate, effectful, or type-mismatched references fail before artifact output.

A finite enum is canonical shorthand for a payload-free tagged variant:

```java
public enum Direction {
  case Left;
  case Right;
}

Direction direction = new Direction.Right();
match (direction) {
  case Direction.Left() { selected = 1; }
  case Direction.Right() { selected = 2; }
}
```

Construction, nominal equality, exhaustive matching, artifact metadata, VM values, and rewind use the existing variant path.

Enum cases have no integer ordinal or wire value. The compiler sorts cases by name for semantic output, so source reordering does not change `.wbc`.

Protocol numbers belong in named constants and explicit encode or decode functions. Quantum basis identity and reversible finite permutations remain planned WIP-0017 work.

## Value records

A nominal record declares one or more ordered immutable fields:

```java
record Span(long start, long end) {}
record Token(Span span, boolean valid) {}

Token token = new Token(new Span(3, 8), true);
long width = token.span.end - token.span.start;
```

A record name begins with an ASCII upper-case letter. This keeps nominal declarations distinct from statements during standalone module parsing.

A field may use a scalar or a record declared earlier in the file. That rule makes recursive and cyclic inline records impossible.

Construction runs from left to right and checks exact arity and field types. Fields are read-only. Records may be locals, parameters, and results. `==` compares nominal type and every immutable field value.

The VM interns equal records in deterministic construction order. Handles are verified implementation values, not source integers or artifact identity.

Rewind removes values created by the rewound step, and snapshots include the record table. One machine may hold at most 65,535 distinct record values.

## Tagged variants

A variant declares a closed, ordered set of cases. Each case may have zero or more typed payload fields:

```java
variant Option {
  case None();
  case Some(long value);
}

Option option = new Option.Some(9);
match (option) {
  case Option.None() { result = 0; }
  case Option.Some(long value) { result = value; }
}
```

Payload types must already exist, so recursive inline layouts are impossible. Construction checks the nominal type, case, arity, and payload types.

Every arm in a `match` must name the same variant type. The compiler rejects duplicate or unknown cases, checks binding types, and requires the full case set.

The final arm needs no fallback because verified values can carry only declared tags. Case bindings become typed locals in that arm.

Variants may be parameters and results. `==` uses nominal structural equality.

The VM interns variants in their own table with a 65,535-value limit. Snapshots and rewind include that table. A payload read with the wrong expected tag traps before mutation.

## Fixed arrays

A fixed array owns an immutable, homogeneous sequence. Its length is part of the type:

```java
long[4] values = new long[4](2, 4, 6, 8);
long selected = values[2];
```

Construction requires exactly the declared number of values and checks each type from left to right. Arrays may be locals, parameters, and results.

An index is a signed value. A negative index or one at least as large as the array length traps before mutation.

`==` compares the complete typed value. Array lengths range from 1 through 65,535. Nested array syntax and mutation are outside this slice.

An immutable borrowed slice uses `T[]` and an explicit checked constructor:

```java
long[] middle = slice(values, 1, 2);
long selected = middle[1];
```

The slice keeps its array origin plus a start and length. Invalid, negative, or overflowing ranges fail before allocation. No elements are copied.

Slice indexing is relative and checked. Slices may be locals and parameters, but they cannot be function results or aggregate fields. This prevents the loan from escaping its owner.

Mutable slices, split and join, and overlapping-loan analysis remain future work.

Equal arrays and slices are interned in deterministic order under separate 65,535-value limits. Their handles remain unobservable and type-specific; snapshots and rewind include both tables.

## Bounded owned regions

The current dynamic-storage slice has function-local `region` owners plus mutable signed-word and byte buffers:

```java
region arena = new region(32, 2);
words data = allocate(arena, 4);
set(data, 0, 7);
long first = data[0];

bytes raw = allocateBytes(arena, 4);
setByte(raw, 0, 255);
long firstByte = raw[0];

drop(raw);
drop(data);
drop(arena);
```

`writeAscii(raw, offset, "WHEELBC")` is a bootstrap encoding statement. The literal may contain at most 4,096 printable ASCII characters and has no escape syntax. It is not a first-class string.

The compiler expands the statement into checked byte writes starting at the signed offset; a failed run publishes no external output, and VM rewind restores each expanded write.

A region declares hard byte and live-object limits. The VM also caps total live region storage at 16 MiB.

A `words` element costs eight bytes. A `bytes` element costs one byte, and `setByte` accepts values from 0 through 255. Both allocation forms start with zero-filled storage.

Allocation and access trap before mutation on invalid length, exhausted bytes or objects, bad handles, the wrong storage kind, invalid byte values, dropped owners, or an out-of-range index.

Buffers must be dropped before their region. Dropping a buffer returns its byte and object charge and releases visible content. Rewind data keeps only what is needed until commit.

`bufferLength(buffer)` returns a fixed element count without consuming the value. `utf8Valid(buffer)` performs strict RFC 3629 validation over the whole byte buffer.

`utf8Count(buffer)` returns the number of Unicode scalar values. It traps before writing a result when the encoding is malformed.

`utf8Scalar(buffer, index)` and `utf8Width(buffer, index)` decode one scalar at an exact leading-byte position. A continuation byte, truncation, malformed sequence, or invalid index traps first.

The decoder rejects overlong encodings, surrogate values, code points above U+10FFFF, stray continuations, invalid leaders, and truncated input. An empty buffer is valid and has zero scalars. These operations do not normalize text or count grapheme clusters.

`freezeUtf8(raw)` validates and consumes a `bytes` owner. It returns an affine immutable `utf8` owner over the same charged allocation.

If validation fails, the byte owner remains live and unchanged. A frozen value supports byte length, scalar count, scalar-boundary decoding, validation, and drop. It does not allow byte mutation or unchecked string indexing.

This type is the bootstrap layer below a future library `String`. It does not provide normalization, concatenation, comparison, grapheme handling, or canonical text serialization.

An explicit `borrow utf8` parameter is an immutable synchronous loan:

```java
long scalarAt(borrow utf8 text, long index) {
  return utf8Scalar(text, index);
}
```

The caller keeps ownership and must later drop the value. The callee may inspect or reborrow it. The callee cannot move, drop, return, aggregate, or mutate the value.

Bytecode uses a separate register type for these loans. Call lowering creates only temporary loan windows.

A plain `utf8` parameter transfers ownership instead; the callee must consume or return it. The same rule applies to each primitive owner type.

Runtime owner and kind checks defend against malformed artifacts. Verifier rules stop valid bytecode from turning a loan into an owner.

`borrow byteview` is the immutable binary form for an entry or normal parameter. It provides checked byte indexing and `bufferLength` only.

A `byteview` performs no UTF-8 validation and accepts any byte sequence, including empty input. It cannot be written, dropped, returned, or stored inside an aggregate.

Passing mutable bytes to that parameter creates a temporary read-only view. It does not grant another writer.

An entry may declare `borrow utf8` or `borrow byteview`, but never both. An optional `borrow mut bytes` output may follow. The embedding API chooses the input kind directly instead of guessing from the byte content. For example, the invalid UTF-8 bytes `0xc0 0x80` remain binary input instead of becoming a protocol guess.

`crypto/Sha256.w` implements bounded SHA-256 in Wheeler. It uses a `byteview`, a caller-owned 32-byte output loan, and a scratch region with 1,088 bytes and three objects.

Its unsigned 32-bit state stays in nonnegative `long` values. Additions reduce modulo 2³², while checked signed `&` and `rotateRight32(value, amount)` operate on normalized words.

No host or provider digest API enters artifact semantics. The current loop limit permits up to 4,096 padded blocks, though normal step and history limits may set a smaller practical bound. This is a deterministic identity primitive, not a side-channel claim.

A `borrow mut region` parameter is a synchronous exclusive allocation loan. The callee may allocate buffers or maps under the caller's existing limits, then use or reborrow them.

Every allocation made through the loan must be dropped before return. The callee cannot drop or return the region itself. This gives compiler helpers bounded scratch storage without transferring ownership.

`borrow mut words` and `borrow mut bytes` are synchronous exclusive mutable loans. They allow checked reads, writes, and length queries. Byte loans also support strict UTF-8 inspection.

Loans may be nested through calls. One owner cannot fill two mutable parameters in the same call. A loan cannot be moved, dropped, returned, frozen into an owner, or stored in a value.

`borrow bytes` is the shared read-only form. It lowers to the same immutable binary view as `borrow byteview`.

A region may also own one fixed-capacity signed map:

```java
longmap symbols = allocateMap(arena, 16);
put(symbols, 7, 11);
boolean present = mapHas(symbols, 7);
long value = mapGet(symbols, 7);
```

`longmap` accepts every signed key, including zero. `put` inserts or updates in deterministic lowest-free-slot order.

Capacity is charged at 24 bytes per slot when allocated. `mapHas` is total. `mapGet` traps before changing its destination when the key is absent.

The first slice has no deletion or iteration. Insertion history stays inside VM state, and no canonical map value encoding exists yet.

A `borrow mut longmap` parameter is a synchronous exclusive mutable loan. The callee may update, query, and reborrow the map in nested calls.

The caller keeps ownership but does not execute while the callee frame is active. Compiler and bytecode checks reject one map passed to two mutable parameters in the same call.

A map loan cannot be moved, dropped, returned, or stored in an aggregate.

A normal function may return one `region`, `words`, `bytes`, `utf8`, or `longmap` owner; `return` consumes that local and requires every other callee owner to be dead.

A returned region must therefore be empty. Other returned storage must remain charged to a live caller region reached through a nonescaping region loan.

Returning a buffer while leaking a callee-owned region fails ownership flow. Borrowed values, slices, and `byteview` results remain invalid because a raw handle does not prove a safe lifetime.

`region`, `words`, `bytes`, `utf8`, and `longmap` locals are affine owners. Binding, passing to an owning parameter, or returning one moves the handle and invalidates its source. Normal copy and equality are not allowed.

An explicit `borrow` or `borrow mut` parameter receives only a checked, nonescaping loan. Owners may be function parameters and results, but they cannot yet appear in aggregates, arrays, or slices.

Definite-ownership flow rejects use after move, drop, or owning call. It also rejects overwriting a live owner, joining branches with different ownership state, and leaving any owned local live at function exit.

An owning callee must drop, move onward, or return its parameter; runtime dropped-state and owner checks remain a second line of defense.

Snapshots expose canonical region and buffer state. Rewind restores allocation, mutation, parameter and result ownership, loan windows, moves, and drops exactly.

This slice supports bounded storage factories, owner transfer through calls, owner return, final-caller use, and explicit drop; it also covers scratch-region loans, exclusive buffer mutation, strict UTF-8 freezing and decoding, and signed symbol maps.

It is not yet a full compiler arena. Library strings and normalization remain WIP-0012 work. WIP-0028 owns public loan origins, non-lexical loans, split and join, recoverable allocation, and commit-aware reclamation over the WIP-0013 machine substrate. WIP-0029 adds generic collections, while WIP-0030 adds their coherent static protocol evidence.

## Generated inverse and adjoint theorems

The first proof slice accepts four closed theorem forms:

```java
theorem incrementInverse proves inverse(increment);
theorem qftAdjoint proves adjoint(qft);
theorem normalized proves equivalent(sourceCircuit, normalizedCircuit);
theorem addBound proves steps(add, 4);
```

The compiler resolves each subject and emits a canonical rule certificate tied to the function or circuit ID.

`GENERATED_INVERSE` requires a `rev` function. The trusted `ProofKernel` rebuilds its expected inverse from the forward opcodes.

`GENERATED_ADJOINT` requires a `unitary` circuit. The kernel reverses operation order, inverts each semantic gate or coherent call, and checks that a second adjoint returns the exact original body.

`CIRCUIT_EQUIVALENCE` requires two circuits on the same register. It checks equality after deterministic cancellation of adjacent inverse operations.

`STATIC_STEP_BOUND` requires a straight-line function with no calls or branches. The full forward instruction count must fit both the positive theorem bound and the program limit.

Unknown subjects, unsupported operations, noncanonical IDs, unknown rules, changed inverse bodies, and malformed metadata reject the artifact before execution.

These certificates are formal structural evidence. They are different from an executable round-trip test.

The rules prove exact compiler generation, one named cancellation rewrite, and static instruction bounds for the accepted subsets. They do not prove matrix-level equivalence for arbitrary circuit rewrites or global phase.

General propositions, contracts, proof terms, resource certificates, assumptions, and experiments remain WIP-0011 work.

## Quantum statements

Unitary methods use familiar gate calls over indexed registers:

```java
unitary void bell() {
  H(q[0]);
  CNOT(q[0], q[1]);
}
```

The current semantic gates are `H`, `X`, `Z`, `Phase`, `CPhase`, `CNOT`, `CZ`, and `Swap`; a target adapter may decompose these gates, but it cannot change their ideal meaning.

Preparation and measurement are explicit:

```java
prepare(q, 0);
bell();
measured = measure(q);
```

Measurement creates a classical observation. It cannot be hidden inside a `pure`, `rev`, or `unitary` method.

## Coherent lifting

The first coherent subset supports finite XOR permutations. One checked method may run over classical state and also be referenced from a quantum register:

```java
coherent rev void flip() {
  bit ^= 1;
}

unitary void oracle() {
  q.apply(flip);
}
```

The compiler rejects checked arithmetic, logged writes, measurement, I/O, and other nonunitary operations from this subset. Broader exact finite arithmetic will need explicit width rules.

## Distinct meanings of reverse

- `reverse method();` runs a verified inverse or adjoint as new work.
- VM rewind consumes earlier classical step records.
- Uncomputation returns temporary coherent state to its required clean value.
- Replay uses recorded observations again.
- Retry prepares fresh state and performs a new target run.

These operations are related, but one cannot replace another.

## Classical source modules

The stage-0 compiler has an exact multi-source entry point for the first self-hosting module slice:

```java
module bootstrap.arithmetic;
classical class Arithmetic {
  public long twice(long value) { return value + value; }
}
```

A root lists imports before its class:

```java
module bootstrap.main;
import bootstrap.arithmetic;
classical class Main {
  state long result = 0;
  entry void main() { result = twice(9); }
}
```

`compileModules(sources, root)` receives the complete named source map. Every key must match the source `module` declaration. Module names use dotted ASCII identifiers, and imports must be unique and sorted.

Resolution requires a closed acyclic graph. It rejects missing or unreachable inputs and processes dependencies before importers.

The graph may contain at most 1,024 modules, with no more than 64 MiB of combined UTF-8 source. Map iteration order cannot change `.wbc` output.

The root declares exactly one entry and may use its private records and closed variants. A dependency has no entry. In this slice, dependencies may contain functions, immutable records, closed variants, and fixed-array or slice descriptors.

Public functions, records, closed variants, and supported fixed-array or slice signatures are visible to direct importers. Imported variants may be constructed and matched exhaustively by the importer.

An unqualified name first checks the same module. It may then resolve one unambiguous public declaration from a direct import.

`example.math::twice(value)` names a public function. `example.math::Pair` names a public value type from an exact direct import.

Qualified nominal types work in locals, signatures, constructors, matches, arrays, and slices. Qualification does not grant transitive or private access.

When short names collide, callers must use full module names. Private helpers and types remain available inside their own module, but a public function, record, or variant cannot expose a private type in its API.

The linker assigns collision-free internal function and type names before normal type checking and bytecode lowering.

Nonpublic references, ambiguous exports, import cycles, unsorted imports, quantum dependency domains, dependency state or proofs, and implicit transitive access all fail closed.

Single-source `compile` rejects module declarations. A modular `wheeler.package.yaml` target lists its exact sorted source set and root module.

Local, workspace, planned, archived, and locked offline builds use the same linker. Imports do not come from file paths.

Direct locked cross-package modules link through exact archive identities and package visibility. Stateful modules, circuits, and proofs do not yet cross that boundary. WIP-0007 and WIP-0009 own those additions.

## Explicit host input and output

A classical entry may request immutable input and mutable output loans:

```java
entry void main(borrow utf8 source, borrow mut bytes output) {
  scalarCount = utf8Count(source);
  setByte(output, 0, 79);
  setByte(output, 1, 75);
}
```

Input-only and output-only entries are valid. When both are present, input comes first.

The entry signature becomes part of canonical bytecode. It does not read a file, environment variable, standard input stream, package resource, or network endpoint by itself.

The embedding API provides exact bytes when it creates the VM or calls `WheelerRuntime`. `wheeler run ... --input <path>` is a small host adapter for one explicit, physical, nonsymlink file.

`--output <path> --output-bytes <count>` supplies one bounded, zero-filled external byte owner. By default, successful execution publishes the full capacity. `setOutputLength(output, used)` selects a checked prefix after the program sizes and writes its result.

Publication is atomic and happens only after success. Each side is capped at 16 MiB. Text input is checked as strict UTF-8 before execution.

Missing, extra, malformed, oversized, nonregular, linked, or incomplete effects fail before the first instruction or before output replacement.

The VM installs both effects as external baseline storage and gives the entry only verified loans. Wheeler code cannot move or drop those external owners.

The owners remain part of the rewind baseline, and `ExecutionResult` returns a defensive copy of output bytes. Output-length changes are rewindable and cannot exceed capacity.

These effects are classical, bounded, and supplied by the caller. General path values, streaming, named effects, and package-resource binding remain future work.

## Parser and editor tooling

The compiler lexer records line, column, and stage-0 UTF-16 source-character offset. The Wheeler scanner slice also records byte ranges and stable errors with a code, byte offset, and one-based line and column.

Codes 1, 2, and 3 mean an unterminated block comment, malformed raw-ASCII literal, and exhausted token capacity.

Identifiers use ASCII letters, digits, and underscore. Unicode remains valid in comments but not in names.

Input is capped at 64 MiB and 16 million source characters. One token may contain at most 4,096 characters. Token and line counts each stop at 1,000,000, declarations at 65,535, and block nesting at 256.

The parser does not depend on formatting. It rejects unsupported syntax instead of dropping unknown nodes.

`tree-sitter-wheeler` provides an incremental grammar, corpus, highlighting, and fold queries for `.w` files. Its concrete syntax tree does not perform type checking. The compiler resolves method and gate meaning.

## Bootstrap direction

Java is stage-0 infrastructure for the current compiler and VM. The production compiler will be Wheeler source and must compile itself into a byte-identical second-stage `.wbc` artifact.

The current bootstrap base includes signed and Boolean values, immutable records and variants, arrays and slices, typed calls and control, deterministic classical module linking, bounded regions, transferred or returned primitive owners, and explicit nonescaping loans.

Library strings, generic deterministic collections, public returned loans, richer modules, cross-package modules, streaming, and multiple file effects still need complete vertical slices.

After native runtime conformance, the project plans to remove the Java compiler, VM, tools, Gradle build, and JVM deployment path. A cold build will use a content-addressed earlier native Wheeler release and `.wbc` recovery seed.

Java APIs and object behavior are not future Wheeler contracts.

See [WIP-0007](../proposals/WIP-0007-self-hosting-compiler-and-bootstrap.md), [WIP-0008](../proposals/WIP-0008-java-free-runtime-and-native-bootstrap.md), and [WIP-0009](../proposals/WIP-0009-wheeler-package-and-build-system.md).

## Proof direction

Proofs will use Wheeler syntax and semantics. Contracts attach to executable declarations. Theorems and experiments resolve through normal modules, and structured proof blocks lower to canonical terms checked by a small trusted kernel.

Formal theorem evidence stays separate from simulator tests and sampled hardware results.

`QFTProof.w` is currently an executable inverse law, not a formal theorem; `Counter.w`, `QFT.w`, and `QuantumCompiler.w` carry the first finite-rule certificates.

General proposition terms, contracts, matrix-level quantum proofs, resource claims, and tool contracts remain specified work in [WIP-0011](../proposals/WIP-0011-integrated-proofs-and-certificates.md).

## Standard library direction

The Wheeler-written standard library will provide allocation-free core values and owned deterministic collections. It will include bytes, UTF-8, explicit host capabilities, and reversible data structures with exact inverse contracts. Quantum support will cover affine logical qubits and registers, circuits, observables, and target jobs. The library will also include proof support and test tools.

[WIP-0012](../proposals/WIP-0012-wheeler-standard-library.md) defines its package layers and ownership rules.

## Generic and ownership direction

The current profile has concrete nominal aggregates, fixed arrays and slices, primitive storage owners that can move or return, and a narrow set of explicit region and storage loans.

It has no generic declarations, type classes, associated types, const-generic parameters, returned loans, closures, effect variables, or runtime class dispatch.

[WIP-0028](../proposals/WIP-0028-deterministic-ownership-borrowing-and-regions.md) defines affine ownership, inferred local loans, public origins, deterministic destruction, and no required collector.

[WIP-0029](../proposals/WIP-0029-parametric-polymorphism-and-bounded-specialization.md) defines checked generics, kinds, bounded values, and deterministic specialization. [WIP-0030](../proposals/WIP-0030-coherent-type-classes-and-associated-types.md) adds coherent static classes and certified semantic evidence.

[WIP-0031](../proposals/WIP-0031-reversible-quantum-and-effect-polymorphism.md) defines closure ownership, effect rows, and distinct reversible, coherent, and unitary callable kinds.

Each feature must still lower to the same typed reversible `.wbc` IR; none is implemented yet unless the reference above describes its executable slice.

## Teaching path

1. `Counter.w`, `BinaryTree.w`, `BootstrapControl.w`, `FunctionValues.w`, and `RecursiveValue.w`: reversible state, fixed-capacity data, typed locals, bounded control, parameters, returns, static calls, and bounded recursion.
2. `RegionStorage.w`, `FrozenUtf8.w`, and `Utf8Lexer.w`: affine bounded storage, immutable UTF-8, strict decoding, and token-buffer scanning.
3. `CoherentOracle.w` and `QuantumNeuralNetwork.w`: exact XOR permutations over classical and coherent data.
4. `QFT.w` and `QFTProof.w`: unitary regions, generated adjoints, and executable inverse laws.
5. `QuantumOptimizer.w`: repeated target observations, classical acceptance, commit, and target-free replay.
6. `QuantumCompiler.w`: semantic comparison of source and normalized circuits.
7. `SurfaceCode.w`: a static correction kernel with an explicit dynamic-target boundary.

See [executable examples](../examples.md) for exact results and scope. Every checked-in example compiles, runs, and parses without Tree-sitter error nodes in the normal test gate.
