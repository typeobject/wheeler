---
title: The Wheeler Language
description: The accepted source forms for classical, reversible, coherent, quantum, and hybrid work.
---

# The Wheeler Language

Wheeler was shaped in ships and instrument rooms where every erased distinction
became heat, history, or doubt. Its source resembles familiar class-based
languages. Its effects remain visible in the words that begin a declaration.

Accepted source lowers to one typed `.wbc` artifact. The artifact keeps inverse
execution, retained-history rewind, coherent permutations, unitary adjoints,
measurement, and external workflow events in separate forms.

Whitespace does not alter meaning. Simple statements end with semicolons. Source
accepts `//` and `/* ... */` comments.

## Domains and state

A source file contains one computation-domain class:

```wheeler
classical class Counter {
  state long count = 0;
}
```

The domains are `classical`, `quantum`, and `hybrid`. Format 1.0 provides signed
64-bit classical state and affine logical quantum registers:

```wheeler
state long measured = 0;
qreg q = new qreg(3);
```

A `qreg` names a logical register. Raw provider qubits never become source values.

## Methods and their promises

```wheeler
long add(long left, long right) { return left + right; }
void helper() { }
rev void increment() { count += 1; }
coherent rev void flip() { count ^= 1; }
unitary void qft() { H(q[0]); }
test void startsAtZero() tags(unit) { assert(count == 0); }
entry void main() { }
```

| Declaration | Promise |
| --- | --- |
| ordinary method | Runs classical work and may return a value. |
| `rev` | The compiler can generate and verify an inverse body. |
| `coherent rev` | The accepted finite permutation can also act on quantum amplitudes. |
| `unitary` | The body contains unitary quantum work and receives a generated adjoint. |
| `dynamic` | The target performs measurement, reset, and local conditions inside one region. |
| `test` | A fresh classical case runs under declared cases, tags, and limits. |
| `entry` | Execution begins here and may hold the declared host loans. |

`Done` is the one-value completion type, and `done` is its value. `void` carries no
value across a call.

The present `rev`, `coherent rev`, and `unitary` source forms take no arguments and
return `void`. Ordinary methods accept the supported scalar, aggregate, owner, and
loan parameters.

A parameterized test accepts one `long` or `boolean` parameter and an inline
`cases(...)` list of 1 through 1,024 unique values. A test may carry at most 64
unique dotted tags. Optional `limits(steps = N, history = M)` values may lower the
normal ceilings of 4,000,000 transitions and 4,000,000 history entries.

An unparameterized test may name `fixtures(suite_acquire = openSuite,
case_acquire = openCase, case_release = closeCase, suite_release = closeSuite)`.
The runner acquires in declaration order and releases in reverse scope order.
Failure in a case or release never suppresses later required release work.

`public`, `private`, `protected`, and `static` are accepted where their declaration
kind permits them.

## Classical work

| Source | Effect |
| --- | --- |
| `count += 1;` | Checked signed addition. The generated inverse subtracts. |
| `count -= 1;` | Checked signed subtraction. The generated inverse adds. |
| `bit ^= 1;` | Bitwise XOR. The operation is self-inverse. |
| `count = 7;` | Logged overwrite. Rejected inside a generated-inverse method. |
| `increment();` | Call a forward method or unitary region. |
| `reverse increment();` | Run a verified inverse or adjoint as new work. |
| `assert(count == 2);` | Trap before later mutation if the condition is false. |
| `checkpoint();` | Add a reversible checkpoint marker. |
| `commit();` | Advance the local rewind horizon. |

A reverse block inverts operations in reverse source order:

```wheeler
reverse {
  first();
  second();
}
```

The runtime performs `reverse second();` followed by `reverse first();`.

## Expressions and control

Classical locals use `long` and `boolean`. Expressions provide checked `*`, `/`,
`%`, `+`, and `-`, signed `&`, signed or Boolean `^`, Boolean `!`, and the
comparisons `<`, `==`, and `!=`.

Division truncates toward zero. A zero divisor and `Long.MIN_VALUE / -1` trap
before mutation. Signed overflow also traps first. Conditions require Boolean
values. Integers never stand in for truth.

Loops declare their maximum body count:

```wheeler
long i = 0;
while (i < 5) limit 5 {
  sum += i;
  i += 1;
}

for (long j = 0; j < 5; j += 1) limit 5 {
  sum += j;
}
```

The limit is evaluated once. Wheeler checks it before every iteration. `break`
leaves the nearest loop. `continue` returns to a `while` condition or performs a
`for` update before the next condition.

Ordinary control flow does not yet enter `rev` or `coherent rev` methods. A future
reversible branch must carry the information needed to choose its inverse path.

Arguments evaluate from left to right. Calls move one contiguous typed argument
window into the callee. Static recursion remains subject to the VM ceiling of
1,024 frames and the program transition limit.

## Constants and finite cases

Compile-time constants create no global or runtime lookup:

```wheeler
const long BASE = 0x0200;
public const long OPCODE_CALL = BASE;
const boolean ENABLED = OPCODE_CALL == 512;
```

Constants accept signed and Boolean expressions, checked arithmetic, parentheses,
`!`, `^`, `&`, `==`, `<`, and `rotateRight32`. Same-module declarations may refer
forward. Directly imported public constants may use an unqualified name or
`module::NAME`.

A finite enum is a payload-free tagged variant:

```wheeler
public enum Direction {
  case Left;
  case Right;
}
```

Cases have no implicit protocol number. Canonical case-name order determines a
coherent basis when a finite mapping contains a power-of-two number of cases.
Protocol numbers belong in explicit constants and encode or decode functions.

## Immutable values

Records contain one or more ordered immutable fields:

```wheeler
record Span(long start, long end) {}
record Token(Span span, boolean valid) {}
```

Variants contain a closed set of cases and optional payloads:

```wheeler
variant LookupResult {
  case Missing();
  case Found(long value);
}
```

A `match` must cover every case exactly once. Records and variants use nominal
structural equality. One machine may intern at most 65,535 distinct values of
each kind.

`Slot<T>` is the first compiler-owned closed generic. It has `Vacant` and
`Holding(T)` cases. The accepted payloads are signed, Boolean, `Done`, fixed
scalar arrays, and nested slots.

A fixed array owns an immutable homogeneous sequence whose length is part of its
type:

```wheeler
long[4] values = new long[4](2, 4, 6, 8);
long selected = values[2];
```

Lengths range from 1 through 65,535. An immutable `T[]` slice keeps an array
origin, start, and length. Slices may be locals and parameters. They cannot escape
as results or aggregate fields.

## Owned storage and loans

A function-local region owns mutable word buffers, byte buffers, and signed maps:

```wheeler
region arena = new region(32, 2);
words data = allocate(arena, 4);
bytes raw = allocateBytes(arena, 4);
set(data, 0, 7);
setByte(raw, 0, 255);
drop(raw);
drop(data);
drop(arena);
```

A region declares byte and live-object limits. All live region storage together
may use at most 16 MiB. Word elements cost eight bytes. Byte elements cost one.
Buffers begin filled with zero. `setByte` accepts values from 0 through 255.

Owners are affine. Binding, passing to an owning parameter, or returning one moves
the handle and invalidates its source. Every owner must be moved, returned, or
dropped before its function exits. A region must be empty before drop.

`borrow T` creates a shared nonescaping loan. `borrow mut T` creates an exclusive
nonescaping loan. One owner cannot fill two mutable parameters in the same call.
Loans cannot be stored, returned, moved, or dropped.

`longmap` uses deterministic lowest-free-slot insertion. Capacity costs 24 bytes
per slot. `mapHas` is total. `mapGet` traps when the key is absent. The current map
has no deletion or iteration.

## Text and binary data

Mutable `bytes` may be validated and consumed into an immutable affine `utf8`
owner with `freezeUtf8`. Validation follows RFC 3629 and rejects overlong forms,
surrogates, values above U+10FFFF, malformed leaders, stray continuations, and
truncation.

`utf8Count` counts Unicode scalar values. `utf8Scalar` and `utf8Width` require an
exact leading-byte position. Wheeler performs no normalization or grapheme
segmentation at this layer.

`borrow byteview` is the immutable binary form. It accepts any byte sequence and
supports checked indexing and length. It never guesses whether bytes are text.

The bootstrap `writeAscii` statement accepts at most 4,096 printable ASCII
characters and expands into checked byte writes. It is an encoding operation,
rather than a general source string value.

## Proof declarations

The first proof kernel accepts four closed forms:

```wheeler
theorem incrementInverse proves inverse(increment);
theorem qftAdjoint proves adjoint(qft);
theorem normalized proves equivalent(sourceCircuit, normalizedCircuit);
theorem addBound proves steps(add, 4);
```

| Rule | Kernel check |
| --- | --- |
| `GENERATED_INVERSE` | Rebuild the inverse from the accepted reversible opcodes. |
| `GENERATED_ADJOINT` | Reverse gate order and invert every semantic operation. |
| `CIRCUIT_EQUIVALENCE` | Cancel adjacent inverse operations for two circuits on one register. |
| `STATIC_STEP_BOUND` | Count one straight-line body with no calls or branches. |

These certificates establish their stated structural rules. They do not establish
hardware fidelity, a general matrix identity, or every behavior of a named
algorithm.

## Quantum regions

Unitary methods use these semantic gates:

```text
H  X  Z  Phase  CPhase  CNOT  CZ  Swap
```

A target may decompose them while preserving their ideal meaning.

Preparation and measurement remain explicit:

```wheeler
prepare(q, 0);
bell();
measured = measure(q);
```

Measurement creates a classical observation and cannot occur inside `rev`,
`coherent rev`, or `unitary` work.

A `dynamic void` region accepts preparation, fixed gates, single-qubit
measurement into a target-resident Boolean slot, reset, and conditional X or Z.
It has no generated adjoint.

## Coherent lifting

The coherent subset accepts no-op, XOR, width-modular constant addition and
subtraction, coherent call or uncall, and return. It rejects overwrite,
measurement, I/O, and data-dependent control.

```wheeler
coherent rev void addThree() {
  value += 3;
}

unitary void oracle() {
  q.apply(addThree);
}
```

On a three-qubit register, the lifted addition maps basis value `x` to
`(x + 3) mod 8`. Ordinary classical execution still uses checked signed
arithmetic.

## Five roads called reverse

- `reverse method();` performs a verified inverse or adjoint as new work.
- VM rewind consumes retained classical transition history.
- uncomputation returns coherent temporary state to its required clean value.
- replay applies an accepted observation without contacting a target.
- retry prepares fresh physical state and creates a new target lineage.

A familiar endpoint does not merge these operations.

## Modules

A module declares its canonical dotted name before the class:

```wheeler
module bootstrap.arithmetic;
classical class Arithmetic {
  public long twice(long value) { return value + value; }
}
```

Imports are unique and sorted. The complete graph must be closed, acyclic, and
rooted. A compilation may contain at most 1,024 modules and 64 MiB of UTF-8 source.
Public declarations cross direct imports. Qualification uses
`example.math::twice(value)` or `example.math::Pair`.

Qualification grants no private or transitive access. The linker rejects
ambiguous exports, unreachable modules, cycles, domain mismatches, and public APIs
that expose private types.

## Explicit host input and output

A classical entry may borrow strict text or binary input and an optional mutable
byte output:

```wheeler
entry void main(borrow utf8 source, borrow mut bytes output) {
  scalarCount = utf8Count(source);
  setByte(output, 0, 79);
  setOutputLength(output, 1);
}
```

Each side may contain at most 16 MiB. The entry signature declares the effects.
Paths and bytes remain host bindings. Output becomes visible only after successful
execution. Wheeler installs external owners in the rewind baseline and gives the
entry verified loans.

## Source limits and tooling

Identifiers use ASCII letters, digits, and underscore. Comments may contain
Unicode. Source may contain at most 64 MiB and 16 million characters. One token
may contain 4,096 characters. Token and line counts each stop at 1,000,000,
declarations at 65,535, and block nesting at 256.

The compiler rejects unsupported syntax. `tree-sitter-wheeler` supplies incremental
parsing, highlighting, and folding. Type and effect meaning remain compiler work.

The current accepted frontier is deliberate. Wheeler has concrete aggregates,
fixed arrays, affine primitive storage, and explicit loans. General generic
declarations, returned loans, closures, runtime dispatch, effect variables, and
provider-defined semantic opcodes have no accepted source form.

The gray recension begins the practical route through these distinctions in
[*Home Was the Easy Part*](../tutorials/). The [program ledger](../examples.md)
provides source identities and expected outcomes for the maintained cases.
