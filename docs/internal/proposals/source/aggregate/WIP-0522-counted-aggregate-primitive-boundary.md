# WIP-0522: Counted aggregate primitive boundary

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler and bootstrap maintainers |
| Created | 2026-09-13 |
| Updated | 2026-09-13 |
| Area | Self-hosting, aggregate phases, counted primitive products |
| Depends on | WIP-0054, WIP-0514, WIP-0517, WIP-0519, WIP-0520 |
| Supersedes | None |
| Superseded by | None |

## Split from WIP-0516

WIP-0516 combines the counted primitive call with original globals, detached
claims, projection coordinates, and final nominal joins. This proposal isolates
the production call boundary and its private phases. It does not remove any
requirement from WIP-0516 or establish compilation of the physical aggregate
owner. That owner's full frame still exceeds the native limit.

The old boundary copied an exact source buffer and called a wrapper around
`compileMinimalCore`. The counted compiler already accepts a byte range. Keep
that range explicit and remove both the obsolete wrapper and redundant copy.
Do not replace either with another source family or exception-driven fallback.

## Contract

1. Call `compileAggregatePrimitiveSource` from the real aggregate adapter.
   Stage callable and parameter ranges through the shared fronts. Materialize
   primitive types and use the existing counted archive compiler and encoder.
2. Carry target intent, original source and class windows, constant count, and
   module owner in `AggregateSourceRequest`. Keep borrowed scalar rows and name
   windows separate. Validate every active scalar fact, including unused rows.
3. Compile claim-free private primitive views. Reject attached claims rather
   than treating a placeholder bound as final proof. WIP-0516 must bind original
   claims and origins before projection and verify the final nominal code.
4. Preserve the intact aggregate fixture and its counted imported products.
   Dependency source bodies must not cross the compilation boundary. Neither
   selected helper families nor a stage-0 nominal artifact may replace it.
5. Extract original-source value binding and operation resolution into coherent
   phases. They may change private scratch on rejection. Never lend caller
   publication buffers to those phases.
6. Validate all seventeen word and three byte publication backings before owned
   staging allocation. Construct the complete outer report before any caller
   copy. Publication helpers must allocate nothing and add no semantic checks.
7. Remove the exact-source allocation. Lend the selected carrier window directly
   to the counted primitive compiler, then drop that buffer before composition.
8. Measure complete frames for every new phase. Keep them within 256 locals.
   Record the remaining aggregate orchestrator separately, without implying that
   its parameter count or source-token fit proves native frame acceptance.

## Bounds and ownership

The primitive workspace contains these word cells:

```text
callable cells  = 4096 * (14 + 1)
parameter cells = 16384 * (3 + 1)
token cells     = 4096 * 3
module/cursor   = 2 + 1
word cells      = 139267
bytes           = word cells * 8 + 32768 = 1146904
buffer IDs      = 15 + 4 + 3 + 2 + 1 = 25
```

The aggregate workspace retains 249,280 word cells, seven simultaneous source
windows, and three code/digest windows. Its reservation remains 2,268,704 bytes.
Removing the exact copy reduces lifetime IDs from 40 to 39. The primitive call
now keeps the full carrier backing live, not a shorter exact allocation. This
saves a copy and an ID, not necessarily peak live bytes across nested arenas.

The binding phases introduce no owned buffers or regions. They still allocate
parser and result records, including one three-field value-phase report. The
preflight and copy helpers allocate neither records nor owned storage.

The source window remains 32,768 bytes with 4,096 raw tokens. Callable staging
admits 64 rows, but final verification admits only 24 functions, including a
library entry. Preserve both bounds. Calculate capacity probes from their actual
owners rather than changing interpreter, scanner, or VM limits.

A local target name can contain a 256-byte qualifier, the two-byte `::`
separator, and a 256-byte identifier. `StructuredSourceTargets.w` derives the
514-byte walk from those component bounds. Its old 256-iteration walk rejected
legal qualified names. The component limits remain unchanged.

## Development evidence

The intact fixture reaches a 1,123-function driver with no `compileMinimal`
function. Complete prepared inputs, active products, inactive tails, report
ordering, late rejection, cleanup, and publication rewind/replay agree.
Every publication backing rejects both its predecessor and successor size
before private storage allocation. Carrier rejection retains real rewind.
The other backing probes run history-free.

Measured frames:

| Phase | Parameters | Locals |
| --- | ---: | ---: |
| Primitive window validation | 7 | 67 |
| Primitive compilation | 12 | 234 |
| Original-source values | 27 | 186 |
| Aggregate operations | 27 | 152 |
| Publication backing validation | 20 | 120 |
| Word publication copy | 4 | 36 |
| Byte publication copy | 3 | 16 |
| Qualified local target binding | 20 | 202 |
| Remaining aggregate orchestrator | 56 | 828 |

The aggregate orchestrator previously used 1,308 locals in this development
branch. Extraction reduces that count but does not close its frame requirement.
Forty-two example invocations, including two token guards, pass with 32 source
checks and twelve documentation checks. Capacity probes compile the
full 32,768-byte source with 24 final functions and a 514-byte target name. The
source, callable count, identifier, and qualifier successors reject unchanged.
A full 16,384-row scalar packet also compiles. Its count successor and an invalid
last unused row reject without publication. These are API probes, not native
command timing evidence.

Physical intake passes for 485 modules, 2,462 constants, 1,909 callables, and
2,342 imports. Archive intake takes 336.119 seconds. Independent CLI and measured
archives and graphs match byte-for-byte. The selected 603,784-byte linked
reference remains unchanged, so its long execution was not repeated. Four
package archives, four refreshed locks, and all 181 workspace targets agree.

Tree-sitter passes its seventeen grammar cases, six-root physical parse, and
queries. Two documentation sites match all 34 files. The review tree has no
text file over 1,000 lines, but nineteen maintained directories and 45 literal
directories still exceed ten files. Exact-tree installation, commit, push, and
hosted acceptance remain outstanding.

The locked consumer builds a complete 4,642,200-byte driver without a minimal
compiler function and consumes the intact 304-byte nominal source. Its 688-byte
primitive artifact agrees with an independent Java compilation of the private
primitive view. All prepared caller inputs, product rows, tails, report fields,
and digest agree before cleanup. This verifies an API consumer, not nominal
compilation or a compiler fixed point.

The consumer reaches inner primitive publication at transition 1,350,651, outer
publication at 1,454,976, and halt at 1,455,107. Rewinding and replaying all 104,456
transitions from the inner checkpoint restores complete snapshots. The command
stays within 4,000,000 steps. The observer measures 14,864,219 peak live buffer
bytes, including host loans, with 399 lifetime buffers and 66 regions. Those
measurements exclude parser/result-record storage and describe this intact case.

## Acceptance

- [x] The genuine aggregate caller uses counted primitive products without a minimal fallback.
- [x] Complete artifacts, scalar facts, entry intent, projections, and caller state agree with independent controls.
- [x] Every publication backing and representative late failures preserve prepared caller state.
- [x] Counted primitive publication through composition, cleanup, and representative rejection rewind and replay exactly.
- [x] Maximum source, name, function, and scalar windows have direct boundary evidence.
- [x] Calculated storage, measured case live bytes, lifetime IDs, and every new phase frame fit.
- [x] Changed physical products, packages, locks, documentation, and a locked consumer agree.
- [ ] The exact verified feature tree is committed, pushed, and checked remotely.
