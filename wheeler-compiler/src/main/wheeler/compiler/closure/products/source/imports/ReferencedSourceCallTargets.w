//! Retains only imported targets referenced by resolved source calls.

module wheeler.compiler.closure.referenced_source_call_targets;

classical class ReferencedSourceCallTargets {
  private const long CALL_COUNT_LIMIT = 256;
  private const long CALL_ROWS = 1024;
  private const long IDENTITY_BYTES = 32;
  private const long PARAMETER_COUNT_LIMIT = 16384;
  private const long TARGET_COUNT_LIMIT = 4096;

  /// Reports the remapped dense target and parameter extents.
  public record ReferencedSourceCallTargetPlan(
    long targetCount,
    long importedCount,
    long parameterCount,
    boolean valid
  ) {}

  private boolean referencedTarget(long target, long callCount, borrow mut words sourceCalls) {
    long call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      if (sourceCalls[768 + call] == target) {
        return true;
      }

      call += 1;
    }

    return false;
  }

  /// Remaps calls and copies local plus referenced imported signature products atomically.
  public ReferencedSourceCallTargetPlan materializeReferencedSourceCallTargets(
    long localCount,
    long importedCount,
    long callCount,
    borrow mut words sourceCalls,
    borrow mut words sourceParameterStarts,
    borrow mut words sourceParameterCounts,
    borrow mut words sourceParameterTypes,
    borrow mut words sourceResultTypes,
    borrow mut words sourceEffects,
    borrow byteview sourceIdentities,
    borrow mut words targetCalls,
    borrow mut words targetParameterStarts,
    borrow mut words targetParameterCounts,
    borrow mut words targetParameterTypes,
    borrow mut words targetResultTypes,
    borrow mut words targetEffects,
    borrow mut bytes targetIdentities
  ) {
    assert(-1 < localCount);
    assert(localCount < 65);
    assert(-1 < importedCount);
    assert(importedCount < TARGET_COUNT_LIMIT - localCount + 1);
    assert(-1 < callCount);
    assert(callCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(sourceCalls) == CALL_ROWS);
    assert(bufferLength(sourceParameterStarts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(sourceParameterCounts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(sourceParameterTypes) == PARAMETER_COUNT_LIMIT);
    assert(bufferLength(sourceResultTypes) == TARGET_COUNT_LIMIT);
    assert(bufferLength(sourceEffects) == TARGET_COUNT_LIMIT);
    assert(bufferLength(sourceIdentities) == 131072);
    assert(bufferLength(targetCalls) == CALL_ROWS);
    assert(bufferLength(targetParameterStarts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(targetParameterCounts) == TARGET_COUNT_LIMIT);
    assert(bufferLength(targetParameterTypes) == PARAMETER_COUNT_LIMIT);
    assert(bufferLength(targetResultTypes) == TARGET_COUNT_LIMIT);
    assert(bufferLength(targetEffects) == TARGET_COUNT_LIMIT);
    assert(bufferLength(targetIdentities) == 131072);

    region staging = new region(/* bytes= */ 434176, /* allocations= */ 8);
    words stagedCalls = allocate(staging, CALL_ROWS);
    words stagedParameterStarts = allocate(staging, TARGET_COUNT_LIMIT);
    words stagedParameterCounts = allocate(staging, TARGET_COUNT_LIMIT);
    words stagedParameterTypes = allocate(staging, PARAMETER_COUNT_LIMIT);
    words stagedResultTypes = allocate(staging, TARGET_COUNT_LIMIT);
    words stagedEffects = allocate(staging, TARGET_COUNT_LIMIT);
    bytes stagedIdentities = allocateBytes(staging, /* length= */ 131072);
    words remap = allocate(staging, TARGET_COUNT_LIMIT);
    boolean valid = true;
    long parameterCursor = 0;
    long retainedImported = 0;
    long sourceTarget = 0;
    while (sourceTarget < localCount + importedCount) limit TARGET_COUNT_LIMIT {
      boolean retain = sourceTarget < localCount;
      if (localCount < sourceTarget + 1) {
        retain = referencedTarget(sourceTarget, callCount, sourceCalls);
      }

      if (retain) {
        long target = sourceTarget;
        if (localCount < sourceTarget + 1) {
          target = localCount + retainedImported;
          retainedImported += 1;
        }

        set(remap, sourceTarget, target + 1);
        long firstParameter = sourceParameterStarts[sourceTarget];
        long parameterCount = sourceParameterCounts[sourceTarget];
        if (firstParameter < 0) {
          valid = false;
        }

        if (parameterCount < 0) {
          valid = false;
        }

        if (64 < parameterCount) {
          valid = false;
        }

        if (PARAMETER_COUNT_LIMIT - parameterCount < firstParameter) {
          valid = false;
        }

        if (PARAMETER_COUNT_LIMIT - parameterCursor < parameterCount) {
          valid = false;
        }

        if (valid) {
          set(stagedParameterStarts, target, parameterCursor);
          set(stagedParameterCounts, target, parameterCount);
          set(stagedResultTypes, target, sourceResultTypes[sourceTarget]);
          set(stagedEffects, target, sourceEffects[sourceTarget]);
          long parameter = 0;
          while (parameter < parameterCount) limit 64 {
            set(
              stagedParameterTypes,
              parameterCursor,
              sourceParameterTypes[firstParameter + parameter]
            );
            parameterCursor += 1;
            parameter += 1;
          }

          long identityByte = 0;
          while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
            setByte(
              stagedIdentities,
              target * IDENTITY_BYTES + identityByte,
              sourceIdentities[sourceTarget * IDENTITY_BYTES + identityByte]
            );
            identityByte += 1;
          }
        }
      }

      sourceTarget += 1;
    }

    long call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      long callSourceTarget = sourceCalls[768 + call];
      if (callSourceTarget < 0) {
        valid = false;
      } else {
        if (localCount + importedCount - 1 < callSourceTarget) {
          valid = false;
        } else {
          long mapped = remap[callSourceTarget] - 1;
          if (mapped < 0) {
            valid = false;
          } else {
            set(stagedCalls, call, sourceCalls[call]);
            set(stagedCalls, 256 + call, sourceCalls[256 + call]);
            set(stagedCalls, 512 + call, sourceCalls[512 + call]);
            set(stagedCalls, 768 + call, mapped);
          }
        }
      }

      call += 1;
    }

    if (valid) {
      long column = 0;
      while (column < 4) limit 4 {
        long callRow = 0;
        while (callRow < callCount) limit CALL_COUNT_LIMIT {
          set(
            targetCalls,
            column * CALL_COUNT_LIMIT + callRow,
            stagedCalls[column * CALL_COUNT_LIMIT + callRow]
          );
          callRow += 1;
        }

        column += 1;
      }

      long retainedTargetCount = localCount + retainedImported;
      long row = 0;
      while (row < retainedTargetCount) limit TARGET_COUNT_LIMIT {
        set(targetParameterStarts, row, stagedParameterStarts[row]);
        set(targetParameterCounts, row, stagedParameterCounts[row]);
        set(targetResultTypes, row, stagedResultTypes[row]);
        set(targetEffects, row, stagedEffects[row]);
        row += 1;
      }

      row = 0;
      while (row < parameterCursor) limit PARAMETER_COUNT_LIMIT {
        set(targetParameterTypes, row, stagedParameterTypes[row]);
        row += 1;
      }

      long publishedIdentityByte = 0;
      while (publishedIdentityByte < (localCount + retainedImported)
        * IDENTITY_BYTES) limit 131072 {
        setByte(
          targetIdentities,
          publishedIdentityByte,
          stagedIdentities[publishedIdentityByte]
        );
        publishedIdentityByte += 1;
      }
    }

    drop(remap);
    drop(stagedIdentities);
    drop(stagedEffects);
    drop(stagedResultTypes);
    drop(stagedParameterTypes);
    drop(stagedParameterCounts);
    drop(stagedParameterStarts);
    drop(stagedCalls);
    drop(staging);
    return new ReferencedSourceCallTargetPlan(
      localCount + retainedImported,
      retainedImported,
      parameterCursor,
      valid
    );
  }
}
