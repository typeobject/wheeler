//! Copies canonical direct-dependency qualifiers beside imported call targets.

module wheeler.compiler.closure.imported_call_qualifier_products;

classical class ImportedCallQualifierProducts {
  private const long MAX_MODULES = 512;
  private const long MAX_NAME_BYTES = 1048576;
  private const long MAX_TARGETS = 4096;

  /// Reports one complete target-aligned qualifier table.
  public record ImportedCallQualifierPlan(long targetCount, long nameBytes, boolean valid) {}

  /// Publishes canonical module names and dependency ranks without dependency source.
  public ImportedCallQualifierPlan materializeImportedCallQualifierProducts(
    long targetCount,
    borrow mut words targetRows,
    borrow mut words callableOwners,
    borrow byteview moduleNames,
    borrow mut words moduleNameStarts,
    borrow mut words moduleNameLengths,
    borrow mut bytes qualifierNames,
    borrow mut words qualifierNameStarts,
    borrow mut words qualifierNameLengths,
    borrow mut words qualifierDependencyRanks
  ) {
    assert(-1 < targetCount);
    assert(targetCount < MAX_TARGETS + 1);
    assert(bufferLength(targetRows) == 32768);
    assert(bufferLength(callableOwners) == MAX_TARGETS);
    assert(bufferLength(moduleNameStarts) == MAX_MODULES);
    assert(bufferLength(moduleNameLengths) == MAX_MODULES);
    assert(bufferLength(qualifierNames) == MAX_NAME_BYTES);
    assert(bufferLength(qualifierNameStarts) == MAX_TARGETS);
    assert(bufferLength(qualifierNameLengths) == MAX_TARGETS);
    assert(bufferLength(qualifierDependencyRanks) == MAX_TARGETS);

    region staging = new region(/* bytes= */ 1146880, /* allocations= */ 4);
    bytes stagedNames = allocateBytes(staging, MAX_NAME_BYTES);
    words stagedStarts = allocate(staging, MAX_TARGETS);
    words stagedLengths = allocate(staging, MAX_TARGETS);
    words stagedRanks = allocate(staging, MAX_TARGETS);
    boolean valid = true;
    long cursor = 0;
    long target = 0;
    while (target < targetCount) limit MAX_TARGETS {
      long callable = targetRows[target];
      if (callable < 0) {
        valid = false;
      }

      if (MAX_TARGETS - 1 < callable) {
        valid = false;
      }

      long owner = -1;
      if (-1 < callable) {
        if (callable < MAX_TARGETS) {
          owner = callableOwners[callable];
        }
      }

      if (owner < 0) {
        valid = false;
      }

      if (MAX_MODULES - 1 < owner) {
        valid = false;
      }

      long start = 0;
      long length = 0;
      if (-1 < owner) {
        if (owner < MAX_MODULES) {
          start = moduleNameStarts[owner];
          length = moduleNameLengths[owner];
        }
      }

      if (start < 0) {
        valid = false;
      }

      if (length < 1) {
        valid = false;
      }

      if (256 < length) {
        valid = false;
      }

      if (bufferLength(moduleNames) - length < start) {
        valid = false;
      }

      if (MAX_NAME_BYTES - cursor < length) {
        valid = false;
      }

      long prior = 0;
      while (prior < target) limit MAX_TARGETS {
        if (targetRows[4096 + prior] == targetRows[4096 + target]) {
          long priorCallable = targetRows[prior];
          if (-1 < priorCallable) {
            if (callableOwners[priorCallable] != owner) {
              valid = false;
            }
          }
        }

        prior += 1;
      }

      if (valid) {
        set(stagedStarts, target, cursor);
        set(stagedLengths, target, length);
        set(stagedRanks, target, targetRows[4096 + target]);
        long nameByte = 0;
        while (nameByte < length) limit 256 {
          setByte(stagedNames, cursor, moduleNames[start + nameByte]);
          cursor += 1;
          nameByte += 1;
        }
      }

      target += 1;
    }

    if (valid) {
      long publishedNameByte = 0;
      while (publishedNameByte < cursor) limit MAX_NAME_BYTES {
        setByte(qualifierNames, publishedNameByte, stagedNames[publishedNameByte]);
        publishedNameByte += 1;
      }

      long row = 0;
      while (row < targetCount) limit MAX_TARGETS {
        set(qualifierNameStarts, row, stagedStarts[row]);
        set(qualifierNameLengths, row, stagedLengths[row]);
        set(qualifierDependencyRanks, row, stagedRanks[row]);
        row += 1;
      }
    }

    drop(stagedRanks);
    drop(stagedLengths);
    drop(stagedStarts);
    drop(stagedNames);
    drop(staging);
    return new ImportedCallQualifierPlan(targetCount, cursor, valid);
  }
}
