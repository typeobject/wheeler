//! Composes one locked archive entry into one canonical package-qualified source plan.

module wheeler.runtime.testing.runners.test_external_source_plan;

import wheeler.core.encoding.binary;
import wheeler.packages.archive_provenance;
import wheeler.runtime.testing.runners.test_source_plan;

classical class TestExternalSourcePlan {
  private const long MAX_PLAN_BYTES = 32768;
  private const long MAX_SOURCES = 64;
  private const long PREFIX_BYTES = 13;

  private long readUnsigned32BigEndian(borrow byteview input, long offset) {
    return input[offset] * 16777216 + input[offset + 1] * 65536 + input[offset + 2] * 256
      + input[offset + 3];
  }

  private void writeUnsigned32BigEndian(borrow mut bytes output, long offset, long value) {
    setByte(output, offset, value / 16777216);
    value = value % 16777216;
    setByte(output, offset + 1, value / 65536);
    value = value % 65536;
    setByte(output, offset + 2, value / 256);
    setByte(output, offset + 3, value % 256);
  }

  private long copyRange(
    borrow byteview input,
    long inputStart,
    long length,
    borrow mut bytes output,
    long outputStart
  ) {
    long offset = 0;
    while (offset < length) limit MAX_PLAN_BYTES {
      setByte(output, outputStart + offset, input[inputStart + offset]);
      offset += 1;
    }

    return outputStart + length;
  }

  private long compareRanges(
    borrow byteview left,
    long leftStart,
    long leftLength,
    borrow byteview right,
    long rightStart,
    long rightLength
  ) {
    long shared = leftLength;
    if (rightLength < shared) {
      shared = rightLength;
    }

    long offset = 0;
    while (offset < shared) limit 255 {
      if (left[leftStart + offset] < right[rightStart + offset]) {
        return -1;
      }

      if (right[rightStart + offset] < left[leftStart + offset]) {
        return 1;
      }

      offset += 1;
    }

    if (leftLength < rightLength) {
      return -1;
    }

    if (rightLength < leftLength) {
      return 1;
    }

    return 0;
  }

  private boolean dependencyPath(
    borrow byteview input,
    long start,
    long length
  ) {
    if (length < 14) {
      return false;
    }

    long hash = 0;
    long offset = 0;
    while (offset < PREFIX_BYTES) limit PREFIX_BYTES {
      hash = (hash * 131 + input[start + offset]) % 4294967296;
      offset += 1;
    }

    return hash == 344468646;
  }

  private boolean sameRange(
    borrow byteview left,
    long leftStart,
    borrow byteview right,
    long rightStart,
    long length
  ) {
    long offset = 0;
    while (offset < length) limit MAX_PLAN_BYTES {
      if (left[leftStart + offset] != right[rightStart + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private long writeQualifiedPath(
    borrow byteview packageName,
    borrow byteview archive,
    LockedArchiveEntry selected,
    borrow mut bytes qualifiedPath
  ) {
    writeAscii(qualifiedPath, /* offset= */ 0, "dependencies/");
    long cursor = copyRange(
      packageName,
      /* inputStart= */ 0,
      bufferLength(packageName),
      qualifiedPath,
      PREFIX_BYTES
    );
    setByte(qualifiedPath, cursor, /* value= */ 47);
    cursor += 1;
    return copyRange(
      archive,
      selected.pathStart,
      selected.pathLength,
      qualifiedPath,
      cursor
    );
  }

  private long copyExternalEntry(
    borrow byteview qualifiedPath,
    borrow byteview archive,
    LockedArchiveEntry selected,
    borrow mut bytes output,
    long outputStart
  ) {
    long cursor = outputStart;
    writeUnsigned32BigEndian(output, cursor, bufferLength(qualifiedPath));
    cursor += 4;
    cursor = copyRange(
      qualifiedPath,
      /* inputStart= */ 0,
      bufferLength(qualifiedPath),
      output,
      cursor
    );
    writeUnsigned32BigEndian(output, cursor, selected.sourceLength);
    cursor += 4;
    return copyRange(
      archive,
      selected.sourceStart,
      selected.sourceLength,
      output,
      cursor
    );
  }

  /// Reports whether a previously validated plan contains package-qualified external source.
  public boolean validatedPlanHasExternalSource(
    borrow byteview input,
    long start,
    long length
  ) {
    long sourceCount = readUnsigned32BigEndian(input, start);
    long cursor = start + 4;
    long source = 0;
    while (source < sourceCount) limit MAX_SOURCES {
      long pathLength = readUnsigned32BigEndian(input, cursor);
      long pathStart = cursor + 4;
      if (dependencyPath(input, pathStart, pathLength)) {
        return true;
      }

      cursor = pathStart + pathLength;
      long sourceLength = readUnsigned32BigEndian(input, cursor);
      cursor += 4 + sourceLength;
      source += 1;
    }

    assert(cursor == start + length);
    return false;
  }

  /// Writes one canonical source plan containing the local plan and one locked external entry.
  public long composeValidatedExternalSourcePlan(
    borrow byteview localPlan,
    borrow byteview lock,
    borrow byteview packageName,
    borrow byteview archive,
    long ordinal,
    borrow mut bytes digest,
    borrow mut bytes output,
    borrow mut region arena
  ) {
    assert(validTargetSourcePlan(localPlan, /* start= */ 0, bufferLength(localPlan)));
    long sourceCount = readUnsigned32BigEndian(localPlan, /* offset= */ 0);
    assert(sourceCount < MAX_SOURCES);
    LockedArchiveEntry selected = validatedLockedArchiveEntry(
      lock,
      packageName,
      archive,
      ordinal,
      digest,
      arena
    );
    long qualifiedLength = PREFIX_BYTES + bufferLength(packageName) + 1 + selected.pathLength;
    assert(qualifiedLength < 256);
    long required = bufferLength(localPlan) + qualifiedLength + selected.sourceLength + 8;
    assert(required < MAX_PLAN_BYTES + 1);
    assert(required < bufferLength(output) + 1);

    bytes qualifiedPath = allocateBytes(arena, qualifiedLength);
    long qualifiedCursor = writeQualifiedPath(
      packageName,
      archive,
      selected,
      qualifiedPath
    );
    assert(qualifiedCursor == qualifiedLength);

    writeUnsigned32BigEndian(output, /* offset= */ 0, sourceCount + 1);
    long inputCursor = 4;
    long outputCursor = 4;
    long source = 0;
    boolean externalWritten = false;
    while (source < sourceCount) limit MAX_SOURCES {
      long entryStart = inputCursor;
      long pathLength = readUnsigned32BigEndian(localPlan, inputCursor);
      long pathStart = inputCursor + 4;
      inputCursor = pathStart + pathLength;
      long sourceLength = readUnsigned32BigEndian(localPlan, inputCursor);
      inputCursor += 4 + sourceLength;
      long order = compareRanges(
        qualifiedPath,
        /* leftStart= */ 0,
        qualifiedLength,
        localPlan,
        pathStart,
        pathLength
      );
      assert(order != 0);
      if (externalWritten == false) {
        if (order < 0) {
          outputCursor = copyExternalEntry(
            qualifiedPath,
            archive,
            selected,
            output,
            outputCursor
          );
          externalWritten = true;
        }
      }

      outputCursor = copyRange(
        localPlan,
        entryStart,
        inputCursor - entryStart,
        output,
        outputCursor
      );
      source += 1;
    }

    if (externalWritten == false) {
      outputCursor = copyExternalEntry(
        qualifiedPath,
        archive,
        selected,
        output,
        outputCursor
      );
    }

    assert(inputCursor == bufferLength(localPlan));
    assert(outputCursor == required);
    assert(validTargetSourcePlan(output, /* start= */ 0, outputCursor));
    drop(qualifiedPath);
    return outputCursor;
  }

  /// Checks that one plan contains every source from one complete locked archive.
  public boolean validLockedExternalSourcePlan(
    borrow byteview plan,
    borrow byteview lock,
    borrow byteview packageName,
    borrow byteview archive,
    borrow mut bytes digest,
    borrow mut region arena
  ) {
    if (validTargetSourcePlan(plan, /* start= */ 0, bufferLength(plan)) == false) {
      return false;
    }

    if (bufferLength(archive) < 16) {
      return false;
    }

    long entryCount = readUnsigned(archive, /* offset= */ 12, /* width= */ 4);
    if (entryCount < 1) {
      return false;
    }

    if (2 < entryCount) {
      return false;
    }

    long sourceCount = readUnsigned32BigEndian(plan, /* offset= */ 0);
    long cursor = 4;
    long source = 0;
    long externalCount = 0;
    while (source < sourceCount) limit MAX_SOURCES {
      long pathLength = readUnsigned32BigEndian(plan, cursor);
      long pathStart = cursor + 4;
      if (dependencyPath(plan, pathStart, pathLength)) {
        externalCount += 1;
      }

      cursor = pathStart + pathLength;
      long sourceLength = readUnsigned32BigEndian(plan, cursor);
      cursor += 4 + sourceLength;
      source += 1;
    }

    if (cursor != bufferLength(plan)) {
      return false;
    }

    if (externalCount != entryCount) {
      return false;
    }

    long foundCount = 0;
    long ordinal = 0;
    while (ordinal < entryCount) limit 2 {
      LockedArchiveEntry selected = validatedLockedArchiveEntry(
        lock,
        packageName,
        archive,
        ordinal,
        digest,
        arena
      );
      long qualifiedLength = PREFIX_BYTES + bufferLength(packageName) + 1
        + selected.pathLength;
      if (255 < qualifiedLength) {
        return false;
      }

      bytes qualifiedPath = allocateBytes(arena, qualifiedLength);
      long qualifiedCursor = writeQualifiedPath(
        packageName,
        archive,
        selected,
        qualifiedPath
      );
      assert(qualifiedCursor == qualifiedLength);
      cursor = 4;
      source = 0;
      boolean found = false;
      while (source < sourceCount) limit MAX_SOURCES {
        long matchedPathLength = readUnsigned32BigEndian(plan, cursor);
        long matchedPathStart = cursor + 4;
        cursor = matchedPathStart + matchedPathLength;
        long matchedSourceLength = readUnsigned32BigEndian(plan, cursor);
        long matchedSourceStart = cursor + 4;
        if (matchedPathLength == qualifiedLength) {
          if (
            sameRange(
              plan,
              matchedPathStart,
              qualifiedPath,
              /* rightStart= */ 0,
              matchedPathLength
            )
          ) {
            if (matchedSourceLength == selected.sourceLength) {
              found = sameRange(
                plan,
                matchedSourceStart,
                archive,
                selected.sourceStart,
                matchedSourceLength
              );
            }
          }
        }

        cursor = matchedSourceStart + matchedSourceLength;
        source += 1;
      }

      drop(qualifiedPath);
      if (found) {
        foundCount += 1;
      }

      ordinal += 1;
    }

    return foundCount == entryCount;
  }
}
