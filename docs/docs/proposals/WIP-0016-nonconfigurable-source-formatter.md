# WIP-0016: One Wheeler source formatter

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler tools, compiler, syntax, documentation, and package maintainers |
| Created | 2026-07-18 |
| Updated | 2026-07-18 |
| Area | Source formatting, documentation policy, diagnostics, editor and build tooling |
| Depends on | WIP-0005, WIP-0006, WIP-0007, WIP-0009, WIP-0012 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler will ship one deterministic formatter for `.w` source. Its style is intentionally not configurable. The formatter preserves syntax, comments, declaration order, and literal bytes; applies fixed whitespace and local line-breaking rules; requires a file documentation header and documentation comments on every named method or function; and either publishes the complete formatted file atomically or leaves the original untouched.

The command is `wheeler format`. `--check` selects verification instead of publication. Neither mode reads a project style file, environment variable, editor preference, terminal width, locale, or phases of the moon.

## Motivation

Formatting arguments consume review time while producing no Wheeler semantics. A configurable formatter merely moves the argument into a repository file and then gives every editor plugin a chance to interpret it differently. Wheeler already requires canonical artifacts, deterministic package records, and exact replay. Source layout should be less imaginative than the runtime.

The tool must also avoid the opposite failure: a “canonical” printer that rewrites an entire file because one argument was added. Large formatting diffs conceal semantic edits and make `git blame` useful mainly as a weather report. Wheeler needs a fixed style whose layout decisions are local and whose comments remain attached to the syntax they document.

Documentation is part of that maintenance contract. A formatter cannot write an honest function summary by inspecting an opcode list, and it must not manufacture one. It can, however, reject undocumented files and functions with exact source locations. Requiring documentation in the same tool gives editors, CI, and package builds one answer instead of a formatter, linter, and hopeful reviewer each implementing a third of the rule.

## Use cases

1. A developer runs `wheeler format src`. Every valid documented `.w` file is rewritten with the same whitespace on every host. Running the command again changes zero bytes.
2. CI runs `wheeler format --check .`. It reports the first differing byte range for badly formatted files and stable diagnostics for missing file or function documentation, without modifying the checkout.
3. An editor formats a complete buffer after a local edit. Only the smallest enclosing layout groups may change line structure; unrelated imports, declarations, comments, and statement groups remain byte-identical.
4. A source file has malformed syntax, an unterminated comment, or a method without `///` documentation. The formatter publishes nothing for that file. It does not “repair” syntax or generate prose with the confidence of a committee that has missed lunch.

## Goals

- Provide one formatter and one style for all Wheeler source.
- Make formatting deterministic, idempotent, bounded, and independent of ambient host state.
- Keep diffs local by preserving source order, literal content, comment content, and stable layout groups.
- Require a nonempty file header documentation comment.
- Require a nonempty documentation comment immediately before every named method or function, including private, entry, reversible, coherent, and unitary declarations.
- Use compiler-compatible concrete syntax and comment attachment rather than a second handwritten grammar.
- Support atomic file replacement and a read-only CI check mode.
- Reach a Wheeler-written implementation under the self-hosting toolchain.

## Non-goals

- User-, repository-, organization-, or editor-configurable style.
- Reordering imports, declarations, fields, methods, theorem clauses, or statements.
- Rewriting identifiers, literals, comments, documentation prose, or semantic modifiers.
- Repairing malformed programs.
- Inventing missing documentation.
- Formatting `wheeler.package`, `wheeler.workspace`, `wheeler.lock`, `.wbc`, `.wpk`, plans, JSON, Markdown, or OpenQASM; their canonical codecs or own tools remain authoritative.
- Range formatting in the first implementation. Editors format the complete in-memory file and apply a minimal text edit.
- Enforcing prose grammar, spelling, line length, parameter sections, or a particular natural language.

## Terms and semantic model

A **source token** is a compiler-lexed token with exact byte range and trivia boundaries. A **documentation comment** is one or more consecutive `///` line comments. `///` remains comment trivia to the Wheeler language; the formatter gives it a tooling role without making runtime behavior depend on prose.

A **file header** is the first documentation comment after an optional UTF-8 BOM. Wheeler source does not otherwise admit preamble text. The header attaches to the module declaration when present, or to the first top-level declaration in a moduleless file. It must contain at least one non-whitespace Unicode scalar after `///`.

A **function header** is the documentation comment immediately preceding a named function or method declaration, with no declaration, ordinary comment, or blank line between the comment and the declaration. Attributes and modifiers, when implemented, belong to the declaration and follow the documentation. The rule applies to every visibility and execution kind:

```java
/// Applies one checked increment to the counter.
rev void increment() {
    count += 1;
}
```

The summary may span multiple `///` lines. Empty markers do not satisfy the rule. Parameter lists, return values, traps, reversibility, and proof obligations ought to be documented when relevant, but the first formatter checks presence and nonempty content rather than pretending to understand whether the prose is good.

A **layout group** is the smallest syntax-owned sequence that may choose horizontal or vertical form: a parameter list, argument list, expression, declaration header, or block. Groups nest but never capture preceding comments or following declarations.

Formatting is a partial pure function:

```text
format(style_version, valid_documented_utf8_source) -> canonical_utf8_source
```

For accepted input `s`, the following laws hold:

```text
parse(format(s)) = parse(s)
format(format(s)) = format(s)
comments(format(s)) = comments(s)       // content and attachment
literals(format(s)) = literals(s)       // exact token bytes
order(format(s)) = order(s)             // declarations and statements
```

The formatter may normalize comment delimiters and indentation around `///`, but the text following the required single delimiter space is preserved exactly. Ordinary line and block comment bodies are byte-preserved.

## Ownership and boundaries

The compiler lexer and concrete parser own tokenization, accepted syntax, source ranges, and error recovery. The formatter consumes their lossless concrete-syntax representation; it does not own a grammar fork.

The formatter owns whitespace, line breaks, indentation, comment attachment validation, documentation-presence diagnostics, and formatted UTF-8 bytes. It does not own semantic name resolution, type checking, bytecode, or package resolution.

`wheeler` owns path selection, physical-file checks, bounded reads, check-mode reporting, sibling temporary files, and atomic replacement. Editor integrations invoke the same formatter library on explicit in-memory bytes. They do not reimplement style rules in TypeScript, Lua, Emacs Lisp, or whichever configuration language has escaped containment this week.

The package manager pins the exact formatter tool package used by CI. A package manifest may select whether a format check is a build task; it may not select formatting options.

## Design

### Command surface

The initial command forms are:

```text
wheeler format <file-or-directory>...
wheeler format --check <file-or-directory>...
wheeler format --stdin
wheeler format --stdin --check
```

Directories are walked through physical nonsymlink paths in lexical logical-path order and include only `.w` files. Duplicate paths after normalization are rejected. `--stdin` reads one bounded UTF-8 document and writes formatted bytes to standard output; it cannot be combined with filesystem paths.

`--check` and `--stdin` control effects, not style. Unknown options fail. There is no short alias, configuration discovery, exclusion glob, line-width flag, “project style,” documentation bypass, or editor-specific mode. Generated checked-in Wheeler source follows the same rules. Generated disposable output may skip invoking the formatter; once committed, it has joined society.

### Fixed whitespace

The first style version uses these rules:

- UTF-8 input, LF line endings, no trailing whitespace, and exactly one final newline;
- four ASCII spaces per indentation level and no tab indentation;
- opening braces on the declaration or control header line;
- an empty block as `{}` when it has no comments;
- one statement per line in a nonempty block;
- one space around binary and assignment operators;
- one space after commas and none immediately inside parentheses, brackets, or angle-like type delimiters;
- no space before a call or index opener;
- module and import declarations each on their own line;
- one blank line between the file header, module declaration, import group, and first declaration when those groups exist;
- one blank line between named type or function declarations;
- at most one author-supplied blank line between statement groups; additional blank lines collapse to one;
- attached comments stay attached, and detached comments retain one separating blank line;
- a soft line target of 100 Unicode scalar values, excluding an indivisible literal or comment token.

The 100-scalar target is not configurable and is not a terminal-column promise. Tabs, combining marks, emoji width, and East Asian display width do not become hidden host inputs. A literal or preserved comment may exceed the target without being rewritten.

### Stable line breaking

Each layout group has an ordered, syntax-defined list of legal breakpoints. The formatter emits the horizontal form when it fits the fixed target. Otherwise it chooses the first vertical form defined for that construct. Vertical lists place one syntactic item per line, indent one level, and keep delimiters on stable lines.

A change may reflow the smallest group whose fit decision changed and its enclosing headers as required for indentation. It may not reflow sibling statements or declarations. The printer never performs whole-file optimal wrapping, aligns unrelated `=` tokens, or pads columns. Alignment looks handsome until somebody adds a longer name and the diff catches fire.

### Comments and documentation

The concrete parser attaches leading, trailing, and detached comments before printing. Formatting preserves that attachment. A trailing line comment remains on its statement when the statement plus two spaces and the comment fits; otherwise the comment moves to the immediately preceding line at the statement indentation. Block comment bodies are not rewrapped.

File and function documentation use `///` with exactly one following space on nonempty lines. The formatter adjusts indentation and delimiter spacing, but never wraps or edits prose. A blank documentation line is emitted as `///`.

Missing documentation is a hard diagnostic in write, check, and stdin modes:

```text
WFMT001 path:1:1 file requires a nonempty /// header
WFMT002 path:18:5 function 'increment' requires /// documentation
WFMT003 path:17:5 documentation must be adjacent to its declaration
```

Diagnostic codes and primary byte ranges are stable formatter API. Additional explanatory text may improve without changing the code.

### Publication and minimal diffs

The tool parses, validates documentation, and formats a complete file in memory before opening an output. If formatted bytes equal input bytes, it performs no write. Otherwise it writes a bounded sibling temporary file, flushes it, preserves the original file's ordinary permission bits where supported, and atomically replaces the original. Symlinks, nonregular files, escaping paths, and oversized inputs fail before replacement.

For multiple files, all inputs are parsed and formatted before publication starts. Publication then proceeds in sorted path order. A validation failure publishes none. A host crash during the publication phase may leave a sorted prefix updated; rerunning converges because formatting is idempotent. The tool does not call this a filesystem transaction merely because the alternative is awkward.

Check mode reports every file that differs and every documentation or syntax diagnostic in sorted path order, then exits nonzero. It writes nothing.

## Reversibility and history

Formatting bytes in memory is a pure deterministic transformation and needs no VM history. Replacing a host file is an explicit irreversible effect owned by the command driver. The driver retains no language-level fiction that a rename is a `rev` operation.

A failed parse, documentation check, format, temporary write, or pre-publication validation leaves the destination bytes unchanged. After successful atomic replacement, reversal means restoring bytes from version control or an explicit caller-owned backup; it is not `rewindOne`.

## Concurrency and determinism

One invocation formats files in sorted logical-path order. Formatting one file has no dependency on another file's contents, timestamps, permissions beyond publication, or task schedule. Implementations may parse files concurrently only if diagnostics and publication retain canonical path order and outputs are byte-identical to serial execution.

Concurrent writers to the same path are outside the formatter's state machine. The command detects replacement races when the host provides stable file identity and otherwise relies on the ordinary atomic-replace boundary. It never merges concurrent edits.

## Quantum and proof implications

Formatting does not alter quantum state, circuit semantics, proof certificates, or the trusted proof kernel. Documentation is not proof evidence. A comment saying “unitary” has exactly the authority one would hope.

Conformance does require compiling source before and after formatting to byte-identical semantic `.wbc` where source locations are not semantic. Diagnostics may move only according to the formatted source map.

## Bytecode, persistence, and compatibility

No bytecode instruction, section, or runtime persistence format changes. Formatter style is a versioned tool behavior, not a marker embedded into source files.

CI and package locks pin formatter identity. A deliberate style change requires this WIP to return to Review, conformance fixtures to change, and one isolated repository-wide formatting commit. The formatter will not retain old style modes. Git already stores the old spelling; production code need not cosplay as an archive.

## Safety, limits, and failures

The formatter imposes explicit ceilings on input bytes, tokens, syntax nodes, nesting depth, comment bytes, output bytes, files per invocation, and total work. Defaults align with compiler and package ceilings and are host-policy caps, not source directives.

Input must be strict UTF-8. Invalid encoding, malformed syntax, parser recovery nodes, unattached comments, missing documentation, exhausted limits, unknown options, unsafe paths, and publication failures produce nonzero status and no replacement for the affected file. Arithmetic for ranges, indentation, and output capacity is checked.

The formatter does not execute source, expand macros, resolve imports, access the network, read credentials, inspect the home directory, or invoke provider SDKs. There is remarkably little justification for a formatter needing cloud credentials.

## Migration and deletion

1. Extend the lossless compiler concrete-syntax boundary to retain every whitespace and comment range needed by the formatter.
2. Specify golden formatting and documentation-diagnostic corpora shared by stage 0, Tree-sitter fixtures, and editor integrations.
3. Implement the fixed-layout engine and in-memory API in the stage-0 tools module.
4. Add `wheeler format`, check/stdin modes, physical path validation, bounded traversal, and atomic publication.
5. Add file headers and function documentation to every checked-in `.w` file in one reviewable documentation series, then format the tree in a separate mechanical commit.
6. Make Gradle-era CI run format check while stage 0 remains the oracle.
7. Port the concrete tree, layout engine, and diagnostics to Wheeler using WIP-0007 storage, UTF-8, collections, and explicit effects.
8. Differentially format the complete corpus, generated whitespace variants, and malformed inputs until stage 0 and Wheeler agree byte-for-byte.
9. Delete the stage-0 formatter implementation, duplicate editor printers, format scripts, and temporary Gradle task at native cutover.

No compatibility adapter will read Prettier, EditorConfig, google-java-format, clang-format, or a `.wheelerfmt` file. None of those formats has wronged us; they are simply not Wheeler's decision log.

## Progress

- [ ] Lossless concrete syntax retains all comments and trivia with stable attachment.
- [ ] Golden fixed-style and minimal-diff corpora are accepted.
- [ ] File and function `///` documentation diagnostics are stable.
- [ ] `wheeler format`, `--check`, and `--stdin` implement bounded deterministic effects.
- [ ] Every checked-in `.w` file is documented and formatted.
- [ ] Editor integrations call the formatter rather than reproduce it.
- [ ] A Wheeler-written formatter matches stage 0 byte-for-byte.
- [ ] Stage-0 and duplicate formatting paths are deleted at native cutover.

## Testing and acceptance

- [ ] Every accepted fixture satisfies parse preservation, comment/literal/order preservation, and idempotence.
- [ ] Adding or removing one list item changes only its enclosing layout groups outside unavoidable line-number shifts.
- [ ] Compact, multiline, deeply nested, comment-heavy, Unicode, reversible, proof, quantum, module, and malformed fixtures are covered.
- [ ] Every checked-in `.w` file has one nonempty file header and adjacent nonempty documentation for every named method/function.
- [ ] Missing, empty, detached, and ordinary `//` documentation substitutes produce exact `WFMT001..003` diagnostics.
- [ ] Formatting before compilation produces byte-identical semantic `.wbc` to compilation before formatting across the source corpus.
- [ ] `--check` writes no files and reports paths in canonical order.
- [ ] Write mode avoids touching already formatted files and atomically replaces changed physical files.
- [ ] Malformed UTF-8, syntax failure, missing documentation, unsafe paths, and exhausted limits leave original bytes unchanged.
- [ ] LF/final-newline normalization and comment attachment are host-independent.
- [ ] Configuration files, environment variables, locale, terminal width, and editor settings cannot alter output.
- [ ] Stage-0 and Wheeler implementations agree byte-for-byte and produce the same diagnostics.
- [ ] Current tooling reference documents implemented commands only after their acceptance suite passes.

## Alternatives

### Support a small configuration file

Rejected. “Small” configuration formats reproduce through mitosis. More importantly, configuration makes source layout depend on ambient package discovery and complicates editor, CI, vendored dependency, and bootstrap identity. One style is easier to dislike consistently.

### Use Tree-sitter as the only formatter parser

Rejected as the semantic authority. Tree-sitter remains essential for editors and recovery tests, but the compiler's lossless concrete syntax decides whether Wheeler source is valid. Differential Tree-sitter parsing remains an acceptance gate.

### Pretty-print the semantic AST

Rejected. The AST intentionally discards trivia and may normalize distinctions the formatter must preserve. Reconstructing comments after that loss produces either wandering comments or a second undocumented attachment language.

### Reorder imports and declarations

Rejected. Ordering may already be semantically constrained, and even harmless sorting creates broad diffs outside the edited construct. The compiler or a dedicated diagnostic should reject invalid order; the formatter should not move code while pretending to add spaces.

### Generate documentation stubs

Rejected. `/// TODO` is not documentation, and machine-generated paraphrases convert missing knowledge into plausible noise. The formatter identifies the accountable declaration and stops.

### Permit a format-only documentation bypass

Rejected. A bypass becomes the default editor command within a week, after which CI discovers all missing documentation at once. The same contract applies locally and remotely.

### Preserve all user line breaks

Rejected. That is an indentation fixer, not a formatter, and leaves review churn to personal taste. The chosen compromise preserves deliberate statement-group blank lines and comment bodies while owning syntactic layout groups.

## Open questions

- Should documentation presence eventually require parameter, result, trap, and reversibility sections for public APIs, or remain a nonempty-summary rule? — **Owner:** documentation and language maintainers — **Decide by:** before WIP acceptance
- Should the first editor protocol expose formatted text only or also canonical byte edits? — **Owner:** tools and editor maintainers — **Decide by:** before editor integration
- What exact input, nesting, and total-work defaults should the formatter use relative to compiler limits? — **Owner:** compiler and security maintainers — **Decide by:** before implementation

## References

- [WIP-0005](WIP-0005-wheeler-source-language.md)
- [WIP-0006](WIP-0006-concrete-syntax-tooling-and-teaching.md)
- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0012](WIP-0012-wheeler-standard-library.md)
- [Language profile](../reference/language-profile.md)
- [Development and testing](../reference/development.md)
