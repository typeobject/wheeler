//! Publishes a closed source-call target view from direct dependency products.

module wheeler.compiler.closure.imported_source_call_targets;

import wheeler.compiler.type_codes;

classical class ImportedSourceCallTargets {
  private const long CALLABLE_COUNT_LIMIT = 4096;
  private const long DEPENDENCY_ROWS = 8192;
  private const long IDENTITY_BYTES = 32;
  private const long NAME_BYTES_LIMIT = 1048576;
  private const long PARAMETER_COUNT_LIMIT = 16384;
  private const long TARGET_ROWS = 32768;

  /// Reports one complete imported target and parameter view.
  public record ImportedSourceCallTargetPlan(
    long targetCount,
    long parameterCount,
    long nameBytes,
    boolean valid
  ) {}

  private long localParameterType(long type, long mode) {
    if (mode == 0) {
      return type;
    }

    if (type == TYPE_REGION) {
      return TYPE_REGION_BORROW;
    }

    if (type == TYPE_WORDS) {
      return TYPE_WORDS_BORROW;
    }

    if (type == TYPE_BYTES) {
      return TYPE_BYTES_BORROW;
    }

    if (type == TYPE_LONG_MAP) {
      return TYPE_LONG_MAP_BORROW;
    }

    if (type == TYPE_UTF8) {
      return TYPE_UTF8_BORROW;
    }

    if (type == TYPE_BYTE_VIEW) {
      return TYPE_BYTE_VIEW;
    }

    return -1;
  }

  private boolean identityBefore(borrow byteview identities, long left, long right) {
    long offset = 0;
    while (offset < IDENTITY_BYTES) limit IDENTITY_BYTES {
      long leftByte = identities[left * IDENTITY_BYTES + offset];
      long rightByte = identities[right * IDENTITY_BYTES + offset];
      if (leftByte < rightByte) {
        return true;
      }

      if (rightByte < leftByte) {
        return false;
      }

      offset += 1;
    }

    return false;
  }

  private boolean sameIdentity(borrow byteview identities, long left, long right) {
    long offset = 0;
    while (offset < IDENTITY_BYTES) limit IDENTITY_BYTES {
      if (
        identities[left * IDENTITY_BYTES + offset] != identities[right * IDENTITY_BYTES + offset]
      ) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private long nextProduct(
    long dependencyCount,
    borrow mut words dependencyRows,
    borrow mut words selected,
    borrow byteview callableIdentities
  ) {
    long chosen = -1;
    long product = 0;
    while (product < dependencyCount) limit CALLABLE_COUNT_LIMIT {
      if (selected[product] == 0) {
        long callable = dependencyRows[4096 + product];
        if (-1 < callable) {
          if (chosen < 0) {
            chosen = product;
          } else {
            long chosenRank = dependencyRows[chosen];
            long candidateRank = dependencyRows[product];
            long chosenCallable = dependencyRows[4096 + chosen];
            if (candidateRank < chosenRank) {
              chosen = product;
            } else {
              if (candidateRank == chosenRank) {
                if (identityBefore(callableIdentities, callable, chosenCallable)) {
                  chosen = product;
                }
              }
            }
          }
        }
      }

      product += 1;
    }

    return chosen;
  }

  /// Copies names, signatures, effects, and identities in semantic dependency order.
  public ImportedSourceCallTargetPlan materializeImportedSourceCallTargets(
    long dependencyCount,
    borrow mut words dependencyRows,
    borrow byteview callableNames,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableFirstParameters,
    borrow mut words callableParameterCounts,
    borrow mut words callableResultTypes,
    borrow mut words callableEffects,
    borrow mut words parameterTypes,
    borrow mut words parameterModes,
    borrow byteview callableIdentities,
    borrow mut words targetRows,
    borrow mut words targetParameterRows,
    borrow mut bytes targetNames,
    borrow mut bytes targetIdentities
  ) {
    assert(-1 < dependencyCount);
    assert(dependencyCount < CALLABLE_COUNT_LIMIT + 1);
    assert(bufferLength(dependencyRows) == DEPENDENCY_ROWS);
    assert(bufferLength(callableNameStarts) == CALLABLE_COUNT_LIMIT);
    assert(bufferLength(callableNameLengths) == CALLABLE_COUNT_LIMIT);
    assert(bufferLength(callableFirstParameters) == CALLABLE_COUNT_LIMIT);
    assert(bufferLength(callableParameterCounts) == CALLABLE_COUNT_LIMIT);
    assert(bufferLength(callableResultTypes) == CALLABLE_COUNT_LIMIT);
    assert(bufferLength(callableEffects) == CALLABLE_COUNT_LIMIT);
    assert(bufferLength(parameterTypes) == PARAMETER_COUNT_LIMIT);
    assert(bufferLength(parameterModes) == PARAMETER_COUNT_LIMIT);
    assert(bufferLength(callableIdentities) == 131072);
    assert(bufferLength(targetRows) == TARGET_ROWS);
    assert(bufferLength(targetParameterRows) == 32768);
    assert(bufferLength(targetNames) == NAME_BYTES_LIMIT);
    assert(bufferLength(targetIdentities) == 131072);

    region staging = new region(/* bytes= */ 1736704, /* allocations= */ 5);
    words stagedTargets = allocate(staging, TARGET_ROWS);
    words stagedParameters = allocate(staging, /* length= */ 32768);
    words selected = allocate(staging, CALLABLE_COUNT_LIMIT);
    bytes stagedNames = allocateBytes(staging, NAME_BYTES_LIMIT);
    bytes stagedIdentities = allocateBytes(staging, /* length= */ 131072);
    boolean valid = true;
    long checked = 0;
    while (checked < dependencyCount) limit CALLABLE_COUNT_LIMIT {
      long checkedCallable = dependencyRows[4096 + checked];
      if (checkedCallable < 0) {
        valid = false;
      } else {
        if (CALLABLE_COUNT_LIMIT - 1 < checkedCallable) {
          valid = false;
        } else {
          long checkedNameStart = callableNameStarts[checkedCallable];
          long checkedNameLength = callableNameLengths[checkedCallable];
          long checkedFirstParameter = callableFirstParameters[checkedCallable];
          long checkedParameterCount = callableParameterCounts[checkedCallable];
          if (checkedNameStart < 0) {
            valid = false;
          }

          if (checkedNameLength < 1) {
            valid = false;
          }

          if (256 < checkedNameLength) {
            valid = false;
          }

          if (bufferLength(callableNames) - checkedNameLength < checkedNameStart) {
            valid = false;
          }

          if (checkedFirstParameter < 0) {
            valid = false;
          }

          if (checkedParameterCount < 0) {
            valid = false;
          }

          if (64 < checkedParameterCount) {
            valid = false;
          }

          if (PARAMETER_COUNT_LIMIT - checkedParameterCount < checkedFirstParameter) {
            valid = false;
          }

          long prior = 0;
          while (prior < checked) limit CALLABLE_COUNT_LIMIT {
            long priorCallable = dependencyRows[4096 + prior];
            if (-1 < priorCallable) {
              if (sameIdentity(callableIdentities, checkedCallable, priorCallable)) {
                valid = false;
              }
            }

            prior += 1;
          }
        }
      }

      checked += 1;
    }

    long nameCursor = 0;
    long parameterCursor = 0;
    long target = 0;
    while (target < dependencyCount) limit CALLABLE_COUNT_LIMIT {
      long product = nextProduct(dependencyCount, dependencyRows, selected, callableIdentities);
      if (product < 0) {
        valid = false;
        target = dependencyCount;
      } else {
        long callable = dependencyRows[4096 + product];
        long nameStart = callableNameStarts[callable];
        long nameLength = callableNameLengths[callable];
        long firstParameter = callableFirstParameters[callable];
        long parameterCount = callableParameterCounts[callable];
        if (NAME_BYTES_LIMIT - nameCursor < nameLength) {
          valid = false;
        }

        if (PARAMETER_COUNT_LIMIT - parameterCursor < parameterCount) {
          valid = false;
        }

        if (valid) {
          set(selected, product, 1);
          set(stagedTargets, target, callable);
          set(stagedTargets, 4096 + target, dependencyRows[product]);
          set(stagedTargets, 8192 + target, nameCursor);
          set(stagedTargets, 12288 + target, nameLength);
          set(stagedTargets, 16384 + target, parameterCursor);
          set(stagedTargets, 20480 + target, parameterCount);
          set(stagedTargets, 24576 + target, callableResultTypes[callable]);
          set(stagedTargets, 28672 + target, callableEffects[callable]);
          long nameByte = 0;
          while (nameByte < nameLength) limit 256 {
            setByte(stagedNames, nameCursor, callableNames[nameStart + nameByte]);
            nameCursor += 1;
            nameByte += 1;
          }

          long identityByte = 0;
          while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
            setByte(
              stagedIdentities,
              target * IDENTITY_BYTES + identityByte,
              callableIdentities[callable * IDENTITY_BYTES + identityByte]
            );
            identityByte += 1;
          }

          long parameter = 0;
          while (parameter < parameterCount) limit 64 {
            long mode = parameterModes[firstParameter + parameter];
            long type = localParameterType(parameterTypes[firstParameter + parameter], mode);
            if (type < 0) {
              valid = false;
            }

            set(stagedParameters, parameterCursor, type);
            set(stagedParameters, 16384 + parameterCursor, mode);
            parameterCursor += 1;
            parameter += 1;
          }
        }

        target += 1;
      }
    }

    if (valid) {
      long row = 0;
      while (row < TARGET_ROWS) limit TARGET_ROWS {
        set(targetRows, row, stagedTargets[row]);
        row += 1;
      }

      row = 0;
      while (row < 32768) limit 32768 {
        set(targetParameterRows, row, stagedParameters[row]);
        row += 1;
      }

      long publishedNameByte = 0;
      while (publishedNameByte < nameCursor) limit NAME_BYTES_LIMIT {
        setByte(targetNames, publishedNameByte, stagedNames[publishedNameByte]);
        publishedNameByte += 1;
      }

      long publishedIdentityByte = 0;
      while (publishedIdentityByte < dependencyCount * IDENTITY_BYTES) limit 131072 {
        setByte(
          targetIdentities,
          publishedIdentityByte,
          stagedIdentities[publishedIdentityByte]
        );
        publishedIdentityByte += 1;
      }
    }

    drop(stagedIdentities);
    drop(stagedNames);
    drop(selected);
    drop(stagedParameters);
    drop(stagedTargets);
    drop(staging);
    return new ImportedSourceCallTargetPlan(dependencyCount, parameterCursor, nameCursor, valid);
  }
}
