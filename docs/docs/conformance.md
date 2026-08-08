# Executable conformance programs

The `wheeler.conformance` package contains bounded executables that pin compiler, verifier, runtime, package, bootstrap, and identity behavior. They are test subjects and recovery evidence, not teaching examples. A digest parser with seventeen rejection cases may be admirable, but nobody should meet the language that way.

Each program consumes exact locked archives from the canonical `wheeler.compiler`, `wheeler.core`, `wheeler.packages`, and `wheeler.runtime` packages. It keeps no implementation copies. Publication remains fail closed: malformed input traps before canonical output becomes visible.

## Programs

### `MinimalCompiler.w`

Files: [`MinimalCompiler.w`](../../wheeler-compiler/src/main/wheeler/MinimalCompiler.w) + [`compiler/Core.w`](../../wheeler-compiler/src/main/wheeler/compiler/Core.w) + [`compiler/Graphs.w`](../../wheeler-compiler/src/main/wheeler/compiler/Graphs.w) + [`compiler/GraphFour.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFour.w) + [`compiler/GraphFive.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFive.w) + [`compiler/GraphSix.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphSix.w) + [`compiler/graphs/Matrix.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/Matrix.w) + [`compiler/graphs/plans/GraphExecutionOrder.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/plans/GraphExecutionOrder.w) + [`compiler/graphs/plans/GraphExecutor.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/plans/GraphExecutor.w) + [`compiler/graphs/plans/GraphHelperMembers.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/plans/GraphHelperMembers.w) + [`compiler/graphs/plans/GraphOwnerMetadata.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/plans/GraphOwnerMetadata.w) + [`compiler/graphs/plans/SourceTable.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/plans/SourceTable.w) + [`compiler/Driver.w`](../../wheeler-compiler/src/main/wheeler/compiler/Driver.w) + focused frontend, resolution, IR, verification, and backend owners.

Covers: Wheeler compilation of one bounded minimal source grammar to canonical `.wbc`.

Expected behavior:

- Input `classical class LongClass { state long value = 7; entry void main() { value += 5; } }` drives global and instruction IR, canonical lexical string ordering, function descriptors, and layout.
- The 504-byte result passes Wheeler's header/directory/payload/instruction-stream verifier, including global/local/type/call operand domains, matches stage 0, and executes with `value = 12`.
- Canonical `module examples.seed;` input emits stage-0-identical qualified entry/helper strings and unqualified theorem names, including stateless helper classes. An entryless library with zero or one general helper emits the unqualified `$library` halt entry. The bounded helper-table path also emits exact canonical descriptors, signatures, code offsets, sorted strings, and that same entry for one through twenty-three public, private, or unqualified zero- through sixteen-parameter helpers. A lone fixed-array reader takes the table path directly. Dummy functions are not admission tickets. Signature evidence covers shared UTF-8 and byte-view loans, mutable byte, word, region, and signed-map loans, and mixed signed/loan parameter lists. A signed or Boolean local may initialize from an exact zero- through two-argument same-module or direct imported call with matching primitive argument types. Each loan is reborrowed into the call frame. A helper may allocate one bounded `bytes` owner through a mutable region loan and advance that owner through `setByte`. It may explicitly drop the owner, consume it into a UTF-8 result with `freezeUtf8`, or forward that result through an exact two-argument same-module call. The native emitter reproduces stage 0's source moves, `BYTES_ALLOC`, mutation-time `OWNED_MOVE`, type rows, `BYTES_SET`, `UTF8_FREEZE`, direct `BUFFER_DROP`, and the final result transfer. Wrong source types, a leak, a foreign owner, use after consumption, an unsupported UTF-8 signature, a mismatched forwarded owner, and a second drop publish nothing. The parser does not retry an invalid entryless scalar library through the entry-bearing helper route. A rejection is not a request for a more credulous parser. The fixed-width core readers and focused result-slot operand verifier compile byte for byte through that path. Signed locals also accept three through seven prior primitive locals with exact owner types and canonical reborrows. The five-, six-, and seven-argument initializers use twelve, fourteen, and sixteen temporary locals and the same number of instructions. An eighth passenger still needs another train. Existing signed locals may receive exact zero- through seven-prior-primitive-local signed-helper results. Seven uses fifteen temporaries and sixteen instructions. Boolean targets, swapped loan types, literals, and eight arguments publish nothing. The emitted `CALL_VALUE` names the resolved function. Function zero has no squatter rights. Final calls forward one through seven signed values, fixed-array owners, or loans across same-module and direct imported helpers with exact type checks and canonical move or borrow opcodes. Seven arguments use fifteen locals and sixteen instructions. An eighth argument publishes nothing. Signed helpers may return `bufferLength` directly or bind it to a signed local over UTF-8, byte-view, byte, and word loans. They may also bind `utf8Scalar` or `utf8Width` from a UTF-8 loan and signed index, or bind one indexed byte or word from a byte-view, byte, or word loan. Mutable byte and word loans admit `setByte` and `set`, while mutable signed-map loans admit `put`. Each uses signed key or index and value locals. Signed and Boolean locals may bind `mapGet` and `mapHas` from a signed-map loan and signed key. Entryless void helpers accept zero through sixteen primitive parameters and either an empty body or those writes. Their type table has no imaginary result local. Void and scalar-result helpers may issue zero- through seven-argument calls to same-module or direct imported void helpers with exact primitive types and canonical reborrows. Four through seven sources use two bounded packed operands. Eight fail before publication. Mismatched owner, index, and value types publish nothing. A twenty-fourth helper still fails closed. Signed-parameter Boolean and signed helpers may use bounded equality or less-than guards, computed signed-local preludes, and up to sixty-four same-module or direct imported Boolean calls with typed literal, constant, or prior-local early returns before one final result. The sixty-four-call case may alternate across all twenty-two helpers from seven owners, reaches the statement boundary and the 256-local window, and matches in reverse frame order. Call sixty-five publishes nothing. The fence has now been kicked from both sides. A final Boolean return may forward one zero-, one-, or two-argument helper call. A helper-call guard may return another imported one-argument Boolean call over the same or a different prior local. Thirty-two pairs fill the call table and pair thirty-three publishes nothing. Equality and less-than guards may return any prior signed local. A signed less-than guard may instead return its parameter minus, divide by, or reduce modulo one literal or constant. Unresolved guard widths account for their generated temporaries before later declarations resolve, so a local after three guards does not read register four and call it destiny. The native body keeps each jump local, so an early return needs no folklore about fallthrough. A four-helper imported-constant differential crosses the former 16 KiB linked-source line and remains byte-identical. Padded two-import input beyond 32,768 linked bytes publishes nothing. The checked-in `compiler/backend/calls/CallArguments.w`, `compiler/backend/EncodingWidths.w`, imported-constant `compiler/frontend/intrinsics/BorrowedIntrinsicShapes.w`, `compiler/ir/Opcodes.w`, `compiler/ir/ProofRules.w`, `compiler/ir/ResolvedStatements.w`, `compiler/ir/StatementKinds.w`, `compiler/ir/StorageOpcodes.w`, `compiler/ir/TypeCodes.w`, `compiler/ir/limits/CompilerProgramLimits.w`, imported-function `compiler/verification/ResultSlotVerifier.w`, `compiler/resolution/returns/WideReturnSources.w`, imported-constant `compiler/resolution/returns/ReturnOpcodeKinds.w`, imported-constant `compiler/syntax/assignments/NamedLocalAssignmentKinds.w`, imported-constant `compiler/syntax/assignments/ResolvedLocalAssignments.w`, imported-constant `compiler/syntax/assertions/ResolvedBooleanLiteralAssertions.w`, imported-constant `compiler/syntax/assertions/ResolvedLessThanAssertions.w`, imported-constant `compiler/syntax/assertions/ResolvedLocalPairAssertions.w`, `compiler/syntax/booleans/BooleanTokens.w`, imported-constant `compiler/syntax/booleans/ResolvedBooleanLiteralComparisons.w`, imported-constant `compiler/syntax/comparisons/NamedComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/LiteralComparisonOperations.w`, imported-constant `compiler/syntax/conditionals/NamedConditionalBases.w`, imported-constant `compiler/syntax/conditionals/NamedLiteralComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/NamedLocalConditionalKinds.w`, imported-constant `compiler/syntax/conditionals/NamedLocalConditionalValues.w`, imported-constant `compiler/syntax/conditionals/ResolvedLiteralComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalKinds.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalSources.w`, imported-constant `compiler/syntax/locals/NamedLongOperations.w`, imported-constant `compiler/syntax/locals/ResolvedLocalCopyKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalEqualityKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalInequalityKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLessThanKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLiteralComparisons.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLiteralComparisonSources.w`, imported-constant `compiler/syntax/locals/ResolvedLongOperations.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopForms.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopKinds.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopOperands.w`, imported-constant `compiler/syntax/updates/NamedLocalUpdateKinds.w`, imported-constant `compiler/syntax/updates/ResolvedLocalUpdates.w`, imported-constant `compiler/ir/OpcodeKinds.w`, imported-constant `compiler/ir/TypeKinds.w`, imported-constant `compiler/ir/InstructionForms.w`, imported-constant `compiler/syntax/BooleanDeclarationKinds.w`, `compiler/syntax/IdentifierStarts.w`, `compiler/syntax/tokens/CompilerTokenLimits.w`, `compiler/syntax/tokens/KeywordTokens.w`, `compiler/syntax/tokens/SourceScalars.w`, `compiler/syntax/helpers/HelperAbi.w`, imported-constant `compiler/syntax/helpers/HelperSignatures.w`, mixed-owner `compiler/syntax/helpers/HelperValueKinds.w`, `compiler/syntax/intrinsics/BorrowedIntrinsicKinds.w`, imported-constant `compiler/syntax/EarlyReturnKinds.w`, imported-constant `compiler/syntax/EarlyReturnResultKinds.w`, `compiler/syntax/LoopKinds.w`, imported-constant `compiler/syntax/calls/CallArgumentSources.w`, imported-constant `compiler/syntax/calls/OneArgumentCalls.w`, imported-constant `compiler/syntax/calls/TwoArgumentCallKinds.w`, imported-constant `compiler/syntax/calls/FourArgumentCalls.w`, `compiler/syntax/calls/assignment/AssignmentCallArities.w`, `compiler/syntax/calls/assignment/AssignmentCallCodeWidths.w`, `compiler/syntax/calls/assignment/AssignmentCallColumns.w`, `compiler/syntax/calls/assignment/AssignmentCallIdentities.w`, `compiler/syntax/calls/assignment/AssignmentCallInstructionWidths.w`, `compiler/syntax/calls/assignment/AssignmentCallLocalWidths.w`, `compiler/syntax/calls/ThreeArgumentCalls.w`, `compiler/syntax/calls/VoidCallKinds.w`, `compiler/syntax/calls/VoidCallSourceKinds.w`, mixed-owner `compiler/syntax/calls/VoidCallSourceWidths.w`, imported-function `compiler/syntax/calls/void/VoidCallSourceForms.w`, `compiler/syntax/calls/VoidCallWidths.w`, imported-constant `compiler/syntax/returns/EarlyReturnSources.w`, imported-constant `compiler/syntax/returns/NamedBooleanReturnKinds.w`, imported-constant `compiler/syntax/returns/NamedReturnArithmeticKinds.w`, imported-constant `compiler/syntax/returns/NamedReturnComparisonOperands.w`, imported-constant `compiler/syntax/returns/NamedSignedReturnKinds.w`, imported-constant `compiler/syntax/returns/ResolvedEarlyComparisonKinds.w`, imported-constant `compiler/syntax/returns/ResolvedEarlyResultKinds.w`, imported-function `compiler/syntax/returns/EarlyComparisonForms.w`, `compiler/syntax/returns/ResolvedLocalReturns.w`, imported-constant `compiler/syntax/returns/ResolvedReturnCallKinds.w` are complete compiler source modules accepted byte for byte by the native compiler. The statement registries pin 138 unresolved identities, six loop-form identities, and ninety-one resolved opcode columns without leaving them in `Tokens.w`. One through seven direct executable dependencies may jointly own one through twenty-two helpers, while the root owns the remainder of a twenty-three-helper table. A twenty-third dependency helper and twenty-fourth total helper fail before publication. Wider function tables and an eighth executable owner still fail closed. Two-owner evidence fills an eleven-plus-eleven dependency split. Three-owner evidence fills an eight-plus-seven-plus-seven split and checks all six frame orders without moving a function. Four-owner evidence fills a six-plus-six-plus-five-plus-five split across eight forward/reverse rotations. Five owners fill a five-plus-five-plus-four-plus-four-plus-four split across ten rotations. Six owners fill 4+4+4+4+3+3 across twelve rotations. Seven owners fill 4+3+3+3+3+3+3 across fourteen rotations. Five through seven owners use one sixteen-comparator network over packed source-start keys. Inactive keys sort last. Sorting by arrival would be networking, not linking. A header may contain up to sixty-four sorted unique direct imports. Empty through sixty-four-import boundaries match stage 0 when imported declarations do not enter the root artifact. Malformed, duplicate, unsorted, and excess imports publish nothing. Public, explicit-private, and unqualified helpers produce the same linked function bytes, while duplicate visibility fails before output. The bounded entry points execute every rooted acyclic scalar-constant graph from one through seven imported modules. The single-import path links directly. Two through seven imports use complete plans for edges, root ranks, leaf-first order, privacy, sharing, and source selection. Dense DAGs and redundant direct edges need no topology identity. Exact shared declarations collapse once. Mismatches, cycles, detached nodes, eight imports, and non-ASCII linked source fail before publication. Direct helper sets, mixed direct owners, redundant constant leaves, the constant-fed helper chain, private helper chains, and multi-input private helper dependencies use the graph executor. Mixed constant/helper inputs run through separate declaration and executable passes. Shared and redundant executable dependencies use exact owner-identity filters. Helper member groups remain once in canonical dependency order. General imported declarations and aggregate symbols remain unsupported.
- `verification = 1`.
- The differential suite covers no-global classes with zero to sixty-four statements. A sixty-fifth statement is rejected before output. Signed-result entries require at least one helper call anywhere in the same bounded sequence. Later calls may consume prior results.
- Cases include signed and Boolean locals, prior signed- and Boolean-local copies, prior-Boolean negation, typed equality and inequality declarations over prior locals, signed locals and literals, or signed and Boolean locals and class constants, direct assertions over prior Boolean or signed locals, Boolean equality assertions against class constants, signed local or state equality assertions against literals or class constants, signed-local less-than declarations over prior locals or literal right operands, and signed ordering assertions against prior locals or class constants, one-arm positive or negated prior-Boolean `if` guards and signed-local equality and less-than guards against literals or class constants over global assignment and checked updates from literals, class constants, or prior locals, checked signed-local `+`, `-`, `^`, `&`, `*`, `/`, and `%` expressions and in-place `+=`, `-=`, and `^=` updates over literal, class-constant, or prior-local right operands, bounded signed-local less-than `while` loops with explicit literal, class-constant, or prior-local conditions and limits and one checked unit update, signed-local equality assertions, literal or prior-local truth assertions, typed signed- and Boolean-local assignment, literal or prior-local state assignment and updates, void helper calls, zero-argument Boolean result helpers with bounded local preludes, one- and two-argument Boolean helpers over Boolean literals or prior locals with bounded parameter-aware local preludes and direct negated, equality, or inequality results over literal, class-constant, or prior-local right operands, Boolean-result helpers over one through sixteen signed parameters, with signed literal or prior-local calls to one- and two-parameter forms, direct signed equality, inequality, or ordering results over literal, class-constant, or prior-local right operands, zero-argument signed result helpers with bounded local preludes, one-argument signed helpers with literal, class-constant, or prior-local arguments and bounded parameter-aware local preludes, two-argument signed calls and three- through sixteen-parameter signed helpers over literals, class constants, or prior entry locals with bounded parameter-aware local preludes, and direct or checked arithmetic and bitwise results over literals, class constants, or parameters, reversible helpers, reverse blocks, and generated-inverse theorems.
- A class may carry one contiguous block of 256 scalar constants before or after optional signed state. A signed constant may initialize that state, including by forward reference. Split blocks fail closed. The native evaluator accepts checked decimal, hexadecimal, binary, Boolean, arithmetic, bitwise, comparison, `rotateRight32`, parenthesized, and forward same-class forms. It substitutes values through locals, direct, arithmetic, and comparison returns, calls, assignments, generated reversible helper updates, signed or Boolean local expression operands, signed or Boolean assertion operands, and signed comparison-condition and guarded state-update operands, bounded loop conditions or limits, and affine-region byte or allocation limits without adding globals or runtime lookup. Differential fixtures reject cycles, unknown dependencies, type errors, malformed expressions, arithmetic traps, invalid rotation amounts, and a 257th declaration before output. Reordering a dependency chain leaves the `.wbc` bytes alone. Source order gets no consolation prize. Two adjacent constant-bounded loops retain their separate six-local windows, so the second loop updates its own target rather than an earlier temporary wearing the same index.
- Fixtures use two to four strings and zero or one global.
- Bounded entry bodies fit the 256-local, 512-instruction native verification window. A sixty-three-declaration signed window plus its final local equality uses 129 typed locals. `assert(global == constant)` still lowers directly to local-free `EXPECT_EQ`.
- A named public, explicit-private, or unqualified zero- through sixty-four-statement helper plus static entry call emits two descriptors, `RETURN`, and `CALL`. Ordinary helpers may live in classes with no state. An empty reversible helper and its generated-inverse theorem also compile without inventing dummy state. Nonempty reversible bodies remain bounded to checked state updates. An inverse of nothing is modest, but at least it does not lie.
- One or two helper calls derive repeated `CALL` sites.
- A following entry statement derives its own locals, type window, descriptor length, and code after the call.
- The `rev` form maps checked `+=`/`-=` to opposite intrinsic bodies and `^=` to a self-inverse body, reverses multi-statement inverse order, emits entry `CALL`/`UNCALL`, then may assert the restored state.
- Plain assignment is rejected because it has no checked inverse.
- A checked statement may appear before and after a reversible block.
- The checked-in `Counter.w` compiles byte for byte through the direct VM and package-selected `wheeler run` paths. It runs two calls, two inverse calls, and both assertions.
- Compiler-local comment compaction leaves the shared teaching scanner's token stream intact.
- Thirty-two deterministic pseudo-random whitespace, line-comment, and block-comment layouts reproduce the baseline bytes in stage 0 and Wheeler.
- Compiler token metadata allows 4,096 pre-compaction tokens. A 3,000-comment source compiles to the baseline bytes. 4,096 comments exceed the bound and trap before publication. Comments remain syntax, not a memory-allocation strategy.
- An optional theorem adds a canonically sorted proof name and 28-byte `GENERATED_INVERSE` section accepted by the proof kernel.
- Signed and Boolean literals, unary negation, literal truth assertions, and prior-local Boolean assertions work in no-global, stateful, and ordinary-helper bodies.
- They lower through `LOCAL_CONST`, `LOCAL_XOR`, `LOCAL_MOVE`, and `EXPECT_TRUE`. The compiler emits exact signed and Boolean local type windows from named token, punctuation, and statement identities.
- Signed decimal initializers and operands use canonical two's-complement form. An overlong negative magnitude fails before publication, with no substitute constant.
- The complete file length is checked against caller output capacity before the first header byte is written.
- `codeStart = 392`, `finalCursor = 504`.

### `NativeModuleCompiler.w`

Source: [`NativeModuleCompiler.w`](../../wheeler-conformance/src/main/wheeler/compiler/NativeModuleCompiler.w).

Covers: One binary frame containing a canonical little-endian `u32` module count, zero through seven length-prefixed imported sources, and the remaining root source. Each physical source occupies at most 32,768 bytes. The exact boundary compiles. Byte 32,769 fails before publication. Zero imports call the ordinary bounded compiler directly. One through seven call the matching bounded import API. Every path publishes only the verified artifact range. Zero no longer has to borrow a fake dependency and return it before lunch.

Expected behavior: Every rooted acyclic scalar-constant graph from one through seven imports matches stage 0 independently of frame order. The single-import path links directly. Two through seven imports use complete plans and one generic executor over the counted source table. Evidence covers the former topology catalogue plus dense three- and four-module DAGs, a shared five-module DAG, and redundant six- and seven-module DAGs. Exact shared declarations appear once. Mismatches, private root uses, collisions, cycles, detached nodes, duplicate modules, eight imports, non-ASCII source, malformed framing, and byte 32,769 publish nothing. The graph executor also handles direct helpers, mixed direct owners, redundant constant and helper leaves, private helper chains and forks, shared helper leaves and diamonds, nonprefix shared owners, and mixed private constant/helper inputs. Differential evidence covers every small frame order and larger forward/reverse rotations.

### `NativeArtifactSetIdentity.w`

Files: [`NativeArtifactSetIdentity.w`](../../wheeler-conformance/src/main/wheeler/bootstrap/NativeArtifactSetIdentity.w) + [`crypto/Sha256.w`](../../wheeler-core/src/main/wheeler/crypto/Sha256.w).

Covers: Exact bounded `wheeler.artifact-set/1` JSON, one through eight sorted safe ASCII `.wbc` paths, canonical positive byte counts, lowercase SHA-256 fields, the domain-separated binary identity contract, embedded-identity verification, fail-closed publication, and exact rewind.

Expected behavior: A two-artifact manifest reproduces the stage-0 set identity. Unsorted paths, uppercase digests, forged identities, unknown profile keys, a ninth artifact, or input beyond 4,096 bytes publish nothing. This fixture validates manifest metadata. The stage-0 closed-tree command still verifies every physical `.wbc` before emitting those bytes. A manifest is evidence about files only after somebody checks the files. Film at eleven.

### `NativeBootstrapFeaturesIdentity.w`

Files: [`NativeBootstrapFeaturesIdentity.w`](../../wheeler-conformance/src/main/wheeler/bootstrap/NativeBootstrapFeaturesIdentity.w) + [`ManifestSyntax.w`](../../wheeler-compiler/src/main/wheeler/compiler/closure/ManifestSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Exact schema-1 canonical YAML, the complete ordered seventeen-feature `bootstrap-1` vocabulary, version 1 for every contract, complete SHA-256 publication, and exact rewind.

Expected behavior: The stage-0 feature manifest reproduces its identity. A renamed feature, changed version, missing final feature, or input beyond 2,048 bytes publishes nothing. A bootstrap feature list is closed evidence, not a buffet where the compiler leaves unsupported vegetables on the plate.

### `NativeBootstrapManifestIdentity.w`

Files: [`NativeBootstrapManifestIdentity.w`](../../wheeler-conformance/src/main/wheeler/bootstrap/NativeBootstrapManifestIdentity.w) + [`ManifestSyntax.w`](../../wheeler-compiler/src/main/wheeler/compiler/closure/ManifestSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Exact schema-2 canonical recovery YAML, twenty-one lowercase identities, bounded profile syntax, stage-1/stage-2 equality, diverse-output and diagnostic equality, genuinely distinct toolchain/compiler identities, complete SHA-256 publication, and exact rewind.

Expected behavior: Complete fixed-point and diverse-compilation evidence reproduces the stage-0 manifest identity. A false fixed point, mismatched diverse output, shared alleged-independent toolchain or compiler, reordered field, or input beyond 2,048 bytes publishes nothing. The validator checks evidence relationships. It does not award independence points for wearing a false moustache.

### `NativeBootstrapModulesIdentity.w`

Files: [`NativeBootstrapModulesIdentity.w`](../../wheeler-conformance/src/main/wheeler/bootstrap/NativeBootstrapModulesIdentity.w) + [`ModuleManifest.w`](../../wheeler-compiler/src/main/wheeler/compiler/closure/ModuleManifest.w) + [`ManifestSyntax.w`](../../wheeler-compiler/src/main/wheeler/compiler/closure/ManifestSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: The compiler-owned counted manifest parser over one through 512 sorted local source modules, zero through sixty-four externals, a 3,072-import table, 262,144-byte manifests, unique paths, complete binding, rooted reachability, cycle rejection, bounded names and paths, lowercase source identities, exact schema bytes, SHA-256 publication, and rewind.

Expected behavior: Empty-import one-module, two-external one-module, and three-, five-, nine-, and seventeen-module rooted DAG closures plus a sixty-five-module star and 128-, 256-, and 257-module chains reproduce stage 0. The last chain crosses the former local-module ceiling. A sixty-six-module star exceeds the per-module import bound. Nine-, ten-, and thirteen-module DAGs over sixty-four externals pin the 512-, 576-, and 768-import boundaries. Sorted module and external tables use bounded binary lookup. Source guards pin the checks before a 513th module or 3,073rd edge is appended without commissioning long rejection fixtures. A cycle, unreachable module, duplicate path, sixty-fifth external, unsorted external, unbound import, mismatched root, uppercase digest, traversal path, or input beyond 262,144 bytes publishes nothing. The current physical compiler closure has 254 modules, 1,312 imports, and 116,394 canonical bytes. The packaged executable reproduces its stage-0 identity in 45,345,372 transitions. The 512-module native table bound remains deliberately smaller than the 10,000-module schema and independently bounded by the manifest byte ceiling. Pretending otherwise would merely give the graph a fake moustache too.

### `NativeCompilerLimitsIdentity.w`

Files: [`NativeCompilerLimitsIdentity.w`](../../wheeler-conformance/src/main/wheeler/bootstrap/NativeCompilerLimitsIdentity.w) + [`ManifestSyntax.w`](../../wheeler-compiler/src/main/wheeler/compiler/closure/ManifestSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Exact schema-1 canonical YAML, all ten required positive compiler ceilings, canonical decimal spelling, the 1,073,741,824 per-field maximum, complete SHA-256 publication, and exact rewind.

Expected behavior: The documented bootstrap limits reproduce the stage-0 identity. Zero, a leading zero, an over-ceiling value, stray whitespace, or input beyond 512 bytes publishes nothing. A missing resource limit is not an exciting opportunity for dynamic defaults.

### `NativeCompilerOptionsIdentity.w`

Files: [`NativeCompilerOptionsIdentity.w`](../../wheeler-conformance/src/main/wheeler/bootstrap/NativeCompilerOptionsIdentity.w) + [`ManifestSyntax.w`](../../wheeler-compiler/src/main/wheeler/compiler/closure/ManifestSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Exact schema-1 canonical YAML, bounded canonical profile names, both source-map values, complete SHA-256 publication, malformed-option rejection, and exact rewind.

Expected behavior: `bootstrap-1` without source maps and `native.test_2` with source maps reproduce stage-0 identities. A leading punctuation profile, unknown Boolean, stray space, or input beyond 256 bytes publishes nothing. Compiler options affect source identity. Treating them as command-line ambiance is how reproducible builds acquire folklore.

### `NativeToolchainIdentity.w`

Files: [`NativeToolchainIdentity.w`](../../wheeler-conformance/src/main/wheeler/bootstrap/NativeToolchainIdentity.w) + [`ManifestSyntax.w`](../../wheeler-compiler/src/main/wheeler/compiler/closure/ManifestSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Exact schema-1 canonical YAML, all three closed toolchain kinds, four lowercase SHA-256 provenance identities, complete publication, and exact rewind.

Expected behavior: Recovery-seed, independent-stage-0, and host-source records reproduce the stage-0 identity of their accepted bytes. An invented kind, uppercase digest, reordered field, missing final LF, or input beyond 512 bytes publishes nothing. Calling a compiler "independent" is evidence only that the typist found the word.

### `NativeArchive.w`

Files: [`NativeArchive.w`](../../wheeler-conformance/src/main/wheeler/packages/NativeArchive.w) + [`packages/archive/Archive.w`](../../wheeler-package/src/main/wheeler/packages/archive/Archive.w).

Covers: Wheeler-native bounded `.wpk` framing with Wheeler-computed outer and entry-data SHA-256, one frozen and parsed canonical-YAML manifest, one or two sorted checked ASCII paths with exact target-source closure, and exact consumption.

Expected behavior:

- An independently encoded `demo.archive` package with `src/Main.w` yields path/data lengths `10/4`, stage-0 decode acceptance, and exact rewind.
- Outer digest damage, re-signed data corruption, traversal, valid-but-wrong source paths, and a re-signed malformed YAML key trap.

### `NativeArchiveIdentity.w`

Files: [`NativeArchiveIdentity.w`](../../wheeler-conformance/src/main/wheeler/packages/identity/NativeArchiveIdentity.w) + [`packages/archive/Archive.w`](../../wheeler-package/src/main/wheeler/packages/archive/Archive.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Complete archive structure, payload and entry-data digests, embedded canonical manifest/source closure, final Wheeler SHA-256, stage-0 differential identity, fail-closed output, and exact rewind.

Expected behavior: A one-file canonical library archive matches the complete stage-0 archive identity. Outer-digest damage and input beyond 4,096 bytes publish nothing. An archive is not valid merely because its last 32 bytes look busy.

### `NativeLock.w`

Files: [`NativeLock.w`](../../wheeler-conformance/src/main/wheeler/packages/NativeLock.w) + [`packages/resolution/Lock.w`](../../wheeler-package/src/main/wheeler/packages/resolution/Lock.w).

Covers: Wheeler-native bounded snapshot-bound `wheeler.package.lock.yaml` parsing into caller-owned package and edge tables, with lowercase digest/name/version checks, package/dependency ordering, known-target validation, and exact canonical-byte publication.

Expected behavior:

- Schema 3 with repository/snapshot-bound sorted packages and dependency `demo.app -> demo.base` yields package count 2 and edge count 1 with exact rewind.
- Empty and generated six-package locks pass the independent stage-0 parser, while a seventh package exceeds the fixture's declared capacity and traps before publication.
- Wrong schema, uppercase digest, duplicate or unsorted packages/dependencies, and unknown targets also trap.

### `NativeLockIdentity.w`

Files: [`NativeLockIdentity.w`](../../wheeler-conformance/src/main/wheeler/packages/identity/NativeLockIdentity.w) + [`packages/resolution/Lock.w`](../../wheeler-package/src/main/wheeler/packages/resolution/Lock.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Bounded binary input, strict UTF-8 ownership, complete schema-3 lock validation, Wheeler SHA-256, stage-0 differential identity, fail-closed publication, and exact rewind.

Expected behavior: Empty and one-package locks produce the stage-0 identity. Two packages exceed this fixture's table, schema drift is still schema drift after hashing, and 2,049 bytes exceed its input budget. None publishes so much as a consolation nybble.

### `NativePlan.w`

Files: [`NativePlan.w`](../../wheeler-conformance/src/main/wheeler/packages/NativePlan.w) + [`packages/resolution/Plan.w`](../../wheeler-package/src/main/wheeler/packages/resolution/Plan.w) + [`PlanIdentity.w`](../../wheeler-package/src/main/wheeler/packages/resolution/PlanIdentity.w).

Covers: Wheeler-native bounded binary build-plan framing, payload SHA-256, one-node field decoding, name/release/path checks, target kind, execution limits, and Wheeler-rederived node identity.

Expected behavior:

- A stage-0 one-node `demo.plan:main` plan yields kind 2, limits `1000/2000/3000/4000/5000`, exact field lengths and rewind.
- A second canonical fixture verifies one package input and one identical requested/granted capability.
- Payload/digest corruption and a re-signed invalid target kind or forged node identity trap.
- Larger input/capability lists and additional nodes remain.

### `NativePlanIdentity.w`

Files: [`NativePlanIdentity.w`](../../wheeler-conformance/src/main/wheeler/packages/identity/NativePlanIdentity.w) + [`packages/resolution/Plan.w`](../../wheeler-package/src/main/wheeler/packages/resolution/Plan.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Payload digest, node-identity rederivation, structural plan validation, final Wheeler SHA-256, stage-0 differential identity, fail-closed output, and exact rewind.

Expected behavior: One canonical tool plan matches `BuildPlanCodec.identity`. Payload-digest damage or input beyond 4,096 bytes publishes nothing. Rehashing a forged plan is not validation. It is stationery.

### `NativeSha256.w`

Files: [`NativeSha256.w`](../../wheeler-conformance/src/main/wheeler/crypto/NativeSha256.w) + [`crypto/Sha256.w`](../../wheeler-core/src/main/wheeler/crypto/Sha256.w).

Covers: Wheeler-written ranged SHA-256 over immutable binary input with caller-owned digest output, region scratch, and enough block iterations for one 16 MiB physical evidence file.

Expected behavior:

- Empty, `abc`, 55/56/64-byte padding boundaries, and 100 arbitrary binary bytes match the JDK SHA-256 oracle.
- Output is exactly 32 bytes and the empty-input run rewinds exactly.
- Full 64-byte input blocks bypass padding-byte synthesis. The final partial block still uses the same checked padding relation.
- SHA evidence receives 1,000,000 startup transitions plus 200 transitions per input byte. The current 116,394-byte compiler manifest hashes in 22,277,854 history-free transitions under its 24,278,800-transition budget. This checks linear work, not the patience of a progress bar.

### `NativeBytecodeCodec.w`

Files: [`NativeBytecodeCodec.w`](../../wheeler-conformance/src/main/wheeler/compiler/NativeBytecodeCodec.w) + [`compiler/verification/Codec.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/Codec.w) + the native verifier modules.

Covers: Wheeler-native canonical identity re-encoding after complete typed structural verification. Canonical `.wbc` has one legal byte representation, so the encoder preserves every verified byte into caller-owned output and publishes only after verification succeeds.

Expected behavior:

- A stage-0 artifact re-encodes byte-for-byte and the complete run rewinds exactly.
- Damaged magic or insufficient output capacity traps before the first output write or publication.
- Copying unverified bytes is not this codec. That trick already has a name: `cp`.

### `NativeBytecodeIdentity.w`

Files: [`NativeBytecodeIdentity.w`](../../wheeler-conformance/src/main/wheeler/compiler/NativeBytecodeIdentity.w) + [`compiler/verification/Codec.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/Codec.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Complete typed artifact verification, canonical byte-for-byte re-encoding into private storage, final Wheeler SHA-256, stage-0 differential identity, fail-closed publication, and exact rewind.

Expected behavior: A bounded stage-0 artifact produces its exact content identity. Damaged magic and input beyond 4,096 bytes leave all 32 output bytes untouched. Hashing arbitrary bytes first and asking semantic questions later is a checksum utility, not a recovery boundary.

### `NativeCompilerIdentity.w`

Files: [`NativeCompilerIdentity.w`](../../wheeler-conformance/src/main/wheeler/compiler/NativeCompilerIdentity.w) + [`compiler/Core.w`](../../wheeler-compiler/src/main/wheeler/compiler/Core.w) + [`compiler/Graphs.w`](../../wheeler-compiler/src/main/wheeler/compiler/Graphs.w) + [`compiler/graphs/Matrix.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/Matrix.w) + [`compiler/graphs/plans/GraphExecutor.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/plans/GraphExecutor.w) + [`compiler/Driver.w`](../../wheeler-compiler/src/main/wheeler/compiler/Driver.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: The importable Wheeler compiler driver, private canonical `.wbc` output, native verification, ranged SHA-256 publication, stage-0 differential compiler output identity, malformed-source rejection, and exact rewind.

Expected behavior: One canonically module-qualified Wheeler source produces the SHA-256 of the byte-identical stage-0 artifact without exposing private artifact storage. An unresolved operand or source beyond 4,096 bytes publishes no identity. The executable compiler wrapper and the importable driver use one implementation. Forks are useful for eating, not for bootstrap logic.

### `NativeVerifier.w`

Files: [`NativeVerifier.w`](../../wheeler-conformance/src/main/wheeler/compiler/NativeVerifier.w) + [`compiler/verification/Verifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/Verifier.w) + [`compiler/verification/FunctionVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/FunctionVerifier.w) + [`compiler/verification/InstructionVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/InstructionVerifier.w) + [`compiler/verification/ProofVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/ProofVerifier.w).

Covers: Package-selected Wheeler verification of framing/payloads plus split instruction, operand-type, local-window, and branch-target checks over exact immutable binary `.wbc` input.

Expected behavior:

- Canonical stage-0, Boolean-negation/XOR, and immutable `byteview`-entry artifacts yield `verification = 1`.
- Damaged magic and forged operand domains fail before interpretation.
- Direct verification rewinds exactly.

### Compiler IR identities

Files: [`compiler/ir/Opcodes.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/Opcodes.w) + [`compiler/ir/OpcodeKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/OpcodeKinds.w) + [`compiler/ir/ResolvedStatements.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/ResolvedStatements.w) + [`compiler/ir/StatementKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/StatementKinds.w) + [`compiler/ir/StorageOpcodes.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/StorageOpcodes.w) + [`compiler/ir/InstructionForms.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/InstructionForms.w) + [`compiler/ir/TypeCodes.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/TypeCodes.w) + [`compiler/ir/TypeKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/TypeKinds.w) + [`compiler/ir/ProofRules.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/ProofRules.w) + [`compiler/syntax/BooleanDeclarationKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/BooleanDeclarationKinds.w) + [`compiler/syntax/EarlyReturnKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/EarlyReturnKinds.w) + [`compiler/syntax/LoopKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/LoopKinds.w) + [`compiler/syntax/calls/OneArgumentCalls.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/calls/OneArgumentCalls.w) + [`compiler/syntax/calls/TwoArgumentCallKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/calls/TwoArgumentCallKinds.w) + [`compiler/syntax/returns/EarlyReturnSources.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/returns/EarlyReturnSources.w) + [`compiler/syntax/returns/ResolvedEarlyComparisonKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/returns/ResolvedEarlyComparisonKinds.w) + [`compiler/syntax/returns/ResolvedEarlyResultKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/returns/ResolvedEarlyResultKinds.w).

Covers: Public compile-time opcode/type/proof identities, interpreter bounds, and shared bounded opcode-family predicates.

Expected behavior:

- `Verifier.w` and `Interpreter.w` import one authority.
- Constants add no VM globals or initializer, and the consumers dispatch without raw opcode/type literals.

### `NativeVm.w`

Files: [`NativeVm.w`](../../wheeler-conformance/src/main/wheeler/runtime/NativeVm.w) + [`runtime/Interpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/Interpreter.w) + [`runtime/AggregateInterpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/AggregateInterpreter.w) + [`compiler/verification/AggregateVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/AggregateVerifier.w) + [`runtime/StorageInterpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/StorageInterpreter.w) + [`compiler/verification/StorageVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/StorageVerifier.w) + [`runtime/Utf8Interpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/Utf8Interpreter.w) + [`runtime/MapInterpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/MapInterpreter.w).

Covers: Wheeler-written bounded interpreter for the self-hosted compiler artifact profile after Wheeler-native structural verification.

Expected behavior:

- A checked local/global update agrees with the stage-0 VM at `value = 12` and rewinds exactly.
- The Wheeler-written compiler emits the checked-in proof-bearing `Counter.w` artifact byte-for-byte with stage 0, then the Wheeler-written interpreter executes `CALL`/`UNCALL` back to `count = 0`.
- Control-flow tests cover signed and Boolean branches, a bounded loop, two-argument value calls, argument-bearing void calls, and the four-function `FunctionValues.w` graph.
- Stress fixtures use a thirty-five-local frame and an eighty-expectation code window. They also cover six-level `RecursiveValue.w` recursion and the early-return, `break`, and `continue` paths in `LoopControl.w`.
- Aggregate tests cover nested `Records.w` values, payload-free `FiniteEnums.w`, payload-carrying `Variants.w`, fixed arrays, slices, and fixed scalar arrays embedded in record fields and variant payloads.
- Storage and text tests cover owned regions, word and byte buffers, nested mutable borrows, valid and malformed UTF-8, and the full `FrozenUtf8.w` path with nested read-only borrows.
- Ownership tests cover returned and transferred owners in `OwnedReturns.w`, plus a signed map with a nested mutable borrow.
- Every case agrees with stage 0 across all declared globals, up to eight, and rewinds exactly.
- Forged record-field, variant-tag, array-index-local, slice-index-local, word/byte-index-local UTF-8-index-local and map-key-local operands, recursive aggregate-element arrays, a forged static-step bound, a structurally valid wrong generated inverse, and damaged artifacts and forged branch/call targets trap before interpretation.

### `NativeDurabilityReceipts.w`

Files: [`NativeDurabilityReceipts.w`](../../wheeler-conformance/src/main/wheeler/io/NativeDurabilityReceipts.w) + [`runtime/io/Receipts.w`](../../wheeler-runtime/src/main/wheeler/runtime/io/Receipts.w) + [`crypto/Sha256.w`](../../wheeler-core/src/main/wheeler/crypto/Sha256.w).

Covers: The fixed 163-byte `wheeler-durability-receipt-1` identity, separate subject/profile/evidence digests, exact parent chaining, six monotonic file-publication stages, stage-specific evidence, namespace and quorum requirements, fail-closed output, and Java/Wheeler differential identity checks.

Expected behavior: Six independently bounded runs reproduce stage 0 from `WriteCompleted` through `QuorumStable`. The final identity is `1d4fb3a8521eaa451dd37734c7fa0017e44bb7a684c004026c7c1c90c3f4d8b5`. A direct jump from write completion to file stability is rejected and leaves all 32 output bytes untouched. The fixture hashes one transition per VM run because a bound is a contract, not a dare.

### `NativeIoLifecycle.w`

Files: [`NativeIoLifecycle.w`](../../wheeler-conformance/src/main/wheeler/io/NativeIoLifecycle.w) + [`runtime/io/Lifecycle.w`](../../wheeler-runtime/src/main/wheeler/runtime/io/Lifecycle.w).

Covers: Wheeler-native bounded submission, exact work charging, terminal completion, cancellation-before-effect, known partial cancellation, late cancellation, uncertainty, resource release, exact reaping, scope closure, and fail-closed capacity. Caller-owned columns hold at most 64 operations. No provider handle or durability claim sneaks into the table wearing a fake moustache.

Expected result: four operations charge 23 work units, every terminal completion is reaped exactly once, completion-won and uncertain-after-cancellation relations remain distinct, a fifth submission is rejected without publication, and the scope closes. Complete VM rewind restores the empty tables and globals.

### `NativeSnapshot.w`

Files: [`NativeSnapshot.w`](../../wheeler-conformance/src/main/wheeler/packages/NativeSnapshot.w) + [`packages/repository/Snapshot.w`](../../wheeler-package/src/main/wheeler/packages/repository/Snapshot.w) + [`Semver.w`](../../wheeler-compiler/src/main/wheeler/compiler/packages/Semver.w).

Covers: Strict schema-1 repository snapshot layout, empty snapshots, caller-owned coordinate rows, lowercase content identities, package ordering, full stable and prerelease semantic-version precedence, exact canonical republication, independent stage-0 decoding, and full VM rewind.

Expected behavior: Canonical views through eight rows publish unchanged. `1.2.0` sorts before `1.10.0`, numeric prerelease identifiers are numbers rather than decorative strings, and stable releases follow their previews. A ninth fixture row or one extra space fails before publication. The parser loop admits more rows when you bring a larger table and enough history. Positive thinking summons neither resource.

### `NativeSnapshotIdentity.w`

Files: [`NativeSnapshotIdentity.w`](../../wheeler-conformance/src/main/wheeler/packages/identity/NativeSnapshotIdentity.w) + [`packages/repository/Snapshot.w`](../../wheeler-package/src/main/wheeler/packages/repository/Snapshot.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Strict binary-input bounds, owned byte-to-UTF-8 freezing, canonical snapshot validation, Wheeler-native SHA-256 publication, Java/Wheeler differential identities, fail-closed output, and complete VM rewind.

Expected behavior: Empty and three-release snapshots produce the same 32-byte identity as stage 0. A fourth release exceeds this fixture's caller-owned table, malformed spacing is not canonical just because it hashes cleanly, and a 2,049-byte input is over budget. All three failures publish no digest.

### `NativeWorkspace.w`

Files: [`NativeWorkspace.w`](../../wheeler-conformance/src/main/wheeler/packages/NativeWorkspace.w) + [`packages/workspace/Workspace.w`](../../wheeler-package/src/main/wheeler/packages/workspace/Workspace.w).

Covers: Wheeler-native bounded `wheeler.workspace.yaml` parsing into caller-owned member tables, with schema/key checks, checked names and paths, ordering, uniqueness, nonnesting, and exact canonical-byte publication.

Expected behavior:

- Workspace `demo-workspace` with five sorted package members is parsed and accepted by the independent stage-0 YAML parser with exact rewind.
- A sixteen-member generated workspace proves that collection parsing uses table bounds. A seventeenth member exceeds the fixture's declared capacity and traps before publication.
- Wrong schema/key, malformed names, duplicates, unsorted members, shared/nested paths, and traversal also trap.

### `NativeWorkspaceIdentity.w`

Files: [`NativeWorkspaceIdentity.w`](../../wheeler-conformance/src/main/wheeler/packages/identity/NativeWorkspaceIdentity.w) + [`packages/workspace/Workspace.w`](../../wheeler-package/src/main/wheeler/packages/workspace/Workspace.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Shared bounded binary-to-UTF-8 ownership, canonical workspace validation, Wheeler SHA-256, stage-0 differential identity, fail-closed publication, and exact rewind.

Expected behavior: A sorted two-member workspace matches the stage-0 identity. A third member exceeds this fixture's table, schema drift fails, and 1,025 bytes exceed its input budget. Bad input gets a diagnostic, not a digest-shaped souvenir.

### `NativeManifest.w`

Files: [`NativeManifest.w`](../../wheeler-conformance/src/main/wheeler/packages/NativeManifest.w) + [`compiler/packages/PackageManifest.w`](../../wheeler-compiler/src/main/wheeler/compiler/packages/PackageManifest.w) + [`PackageManifestTokens.w`](../../wheeler-compiler/src/main/wheeler/compiler/packages/PackageManifestTokens.w).

Covers: Wheeler-native bounded token parsing of canonical `wheeler.package.yaml` into caller-owned target/source/dependency/capability row tables, with closed schema/kinds, names, paths, releases, constraints, booleans, ordering, source closure, and exact canonical-byte publication.

Expected behavior:

- The canonical `demo.native` fixture yields header lengths `11/10/11`, two targets, two sources, two dependencies, and two capabilities with exact rewind.
- Empty trailing sections and a generated eight-target manifest pass the independent stage-0 parser, while a ninth target exhausts the fixture table.
- Wrong schema/kind, test-selected library, malformed name/path, unsorted source selectors, or selectors that omit the root trap before publication.

### `NativeManifestIdentity.w`

Files: [`NativeManifestIdentity.w`](../../wheeler-conformance/src/main/wheeler/packages/identity/NativeManifestIdentity.w) + [`compiler/packages/PackageManifest.w`](../../wheeler-compiler/src/main/wheeler/compiler/packages/PackageManifest.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Bounded binary manifest input, strict UTF-8 ownership, complete canonical validation, Wheeler SHA-256, stage-0 differential identity, fail-closed publication, and exact rewind.

Expected behavior: One canonical tool target produces the same manifest identity as stage 0. A second target exceeds this fixture's table, schema 2 remains the wrong schema, and 1,025 bytes exceed the declared input budget. None receives a participation digest.

## Running the suite

The canonical [`wheeler.package.yaml`](../../wheeler-conformance/wheeler.package.yaml) declares every conformance program as a deployable target:

```bash
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='check wheeler-conformance'
```

The Java stage-0 harness under `bootstrap/examples` performs differential and negative testing. Its historical Gradle name is infrastructure, not a claim that a bootstrap manifest is an example. Renaming that quarantined harness can wait until it stops buying us compatibility with old CI command lines.
