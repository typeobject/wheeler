//! Packs header-ranked public callable products from direct dependencies.

module wheeler.compiler.closure.callable_dependency_products;

classical class CallableDependencyProducts {
  private const long DEPENDENCY_ROWS = 8192;
  private const long MAX_CALLABLES = 4096;
  private const long MAX_DIRECT_IMPORTS = 64;
  private const long MAX_EXTERNALS = 64;
  private const long MAX_IMPORTS = 3072;
  private const long MAX_MODULES = 512;

  private long publicCallableCount(
    long firstCallable,
    long callableCount,
    borrow mut words visibilities,
    borrow mut words availableCallables
  ) {
    assert(-1 < firstCallable);
    assert(-1 < callableCount);
    assert(callableCount < MAX_CALLABLES - firstCallable + 1);
    long count = 0;
    long offset = 0;
    while (offset < callableCount) limit MAX_CALLABLES {
      long visibility = visibilities[firstCallable + offset];
      if (visibility == 0) {} else {
        assert(visibility == 1);
      }

      long available = availableCallables[firstCallable + offset];
      if (available == 0) {} else {
        assert(available == 1);
      }

      if (visibility == 1) {
        if (available == 1) {
          count += 1;
        }
      }

      offset += 1;
    }

    return count;
  }

  /// Publishes dependency rank and local or negative external callable index columns.
  public long packCallableDependencyProducts(
    long moduleCount,
    long externalCount,
    long module,
    borrow mut words firstImports,
    borrow mut words directImportCounts,
    borrow mut words edgeTargets,
    borrow mut words moduleFirstCallables,
    borrow mut words moduleCallableCounts,
    borrow mut words localVisibilities,
    borrow mut words localAvailableCallables,
    borrow mut words externalFirstCallables,
    borrow mut words externalCallableCounts,
    borrow mut words externalVisibilities,
    borrow mut words externalAvailableCallables,
    borrow mut words dependencyRows
  ) {
    assert(0 < moduleCount);
    assert(moduleCount < MAX_MODULES + 1);
    assert(-1 < externalCount);
    assert(externalCount < MAX_EXTERNALS + 1);
    assert(-1 < module);
    assert(module < moduleCount);
    assert(bufferLength(firstImports) == MAX_MODULES);
    assert(bufferLength(directImportCounts) == MAX_MODULES);
    assert(bufferLength(edgeTargets) == MAX_IMPORTS);
    assert(bufferLength(moduleFirstCallables) == MAX_MODULES);
    assert(bufferLength(moduleCallableCounts) == MAX_MODULES);
    assert(bufferLength(localVisibilities) == MAX_CALLABLES);
    assert(bufferLength(localAvailableCallables) == MAX_CALLABLES);
    assert(bufferLength(externalFirstCallables) == MAX_EXTERNALS);
    assert(bufferLength(externalCallableCounts) == MAX_EXTERNALS);
    assert(bufferLength(externalVisibilities) == MAX_CALLABLES);
    assert(bufferLength(externalAvailableCallables) == MAX_CALLABLES);
    assert(bufferLength(dependencyRows) == DEPENDENCY_ROWS);
    long firstImport = firstImports[module];
    long directImportCount = directImportCounts[module];
    assert(-1 < firstImport);
    assert(-1 < directImportCount);
    assert(directImportCount < MAX_DIRECT_IMPORTS + 1);
    assert(directImportCount < MAX_IMPORTS - firstImport + 1);

    long productCount = 0;
    long rank = 0;
    while (rank < directImportCount) limit MAX_DIRECT_IMPORTS {
      long target = edgeTargets[firstImport + rank];
      if (-1 < target) {
        assert(target < moduleCount);
        productCount += publicCallableCount(
          moduleFirstCallables[target],
          moduleCallableCounts[target],
          localVisibilities,
          localAvailableCallables
        );
      } else {
        long external = 0 - target - 1;
        assert(-1 < external);
        assert(external < externalCount);
        productCount += publicCallableCount(
          externalFirstCallables[external],
          externalCallableCounts[external],
          externalVisibilities,
          externalAvailableCallables
        );
      }

      assert(productCount < MAX_CALLABLES + 1);
      rank += 1;
    }

    long product = 0;
    rank = 0;
    while (rank < directImportCount) limit MAX_DIRECT_IMPORTS {
      long selectedTarget = edgeTargets[firstImport + rank];
      long firstCallable = 0;
      long callableCount = 0;
      boolean externalProduct = false;
      if (-1 < selectedTarget) {
        firstCallable = moduleFirstCallables[selectedTarget];
        callableCount = moduleCallableCounts[selectedTarget];
      } else {
        long selectedExternal = 0 - selectedTarget - 1;
        firstCallable = externalFirstCallables[selectedExternal];
        callableCount = externalCallableCounts[selectedExternal];
        externalProduct = true;
      }

      long offset = 0;
      while (offset < callableCount) limit MAX_CALLABLES {
        long callable = firstCallable + offset;
        long visibility = localVisibilities[callable];
        long available = localAvailableCallables[callable];
        if (externalProduct) {
          visibility = externalVisibilities[callable];
          available = externalAvailableCallables[callable];
        }

        if (visibility == 1) {
          if (available == 1) {
            set(dependencyRows, product, rank);
            if (externalProduct) {
              set(dependencyRows, 4096 + product, 0 - callable - 1);
            } else {
              set(dependencyRows, 4096 + product, callable);
            }

            product += 1;
          }
        }

        offset += 1;
      }

      rank += 1;
    }

    assert(product == productCount);
    return productCount;
  }
}
