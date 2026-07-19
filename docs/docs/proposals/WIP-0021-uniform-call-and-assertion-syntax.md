# WIP-0021: Uniform call and assertion syntax

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler language, compiler, testing, formatter, and documentation maintainers |
| Created | 2026-07-18 |
| Updated | 2026-07-18 |
| Area | Source syntax, assertions, test doubles, diagnostics, migration |
| Depends on | WIP-0005, WIP-0006, WIP-0016, WIP-0018 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler should use one call-shaped spelling for operations that consume arguments. Assertions therefore use `assert(condition);`. The language should not duplicate that operation as `assertTrue`, `assertEquals`, `expectEqual`, matcher chains, or a bare `assert condition;` statement.

Test doubles should be explicit typed values or fixtures passed through ordinary ownership and capability boundaries. Wheeler should not grow Mockito-style interception, `when(...).thenReturn(...)`, ambient replacement registries, or a second meaning of `verify`. Familiar syntax is useful; familiar accidental complexity is still accidental complexity.

This proposal defines the syntax rubric and migration gate before changing the corpus. It exists specifically to prevent a cheerful repository-wide replacement from becoming the language specification.

## Motivation

The current bootstrap profile spells an equality check as:

```java
assert value == 2;
```

That form is easy to parse, but it is inconsistent with argument-taking intrinsics such as `drop(value);`, `prepare(q, 0);`, and ordinary calls. It also invites a second family of test-only names: `assertTrue`, `assertEquals`, `expectEqual`, matchers, and eventually a fluent mock API with more aliases than semantics.

Syntax duplication has a real bootstrap cost. The stage-0 parser, Wheeler parser, Tree-sitter grammar, formatter, examples, teaching text, malformed corpus, and self-host differential fixtures must all agree. Every gratuitous spelling multiplies that matrix. Two ways to say the same thing are not twice as ergonomic when both must survive a fixed point.

The change must be planned before migration because Wheeler source appears in `.w` files, Java text blocks, Tree-sitter corpora, Markdown examples, package archives, and native compiler fixtures. Search can find candidates; only parsers and tests prove the result.

## Use cases

1. A classical entry checks state with `assert(count == 2);`. Stage 0, the Wheeler compiler, Tree-sitter, the formatter, and documentation all recognize exactly that form.
2. A parameterized test checks `assert(roundTrip(value) == value);`. It does not choose among `assertTrue`, `assertEquals`, and `expectEqual` according to the author's breakfast.
3. A package test needs a failing storage provider. It receives an explicit `FailingStore` fixture implementing the required typed boundary. No ambient registry rewrites the production store, and ordinary ownership rules still apply.
4. A reversible test records an event, runs an inverse, and asserts over the resulting typed state. The assertion is an irreversible observation; it is not smuggled into the reversible operation merely because its name looks like a method.
5. Old bare assertion syntax reaches the new parser. Compilation fails at the missing `(` with one bounded diagnostic; no compatibility parser guesses which source generation produced it.

## Goals

- Define one visible assertion form: `assert(boolean_expression);`.
- Apply ordinary call punctuation to every argument-taking intrinsic unless a WIP establishes control-flow or declaration syntax.
- Keep equality, ordering, negation, and Boolean composition in expressions rather than assertion-name variants.
- Define test doubles as explicit typed values, fixtures, capabilities, or deterministic target implementations.
- Reserve `verify` for semantic verification boundaries such as bytecode, packages, and proofs, not mock-call accounting.
- Inventory and migrate every authoritative parser, grammar, formatter, native fixture, example, package archive, and document without retaining a legacy spelling.
- Make malformed old and near-miss forms fail with stable diagnostics.

## Non-goals

- Turn `if`, `while`, `for`, `match`, `reverse`, declarations, or proof clauses into ordinary functions. Their syntax denotes control, binding, or proof structure rather than argument dispatch.
- Copy JUnit, Hamcrest, Mockito, or another host framework's API.
- Add stringly named dependency injection, runtime method replacement, reflection, or dynamic proxies.
- Decide the complete assertion library for traps, quantum evidence, histories, workflows, or proofs. Those operations need distinct semantics, not merely distinct capitalization.
- Preserve source compatibility with the bootstrap-only bare assertion spelling.
- Change canonical `.wbc` solely because source punctuation changed.

## Terms and semantic model

An **ordinary call** evaluates explicit arguments left to right, checks the callee's static signature, and crosses the ownership and effect boundary declared by that signature.

An **intrinsic call** uses the same visible argument punctuation but is resolved by the compiler to a language operation rather than a user declaration. Call-shaped syntax does not imply that an intrinsic is a first-class function.

A **structural form** controls parsing, binding, effects, inversion, or proof construction. Classes, methods, `if`, `match`, `reverse`, and theorem clauses are structural forms and need not mimic calls.

An **assertion** evaluates one Boolean expression exactly once. If it is true, execution advances without mutating program state. If it is false, execution traps before later state mutation or report publication. The assertion event may be recorded by a test runner, but it is not a reversible program-state transition.

A **test double** is an explicit implementation of a typed boundary supplied by a test descriptor or fixture. A double has ordinary identity, ownership, limits, effects, and event output. It is not an instruction to rewrite another declaration.

The first grammar decision is:

```ebnf
assertion_statement := "assert" "(" boolean_expression ")" ";"
```

The following are deliberately not aliases:

```java
assert ready;                    // rejected: missing call punctuation
assertTrue(ready);               // rejected: no duplicate intrinsic
assertEquals(expected, actual);  // rejected: equality belongs in the expression
expectEqual(actual, expected);   // rejected: another duplicate
```

The canonical form is:

```java
assert(ready);
assert(actual == expected);
```

## Ownership and boundaries

The language specification owns the classification of call, intrinsic, and structural forms. The compiler owns name resolution, Boolean typing, single evaluation, lowering, and source diagnostics. The bytecode verifier owns the validity of the lowered checked operation. The VM owns successful advance and trap-before-mutation behavior.

`tree-sitter-wheeler` owns a structurally equivalent editor grammar, not an alternative language. The formatter owns whitespace around the accepted token structure and must not translate between assertion APIs. The package test runner owns assertion events and test-double fixture construction. Host adapters may implement a typed fixture but may not install ambient interception.

Documentation and examples consume this contract. They are not a compatibility authority, even when an old snippet has been copied often enough to acquire seniority.

## Design

### Syntax rubric

A construct uses call-shaped punctuation when all of the following hold:

1. it consumes zero or more value expressions;
2. argument evaluation follows ordinary expression order;
3. it does not introduce a lexical binding or a nested control region;
4. it does not alter parse precedence outside its parentheses.

A construct remains structural when it introduces names, scopes, branches, loops, inversion regions, ownership transfer syntax, effect clauses, or proof terms whose meaning cannot be represented as ordinary eager arguments.

New syntax proposals must state which side of this line they occupy. “It looked nicer in one example” is not a semantic category.

### Assertions

Wheeler exposes only `assert(condition);` for a direct Boolean assertion. Equality and truth are expression operations. Diagnostics may render evaluated expected and actual values when the expression carries typed comparison metadata, but richer rendering does not create another source spelling.

Expected traps, inverse restoration, rewind restoration, quantum-state comparison, sampled acceptance, and proof-kernel rejection are test-runner operations with their own typed evidence. They may use call syntax, but they must not masquerade as aliases for direct Boolean assertion.

### Reversible, quantum, and proof evidence

The framework does not solve Wheeler's unusual test dimensions by minting a commemorative assertion name for each one. Instead, execution operations produce typed evidence and `assert(condition);` checks a proposition over that evidence.

| Dimension | Evidence producer | Valid assertion subject | Invalid shortcut |
| --- | --- | --- | --- |
| Forward execution | bounded fresh VM attempt | final typed state, output, steps, trap, events | host exception text |
| Language inverse | verified forward/inverse attempt pair | exact declared-state restoration and inverse identity | VM rewind result |
| VM rewind | retained-history rewind attempt | complete snapshot and history cursor restoration | invoking a generated inverse |
| Uncomputation | coherent workspace witness | clean ancillas, restored workspace, preserved output | measurement-only agreement |
| Exact quantum | exact simulator evidence | amplitudes under a declared global-phase rule, qubit order, clean ancillas | sampled counts |
| Sampled quantum | shot-bounded target evidence | explicit acceptance result and retained target identity | Boolean coercion of inconclusive evidence |
| Hybrid workflow | durable run and event evidence | replay, retry, commit, cancellation, compensation, and job identities | rerunning a provider call during replay |
| Proof | kernel result tied to a proposition and certificate | exact accepted/rejected rule result and proposition identity | compiler search success |
| Malformed artifact | verifier attempt | stable rejection code and pre-execution state | a Java decoder exception class |

A test may take snapshots and invoke these producers through explicit runner APIs. The syntax must keep operations distinct even when the final line is an ordinary assertion:

```java
MachineSnapshot before = machine.snapshot();
InverseEvidence inverse = runner.invokeInverse(machine, operation);
assert(inverse.operationIdentity == operation.identity);
assert(machine.snapshot() == before);

RewindEvidence rewind = runner.rewind(machine, inverse.forwardSteps);
assert(rewind.restoredHistoryCursor);
```

The example is design pseudocode, not current reference syntax. In particular, `invokeInverse` and `rewind` return different nominal types. A generic matcher that accepts either would erase the distinction the framework is supposed to test.

Exact quantum assertions occur outside unitary regions over simulator evidence; an assertion inside coherent evolution would itself be an observation and is rejected. Sampled evidence reduces to `Accepted`, `Rejected`, or `Inconclusive`. Only an explicit comparison with one of those variants yields a Boolean; `Inconclusive` never becomes truthy because the dashboard looked anxious.

Proof assertions consume kernel output. `assert(result.accepted);` establishes that the kernel accepted the exact certificate and proposition identity. It does not establish that a compiler search was exhaustive, that hardware behaved ideally, or that a differently encoded proposition is “close enough.”

Expected traps likewise become values in runner-owned attempt evidence rather than host exceptions:

```java
Attempt evidence = runner.observe {
    boundedOperation();
};
assert(evidence.outcome == Outcome.Trap(TrapCode.Bounds));
assert(evidence.successfulTransitions == 0);
```

`observe { ... }` is structural pseudocode because it delimits execution, ownership, and trap capture; it is not proposed as an ordinary eager function. WIP-0018 owns its final spelling and descriptor semantics.

### Test doubles

A test selects a double by declaring a fixture or explicit parameter whose static type satisfies the production boundary. Construction is deterministic and bounded. Calls produce typed events owned by that double. Tests assert over returned values, state, or event sequences using ordinary Wheeler expressions.

There is no method interception, invocation-count matcher, hidden global replacement table, or source-level `verify(double).called(...)` dialect. If call accounting matters, the boundary exposes a typed bounded event log. This is slightly more typing and considerably less séance.

### Naming

Assertion-related operations use the `assert` stem only when they terminate a case on failure. Predicates remain predicates: `isEmpty`, `contains`, `verified`, or a domain name. Verification operations retain domain-qualified meaning and return typed results or diagnostics; they are not assertion aliases.

The manual must not teach `assertTrue`, `assertFalse`, `assertEquals`, `expectEqual`, bare `assert`, Mockito matcher names, or fluent stubbing as Wheeler syntax.

## Reversibility and history

An assertion is a checked observation. A successful assertion changes no Wheeler program state and emits no reversible inverse operation. A failed assertion traps before state mutation and therefore adds no successful VM transition or retained-history record.

Runner-level assertion evidence is append-only test evidence. Rewinding program execution does not erase the runner's knowledge that an assertion was attempted. Language inversion, VM rewind, and test-report reduction remain separate operations.

A test double follows the reversibility contract of its typed boundary. Pure deterministic doubles need no history. Stateful reversible doubles provide explicit inverse behavior. Effectful doubles record bounded fixture-owned events; those events are not made reversible by calling them “mock history.”

## Concurrency and determinism

Assertion expression evaluation follows the language's ordinary deterministic evaluation order. The runner assigns assertion events stable case-local sequence numbers. Parallel case completion cannot alter semantic report order.

Test doubles are invocation-owned unless a descriptor explicitly declares shared state. Shared doubles require a deterministic scheduler or append-only canonical event order. Ambient singleton doubles and process-wide call counters are rejected.

## Quantum and proof implications

`assert(condition);` checks a classical Boolean. It cannot inspect unmeasured amplitudes, establish a theorem, or turn sampled evidence into certainty.

Quantum state, sampled distributions, generated adjoints, clean ancillas, and proof certificates require typed runner or kernel operations defined by WIP-0011 and WIP-0018. Their results may feed a classical assertion only when the relevant contract explicitly produces a Boolean with adequate evidence.

The proof kernel's `verify` operation retains its semantic name. Mockito-style `verify(mock)` syntax is excluded so proof review does not require guessing which universe the verb belongs to.

## Bytecode, persistence, and compatibility

The punctuation migration does not require a new `.wbc` opcode. The accepted assertion lowers to the existing checked operation where its expression fits the current profile; broader Boolean expressions may require separately reviewed lowering but not a duplicate assertion family.

Source compatibility is intentionally broken. The parser rejects bare `assert condition;` after migration. Canonical package archives containing source must be rebuilt and relocked. Existing canonical `.wbc` artifacts remain valid because their semantics do not depend on source punctuation.

No artifact or manifest records a “legacy assertion syntax” switch. Source profiles are not nesting dolls.

## Safety, limits, and failures

Assertion expressions obey ordinary expression depth, local, step, and arithmetic limits. Evaluation traps before the assertion outcome if the expression itself traps. A false result produces one stable assertion diagnostic. Diagnostic payloads and rendered values remain bounded.

Test-double event logs, queued responses, failures, and fixture bytes have descriptor limits. Exhaustion fails the case rather than dropping events or returning an undeclared default. Unknown fixture kinds, incompatible boundary types, duplicate fixture identities, and ambient replacement requests fail during discovery.

Near-miss syntax is rejected deterministically:

- bare assertion: expected `(` after `assert`;
- empty assertion: expected a Boolean expression;
- extra assertion arguments: expected `)` after one expression;
- non-Boolean expression: expected Boolean assertion condition;
- `assertTrue` or `assertEquals`: ordinary unresolved function unless explicitly declared by user code, never a language intrinsic.

## Migration and deletion

1. Inventory assertion and test-double spellings in Wheeler files, embedded source fixtures, Tree-sitter corpora, Markdown, package archives, and generated locks. Classify matches; do not replace English prose because `rg` felt energetic.
2. Add parser and Tree-sitter acceptance for `assert(condition);`, plus malformed tests for the old and near-miss forms.
3. Update the Wheeler-native parser and differential compiler fixtures. Require stage-0/native byte-identical `.wbc` for equivalent accepted sources.
4. Update the formatter and documentation validator tests for token preservation, comments, idempotence, and call punctuation.
5. Migrate canonical Wheeler packages and examples, rebuild exact `.wpk` archives and locks, then run every package and workspace test.
6. Migrate Java text blocks, Tree-sitter corpora, manuals, WIPs, and future sketches. Future documents may be speculative; they may not be syntactically sloppy for sport.
7. Delete bare assertion parsing in the same feature. Add no compatibility switch, warning period, or second AST node.
8. Audit assertion-name and mock-style vocabulary. Replace duplicate proposed APIs with `assert(expression)` or explicit typed fixture/event operations.

## Progress

- [x] The syntax inconsistency and repository-wide migration surface are documented before implementation.
- [ ] Parser, native parser, Tree-sitter, and formatter agree on one assertion grammar.
- [ ] Direct Boolean expressions type-check and evaluate exactly once.
- [ ] Old, duplicate, and near-miss assertion forms fail with focused diagnostics.
- [ ] Stage-0 and Wheeler-native compilers emit byte-identical artifacts for assertion fixtures.
- [ ] Canonical packages, archives, locks, examples, tests, and documentation use the accepted spelling.
- [ ] Test fixtures expose explicit typed doubles and bounded event logs without interception APIs.
- [ ] Assertion and test-double vocabulary audits contain no undocumented competing authority.

## Testing and acceptance

- [ ] Positive parser tests cover literals, locals, calls, equality, ordering, negation, and composed Boolean expressions.
- [ ] Negative parser and type tests cover bare, empty, multiple-argument, non-Boolean, duplicate-name, and malformed assertions.
- [ ] An assertion expression is evaluated once, including when it calls a stateful or trapping operation.
- [ ] A false assertion traps before mutation and creates no successful transition-history record.
- [ ] Forward execution, inverse invocation, and rewind retain distinct assertion evidence.
- [ ] Formatter output is deterministic, comment-preserving, minimal-diff, and idempotent.
- [ ] Tree-sitter parses every checked-in Wheeler file and its assertion malformed corpus.
- [ ] Stage-0 and native compiler outputs match for accepted assertion fixtures.
- [ ] A typed failing double and a bounded event-recording double run through package discovery without ambient state.
- [ ] Inverse, rewind, uncomputation, exact quantum, sampled quantum, workflow, proof, and malformed-artifact evidence remain nominally distinct through assertion reduction.
- [ ] Sampled `Inconclusive` evidence cannot satisfy a Boolean assertion without an explicit, reviewable comparison.
- [ ] Full repository search plus parser/runner gates prove old source spellings and proposed duplicate intrinsics are absent.
- [ ] Current reference documentation describes only implemented syntax and fixture behavior.

## Alternatives

### Keep bare `assert condition;`

Rejected. It saves two punctuation characters while creating a special argument-taking statement and a predictable bikeshed over every future assertion name.

### Provide `assertTrue`, `assertFalse`, and `assertEquals`

Rejected. Boolean truth and equality already belong to expressions. Duplicate assertion names split teaching, diagnostics, generic equality, and future self-hosting work without adding semantics.

### Copy JUnit and Mockito

Rejected. JUnit remains useful stage-0 scaffolding, but its Java overloads, reflection, exceptions, and extension model are not Wheeler semantics. Mockito's dynamic interception and fluent matcher state conflict with explicit ownership, deterministic discovery, and self-hosting.

### Treat every structural form as a function

Rejected. Control flow, binding, inversion, and proofs have region semantics that eager ordinary calls do not express. Uniformity bought by lying about evaluation is merely matching punctuation.

## Open questions

- Should assertion failure bytecode retain typed comparison metadata for structural diffs, or should the first profile report only the source range and Boolean result? — **Owner:** compiler and runtime maintainers — **Decide by:** before broad expression lowering
- Which minimal fixture interface should demonstrate typed event-recording doubles without preempting WIP-0018 lifecycle design? — **Owner:** testing and package maintainers — **Decide by:** before fixture implementation

## References

- [WIP-0005: Wheeler source language](WIP-0005-wheeler-source-language.md)
- [WIP-0006: Concrete syntax, tooling, and teaching](WIP-0006-concrete-syntax-tooling-and-teaching.md)
- [WIP-0016: Nonconfigurable source formatter](WIP-0016-nonconfigurable-source-formatter.md)
- [WIP-0018: Integrated deterministic testing](WIP-0018-integrated-deterministic-testing.md)
- [Language profile](../reference/language-profile.md)
