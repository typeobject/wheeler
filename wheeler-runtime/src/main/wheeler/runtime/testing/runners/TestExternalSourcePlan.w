//! Composes one locked archive entry into one canonical package-qualified source plan.

module wheeler.runtime.testing.runners.test_external_source_plan;

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
    writeAscii(qualifiedPath, /* offset= */ 0, "dependencies/");
    long qualifiedCursor = copyRange(
      packageName,
      /* inputStart= */ 0,
      bufferLength(packageName),
      qualifiedPath,
      PREFIX_BYTES
    );
    setByte(qualifiedPath, qualifiedCursor, /* value= */ 47);
    qualifiedCursor += 1;
    qualifiedCursor = copyRange(
      archive,
      selected.pathStart,
      selected.pathLength,
      qualifiedPath,
      qualifiedCursor
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
}
