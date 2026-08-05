# Wheeler compiler

This directory owns the Wheeler-written compiler package. Sources under
`src/main/wheeler` define the scanner, compiler, verifier, codecs, and package driver.
Java does not get a weekend cottage here.

## Package boundary

`compiler/Core.w` owns canonical lowering and artifact verification. `compiler/Driver.w`
owns the stateless source-graph API. `MinimalCompiler.w` is its executable wrapper and
publishes only the verified output range. Identity tools call the same API
instead of maintaining a shadow compiler with a fake moustache.

The package keeps responsibilities narrow:

- `compiler/frontend` owns bounded token, structure, body, and statement parsing.
- `compiler/syntax` owns statement and call shapes.
- `compiler/resolution` owns typed locals, helper calls, operands, and scalar class
  constants.
- `compiler/ir` owns statement, opcode, instruction-form, type, and proof identities.
- `compiler/backend` owns type tables, strings, control flow, returns, and encoding.
- `compiler/Core.w` assembles and verifies one already linked source.
- `compiler/Graphs.w` executes one- through three-module graph plans before invoking the core.
- `compiler/GraphFour.w` owns four-module direct, chain, and fork forms.
- `compiler/GraphFourBranches.w` owns root-heavy short chains.
- `compiler/GraphFourDag.w` owns shared-dependency four-module DAGs.
- `compiler/GraphFourMixed.w` owns transitive chains beside direct root imports.
- `compiler/GraphFourNested.w` owns the two nested four-module trees.
- `compiler/graphs/SmallStructures.w` classifies every admitted two- and three-module topology.
- `compiler/graphs/FourStructures.w` classifies every admitted four-module topology.
- `compiler/GraphFive.w` coordinates bounded five-module forms.
- `compiler/graphs/FiveStructures.w` records exact five-module structure and source order.
- `compiler/graphs/Plans.w` maps exact five-module structure to executor identities.
- `compiler/graphs/Matrix.w` records canonical edges, roots, order, visibility, and sharing facts.
- `compiler/graphs/five/FiveFork.w` owns the five-module four-leaf fork.
- `compiler/graphs/five/FiveBranches.w` owns a three-leaf fork beside a direct import.
- `compiler/graphs/five/FiveMixed.w` owns one chain edge beside three direct imports.
- `compiler/graphs/five/FiveForkMixed.w` owns a two-leaf fork beside two direct imports.
- `compiler/graphs/five/FivePairs.w` owns two independent chains beside a direct import.
- `compiler/graphs/five/FiveLongMixed.w` owns a three-module chain beside two direct imports.
- `compiler/graphs/five/FiveDeepMixed.w` owns a four-module chain beside one direct import.
- `compiler/graphs/five/FiveNestedMixed.w` owns a nested two-leaf fork beside a direct import.
- `compiler/graphs/five/FiveNestedFork.w` owns two nested fork levels.
- `compiler/graphs/five/FiveDag.w` owns a shared diamond with one side leaf.
- `compiler/graphs/FiveChain.w` executes the exact planned five-module chain order.
- `compiler/GraphSix.w` coordinates bounded six-module forms.
- `compiler/graphs/six/Mixed.w` owns one chain edge beside four direct imports, one two-leaf fork beside three direct imports, one three-leaf fork beside two direct imports, one three-module chain beside three direct imports, and one four-module chain beside two direct imports.
- `compiler/graphs/six/Nested.w` owns a nested two-leaf fork beside two direct imports.
- `compiler/graphs/six/Uneven.w` owns an uneven two-branch tree beside two direct imports.
- `compiler/graphs/six/Separate.w` owns a fork and chain beside a direct import, three independent chains, and long and short chains beside a direct import.
- `compiler/graphs/six/Pairs.w` owns two independent chains beside two direct imports.
- `compiler/graphs/six/SixPlans.w` extracts and validates the rooted six-module graph.
- `compiler/graphs/six/Structures.w` owns exact six-module classification and role order.
- `compiler/Driver.w` keeps one small stable API over the graph compilers and core.
- `compiler/verification` owns complete check-before-publication artifact validation.

`wheeler.package.yaml`, its exact lock, and the canonical workspace sources define the
closed build. Generated `vendor/` trees belong to exported offline bundles, not source
control.

## Current recovery profile

The bounded compiler accepts one class, zero or one signed global, one optional helper,
and one entry. It also emits the canonical unqualified `$library` halt entry for an
entryless library. `frontend/helpers/ScalarHelperTables.w` owns bounded helper lookup, duplicate checks, and call resolution. `ScalarHelperLibraries.w` parses members. `ScalarHelperParsing.w` assembles declarations. `ScalarHelperCallResolution.w` resolves one member, `ScalarHelperResolution.w` validates the complete resolved table, and `ScalarHelperPrograms.w` constructs the IR. That path accepts zero or one general helper, or two through twenty-three explicitly
public or private zero- through sixteen-parameter scalar helpers. Signed-parameter Boolean and signed helpers may
contain bounded equality or less-than guards, computed signed-local preludes, and up to two same-module Boolean calls with typed
early returns. A final Boolean return may forward one zero-, one-, or two-argument helper call. A signed less-than guard may
return its parameter minus or modulo one scalar. A twenty-fourth helper fails
before publication. The checked-in `compiler/backend/EncodingWidths.w`, `compiler/graphs/kinds/FivePlanKinds.w`, `compiler/graphs/kinds/SixGraphKinds.w`,
`compiler/graphs/kinds/SevenPlanKinds.w`, `compiler/ir/Opcodes.w`,
`compiler/ir/ProofRules.w`, `compiler/ir/ResolvedStatements.w`,
`compiler/ir/StatementKinds.w`, `compiler/ir/StorageOpcodes.w`, `compiler/ir/TypeCodes.w`,
`compiler/ir/limits/CompilerProgramLimits.w`,
imported-constant `compiler/resolution/returns/ReturnOpcodeKinds.w`, imported-constant
`compiler/syntax/assignments/NamedLocalAssignmentKinds.w`, imported-constant
`compiler/syntax/assignments/ResolvedLocalAssignments.w`, imported-constant
`compiler/syntax/assertions/ResolvedBooleanLiteralAssertions.w`, imported-constant
`compiler/syntax/assertions/ResolvedLessThanAssertions.w`, imported-constant
`compiler/syntax/assertions/ResolvedLocalPairAssertions.w`,
`compiler/syntax/booleans/BooleanTokens.w`, imported-constant
`compiler/syntax/booleans/ResolvedBooleanLiteralComparisons.w`, imported-constant
`compiler/syntax/comparisons/NamedComparisonKinds.w`, imported-constant
`compiler/syntax/conditionals/LiteralComparisonOperations.w`, imported-constant
`compiler/syntax/conditionals/NamedConditionalBases.w`, imported-constant
`compiler/syntax/conditionals/NamedLiteralComparisonKinds.w`, imported-constant
`compiler/syntax/conditionals/NamedLocalConditionalKinds.w`, imported-constant
`compiler/syntax/conditionals/NamedLocalConditionalValues.w`, imported-constant
`compiler/syntax/conditionals/ResolvedLiteralComparisonKinds.w`, imported-constant
`compiler/syntax/conditionals/ResolvedLocalConditionalKinds.w`, imported-constant
`compiler/syntax/conditionals/ResolvedLocalConditionalOperands.w`, imported-constant
`compiler/syntax/conditionals/ResolvedLocalConditionalSources.w`, imported-constant
`compiler/syntax/locals/NamedLongOperations.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalCopyKinds.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalEqualityKinds.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalInequalityKinds.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalLessThanKinds.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalLiteralComparisons.w`, imported-constant
`compiler/syntax/locals/ResolvedLocalLiteralComparisonSources.w`, imported-constant
`compiler/syntax/locals/ResolvedLongOperations.w`, imported-constant
`compiler/syntax/loops/ResolvedLocalLoopForms.w`, imported-constant
`compiler/syntax/loops/ResolvedLocalLoopKinds.w`, imported-constant
`compiler/syntax/loops/ResolvedLocalLoopOperands.w`, imported-constant
`compiler/syntax/updates/NamedLocalUpdateKinds.w`, imported-constant
`compiler/syntax/updates/ResolvedLocalUpdates.w`, imported-constant `compiler/ir/OpcodeKinds.w`, imported-constant `compiler/ir/TypeKinds.w`,
imported-constant `compiler/ir/InstructionForms.w`, imported-constant
`compiler/syntax/BooleanDeclarationKinds.w`, `compiler/syntax/IdentifierStarts.w`,
`compiler/syntax/tokens/CompilerTokenLimits.w`, `compiler/syntax/tokens/KeywordTokens.w`, `compiler/syntax/tokens/SourceScalars.w`,
`compiler/syntax/helpers/HelperAbi.w`, imported-constant `compiler/syntax/helpers/HelperSignatures.w`,
imported-constant `compiler/syntax/helpers/HelperValueKinds.w`, imported-constant
`compiler/syntax/EarlyReturnKinds.w`, imported-constant
`compiler/syntax/EarlyReturnResultKinds.w`, `compiler/syntax/LoopKinds.w`, imported-constant
`compiler/syntax/calls/CallArgumentSources.w`, imported-constant
`compiler/syntax/calls/OneArgumentCalls.w`, imported-constant
`compiler/syntax/calls/TwoArgumentCallKinds.w`, imported-constant
`compiler/syntax/returns/EarlyReturnSources.w`, imported-constant
`compiler/syntax/returns/NamedBooleanReturnKinds.w`, imported-constant
`compiler/syntax/returns/NamedReturnArithmeticKinds.w`, imported-constant
`compiler/syntax/returns/NamedReturnComparisonOperands.w`, imported-constant
`compiler/syntax/returns/NamedSignedReturnKinds.w`, imported-constant
`compiler/syntax/returns/ResolvedEarlyComparisonKinds.w`, imported-constant
`compiler/syntax/returns/ResolvedEarlyResultKinds.w`, imported-function
`compiler/syntax/returns/EarlyComparisonForms.w`, `compiler/syntax/returns/ResolvedLocalReturns.w`,
and imported-constant `compiler/syntax/returns/ResolvedReturnCallKinds.w` modules compile byte for byte with stage 0.
`StatementKinds.w` owns 128 unresolved statement identities. `LoopKinds.w` owns six loop-form
identities. `ResolvedStatements.w` owns seventy-nine resolved columns. `Tokens.w` now sticks to
lexical work instead of running a parser-IR registry from the back room. Sixty-nine real self-source modules beat sixty-one motivational slides. One of them now owns conditional base mapping instead of leaving it in the parser's coat pocket. The bar has retained counsel. A modular source may carry up to sixty-four sorted unique direct imports.
The header parser validates exact dotted names and rejects malformed, duplicate, unsorted,
or excess imports before publication. `compileMinimalWithConstantImport`,
`compileMinimalWithConstantImports`, `compileMinimalWithThreeConstantImports`, and
`compileMinimalWithFourConstantImports` link every rooted tree topology over one through
four imported scalar-constant modules plus one shared-dependency diamond.
`compileMinimalWithFiveConstantImports` first builds a closed topology plan, then links
the five-module direct star, chain, four-leaf fork, three-leaf fork beside a direct import, one chain edge beside three direct imports, a two-leaf fork beside two direct imports, two independent chains beside a direct import, a three-module chain beside two direct imports, a four-module chain beside a direct import, a nested two-leaf fork beside a direct import, two nested fork levels, or a shared diamond with a side leaf. `compileMinimalWithSixConstantImports` links the six-module direct star, full chain, five-leaf fork, one three-leaf fork beside two direct imports, one nested two-leaf fork beside two direct imports, one uneven two-branch tree beside two direct imports, one fork beside one chain and one direct import, three independent chains, one three-module chain beside one two-module chain and one direct import, one chain edge beside four direct imports, one two-leaf fork beside three direct imports, one three-module chain beside three direct imports, one four-module chain beside two direct imports, and two independent chains beside two direct imports. `compileMinimalWithSevenConstantImports` links a seven-module direct star, full chain, six-leaf fork, one chain edge beside five direct imports, one two-leaf fork beside four direct imports, two independent chains beside three direct imports, three independent chains beside one direct import, one three-module chain beside four direct imports, one four-leaf fork beside two direct imports, or one five-leaf fork beside one direct import. Differential fixtures exhaust all 120 five-module orders and all 720 orders of each six-module graph. Fourteen orders of each seven-module graph put every source in every frame position in forward and reverse rings. Every two- through seven-module planner records exact edges, roots, topological order, private visibility, and shared-dependency facts before topology dispatch. Two- through seven-module chain and fork executors consume their canonical source order before rewriting. Every four- and five-module executor, the six-module root-branch executors, and the seven-module mixed executor also consume exact topology-specific role order. A leaf
export becomes private inside its dependent, so a root cannot acquire transitive access by
spelling the leaf name loudly. One bounded direct edge may give a dependency one through twenty-two helpers while the root owns the remainder of the twenty-three-helper table.
A twenty-third dependency helper fails before publication. One three-module chain may first resolve a constant owner into that dependency. Both paths preserve
dependency function names and private visibility. Other executable imported members,
mismatched module names, unsupported four-module DAGs, unsupported five-module graphs, other
six- and seven-module graphs, and eight or more root imports fail closed. General symbol
resolution remains future work. Entry and helper bodies
admit at most sixty-four statements. Scanner metadata admits 2,048 tokens across a 32,768-byte
physical or linked source window. Linked graph arenas admit 32,768 bytes. A four-helper differential
crosses the former 16 KiB line, and a padded two-import source pins the new refusal boundary. The
current slice covers typed signed and Boolean locals,
assertions, assignments, checked scalar operations, calls, results, and narrow explicitly limited
loops.

A class may place one contiguous block of at most 256 `const long` or `const boolean`
declarations around its optional signed state and before its helper or entry. Constants may
initialize that state, including a forward reference when state comes first. Splitting the
constant block around state fails rather than creating two lookup rules. Their bounded
expressions admit decimal, hexadecimal, and binary
integers, Booleans, parentheses, checked arithmetic, `!`, `^`, `&`, `==`, `<`, checked
`rotateRight32`, and forward same-class dependencies. A lookup allows 4,096 evaluation steps, dependency paths stop at
sixty-four declarations, and parentheses stop at depth thirty-two. Cycles, unknown names,
type errors, malformed forms, and arithmetic traps publish nothing.

The resolver substitutes evaluated values into matching local declarations, scalar helper
returns, scalar assignments, checked signed updates including generated reversible helper updates,
one- or two-argument scalar helper calls,
right operands of signed arithmetic and ordering expressions, signed or Boolean equality and
inequality expressions,
signed arithmetic or typed scalar comparison returns, signed or Boolean equality assertions, signed ordering assertions, conditions and their
state-update values, bounded loop conditions and limits, and affine-region byte and allocation
limits. Calls and mutations
may mix constants with prior locals. Helper parameters and locals cannot reuse constant names.
Constants create no global, initializer, lookup, or declaration-order artifact noise. The
native header path accepts direct import declarations. The linker resolves bounded public
scalar constants through unqualified or canonical owner-qualified uses and preserves stage-0
artifact bytes. It covers every rooted tree topology over one through four imports, one
shared-dependency diamond, the five-module direct star, chain, four-leaf fork, three-leaf fork beside a direct import, one chain edge beside three direct imports, a two-leaf fork beside two direct imports, two independent chains beside a direct import, a three-module chain beside two direct imports, a four-module chain beside a direct import, a nested two-leaf fork beside a direct import, two nested fork levels, and a shared diamond with a side leaf, plus the six-module direct star, full chain, five-leaf fork, one three-leaf fork beside two direct imports, one nested two-leaf fork beside two direct imports, one uneven two-branch tree beside two direct imports, one fork beside one chain and one direct import, three independent chains, one three-module chain beside one two-module chain and one direct import, one chain edge beside four direct imports, one two-leaf fork beside three direct imports, one three-module chain beside three direct imports, one four-module chain beside two direct imports, and two independent chains beside two direct imports, plus the seven-module direct star, full chain, six-leaf fork, one chain edge beside five direct imports, one two-leaf fork beside four direct imports, two independent chains beside three direct imports, three independent chains beside one direct import, one three-module chain beside four direct imports, one four-module chain beside three direct imports, one three-module chain beside one two-module chain and two direct imports, one nested two-leaf fork beside three direct imports, one three-leaf fork beside three direct imports, one four-leaf fork beside two direct imports, and one five-leaf fork beside one direct import, while preventing intermediate
exports from reaching the root.
Repeated dependency declarations are deduplicated only when their private token sequences
match exactly. Sharing a name and a hopeful expression does not count. Root collisions with
imported private names, colliding exports, unsupported four-module DAGs, unsupported five-module graphs, other six- and seven-module graphs, graphs with eight or more imports, and general multi-file linking remain stage-0 work until native differential artifacts pin
them down.

The canonical registry also owns `CALL_RESULT_SLOT`, `UNCALL_RESULT_SLOT`,
`RESULT_FILL_CONSTANT`, `RESULT_FILL_SOURCE`, `RESULT_FILL_BINARY`,
`RESULT_FILL_BINARY_SOURCES`, and `RETURN_RESULT_SLOT`. The Wheeler verifier accepts the first canonical signed result-slot
descriptor and generated-inverse proof. The native compiler lowers a `rev long` helper with
up to two signed parameters that returns one signed literal, evaluated constant, preserved
signed parameter, checked operation over either signed parameter and a constant, or checked
operation over two signed parameters. Independent checked operations may bind signed locals before the tail return selects one exact relation. Its entry interleaves one or more result calls with signed checks against literals,
constants, or other results already produced. The emitted function flags, adjacent slot locals, forward
and inverse bodies, call, return, and proof bytes match stage 0 exactly. The bounded
Wheeler interpreter executes both call directions against the same artifact. A committed
VM history remains irrelevant to the generated inverse, as it should unless time travel
has acquired a debugger dependency.

The narrow loop body and local constant graph are deliberate limits, not parser folklore.
Unsupported syntax fails before output publication. Each extension must match stage 0 byte
for byte before the profile claims it.

## Promotion

The temporary Java seed lives in [`../bootstrap/stage0`](../bootstrap/stage0). It compiles
this package into stage 1. Stage 1 must then compile the same sources into a byte-identical
stage 2. Promotion also requires the diverse-bootstrap and provenance evidence from
WIP-0007. A fixed point catches drift. Repetition alone does not exorcise a malicious
ancestor.

Examples consume this package through exact locks. They do not carry compiler copies.
New implementation features land in Wheeler once the recovery profile can express and
test them. Any Java addition needs a concrete stage-crossing reason and a deletion
condition.
