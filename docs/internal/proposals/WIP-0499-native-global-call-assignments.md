# WIP-0499: Native global call assignments

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and testing maintainers |
| Created | 2026-09-05 |
| Updated | 2026-09-07 |
| Area | Source binding, native call emission |
| Depends on | WIP-0049, WIP-0411 |
| Supersedes | None |
| Superseded by | None |

## Boundary

[WIP-0049](WIP-0049-bounded-native-source-product-compilation.md) still needs
complete source compilation. The mixed scalar fixture in
[WIP-0498](WIP-0498-native-test-member-front-admission.md) exposed a narrower
failure: `observed = helper()` passed call-width admission but did not bind the
class-state destination or select its helper consistently.

This stage extends the bounded scalar-helper compiler, not the eight-argument
retained source route. A call with zero through seven signed arguments may store
its signed result into the existing class-state slot. Arguments in this
assignment-call profile are identifiers. Literal arguments remain available to
admitted declaration calls, not direct global assignments. The slot remains a
global. Projection must not rename it into a local or remove retained declarations.

Member-front admission and test projection remain in WIP-0498. Nominal bodies,
proof compilation, general global tables, and argument-bearing inverse lowering
remain separate compiler gates.

## Binding and emission

The existing source identities and all 256 local destination columns keep their
meaning. Global assignments use `[42048, 42056)`, one identity per admitted arity,
and global ordinal zero. Argument cells do not carry destination flags.
`AssignmentCallKinds.w` owns classification and target decoding. The decoder
uses the admitted scalar forms without adding a new lowering rule.

`LocalResolution.w` counts prior parameter and primitive declaration names before
filtering their types. A unique signed local wins. A wrong-type or ambiguous name
rejects instead of falling back to class state. Only absence permits
`ClassLayouts.w` to compare the exact retained global-name range. Missing or
short metadata columns do not turn source offset zero into a state name.

Source-level parameters and locals cannot shadow class state. Method names occupy
a separate namespace and may share its spelling. The native helper profile's
existing class-constant shadow exclusion remains. That exclusion is not a claim
that stage 0 rejects every such source.

Helper selection checks every recognized declaration or assignment call target.
A later valid call cannot hide an earlier unknown helper. Result and argument
types must match before artifact publication. The emitter shares argument moves
and the result temporary with local assignments, then uses `LOCAL_STORE_GLOBAL`
instead of `LOCAL_MOVE` for the global destination.

## Program composition

Scalar helper tables retain the zero-or-one global layout, initial value, and
resolved entry call table. One-helper and multi-helper entries follow the same
composition. The scalar sequence's admission result is mandatory. Failed
statement admission cannot disappear during helper validation.

`LibraryStringPlan` carries the global string index. Its table can name the class,
entry, twenty-three helpers, the existing optional proof, and one global. Core
emission uses that index rather than a plan for a smaller string table. Helper
order and the global name's lexical position do not change binding.

Entry emission consumes resolved void and assignment calls before scalar value
calls. It preserves actual call identities when the old sole-helper call counter
is zero. Reversible helpers retain their separate lowering path. This change
does not synthesize transfer or cleanup inverses.

## Evidence

`NativeCompilerGlobalCallExampleTest` compares complete source-produced artifacts
with independent stage 0, executes them, and rewinds their execution. It covers
zero through seven arguments, mixed local/global destinations, either helper
order, method/state name sharing, and different global string positions. A
23-helper global entry passes. Helper 24, state slot two, and argument eight
reject natively without publication even though stage 0 admits those sources.

`NativeImportedHelperPresenceExampleTest` checks a constant import with an unused
void or signed helper. It compares the complete artifact, both function names,
and execution rewind with stage 0. The void source previously appeared as an
unsupported-import rejection. Unified one-helper composition admits it without
discarding its body. The remaining malformed-import checks keep their publication
assertions.

The global-call fixture also checks missing destinations, unknown helper calls,
wrong result and argument types, duplicate names, and class-state shadows. Small
accepted and rejected compiler runs restore their complete initial snapshots.
Separate coverage comparisons bind complete native reports to independent
stage-0 traces.

`NativeCompilerGlobalCallBindingExampleTest` checks counted windows, signed
extremes, wrong-type precedence, local columns 255/256, every global arity, and
unchanged rows after rewind. `NativeCompilerGlobalCallEncodingExampleTest`
compares every emitted instruction for zero through seven arguments with actual
function identities and rejects excess arities without changing caller output.

The assignment-kind method in `NativeCompilerNestedHelperEntryExampleTest`
collects the actual physical dependency closure and computes the stage-0 oracle
first. Complete artifacts compare before execution of local/global endpoints,
classification, target decoding, and first-excess rejection. This is physical
source evidence for that closure, not a whole-compiler fixed point. The dedicated
assignment-kind product test now compares all six local bodies and their imported
targets instead of retaining the old four-function count check.

The isolated physical pass binds 447 modules, 2,104 imports, 2,103 symbols, and
1,788 callables. Its linked subset contains 523 functions and 19,652 instructions.
Complete products, relocated bodies, linked bytes, verification, and execution
pass. These are this stage's measurements, not whole-compiler parity.

A locked compiler target produces a complete 1,024-byte two-helper global-call
artifact matching independent stage 0. The locked runtime produces the same
1,677-byte coverage report for its sixteen transitions and final global value
seven. All seven selected physical spine cases pass. This is not evidence that
every compiler package shard completes its deadline.

The unchanged primitive mixed-member runner fixture passes with WIP-0498's
working-tree projection. That combined check does not establish a committed
WIP-0498 integration. The larger nominal fixture still traps at
`requireMinimalProgram`. It remains executable, with its original declarations
and selection, rather than an empty-selection substitute.

## Acceptance

- [x] One identity owner distinguishes local and global destinations.
- [x] Binding rejects absence, ambiguity, and type mismatch before publication.
- [x] Helper selection, frame planning, strings, and emission consume the same destination.
- [x] Complete artifact, execution, coverage, and rewind comparisons pass.
- [x] Argument, local-column, global-slot, and helper-table limits stay distinct.
- [x] Physical assignment-kind bodies and call targets match stage 0 and execute.
- [x] The unchanged primitive mixed-member runner fixture passes with WIP-0498's working-tree projection.
- [x] Affected graph/archive evidence, current identities, and dependency locks agree.
- [x] Documentation gates and affected locked consumers pass.

## Remaining work

This stage does not close WIP-0049 or WIP-0498. Full nominal and global products,
complete frontend admission, diagnostic parity, compiler fixed-point evidence,
native recovery, and Java-free operation remain open. A separate imported-helper
fixture with root class state still rejects at the minimal compiler boundary.
Its linked source places the imported helper before the root state declaration.
WIP-0043 owns that root-prelude join. The unused-helper receipt above does not
cover it. Draft status remains until maintainers review this contract and its
evidence.
