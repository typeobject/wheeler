# WIP-0504: Complete retained call statement windows

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler maintainers |
| Created | 2026-09-07 |
| Updated | 2026-09-07 |
| Area | Retained source-call syntax and widths |
| Depends on | WIP-0057, WIP-0059, WIP-0503 |
| Supersedes | None |
| Superseded by | None |

## Boundary

[WIP-0057](WIP-0057-source-call-relocation-and-ownership-coordinate-products.md)
requires one statement owner for each call's values, locals, instructions, and
relocations. The dependencies above name retained call rows, imported targets,
and existing loan typing, not complete compiler composition. Qualified forwarded
returns violate that handoff. Value planning
recognizes only the unqualified return opcode. A later qualified-call pass also
overwrites the measured width with a value-call width, losing the forwarded
return instruction.

A separate unqualified control, `return recurse(number) + number;`, publishes a
568-byte artifact on `7e63b4721`. Stage zero produces 632 bytes for the unchanged
source. Retained lowering silently omits the addition. The source window must
reject that unsupported combination rather than certify the shortened program.

Validate complete ordinary call statements before measuring their frames. Admit
qualified forwarded results through the same source-owned width path as other
calls. A call-name match must not authorize ignoring tokens after the call.

## Change

`SourceCallArgumentProducts.w::sourceCallStatementValid` checks counted scanner
columns, a complete statement extent, the retained call-name range, and arity.
Its heads are a standalone call, a forwarded return, or a signed/Boolean local
declaration. The predicate validates every consumed token extent before reading
source spelling. The last token must be the statement's final semicolon. No
unconsumed token may remain inside that byte window.

The call prefix accepts an unqualified name or dotted namespace plus `::`.
Arguments remain ordered identifiers. Complete names, target visibility, exact
types, and defining values remain separate binding work. Scanner columns retain
trivia coordinates and are not rewritten or allocated by this predicate.

`SourceValueProducts.w` consumes that complete window before publishing call
widths. Ordinary calls own twice their arity in locals. Forwarded results add one
slot. Value declarations add two. Structured conditions retain their own window
admission. No new arity, frame, token, artifact, or evaluator limit appears.

Delete `materializeQualifiedCallStatementWidths` and its orchestration call. A
qualifier must not create a second width authority or a second staging arena.

## Evidence

- Keep the original signed and storage-loan qualified-return counterexamples and
  compare their complete artifacts with stage zero.
- Compare qualified/unqualified signed and Boolean returns, declarations, and
  void calls at zero, one, and 64 arguments. Keep argument 65 rejected.
- Validate nonzero windows, UTF-8 trivia, the last counted token, short columns,
  malformed extents, unknown heads, and arithmetic overflow guards.
- Reject extra prefixes, suffixes, and argument expressions without publishing
  artifact, identity, or caller-owned products. Preserve all token columns and
  complete rewind in small predicate fixtures.
- Execute a qualified native-produced caller with the independent allocation/map
  callee. Check actual result forwarding, mutation, reborrows, and rewind.
- Restore mutants that bypass return-window admission, ignore the final extent,
  admit an unconsumed token, publish rejected frame products, restore qualified
  width replacement, or restore the parameter-token scan bug. Check source hashes
  before final package evidence.

### Verified scope

`NativeCompilerCallStatementWindowExampleTest` checks all three statement heads,
nonzero UTF-8 windows, arities zero through 64, and the last of 4,096 tokens.
Short columns, invalid counts, empty qualifiers, bad coordinates, argument
expressions, and detached tails reject. Every token column is preserved. Small
fixtures rewind completely, and ordinary checks retain only the fixture's seven
buffers. A separate rejected return checks all 15,424 caller-owned value, local
count, and statement-width cells against sentinels, then rewinds completely.

`NativeCompilerCompleteCallStatementExampleTest` compares complete imported
artifacts, stubs, and relocations at zero, one, and 64 arguments across all eight
scalar/loan kinds. It includes a completed loop before forwarding and rejects
tails without artifact or identity publication. The original signed and loan
counterexamples remain in `NativeCompilerRetainedStorageCallExampleTest`. Both
qualified and unqualified callers execute through the independent allocating,
map-mutating callee, then rewind.

Six restored mutants fail. Skipping return admission publishes the shortened
artifact. Ignoring the final extent or next token breaks a window assertion.
Publishing rejected frame products changes their sentinels. Restoring the
qualified width pass produces a fall-through body. Restoring the 256-iteration
parameter scan fails the mixed 64-argument signature. All 703 Wheeler hashes
match the restored source receipt.

Local evidence covers 135 isolated JUnit identities and thirteen additional
unfinished-member integrations, or 148 distinct identities. The 32 integration
results overlap nineteen isolated identities. The intact nominal runner is not
counted as passing. The physical/archive gate passes on all 451 module bindings
and 29 imported entry targets. It does not compile the complete argument or
value-planning owners natively.

| Measured input | Result |
| --- | --- |
| Compiler graph | 451 modules, 2,140 imports, two externals |
| Symbols and callables | 2,110 constants, 1,815 callables |
| Module manifest | 208,445 bytes, `fe4e240b037b56309208ab606cf5a9ec9b2eed0dda9fdfe327a440b5a0e68534` |
| Compiler archive | 3,379,087 bytes, `e9772428542cb08f755b4938f3bdda226769b29934ec1a432d60fe822b53ae62` |
| Compiler executable | 6,966,424 bytes, 1,831 functions, 237,244 instructions |
| Executable SHA-256 | `863940abb7a09a77a65bc0b90255a1dd18284e04ca9f92469242a93855ddcab1` |

Graph identity takes 88,823,371 transitions under the unchanged 89-million bound.
Manifest SHA takes 39,901,270 under its separate input-size budget. The four
compiler-dependent archive locks change. The compiler's physical manifest and
lock do not. All 713 canonical package inputs are retained in the final receipt.

The locked original-minimum consumer matches all 568 artifact bytes and 772
coverage bytes. It executes seven tested transitions and leaves state seven.
Native spine and ordering targets pass seven and three cases respectively. A
fresh workspace emits 497 artifacts. Source, formatter, lock, and documentation
gates pass. API checks and site rendering cover the five published main roots,
not the existing conformance/test documentation diagnostics.

## Acceptance

- [x] One source owner validates complete ordinary call windows.
- [x] Qualified forwarded results match complete independent artifacts.
- [x] Rejected windows preserve every caller-owned product.
- [x] Executed calls and small rejected predicates rewind completely.
- [x] The qualified width override and its allocation are deleted.
- [x] Formatter, source, physical, package, lock, and documentation gates agree.

## Remaining work

This does not add arbitrary call argument expressions or arithmetic after calls.
It must reject unsupported combinations rather than discard their values.
Aggregate artifact composition and WIP-0498's intact nominal runner remain open.
Hosted native-package acceptance must pass on these inputs. The parent repair's
run 34166510984 passed 51 jobs but timed out on native shard 15 at the unchanged
twelve-minute method deadline. It is not acceptance for this change.

The stage-0-produced compiler, fixed point, recovery, and Java-free cutover retain
their existing acceptance requirements.
