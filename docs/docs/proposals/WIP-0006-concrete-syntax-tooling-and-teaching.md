# WIP-0006: Concrete syntax, editor tooling, and teaching profile

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler language, tooling, and documentation maintainers |
| Created | 2026-07-17 |
| Updated | 2026-07-18 |
| Area | Parser, concrete syntax, Tree-sitter, diagnostics, teaching |
| Depends on | WIP-0005 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler defines a formatting-independent, unambiguous concrete syntax with stable source locations and a mirrored Tree-sitter grammar. The compiler lexer records line, column, and offset for every token. Editor tooling receives named syntax nodes, highlights, folds, comments, and `.w` file identity without depending on compiler implementation classes.

The language is also organized as a teaching progression matching Wheeler's reversible typed IR: ordinary state and explicit barriers, reversible methods and reverse blocks, exact coherent permutations, unitary circuits and adjoints, measurement, and finally hybrid target workflows. Concrete syntax gives each boundary a stable node; it does not infer semantics or merge them for highlighting convenience. Examples introduce one boundary at a time and never explain measurement as ordinary reversible assignment.

## Motivation

Wheeler source must work equally well in a compiler, editor, notebook, code browser, classroom, and research tool. A parser that depends on line breaks or accepts broad syntax only to discard unsupported nodes is hostile to all of those uses. Quantum programming is already conceptually demanding; syntax should expose semantic boundaries without unnecessary punctuation or provider-specific ceremony.

Tree-sitter-like tools need a stable concrete tree even while type checking and target support evolve. Learners need runnable examples, deterministic simulators, useful failures, and vocabulary that distinguishes inverse, uncompute, rewind, replay, and retry.

## Use cases

- An editor incrementally reparses a reverse block after one keystroke and retains surrounding method nodes.
- A notebook highlights quantum resources, unitary methods, measurements, and reversible modifiers.
- A compiler diagnostic reports the exact line and column of an unresolved state or malformed gate.
- A course begins with Counter, then uses one XOR method both classically and coherently, then introduces Bell/QFT and measurement.
- A syntax-tree consumer can index declarations and calls without loading the compiler or a quantum provider.

## Goals

- Make whitespace and line wrapping non-semantic outside tokens and comments.
- Keep delimiters, keywords, and declaration shapes deterministic and easy to recover.
- Provide a maintained Tree-sitter grammar, corpus, highlight queries, and fold queries.
- Keep compiler and Tree-sitter examples synchronized in CI.
- Provide source line, column, and offset from lexical analysis onward.
- Organize executable examples into a documented teaching path.
- Use ASCII source for required syntax while permitting Unicode in comments and future identifiers deliberately.
- Make every conceptual transition explicit enough to explain and inspect.

## Non-goals

- Put type checking or target capability logic in Tree-sitter queries.
- Require one editor or language-server protocol implementation.
- Minimize character count at the cost of semantic clarity.
- Introduce symbolic quantum notation as required syntax.
- Teach provider APIs before portable Wheeler semantics.

## Terms and semantic model

The **concrete syntax tree** records source structure, delimiters, and recovery nodes. The **semantic model** resolves names, effects, ownership, inverse relationships, and target requirements. Tooling may rely on stable named syntax nodes but not on compiler-private Java classes.

A **teaching level** is a set of already implemented language features and examples, not a weaker execution mode. Code learned at an earlier level remains valid later.

## Ownership and boundaries

`wheeler-compiler` owns the authoritative lexical and semantic diagnostics used for compilation. `tree-sitter-wheeler` owns incremental concrete parsing and editor queries. WIP-0005 owns language meaning. Documentation and examples own the teaching sequence.

The two parsers share corpus source fixtures and a checked grammar contract, not generated implementation code. WIP-0016 owns the one fixed formatter style, lossless trivia boundary, and mandatory `///` file/function documentation policy; this WIP supplies the syntax and recovery contract it must not fork.

## Design

### Lexical contract

Comments are `//` or `/* ... */`. Identifiers use the documented ASCII profile initially. Numeric forms are explicit. Keywords are closed and provider-independent. Operators use longest-match tokenization. Tokens retain line, column, and source offset.

Whitespace, comments, and line breaks may occur between tokens. A statement does not need to occupy one line. Semicolons terminate simple statements; braces delimit classes, methods, and reverse blocks.

### Concrete tree

Named nodes include class, computation domain, member declaration, state declaration, qreg declaration, method declaration, modifiers, block, assignment, assertion, call, coherent application, reverse statement, call expression, qubit reference, numeric literal, identifier, and comments.

The grammar avoids semantic ambiguity. Whether a method call is classical, unitary, or invalid is resolved after parsing from declarations and effects.

### Error recovery

Class, method, and statement delimiters provide synchronization points. Compiler diagnostics fail closed and identify an expected token plus actual token location. Incremental tooling may retain `ERROR` nodes while users type.

### Teaching sequence

1. **Classical state:** fields, arithmetic, assertions, and deterministic execution.
2. **Reversible methods:** generated inverses, reverse calls/blocks, and history versus inverse.
3. **Coherent values:** an exact XOR permutation on a classical bit and quantum basis state.
4. **Unitary circuits:** H, controlled operations, QFT, and generated adjoints.
5. **Measurement:** affine consumption, classical observations, and sampling.
6. **Hybrid workflows:** parameter binding, jobs, replay, and target capabilities.
7. **Advanced systems:** dynamic correction, resource estimates, proofs, and future logical hardware.

Every level has at least one checked-in source file and an automated expected result.

## Reversibility and history

Syntax and teaching material consistently distinguish `reverse` from debugger rewind. `q.apply(method)` describes coherent lifting; unitary method reversal describes an adjoint. Measurement examples explain replay/retry rather than inverse collapse.

## Concurrency and determinism

Parsing is deterministic. The first teaching levels avoid concurrency. Draft WIP-0032 owns later `IoScope`, request, operation, batch, graph, selection, asynchronous, and required-concurrent syntax. Tooling must not copy Java threads or expose a backend poll state machine as the language merely because both have punctuation.

## Quantum and proof implications

Gate names are ordinary ASCII identifiers and qreg indexing is Java-shaped. Dirac notation may be added as optional sugar only with a canonical ASCII equivalent and tooling coverage. WIP-0011 proof syntax exposes contracts, theorem statements, propositions, proof terms, and experiment declarations as stable nodes; free-form justification text is not proof evidence.

## Bytecode, persistence, and compatibility

Concrete syntax is not bytecode. Syntax changes follow WIP migration rules and Tree-sitter corpus updates. Debug sections may retain source spans but canonical execution does not require source files.

## Safety, limits, and failures

The compiler bounds input bytes and characters, token and line counts, token width, declarations, and structured-block nesting before lowering. Block comments must close; identifiers use the required ASCII profile. Numeric overflow and malformed encodings produce diagnostics rather than partial artifacts. Tree-sitter editor hosts remain responsible for document-size policy; the repository gate applies the grammar to every bounded checked-in source.

## Migration and deletion

1. Replace line-oriented parsing with a token and recursive-descent parser.
2. Add `tree-sitter-wheeler` with corpus and editor queries.
3. Test multiline and compact formatting through both parsers.
4. Publish the concrete syntax and teaching sequence in reference documentation.
5. Delete temporary syntax and stale tutorial scaffolding.

## Progress

- [x] Compiler lexer records line, column, and offset and exposes one authoritative lossless token/trivia/comment range stream with exact reconstruction; syntax-node attachment and formatting remain WIP-0016.
- [x] Compiler parsing is formatting-independent.
- [x] Tree-sitter grammar, corpus, highlights, and folds exist.
- [x] The Gradle/CI gate runs both compiler and Tree-sitter corpus tests.
- [x] The implemented syntax and teaching path are published in reference documentation.
- [ ] Every teaching level has an executable example.

## Testing and acceptance

- [x] Compiler tests parse compact, multiline, and comment-heavy programs.
- [x] Lexer tests cover longest-match operators, comments, numeric forms, locations, ASCII identifiers, and hard source/token limits; parser tests cover the structured nesting ceiling.
- [x] Tree-sitter generates without conflicts and its initial corpus passes.
- [x] Every checked-in example parses without Tree-sitter `ERROR` nodes, compiles, and executes.
- [x] Highlight queries compile against the grammar; fold nodes are covered by generated node types.
- [x] Malformed delimiter fixtures recover in Tree-sitter and fail with source locations in the compiler.
- [x] The documentation teaches the currently implemented semantic boundaries in dependency order.

## Alternatives

### Continue line-oriented parsing

Rejected. It makes formatting semantic and produces poor editor recovery.

### Use the Java grammar unchanged

Rejected. It would parse many constructs Wheeler cannot type or execute and would hide Wheeler's computation domains and affine resource semantics.

### Use symbolic quantum notation as the primary grammar

Rejected. ASCII Java-shaped syntax is easier to type, teach, search, and support across tools. Mathematical notation can remain documentation or future optional sugar.

## Open questions

- When should the initial ASCII identifier profile expand to full Unicode identifier classes? — **Owner:** language and tooling maintainers — **Decide by:** before module/package syntax
- Which stable syntax-node compatibility policy begins with the first external editor integration? — **Owner:** tooling maintainers — **Decide by:** before grammar package release

## References

- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0016](WIP-0016-nonconfigurable-source-formatter.md)
- [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md)
- [WIP-0032](WIP-0032-unified-io-fabric-and-durability-receipts.md)
- [Language profile](../reference/language-profile.md)
- [`tree-sitter-wheeler`](../../../tree-sitter-wheeler/grammar.js)
