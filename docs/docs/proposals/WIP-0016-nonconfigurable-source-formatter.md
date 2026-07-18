# WIP-0016: Canonical source formatting and documentation

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler tools, compiler, syntax, documentation, and package maintainers |
| Created | 2026-07-18 |
| Updated | 2026-07-18 |
| Area | Source formatting, documentation comments, diagnostics, editor and build tooling |
| Depends on | WIP-0005, WIP-0006 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler will ship one deterministic formatter for `.w` source and one documentation-comment convention. The style is intentionally not configurable.

`//!` documents the containing source file or module. `///` documents the declaration that immediately follows it. `//` and `/* ... */` remain ordinary implementation comments. Documentation text is source-readable, line-oriented, and minimally structured: a required summary paragraph followed, when useful, by a small set of Wheeler-specific semantic facets such as effects, inverse behavior, coherent action, adjoint behavior, traps, and bounds.

The formatter preserves syntax, declaration order, literal bytes, comment payloads, and comment attachment. It applies fixed whitespace and local line-breaking rules, never reflows documentation prose, and either publishes a complete formatted file atomically or leaves the original untouched.

Formatting and documentation validation are separate operations over the same lossless concrete syntax. A valid but undocumented buffer can always be formatted. Documentation checks report missing or malformed documentation without changing source. Neither operation reads a style file, environment variable, editor preference, terminal width, locale, or other ambient host state.

## Motivation

Formatting arguments consume review time while producing no Wheeler semantics. A configurable formatter merely moves those arguments into a repository file and gives command-line tools, editors, CI, and package builds multiple opportunities to disagree. Wheeler already depends on deterministic artifacts, exact package inputs, stable diagnostics, and reproducible execution. Source layout should have one implementation and one answer.

A formatter can still fail maintainers if a small edit causes unrelated code to move. Whole-file optimal wrapping, column alignment, import reordering, and prose reflow create broad diffs, obscure semantic changes, and damage source history. Wheeler needs a fixed style whose decisions are local: editing one parameter list may reflow that list and its declaration header, but not neighboring declarations or comments.

Documentation needs a similarly narrow contract. JavaDoc-style tag inventories duplicate signatures and become stale. Unstructured comments do not give tools reliable attachment or help readers find Wheeler-specific semantic boundaries. Wheeler declarations may be ordinary, reversible, coherently liftable, unitary, effectful, bounded, or formally proved. Documentation should explain those observable distinctions without pretending that prose is a type, contract, theorem, or certificate.

The formatter must not enforce documentation coverage as a precondition to formatting. Editors need to format incomplete work, newly created declarations, and private helpers before their documentation is finished. Keeping formatting and documentation validation separate also gives each operation a simple deterministic contract.

## Use cases

1. A developer runs `wheeler format src`. Every syntactically valid `.w` file is rewritten with the same code layout on every host. Running the command again changes zero bytes.

2. CI runs `wheeler format --check .`. It reports every file whose formatted bytes differ, in stable path order, and writes nothing.

3. CI separately runs `wheeler check-docs .`. It requires file or module documentation and documentation on the public and semantic API surface, reports stable source diagnostics, and writes nothing.

4. An editor formats a complete in-memory buffer after adding one argument. Only the smallest enclosing layout groups whose fit decisions changed may change line structure. Documentation prose, neighboring declarations, imports, and unrelated statement groups remain byte-identical.

5. A developer writes a new private helper without documentation. The buffer still formats. Documentation checking accepts the helper unless its visibility or execution kind makes it part of the required documented surface.

6. A `coherent rev` method has a summary but does not explain its coherent basis-state action. Documentation checking identifies the declaration and the missing `Coherent` facet. It does not generate text or infer prose from bytecode.

7. A source file has malformed syntax, an unterminated comment, unsafe path traversal, or exhausted formatter limits. Write mode publishes no output for the invocation. Check modes write nothing.

## Goals

- Provide one formatter implementation and one nonconfigurable style for Wheeler source.
- Make formatting deterministic, idempotent, bounded, formatting-independent, and independent of ambient host state.
- Keep diffs local by preserving source order, literal content, comment payloads, comment attachment, and stable layout groups.
- Define distinct file or module documentation and declaration documentation without adding runtime semantics.
- Make documentation readable in source before it is rendered by a tool.
- Require meaningful summaries on the public and Wheeler-semantic API surface without requiring boilerplate on every private helper.
- Give reversible, coherent, unitary, effectful, trapping, bounded, and proved behavior a consistent vocabulary.
- Avoid duplicating parameter types, return types, modifiers, contracts, or theorem statements in prose.
- Use one lossless concrete-syntax boundary for formatting, documentation attachment, editor integration, and diagnostics.
- Support atomic file replacement and read-only CI check modes.
- Reach a Wheeler-written implementation under the self-hosting toolchain.

## Non-goals

- User-, repository-, organization-, package-, or editor-configurable style.
- Reordering imports, declarations, fields, methods, theorem clauses, variant cases, match arms, or statements.
- Renaming identifiers, rewriting literals, normalizing Unicode, editing documentation prose, or performing semantic refactors.
- Repairing malformed programs or formatting parser recovery nodes as if they were valid source.
- Requiring documentation on every private ordinary helper.
- Requiring one tag per parameter or restating types already present in the declaration.
- Treating comments as formal preconditions, postconditions, proof terms, certificates, or effect declarations.
- Inventing documentation summaries, stubs, examples, or semantic facets.
- Implementing a complete Markdown or HTML engine in the formatter.
- Defining the final generated API-documentation site, search index, package publication format, or cross-package link resolver.
- Formatting `wheeler.package`, `wheeler.workspace`, `wheeler.lock`, `.wbc`, `.wpk`, build plans, JSON, Markdown, or OpenQASM.
- Range formatting in the first implementation. Editors format a complete in-memory file and apply the returned minimal text edit.
- Formatter-disabling directives such as `fmt: off`.
- Enforcing a particular natural language, spelling dictionary, or prose grammar.

## Terms and semantic model

A **source token** is a compiler-lexed token with an exact byte range and source location.

**Trivia** is whitespace or a comment between source tokens. Trivia has exact bytes and an attachment to a containing or neighboring syntax node.

A **lossless concrete syntax tree** records every token, delimiter, whitespace range, comment range, and recovery status required to reproduce the source. A semantic AST is not lossless enough for formatting.

A **layout group** is the smallest syntax-owned sequence allowed to choose horizontal or vertical form. Parameter lists, argument lists, declaration headers, expressions, match arms, and blocks are layout groups. Groups nest but do not capture sibling declarations or unattached comments.

A **file documentation block** is one or more consecutive line comments beginning with `//!`. It documents the containing file. When the file has a `module` declaration, it is also the module documentation for that source unit. In a moduleless file, it documents the top-level computation-domain class.

A **declaration documentation block** is one or more consecutive line comments beginning with `///`. It documents the declaration that immediately follows the block.

A **documentation payload** is the text after the `//!` or `///` marker and its optional one delimiter space. Marker indentation and delimiter spacing are not payload.

A **summary** is the first nonempty paragraph of a documentation block.

A **semantic facet** is an optional final list item with a reserved label such as `Effects`, `Inverse`, `Coherent`, `Adjoint`, `Traps`, or `Bounds`. Facets summarize observable behavior; they are not executable contracts.

A **required documented declaration** is a declaration for which `check-docs` requires an attached nonempty `///` block. The initial set is defined below.

Formatting and documentation checking are separate deterministic functions:

```text
format(style_version, valid_utf8_source) -> formatted_utf8_source

check_docs(documentation_version, valid_utf8_source)
    -> ordered documentation diagnostics
```

For every accepted input `s`, formatting obeys:

```text
parse(format(s)) = parse(s)
format(format(s)) = format(s)

token_spelling(format(s)) = token_spelling(s)
literal_bytes(format(s)) = literal_bytes(s)
declaration_order(format(s)) = declaration_order(s)
statement_order(format(s)) = statement_order(s)

comment_payloads(format(s)) = comment_payloads(s)
comment_kinds(format(s)) = comment_kinds(s)
comment_attachments(format(s)) = comment_attachments(s)
```

Documentation checking obeys:

```text
documented_targets(format(s)) = documented_targets(s)
documentation_payloads(format(s)) = documentation_payloads(s)
diagnostic_codes_by_target(format(s)) = diagnostic_codes_by_target(s)
```

Source locations may change after formatting, but the same declarations receive the same documentation diagnostic codes.

## Ownership and boundaries

The compiler lexer and concrete parser own tokenization, accepted syntax, exact source ranges, delimiter recovery, and the distinction between valid syntax and recovery nodes.

The lossless concrete-syntax layer owns trivia ranges and stable attachment of leading, trailing, inner, and detached comments. It is shared by the formatter and documentation checker. Wheeler does not maintain a second formatter grammar or a second documentation attachment parser.

The formatter owns code whitespace, code line breaks, indentation, blank-line normalization, and formatted UTF-8 bytes. It does not own declaration visibility, name resolution, type checking, proof checking, package resolution, or documentation quality.

The documentation checker owns `//!` and `///` placement, required coverage, summary presence, reserved-facet structure, and documentation diagnostics. It may inspect declaration syntax and modifiers. The first implementation does not need semantic name resolution or cross-reference resolution.

The compiler and proof kernel remain authoritative for types, effects, reversibility, generated inverses, generated adjoints, ownership, contracts, theorem validity, and certificates. Documentation may describe those facts but cannot establish them.

The `wheeler` command owns path selection, physical-file validation, bounded reads, sorted traversal, check-mode reporting, sibling temporary files, and atomic replacement.

Editor integrations invoke the same in-memory formatter and documentation-checker libraries. They do not reproduce the style or attachment rules in TypeScript, Lua, Emacs Lisp, or editor configuration.

Package and CI tooling pin the exact formatter and documentation-checker identity. A package may choose whether a repository gate invokes formatting and documentation checks, but it cannot select style options or redefine documentation syntax.

A future documentation renderer consumes the same attached documentation model. Rendering, search, cross-package links, and publication are not authoritative sources for attachment or coverage.

## Design

### Command surface

The initial formatter command forms are:

```text
wheeler format <file-or-directory>...
wheeler format --check <file-or-directory>...
wheeler format --stdin
wheeler format --stdin --check
```

The initial documentation-check command forms are:

```text
wheeler check-docs <file-or-directory>...
wheeler check-docs --stdin
```

`format --check` checks formatting only. `check-docs` checks documentation only. A repository or package gate may invoke both.

Directories are walked through physical nonsymlink paths in lexical logical-path order and include only `.w` files. Duplicate paths after normalization are rejected. `--stdin` reads one bounded strict-UTF-8 document. Formatter stdin mode writes formatted bytes to standard output unless `--check` is present. Documentation stdin mode writes diagnostics only.

Unknown options fail. There is no short alias, configuration discovery, exclusion glob, line-width option, project style, documentation bypass, editor-specific mode, locale-sensitive mode, or network-backed resolver.

Generated checked-in Wheeler source follows the same rules as handwritten checked-in source. Disposable generated output may skip the tools; once committed, it has joined the maintained source surface.

### Fixed code whitespace

The first style version uses these rules:

- strict UTF-8 input;
- LF line endings;
- no trailing whitespace;
- exactly one final newline;
- four ASCII spaces per indentation level;
- no tab indentation;
- opening braces on the declaration or control-header line;
- an empty block formatted as `{}` when it contains no comment;
- one statement and one `const` declaration per line;
- one finite-enum case per line, with source order preserved;
- one ASCII space around binary and assignment operators;
- one ASCII space after commas;
- no space immediately inside parentheses or brackets;
- no space before a call or index opener;
- module and import declarations each on their own line;
- one blank line between file documentation, a module declaration, the import group, and the first top-level declaration when those groups exist;
- one blank line between named top-level or member declarations;
- no blank line between a `///` block and its declaration;
- at most one author-supplied blank line between statement groups;
- no column alignment across sibling declarations or assignments;
- a soft code-line target of 100 Unicode scalar values, excluding indivisible literal and comment tokens.

The 100-scalar target is fixed and is not a display-column promise. Tabs, combining marks, emoji width, East Asian display width, terminal settings, and font metrics do not become formatter inputs. A literal or preserved comment may exceed the target.

Documentation payload is not automatically wrapped to the code-line target.

### Stable line breaking

Every layout group has an ordered syntax-defined set of legal forms. The formatter chooses without consulting sibling layout groups.

A group remains horizontal when:

- its horizontal form fits the fixed target;
- it contains no line comment;
- it contains no source-significant blank-line boundary;
- none of its children requires vertical form.

Otherwise the formatter chooses the first vertical form defined for that construct.

A vertical comma-separated list places one syntactic item per line, indents items one level, and places its closing delimiter on a stable line. The formatter does not pack multiple short items after another item has forced vertical form.

For example:

```java
long emitNumber(
    utf8 source,
    words tokenStarts,
    words tokenLengths,
    bytes output
) {
    ...
}
```

A change may reflow the smallest group whose fit decision changed and enclosing headers required by indentation or delimiters. It may not reflow sibling statements, sibling declarations, unrelated imports, or attached documentation.

The printer never performs whole-file optimal wrapping, aligns unrelated tokens, sorts source, or chooses a layout based on the longest sibling name.

Golden fixtures, rather than an implementation-specific pretty-printing library, define the complete layout table for each accepted syntax construct.

### Ordinary comments

`//` is the preferred implementation-comment form.

A standalone implementation comment appears at the indentation of the code it explains. It should explain a non-obvious invariant, reason, boundary, or choice rather than narrate the next token.

A trailing `//` comment remains attached to the statement or declaration on which it was written. The formatter does not move it merely to satisfy the soft line target. New explanatory comments should normally be placed on their own preceding line.

`/* ... */` remains valid ordinary comment syntax. Its body is byte-preserved except for line-ending normalization. Block comments are not documentation comments and are not automatically reflowed.

Documentation must not use `/** ... */`. Wheeler uses line-oriented documentation so adding or removing one documentation line does not modify a closing delimiter or reindent an entire block.

There is no formatter suppression comment. Source that cannot be expressed in the fixed style is a formatter design bug or a language-design issue, not a local configuration opportunity.

### File and module documentation

A file documentation block uses `//!`.

It must be the first non-BOM content in a source file. Ordinary comments, declarations, or imports may not precede it. The block may contain internal blank documentation lines, written as `//!`.

Example:

```java
//! Bounded scanner and parser for Wheeler source tokens.
//!
//! This module converts strict UTF-8 source into token metadata.
//! It owns lexical limits and source diagnostics; name resolution belongs to the compiler.

module examples.lexer.scanner;
```

The first paragraph states the file or module responsibility. Additional paragraphs should explain boundaries, owned state or resources, public surface, important invariants, or what the module deliberately does not own. They should not repeat the module name, import list, changelog, or repository path.

A required file documentation block must contain a nonempty summary.

### Declaration documentation

A declaration documentation block uses `///`.

The block attaches to the next declaration. No blank line, ordinary comment, other declaration, or statement may occur between the block and its target. Attributes and modifiers, when implemented, are part of the target declaration and follow the documentation block.

Example:

```java
/// Returns the Unicode scalar beginning at byte `offset`.
///
/// `offset` names a leading UTF-8 byte, not a scalar index.
///
/// - Traps: If `offset` is out of range or the bytes are malformed.
/// - Bounds: Reads at most four bytes and allocates nothing.
long scalarAt(utf8 text, long offset) {
    return utf8Scalar(text, offset);
}
```

The first paragraph is a concise summary of observable purpose. For a callable declaration, it normally begins with a present-tense verb such as “Returns,” “Decodes,” “Applies,” “Measures,” or “Restores.” It does not begin with “This function,” reproduce the declaration, or merely expand the identifier into words.

Following prose explains only information a reader cannot reliably recover from the signature, types, modifiers, formal contracts, or theorem statement. Useful subjects include:

- units, encodings, coordinate systems, and index domains;
- ownership or borrowing consequences not obvious from the type spelling;
- state and resource transitions;
- measurement, target submission, commit, replay, retry, or other irreversible boundaries;
- the meaning of a result rather than its type;
- caller-relevant trap conditions;
- hard execution or resource bounds;
- the relationship to an inverse, coherent lift, adjoint, theorem, or certificate.

Documentation should not enumerate every parameter merely because it exists. Parameter names are written in backticks when discussed in prose. A parameter list is appropriate only when several parameters have non-obvious, distinct semantic roles.

### Documentation text profile

Documentation payload uses a deliberately small source-readable markup profile:

- paragraphs separated by a blank documentation line;
- inline code spans using backticks;
- unordered lists using `-`;
- ordered lists using decimal numbers;
- fenced code blocks using triple backticks;
- inline links using `[label](target)`.

Raw HTML, tables, heading syntax, reference-style links, footnotes, embedded scripts, and renderer-specific directives are outside the first profile. A renderer treats unsupported constructs as escaped text rather than executable markup.

Fenced Wheeler examples use the `wheeler` information string when practical:

````java
/// Applies a reversible increment.
///
/// ```wheeler
/// increment();
/// reverse increment();
/// ```
````

The formatter preserves documentation payload exactly and does not format fenced examples recursively.

Authors should use semantic line breaks: one sentence or list item per source line when practical. The formatter does not use natural-language parsing and does not enforce sentence boundaries. It never rewraps prose merely because a nearby edit changes indentation or line width.

Nonempty documentation lines use exactly one ASCII space after the marker:

```text
//! Text
/// Text
```

A blank documentation line contains only the marker:

```text
//!
///
```

The formatter normalizes marker indentation and delimiter spacing while preserving the payload. It never changes wording, punctuation, code spans, links, list markers, or fenced content.

### Semantic facets

A declaration documentation block may end with a **semantic facet list**. Each facet is one unordered-list item with a reserved label.

The initial labels, in canonical order, are:

1. `Inputs`
2. `Returns`
3. `Effects`
4. `Inverse`
5. `Coherent`
6. `Adjoint`
7. `Traps`
8. `Bounds`
9. `Proof`
10. `See also`

Example:

```java
/// Increments `count` by one.
///
/// - Effects: Mutates `count`.
/// - Inverse: Decrements `count` by one.
/// - Traps: Before mutation when `count` is `Long.MAX_VALUE`.
rev void increment() {
    count += 1;
}
```

Facets are optional unless required by declaration kind below. Empty facets, duplicate facets, and facets outside canonical order are documentation diagnostics.

Facet meanings are:

- `Inputs`: non-obvious units, encodings, valid domains, alias relationships, or caller obligations not already expressed as a formal contract;
- `Returns`: the semantic meaning of a result when the summary does not already make it clear;
- `Effects`: observable mutation, allocation, ownership transition, host I/O, measurement, target submission, commit, replay, retry, or other effect;
- `Inverse`: the forward declaration's generated or declared inverse behavior;
- `Coherent`: the exact basis-state action, width assumptions, and clean-resource behavior of coherent lifting;
- `Adjoint`: the unitary declaration's adjoint behavior;
- `Traps`: stable caller-relevant conditions that trap before or after specified effects;
- `Bounds`: source-level hard limits, static bounds, or useful asymptotic resource behavior;
- `Proof`: names of formal Wheeler theorems or certificates relevant to the described behavior;
- `See also`: closely related declarations or reference material.

The facet vocabulary is intentionally Wheeler-specific. Documentation says “traps,” “inverse,” “adjoint,” “rewind,” “uncompute,” “replay,” and “retry” according to their language meanings. It does not use “throws,” “undo,” or “rollback” as interchangeable substitutes.

A `Proof` facet may identify checked evidence, but the comment is not evidence. A stale or false `Proof` facet cannot create, satisfy, or replace a contract, theorem, proof term, or certificate.

### Documentation coverage

Every checked source file requires one nonempty `//!` block.

The initial declaration set requiring nonempty attached `///` documentation is:

- every `public` class, record, variant, function, method, theorem, experiment, state declaration, or quantum-register declaration supported by the source profile;
- every `entry` declaration, regardless of visibility;
- every `rev` declaration, regardless of visibility;
- every `coherent rev` declaration, regardless of visibility;
- every `unitary` declaration, regardless of visibility;
- every theorem or experiment declaration, regardless of visibility.

A file-level `//!` block satisfies the documentation requirement for the containing module or the sole moduleless top-level class. The same class is not required to repeat identical `///` documentation immediately below the file block.

Private ordinary helpers and private data declarations are not required to have documentation. They should receive `///` documentation when they expose a non-obvious local contract that callers need, and `//` comments when the explanation concerns implementation rather than API behavior.

The initial required semantic facets are:

- `entry` requires `Effects`;
- `rev` requires `Inverse`;
- `coherent rev` requires both `Inverse` and `Coherent`;
- `unitary` requires `Adjoint`.

A declaration may satisfy more than one rule. For example, `coherent rev` requires one documentation block containing both facets in canonical order.

The checker does not initially require `Inputs`, `Returns`, `Traps`, `Bounds`, or `Proof`, because determining whether those facets are useful is partly semantic and partly editorial. Public library review should require them when omission would make observable behavior unclear.

Documentation coverage is a repository and package-quality rule, not a source-language typing rule. The compiler may compile valid undocumented source when documentation checking is not requested. Documentation does not affect runtime behavior or semantic bytecode identity.

### Examples

An ordinary function:

```java
/// Returns the number of Unicode scalars in `text`.
///
/// - Traps: If `text` is not strict UTF-8.
long scalarCount(utf8 text) {
    return utf8Count(text);
}
```

A reversible method:

```java
/// Adds one to `count`.
///
/// - Effects: Mutates `count`.
/// - Inverse: Subtracts one from `count`.
/// - Traps: Before mutation when addition would overflow.
rev void increment() {
    count += 1;
}
```

A coherently liftable method:

```java
/// Toggles `bit`.
///
/// - Effects: Mutates `bit`.
/// - Inverse: Applies the same XOR operation.
/// - Coherent: Acts as the exact basis permutation `0 ↔ 1`.
coherent rev void flip() {
    bit ^= 1;
}
```

A unitary method:

```java
/// Applies the quantum Fourier transform to `q`.
///
/// - Effects: Changes amplitudes without measurement.
/// - Adjoint: Applies the inverse transform in reverse gate order.
/// - Bounds: Uses a statically bounded number of semantic gates.
unitary void qft() {
    ...
}
```

An entry point:

```java
/// Tokenizes `source` and writes the numeric token to `output`.
///
/// - Effects: Mutates result state and the caller-provided output borrow.
/// - Traps: On malformed input, invalid token ranges, or insufficient output capacity.
entry void main(utf8 source, bytes output) {
    ...
}
```

An implementation comment:

```java
// Preserve the lexical offset so parser diagnostics refer to the original source.
long declarationStart = cursor;
```

A poor declaration comment:

```java
/// Increment method.
///
/// - Inputs: None.
/// - Returns: void.
rev void increment() {
    count += 1;
}
```

The poor comment repeats syntax, omits the mutated state, and fails the required `Inverse` facet.

### Diagnostics

Formatter diagnostics use the `WFMT` namespace. Documentation diagnostics use the `WDOC` namespace. Codes and primary source ranges are stable tool APIs; explanatory wording may improve.

The initial documentation diagnostics include:

```text
WDOC001 path:1:1 source file requires nonempty //! documentation
WDOC002 path:18:5 declaration 'increment' requires /// documentation
WDOC003 path:17:5 documentation block requires a nonempty summary
WDOC004 path:17:5 /// documentation must be adjacent to a declaration
WDOC005 path:1:1 //! documentation must be the first source content
WDOC006 path:17:5 duplicate or out-of-order documentation facet 'Effects'
WDOC007 path:18:5 rev declaration 'increment' requires an Inverse facet
WDOC008 path:18:5 coherent declaration 'flip' requires a Coherent facet
WDOC009 path:18:5 unitary declaration 'qft' requires an Adjoint facet
WDOC010 path:18:5 entry declaration 'main' requires an Effects facet
```

A misplaced `//!` block, an unattached `///` block, or a mixed `//!` and `///` block is invalid documentation attachment. It remains ordinary comment trivia to the compiler unless documentation checking is requested.

Documentation checking reports all diagnostics in source order within each file and canonical path order across files. It writes nothing.

### Formatter publication and minimal diffs

The formatter parses and formats a complete file in memory before opening an output. If formatted bytes equal input bytes, it performs no write.

For filesystem write mode, the command:

1. validates every requested path and reads every bounded input;
2. parses and formats every file;
3. aborts before publication if any input fails;
4. writes changed outputs to bounded sibling temporary files;
5. flushes and validates each temporary file;
6. preserves ordinary permission bits where supported;
7. atomically replaces destinations in canonical path order.

A host crash during publication may leave a sorted prefix updated. Rerunning converges because formatting is idempotent. The command does not claim a multi-file filesystem transaction.

Symlinks, nonregular files, escaping paths, duplicate normalized paths, oversized inputs, unsafe temporary paths, and replacement races fail closed.

`format --check` reports every differing path in canonical order and exits nonzero. It writes no file and does not run documentation validation.

`check-docs` writes no file and does not require already formatted input.

### Editor and tooling API

The formatter library accepts explicit UTF-8 bytes and returns either:

- formatted UTF-8 bytes plus a deterministic minimal text edit; or
- source-located syntax, limit, or formatting diagnostics.

The initial minimal edit is the longest common byte prefix and suffix around the complete formatted replacement. A later edit-list protocol may provide multiple nonoverlapping edits only if applying them produces exactly the same formatted bytes.

The documentation checker accepts the same explicit UTF-8 bytes and returns attached documentation records plus diagnostics. Each record includes:

- documentation kind: file or declaration;
- target syntax kind and source range;
- exact payload bytes;
- summary range;
- recognized facets and their ranges.

Tree-sitter queries expose file and declaration documentation as documentation-comment captures while retaining ordinary comment captures. Tree-sitter is not the validity authority.

## Reversibility and history

Formatting bytes in memory is a pure deterministic transformation and requires no VM history.

Documentation checking is a pure deterministic validation and requires no VM history.

Replacing a host file is an explicit irreversible effect owned by the command driver. The driver does not describe a filesystem rename as a `rev` operation.

A failed parse, format, bounded write, temporary-file validation, or prepublication path check leaves destination bytes unchanged. After successful replacement, reversal means restoring caller-owned bytes or version-control state; it is not VM rewind.

Documentation comments describing an inverse, adjoint, rewind, replay, retry, or uncomputation do not perform or prove that operation.

## Concurrency and determinism

One invocation traverses files in canonical logical-path order. Formatting one file has no dependency on another file's content, timestamp, editor state, or task schedule.

Implementations may parse or format files concurrently only when outputs, diagnostic ordering, and publication order are byte-for-byte equivalent to serial canonical-order execution.

Documentation checking may run concurrently under the same ordering rule.

Concurrent writers to the same path are outside the formatter state machine. The command detects replacement races when the host exposes stable file identity and otherwise relies on the atomic-replace boundary. It never merges concurrent edits.

No formatting or documentation result depends on wall-clock time, random values, locale, network access, user identity, home-directory contents, terminal size, or provider state.

## Quantum and proof implications

Formatting does not alter quantum state, circuit semantics, generated adjoints, proof terms, certificates, or the trusted proof kernel.

Documentation has no quantum or proof authority. `Inverse`, `Coherent`, `Adjoint`, and `Proof` facets are explanatory indexes into language semantics and checked declarations. They cannot make an irreversible method reversible, make a classical function coherent, establish unitarity, or satisfy a theorem.

Conformance compiles source before and after formatting and requires byte-identical semantic `.wbc` where source locations and optional debug text are excluded from semantic identity.

Documentation terminology must keep distinct:

- language-level inverse execution;
- VM history rewind;
- coherent uncomputation;
- unitary adjoint;
- measurement;
- replay of recorded observations;
- retry as fresh execution;
- formal theorem evidence;
- empirical experiment evidence.

## Bytecode, persistence, and compatibility

No bytecode instruction, semantic section, VM state, quantum region, or runtime persistence format changes.

Comments and documentation do not affect semantic `.wbc` identity. Optional debug or documentation artifacts may retain source ranges and payloads, but the VM does not require them for execution.

Formatter style and documentation structure are versioned tool behavior, not source directives embedded into `.w` files.

A deliberate style or documentation-structure change requires this WIP or a successor to return to Review, conformance fixtures to change, and one isolated repository-wide mechanical migration. The formatter does not retain old style modes.

Package locks and CI pin exact tool identity. Source archives preserve exact comments as source bytes; generated documentation artifacts, if introduced, use a separately specified canonical format.

## Safety, limits, and failures

The formatter and documentation checker impose explicit ceilings on:

- input bytes and Unicode scalar values;
- tokens and syntax nodes;
- nesting depth;
- individual and aggregate comment payload bytes;
- output bytes;
- files per invocation;
- total traversal and formatting work.

Defaults align with compiler and package ceilings where practical. They are host-policy and tool-version limits, not source directives.

Input must be strict UTF-8. Invalid encoding, malformed syntax, parser recovery nodes, unclosed comments, exhausted limits, unsafe paths, unknown options, and publication failures produce nonzero status.

Formatter write mode performs no replacement for the invocation when validation fails before publication. Check modes never write.

The tools do not execute Wheeler source, expand macros, resolve imports, invoke theorem automation, submit target jobs, access a network, read credentials, inspect the home directory, or invoke provider SDKs.

Documentation payload is treated as inert text. Renderers escape unsupported markup and never execute raw HTML or scripts.

## Migration and deletion

1. Extend the compiler concrete-syntax boundary to retain every token, whitespace range, comment payload, comment kind, and attachment needed by formatting and documentation checking.

2. Add `//!` and `///` recognition to compiler tooling and Tree-sitter queries without changing runtime comment semantics.

3. Specify shared golden corpora for fixed formatting, local line breaking, comment attachment, documentation attachment, semantic facets, and diagnostics.

4. Implement the fixed-layout engine and in-memory formatter API in the stage-0 tools module.

5. Implement the documentation attachment and validation API separately over the same lossless tree.

6. Add `wheeler format`, `--check`, `--stdin`, `wheeler check-docs`, physical path validation, bounded traversal, and atomic publication.

7. Add `//!` documentation to every checked-in `.w` file and `///` documentation to every required declaration. Make documentation changes in reviewable semantic commits.

8. Format the complete source tree in a separate mechanical commit so review can distinguish prose decisions from whitespace changes.

9. Make CI run formatter and documentation checks while stage 0 remains the oracle.

10. Port the concrete tree, formatter, documentation checker, and diagnostics to Wheeler using the WIP-0007 bootstrap substrate.

11. Differentially run stage 0 and Wheeler over the complete corpus, generated whitespace variants, comment-heavy cases, Unicode documentation, and malformed inputs until outputs and diagnostics agree byte-for-byte.

12. Delete stage-0 and duplicate editor formatting or documentation paths at native cutover.

## Progress

- [x] The authoritative compiler lexer exposes an ordered lossless stream of exact token, whitespace, line-comment, and block-comment ranges with one-based locations; reconstruction is byte-for-byte, including CRLF and comment payloads, and malformed comments fail through the compiler diagnostic boundary.
- [ ] Lossless concrete syntax attaches those retained comments and trivia stably to syntax nodes. A token stream is necessary; calling it a tree would merely annoy the branches.
- [ ] Golden fixed-style and minimal-diff corpora are accepted.
- [ ] `//!` and `///` attachment fixtures are accepted.
- [ ] Documentation summary, coverage, and semantic-facet diagnostics are stable.
- [ ] `wheeler format`, `--check`, and `--stdin` implement bounded deterministic behavior.
- [ ] `wheeler check-docs` implements bounded deterministic validation.
- [ ] Every checked-in `.w` file and required declaration is documented.
- [ ] Every checked-in `.w` file is formatted.
- [ ] Editor integrations call shared libraries rather than reproduce rules.
- [ ] A Wheeler-written formatter and documentation checker match stage 0 byte-for-byte.
- [ ] Stage-0 and duplicate tooling paths are deleted at native cutover.

## Testing and acceptance

- [ ] Every accepted formatting fixture satisfies parse preservation, token and literal preservation, order preservation, comment-payload preservation, comment-kind preservation, comment-attachment preservation, and idempotence.

- [ ] Adding, removing, or renaming one list item changes only its smallest enclosing layout groups outside unavoidable source-location shifts.

- [ ] Compact, multiline, deeply nested, comment-heavy, Unicode, reversible, coherent, unitary, proof, module, and malformed fixtures are covered.

- [ ] Every checked-in `.w` file has one nonempty first-content `//!` block.

- [ ] Every required declaration has one adjacent nonempty `///` block.

- [ ] Public, entry, reversible, coherent, unitary, theorem, and experiment coverage rules have positive and negative fixtures.

- [ ] Required `Effects`, `Inverse`, `Coherent`, and `Adjoint` facets have exact positive and negative fixtures.

- [ ] Missing, empty, misplaced, detached, mixed-kind, duplicate-facet, and out-of-order-facet cases produce exact `WDOC` diagnostics.

- [ ] A private ordinary helper without `///` documentation remains valid for both formatting and documentation checking.

- [ ] Documentation payload, semantic line breaks, lists, links, and fenced blocks survive formatting byte-for-byte.

- [ ] Formatting before compilation produces byte-identical semantic `.wbc` to compilation before formatting across the source corpus.

- [ ] `format --check` writes no files, does not run documentation checks, and reports paths in canonical order.

- [ ] `check-docs` writes no files, accepts unformatted valid source, and reports paths and declarations in canonical order.

- [ ] Write mode avoids touching already formatted files and atomically replaces changed physical files.

- [ ] Malformed UTF-8, syntax failure, unsafe paths, exhausted limits, and prepublication failures leave original bytes unchanged.

- [ ] LF, final-newline, indentation, and code-layout normalization are host-independent.

- [ ] Configuration files, environment variables, locale, terminal width, editor settings, and network state cannot alter output or diagnostics.

- [ ] Stage-0 and Wheeler implementations agree byte-for-byte on formatting and by code, target, and source range on documentation diagnostics.

- [ ] Current tooling and language-reference documentation describe implemented commands and comment conventions only after the acceptance suite passes.

## Alternatives

### Support a small configuration file

Rejected. Small configuration formats reproduce through mitosis. More importantly, configuration makes source layout depend on ambient package discovery and complicates editor, CI, vendored dependency, bootstrap, and source-identity behavior.

### Use `///` for both file and declaration documentation

Rejected. Attachment would depend on whether a module declaration exists and on the position of imports or the first declaration. Distinct `//!` and `///` markers make containing-file and following-declaration intent explicit to readers and tools.

### Use JavaDoc-style `/** ... */` documentation

Rejected. Wheeler is Java-shaped but not Java. Block documentation makes line insertion touch a closing delimiter, encourages tag inventories that duplicate signatures, and complicates minimally local edits.

### Require `@param`, `@return`, and `@throws` tags

Rejected. Types, parameter names, return types, and Wheeler traps already have authoritative language representations. Mandatory tag inventories reward duplication rather than explanation and use host-language terminology that does not fit inverse, coherent, unitary, ownership, or bounded semantics.

### Require documentation on every private helper

Rejected. Tiny private helpers are often clearer from names, types, and nearby code. Mandatory comments would produce paraphrases rather than knowledge. The required surface instead follows visibility and Wheeler-specific execution boundaries.

### Make missing documentation a formatter error

Rejected. Formatting must remain usable on incomplete work and must be a total transformation over valid syntax. Documentation validation is deterministic but separate. CI may invoke both operations.

### Generate documentation stubs

Rejected. `/// TODO` is not documentation, and generated paraphrases convert missing knowledge into plausible noise. The checker identifies the accountable declaration and stops.

### Permit a format-only suppression directive

Rejected. A local escape creates multiple styles and makes the formatter's output depend on user-maintained control comments. Constructs the formatter cannot handle must be fixed in the formatter or language.

### Reflow documentation to the code-line target

Rejected. Prose reflow turns a one-word edit into a paragraph diff and depends on markup and natural-language interpretation. Authors use semantic line breaks; the formatter preserves them.

### Use full CommonMark or raw HTML in source docs

Rejected for the first profile. A large renderer is unnecessary for source-readable API documentation and expands the bootstrap and security surface. The small profile can be extended deliberately later.

### Use Tree-sitter as the only formatter parser

Rejected as the validity authority. Tree-sitter remains essential for editors and recovery tests, but compiler-compatible lossless concrete syntax decides whether Wheeler source is valid.

### Pretty-print the semantic AST

Rejected. The semantic AST intentionally discards trivia and may normalize distinctions the formatter must preserve. Reconstructing comments after that loss creates wandering comments or a second attachment language.

### Reorder imports and declarations

Rejected. Ordering may be semantically constrained, and even harmless sorting creates broad diffs outside the edited construct. The compiler should diagnose invalid order; the formatter should not move code while pretending to add spaces.

### Preserve all user line breaks

Rejected. That is an indentation fixer rather than a formatter and leaves syntactic layout to personal taste. The chosen compromise owns code layout groups while preserving documentation prose, comment payloads, and one intentional statement-group separator.

## Open questions

- Should public variant cases receive individual required `///` documentation once the concrete grammar gives case comments stable attachment, or should the containing variant documentation remain sufficient? — **Owner:** language and documentation maintainers — **Decide by:** before WIP acceptance

- Should `wheeler check` eventually compose compilation, formatting verification, and documentation checking, or should repositories invoke the three commands explicitly? — **Owner:** package and tools maintainers — **Decide by:** before CI integration

- Which code-reference syntax and resolution rules should a future generated-documentation renderer use across modules and packages? — **Owner:** documentation, package, and language-server maintainers — **Decide by:** before documentation rendering is proposed

## References

- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0011](WIP-0011-integrated-proofs-and-certificates.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [WIP-0017](WIP-0017-compile-time-constants-and-finite-enums.md)
- [Language profile](../reference/language-profile.md)
- [Development and testing](../reference/development.md)
