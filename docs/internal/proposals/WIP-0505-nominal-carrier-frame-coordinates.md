# WIP-0505: Nominal carrier frame coordinates

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler maintainers |
| Created | 2026-09-07 |
| Updated | 2026-09-07 |
| Area | Nominal carrier type linking |
| Depends on | WIP-0048, WIP-0050 |
| Supersedes | None |
| Superseded by | None |

## Boundary

[WIP-0050](WIP-0050-native-aggregate-source-lowering.md) binds nominal value
carriers to module, function, and frame-local coordinates.
[WIP-0048](WIP-0048-canonical-native-product-linker.md) restores their types
when linking. Those coordinates do not include the optional result-type word
at the front of a serialized function type window.

`LinkedLocalTypes.w` currently uses a frame-local index as a serialized type
index. On `ae690860a`, restoring a record parameter at local zero replaces a
signed result type with `0x10000000`. It also admits a carrier at `localCount`
when the result prefix leaves another serialized word available. Both failures
reproduce using function rows indexed from a complete stage-zero artifact.

This record repairs that coordinate conversion. It does not assemble nominal
source artifacts or supply missing nominal result-type products.
[WIP-0054](WIP-0054-native-source-product-artifact-integration.md) retains those
composition requirements and the full physical compiler gate.

## Change

`LinkedLocalTypes.w` owns the conversion. The existing result flag determines
whether the serialized window starts with a result type. Validate the flags,
frame extent, and exact `localCount + resultTypeCount` agreement before reading
the type window or publishing output.

A carrier must select an actual frame local in `0..localCount-1`, bounded by
`0..255`. Check its signed source type at `local + resultTypeCount`. During
emission, convert the serialized position back to a frame-local index before
matching carrier rows. The result prefix never matches a value carrier. Ordinary
nominal descriptor relocation still applies to result types.

Retain the existing two-phase validation and publication. Rejection leaves the
whole caller-owned type table unchanged. Remove the direct serialized-index
matching. Do not add an alternate carrier convention or a compatibility path.
The result prefix is not another frame slot and does not raise the frame bound.
One value-returning frame may have 256 locals and 257 serialized type words.
The closure's 1,048,576-word type pool remains an independent limit.

## Evidence

`NativeCompilerCarrierTypeCoordinatesExampleTest` uses actual compiled function
rows, an independent typed-source oracle, and complete artifact comparison.
`NativeCarrierTypeFixture` exposes the native type result without supplying a
replacement result type from Java. Reassembling those types with unchanged
artifact sections is a linker check, not source-to-artifact compilation.

The baseline signed-result control fails at type word zero: expected `1`, got
`268435456`. The first-excess carrier control expected a trap but published
successfully. Fixture syntax and encoding setup failures are not this evidence.

The accepted controls include signed, Boolean, `Done`, void, record, and variant
results, plus reversible scalar results with implicit result slots. Complete
reconstructed artifacts retain both instruction directions. The 256-local cases
use independently padded frames. They do not claim that every local can be
simultaneously populated by admitted source. Record and variant calls execute
through independently compiled callers and completely rewind.

Each carrier-coordinate fixture compares all 1,048,576 output type cells.
Accepted fixtures also compare every published byte. Separate record and variant
result controls relocate descriptor zero to one while restoring a carrier of
the other kind. Those checks cover type products, not complete module relinking.
Every fixture also rewinds its native type-emission execution, including rejected
frame metadata and missing or nonsigned carriers. The first-excess control has
an adjacent signed type window, so an incorrect frame bound cannot hide behind
an unrelated read failure.

Five restored mutants fail: omit the result-prefix subtraction during emission,
use serialized type count as the frame bound, omit count agreement, write an
interior output cell before validation, or bypass result descriptor relocation.
All 703 Wheeler and 713 canonical package input hashes match the restored sources.

The measured clean inputs have 451 modules, 2,140 imports, 2,110 scalar symbols,
and 1,816 callables. The compiler archive is 3,379,808 bytes with SHA-256
`d1792bab2d7646f21389cd9989c428e13907b9f527c967ed0a7364dd6e60e9e2`.
The stage-zero executable is 6,968,512 bytes, 1,832 functions, and 237,310
instructions. Graph identity takes 88,823,353 transitions under the unchanged
89-million ceiling. Manifest hashing takes 39,901,270 transitions under its
42,689,000-transition budget. These measurements do not establish a fixed point.

Physical linker and archive checks pass in 8m16s. They follow 29 imported entry
targets and bind all 451 archive modules. The fresh workspace emits 497 artifacts.
Canonical locks, source and formatter gates, proposal and link checks, the five
published main-root API checks, and site rendering pass. Broader conformance and
test documentation checks are not included.

There are 59 distinct isolated JUnit identities and five integration-only
identities, 64 total. The unfinished member-front overlay passes 21 selected
identities, sixteen shared with the isolated suite. Its intact nominal test still
fails in `compiler_core::requireMinimalProgram`. That failure is not acceptance.

## Acceptance

- [x] Signed, Boolean, void, and nominal results preserve their own type slots.
- [x] Record and variant carriers restore the first and last actual frame locals.
- [x] Missing locals, nonsigned carriers, and inconsistent frame metadata reject
  without changing any caller-owned type word.
- [x] Complete reconstructed artifacts match independent artifacts, execute
  typed calls, and rewind. Small rejected compositions also rewind.
- [x] Restored mutants expose prefix and first-excess mistakes.
- [x] Source, documentation, physical identity, and affected lock checks pass.

## Remaining work

Connect source products to complete nominal artifacts under WIP-0054. A correct
local-type linker cannot replace the missing source result, global, proof, entry,
and instruction handoffs. The intact mixed-member native test must pass with
its declarations and selected body unchanged.
