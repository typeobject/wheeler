//! Joins local and imported callable products into one dense call-target table.

module wheeler.compiler.closure.source_call_target_table;

classical class SourceCallTargetTable {
  private const long IDENTITY_BYTES = 32;
  private const long LOCAL_COUNT_LIMIT = 64;
  private const long NAME_BYTES_LIMIT = 1048576;
  private const long PARAMETER_COUNT_LIMIT = 16384;
  private const long TARGET_COUNT_LIMIT = 4096;
  private const long TARGET_ROWS = 32768;

  /// Reports one complete dense target table.
  public record SourceCallTargetTablePlan(
    long targetCount,
    long parameterCount,
    long nameBytes,
    boolean valid
  ) {}

  private boolean validResultType(long type) {
    if (type == 0) {
      return true;
    }

    if (type == 1) {
      return true;
    }

    return type == 2;
  }

  /// Copies local targets first and dependency targets in admitted semantic order.
  public SourceCallTargetTablePlan materializeSourceCallTargetTable(
    long localCount,
    borrow byteview localNames,
    borrow mut words localNameStarts,
    borrow mut words localNameLengths,
    borrow mut words localParameterStarts,
    borrow mut words localParameterCounts,
    borrow mut words localParameterTypes,
    borrow mut words localResultTypes,
    borrow byteview localIdentities,
    long importedCount,
    borrow mut words importedRows,
    borrow mut words importedParameterRows,
    borrow byteview importedNames,
    borrow byteview importedIdentities,
    borrow mut bytes targetNames,
    borrow mut words targetNameStarts,
    borrow mut words targetNameLengths,
    borrow mut words targetParameterStarts,
    borrow mut words targetParameterCounts,
    borrow mut words targetParameterTypes,
    borrow mut words targetResultTypes,
    borrow mut bytes targetIdentities,
    borrow mut words dependencyRows
  ) {
    assert(-1 < localCount);
    assert(localCount < LOCAL_COUNT_LIMIT + 1);
    assert(-1 < importedCount);
    assert(importedCount < TARGET_COUNT_LIMIT + 1);
    assert(importedCount < TARGET_COUNT_LIMIT - localCount + 1);
    assert(bufferLength(localNameStarts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(localNameLengths) == TARGET_COUNT_LIMIT);
    assert(bufferLength(localParameterStarts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(localParameterCounts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(localParameterTypes) == PARAMETER_COUNT_LIMIT);
    assert(bufferLength(localResultTypes) == TARGET_COUNT_LIMIT);
    assert(bufferLength(localIdentities) == 131072);
    assert(bufferLength(importedRows) == TARGET_ROWS);
    assert(bufferLength(importedParameterRows) == 32768);
    assert(bufferLength(importedIdentities) == 131072);
    assert(bufferLength(targetNames) == NAME_BYTES_LIMIT);
    assert(bufferLength(targetNameStarts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(targetNameLengths) == TARGET_COUNT_LIMIT);
    assert(bufferLength(targetParameterStarts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(targetParameterCounts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(targetParameterTypes) == PARAMETER_COUNT_LIMIT);
    assert(bufferLength(targetResultTypes) == TARGET_COUNT_LIMIT);
    assert(bufferLength(targetIdentities) == 131072);
    assert(bufferLength(dependencyRows) == 8192);

    region staging = new region(/* bytes= */ 1540096, /* allocations= */ 9);
    bytes stagedNames = allocateBytes(staging, NAME_BYTES_LIMIT);
    words stagedNameStarts = allocate(staging, TARGET_COUNT_LIMIT);
    words stagedNameLengths = allocate(staging, TARGET_COUNT_LIMIT);
    words stagedParameterStarts = allocate(staging, TARGET_COUNT_LIMIT);
    words stagedParameterCounts = allocate(staging, TARGET_COUNT_LIMIT);
    words stagedParameterTypes = allocate(staging, PARAMETER_COUNT_LIMIT);
    words stagedResultTypes = allocate(staging, TARGET_COUNT_LIMIT);
    bytes stagedIdentities = allocateBytes(staging, /* length= */ 131072);
    words stagedDependencies = allocate(staging, /* length= */ 8192);
    boolean valid = true;
    long nameCursor = 0;
    long parameterCursor = 0;
    long target = 0;
    while (target < localCount + importedCount) limit TARGET_COUNT_LIMIT {
      long nameStart = 0;
      long nameLength = 0;
      long firstParameter = 0;
      long parameterCount = 0;
      long resultType = -1;
      if (target < localCount) {
        nameStart = localNameStarts[target];
        nameLength = localNameLengths[target];
        firstParameter = localParameterStarts[target];
        parameterCount = localParameterCounts[target];
        resultType = localResultTypes[target];
        if (nameStart < 0) {
          valid = false;
        }

        if (bufferLength(localNames) - nameLength < nameStart) {
          valid = false;
        }

        if (PARAMETER_COUNT_LIMIT - parameterCount < firstParameter) {
          valid = false;
        }
      } else {
        long imported = target - localCount;
        nameStart = importedRows[8192 + imported];
        nameLength = importedRows[12288 + imported];
        firstParameter = importedRows[16384 + imported];
        parameterCount = importedRows[20480 + imported];
        resultType = importedRows[24576 + imported];
        if (nameStart < 0) {
          valid = false;
        }

        if (bufferLength(importedNames) - nameLength < nameStart) {
          valid = false;
        }

        if (PARAMETER_COUNT_LIMIT - parameterCount < firstParameter) {
          valid = false;
        }

        set(stagedDependencies, imported, importedRows[4096 + imported]);
        set(stagedDependencies, 4096 + imported, target);
      }

      if (nameLength < 1) {
        valid = false;
      }

      if (256 < nameLength) {
        valid = false;
      }

      if (parameterCount < 0) {
        valid = false;
      }

      if (64 < parameterCount) {
        valid = false;
      }

      if (NAME_BYTES_LIMIT - nameCursor < nameLength) {
        valid = false;
      }

      if (PARAMETER_COUNT_LIMIT - parameterCursor < parameterCount) {
        valid = false;
      }

      if (validResultType(resultType) == false) {
        valid = false;
      }

      if (valid) {
        set(stagedNameStarts, target, nameCursor);
        set(stagedNameLengths, target, nameLength);
        set(stagedParameterStarts, target, parameterCursor);
        set(stagedParameterCounts, target, parameterCount);
        set(stagedResultTypes, target, resultType);
        long nameByte = 0;
        while (nameByte < nameLength) limit 256 {
          long value = 0;
          if (target < localCount) {
            value = localNames[nameStart + nameByte];
          } else {
            value = importedNames[nameStart + nameByte];
          }

          setByte(stagedNames, nameCursor, value);
          nameCursor += 1;
          nameByte += 1;
        }

        long parameter = 0;
        while (parameter < parameterCount) limit 64 {
          long type = 0;
          if (target < localCount) {
            type = localParameterTypes[firstParameter + parameter];
          } else {
            type = importedParameterRows[firstParameter + parameter];
          }

          set(stagedParameterTypes, parameterCursor, type);
          parameterCursor += 1;
          parameter += 1;
        }

        long identityByte = 0;
        while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
          long identityValue = 0;
          if (target < localCount) {
            identityValue = localIdentities[target * IDENTITY_BYTES + identityByte];
          } else {
            identityValue = importedIdentities[(target - localCount) * IDENTITY_BYTES
              + identityByte];
          }

          setByte(stagedIdentities, target * IDENTITY_BYTES + identityByte, identityValue);
          identityByte += 1;
        }
      }

      target += 1;
    }

    if (valid) {
      long publishedNameByte = 0;
      while (publishedNameByte < nameCursor) limit NAME_BYTES_LIMIT {
        setByte(targetNames, publishedNameByte, stagedNames[publishedNameByte]);
        publishedNameByte += 1;
      }

      long row = 0;
      while (row < TARGET_COUNT_LIMIT) limit TARGET_COUNT_LIMIT {
        set(targetNameStarts, row, stagedNameStarts[row]);
        set(targetNameLengths, row, stagedNameLengths[row]);
        set(targetParameterStarts, row, stagedParameterStarts[row]);
        set(targetParameterCounts, row, stagedParameterCounts[row]);
        set(targetResultTypes, row, stagedResultTypes[row]);
        row += 1;
      }

      row = 0;
      while (row < PARAMETER_COUNT_LIMIT) limit PARAMETER_COUNT_LIMIT {
        set(targetParameterTypes, row, stagedParameterTypes[row]);
        row += 1;
      }

      long publishedIdentityByte = 0;
      while (publishedIdentityByte < (localCount + importedCount) * IDENTITY_BYTES) limit 131072 {
        setByte(
          targetIdentities,
          publishedIdentityByte,
          stagedIdentities[publishedIdentityByte]
        );
        publishedIdentityByte += 1;
      }

      row = 0;
      while (row < 8192) limit 8192 {
        set(dependencyRows, row, stagedDependencies[row]);
        row += 1;
      }
    }

    drop(stagedDependencies);
    drop(stagedIdentities);
    drop(stagedResultTypes);
    drop(stagedParameterTypes);
    drop(stagedParameterCounts);
    drop(stagedParameterStarts);
    drop(stagedNameLengths);
    drop(stagedNameStarts);
    drop(stagedNames);
    drop(staging);
    return new SourceCallTargetTablePlan(
      localCount + importedCount,
      parameterCursor,
      nameCursor,
      valid
    );
  }
}
