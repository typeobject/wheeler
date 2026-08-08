//! Packs header-ranked local and locked external aggregate product identities.

module wheeler.compiler.closure.aggregate_dependency_products;

classical class AggregateDependencyProducts {
  private const long EXTERNAL_IDENTITY_BYTES = 2048;
  private const long IDENTITY_BYTES = 32;
  private const long MAX_DIRECT_IMPORTS = 64;
  private const long MAX_EXTERNALS = 64;
  private const long MAX_IMPORTS = 3072;
  private const long MAX_LOCAL_MODULES = 512;
  private const long MODULE_IDENTITY_BYTES = 16384;

  /// Copies one validated identity per direct import in header order.
  public long packAggregateDependencyIdentities(
    long moduleCount,
    long externalCount,
    long module,
    borrow mut words firstImports,
    borrow mut words directImportCounts,
    borrow mut words edgeTargets,
    borrow mut words localPublished,
    borrow mut words externalPublished,
    borrow byteview localIdentities,
    borrow byteview externalIdentities,
    borrow mut bytes output
  ) {
    assert(0 < moduleCount);
    assert(moduleCount < MAX_LOCAL_MODULES + 1);
    assert(-1 < externalCount);
    assert(externalCount < MAX_EXTERNALS + 1);
    assert(-1 < module);
    assert(module < moduleCount);
    assert(bufferLength(firstImports) == MAX_LOCAL_MODULES);
    assert(bufferLength(directImportCounts) == MAX_LOCAL_MODULES);
    assert(bufferLength(edgeTargets) == MAX_IMPORTS);
    assert(bufferLength(localPublished) == MAX_LOCAL_MODULES);
    assert(bufferLength(externalPublished) == MAX_EXTERNALS);
    assert(bufferLength(localIdentities) == MODULE_IDENTITY_BYTES);
    assert(bufferLength(externalIdentities) == EXTERNAL_IDENTITY_BYTES);
    assert(bufferLength(output) == EXTERNAL_IDENTITY_BYTES);
    long firstImport = firstImports[module];
    long dependencyCount = directImportCounts[module];
    assert(-1 < firstImport);
    assert(-1 < dependencyCount);
    assert(dependencyCount < MAX_DIRECT_IMPORTS + 1);
    assert(firstImport < MAX_IMPORTS + 1);
    assert(dependencyCount < MAX_IMPORTS - firstImport + 1);

    long dependency = 0;
    while (dependency < dependencyCount) limit MAX_DIRECT_IMPORTS {
      long target = edgeTargets[firstImport + dependency];
      if (-1 < target) {
        assert(target < moduleCount);
        assert(localPublished[target] == 1);
      } else {
        long external = 0 - target - 1;
        assert(-1 < external);
        assert(external < externalCount);
        assert(externalPublished[external] == 1);
      }

      dependency += 1;
    }

    dependency = 0;
    while (dependency < dependencyCount) limit MAX_DIRECT_IMPORTS {
      long selectedTarget = edgeTargets[firstImport + dependency];
      long identityStart = 0;
      if (-1 < selectedTarget) {
        identityStart = selectedTarget * IDENTITY_BYTES;
      } else {
        identityStart = (0 - selectedTarget - 1) * IDENTITY_BYTES;
      }

      long identityByte = 0;
      while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
        if (-1 < selectedTarget) {
          setByte(
            output,
            dependency * IDENTITY_BYTES + identityByte,
            localIdentities[identityStart + identityByte]
          );
        } else {
          setByte(
            output,
            dependency * IDENTITY_BYTES + identityByte,
            externalIdentities[identityStart + identityByte]
          );
        }

        identityByte += 1;
      }

      dependency += 1;
    }

    return dependencyCount;
  }
}
