# WIP-0022: Package instances and deterministic target graphs

| Field | Value |
| --- | --- |
| Status | Draft |
| Owners | Wheeler package, module, compiler, build, security, and tooling maintainers |
| Created | 2026-07-19 |
| Updated | 2026-07-19 |
| Area | Packages, dependency resolution, modules, workspaces, lockfiles, diagnostics |
| Depends on | WIP-0005, WIP-0007, WIP-0009 |
| Supersedes | None |
| Superseded by | None |

## Summary

Wheeler dependency resolution will operate on exact package instances connected by target-scoped typed edges. A package name is not an instance, a transitive package is not an ambient import provider, and a build tool does not share the target program's dependency context.

The resolver consumes explicit runnable or library roots, repository snapshots, build and target profiles, feature selections, and an optional existing lock. It produces one deterministic realizable graph or one deterministic incompatibility explanation. Total work is bounded. A still-valid locked instance remains selected unless an explicit update forces movement.

A workspace owns one root set and one graph. Multiple ordinary package versions may coexist under distinct aliases and nominal identities. Graph selection fixes exact source, generic/class evidence, callable, and reversible-IR identities before emission; resolution never rewrites an inverse, adjoint, effect, or quantum region to make a dependency fit. Packages that genuinely cannot coexist declare a singleton or native link-group constraint instead of making global lockstep everybody's hobby.

## Motivation

The implemented stage-0 resolver deliberately selects one version per package name and the compiler receives a flat candidate map from the locked closure. That is sufficient for the current canonical packages, but preserving it would cause:

- development and build dependencies leaking into unrelated targets;
- dependency tests, tools, or deployables being compiled when not selected;
- accidental imports through a transitive dependency;
- globally unique module names across an entire closure;
- profile rejection after selection instead of solver backtracking;
- stable ranges admitting prereleases;
- exponential search hidden behind a package-count limit;
- unrelated lock churn after repository additions;
- workspace members drifting onto different graphs;
- package-wide capability grants wider than the selected phase.

These are graph semantics, not cleanup items. Once third-party packages depend on them, changing them becomes archaeology with a release calendar.

## Goals

- Define package instances, aliases, typed target edges, and build/target contexts.
- Preserve exactly three target kinds: `deployable`, `library`, and `tool`; `test` remains an orthogonal selector on runnable targets.
- Permit source imports only through direct declared normal dependencies.
- Keep build dependencies invisible to target source and development dependencies root-selected and nontransitive.
- Support multiple package versions with instance-qualified nominal types and output paths.
- Add explicit singleton and native link-group constraints.
- Evaluate source, bytecode, proof, target, platform, and ABI profiles during solving.
- Exclude prereleases from stable ranges unless policy explicitly opts in.
- Use deterministic incompatibility-driven resolution with total work limits.
- Prefer an existing valid lock and support targeted, full, and minimum-version updates.
- Give a workspace one canonical graph.
- Scope capabilities to package instance, target, phase, and resource pattern.
- Preserve exact offline vendored builds.

## Non-goals

- Define repository snapshots or recipe/package revisions; WIP-0023 owns them.
- Define system-package export; WIP-0024 owns it.
- Define FFI; WIP-0025 owns it.
- Define platform-native executable layout; WIP-0026 owns it.
- Infer dependencies from imports, link errors, installed libraries, or ambient caches.
- Add arbitrary resolver plugins or let a lock override current manifests.
- Add decorative target kinds for tests, examples, documentation, images, or distributions.

## Terms and semantic model

A **repository identity** names one trust domain, not one URL. Mirrors serve the same signed snapshots and objects. Different repository identities never compete for a package name implicitly.

A human package coordinate is:

```text
(repository_id, package_name, semantic_version)
```

A package instance is contextual and exact:

```text
package_instance {
    repository_id
    package_name
    semantic_version
    recipe_revision
    selected_features
    source_profile
    bytecode_profile
    proof_profile
    context
    target_profile
}
```

WIP-0023 adds variant and built-output identities.

A **dependency alias** is the source-visible local name for one direct dependency instance. Two instances of the same package in one target require distinct aliases.

A resolved edge contains:

```text
dependency_edge {
    from_instance
    from_target
    alias
    kind                 // normal, build, development
    to_instance
    to_export
    version_requirement
    selected_features
    source_visibility
    context_transition
    capability_effect
}
```

### Edge kinds

A normal edge supplies a semantic export to its declaring target. It resolves in target context and is importable only through its direct alias. Public API identity records an exposed dependency nominal type or capability contract.

A build edge supplies a locked tool that executes in build context. Its modules are not importable by target source, its exact artifact enters build-input identity, and it cannot observe the output it is producing.

A development edge activates only for a selected root-owned test, example-like deployable, documentation tool, benchmark tool, or analysis tool. It never propagates from a dependency merely because a command enabled development mode.

Build and target contexts remain distinct even when both happen to say `x86_64-linux`.

### Direct-import invariant

For an external import such as:

```text
import codec::encoding.json;
```

the compiler proves that `codec` is a direct dependency alias of the importing target, the edge permits source visibility, the exact instance exports the module, and no transitive or unrelated package can satisfy it.

An exported nominal type identity includes:

```text
(package_instance_id, module_name, declaration_name)
```

Equal spelling and layout do not merge nominal types from different instances.

WIP-0030 type-class adapter instances obey the same boundary. Class-package and principal-type-package instances are intrinsic to those exact package instances; an adapter activates only through a direct declared dependency and explicit source selection. It never leaks transitively. Selected evidence records exact package-instance identity in WIP-0029 generic bodies and closed reversible IR artifacts.

### Coexistence and singleton groups

Multiple versions may coexist when aliases, nominal identities, resources, output paths, capabilities, and native link groups remain distinct. A singleton declaration is permitted only for observably process-global state such as one runtime, symbol namespace, provider registry, or hardware session manager. It records group, scope, compatibility key, and reason.

### Profiles and prereleases

Candidate filtering includes source/compiler profile, `.wbc` version, proof-kernel profile, build platform, target platform, portable ABI, native ABI when applicable, and statically planned target capability requirements. An incompatible high release is rejected as a candidate so a compatible lower release can be selected.

Stable ranges exclude prereleases unless the requirement names one or explicit dependency/update policy opts in.

### Realizable lock

A lock is realizable only when every snapshot and recipe revision exists, every edge is still declared, all versions/features/profiles/singletons hold, every active instance is reachable, grants do not exceed requests, and exact objects match. A lock cannot manufacture an edge forbidden by the current manifest.

## Ownership and boundaries

Manifests own targets, requirements, aliases, exports, features, compatibility metadata, and capability requests. Repository snapshots own candidates. The resolver owns selection, conflicts, work limits, and graph construction. The lock owns one exact realizable graph. The compiler owns direct imports, visibility, nominal identity, and profile checks. The planner owns selected closure, tools, grants, limits, inputs, and outputs. The workspace owns roots and one graph.

## Design

For each selected root target, the resolver creates its instance, expands only that target's dependencies, sends build edges to build context, activates development edges only for selected root-owned work, selects exact named exports, applies features, profiles, singleton constraints, and cycle policy, then emits canonical graph order.

Normal source cycles, build-tool cycles, tools depending on outputs they produce, and context-crossing future-output cycles are rejected.

The solver is incompatibility-driven—PubGrub-style or semantically equivalent. Every decision records declaring instance/target, edge kind/context, version/profile/feature requirement, snapshot, old-lock preference, and rejection reason. Equivalent failed states are learned.

After filtering, candidate order is:

1. retain a valid locked candidate;
2. honor explicit update scope;
3. apply semantic-version and prerelease policy;
4. apply immutable recipe-revision policy within the pinned snapshot;
5. break exact ties by canonical content identity.

Mirror order, response order, filenames, timestamps, locale, and map iteration are irrelevant.

Hard limits cover roots, instances, edges, candidates, incompatibilities, decisions, backtracks, derivation depth, diagnostic bytes, and total work units. Wall-clock cancellation may stop a run but cannot turn exhaustion into “no solution.”

The ordinary update objective preserves the maximum valid locked instances, changes explicitly selected packages and forced dependents, minimizes changed contextual edges, then prefers highest compatible stable versions with canonical tie-breakers. Resolver/objective versions enter the lock.

A workspace names members, root targets, repository aliases/snapshots, explicit content-identified overrides, and capability policy. Member dependencies bind directly to exact member source identity and cannot be published accidentally as upstream coordinates.

Capabilities are keyed by:

```text
(package_instance, target, phase, capability_name, resource_pattern)
```

Phases include fetch, build, test, documentation, native image construction, and distribution export.

The next lock schema records resolver version, roots, repository snapshots, instance IDs, coordinates/RREVs, profiles/features, aliases, typed edges, contexts, singleton decisions, capability requests/grants, and exact source/archive identities. Edges name instance IDs, never bare package names.

## Reversibility and determinism

Resolution and lock verification are pure deterministic computations. Atomic lock replacement is an external effect; failure leaves the old lock unchanged. Fetch/cache insertion reconciles by immutable identity rather than pretending to be reversible.

Candidate discovery may run concurrently, but canonicalization precedes solving. Graph bytes, diagnostics, and lock bytes match serial execution regardless of completion order.

## Quantum and proof implications

Instance compatibility includes proof and target profiles. Certificates bind exact package-instance identities. Credentials, mutable calibration, queues, and hardware observations are not resolver inputs.

## Persistence and compatibility

This WIP replaces the unreleased lock schema in one change. No compatibility reader or migration mode remains. The compiler/linker includes instance identity wherever nominal collision is possible, and canonical packages, locks, archives, examples, and fixtures move together.

## Safety and failures

Reject unknown repositories/snapshots, unauthorized namespaces, duplicate aliases, undeclared exports, incompatible profiles, unintended prereleases, forbidden cycles, singleton conflicts, transitive imports, conflicting overrides, excess grants, work exhaustion, and unrealizable locks. A repository outage does not affect a complete vendored lock.

## Migration and deletion

1. Add package-instance and typed-edge models.
2. Add build/target contexts and target-scoped dependencies.
3. Add aliases and direct cross-package import syntax.
4. Delete the flat transitive module candidate path.
5. Add profile/prerelease filtering.
6. Replace depth-first backtracking with bounded incompatibility solving.
7. Add lock preference and update modes.
8. Replace the lock schema and introduce one workspace graph.
9. Scope capabilities.
10. Add multiple-instance nominal/output identity and singleton groups.
11. Replace every fixture, lock, and archive atomically; retain no old graph authority.

## Progress

- [ ] Instance and typed-edge model accepted.
- [x] Stage 0 rejects package-source imports outside the package's own modules and direct declared dependencies while retaining the private transitive closure needed to compile those direct dependencies.
- [ ] Alias-qualified direct imports and full build/target context rules accepted.
- [x] Stable exact, caret, and tilde requirements exclude prerelease candidates unless the requirement itself names a prerelease. Candidate ordering still prefers the highest compatible release, but a newly uploaded preview cannot ambush an unchanged stable range.
- [x] Stage 0 filters dependency candidates by the root's exact source profile during solving, so an incompatible higher release backtracks to a compatible lower one rather than failing after selection.
- [ ] Bytecode, proof, target, platform, ABI, richer source-profile compatibility, and explicit prerelease-policy filtering implemented.
- [x] The current deterministic backtracking solver has a 10,000-unit total budget over solver-state and candidate visits; exhaustion is a distinct error rather than counterfeit unsatisfiability.
- [ ] Incompatibility-driven solving, learned failed states, canonical derivations, and the complete versioned work schedule implemented.
- [ ] Lock preference and targeted updates implemented.
- [ ] Workspace graph and target-scoped capabilities implemented.
- [ ] Multiple instances compile safely.
- [ ] Singleton/link-group rules implemented.
- [ ] Flat transitive module path deleted.

## Testing and acceptance

- [ ] Development dependencies never propagate transitively.
- [ ] Build/target contexts cross-compile and unselected targets stay uncompiled.
- [ ] Transitive imports fail and equal module names do not collide.
- [ ] Incompatible majors coexist while nominal types remain distinct.
- [ ] Singleton conflicts are deterministic.
- [x] Version- or source-profile-incompatible high releases backtrack and stable ranges exclude prereleases; focused insertion-order, profile, and preview-candidate fixtures cover all three.
- [ ] Input order cannot alter the graph.
- [x] Work exhaustion differs from unsatisfiability in diagnostics and focused worst-order candidate tests.
- [ ] Conflict explanations name causal edges.
- [ ] Unrelated additions do not change a valid lock.
- [ ] Targeted updates preserve unrelated instances.
- [ ] Workspace overrides are visible and publication-safe.
- [ ] Locked vendored builds invoke no resolver, network, or ambient cache.
- [ ] Stage 0 and Wheeler implementations agree.

## Alternatives

One version per name forces ecosystem lockstep; actual singleton constraints are narrower. Exposing transitive modules makes manifests dishonest. Import inference couples resolution to conditional parsing. Unbounded depth-first backtracking has no total-work argument. Always choosing highest versions causes churn. Resolver plugins create local package dialects. All are rejected.

## Open questions

- Which alias-qualified import spelling best fits Wheeler? — **Owner:** language/module maintainers — **Decide by:** before parser implementation
- Which additive feature unification rules are safe? — **Owner:** package/type maintainers — **Decide by:** before features
- Which singleton scopes are required first? — **Owner:** runtime/native maintainers — **Decide by:** before WIP-0025 acceptance
- Which incompatibility derivation encoding is canonical? — **Owner:** resolver maintainers — **Decide by:** before implementation

## References

- [WIP-0007](WIP-0007-self-hosting-compiler-and-bootstrap.md)
- [WIP-0009](WIP-0009-wheeler-package-and-build-system.md)
- [WIP-0023](WIP-0023-recipe-repositories-and-reproducible-builds.md)
- [WIP-0028](WIP-0028-deterministic-ownership-borrowing-and-regions.md)
- [WIP-0029](WIP-0029-parametric-polymorphism-and-bounded-specialization.md)
- [WIP-0030](WIP-0030-coherent-type-classes-and-associated-types.md)
- [WIP-0031](WIP-0031-reversible-quantum-and-effect-polymorphism.md)
- [Conan lockfiles](https://docs.conan.io/2/tutorial/versioning/lockfiles.html)
- [Conan build and host contexts](https://docs.conan.io/2/tutorial/consuming_packages/cross_building_with_conan.html)
