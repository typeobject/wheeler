# WIP-0502: Sixty-four-argument retained source calls

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler maintainers |
| Created | 2026-09-07 |
| Updated | 2026-09-07 |
| Area | Retained source-call lowering |
| Depends on | WIP-0049, WIP-0496 |
| Follow-up | WIP-0503 |
| Supersedes | None |
| Superseded by | None |

## Boundary

[WIP-0496](WIP-0496-eight-argument-retained-source-calls.md) established eight ordered
arguments. That closed its manifest-entry boundary, not the compiler's call
graph. At `a6384a6f6`, the stage-0 compiler executable has 1,828 functions. Of
those, 219 take more than eight parameters. The largest signature takes 55.
`compileAggregateSourceModuleProductWithImports` owns that signature. The
structured source orchestrator takes 39 parameters.

Admit up to 64 ordered identifiers through the retained ordinary-call path.
This count covers the current signatures and matches the callable-front window.
It does not widen the separate seven-argument scalar-helper compiler. Signature
size does not establish body lowering, aggregate composition, test-runner
integration, or a compiler fixed point.

## Change

`SourceCallArgumentLayouts.w` remains the only owner of retained argument extents.
Keep 256 call rows. Each argument column grows to 16,384 entries, and each two-column table
grows to 32,768 words. The argument and defining-value tables together require
524,288 bytes. Their owning private arenas must account for that storage.
Do not borrow capacity from the independent parameter, value, or statement pools.

Binding, type checks, call widths, frame placement, instruction planning, loop
emission, imported stubs, and relocation publication consume the same profile.
Argument 65 rejects before width arithmetic or indexed operand reads. Negative,
overflowing, or incomplete table windows reject before caller publication. Wrong
types and unknown defining values retain their existing precedence.

Each argument still names a prior signed or Boolean value, shared UTF-8 or
byte-view loan, or mutable word or byte loan. Loads and reborrows remain in source
order, exactly once per occurrence. The call opcode and artifact format do not
change. The 256-local frame, 4,096-token source, and 32,768-byte artifact remain
independent limits. A 64-argument signature does not guarantee that a particular
caller fits those limits.

Remove copied eight-argument dimensions and obsolete ninth-argument rejection
expectations. Keep eight-argument regressions as admitted cases, not as another
profile. Argument-bearing generated inverses still reject, including one
argument. Arbitrary argument expressions and global literal-call assignments
remain separate work.

## Evidence

- Compare complete local artifacts at nine, 55, and 64 arguments, with signed,
  Boolean, and borrowed parameter types. Cover root, loop, forwarded-return,
  guarded, and void calls without changing source order.
- Compare complete imported callable bodies, typed stubs, and relocation
  coordinates for both admitted imported spellings. Retain only closed target
  products, not dependency source.
- Fill every argument and defining-value cell across 256 repeated admitted
  call-site ranges. This isolates the argument arena from source-token and
  executable-code limits. Check sentinel preservation at the first excess.
- Reject argument 65, a wrong final type, an unknown final name, invalid windows,
  and overlapping or exhausted frames before publication. Preserve the inverse
  rejection. Small fixtures rewind. Full arena checks may run without history.
- Execute compiled wide calls through an independent wrapper. A complete byte
  comparison alone does not show that the call ran.
- Verify affected physical products, then refresh graph, executable, archive,
  manifest-hash, and lock evidence from the final source tree. Keep their current
  transition and deadline ceilings.

### Focused implementation

The focused suite currently covers 32 distinct JUnit tests. Complete native
artifacts match stage 0 at nine, 55, and 64 arguments. Complete imported artifacts
include independently constructed stubs and the inert entry. Their bodies, types,
and relocations match without dependency source. The 55- and 64-argument
signed witnesses execute one internal value call through an independent wrapper,
check its returned state, and rewind.

The complete arena fixture checks both 32,768-word tables. Small instruction and
type-composition fixtures retain full rewind. History-free capacity fixtures do
not claim whole-compiler rewind. The full-frame witness also exposed two
pre-existing off-by-one checks. Their correction and direct rejection evidence
belong to [WIP-0049](WIP-0049-bounded-native-source-product-compilation.md#complete-frame-admission).

### Final local evidence

The isolated suite passes 122 distinct JUnit tests. A separate worktree combines
this change with the unfinished member-front work and passes 23 tests, thirteen
additional identities. The total is 135 across scopes. The intact nominal test
runner remains outside that result. Two restored mutants fail the retained tests:
skipping the final argument type and ignoring an unconsumed frame type row.

Physical entry products retain 29 exact imported call targets. The archive pass
binds all 451 compiler modules and publishes 2,110 symbols and 1,812 callables.
These checks do not natively compile the complete value-planning or frame-composition
owners. The graph takes 88,834,684 transitions under the unchanged 89-million
ceiling. The 208,489-byte manifest hash still takes 39,899,856 transitions.

The compiler archive contains 3,375,574 bytes. Its SHA-256 is
`1033610af76410aa9579fc14e59addcc54ff4104f978845275e2bcc81d05dccf`.
The executable contains 1,828 functions and 236,749 instructions in 6,952,496 bytes.
Canonical manifest checks, dependent locks, and a 497-artifact workspace build
agree with the final inputs.

The locked bounded-compiler regression retains the original signed-minimum
source and matches all 568 artifact bytes. Its coverage consumer matches all
772 report bytes, seven tested transitions, and final state seven. This checks
the existing consumer path, not wide-call execution or complete compiler composition.

### Hosted acceptance

Run [34159406697](https://github.com/typeobject/wheeler/actions/runs/34159406697)
passed all 52 jobs on `76b21180613d4fd2c41a7af76b54785b51340701`. All sixteen native
compiler-package rows executed `testsOnePhysicalCompilerShardNatively` under the
unchanged twelve-minute method deadline. These results bind this milestone, not
later loan-typing changes.

## Acceptance

- [x] One production profile owns all retained argument extents.
- [x] Every admitted call position preserves ordered values, loans, and types.
- [x] Complete arena and first-excess checks preserve all caller-owned output.
- [x] Imported bodies, stubs, and relocations match independent artifacts.
- [x] Wide compiled calls execute and small publication fixtures rewind.
- [x] Inverse, frame, token, artifact, and scalar-helper limits remain separate.
- [x] Required old dimensions and rejection paths are deleted.
- [x] Physical evidence, package identities, docs, and locks agree.

## Remaining work

[WIP-0049](WIP-0049-bounded-native-source-product-compilation.md) still owns
complete physical compiler composition. Region and map arguments failed type
binding at this milestone. [WIP-0503](WIP-0503-retained-region-and-map-call-loans.md)
extends that loan profile. Qualified imported initializer and void calls have
artifact evidence. Qualified forwarded returns still reject, including a control with only signed
parameters. Arity admission does not remove that source-shape boundary.

This stage does not compile the 55-parameter aggregate owner, repair general
returns, finish WIP-0498's intact nominal test runner, or establish stage equality,
recovery, and Java-free operation.
