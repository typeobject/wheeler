# WIP-0044: Counted native compiler closure execution

| Field | Value |
| --- | --- |
| Status | Implementing |
| Owners | Wheeler compiler, bootstrap, package, and conformance maintainers |
| Created | 2026-08-07 |
| Updated | 2026-08-07 |
| Area | Self-hosting, module closure, linking, bootstrap |
| Depends on | WIP-0007, WIP-0009, WIP-0043 |
| Supersedes | None |
| Superseded by | None |

## Summary

The native compiler shall consume the canonical compiler package closure without an arity-shaped frame. WIP-0043 proved graph-complete execution for the seven-source recovery frame. This WIP replaces that transport bound with counted closure tables already validated by bootstrap evidence.

The target is the physical compiler closure, not an intermediate collection of larger tuples. The current closure has 285 local modules and 1,378 imports. Native closure metadata already admits 512 local modules, sixty-four externals, 3,072 imports, and 262,144 canonical manifest bytes. Package-target validation admits 512 targets, 8,192 source selectors, 512 dependencies, 512 capabilities, and 131,072 tokens within the same manifest-byte ceiling. The compiler shall use those facts instead of reconstructing another graph format.

## Problem

`NativeModuleCompiler.w` receives zero through seven imported source frames followed by one root. That boundary is useful differential evidence and an unsuitable compiler interface. Raising it to eight by adding another loan would preserve the defect.

A self-hosting compiler needs:

- one validated package source archive.
- one validated rooted module manifest.
- counted module and import tables.
- deterministic source offsets independent of archive arrival.
- bounded work storage for active linking.
- executable-owner metadata whose size follows the closure, not a record constructor.
- one final root artifact published after complete verification.

The archive, manifest, package lock, and compiler options already have validate-before-identity codecs. Native compilation must consume those identities without weakening them.

## Goals

- Accept the canonical compiler archive and bootstrap module manifest as physical inputs.
- Revalidate package, source, path, module, import, and root identities before planning.
- Reuse the 512-module and 3,072-import closure ceilings.
- Replace packed forty-nine-bit graph facts with counted node and edge columns.
- Preserve canonical dependency-import and root-import order.
- Keep only bounded active linked sources mutable.
- Carry executable-owner identity through arbitrary closure depth.
- Publish one verified artifact or no artifact.
- Retain the seven-frame API only as a conformance fixture.

## Non-goals

- Add records, variants, aggregate layouts, or arbitrary ownership calls. [WIP-0045](WIP-0045-counted-native-module-symbol-products.md) owns those module products.
- Increase any package-schema ceiling.
- Infer source modules from directories.
- Trust archive order, manifest order, cache order, or allocation order.
- Check in `wheeler.bootstrap.yaml` before fixed-point and diverse-compilation evidence exists.

## Inputs

The compiler receives four immutable physical inputs:

1. canonical `wheeler.compiler.wpk` bytes.
2. canonical `wheeler.bootstrap-modules.yaml` bytes.
3. the selected root module name.
4. exact compiler options and limits identities.

Each physical evidence file remains nonsymbolic and at most 16 MiB. The package archive and module manifest must agree on every source path and SHA-256 identity. The selected root must be reachable and belong to the compiler tool target.

No input receives a trusted identity before complete structural and semantic validation.

## Closure plan

The closure plan uses counted fixed-capacity columns:

```text
ClosurePlan {
    module_count
    import_count
    root_module
    module_name[module_count]
    source_path[module_count]
    source_start[module_count]
    source_length[module_count]
    first_import[module_count]
    direct_import_count[module_count]
    import_target[import_count]
    import_rank[import_count]
    leaf_first_order[module_count]
    executable_owner[module_count]
}
```

Names and paths refer to validated ranges in immutable manifest or archive storage. Imports refer to module indices only after complete binding. `import_rank` preserves the dependent header. Frame arrival has no representation.

The planner rejects a cycle, detached source, duplicate module or path, unbound import, source-identity mismatch, count overflow, offset overflow, or changing input before publishing the plan.

## Execution

Execution follows leaf-first order. A source may be in one of three states:

- immutable archive source.
- active linked source.
- released linked source whose facts have been transferred to all dependents.

The compiler does not reserve 32,768 mutable bytes for every module. It allocates bounded work slots for active frontier sources and checks liveness before reuse. Immutable archive bytes remain the source of truth.

Constant-only edges run before executable edges for one dependent. Executable owners follow dependent import rank. Exact repeated constants and executable owner groups are retained once. The root compiles only after every selected dependency has completed.

## Ownership

Archive and manifest inputs are shared byte-view loans. Plan columns live in one owned region. Every active linked source has one owner and one slot generation. Reuse requires the prior owner to be destroyed and the generation to advance.

A source range never outlives its archive or manifest loan. A linked UTF-8 owner never outlives its work slot. The final artifact borrows neither.

## Determinism

The manifest module table, dependent-header import rank, and leaf-first plan order are authority. Hash-table iteration, archive entry order, frame order, allocation addresses, and worker completion order are not.

Equal validated inputs and limits produce equal plan columns, linked source, `.wbc` bytes, diagnostics, and transition counts.

## Limits

The first implementation retains existing proved ceilings:

- 512 local modules.
- sixty-four external modules.
- 3,072 imports.
- 262,144 manifest bytes.
- 32,768 bytes per physical or active linked source.
- 16 MiB per physical evidence file.

The first work-slot profile owns eight active sources and 262,144 mutable source bytes. `ACTIVE_SOURCE_SLOT_ARENA_BYTES = 262464` adds five eight-word metadata columns. These independent constants are not inferred from the module limit.

## Migration

1. Decode archive source offsets without copying source payloads.
2. Join archive paths and identities to the validated module manifest.
3. Materialize counted node and import columns.
4. Reproduce seven-frame scalar artifacts through the closure executor.
5. Add bounded active-source slot allocation and generation checks.
6. Compile progressively larger real compiler subclosures.
7. Retire the seven-frame API from production entry points.
8. Compile the complete physical compiler closure.

Compatibility wrappers do not remain in production. The seven-frame path stays only where differential tests need a small physical fixture.

## Progress

- [x] Core ranged SHA-256 admits every block in a 16 MiB physical evidence file.
- [x] `compiler/closure/ArchiveSources.w` validates the outer archive digest, every entry digest, canonical sorted paths, complete framing, and exact path/data offsets before publishing any column.
- [x] Archive source columns admit 512 entries. A 513th entry fails before hashing or mutation.
- [x] `PackageTarget.w` parses the complete canonical package manifest and binds one untested `compiler` tool target to the bootstrap root module and source path. Noncanonical layout and another target kind publish nothing.
- [x] Package syntax, names, paths, semantic versions, and manifest parsing moved under `compiler/packages`. The package library consumes those compiler-owned modules instead of carrying another parser.
- [x] Three-entry evidence checks physical path and payload offsets. Damaged outer evidence preserves caller columns.
- [x] `compiler/closure/ModuleManifest.w` owns canonical syntax, binding, root, cycle, and reachability validation. Conformance identity publication calls that owner.
- [x] `ArchiveModuleSources.w` joins all 285 physical compiler modules to exact digest-matching archive ranges. A mismatched source identity leaves publication untouched.
- [x] The manifest parser materializes counted module, external, import-owner, and resolved-target columns through 512 modules and 3,072 imports.
- [x] `ClosurePlan.w` publishes archive source ranges, first-import offsets, direct-import counts, import ranks, leaf-first order, and executable-owner bits only after complete validation.
- [x] A 257-module chain plans and classifies with its root last. The complete physical compiler closure plans and classifies without truncation.
- [x] Every physical compiler source is at most 32,768 bytes and classifies within 4,096 semantic tokens. Backend statement, compiler-core, and local-type owners replaced the oversized modules.
- [x] `SmallClosureExecutor.w` bridges an exact seven-import counted fixture to the differential executor. Direct constants, a redundant DAG, three executable owners beside four constants, and private helper edges match stage 0 byte for byte from package and manifest inputs.
- [x] `CountedConstantExecutor.w` consumes counted closure and product columns directly. A 257-module executable forwarding chain compiles without `BoundedGraphPlan` or dependency source.
- [x] Counted callable products and `GraphExecutor.w` replace packed arity-specific execution facts. The small seven-node bridge remains a differential fixture, not a production executor.
- [x] `ActiveSourceSlots.w` owns eight active linked sources, exact 32,768-byte publication, generation-checked leases, lowest-slot reuse, deterministic exhaustion, and byte destruction on release.
- [x] `ClosureSchedule.w` stages every source in leaf-first order, transfers no archive loan, releases each lease after staging, and publishes per-module slot generations only after the complete pass. The 257-module chain reaches generation 257.
- [x] WIP-0045 owns semantic module products. Scalar compilation transfers validated declarations and values instead of retaining linked source. The callable phase publishes 1,121 typed physical compiler signatures and body ranges. WIP-0049 now compiles complete primitive local classes against imported signatures without dependency bodies.
- [ ] The complete physical compiler closure compiles.

## Acceptance

- The counted closure executor reproduces every seven-frame differential byte for byte.
- A 257-module chain crosses the former native closure boundary and publishes correctly.
- The current 285-module compiler closure plans without truncation.
- Module and import order are invariant under archive-entry permutation.
- Invalid archive, manifest, source identity, root, offset, cycle, or bound publishes nothing.
- Active work slots cannot be read after release or stale generation.
- No executor API names a module arity.
- No authored file reaches 1,000 lines.
- No Wheeler source directory exceeds ten files.

## Rejected alternatives

### Add frame eight

Rejected. It extends a transport tuple and leaves the physical compiler closure 192 modules away.

### Allocate one full source slot per module

Rejected. The closure table bound is not permission to reserve 16 MiB of mutable linked-source storage.

### Reparse archive order as module order

Rejected. Archive order is serialization, not authority.

### Raise closure limits first

Rejected. The current proved limits already cover the physical compiler closure. Unused capacity is not the missing implementation.
