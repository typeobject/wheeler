//! Joins validated package entries to one validated bootstrap module closure.

module wheeler.compiler.closure.archive_module_sources;

import wheeler.compiler.closure.archive_sources;
import wheeler.compiler.closure.manifest_assertions;
import wheeler.compiler.closure.module_manifest;

classical class ArchiveModuleSources {
  private const long MAX_LOCAL_MODULES = 512;
  private const long MAX_ARCHIVE_ENTRIES = 512;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long SOURCE_ENTRY_ARENA_BYTES = 4096;

  /// Records one complete manifest-to-archive source binding.
  public record ArchiveModuleSourcePlan(
    long moduleCount,
    long rootModule,
    long archiveEntryCount
  ) {}

  private boolean samePath(
    borrow byteview archive,
    long archiveStart,
    long archiveLength,
    borrow byteview manifest,
    long manifestStart,
    long manifestLength
  ) {
    if (archiveLength == manifestLength) {} else {
      return false;
    }

    long index = 0;
    while (index < manifestLength) limit 256 {
      if (archive[archiveStart + index] == manifest[manifestStart + index]) {} else {
        return false;
      }

      index += 1;
    }

    return true;
  }

  private long hexNibble(long scalar) {
    if (scalar < 58) {
      return scalar - 48;
    }

    return scalar - 87;
  }

  private boolean sameIdentity(
    borrow byteview archive,
    long digestStart,
    borrow byteview manifest,
    long identityStart
  ) {
    long index = 0;
    while (index < 32) limit 32 {
      long high = hexNibble(manifest[identityStart + index * 2]);
      long low = hexNibble(manifest[identityStart + index * 2 + 1]);
      if (archive[digestStart + index] == high * 16 + low) {} else {
        return false;
      }

      index += 1;
    }

    return true;
  }

  /// Binds every local module to one digest-matching immutable archive range.
  ///
  /// Caller columns are unchanged unless every module has one exact source entry.
  public ArchiveModuleSourcePlan joinArchiveModuleSources(
    borrow byteview archive,
    ArchiveSourceIndex archiveIndex,
    borrow mut words archivePathStarts,
    borrow mut words archivePathLengths,
    borrow mut words archiveDataStarts,
    borrow mut words archiveDataLengths,
    borrow byteview manifest,
    BootstrapModuleManifestPlan manifestPlan,
    borrow mut words moduleSourceStarts,
    borrow mut words moduleSourceLengths,
    borrow mut words moduleIdentityStarts,
    borrow mut words moduleArchiveEntries
  ) {
    requireMetadata(manifestPlan.moduleCount < MAX_LOCAL_MODULES + 1, manifest);
    requireMetadata(archiveIndex.entryCount < MAX_ARCHIVE_ENTRIES + 1, manifest);
    region scratchArena = new region(/* bytes= */ SOURCE_ENTRY_ARENA_BYTES, /* allocations= */ 1);
    words scratchEntries = allocate(scratchArena, MAX_LOCAL_MODULES);
    long module = 0;
    while (module < manifestPlan.moduleCount) limit MAX_LOCAL_MODULES {
      long found = -1;
      long entry = 0;
      while (entry < archiveIndex.entryCount) limit MAX_ARCHIVE_ENTRIES {
        if (
          samePath(
            archive,
            archivePathStarts[entry],
            archivePathLengths[entry],
            manifest,
            moduleSourceStarts[module],
            moduleSourceLengths[module]
          )
        ) {
          requireMetadata(found < 0, manifest);
          found = entry;
        }

        entry += 1;
      }

      requireMetadata(-1 < found, manifest);
      requireMetadata(archiveDataLengths[found] < MAX_SOURCE_BYTES + 1, manifest);
      requireMetadata(
        sameIdentity(
          archive,
          archiveDataStarts[found] - 32,
          manifest,
          moduleIdentityStarts[module]
        ),
        manifest
      );
      set(scratchEntries, module, found);
      module += 1;

    }

    module = 0;

    while (module < manifestPlan.moduleCount) limit MAX_LOCAL_MODULES {
      set(moduleArchiveEntries, module, scratchEntries[module]);
      module += 1;

    }

    ArchiveModuleSourcePlan result = new ArchiveModuleSourcePlan(
      manifestPlan.moduleCount,
      manifestPlan.rootModule,
      archiveIndex.entryCount
    );
    drop(scratchEntries);
    drop(scratchArena);
    return result;
  }
}
