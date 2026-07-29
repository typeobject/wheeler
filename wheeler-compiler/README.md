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
- `compiler/ir` owns opcode, instruction-form, type, and proof identities.
- `compiler/backend` owns type tables, strings, control flow, returns, and encoding.
- `compiler/Core.w` assembles and verifies one already linked source.
- `compiler/Graphs.w` resolves one- through three-module graphs before invoking the core.
- `compiler/GraphFour.w` owns four-module direct, chain, and fork forms.
- `compiler/GraphFourBranches.w` owns root-heavy short chains.
- `compiler/GraphFourDag.w` owns shared-dependency four-module DAGs.
- `compiler/GraphFourMixed.w` owns transitive chains beside direct root imports.
- `compiler/GraphFourNested.w` owns the two nested four-module trees.
- `compiler/GraphFive.w` owns the bounded five-module direct star.
- `compiler/Driver.w` keeps one small stable API over the graph compilers and core.
- `compiler/verification` owns complete check-before-publication artifact validation.

`wheeler.package.yaml`, its exact lock, and the canonical workspace sources define the
closed build. Generated `vendor/` trees belong to exported offline bundles, not source
control.

## Current recovery profile

The bounded compiler accepts one class, zero or one signed global, one optional helper,
and one entry. A modular source may carry up to sixty-four sorted unique direct imports.
The header parser validates exact dotted names and rejects malformed, duplicate, unsorted,
or excess imports before publication. `compileMinimalWithConstantImport`,
`compileMinimalWithConstantImports`, `compileMinimalWithThreeConstantImports`, and
`compileMinimalWithFourConstantImports` link every rooted tree topology over one through
four imported scalar-constant modules plus one shared-dependency diamond.
`compileMinimalWithFiveConstantImports` links five direct modules and verifies all 120
input orders against one artifact. A leaf export becomes private inside its dependent, so a
root cannot acquire transitive access by spelling the leaf name loudly. Executable imported
members, mismatched module names, five-module nonstars, and more than five root imports
fail closed. General symbol resolution remains future work. Entry and helper bodies
admit at most sixty-four statements. The current slice covers typed signed
and Boolean locals, assertions, assignments, checked scalar operations, calls, results, and
narrow explicitly limited loops.

A class may place one contiguous block of at most sixty-four `const long` or `const boolean`
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
state-update values, and bounded
loop conditions and limits. Calls and mutations
may mix constants with prior locals. Helper parameters and locals cannot reuse constant names.
Constants create no global, initializer, lookup, or declaration-order artifact noise. The
native header path accepts direct import declarations. The linker resolves bounded public
scalar constants through unqualified or canonical owner-qualified uses and preserves stage-0
artifact bytes. It covers every rooted tree topology over one through four imports, one
shared-dependency diamond, and a five-module direct star while preventing intermediate
exports from reaching the root.
Repeated dependency declarations are deduplicated only when their private token sequences
match exactly. Sharing a name and a hopeful expression does not count. Root collisions with
imported private names, colliding exports, five-module nonstars, graphs with six or more
imports, and general multi-file linking remain stage-0 work until native differential artifacts pin
them down.

The canonical registry also owns `CALL_RESULT_SLOT`, `UNCALL_RESULT_SLOT`,
`RESULT_FILL_CONSTANT`, `RESULT_FILL_SOURCE`, `RESULT_FILL_BINARY`,
`RESULT_FILL_BINARY_SOURCES`, and `RETURN_RESULT_SLOT`. The Wheeler verifier accepts the first canonical signed result-slot
descriptor and generated-inverse proof. The native compiler lowers a `rev long` helper with
up to two signed parameters that returns one signed literal, evaluated constant, preserved
signed parameter, checked operation over either signed parameter and a constant, or checked
operation over two signed parameters. A checked operation may pass through one exact signed
local before return. Its entry interleaves one or more result calls with signed checks against literals,
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
