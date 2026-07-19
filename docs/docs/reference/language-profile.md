# Wheeler source language profile

Wheeler uses familiar class, field, method, call, assignment, and block forms while giving reversibility and quantum resources explicit semantics. The profile grows only when a construct has parser, verifier, runtime, negative, editor-grammar, and end-to-end tests.

Whitespace and line breaks are not semantic. Simple statements end in semicolons. `//` and `/* ... */` comments are supported.

## Classes and state

A file contains one computation-domain class:

```java
classical class Counter {
    state long count = 0;
}
```

The available domains are `classical`, `quantum`, and `hybrid`. The first format supports signed 64-bit classical state and affine logical quantum registers:

```java
state long measured = 0;
qreg q = new qreg(3);
```

Raw provider qubits are never source values.

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

- A normal classical method may take supported scalar, aggregate, slice, or storage-borrow parameters and return a supported value or `void`.
- A `rev` method receives a compiler-validated inverse.
- A `coherent rev` method also satisfies the exact finite subset that can become a unitary operation.
- A `unitary` method lowers to backend-neutral quantum region IR and receives a generated adjoint.
- A `test` method is a classical `void` declaration with either no parameters or one `long` or `boolean` parameter. A parameter requires an inline `cases(...)` list of 1–1,024 unique type-correct scalar values; no hidden generator or ambient seed is involved. On a runnable target carrying the package `test` selector, each nonmodular declaration row or root-module declaration row compiles to its own verified entry artifact and runs in a fresh VM in lexical qualified-name order. Ordinary build and run artifacts omit test methods.
- Exactly one entry defines ordinary execution; it may borrow an optional `utf8` input followed by an optional mutable `bytes` output.

`public`, `private`, `protected`, and `static` are accepted where meaningful for familiar organization. Ordinary classical methods have typed signed or Boolean parameters, return values, and local bindings, plus bounded control flow. `rev`, `coherent rev`, and `unitary` methods remain zero-argument and `void` until their parameter ownership and inverse signatures are implemented.

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

`assert(condition);` is the sole direct assertion spelling. Classical entries, ordinary methods, and tests accept the implemented Boolean expression profile, evaluate it once, and lower the resulting Boolean local to checked `EXPECT_TRUE`; direct signed-global/literal equality retains compact `EXPECT_EQ`. A false condition traps before later mutation. Current quantum and hybrid entries retain only the compact global/literal equality slice. Wheeler does not define `assertTrue`, `assertFalse`, `assertEquals`, `expectEqual`, matcher objects, or bare `assert condition;` aliases. Typed reversible, quantum, workflow, and proof evidence remains WIP-0021 and WIP-0018 work; this reference does not claim it early merely to make the table look busy.

A reverse block invokes supported calls in reverse lexical order:

```java
reverse {
    first();
    second();
}
```

This executes `reverse second();` and then `reverse first();`.

## Local expressions and bounded control

Ordinary classical methods support signed `long` and `boolean` locals, expressions over checked `*`, `/`, `%`, `+`, `-`, bitwise `^`, `<`, and `==` with multiplication binding before addition/subtraction, `if`/`else`, source-bounded `while`, and source-bounded `for`. Arithmetic and ordering require signed operands. Addition, subtraction, and multiplication trap before destination mutation on signed 64-bit overflow. Division truncates toward zero; remainder follows that quotient. A zero divisor and `Long.MIN_VALUE / -1` trap before writing the destination. Equality requires equal operand types and returns Boolean. XOR accepts two signed values or two Booleans and preserves their type. Conditions require Boolean values; integers are never truthy:

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

A familiar counted loop carries the same mandatory semantic bound:

```java
for (long i = 0; i < 5; i += 1) limit 5 {
    sum += i;
}
```

Its initializer executes once, then the limit is evaluated once. Wheeler checks the limit before every body iteration and traps before executing an iteration beyond the bound. In a `while`, `continue;` transfers to condition reevaluation; in a `for`, it executes the update before reevaluating the condition and therefore cannot evade the next bound check. `break;` exits the innermost bounded loop. Both are rejected outside a loop. Nested loops carry distinct targets and counters. The whole-program step limit remains a separate defense.

Calls evaluate arguments left to right and move them through a verified contiguous typed call window. A value call places one exact declared result in a caller register. A `void` call may carry the same parameter and borrow types without manufacturing or discarding a result register. A value-returning method may return early from a conditional, but every reachable path must end in `return expression;` of the declared type. Static recursion is permitted under the VM's hard 1,024-frame ceiling and the program step ceiling.

Local control compiles to verified typed frame registers and explicit control-flow targets. The function descriptor stores one canonical type code per register. The verifier rejects unknown type codes, invalid targets, out-of-range locals, reads not definitely assigned on every incoming path, operand or call type mismatches, non-Boolean conditions, invalid Boolean constants, and a function that falls through its body.

Control flow is not accepted in `rev` or `coherent rev` methods yet. Wheeler will add reversible branches and loops only with an exact branch or iteration witness; it does not retain hidden history automatically.

## Compile-time constants and finite enums

A scalar constant is evaluated while parsing/lowering and contributes no global, initializer function, or runtime lookup:

```java
const long BASE = 0x0200;
public const long OPCODE_CALL = BASE;
const boolean ENABLED = OPCODE_CALL == 512;
```

The implemented profile accepts `long` and `boolean`, parentheses, checked negation/arithmetic, `^`, `&`, `==`, `<`, declaration-order-independent same-module constants, direct imported public constants, canonical `module::NAME` qualification, and checked `rotateRight32`. Arithmetic follows VM trap rules. The compiler evaluates the bounded dependency graph in canonical name order; cycles report their complete canonical path. Reordering independent declarations leaves semantic `.wbc` unchanged. Constant expressions are accepted in scalar constant declarations, signed state initializers, qreg sizes, static theorem step bounds, and ordinary local expressions. Private, missing, ambiguous, duplicate, effectful, or type-mismatched declarations fail before artifact emission.

A finite enum is canonical sugar for a payload-free tagged variant:

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

Construction, nominal equality, exhaustive matching, artifact metadata, VM values, and rewind use the existing variant path. Enum cases carry no integer ordinal or wire value. The compiler canonicalizes enum cases by name, so reordering declarations does not change semantic `.wbc`. Protocol numbers belong in named constants and explicit encode/decode functions; quantum basis identity and reversible finite permutations remain specified but unimplemented WIP-0017 work.

## Value records

A nominal record declares one or more ordered, immutable fields:

```java
record Span(long start, long end) {}
record Token(Span span, boolean valid) {}

Token token = new Token(new Span(3, 8), true);
long width = token.span.end - token.span.start;
```

A record name begins with an ASCII upper-case letter, keeping nominal type declarations syntactically distinct from statements during standalone module parsing. A field may use a scalar or a previously declared record type. Requiring prior declaration makes recursive and cyclic inline values impossible. Construction is left to right and checks exact arity and field types. Field access is read-only. Records may be locals, parameters, and results; `==` compares nominal type and complete immutable field values.

The VM interns equal immutable values in deterministic construction order. Handles are verified implementation values, not source integers or artifact identity. Rewind removes allocations made by the rewound step, and snapshots include the record table. The current hard ceiling is 65,535 distinct record values per machine.

## Tagged variants

A variant declares a closed ordered case set. Cases carry zero or more typed payload fields:

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

Payload types must already be declared, preventing recursive inline layouts. Construction checks the nominal type, case, arity, and payload types. `match` names one variant type in every arm, rejects duplicate or unknown cases, checks binding types, and requires the complete case set. The final arm is safe without a fallback because verified values can carry only descriptor tags. Bindings are typed locals in their case body. Variants may be parameters and results, and `==` uses nominal structural equality.

The VM interns variants separately from records under a 65,535-value ceiling. Snapshots and rewind include both tables; a checked payload read traps before mutation if its expected tag does not match.

## Fixed arrays

A fixed array owns an immutable, homogeneous sequence whose length is part of its type:

```java
long[4] values = new long[4](2, 4, 6, 8);
long selected = values[2];
```

Construction requires exactly the declared number of left-to-right elements and checks every element type. Arrays may be locals, parameters, and results. Index expressions are signed values and trap before mutation when negative or at least the array length. `==` compares the complete typed value. Lengths range from 1 through 65,535; nested array syntax and mutation are not in this slice.

An immutable borrowed slice uses `T[]` and an explicit checked constructor:

```java
long[] middle = slice(values, 1, 2);
long selected = middle[1];
```

The constructor retains the array origin plus start and length, rejects negative or overflowing ranges before allocation, and never copies elements. Slice indexing is relative and checked. Slices may be locals and parameters but cannot be function results or aggregate elements, so a borrow cannot escape its owner. Mutable slices, split/join, and overlapping-borrow analysis remain future work.

Equal arrays and slices are interned in deterministic construction order under separate 65,535-value machine ceilings. Handles remain unobservable and type-specific. Snapshots and rewind include both tables.

## Bounded owned regions

The dynamic-storage slice provides function-local `region` owners plus mutable signed-word and byte buffers:

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

`writeAscii(raw, offset, "WHEELBC")` is a bootstrap encoding statement. Its literal is at most 4,096 printable ASCII characters, has no escape syntax, and is not a first-class string value. The compiler expands it to checked byte writes starting at the supplied signed offset. A failed run cannot publish an external output file, and ordinary VM rewind still restores every expanded write.

A region declares hard byte and live-object ceilings; the VM also caps total live region storage at 16 MiB. `words` charges eight bytes per signed element. `bytes` charges one byte per element, and `setByte` accepts only 0 through 255. Both allocations are zero-initialized and trap before mutation on a zero/negative length, byte exhaustion, object exhaustion, invalid handle, wrong buffer kind, out-of-range byte, dropped owner, or checked-index failure. Buffers must be dropped before their region; dropping returns their byte and object charge and releases visible contents, while rewind data retains only what is required until commit.

`bufferLength(buffer)` returns the fixed element count for either buffer kind without consuming it. `utf8Valid(buffer)` performs strict RFC 3629 validation over the complete byte buffer. `utf8Count(buffer)` returns the number of Unicode scalar values and traps before destination mutation when the encoding is malformed. `utf8Scalar(buffer, index)` and `utf8Width(buffer, index)` decode one scalar at an exact leading-byte boundary; a continuation, truncation, malformed sequence, or out-of-range index traps before writing the result. The decoder rejects overlong forms, surrogate encodings, values above U+10FFFF, stray continuations, illegal leaders, and truncation; an empty buffer is valid with count zero. Neither operation normalizes text or claims grapheme indexing.

`freezeUtf8(raw)` validates and consumes a `bytes` owner, yielding an affine immutable `utf8` owner over the same charged allocation. Validation failure leaves the source live and unchanged. A frozen value permits byte length, scalar count, scalar-boundary decode, validation, and drop, but no byte mutation or arbitrary string indexing. This primitive is the bootstrap representation below the future library `String`; it does not provide normalization, concatenation, comparison, grapheme segmentation, or canonical text serialization.

An `utf8` function parameter is an immutable synchronous borrow rather than an ownership transfer:

```java
long scalarAt(utf8 text, long index) {
    return utf8Scalar(text, index);
}
```

The caller retains and must eventually drop the owner. The callee may inspect the value and pass the borrow to another call, but cannot move, drop, return, aggregate, or mutate it. Bytecode gives borrowed parameters a distinct verified register type; call lowering creates only transient borrow windows. Mutable `bytes`, `words`, maps, regions, and owned `utf8` results remain forbidden at function boundaries. Runtime owner/kind checks defend malformed artifacts, while verifier rules prevent a valid artifact from turning a borrow into an owner.

`byteview` is the immutable binary counterpart at an entry or ordinary parameter. It exposes only checked octet indexing and `bufferLength`; it performs no UTF-8 validation, permits every byte sequence including empty input, and cannot be written, dropped, returned, or embedded in an aggregate. Passing a mutable byte owner or borrow to a `byteview` parameter creates an immutable transient call window without granting a second writer. An entry declares either `utf8` or `byteview` input, never both, followed by an optional mutable `bytes` output. The embedding API selects the input kind explicitly. Guessing from content would make `0xc0 0x80` a protocol decision, which is not a job for wishful Unicode.

`crypto/Sha256.w` implements bounded SHA-256 in Wheeler over `byteview`, a caller-owned 32-byte output borrow, and a 1,088-byte/three-object scratch region. Its unsigned 32-bit state stays in nonnegative `long` values, reduces additions modulo 2³², and uses checked signed `&` plus `rotateRight32(value, amount)` over those normalized words; no provider or host digest API enters artifact semantics. The current loop bound admits at most 4,096 padded blocks, while ordinary program step/history limits may impose a lower operational ceiling. It is a deterministic identity primitive, not a claim of side-channel resistance.

A `region` function parameter is a synchronous exclusive allocation borrow. The callee may allocate owned buffers/maps under the caller's unchanged byte/object ceilings, use or reborrow them, and must drop every allocation before returning. It cannot drop or return the borrowed region. This gives compiler helpers bounded scratch arenas without transferring or duplicating ownership.

`words` and `bytes` function parameters are synchronous exclusive mutable borrows. They support checked reads, writes, length, and—on byte borrows—strict UTF-8 inspection. Borrows may be nested through calls. One owner cannot fill two mutable parameter slots of the same call, and a borrow cannot be moved, dropped, returned, frozen into an owner, or embedded in a value.

A region can also own one fixed-capacity signed map:

```java
longmap symbols = allocateMap(arena, 16);
put(symbols, 7, 11);
boolean present = mapHas(symbols, 7);
long value = mapGet(symbols, 7);
```

`longmap` accepts every signed key, including zero. `put` inserts or updates in deterministic lowest-free-slot order. Capacity is charged at 24 bytes per entry when allocated. `mapHas` is total; `mapGet` traps before destination mutation when the key is absent. The first slice has no deletion or iteration, so insertion history remains internal VM state and no map encoding is yet exposed as a canonical value.

A `longmap` function parameter is a synchronous exclusive mutable borrow. The callee may update, query, and reborrow the map in nested calls. The caller retains ownership but cannot execute while the callee frame is active. One call cannot pass the same map to two mutable parameters; compiler and bytecode-verifier checks reject that alias before execution. A map borrow cannot be moved, dropped, returned, or stored in an aggregate.

An ordinary function may return one `region` owner. `return` consumes that local and requires every other owner in the callee to have been dropped, so a returned region is empty and uniquely owned by the caller. This supports bounded arena-factory helpers without permitting a buffer to escape from its region. Other owned and borrowed storage results remain rejected.

`region`, `words`, `bytes`, `utf8`, and `longmap` locals are affine owners. Binding one moves the handle and invalidates the source; ordinary copy and equality are rejected. Owners cannot be results, aggregate elements, arrays, or slices. Every owned storage spelling in parameter position denotes its checked nonescaping borrow contract; no parameter receives ownership. Definite-ownership dataflow rejects use after move/drop, live-owner overwrite, control-flow joins with different ownership states, and any function exit with a live owned local. Runtime dropped-state and owner checks remain defense in depth. Snapshots expose canonical region/buffer state, and rewind restores allocation, mutation, borrow-call windows, owned region results, move, and drop exactly.

This slice is enough to exercise bounded region scratch borrowing, owned and exclusively borrowed word/byte mutation, strict UTF-8 freezing/scalar decoding, and owned/borrowed signed symbol maps; it is not yet a compiler arena. Library strings, normalization, generic maps/sets/queues, cross-function ownership, borrowing, split/join, region capabilities, recoverable allocation results, and commit-aware reclamation remain WIP-0013/WIP-0012 work.

## Generated inverse and adjoint theorems

The initial proof slice accepts four closed theorem forms:

```java
theorem incrementInverse proves inverse(increment);
theorem qftAdjoint proves adjoint(qft);
theorem normalized proves equivalent(sourceCircuit, normalizedCircuit);
theorem addBound proves steps(add, 4);
```

The compiler resolves each subject and emits a canonical rule certificate tied to the function or circuit ID. `GENERATED_INVERSE` requires a `rev` function; the trusted `ProofKernel` reconstructs its expected inverse from the forward opcodes. `GENERATED_ADJOINT` requires a `unitary` circuit; the kernel reverses its operation order, inverts every semantic gate or coherent call, and checks that taking the adjoint twice restores the exact circuit body. `CIRCUIT_EQUIVALENCE` requires two circuits on the same register and checks equality after deterministic cancellation of adjacent inverse operations. `STATIC_STEP_BOUND` requires a straight-line function with no calls or branches and checks that its complete forward instruction count does not exceed the stated positive bound or the program ceiling. Unknown subjects, unsupported operations, noncanonical IDs, unknown rules, changed inverse bodies, and malformed metadata reject before execution. This is formal structural evidence, unlike an executable round-trip test.

These rules prove exact compiler generation, one named cancellation rewrite, and straight-line static instruction bounds for the accepted subsets. They do not yet establish matrix-level circuit equivalence under arbitrary rewrites or global phase. General propositions, contracts, proof terms, resource certificates, assumptions, and experiments remain WIP-0011 work.

## Quantum statements

Unitary methods use Java-shaped gate calls over indexed registers:

```java
unitary void bell() {
    H(q[0]);
    CNOT(q[0], q[1]);
}
```

The current semantic gates are `H`, `X`, `Z`, `Phase`, `CPhase`, `CNOT`, `CZ`, and `Swap`. Target adapters may decompose them but cannot change their ideal meaning.

Preparation and measurement are explicit:

```java
prepare(q, 0);
bell();
measured = measure(q);
```

Measurement creates a classical observation and cannot be hidden in a `pure`, `rev`, or `unitary` method.

## Coherent lifting

The first coherent subset supports finite XOR permutations. The same checked method may run on classical state and be referenced from a quantum register:

```java
coherent rev void flip() {
    bit ^= 1;
}

unitary void oracle() {
    q.apply(flip);
}
```

The compiler rejects checked arithmetic, logged writes, measurement, I/O, and other non-unitary operations from this subset. Broader exact finite arithmetic will be added with explicit width semantics.

## Distinct meanings of reverse

- `reverse method();` is new execution of a verified inverse or adjoint.
- VM rewind consumes prior classical step records.
- Uncomputation returns temporary coherent state to its required clean value.
- Replay reuses recorded observations.
- Retry performs a fresh preparation and target execution.

These operations are related but not interchangeable.

## Classical source modules

The stage-0 compiler has an exact multi-source entry point for the first self-hosting module slice:

```java
module bootstrap.arithmetic;
classical class Arithmetic {
    public long twice(long value) { return value + value; }
}
```

A root names imports before its class declaration:

```java
module bootstrap.main;
import bootstrap.arithmetic;
classical class Main {
    state long result = 0;
    entry void main() { result = twice(9); }
}
```

`compileModules(sources, root)` receives the complete named source map. Every map key must equal its source `module` declaration; names are dotted ASCII identifiers; imports are unique and lexically sorted. Resolution requires a closed acyclic graph, rejects missing and unreachable inputs, processes dependencies before importers, caps the graph at 1,024 modules, and caps aggregate UTF-8 source input at 64 MiB. Input map iteration order cannot affect `.wbc` bytes.

The root declares exactly one entry and may use its private records and closed variants. A dependency declares no entry and, in this slice, contains functions, immutable records, closed variants, and structural fixed-array/slice descriptors only. Nominal record names begin with an ASCII upper-case letter. `public` functions, records, closed variants, and fixed-array/slice signatures over scalar or direct public nominal element types are visible to direct importers; imported variant schemas support typed construction and exhaustive matching in the importer; unqualified references prefer same-module declarations and otherwise resolve one unambiguous direct public import. `example.math::twice(value)` names a public function and `example.math::Pair` names a public value type in an exact direct import. Qualified nominal types work in locals, signatures, construction, matches, arrays, and slices. Qualification does not grant transitive or private access. Colliding short names are unavailable unqualified but remain usable by full module name. Private helpers and value types remain usable inside their declaring module, but a public function, record, or variant cannot expose a private local value type in its API. The linker assigns collision-free internal function/type names before ordinary type checking and bytecode lowering. Non-public references, ambiguous exports, import cycles, unsorted imports, quantum domains, dependency state/proofs and transitive implicit access fail closed.

Single-source `compile` rejects module declarations. A modular `wheeler.package` target declares its exact sorted source set and root module; local, workspace, planned, archived, and locked offline builds use the same linker with no path-derived imports. Modules do not yet export variants, arrays, slices, state, circuits, or proofs, and cross-package module imports are not yet linked. Those omissions are explicit WIP-0007/WIP-0009 work, not ambient classpath behavior.

## Explicit host input and output

A classical entry may request immutable input and mutable output borrows:

```java
entry void main(utf8 source, bytes output) {
    scalarCount = utf8Count(source);
    setByte(output, 0, 79);
    setByte(output, 1, 75);
}
```

Input-only and output-only entries are also valid; when both exist, input comes first.

The entry signature is part of canonical bytecode. It does not read a file, environment variable, standard input stream, package resource, or network endpoint. The embedding API supplies exact bytes when constructing the VM or calling `WheelerRuntime`; `wheeler run ... --input <path>` is a capability-minimal host adapter for one explicit physical nonsymlink file. `--output <path> --output-bytes <count>` supplies one bounded zero-initialized external byte owner. By default the complete capacity is published; `setOutputLength(output, used)` selects a checked prefix after sizing and emission. Publication remains atomic and occurs only after successful execution. Each side is capped at 16 MiB. Input is validated as strict UTF-8 before execution. Missing, unexpected, malformed, oversized, nonregular, linked, or incompletely specified effects fail before the first instruction or before output replacement.

The VM installs both effects as externally owned baseline storage and gives the entry only verified borrows. External owners are visible in the initial snapshot, cannot be moved or dropped by Wheeler code, and remain the rewind baseline. `ExecutionResult` returns a defensive copy of output bytes. These effects are classical, bounded, and caller-bound. Output-length changes are rewindable and cannot exceed capacity. General path values, streaming, multiple named effects, and package-resource binding remain WIP-0007/WIP-0012 work.

## Parser and editor tooling

The compiler lexer records line, column, and stage-0 UTF-16 source-character offset. The Wheeler scanner slice records byte ranges and stable error records containing code, byte offset, and one-based line/column; codes 1, 2, and 3 mean unterminated block comment, malformed raw-ASCII literal, and exhausted token capacity. Required identifiers are ASCII letters, digits, and underscore; Unicode remains valid in comments, not names. Inputs are capped at 64 MiB and 16 Mi source characters, tokens at 4,096 characters, token and line counts at 1,000,000 each, declarations at 65,535, and structured block nesting at 256. The parser is formatting-independent and rejects unsupported constructs rather than dropping them.

`tree-sitter-wheeler` provides an incremental grammar, corpus, highlighting, and fold queries for `.w` files. Its concrete syntax tree does not attempt type checking; method and gate meaning are resolved by the compiler.

## Bootstrap direction

The current compiler and VM use Java only as stage-0 infrastructure. The production compiler will be Wheeler source and must compile itself to a byte-identical second-stage `.wbc` artifact. Signed/Boolean values, immutable records/variants/arrays/slices, typed calls/control, deterministic classical source-module linking, and function-local bounded regions with owned word/byte/UTF-8 buffers and signed maps form the current bootstrap substrate. Library strings, generic deterministic collections, cross-function ownership, qualified/re-exported and cross-package modules, and streaming or multiple file effects remain complete vertical slices.

After native runtime conformance, the Java compiler, VM, tools, Gradle build, and JVM deployment path will be deleted. A cold build will use a content-addressed prior native Wheeler release and `.wbc` recovery seed. Java APIs and object semantics are therefore not prospective Wheeler contracts.

See [WIP-0007](../proposals/WIP-0007-self-hosting-compiler-and-bootstrap.md), [WIP-0008](../proposals/WIP-0008-java-free-runtime-and-native-bootstrap.md), and the Wheeler-native package/build contract in [WIP-0009](../proposals/WIP-0009-wheeler-package-and-build-system.md).

## Proof direction

Proofs will use integrated Wheeler syntax and semantics. Contracts attach to executable declarations; theorem and experiment declarations resolve through ordinary modules; structured proof blocks elaborate to canonical terms checked by a small trusted kernel. Formal theorem evidence remains distinct from simulator tests and sampled hardware results.

The current `QFTProof.w` is an executable inverse law, not a formal theorem. `Counter.w`, `QFT.w`, and `QuantumCompiler.w` carry the initial finite-rule certificates. General proposition terms, contracts, matrix-level quantum proofs, resource claims, and tooling contracts remain specified work in [WIP-0011](../proposals/WIP-0011-integrated-proofs-and-certificates.md).

## Standard library direction

The Wheeler-written standard library will provide allocation-free core values, owned deterministic collections, bytes and UTF-8, explicit host capabilities, reversible data structures with honest inverse contracts, affine logical qubits and registers, circuits, observables, target jobs, proof support, and test utilities. Its package layering and ownership rules are specified in [WIP-0012](../proposals/WIP-0012-wheeler-standard-library.md).

## Teaching path

1. `Counter.w`, `BinaryTree.w`, `BootstrapControl.w`, `FunctionValues.w`, and `RecursiveValue.w`: reversible state, fixed-capacity data, typed locals, bounded control, parameters, returns, static calls, and bounded recursion.
2. `RegionStorage.w`, `FrozenUtf8.w`, and `Utf8Lexer.w`: affine bounded storage, immutable UTF-8, strict decoding, and token-buffer scanning.
3. `CoherentOracle.w` and `QuantumNeuralNetwork.w`: exact XOR permutations over classical and coherent data.
4. `QFT.w` and `QFTProof.w`: unitary regions, generated adjoints, and executable inverse laws.
5. `QuantumOptimizer.w`: repeated target observations, classical acceptance, commit, and target-free replay.
6. `QuantumCompiler.w`: semantic comparison of source and normalized circuits.
7. `SurfaceCode.w`: a static correction kernel whose documentation states the dynamic-target boundary.

See [executable examples](../examples.md) for exact results and scope. Every checked-in example compiles, executes, and parses without Tree-sitter error nodes in the ordinary test gate.
