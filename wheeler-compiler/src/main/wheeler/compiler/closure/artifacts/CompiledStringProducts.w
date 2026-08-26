//! Decodes canonical source-local string ranges into one counted closure table.

module wheeler.compiler.closure.compiled_string_products;

import wheeler.core.encoding.binary;

classical class CompiledStringProducts {
  private const long MAX_SECTIONS = 64;
  private const long MAX_STRINGS = 16384;
  private const long STAGING_BYTES = 262144;

  private record StringSection(long start, long length) {}

  /// Reports one source-local string window and the complete closure count.
  public record CompiledStringPlan(long firstString, long stringCount, long closureStringCount) {}

  private StringSection stringSection(borrow byteview artifact, long artifactLength) {
    assert(39 < artifactLength);
    assert(artifact[0] == 87);
    assert(artifact[1] == 72);
    assert(artifact[2] == 69);
    assert(artifact[3] == 69);
    assert(artifact[4] == 76);
    assert(artifact[5] == 66);
    assert(artifact[6] == 67);
    assert(artifact[7] == 0);
    assert(readUnsigned(artifact, 8, 2) == 1);
    assert(readUnsigned(artifact, 10, 2) == 0);
    assert(readUnsigned(artifact, 16, 8) == artifactLength);
    long sectionCount = readUnsigned(artifact, 24, 4);
    assert(0 < sectionCount);
    assert(sectionCount < MAX_SECTIONS + 1);
    assert(readUnsigned(artifact, 28, 4) == 32);
    assert(readUnsigned(artifact, 32, 8) == 40);
    long previousType = 0;
    long previousEnd = 40 + sectionCount * 32;
    long selectedStart = -1;
    long selectedLength = 0;
    long section = 0;
    while (section < sectionCount) limit MAX_SECTIONS {
      long directory = 40 + section * 32;
      long type = readUnsigned(artifact, directory, 4);
      long flags = readUnsigned(artifact, directory + 4, 4);
      long start = readUnsigned(artifact, directory + 8, 8);
      long length = readUnsigned(artifact, directory + 16, 8);
      assert(previousType < type);
      assert(flags == 1);
      assert(readUnsigned(artifact, directory + 24, 4) == 8);
      assert(readUnsigned(artifact, directory + 28, 4) == 0);
      assert(start % 8 == 0);
      assert(previousEnd < start + 1);
      assert(start < artifactLength + 1);
      assert(length < artifactLength - start + 1);
      previousType = type;
      previousEnd = start + length;
      if (type == 2) {
        selectedStart = start;
        selectedLength = length;
      }

      section += 1;
    }

    assert(-1 < selectedStart);
    return new StringSection(selectedStart, selectedLength);
  }

  private long stubHexScalar(long digit) {
    assert(-1 < digit);
    assert(digit < 16);
    if (digit < 10) {
      return digit + 48;
    }

    return digit + 87;
  }

  private long compareRanges(
    borrow byteview artifact,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long shared = leftLength;
    if (rightLength < shared) {
      shared = rightLength;
    }

    long index = 0;
    while (index < shared) limit 4096 {
      if (artifact[leftStart + index] < artifact[rightStart + index]) {
        return -1;
      }

      if (artifact[rightStart + index] < artifact[leftStart + index]) {
        return 1;
      }

      index += 1;
    }

    if (leftLength < rightLength) {
      return -1;
    }

    if (rightLength < leftLength) {
      return 1;
    }

    return 0;
  }

  /// Appends canonical source strings after validating and removing verifier stubs.
  public CompiledStringPlan appendCompiledStringProducts(
    borrow byteview artifact,
    long artifactLength,
    long artifactBase,
    long artifactRank,
    long closureStringCount,
    borrow mut words stringArtifactRanks,
    borrow mut words stringStarts,
    borrow mut words stringLengths
  ) {
    assert(-1 < artifactBase);
    assert(-1 < artifactRank);
    assert(artifactRank < 512);
    assert(-1 < closureStringCount);
    assert(closureStringCount < MAX_STRINGS + 1);
    assert(bufferLength(stringArtifactRanks) == MAX_STRINGS);
    assert(bufferLength(stringStarts) == MAX_STRINGS);
    assert(bufferLength(stringLengths) == MAX_STRINGS);
    StringSection strings = stringSection(artifact, artifactLength);
    long sectionStart = strings.start;
    long stringCount = readUnsigned(artifact, sectionStart, 4);
    assert(0 < stringCount);
    assert(stringCount < MAX_STRINGS + 1);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 2);
    words stagedStarts = allocate(staging, MAX_STRINGS);
    words stagedLengths = allocate(staging, MAX_STRINGS);
    long cursor = sectionStart + 4;
    long previousStart = -1;
    long previousLength = 0;
    long retainedStringCount = 0;
    long stubCount = 0;
    boolean stubSuffix = false;
    long string = 0;
    while (string < stringCount) limit MAX_STRINGS {
      long length = readUnsigned(artifact, cursor, 4);
      cursor += 4;
      assert(0 < length);
      assert(cursor < artifactLength + 1);
      assert(length < artifactLength - cursor + 1);
      long stringByte = 0;
      while (stringByte < length) limit 4096 {
        long value = artifact[cursor + stringByte];
        assert(0 < value);
        assert(value < 128);
        stringByte += 1;
      }

      if (-1 < previousStart) {
        assert(compareRanges(artifact, previousStart, previousLength, cursor, length) < 0);
      }

      boolean verifierStub = artifact[cursor] == 126;
      if (verifierStub) {
        assert(length == 3);
        assert(stubCount < 64);
        assert(artifact[cursor + 1] == stubHexScalar(stubCount / 16));
        assert(artifact[cursor + 2] == stubHexScalar(stubCount % 16));
        stubSuffix = true;
        stubCount += 1;
      } else {
        assert(stubSuffix == false);
        set(stagedStarts, retainedStringCount, artifactBase + cursor);
        set(stagedLengths, retainedStringCount, length);
        retainedStringCount += 1;
      }

      previousStart = cursor;
      previousLength = length;
      cursor += length;
      string += 1;
    }

    assert(cursor == sectionStart + strings.length);
    assert(0 < retainedStringCount);
    assert(retainedStringCount < MAX_STRINGS - closureStringCount + 1);

    string = 0;
    while (string < retainedStringCount) limit MAX_STRINGS {
      long target = closureStringCount + string;
      set(stringArtifactRanks, target, artifactRank);
      set(stringStarts, target, stagedStarts[string]);
      set(stringLengths, target, stagedLengths[string]);
      string += 1;
    }

    drop(stagedLengths);
    drop(stagedStarts);
    drop(staging);
    return new CompiledStringPlan(
      closureStringCount,
      retainedStringCount,
      closureStringCount + retainedStringCount
    );
  }
}
