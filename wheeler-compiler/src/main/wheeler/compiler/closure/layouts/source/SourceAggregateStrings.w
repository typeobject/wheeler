//! Copies aggregate source names into immutable counted string-product storage.

module wheeler.compiler.closure.source_aggregate_strings;

classical class SourceAggregateStrings {
  private const long MAX_ARCHIVE_BYTES = 16777216;
  private const long MAX_CLOSURE_STRINGS = 16384;
  private const long MAX_LOCAL_STRINGS = 512;
  private const long MAX_NAME_BYTES = 256;

  /// Reports the immutable archive and counted string extents after one append.
  public record SourceAggregateStringPlan(long archiveBytes, long stringCount) {}

  /// Validates every source range before copying names and publishing string rows.
  public SourceAggregateStringPlan appendSourceAggregateStrings(
    borrow utf8 source,
    long artifactRank,
    long localStringCount,
    borrow mut words localStringStarts,
    borrow mut words localStringLengths,
    long archiveBytes,
    long closureStringCount,
    borrow mut bytes archive,
    borrow mut words artifactRanks,
    borrow mut words stringStarts,
    borrow mut words stringLengths
  ) {
    assert(-1 < artifactRank);
    assert(artifactRank < 512);
    assert(-1 < localStringCount);
    assert(localStringCount < MAX_LOCAL_STRINGS + 1);
    assert(bufferLength(localStringStarts) == MAX_LOCAL_STRINGS);
    assert(bufferLength(localStringLengths) == MAX_LOCAL_STRINGS);
    assert(-1 < archiveBytes);
    assert(archiveBytes < bufferLength(archive) + 1);
    assert(bufferLength(archive) < MAX_ARCHIVE_BYTES + 1);
    assert(-1 < closureStringCount);
    assert(closureStringCount < MAX_CLOSURE_STRINGS + 1);
    assert(localStringCount < MAX_CLOSURE_STRINGS - closureStringCount + 1);
    assert(bufferLength(artifactRanks) == MAX_CLOSURE_STRINGS);
    assert(bufferLength(stringStarts) == MAX_CLOSURE_STRINGS);
    assert(bufferLength(stringLengths) == MAX_CLOSURE_STRINGS);

    long appendBytes = 0;
    long localString = 0;
    while (localString < localStringCount) limit MAX_LOCAL_STRINGS {
      long start = localStringStarts[localString];
      long length = localStringLengths[localString];
      assert(-1 < start);
      assert(0 < length);
      assert(length < MAX_NAME_BYTES + 1);
      assert(start < bufferLength(source));
      assert(length < bufferLength(source) - start + 1);
      assert(length < bufferLength(archive) - archiveBytes - appendBytes + 1);
      long nameByte = 0;
      while (nameByte < length) limit MAX_NAME_BYTES {
        long value = utf8Scalar(source, start + nameByte);
        assert(31 < value);
        assert(value < 127);
        nameByte += 1;
      }

      appendBytes += length;
      localString += 1;
    }

    long copiedBytes = 0;
    localString = 0;
    while (localString < localStringCount) limit MAX_LOCAL_STRINGS {
      long selectedStart = localStringStarts[localString];
      long selectedLength = localStringLengths[localString];
      long selectedByte = 0;
      while (selectedByte < selectedLength) limit MAX_NAME_BYTES {
        setByte(
          archive,
          archiveBytes + copiedBytes + selectedByte,
          utf8Scalar(source, selectedStart + selectedByte)
        );
        selectedByte += 1;
      }

      long closureString = closureStringCount + localString;
      set(artifactRanks, closureString, artifactRank);
      set(stringStarts, closureString, archiveBytes + copiedBytes);
      set(stringLengths, closureString, selectedLength);
      copiedBytes += selectedLength;
      localString += 1;
    }

    assert(copiedBytes == appendBytes);
    return new SourceAggregateStringPlan(
      archiveBytes + appendBytes,
      closureStringCount + localStringCount
    );
  }
}
