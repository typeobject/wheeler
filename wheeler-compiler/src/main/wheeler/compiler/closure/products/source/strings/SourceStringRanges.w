//! Compares already validated source artifact string windows in unsigned byte order.

module wheeler.compiler.closure.source_string_ranges;

classical class SourceStringRanges {
  /// Bounds a complete string byte window by source artifact storage.
  public const long MAX_SOURCE_STRING_BYTES = 32768;

  /// Compares complete windows from independent borrowed views without copying them.
  /// Callers validate both extents before comparison. No allocation or mutation occurs.
  public long compareSourceStringRanges(
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
    while (offset < shared) limit MAX_SOURCE_STRING_BYTES {
      long leftByte = left[leftStart + offset];
      long rightByte = right[rightStart + offset];
      if (leftByte < rightByte) {
        return -1;
      }

      if (rightByte < leftByte) {
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
}
