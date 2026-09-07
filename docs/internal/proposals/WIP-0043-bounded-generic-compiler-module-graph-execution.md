# WIP-0043: Bounded generic compiler module graph execution

| Field | Value |
| --- | --- |
| Status | Implemented |
| Owners | Wheeler compiler, linker, bootstrap, package, and conformance maintainers |
| Created | 2026-08-07 |
| Updated | 2026-09-07 |
| Area | Self-hosting, modules, linking, graph execution |
| Depends on | WIP-0007, WIP-0017, WIP-0028 |
| Supersedes | The topology-specific execution work remaining in WIP-0007 |
| Superseded by | None |
| Follow-up | WIP-0044 closure execution, WIP-0356 36 KiB linked slots, then WIP-0365 nested helper owners |

## Summary

The recovery compiler shall execute one validated bounded module graph instead of dispatching to a catalogue of tree shapes. Planning and execution remain separate. Planning records exact modules, edges, direct root imports, visibility, shared declarations, and one deterministic leaf-first order. Execution consumes only that plan.

The first bound remains seven imported modules and 32,768 bytes per physical or linked source. This WIP removes the topology staircase before raising either bound. More capacity on top of twenty-eight switch arms would be an accounting error, not a linker.

## Problem

The old compiler validated graph facts before linking, then spread execution across direct, chain, fork, nested, mixed, and shared-DAG owners. A new legal edge pattern needed a classifier identity and an executor path. The redundant two-module chain was the last small example: the leaf fed its dependent while both remained direct root imports.

Scalar constants and helpers no longer have that defect. One executor accepts every rooted acyclic constant or scalar-helper plan from two through seven imported modules. Direct, mixed, private, shared, redundant, chain, fork, and diamond graphs use the same plan facts. The plan records executable-owner kinds before linking an edge. WIP-0365 completes that invariant for nested executable chains by recording each physical owner's function count before graph mutation.

This does not scale to the physical compiler closure. Real module graphs contain redundant direct edges, shared dependencies, independent branches, constants beside functions, and imports retained for their own public API. A closed list of picturesque trees cannot become a module system by acquiring more pictures.

## Goals

- Build one canonical bounded source table from framed modules.
- Validate module names, direct imports, edges, roots, and reachability once.
- Record root-import rank independently of source-frame order.
- Execute every acyclic graph accepted by the bound.
- Resolve constants before members that consume them.
- Preserve public direct imports and privatize only transitive exposure.
- Drop duplicate private constants only after exact token comparison.
- Keep constants before executable members in the synthetic class.
- Preserve helper owner identity and canonical function order.
- Publish nothing until the final linked source compiles and verifies.
- Delete topology identities and executors after differential replacement.

## Non-goals

- Raise the seven-import frame bound in the same change.
- Add general records, variants, methods, or aggregate ownership.
- Infer imports from directories or package source order.
- Merge unrelated exported declarations by name.
- Treat frame arrival as module authority.
- Make malformed entryless libraries eligible for another parser.
- Replace package-level closure validation.

## Canonical plan

The planner produces one immutable value:

```text
GraphPlan {
    node_count
    root
    module_name[node_count]
    source_slot[node_count]
    edge[node_count][node_count]
    direct_root[node_count]
    root_import_rank[node_count]
    leaf_first_order[node_count]
    private_use[node_count]
    shared_use[node_count]
    executable_owner[node_count]
}
```

`source_slot` names a validated physical frame. It does not copy source bytes. `root_import_rank` comes from the root header. Frame order has no vote.

The plan is valid only when all of these hold:

- module names are canonical and unique.
- every import resolves to one local or declared external module.
- every local node reaches the root.
- the local graph is acyclic.
- every direct-root bit matches the root header.
- every edge matches the dependent header.
- source paths and physical frames are unique.
- all counts and byte lengths fit before append.
- every physical executable owner is classified before dependency linking.

A redundant edge is ordinary graph data. It needs no topology identity.

## Execution

Execution walks `leaf_first_order`. Each node starts with its physical source and receives resolved dependencies in canonical dependency order.

For one dependency edge, the executor performs these steps:

1. Select the dependency and dependent by planned source slot.
2. Revalidate the selected module names against the plan.
3. Resolve and insert the dependency's declaration prefix.
4. Preserve or privatize exports according to `direct_root` and the dependent edge.
5. Deduplicate shared constants only after exact token comparison.
6. Filter repeated helper groups only when the planned executable-owner identity is equal.
7. Freeze the complete linked source before advancing the table owner.

The executor compiles the root only after processing every incoming edge. Constant-only edges run before executable edges. Multiple executable inputs follow dependent-import rank. `GraphHelperMembers.w` removes repeated owner groups and rotates each retained group behind earlier dependencies. `GraphOwnerMetadata.w` carries owner order through each source slot and writes inert canonical-name markers for owners private to the final root. A helper's physical frame, topological position, or completion order does not alter its function identity.

The executor may use fixed seven-slot storage in the initial implementation. The public operation must still take a counted plan and one source table. Arity-shaped entry points are not the interface.

## Ownership

Every physical source enters as a shared UTF-8 loan. A linked source is a fresh owned UTF-8 value in one bounded region. Replacing a table slot destroys the prior linked owner only after the replacement freezes successfully.

Inactive source slots are not candidates. They may be padded with shared loans at a binary boundary, but the counted plan prevents selection.

No linked source outlives its arena. The final artifact borrows no source storage. Failure drops temporary owners and leaves caller output unchanged.

`graphs/plans/SourceTable.w` uses one 229,376-byte arena and one seven-word length column. Each imported node owns one fixed 32,768-byte slot. The active length, not stale tail storage, defines the source. Initialization validates every active input before the first write. Replacement validates the complete frozen source before mutation and clears the replaced slot's former tail. The executor carries the synthetic root in a separate fixed buffer, so seven imported modules do not weaken the table's count-eight rejection.

## Visibility and duplicates

A direct root import retains its public declarations even when it is also a transitive dependency. The dependent receives private access to the same declarations. The executor drops the private copy only when the complete constant declaration matches the public declaration token for token after the visibility keyword.

A same-name mismatch fails. A private name used directly by the root fails. Two unrelated public exports with the same name fail. Qualification removal occurs only for the selected module owner. `GraphHelperMembers.w` filters repeated helper groups by planned physical owner identity, not spelling. Nonprefix sharing receives the same treatment as a leading shared leaf.

Constants remain ahead of functions. Inserting a helper at the class opening brace after constants already exist is invalid, even if a later formatter could make the text look less guilty.

`ImportedHelpers.w` checks the complete constant section, not just its leading shared prefix. `SharedDeclarations.w` owns exact comparison after visibility. The planner measures matching private declaration spans. `CanonicalHelperLinking.w` omits those same spans and keeps intervening private constants, public tails, and surrounding whitespace.

Both constant writers walk declaration boundaries and rewrite only leading visibility. A constant named `public` remains a name, including uses in another initializer. The flat writer no longer scans arbitrary body tokens for that spelling.

Unshared private declarations still undergo root-use checks. Equal evaluated values do not authorize merging different declarations. Sharing a local declaration does not export the imported private name. A qualified reference to that private owner still fails before artifact publication.

## Determinism

The planner uses module names and root-header import order as authority. The executor uses the recorded leaf-first order and root import ranks. Equal plans and equal source bytes produce equal synthetic source and equal `.wbc` bytes.

No hash table iteration, file enumeration, allocation address, or frame arrival enters the order. A comparator tie is an error unless the compared module identity is equal and has already failed uniqueness.

## Limits

The initial executor retains these bounds:

- seven imported modules.
- sixty-four direct imports in any source header.
- 32,768 bytes per physical source.
- 32,768 bytes per linked source.
- forty-nine graph bits.
- one rooted acyclic local component.

The source table and plan must reject count eight and byte 32,769 before allocation or publication. Later work may raise the module and linked-source bounds after the generic executor replaces the closed profile.

## Migration

1. Give the bounded matrix root-import ranks and source slots.
2. Introduce one counted source table with checked replacement.
3. Execute direct and full-chain graphs through the generic path.
4. Execute forks, independent branches, and redundant direct edges.
5. Execute shared DAGs with exact declaration deduplication.
6. Execute mixed constant and helper owners in root-import order.
7. Differentially compare every existing topology and frame rotation.
8. Delete topology identities, classifiers, coordinators, and executors.
9. Defer larger graph transport and general symbol closure to WIP-0044.

Compatibility wrappers are not retained. During migration the driver may dispatch old and new implementations in tests, but one implementation remains after parity.

## Progress

- [x] `graphs/Matrix.w` records bounded edges, roots, root order, reachability, privacy, sharing, and leaf-first order.
- [x] Checked plan accessors expose every node, edge, root rank, privacy bit, and sharing bit.
- [x] `graphs/plans/SourceTable.w` provides one counted seven-slot table over the complete physical source window.
- [x] Two- through seven-module planners validate exact graph facts without topology classification.
- [x] Every admitted legacy topology has differential frame-order evidence.
- [x] `graphs/plans/GraphExecutor.w` handles redundant direct leaves and one public constant leaf shared by two direct constant dependents.
- [x] Shared helper planning drops exact private declarations against existing public or private constants, including interleaved sharing and retained tails.
- [x] `graphs/plans/SourceTable.w` owns physical and linked source slots in one counted fixed-slot arena.
- [x] The generic executor selects every source from the counted table. Planned-loan and planned-source wrappers are deleted.
- [x] `graphs/plans/GraphExecutor.w` executes every validated two- through seven-module constant graph by leaf-first edges and dependency-aware root-import rank. This includes forests, redundant direct edges, the three-root shared leaf, and both admitted shared diamonds. Exact private-prefix comparison removes repeated leaves.
- [x] Header dependency facts carry validated candidate import rank, and small direct plans use it.
- [x] One graph executor handles direct, chain, fork, branch, redundant-edge, dense-DAG, and shared-DAG plans from two through seven modules.
- [x] Every legacy constant topology matches stage 0 byte for byte through the generic path.
- [x] The five-, six-, and seven-module topology registries, classifiers, role selectors, and executors are deleted.
- [x] The four-module topology executors and planned-source selectors are deleted.
- [x] The complete bounded graph plan validates and packs root-import rank.
- [x] New dense three- and four-module DAGs, shared five-module DAGs, and redundant six- and seven-module DAGs execute without new topology identities.
- [x] Mixed direct constants and helpers, direct helper sets, redundant constant leaves, and the constant-fed helper chain use the graph executor. Three helper owners beside four constants match stage 0 across all fourteen seven-frame rotations.
- [x] The arity-shaped direct-helper linkers, source-order network, mixed coordinators, and structural fallbacks are deleted.
- [x] `BoundedGraphPlan` records executable-owner kinds before dependency linking.
- [x] Private two-edge helper chains, two-input helper forks, and mixed private constant/helper inputs match stage 0 across every three-frame order.
- [x] Redundant direct helpers, shared helper leaves, shared helper diamonds, and nonprefix shared owners retain each exact helper group once across frame rotations.
- [x] Graph execution order, helper-member filtering, owner metadata, source storage, and execution have focused files below 1,000 lines.
- [x] Raising graph transport beyond seven modules is split into WIP-0044.

## Shared-constant evidence

`NativeCompilerSharedHelperConstantsExampleTest` compares complete artifacts with independent stage 0 across both frame orders. It covers leading, trailing, and interleaved sharing, retained private gaps, public tails, and keyword-spelled names. It executes and rewinds each accepted artifact.

Changed literals, types, and token-distinct equivalent expressions reject without native artifact publication. Private-tail exposure and conflicting public exports also reject. Both source columns admit constant 256 and reject 257 before publication. Small planning and emission fixtures compare every output byte and fully rewind success and rejection. The large count fixtures run without history.

The physical resolved-local-return and resolved-return-call entry fixtures also compare complete artifacts and execute them. Their inputs now come from actual module closures rather than stale lists of constant owners. This remains bounded helper-graph evidence, not full compiler composition or a self-hosting fixed point.

## Root state ordering

The one-helper composition in WIP-0499 also admits an unused helper beside an
imported constant. Complete artifact comparison retains both the imported helper
and the root entry. This replaces an obsolete unsupported-import expectation.

`ClassLayouts.w` now separates the constant range, state range, and executable
insertion point. `ClassPrelude` carries all five coordinates and validity without
evaluating initializers or publishing global metadata. Constants may precede or
follow one state declaration. Split constant sections and a second state fail.

The linker inserts ordinary constants at the constant start and shared tails at
the constant end. Helpers follow the entire prelude, including state. The
single-import path uses the canonical helper writer for shared helper plans.
Constant-only edges retain the same constant boundary in a larger graph.

`ConstantDeclarations.w` owns the counted constant-prefix locator and shared
initializer extent. Qualified initializers survive syntax location before
canonical name rewriting. Final layout checks the complete initializer tail
before value admission. Arithmetic and parenthesized state initializers remain
lowering work. The compiler must reject them, not discard their suffixes.

Focused tests compare every prelude coordinate and scanner column. They cover
both orders, malformed fronts, 256 and 257 declarations or name bytes, 32 and 33
parentheses, and the complete 4,096-token window with spare backing storage.
Small cases fully rewind. Large count and token cases run without history.
Imported-state fixtures compare complete stage-0 artifacts, preserve helper and
root identities, execute the global result, and rewind the emitted program.

## Token-owned qualifications

`ModuleQualifications.w` counts and copies qualified names from scanner tokens.
A namespace match starts at a complete identifier and cannot begin after a dot
or scope separator. Comments and quoted text are not references. The old byte
substring search and duplicate ASCII comparator are gone.

This prevents `myexamples.constants::BASE` from becoming a local `myBASE` while
linking `examples.constants`. Shared private-name checks use the same namespace
matcher as measurement and copying. They reject qualified private access even
when an identical local declaration exists. Bare local references retain their
own binding.

The helper writer reuses its scanner columns. The flat constant writer owns
three private 4,096-row root columns. Privatization adds three imported columns.
Tests measure both allocation profiles and verify that all writer scratch is
released before host publication. Qualification products allocate no buffers and
leave their scanner columns unchanged. The 64-reference and 36 KiB linked-source
limits remain separate from physical-source, graph, argument, and evaluator
limits.

Complete source comparisons preserve quoted namespace text and seventy matching
comments while rewriting the actual call. Whole and disjoint copies use nonzero
destinations and preserve inactive bytes. Invalid windows reject before writes.
Capacity failure and a split qualification may retain private staging bytes.
Both failures fully rewind. The enclosing linker still owns artifact publication.
The complete 36 KiB copy and byte 36,865 rejection run without history.

Private-access and namespace-alias fixtures reject without artifact publication
and fully rewind the compiler. A constant-fed helper edge retains a constant
named `public` across both state and frame orders. These are bounded graph and source products. They do not establish native
compilation of these owners or a self-hosting fixed point.

## Acceptance

- Every existing two- through seven-module differential remains byte-identical.
- All source-frame permutations produce one artifact.
- A redundant direct leaf works for constant and helper dependents.
- Shared identical declarations appear once.
- Shared mismatched declarations fail before output.
- Constants precede every executable member.
- Private helper chains preserve every canonical owner identity.
- Private transitive exports do not leak into the root.
- Unsupported cycles, detached nodes, duplicate modules, and excess bounds fail before mutation.
- No maintained graph executor dispatches on a topology identity.
- No Wheeler source directory exceeds ten files.
- No authored file reaches 1,000 lines.

## Rejected alternatives

### Keep extending the topology registry

Rejected. It gives each new legal edge set a permanent source file and numeric identity. The number of DAGs grows faster than maintainers do.

### Link in frame order

Rejected. Transport order is not module authority and already varies in differential tests.

### Concatenate complete modules

Rejected. Constants can land after functions, imports remain unresolved, private exports leak, and duplicate declarations survive. Concatenation is a byte operation, not linking.

### Deduplicate by name

Rejected. Equal spelling does not prove equal type, value, visibility, owner, or source identity.

### Raise the module bound first

Rejected. A larger topology staircase makes the deletion harder and proves no additional graph completeness.
