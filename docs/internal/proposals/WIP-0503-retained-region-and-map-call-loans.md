# WIP-0503: Retained region and map call loans

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler compiler maintainers |
| Created | 2026-09-07 |
| Updated | 2026-09-07 |
| Area | Retained call typing and storage loans |
| Depends on | WIP-0057, WIP-0502 |
| Supersedes | None |
| Superseded by | None |
| Follow-up | WIP-0504 |

## Boundary

[WIP-0502](WIP-0502-sixty-four-argument-retained-source-calls.md) admits 64 ordered
identifier arguments. Its region and map controls still reject at argument
binding. The signatures already carry `TYPE_REGION_BORROW` and
`TYPE_LONG_MAP_BORROW`, and the call emitter already selects `REGION_BORROW` and
`MAP_BORROW`. Binding incorrectly asks the buffer-only classifier for these types.

Admit existing mutable region and signed-map loans as ordinary retained call
arguments. Preserve their exact types through local and imported calls. This
removes another compiler-signature boundary, not the aggregate artifact join or
the intact nominal test runner's dependency on `compileMinimal`.

## Change

`SourceCallArgumentProducts.w` owns call-value type selection. It resolves signed,
Boolean, buffer, region-loan, and map-loan values from the same defining-value
coordinates. Region and map arguments must carry an admitted borrow mode. Their
types do not collapse into a generic storage code.

Keep `directBufferLocalType` restricted to buffers. Admitting a region or map call
argument must not admit it to `bufferLength`, indexed buffer reads, or byte/word
mutation. The existing call encoder still emits each source move and reborrow in
argument order. No new opcode, operand format, descriptor table, or arena appears.

The 64-argument, 256-local, 4,096-token, and 32,768-byte artifact windows remain
independent. Generated inverses with arguments remain excluded. Owned region/map
arguments and arbitrary argument expressions remain separate source-profile work.

## Evidence

- Compare complete local artifacts for root, loop, forwarded, guarded, and void
  calls with both loan kinds.
- Compare complete imported artifacts, typed stubs, and relocations for qualified
  and unqualified targets without dependency source.
- Reject swapped region/map types, wrong final types, unknown values, and attempts
  to use either loan as a buffer before artifact publication.
- Exercise both loan kinds at the last admitted argument slot without widening
  the arity or frame bounds.
- Execute a native-produced caller against an independent callee that allocates
  through the region and mutates the map. Check the result, reborrow operations,
  released scratch, and complete rewind.
- Query the buffer classifier directly for every region/map row. Keep owned
  storage as a stage-0-positive, retained-binding-negative control. Replace the
  old loan rejections with complete artifact comparisons.
- Refresh affected physical, graph, package, lock, and documentation evidence.

The focused suites compare both complete 16,384-entry argument columns and both
defining-value columns. They retain all eight scalar/loan kinds in a permuted
64-argument order. Root, loop, forwarded, guarded, and void local calls pass.
Imported initializer and void calls pass with qualified or unqualified names.
Unqualified forwarded calls also pass. The one-, 55-, and 64-argument cases test
both storage kinds at the last slot. Argument 65 rejects before publication.

The executed caller performs one `CALL_VALUE`, one `REGION_BORROW`, and one
`MAP_BORROW`. Its independent callee allocates byte scratch, releases it, and
stores seven in the map. The wrapper checks both returned and stored values,
drops the map and region, and rewinds to the complete initial snapshot.

Three restored mutants fail: assigning the map type to a region loan, inventing
a borrow mode for owned storage, and admitting a region to the buffer classifier.
All 703 Wheeler input hashes match the pre-mutation snapshot after restoration.

### Final input scope

The isolated review passes 59 distinct JUnit identities. The preserved WIP-0498
integration adds thirteen identities, for 72 across scopes. Its primitive runner
control passes. The intact nominal runner is not counted as passing evidence.

The physical entry products retain 29 imported targets. One archive pass binds
all 451 modules, 2,110 symbols, and 1,813 callables. These tests do not compile the
complete argument-binding owner natively. The graph takes 88,834,618 transitions
under the unchanged 89-million ceiling. The manifest hash still takes 39,899,856
transitions. The compiler archive has 3,376,044 bytes and SHA-256
`69d4de6cc17a1a81f13099fbaf009e0f1b6633dac7ce27e0698da92fb9c7c005`.
The executable has 1,829 functions and 236,811 instructions in 6,954,288 bytes.

Canonical locks and the 497-artifact workspace agree with these inputs. The
locked minimum-state consumer again matches 568 artifact bytes and 772 coverage
bytes, with seven tested transitions and final state seven. This is a bounded
consumer regression, not the loan-execution proof above. Documentation checks
and site rendering pass for the five published library roots. Broader checks
still report missing API comments in existing test and conformance sources.

## Acceptance

- [x] Exact call-value typing admits both existing loan kinds.
- [x] Buffer-only operations keep their domain.
- [x] Complete local and imported artifacts preserve types and call order.
- [x] Rejection and first-excess cases publish nothing.
- [x] Executed allocation, map mutation, and rewind preserve loan lifetimes.
- [x] Legacy call rejections are removed and all affected identities agree.

## Remaining work

Hosted run 34165634909 at `6fb3f3d2f` fails the canonical source formatter gate.
The three new calls in `argumentType` need one argument per line. Native package
rows were skipped. The formatting repair leaves all 6,954,288 compiler executable
bytes unchanged, but changes the archive to 3,376,184 bytes and SHA-256
`d5d9bac8442b5d2e4fb36ae512a9b97257e82f509780c3daad4ca15407ca70d5`.
The repaired graph takes 88,834,648 transitions under the same ceiling.

Run 34166510984 on the formatting repair `7e63b4721` passes 51 jobs. Native shard
15 exceeds the unchanged twelve-minute method deadline. The repaired inputs do
not have hosted native-package acceptance. WIP-0502's accepted run at `76b211806`
does not cover them.

WIP-0049 and WIP-0054 still own source-product and aggregate artifact composition.
The aggregate helper currently returns a primitive artifact and separate composed
instruction products. Connecting that helper alone to the native test runner
would not produce the complete nominal artifact. Qualified forwarded returns
were outside this milestone, including a signed-only control independent of
storage types. [WIP-0504](WIP-0504-complete-retained-call-statement-windows.md)
closes their complete-window and width handoff.

Do not remove the nominal test's declarations or replace its selected body to
bypass that join.
