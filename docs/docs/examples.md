# Executable examples

Every checked-in `.w` file must pass both the compiler and the Tree-sitter grammar. Classical examples run on the VM. Quantum and hybrid examples use asynchronous `QuantumTarget` jobs on the ideal state-vector target. Before any example runs, its bytecode must complete a canonical round trip.

Each example has a fixed bound. It shows behavior that works today and names any limit it reaches. Rows that name core, compiler, runtime, or package-codec modules link to the canonical `wheeler.core`, `wheeler.compiler`, `wheeler.runtime`, and `wheeler.packages` sources. The example package uses their locked archives and keeps no duplicate copies. `QFTProof.w` is also the workspace's selected test target, so `wheeler test .` follows the normal package build and execution path.


## Examples

### `Counter.w`

Source: [`Counter.w`](../../wheeler-examples/src/main/wheeler/classical/control/Counter.w).

Covers: Generated inverse calls, reverse-block order, kernel-checked generated-inverse theorem, and byte-identical compilation by the Wheeler-written bounded compiler.

Expected result: `count = 0`.

### `BinaryTree.w`

Source: [`BinaryTree.w`](../../wheeler-examples/src/main/wheeler/classical/data/BinaryTree.w).

Covers: Fixed-capacity reversible tree slots.

Expected result: `root = left = right = 0`.

### `BootstrapControl.w`

Source: [`BootstrapControl.w`](../../wheeler-examples/src/main/wheeler/classical/control/BootstrapControl.w).

Covers: Typed signed and Boolean locals, expressions, branch joins, and a bounded counted `for`.

Expected result: `sum = 10`, `branch = 1`.

### `MinimalCompiler.w`

Files: [`MinimalCompiler.w`](../../wheeler-compiler/src/main/wheeler/MinimalCompiler.w) + [`compiler/Core.w`](../../wheeler-compiler/src/main/wheeler/compiler/Core.w) + [`compiler/Graphs.w`](../../wheeler-compiler/src/main/wheeler/compiler/Graphs.w) + [`compiler/GraphFour.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFour.w) + [`compiler/GraphFourBranches.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFourBranches.w) + [`compiler/GraphFourDag.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFourDag.w) + [`compiler/GraphFourMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFourMixed.w) + [`compiler/GraphFourNested.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFourNested.w) + [`compiler/graphs/SmallStructures.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/SmallStructures.w) + [`compiler/graphs/FourStructures.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/FourStructures.w) + [`compiler/GraphFive.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFive.w) + [`compiler/graphs/Plans.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/Plans.w) + [`compiler/graphs/five/FiveFork.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveFork.w) + [`compiler/graphs/five/FiveBranches.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveBranches.w) + [`compiler/graphs/five/FiveMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveMixed.w) + [`compiler/graphs/five/FiveForkMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveForkMixed.w) + [`compiler/graphs/five/FivePairs.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FivePairs.w) + [`compiler/graphs/five/FiveLongMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveLongMixed.w) + [`compiler/graphs/five/FiveDeepMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveDeepMixed.w) + [`compiler/graphs/five/FiveNestedMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveNestedMixed.w) + [`compiler/graphs/five/FiveNestedFork.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveNestedFork.w) + [`compiler/graphs/five/FiveDag.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveDag.w) + [`compiler/Driver.w`](../../wheeler-compiler/src/main/wheeler/compiler/Driver.w) + [`compiler/frontend/Parser.w`](../../wheeler-compiler/src/main/wheeler/compiler/frontend/Parser.w) + [`compiler/frontend/modules/Headers.w`](../../wheeler-compiler/src/main/wheeler/compiler/frontend/modules/Headers.w) + [`compiler/backend/StringTable.w`](../../wheeler-compiler/src/main/wheeler/compiler/backend/StringTable.w) + dedicated local-resolution, IR, token, scanner, code-generation, and encoding modules.

Covers: Wheeler compilation of one bounded minimal source grammar to canonical `.wbc`.

Expected behavior:

- Input `classical class LongClass { state long value = 7; entry void main() { value += 5; } }` drives global and instruction IR, canonical lexical string ordering, function descriptors, and layout.
- The 504-byte result passes Wheeler's header/directory/payload/instruction-stream verifier, including global/local/type/call operand domains, matches stage 0, and executes with `value = 12`.
- Canonical `module examples.seed;` input emits stage-0-identical qualified entry/helper strings and unqualified theorem names, including stateless helper classes. An entryless library with zero or one general helper emits the unqualified `$library` halt entry. The bounded helper-table path also emits exact canonical descriptors, signatures, code offsets, sorted strings, and that same entry for two through twenty-three explicitly public or private zero- through sixteen-parameter scalar helpers. A twenty-fourth helper still fails closed. Signed-parameter Boolean and signed helpers may use bounded equality or less-than guards, computed signed-local preludes, and up to two same-module Boolean calls with typed literal or constant early returns before one final result. A final Boolean return may forward one zero-, one-, or two-argument helper call. A signed less-than guard may instead return its parameter minus or modulo one literal or constant. The native body keeps each jump local, so an early return needs no folklore about fallthrough. A four-helper imported-constant differential crosses the former 16 KiB linked-source line and remains byte-identical. Padded two-import input beyond 32,768 linked bytes publishes nothing. The checked-in `compiler/backend/EncodingWidths.w`, `compiler/graphs/kinds/FivePlanKinds.w`, `compiler/graphs/kinds/SixGraphKinds.w`, `compiler/graphs/kinds/SevenPlanKinds.w`, `compiler/ir/Opcodes.w`, `compiler/ir/ProofRules.w`, `compiler/ir/ResolvedStatements.w`, `compiler/ir/StatementKinds.w`, `compiler/ir/StorageOpcodes.w`, `compiler/ir/TypeCodes.w`, `compiler/ir/limits/CompilerProgramLimits.w`, imported-constant `compiler/resolution/returns/ReturnOpcodeKinds.w`, imported-constant `compiler/syntax/assignments/NamedLocalAssignmentKinds.w`, imported-constant `compiler/syntax/assignments/ResolvedLocalAssignments.w`, imported-constant `compiler/syntax/assertions/ResolvedBooleanLiteralAssertions.w`, imported-constant `compiler/syntax/assertions/ResolvedLessThanAssertions.w`, imported-constant `compiler/syntax/assertions/ResolvedLocalPairAssertions.w`, `compiler/syntax/booleans/BooleanTokens.w`, imported-constant `compiler/syntax/booleans/ResolvedBooleanLiteralComparisons.w`, imported-constant `compiler/syntax/comparisons/NamedComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/LiteralComparisonOperations.w`, imported-constant `compiler/syntax/conditionals/NamedConditionalBases.w`, imported-constant `compiler/syntax/conditionals/NamedLiteralComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/NamedLocalConditionalKinds.w`, imported-constant `compiler/syntax/conditionals/NamedLocalConditionalValues.w`, imported-constant `compiler/syntax/conditionals/ResolvedLiteralComparisonKinds.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalKinds.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w`, imported-constant `compiler/syntax/conditionals/ResolvedLocalConditionalSources.w`, imported-constant `compiler/syntax/locals/NamedLongOperations.w`, imported-constant `compiler/syntax/locals/ResolvedLocalCopyKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalEqualityKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalInequalityKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLessThanKinds.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLiteralComparisons.w`, imported-constant `compiler/syntax/locals/ResolvedLocalLiteralComparisonSources.w`, imported-constant `compiler/syntax/locals/ResolvedLongOperations.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopForms.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopKinds.w`, imported-constant `compiler/syntax/loops/ResolvedLocalLoopOperands.w`, imported-constant `compiler/syntax/updates/NamedLocalUpdateKinds.w`, imported-constant `compiler/syntax/updates/ResolvedLocalUpdates.w`, imported-constant `compiler/ir/OpcodeKinds.w`, imported-constant `compiler/ir/TypeKinds.w`, imported-constant `compiler/ir/InstructionForms.w`, imported-constant `compiler/syntax/BooleanDeclarationKinds.w`, `compiler/syntax/IdentifierStarts.w`, `compiler/syntax/tokens/CompilerTokenLimits.w`, `compiler/syntax/tokens/KeywordTokens.w`, `compiler/syntax/tokens/SourceScalars.w`, `compiler/syntax/helpers/HelperAbi.w`, imported-constant `compiler/syntax/helpers/HelperSignatures.w`, imported-constant `compiler/syntax/helpers/HelperValueKinds.w`, imported-constant `compiler/syntax/EarlyReturnKinds.w`, imported-constant `compiler/syntax/EarlyReturnResultKinds.w`, `compiler/syntax/LoopKinds.w`, imported-constant `compiler/syntax/calls/CallArgumentSources.w`, imported-constant `compiler/syntax/calls/OneArgumentCalls.w`, imported-constant `compiler/syntax/calls/TwoArgumentCallKinds.w`, imported-constant `compiler/syntax/returns/EarlyReturnSources.w`, imported-constant `compiler/syntax/returns/NamedBooleanReturnKinds.w`, imported-constant `compiler/syntax/returns/NamedReturnArithmeticKinds.w`, imported-constant `compiler/syntax/returns/NamedReturnComparisonOperands.w`, imported-constant `compiler/syntax/returns/NamedSignedReturnKinds.w`, imported-constant `compiler/syntax/returns/ResolvedEarlyComparisonKinds.w`, imported-constant `compiler/syntax/returns/ResolvedEarlyResultKinds.w`, imported-function `compiler/syntax/returns/EarlyComparisonForms.w`, `compiler/syntax/returns/ResolvedLocalReturns.w`, and imported-constant `compiler/syntax/returns/ResolvedReturnCallKinds.w` are the first sixty-nine complete compiler source modules accepted byte for byte by the native compiler. The statement registries pin 128 unresolved identities, six loop-form identities, and seventy-nine resolved opcode columns without leaving them in `Tokens.w`. One direct executable dependency may own one through twenty-two helpers, while the root owns the remainder of a twenty-three-helper table. A twenty-third dependency helper and twenty-fourth total helper fail before publication. Wider function tables and multiple executable owners still fail closed. A header may contain up to sixty-four sorted unique direct imports. Empty through sixty-four-import boundaries match stage 0 when imported declarations do not enter the root artifact. Malformed, duplicate, unsorted, and excess imports publish nothing. Public, explicit-private, and unqualified helpers produce the same linked function bytes, while duplicate visibility fails before output. Separate bounded paths link every rooted tree topology over one through four imported scalar-constant modules, one four-module shared-dependency diamond, and the five-module direct star, chain, four-leaf fork, three-leaf fork beside a direct import, one chain edge beside three direct imports, a two-leaf fork beside two direct imports, two independent chains beside a direct import, a three-module chain beside two direct imports, a four-module chain beside a direct import, a nested two-leaf fork beside a direct import, two nested fork levels, and a shared diamond with a side leaf, plus a six-module direct star, full chain, five-leaf fork, one three-leaf fork beside two direct imports, one nested two-leaf fork beside two direct imports, one uneven two-branch tree beside two direct imports, one fork beside one chain and one direct import, three independent chains, one three-module chain beside one two-module chain and one direct import, one chain edge beside four direct imports, one two-leaf fork beside three direct imports, one three-module chain beside three direct imports, one four-module chain beside two direct imports, and two independent chains beside two direct imports, plus a seven-module direct star, full chain, six-leaf fork, one chain edge beside five direct imports, one two-leaf fork beside four direct imports, two independent chains beside three direct imports, three independent chains beside one direct import, one three-module chain beside four direct imports, one nested two-leaf fork beside three direct imports, one three-leaf fork beside three direct imports, one four-leaf fork beside two direct imports, and one five-leaf fork beside one direct import, into unqualified or canonical owner-qualified public root uses. Private constants may feed public exports. Leaf exports become private in the dependent and do not leak into the root. Any private name in the root publishes nothing, including a root-local collision until separate symbol tables land. One direct edge links a helper dependency to its root. One three-module chain first resolves constants into such a dependency. Both paths retain dependency function owners and private visibility. Other executable imported members, mismatched names, unsupported four-module DAGs, unsupported five-module graphs, other six- and seven-module graphs, eight or more root imports, and non-ASCII linked source also fail closed. Colliding exports, wider graphs, unrelated qualifiers, and general multi-file linking remain outside this path. The header has acquired a third chair. It still does not have a committee.
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
- Compiler token metadata allows 2,048 pre-compaction tokens. A 1,000-comment source compiles to the baseline bytes. 2,048 comments exceed the bound and trap before publication. Comments remain syntax, not a memory-allocation strategy.
- An optional theorem adds a canonically sorted proof name and 28-byte `GENERATED_INVERSE` section accepted by the proof kernel.
- Signed and Boolean literals, unary negation, literal truth assertions, and prior-local Boolean assertions work in no-global, stateful, and ordinary-helper bodies.
- They lower through `LOCAL_CONST`, `LOCAL_XOR`, `LOCAL_MOVE`, and `EXPECT_TRUE`. The compiler emits exact signed and Boolean local type windows from named token, punctuation, and statement identities.
- Signed decimal initializers and operands use canonical two's-complement form. An overlong negative magnitude fails before publication, with no substitute constant.
- The complete file length is checked against caller output capacity before the first header byte is written.
- `codeStart = 392`, `finalCursor = 504`.

### `NativeModuleCompiler.w`

Source: [`NativeModuleCompiler.w`](../../wheeler-examples/src/main/wheeler/native/compiler/NativeModuleCompiler.w).

Covers: One binary frame containing a canonical little-endian `u32` module count, one through seven length-prefixed imported sources, and the remaining root source. The fixture calls the matching bounded constant-import API and publishes only the verified artifact range.

Expected behavior: One through seven signed and Boolean constant modules with private and forward dependencies substitute through unqualified and repeated canonical owner-qualified public uses without adding runtime state and match stage 0 byte for byte. The fixture covers every rooted tree topology over one through four imported modules, including direct stars, chains, balanced and uneven forks, mixed-depth branches, and a shared-dependency diamond. It also covers all 120 input orders of five direct imports, a five-module chain, a four-leaf fork, a three-leaf fork beside a direct import, one chain edge beside three direct imports, a two-leaf fork beside two direct imports, two independent chains beside a direct import, a three-module chain beside two direct imports, a four-module chain beside a direct import, a nested two-leaf fork beside a direct import, two nested fork levels, and a shared diamond with a side leaf. It checks all 720 orders of the six-module direct star, full chain, five-leaf fork, one three-leaf fork beside two direct imports, one nested two-leaf fork beside two direct imports, one uneven two-branch tree beside two direct imports, one fork beside one chain and one direct import, three independent chains, one three-module chain beside one two-module chain and one direct import, one chain edge beside four direct imports, one two-leaf fork beside three direct imports, one three-module chain beside three direct imports, one four-module chain beside two direct imports, and two independent chains beside two direct imports. Fourteen orders of each seven-module graph place every source in every frame position in forward and reverse rings. Closed graph plans select the two-module through seven-module forms before linking. Every two- through seven-module plan records exact edges, roots, topological order, private visibility, and shared-dependency facts before topology dispatch. Two- through seven-module chain and fork executors consume the planned source order instead of probing permutations. Every four- and five-module nested, mixed, paired, and shared form, the six-module root-branch forms, and the seven-module mixed form also consume exact role order. Input order does not affect the artifact. Imported constants also lower through generated reversible helper updates and their inverse bodies. A private name in the root, colliding exports, unsupported four-module DAGs, unsupported five-module graphs, unsupported executable imported members, mismatched module names, another or disconnected six-module graph, another or disconnected seven-module graph, eight imported modules, non-ASCII source, malformed framing, and linked source above 32,768 bytes publish nothing. Seven honest imports now fit as a direct star, a row, one exceptionally well-fed fork, a short chain with five wallflowers, a small fork with four, two chains with three bystanders, three chains and a spectator, one longer chain with four spectators, a nested two-leaf fork with three witnesses, a three-leaf fork with three, a four-leaf fork with two, or a five-leaf fork with one. Pity the witnesses. The pile still needs a general graph planner.

### `FixedArrays.w`

Files: [`FixedArrays.w`](../../wheeler-examples/src/main/wheeler/classical/data/FixedArrays.w) + [`collections/FixedLongs.w`](../../wheeler-core/src/main/wheeler/collections/FixedLongs.w).

Covers: Fixed immutable arrays, signed/Boolean scalar arrays embedded in records and variant payloads, nonescaping borrowed slices, locked core reductions, checked indexing, and structural equality.

Expected result: `selected = 6`, `sum = 20`, `middleSum = 10`, `equal = 1`, `recordSelected = 7`, `variantSelected = 13`.

### `FrozenUtf8.w`

Files: [`FrozenUtf8.w`](../../wheeler-examples/src/main/wheeler/text/FrozenUtf8.w) + [`text/Utf8.w`](../../wheeler-core/src/main/wheeler/text/Utf8.w).

Covers: Strict byte-owner freezing plus locked core metrics/scalar inspection over nested nonescaping immutable UTF-8 parameter borrows.

Expected result: `byteLength = 6`, `scalarCount = 3`, `middleScalar = 8364`, `valid = 1`.

### `FiniteEnums.w`

Source: [`FiniteEnums.w`](../../wheeler-examples/src/main/wheeler/classical/data/FiniteEnums.w).

Covers: Compile-time scalar constants and a finite enum elaborated to a payload-free variant.

Expected behavior:

- Checked constant folding emits no extra global.
- Exhaustive enum matching selects `Right` and produces `selected = 7`.
- Compiler acceptance compares enum spelling with the equivalent nullary variant bytes, executes both cases, and rejects missing arms or mixed-type equality.
- Complete rewind.

### `FunctionValues.w`

Source: [`FunctionValues.w`](../../wheeler-examples/src/main/wheeler/classical/control/FunctionValues.w).

Covers: Signed/Boolean values, typed calls, right-associative logical negation, a callee loop, and a named compile-time constant used by a kernel-checked straight-line step bound.

Expected result: `result = 10`.

### `HostBinaryInput.w`

Source: [`HostBinaryInput.w`](../../wheeler-examples/src/main/wheeler/host/HostBinaryInput.w).

Covers: Explicit immutable `byteview` host input, arbitrary octet reads, bounded byte output, defensive input copying, and exact rewind.

Expected behavior:

- Input `00 ff 7f 80` gives `byteLength = 4`, `middleByte = 255`, `checksum = 510`.
- Output `00 80`.
- UTF-8 binding and source mutation are rejected.

### `HostInput.w`

Source: [`HostInput.w`](../../wheeler-examples/src/main/wheeler/host/HostInput.w).

Covers: Explicit bounded UTF-8 input and byte-output borrows with no ambient file/network access.

Expected behavior:

- For UTF-8 `A¢` and capacity 2: globals `byteLength = 3`, `scalarCount = outputLength = 2`, `firstScalar = 65`.
- Output `A!`.

### `LoopControl.w`

Source: [`LoopControl.w`](../../wheeler-examples/src/main/wheeler/classical/control/LoopControl.w).

Covers: Early typed return plus bounded `break` and `continue` edges.

Expected result: `sum = 12`, `selected = 7`.

### `modules/ModuleMain.w`

Files: [`modules/ModuleMain.w`](../../wheeler-examples/src/main/wheeler/modules/ModuleMain.w) + [`Arithmetic.w`](../../wheeler-examples/src/main/wheeler/modules/Arithmetic.w) + [`Collections.w`](../../wheeler-examples/src/main/wheeler/modules/Collections.w) + [`Results.w`](../../wheeler-examples/src/main/wheeler/modules/Results.w).

Covers: Exact source set, sorted imports, qualified calls and value types, private helper, and direct public function/record/variant/scalar-array/slice APIs. The exported `ArrayBox` carries a fixed scalar array across the module boundary.

Expected result: `result = 18`, `decoded = 9`, `arrayValue = 5`, `arrayRecordValue = 6`, `sliceValue = 15`, `nominalArrayValue = 8`, `nominalSliceValue = 26`, `qualifiedVariant = 1`.

### `NativeArtifactSetIdentity.w`

Files: [`NativeArtifactSetIdentity.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/NativeArtifactSetIdentity.w) + [`crypto/Sha256.w`](../../wheeler-core/src/main/wheeler/crypto/Sha256.w).

Covers: Exact bounded `wheeler.artifact-set/1` JSON, one through eight sorted safe ASCII `.wbc` paths, canonical positive byte counts, lowercase SHA-256 fields, the domain-separated binary identity contract, embedded-identity verification, fail-closed publication, and exact rewind.

Expected behavior: A two-artifact manifest reproduces the stage-0 set identity. Unsorted paths, uppercase digests, forged identities, unknown profile keys, a ninth artifact, or input beyond 4,096 bytes publish nothing. This fixture validates manifest metadata. The stage-0 closed-tree command still verifies every physical `.wbc` before emitting those bytes. A manifest is evidence about files only after somebody checks the files. Film at eleven.

### `NativeBootstrapFeaturesIdentity.w`

Files: [`NativeBootstrapFeaturesIdentity.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/NativeBootstrapFeaturesIdentity.w) + [`BootstrapSyntax.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/BootstrapSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Exact schema-1 canonical YAML, the complete ordered seventeen-feature `bootstrap-1` vocabulary, version 1 for every contract, complete SHA-256 publication, and exact rewind.

Expected behavior: The stage-0 feature manifest reproduces its identity. A renamed feature, changed version, missing final feature, or input beyond 2,048 bytes publishes nothing. A bootstrap feature list is closed evidence, not a buffet where the compiler leaves unsupported vegetables on the plate.

### `NativeBootstrapManifestIdentity.w`

Files: [`NativeBootstrapManifestIdentity.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/NativeBootstrapManifestIdentity.w) + [`BootstrapSyntax.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/BootstrapSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Exact schema-2 canonical recovery YAML, twenty-one lowercase identities, bounded profile syntax, stage-1/stage-2 equality, diverse-output and diagnostic equality, genuinely distinct toolchain/compiler identities, complete SHA-256 publication, and exact rewind.

Expected behavior: Complete fixed-point and diverse-compilation evidence reproduces the stage-0 manifest identity. A false fixed point, mismatched diverse output, shared alleged-independent toolchain or compiler, reordered field, or input beyond 2,048 bytes publishes nothing. The validator checks evidence relationships. It does not award independence points for wearing a false moustache.

### `NativeBootstrapModulesIdentity.w`

Files: [`NativeBootstrapModulesIdentity.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/NativeBootstrapModulesIdentity.w) + [`BootstrapSyntax.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/BootstrapSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: One through 256 sorted local source modules, zero through sixty-four externals, 768 total imports, unique paths, complete binding, rooted reachability, cycle rejection, bounded names and paths, lowercase source identities, exact schema bytes, SHA-256 publication, and rewind.

Expected behavior: Empty-import one-module, two-external one-module, and three-, five-, nine-, and seventeen-module rooted DAG closures plus a sixty-five-module star and 128- and 256-module chains reproduce stage 0. A sixty-six-module star exceeds the per-module import bound. Nine-, ten-, and thirteen-module DAGs over sixty-four externals pin the 512-, 576-, and 768-import boundaries. Sorted module and external tables use bounded binary lookup. The parser checks a 769th edge before append, and a source guard test pins that check without commissioning a long rejection fixture. A cycle, unreachable module, duplicate path, 257th local module, sixty-fifth external, unsorted external, unbound import, mismatched root, uppercase digest, traversal path, or input beyond 131,072 bytes publishes nothing. The current physical compiler closure has 175 modules, 841 imports, and 75,492 canonical bytes. The packaged executable reproduces its stage-0 identity in 26,019,683 transitions. The 256-module native bound is still deliberately smaller than the 10,000-module schema. Pretending otherwise would merely give the graph a fake moustache too.

### `NativeCompilerLimitsIdentity.w`

Files: [`NativeCompilerLimitsIdentity.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/NativeCompilerLimitsIdentity.w) + [`BootstrapSyntax.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/BootstrapSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Exact schema-1 canonical YAML, all ten required positive compiler ceilings, canonical decimal spelling, the 1,073,741,824 per-field maximum, complete SHA-256 publication, and exact rewind.

Expected behavior: The documented bootstrap limits reproduce the stage-0 identity. Zero, a leading zero, an over-ceiling value, stray whitespace, or input beyond 512 bytes publishes nothing. A missing resource limit is not an exciting opportunity for dynamic defaults.

### `NativeCompilerOptionsIdentity.w`

Files: [`NativeCompilerOptionsIdentity.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/NativeCompilerOptionsIdentity.w) + [`BootstrapSyntax.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/BootstrapSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Exact schema-1 canonical YAML, bounded canonical profile names, both source-map values, complete SHA-256 publication, malformed-option rejection, and exact rewind.

Expected behavior: `bootstrap-1` without source maps and `native.test_2` with source maps reproduce stage-0 identities. A leading punctuation profile, unknown Boolean, stray space, or input beyond 256 bytes publishes nothing. Compiler options affect source identity. Treating them as command-line ambiance is how reproducible builds acquire folklore.

### `NativeToolchainIdentity.w`

Files: [`NativeToolchainIdentity.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/NativeToolchainIdentity.w) + [`BootstrapSyntax.w`](../../wheeler-examples/src/main/wheeler/native/bootstrap/BootstrapSyntax.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Exact schema-1 canonical YAML, all three closed toolchain kinds, four lowercase SHA-256 provenance identities, complete publication, and exact rewind.

Expected behavior: Recovery-seed, independent-stage-0, and host-source records reproduce the stage-0 identity of their accepted bytes. An invented kind, uppercase digest, reordered field, missing final LF, or input beyond 512 bytes publishes nothing. Calling a compiler "independent" is evidence only that the typist found the word.

### `NativeArchive.w`

Files: [`NativeArchive.w`](../../wheeler-examples/src/main/wheeler/native/NativeArchive.w) + [`packages/archive/Archive.w`](../../wheeler-package/src/main/wheeler/packages/archive/Archive.w).

Covers: Wheeler-native bounded `.wpk` framing with Wheeler-computed outer and entry-data SHA-256, one frozen and parsed canonical-YAML manifest, one or two sorted checked ASCII paths with exact target-source closure, and exact consumption.

Expected behavior:

- An independently encoded `demo.archive` package with `src/Main.w` yields path/data lengths `10/4`, stage-0 decode acceptance, and exact rewind.
- Outer digest damage, re-signed data corruption, traversal, valid-but-wrong source paths, and a re-signed malformed YAML key trap.

### `NativeArchiveIdentity.w`

Files: [`NativeArchiveIdentity.w`](../../wheeler-examples/src/main/wheeler/native/packages/NativeArchiveIdentity.w) + [`packages/archive/Archive.w`](../../wheeler-package/src/main/wheeler/packages/archive/Archive.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Complete archive structure, payload and entry-data digests, embedded canonical manifest/source closure, final Wheeler SHA-256, stage-0 differential identity, fail-closed output, and exact rewind.

Expected behavior: A one-file canonical library archive matches the complete stage-0 archive identity. Outer-digest damage and input beyond 4,096 bytes publish nothing. An archive is not valid merely because its last 32 bytes look busy.

### `NativeLock.w`

Files: [`NativeLock.w`](../../wheeler-examples/src/main/wheeler/native/NativeLock.w) + [`packages/resolution/Lock.w`](../../wheeler-package/src/main/wheeler/packages/resolution/Lock.w).

Covers: Wheeler-native bounded snapshot-bound `wheeler.package.lock.yaml` parsing into caller-owned package and edge tables, with lowercase digest/name/version checks, package/dependency ordering, known-target validation, and exact canonical-byte publication.

Expected behavior:

- Schema 3 with repository/snapshot-bound sorted packages and dependency `demo.app -> demo.base` yields package count 2 and edge count 1 with exact rewind.
- Empty and generated six-package locks pass the independent stage-0 parser, while a seventh package exceeds the fixture's declared capacity and traps before publication.
- Wrong schema, uppercase digest, duplicate or unsorted packages/dependencies, and unknown targets also trap.

### `NativeLockIdentity.w`

Files: [`NativeLockIdentity.w`](../../wheeler-examples/src/main/wheeler/native/packages/NativeLockIdentity.w) + [`packages/resolution/Lock.w`](../../wheeler-package/src/main/wheeler/packages/resolution/Lock.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Bounded binary input, strict UTF-8 ownership, complete schema-3 lock validation, Wheeler SHA-256, stage-0 differential identity, fail-closed publication, and exact rewind.

Expected behavior: Empty and one-package locks produce the stage-0 identity. Two packages exceed this fixture's table, schema drift is still schema drift after hashing, and 2,049 bytes exceed its input budget. None publishes so much as a consolation nybble.

### `NativePlan.w`

Files: [`NativePlan.w`](../../wheeler-examples/src/main/wheeler/native/NativePlan.w) + [`packages/resolution/Plan.w`](../../wheeler-package/src/main/wheeler/packages/resolution/Plan.w) + [`PlanIdentity.w`](../../wheeler-package/src/main/wheeler/packages/resolution/PlanIdentity.w).

Covers: Wheeler-native bounded binary build-plan framing, payload SHA-256, one-node field decoding, name/release/path checks, target kind, execution limits, and Wheeler-rederived node identity.

Expected behavior:

- A stage-0 one-node `demo.plan:main` plan yields kind 2, limits `1000/2000/3000/4000/5000`, exact field lengths and rewind.
- A second canonical fixture verifies one package input and one identical requested/granted capability.
- Payload/digest corruption and a re-signed invalid target kind or forged node identity trap.
- Larger input/capability lists and additional nodes remain.

### `NativePlanIdentity.w`

Files: [`NativePlanIdentity.w`](../../wheeler-examples/src/main/wheeler/native/packages/NativePlanIdentity.w) + [`packages/resolution/Plan.w`](../../wheeler-package/src/main/wheeler/packages/resolution/Plan.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Payload digest, node-identity rederivation, structural plan validation, final Wheeler SHA-256, stage-0 differential identity, fail-closed output, and exact rewind.

Expected behavior: One canonical tool plan matches `BuildPlanCodec.identity`. Payload-digest damage or input beyond 4,096 bytes publishes nothing. Rehashing a forged plan is not validation. It is stationery.

### `NativeSha256.w`

Files: [`NativeSha256.w`](../../wheeler-examples/src/main/wheeler/native/NativeSha256.w) + [`crypto/Sha256.w`](../../wheeler-core/src/main/wheeler/crypto/Sha256.w).

Covers: Wheeler-written bounded SHA-256 over immutable binary input with caller-owned digest output and region scratch.

Expected behavior:

- Empty, `abc`, 55/56/64-byte padding boundaries, and 100 arbitrary binary bytes match the JDK SHA-256 oracle.
- Output is exactly 32 bytes and the empty-input run rewinds exactly.
- Full 64-byte input blocks bypass padding-byte synthesis. The final partial block still uses the same checked padding relation.
- SHA evidence receives 1,000,000 startup transitions plus 200 transitions per input byte. The current 75,492-byte compiler manifest hashes in 14,452,708 history-free transitions under its 16,098,400-transition budget. This checks linear work, not the patience of a progress bar.

### `NativeBytecodeCodec.w`

Files: [`NativeBytecodeCodec.w`](../../wheeler-examples/src/main/wheeler/native/NativeBytecodeCodec.w) + [`compiler/verification/Codec.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/Codec.w) + the native verifier modules.

Covers: Wheeler-native canonical identity re-encoding after complete typed structural verification. Canonical `.wbc` has one legal byte representation, so the encoder preserves every verified byte into caller-owned output and publishes only after verification succeeds.

Expected behavior:

- A stage-0 artifact re-encodes byte-for-byte and the complete run rewinds exactly.
- Damaged magic or insufficient output capacity traps before the first output write or publication.
- Copying unverified bytes is not this codec. That trick already has a name: `cp`.

### `NativeBytecodeIdentity.w`

Files: [`NativeBytecodeIdentity.w`](../../wheeler-examples/src/main/wheeler/native/compiler/NativeBytecodeIdentity.w) + [`compiler/verification/Codec.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/Codec.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Complete typed artifact verification, canonical byte-for-byte re-encoding into private storage, final Wheeler SHA-256, stage-0 differential identity, fail-closed publication, and exact rewind.

Expected behavior: A bounded stage-0 artifact produces its exact content identity. Damaged magic and input beyond 4,096 bytes leave all 32 output bytes untouched. Hashing arbitrary bytes first and asking semantic questions later is a checksum utility, not a recovery boundary.

### `NativeCompilerIdentity.w`

Files: [`NativeCompilerIdentity.w`](../../wheeler-examples/src/main/wheeler/native/compiler/NativeCompilerIdentity.w) + [`compiler/Core.w`](../../wheeler-compiler/src/main/wheeler/compiler/Core.w) + [`compiler/Graphs.w`](../../wheeler-compiler/src/main/wheeler/compiler/Graphs.w) + [`compiler/GraphFour.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFour.w) + [`compiler/GraphFourBranches.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFourBranches.w) + [`compiler/GraphFourDag.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFourDag.w) + [`compiler/GraphFourMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFourMixed.w) + [`compiler/GraphFourNested.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFourNested.w) + [`compiler/graphs/SmallStructures.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/SmallStructures.w) + [`compiler/graphs/FourStructures.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/FourStructures.w) + [`compiler/GraphFive.w`](../../wheeler-compiler/src/main/wheeler/compiler/GraphFive.w) + [`compiler/graphs/Plans.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/Plans.w) + [`compiler/graphs/five/FiveFork.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveFork.w) + [`compiler/graphs/five/FiveBranches.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveBranches.w) + [`compiler/graphs/five/FiveMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveMixed.w) + [`compiler/graphs/five/FiveForkMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveForkMixed.w) + [`compiler/graphs/five/FivePairs.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FivePairs.w) + [`compiler/graphs/five/FiveLongMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveLongMixed.w) + [`compiler/graphs/five/FiveDeepMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveDeepMixed.w) + [`compiler/graphs/five/FiveNestedMixed.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveNestedMixed.w) + [`compiler/graphs/five/FiveNestedFork.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveNestedFork.w) + [`compiler/graphs/five/FiveDag.w`](../../wheeler-compiler/src/main/wheeler/compiler/graphs/five/FiveDag.w) + [`compiler/Driver.w`](../../wheeler-compiler/src/main/wheeler/compiler/Driver.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: The importable Wheeler compiler driver, private canonical `.wbc` output, native verification, ranged SHA-256 publication, stage-0 differential compiler output identity, malformed-source rejection, and exact rewind.

Expected behavior: One canonically module-qualified Wheeler source produces the SHA-256 of the byte-identical stage-0 artifact without exposing private artifact storage. An unresolved operand or source beyond 4,096 bytes publishes no identity. The executable compiler wrapper and the importable driver use one implementation. Forks are useful for eating, not for bootstrap logic.

### `NativeVerifier.w`

Files: [`NativeVerifier.w`](../../wheeler-examples/src/main/wheeler/native/NativeVerifier.w) + [`compiler/verification/Verifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/Verifier.w) + [`compiler/verification/FunctionVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/FunctionVerifier.w) + [`compiler/verification/InstructionVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/InstructionVerifier.w) + [`compiler/verification/ProofVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/ProofVerifier.w).

Covers: Package-selected Wheeler verification of framing/payloads plus split instruction, operand-type, local-window, and branch-target checks over exact immutable binary `.wbc` input.

Expected behavior:

- Canonical stage-0, Boolean-negation/XOR, and immutable `byteview`-entry artifacts yield `verification = 1`.
- Damaged magic and forged operand domains fail before interpretation.
- Direct verification rewinds exactly.

### Compiler IR identities

Files: [`compiler/ir/Opcodes.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/Opcodes.w) + [`compiler/ir/OpcodeKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/OpcodeKinds.w) + [`compiler/ir/ResolvedStatements.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/ResolvedStatements.w) + [`compiler/ir/StatementKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/StatementKinds.w) + [`compiler/ir/StorageOpcodes.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/StorageOpcodes.w) + [`compiler/ir/InstructionForms.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/InstructionForms.w) + [`compiler/ir/TypeCodes.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/TypeCodes.w) + [`compiler/ir/TypeKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/TypeKinds.w) + [`compiler/ir/ProofRules.w`](../../wheeler-compiler/src/main/wheeler/compiler/ir/ProofRules.w) + [`compiler/syntax/BooleanDeclarationKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/BooleanDeclarationKinds.w) + [`compiler/syntax/EarlyReturnKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/EarlyReturnKinds.w) + [`compiler/syntax/LoopKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/LoopKinds.w) + [`compiler/syntax/calls/CallArgumentSources.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/calls/CallArgumentSources.w) + [`compiler/syntax/calls/OneArgumentCalls.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/calls/OneArgumentCalls.w) + [`compiler/syntax/calls/TwoArgumentCallKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/calls/TwoArgumentCallKinds.w) + [`compiler/syntax/returns/EarlyReturnSources.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/returns/EarlyReturnSources.w) + [`compiler/syntax/returns/ResolvedEarlyComparisonKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/returns/ResolvedEarlyComparisonKinds.w) + [`compiler/syntax/returns/ResolvedEarlyResultKinds.w`](../../wheeler-compiler/src/main/wheeler/compiler/syntax/returns/ResolvedEarlyResultKinds.w).

Covers: Public compile-time opcode/type/proof identities, interpreter bounds, and shared bounded opcode-family predicates.

Expected behavior:

- `Verifier.w` and `Interpreter.w` import one authority.
- Constants add no VM globals or initializer, and the consumers dispatch without raw opcode/type literals.

### `NativeVm.w`

Files: [`NativeVm.w`](../../wheeler-examples/src/main/wheeler/native/NativeVm.w) + [`runtime/Interpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/Interpreter.w) + [`runtime/AggregateInterpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/AggregateInterpreter.w) + [`compiler/verification/AggregateVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/AggregateVerifier.w) + [`runtime/StorageInterpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/StorageInterpreter.w) + [`compiler/verification/StorageVerifier.w`](../../wheeler-compiler/src/main/wheeler/compiler/verification/StorageVerifier.w) + [`runtime/Utf8Interpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/Utf8Interpreter.w) + [`runtime/MapInterpreter.w`](../../wheeler-runtime/src/main/wheeler/runtime/MapInterpreter.w).

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

Files: [`NativeDurabilityReceipts.w`](../../wheeler-examples/src/main/wheeler/native/io/NativeDurabilityReceipts.w) + [`runtime/io/Receipts.w`](../../wheeler-runtime/src/main/wheeler/runtime/io/Receipts.w) + [`crypto/Sha256.w`](../../wheeler-core/src/main/wheeler/crypto/Sha256.w).

Covers: The fixed 163-byte `wheeler-durability-receipt-1` identity, separate subject/profile/evidence digests, exact parent chaining, six monotonic file-publication stages, stage-specific evidence, namespace and quorum requirements, fail-closed output, and Java/Wheeler differential identity checks.

Expected behavior: Six independently bounded runs reproduce stage 0 from `WriteCompleted` through `QuorumStable`. The final identity is `1d4fb3a8521eaa451dd37734c7fa0017e44bb7a684c004026c7c1c90c3f4d8b5`. A direct jump from write completion to file stability is rejected and leaves all 32 output bytes untouched. The fixture hashes one transition per VM run because a bound is a contract, not a dare.

### `NativeIoLifecycle.w`

Files: [`NativeIoLifecycle.w`](../../wheeler-examples/src/main/wheeler/native/NativeIoLifecycle.w) + [`runtime/io/Lifecycle.w`](../../wheeler-runtime/src/main/wheeler/runtime/io/Lifecycle.w).

Covers: Wheeler-native bounded submission, exact work charging, terminal completion, cancellation-before-effect, known partial cancellation, late cancellation, uncertainty, resource release, exact reaping, scope closure, and fail-closed capacity. Caller-owned columns hold at most 64 operations. No provider handle or durability claim sneaks into the table wearing a fake moustache.

Expected result: four operations charge 23 work units, every terminal completion is reaped exactly once, completion-won and uncertain-after-cancellation relations remain distinct, a fifth submission is rejected without publication, and the scope closes. Complete VM rewind restores the empty tables and globals.

### `NativeSnapshot.w`

Files: [`NativeSnapshot.w`](../../wheeler-examples/src/main/wheeler/native/packages/NativeSnapshot.w) + [`packages/repository/Snapshot.w`](../../wheeler-package/src/main/wheeler/packages/repository/Snapshot.w) + [`Semver.w`](../../wheeler-package/src/main/wheeler/packages/resolution/Semver.w).

Covers: Strict schema-1 repository snapshot layout, empty snapshots, caller-owned coordinate rows, lowercase content identities, package ordering, full stable and prerelease semantic-version precedence, exact canonical republication, independent stage-0 decoding, and full VM rewind.

Expected behavior: Canonical views through eight rows publish unchanged. `1.2.0` sorts before `1.10.0`, numeric prerelease identifiers are numbers rather than decorative strings, and stable releases follow their previews. A ninth fixture row or one extra space fails before publication. The parser loop admits more rows when you bring a larger table and enough history. Positive thinking summons neither resource.

### `NativeSnapshotIdentity.w`

Files: [`NativeSnapshotIdentity.w`](../../wheeler-examples/src/main/wheeler/native/packages/NativeSnapshotIdentity.w) + [`packages/repository/Snapshot.w`](../../wheeler-package/src/main/wheeler/packages/repository/Snapshot.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Strict binary-input bounds, owned byte-to-UTF-8 freezing, canonical snapshot validation, Wheeler-native SHA-256 publication, Java/Wheeler differential identities, fail-closed output, and complete VM rewind.

Expected behavior: Empty and three-release snapshots produce the same 32-byte identity as stage 0. A fourth release exceeds this fixture's caller-owned table, malformed spacing is not canonical just because it hashes cleanly, and a 2,049-byte input is over budget. All three failures publish no digest.

### `NativeWorkspace.w`

Files: [`NativeWorkspace.w`](../../wheeler-examples/src/main/wheeler/native/NativeWorkspace.w) + [`packages/workspace/Workspace.w`](../../wheeler-package/src/main/wheeler/packages/workspace/Workspace.w).

Covers: Wheeler-native bounded `wheeler.workspace.yaml` parsing into caller-owned member tables, with schema/key checks, checked names and paths, ordering, uniqueness, nonnesting, and exact canonical-byte publication.

Expected behavior:

- Workspace `demo-workspace` with five sorted package members is parsed and accepted by the independent stage-0 YAML parser with exact rewind.
- A sixteen-member generated workspace proves that collection parsing uses table bounds. A seventeenth member exceeds the fixture's declared capacity and traps before publication.
- Wrong schema/key, malformed names, duplicates, unsorted members, shared/nested paths, and traversal also trap.

### `NativeWorkspaceIdentity.w`

Files: [`NativeWorkspaceIdentity.w`](../../wheeler-examples/src/main/wheeler/native/packages/NativeWorkspaceIdentity.w) + [`packages/workspace/Workspace.w`](../../wheeler-package/src/main/wheeler/packages/workspace/Workspace.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Shared bounded binary-to-UTF-8 ownership, canonical workspace validation, Wheeler SHA-256, stage-0 differential identity, fail-closed publication, and exact rewind.

Expected behavior: A sorted two-member workspace matches the stage-0 identity. A third member exceeds this fixture's table, schema drift fails, and 1,025 bytes exceed its input budget. Bad input gets a diagnostic, not a digest-shaped souvenir.

### `NativeManifest.w`

Files: [`NativeManifest.w`](../../wheeler-examples/src/main/wheeler/native/NativeManifest.w) + [`packages/manifest/Manifest.w`](../../wheeler-package/src/main/wheeler/packages/manifest/Manifest.w) + [`ManifestTokens.w`](../../wheeler-package/src/main/wheeler/packages/manifest/ManifestTokens.w).

Covers: Wheeler-native bounded token parsing of canonical `wheeler.package.yaml` into caller-owned target/source/dependency/capability row tables, with closed schema/kinds, names, paths, releases, constraints, booleans, ordering, source closure, and exact canonical-byte publication.

Expected behavior:

- The canonical `demo.native` fixture yields header lengths `11/10/11`, two targets, two sources, two dependencies, and two capabilities with exact rewind.
- Empty trailing sections and a generated eight-target manifest pass the independent stage-0 parser, while a ninth target exhausts the fixture table.
- Wrong schema/kind, test-selected library, malformed name/path, unsorted source selectors, or selectors that omit the root trap before publication.

### `NativeManifestIdentity.w`

Files: [`NativeManifestIdentity.w`](../../wheeler-examples/src/main/wheeler/native/packages/NativeManifestIdentity.w) + [`packages/manifest/Manifest.w`](../../wheeler-package/src/main/wheeler/packages/manifest/Manifest.w) + [`crypto/ContentIdentity.w`](../../wheeler-core/src/main/wheeler/crypto/ContentIdentity.w).

Covers: Bounded binary manifest input, strict UTF-8 ownership, complete canonical validation, Wheeler SHA-256, stage-0 differential identity, fail-closed publication, and exact rewind.

Expected behavior: One canonical tool target produces the same manifest identity as stage 0. A second target exceeds this fixture's table, schema 2 remains the wrong schema, and 1,025 bytes exceed the declared input budget. None receives a participation digest.

### `LongMap.w`

Files: [`LongMap.w`](../../wheeler-examples/src/main/wheeler/classical/data/LongMap.w) + [`collections/LongMap.w`](../../wheeler-core/src/main/wheeler/collections/LongMap.w).

Covers: Region-owned signed map using the locked core package's deterministic insert/lookup and membership API, nested exclusive mutable parameter borrows, and drop.

Expected result: `selected = 17`, `zeroKey = 5`, `present = missing = 1`.

### `OwnedReturns.w`

Source: [`OwnedReturns.w`](../../wheeler-examples/src/main/wheeler/classical/ownership/OwnedReturns.w).

Covers: Caller-region factories returning unique word, byte, immutable UTF-8, and signed-map owners through typed calls, followed by final-caller use and one consuming sink over all five owner kinds, stage-0/Wheeler interpreter parity, and exact rewind.

Expected result: `wordValue = 17`, `byteValue = 65`, `scalarCount = 2`, `mapValue = 23`.

### `Records.w`

Source: [`Records.w`](../../wheeler-examples/src/main/wheeler/classical/data/Records.w).

Covers: Nested immutable records, typed record calls, fields, and structural equality.

Expected result: `width = 5`, `equal = 1`.

### `RecursiveValue.w`

Source: [`RecursiveValue.w`](../../wheeler-examples/src/main/wheeler/classical/control/RecursiveValue.w).

Covers: Recursive signed value call under frame and step ceilings.

Expected result: `result = 6`.

### `ReversibleResult.w`

Source: [`ReversibleResult.w`](../../wheeler-examples/src/main/wheeler/classical/control/ReversibleResult.w).

Covers: A checked relation over two preserved signed parameters bound through one exact
signed local, the implicit caller-owned result slot, dedicated two-source binary-fill, call,
and return instructions, and one generated-inverse
certificate. Core conformance also commits VM history between the forward and inverse
call. The Wheeler-native compiler emits the same computed helper, adjacent slot locals,
generated bodies, computed-local collapse, and proof bytes as stage 0. Differential fixtures also select the first or second independent prelude without emitting discarded local state. The Wheeler-native interpreter executes both
call directions and checks restored vacancy against the Java VM. The inverse recomputes
both preserved sources for `34 + 8` instead of asking the debugger whether 42 looked familiar.

Expected result: `observed = 42`.

### `RegionStorage.w`

Source: [`RegionStorage.w`](../../wheeler-examples/src/main/wheeler/classical/ownership/RegionStorage.w).

Covers: Consumed region-factory results, nested exclusive word/byte loans, one shared byte loan followed by resumed mutation, strict UTF-8 scanning, affine ownership, and explicit drop.

Expected result: `first = 7`, `byteValue = 65`, `byteLength = 6`, `validUtf8 = 1`, `utf8Scalars = decodedScalars = 3`, `scalarSum = 8591`, `scratchValue = 19`.

### `Utf8Lexer.w`

Files: [`Utf8Lexer.w`](../../wheeler-examples/src/main/wheeler/text/Utf8Lexer.w) + [`lexer/Parser.w`](../../wheeler-examples/src/main/wheeler/lexer/Parser.w) + [`lexer/Scanner.w`](../../wheeler-compiler/src/main/wheeler/lexer/Scanner.w).

Covers: An explicit host UTF-8 source scanned and parsed by dependency-first modules. The scanner creates region-owned identifier, number, punctuation, escaped ASCII literal, and line or block comment tokens. It supports digits after the first identifier character, bounded decimal, hexadecimal, and binary parsing, and stable diagnostic codes with byte offset, line, and column. A typed-local-declaration parser consumes those tokens.

Expected behavior:

- Input `long x2=123;/*c*/` gives `tokenCount = 6`, `numberStart = 8`, `commentStart = 12`, `numericValue = 123`, `lexicalCode = 0`, `outputLength = 3`, `finalCursor = 17`.
- Malformed comment, literal, and token-capacity cases report codes 1, 2, and 3 with one-based source coordinates.
- Output `123`.

### `Variants.w`

Source: [`Variants.w`](../../wheeler-examples/src/main/wheeler/classical/data/Variants.w).

Covers: The one-value `Done` completion type, ordinary `done` returns, closed tagged variants, compiler-owned `Slot<long>` presence, typed construction, structural equality, and exhaustive payload selection.

Expected result: `selected = 9`, `equal = 1`, `presence = 11`.

### `WorkQueue.w`

Files: [`WorkQueue.w`](../../wheeler-examples/src/main/wheeler/classical/data/WorkQueue.w) + [`collections/LongQueue.w`](../../wheeler-core/src/main/wheeler/collections/LongQueue.w).

Covers: Bounded FIFO over an exclusive word-buffer borrow with immutable cursor and explicit `Full`/`Empty` results.

Expected result: `first = 4`, `second = 9`, `finalHead = 2`, `finalTail = 4`, `emptyObserved = fullObserved = 1`.

### `CoherentOracle.w`

Source: [`CoherentOracle.w`](../../wheeler-examples/src/main/wheeler/quantum/CoherentOracle.w).

Covers: One XOR function over classical and coherent data.

Expected result: `bit = 0`, `measured = 1`.

### `QFT.w`

Source: [`QFT.w`](../../wheeler-examples/src/main/wheeler/quantum/QFT.w).

Covers: Quantum Fourier transform whose qreg size is a compile-time constant, with a generated adjoint and kernel-checked adjoint certificate.

Expected result: `measured = 5`.

### `QFTProof.w`

Source: [`QFTProof.w`](../../wheeler-examples/src/main/wheeler/quantum/QFTProof.w).

Covers: Executable two-qubit inverse law.

Expected result: `measured = 2`.

### `QuantumOptimizer.w`

Source: [`QuantumOptimizer.w`](../../wheeler-examples/src/main/wheeler/quantum/QuantumOptimizer.w).

Covers: Two target observations, reversible acceptance update, commit, and target-free replay.

Expected result: `sample = 1`, `bestCost = 1`, `accepted = 1`.

### `QuantumNeuralNetwork.w`

Source: [`QuantumNeuralNetwork.w`](../../wheeler-examples/src/main/wheeler/quantum/QuantumNeuralNetwork.w).

Covers: One-bit coherent activation layer.

Expected result: `activation = 1`, `measured = 0`.

### `QuantumCompiler.w`

Source: [`QuantumCompiler.w`](../../wheeler-examples/src/main/wheeler/quantum/QuantumCompiler.w).

Covers: Kernel-checked adjacent-inverse normalization plus basis-state execution.

Expected result: `sourceResult = normalizedResult = 1`.

### `SurfaceCode.w`

Source: [`SurfaceCode.w`](../../wheeler-examples/src/main/wheeler/quantum/SurfaceCode.w).

Covers: Static correction kernel and generated adjoint.

Expected result: `measured = 0`.

## Scope boundaries

No checked-in example uses the planned WIP-0032 unified I/O API. `HostInput.w`, `HostBinaryInput.w`, and the current asynchronous quantum jobs cover the smaller host boundaries that exist today. They do not implement `IoScope`, operation graphs, or durability receipts. The planned conformance fixture remains in [WIP-0010](proposals/WIP-0010-executable-application-portfolio.md) until a full vertical slice can compile, parse, format, and run.

`BinaryTree.w` uses three fixed state slots. Generic nodes, allocation, ownership, and unbounded traversal are outside its scope. Those features belong to the self-hosting language work.

`QFTProof.w` is an executable conformance law. The trusted proof kernel does not accept it as a theorem. It checks that the generated adjoint restores one basis state on the semantic simulator.

`QuantumOptimizer.w` uses deterministic basis candidates so CI can check exact observations. Its event-log test records both jobs, then reproduces the classical result through replay without another target call. Parameter binding, sampled objective estimates, and convergence loops remain separate work.

`QuantumNeuralNetwork.w` shows that one coherent reversible function can act as a classical activation and a quantum permutation. Training arrays, gradients, and floating-point optimizers are not part of this example.

`QuantumCompiler.w` checks one small compiler law in two ways. Its exact cancellation rewrite carries a kernel certificate, and execution checks the basis behavior. This fixture is separate from the larger self-hosted compiler effort.

`SurfaceCode.w` is static. A full syndrome loop needs measurement, reset, bounded decoding, conditional correction, and a target that supports dynamic resident control. Wheeler must reject that workflow on a static target. It cannot hide the cost of host round trips.

## Running the suite

The canonical [`wheeler.package.yaml`](../../wheeler-examples/wheeler.package.yaml) declares every example as a package target. Use the same commands to check them all:

```bash
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='check .'
./bootstrap/gradlew -p bootstrap :tools:wheeler --args='test .'
```

See the [development guide](reference/development.md) for the full gate. The normal `check` and `treeSitterTest` tasks cover every example. None is excluded as future syntax.
