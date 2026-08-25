//! Materializes counted closure columns from validated manifest and archive facts.

module wheeler.compiler.closure.plan;

import wheeler.compiler.closure.manifest_assertions;
import wheeler.compiler.closure.module_manifest;
import wheeler.compiler.graphs.executable_owner_kinds;

classical class ClosurePlans {
  private const long MAX_LOCAL_MODULES = 512;
  private const long MAX_EXTERNAL_MODULES = 64;
  private const long MAX_IMPORTS = 3072;
  private const long MAX_ARCHIVE_ENTRIES = 512;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long PLAN_ARENA_BYTES = 53248;
  private const long SOURCE_ARENA_BYTES = 32768;

  /// Identifies the active prefix of every validated closure-plan column.
  public record CountedClosurePlan(
    long moduleCount,
    long externalCount,
    long importCount,
    long rootModule
  ) {}

  private boolean sameModuleName(
    borrow byteview manifest,
    long manifestStart,
    long manifestLength,
    borrow utf8 source,
    long sourceStart,
    long sourceLength
  ) {
    if (manifestLength == sourceLength) {} else {
      return false;
    }

    long index = 0;
    while (index < manifestLength) limit 128 {
      if (manifest[manifestStart + index] == utf8Scalar(source, sourceStart + index)) {} else {
        return false;
      }

      index += 1;
    }

    return true;
  }

  /// Publishes source ranges, import ranks, and deterministic leaf-first order.
  ///
  /// Every caller column remains unchanged until the complete plan validates.
  public CountedClosurePlan planClosureStructure(
    borrow byteview archive,
    borrow byteview manifest,
    BootstrapModuleManifestPlan manifestPlan,
    borrow mut words edgeOwners,
    borrow mut words edgeTargets,
    borrow mut words moduleArchiveEntries,
    borrow mut words archiveDataStarts,
    borrow mut words archiveDataLengths,
    borrow mut words sourceStarts,
    borrow mut words sourceLengths,
    borrow mut words firstImports,
    borrow mut words directImportCounts,
    borrow mut words importRanks,
    borrow mut words leafFirstOrder
  ) {
    requireMetadata(0 < manifestPlan.moduleCount);
    requireMetadata(manifestPlan.moduleCount < MAX_LOCAL_MODULES + 1);
    requireMetadata(manifestPlan.externalCount < MAX_EXTERNAL_MODULES + 1);
    requireMetadata(manifestPlan.importCount < MAX_IMPORTS + 1);
    requireMetadata(-1 < manifestPlan.rootModule);
    requireMetadata(manifestPlan.rootModule < manifestPlan.moduleCount);
    region scratchArena = new region(/* bytes= */ PLAN_ARENA_BYTES, /* allocations= */ 8);
    words scratchSourceStarts = allocate(scratchArena, MAX_LOCAL_MODULES);
    words scratchSourceLengths = allocate(scratchArena, MAX_LOCAL_MODULES);
    words scratchFirstImports = allocate(scratchArena, MAX_LOCAL_MODULES);
    words scratchDirectCounts = allocate(scratchArena, MAX_LOCAL_MODULES);
    words scratchRanks = allocate(scratchArena, MAX_IMPORTS);
    words scratchOrder = allocate(scratchArena, MAX_LOCAL_MODULES);
    words remainingDependencies = allocate(scratchArena, MAX_LOCAL_MODULES);
    words removed = allocate(scratchArena, MAX_LOCAL_MODULES);

    long module = 0;
    while (module < manifestPlan.moduleCount) limit MAX_LOCAL_MODULES {
      long entry = moduleArchiveEntries[module];
      requireMetadata(-1 < entry);
      requireMetadata(entry < MAX_ARCHIVE_ENTRIES);
      long sourceStart = archiveDataStarts[entry];
      long sourceLength = archiveDataLengths[entry];
      requireMetadata(-1 < sourceStart);
      requireMetadata(-1 < sourceLength);
      requireMetadata(sourceLength < MAX_SOURCE_BYTES + 1);
      requireMetadata(sourceStart < bufferLength(archive) + 1);
      requireMetadata(sourceLength < bufferLength(archive) - sourceStart + 1);
      set(scratchSourceStarts, module, sourceStart);
      set(scratchSourceLengths, module, sourceLength);
      module += 1;

    }

    long edge = 0;
    module = 0;

    while (module < manifestPlan.moduleCount) limit MAX_LOCAL_MODULES {
      set(scratchFirstImports, module, edge);
      long rank = 0;
      boolean more = edge < manifestPlan.importCount;
      if (more) {
        requireMetadata(module < edgeOwners[edge] + 1);
        more = edgeOwners[edge] == module;
      }

      while (more) limit 64 {
        long target = edgeTargets[edge];
        if (-1 < target) {
          requireMetadata(target < manifestPlan.moduleCount);
          set(remainingDependencies, module, remainingDependencies[module] + 1);
        } else {
          long externalTarget = 0 - target - 1;
          requireMetadata(-1 < externalTarget);
          requireMetadata(externalTarget < manifestPlan.externalCount);
        }

        set(scratchRanks, edge, rank);
        rank += 1;
        edge += 1;
        more = edge < manifestPlan.importCount;
        if (more) {
          more = edgeOwners[edge] == module;
        }
      }

      set(scratchDirectCounts, module, rank);
      module += 1;

    }

    requireMetadata(edge == manifestPlan.importCount);

    long ordered = 0;
    while (ordered < manifestPlan.moduleCount) limit MAX_LOCAL_MODULES {
      long candidate = -1;
      module = 0;

      while (module < manifestPlan.moduleCount) limit MAX_LOCAL_MODULES {
        if (removed[module] == 0) {
          if (remainingDependencies[module] == 0) {
            if (candidate < 0) {
              candidate = module;
            }
          }
        }

        module += 1;

      }

      requireMetadata(-1 < candidate);
      set(scratchOrder, ordered, candidate);
      set(removed, candidate, 1);
      edge = 0;
      while (edge < manifestPlan.importCount) limit MAX_IMPORTS {
        if (edgeTargets[edge] == candidate) {
          long owner = edgeOwners[edge];
          set(remainingDependencies, owner, remainingDependencies[owner] - 1);
        }

        edge += 1;
      }

      ordered += 1;
    }

    requireMetadata(scratchOrder[manifestPlan.moduleCount - 1] == manifestPlan.rootModule);

    module = 0;

    while (module < manifestPlan.moduleCount) limit MAX_LOCAL_MODULES {
      set(sourceStarts, module, scratchSourceStarts[module]);
      set(sourceLengths, module, scratchSourceLengths[module]);
      set(firstImports, module, scratchFirstImports[module]);
      set(directImportCounts, module, scratchDirectCounts[module]);
      set(leafFirstOrder, module, scratchOrder[module]);
      module += 1;

    }

    edge = 0;
    while (edge < manifestPlan.importCount) limit MAX_IMPORTS {
      set(importRanks, edge, scratchRanks[edge]);
      edge += 1;
    }

    CountedClosurePlan result = new CountedClosurePlan(
      manifestPlan.moduleCount,
      manifestPlan.externalCount,
      manifestPlan.importCount,
      manifestPlan.rootModule
    );
    drop(removed);
    drop(remainingDependencies);
    drop(scratchOrder);
    drop(scratchRanks);
    drop(scratchDirectCounts);
    drop(scratchFirstImports);
    drop(scratchSourceLengths);
    drop(scratchSourceStarts);
    drop(scratchArena);
    return result;
  }

  /// Classifies each module from its validated immutable archive source range.
  ///
  /// The caller's executable-owner column changes only after every source validates.
  public void classifyClosureExecutableOwners(
    borrow byteview archive,
    borrow byteview manifest,
    CountedClosurePlan plan,
    borrow mut words moduleNameStarts,
    borrow mut words moduleNameLengths,
    borrow mut words sourceStarts,
    borrow mut words sourceLengths,
    borrow mut words executableOwners
  ) {
    region resultArena = new region(/* bytes= */ 4096, /* allocations= */ 1);
    words scratchOwners = allocate(resultArena, MAX_LOCAL_MODULES);
    long module = 0;
    while (module < plan.moduleCount) limit MAX_LOCAL_MODULES {
      long sourceStart = sourceStarts[module];
      long sourceLength = sourceLengths[module];
      requireMetadata(sourceLength < MAX_SOURCE_BYTES + 1);
      region sourceArena = new region(/* bytes= */ SOURCE_ARENA_BYTES, /* allocations= */ 1);
      bytes sourceBytes = allocateBytes(sourceArena, sourceLength);
      long cursor = 0;
      while (cursor < sourceLength) limit MAX_SOURCE_BYTES {
        setByte(sourceBytes, cursor, archive[sourceStart + cursor]);
        cursor += 1;
      }

      utf8 source = freezeUtf8(sourceBytes);
      ExecutableOwnerKind kind = classifyExecutableOwner(source);
      requireMetadata(kind.valid);
      requireMetadata(
        sameModuleName(
          manifest,
          moduleNameStarts[module],
          moduleNameLengths[module],
          source,
          kind.moduleStart,
          kind.moduleLength
        )
      );
      long executable = 0;
      if (kind.executable) {
        executable = 1;
      }

      set(scratchOwners, module, executable);
      drop(source);
      drop(sourceArena);
      module += 1;

    }

    module = 0;

    while (module < plan.moduleCount) limit MAX_LOCAL_MODULES {
      set(executableOwners, module, scratchOwners[module]);
      module += 1;

    }

    drop(scratchOwners);
    drop(resultArena);
  }
}
