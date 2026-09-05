# WIP-0496: Eight-argument retained source calls

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler maintainers |
| Created | 2026-09-04 |
| Updated | 2026-09-04 |
| Area | Retained source-call lowering |
| Depends on | WIP-0049, WIP-0057, WIP-0059, WIP-0060 |
| Supersedes | None |
| Superseded by | None |

## Boundary

[WIP-0049](WIP-0049-bounded-native-source-product-compilation.md) admitted
manifest-entry signatures with eight parameters while retained calls stopped at
seven arguments. Close that mismatch for ordinary root, loop, and imported calls. Keep
exact scalar and borrowed types, defining-value coordinates, and relocation
identities. Signature admission alone is not call-lowering evidence.

This change does not widen the separate bounded helper compiler, add arbitrary
argument expressions, or complete aggregate parser integration. The generated
inverse profile still rejects argument-bearing calls, including one-argument
calls. WIP-0049 retains that lowering work. Widening ordinary arity does not
supply an inverse for argument transfers.

## Change

`SourceCallArgumentLayouts.w` owns the retained profile: 256 calls, eight ordered
identifier arguments per call, and 2,048 entries in each argument column. Both
two-column argument tables contain 4,096 words. Argument binding, typed layout,
qualified-call width correction, final-return measurement, instruction planning,
loop emission, and imported signature stubs use that profile. Arena sizes include
both complete tables.

Validate arity and table extents before indexed type reads or width calculation.
A ninth argument, an unknown defining value, or an exact parameter-type mismatch
rejects before caller-owned arguments, widths, code, types, relocations, artifact
bytes, or identities are published. Previously admitted staging is private.
Frame-local, type-pool, token, code, and artifact bounds remain independent.

Delete the duplicated seven-argument table constants. Do not leave a second
layout behind as a compatibility path. Artifact encodings and call opcodes do
not change. The admitted retained source profile grows by one argument.

The orchestrator's imported-target buffer checks move to
`StructuredSourceTargets.w`. The call takes eight arguments and preserves the
existing check-before-allocation order. This keeps the orchestrator inside the
unchanged 4,096-token scanner arena, which counts comments before compaction.

## Evidence

- `NativeCompilerSourceCallArgumentProductsExampleTest` compares every argument,
  type, defining-value, and offset cell. It repeats one valid call-site range to
  fill the complete arena. Other compiler pools have separate bounds.
- `NativeCompilerSourceCallLayoutProductsExampleTest`,
  `NativeCompilerSourceCallInstructionProductsExampleTest`, and
  `NativeCompilerLoopCallProductsExampleTest` check eight-argument extents,
  last complete target windows, invalid indexes and arities, and every unchanged
  output row. Rejected code and relocation identities remain untouched.
- `NativeCompilerEightArgumentSourceProductExampleTest` compares complete local
  artifacts and imported callable frames and instructions after exact target
  rebinding. Root and loop value and void calls cover both imported spellings.
  Signed, Boolean, and void stubs preserve all eight parameter types.
  Final and Boolean-guarded local calls also match stage 0. Wrong eighth types,
  unknown values, and ninth arguments leave artifact and identity buffers empty.
  One- and eight-argument reversible calls preserve the existing rejection, even
  after private forward-artifact staging.
- `NativeCompilerStructuredSourceTokenBudgetExampleTest` catches orchestration
  token overflow before the archive pass.
- The confirming archive and retained-closure checks pass. The selected body set
  and linked executable identity are unchanged. This is regression evidence for
  that subset, not a complete compiler fixed point.

## Acceptance

- [x] Argument binding fills the eighth position and the complete argument arena
  with exact types and defining-value coordinates. First-excess and malformed
  candidates leave every output cell unchanged.
- [x] Typed layout and instruction/code planning reject bad arities and target
  windows before publication.
- [x] Root and loop calls with eight mixed scalar and borrowed arguments match
  stage 0 in complete artifact bytes, including frame types and instructions.
- [x] Imported calls retain exact target signatures and relocation identities
  without dependency source. A wrong eighth type or ninth argument publishes no
  artifact or identity.
- [x] Focused regressions and the necessary physical closure pass. Graph and
  archive identities, current docs, examples, and dependent locks agree.
- [x] Old argument extents and redundant test scaffolding are removed.

## Remaining work

Complete target and collection composition, every physical compiler body, final
linking, and stage-1/stage-2 equality remain open in the parent contracts. This
record closes one call boundary, not self-hosting.
