//! Assembles validated canonical sections into one aligned bytecode container.

module wheeler.compiler.closure.linked_container;

import wheeler.core.encoding.binary;

classical class LinkedContainer {
  private const long DIRECTORY_ROWS = 64;
  private const long MAX_ARTIFACT_BYTES = 16777216;
  private const long MAX_SECTIONS = 10;

  private void writeUnsigned(borrow mut bytes output, long cursor, long width, long value) {
    assert(-1 < value);
    long remaining = value;
    long outputByte = 0;
    while (outputByte < width) limit 8 {
      setByte(output, cursor + outputByte, remaining % 256);
      remaining = remaining / 256;
      outputByte += 1;
    }

    assert(remaining == 0);
  }

  private long align8(long value) {
    assert(-1 < value);
    assert(value < MAX_ARTIFACT_BYTES + 1);
    long remainder = value % 8;
    if (remainder == 0) {
      return value;
    }

    return value + 8 - remainder;
  }

  private boolean allowedSectionType(long type) {
    if (0 < type) {
      if (type < 9) {
        return true;
      }
    }

    if (type == 10) {
      return true;
    }

    return type == 13;
  }

  private void validateSectionInputs(
    borrow byteview sections,
    long sectionBytes,
    long sectionCount,
    borrow mut words sectionTypes,
    borrow mut words sectionStarts,
    borrow mut words sectionLengths
  ) {
    assert(-1 < sectionBytes);
    assert(sectionBytes < bufferLength(sections) + 1);
    assert(5 < sectionCount);
    assert(sectionCount < MAX_SECTIONS + 1);
    assert(bufferLength(sectionTypes) == DIRECTORY_ROWS);
    assert(bufferLength(sectionStarts) == DIRECTORY_ROWS);
    assert(bufferLength(sectionLengths) == DIRECTORY_ROWS);
    long previousType = 0;
    long section = 0;
    while (section < sectionCount) limit MAX_SECTIONS {
      long type = sectionTypes[section];
      long start = sectionStarts[section];
      long length = sectionLengths[section];
      assert(previousType < type);
      assert(allowedSectionType(type));
      if (section < 6) {
        assert(type == section + 1);
      }

      assert(-1 < start);
      assert(-1 < length);
      assert(start < sectionBytes + 1);
      assert(length < sectionBytes - start + 1);
      if (type == 1) {
        assert(length == 24);
      }

      if (type == 2) {
        assert(3 < length);
      }

      if (type == 3) {
        assert(15 < length);
      }

      if (type == 4) {
        assert(3 < length);
      }

      if (type == 5) {
        assert(3 < length);
      }

      previousType = type;
      section += 1;
    }
  }

  /// Verifies canonical header, directory, alignment, and zero padding.
  public void verifyCanonicalContainer(
    borrow byteview artifact,
    long artifactLength,
    long expectedSectionCount,
    borrow mut words expectedTypes,
    borrow mut words expectedLengths
  ) {
    assert(39 < artifactLength);
    assert(artifactLength < bufferLength(artifact) + 1);
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
    assert(readUnsigned(artifact, 12, 4) == 0);
    assert(readUnsigned(artifact, 16, 8) == artifactLength);
    assert(readUnsigned(artifact, 24, 4) == expectedSectionCount);
    assert(readUnsigned(artifact, 28, 4) == 32);
    assert(readUnsigned(artifact, 32, 8) == 40);
    assert(bufferLength(expectedTypes) == DIRECTORY_ROWS);
    assert(bufferLength(expectedLengths) == DIRECTORY_ROWS);
    long previousEnd = 40 + expectedSectionCount * 32;
    long section = 0;
    while (section < expectedSectionCount) limit MAX_SECTIONS {
      long directory = 40 + section * 32;
      long type = readUnsigned(artifact, directory, 4);
      long start = readUnsigned(artifact, directory + 8, 8);
      long length = readUnsigned(artifact, directory + 16, 8);
      assert(type == expectedTypes[section]);
      assert(readUnsigned(artifact, directory + 4, 4) == 1);
      assert(length == expectedLengths[section]);
      assert(readUnsigned(artifact, directory + 24, 4) == 8);
      assert(readUnsigned(artifact, directory + 28, 4) == 0);
      assert(start == align8(previousEnd));
      assert(start < artifactLength + 1);
      assert(length < artifactLength - start + 1);
      long padding = previousEnd;
      while (padding < start) limit 7 {
        assert(artifact[padding] == 0);
        padding += 1;
      }

      previousEnd = start + length;
      section += 1;
    }

    long finalLength = align8(previousEnd);
    assert(finalLength == artifactLength);
    long finalPadding = previousEnd;
    while (finalPadding < finalLength) limit 7 {
      assert(artifact[finalPadding] == 0);
      finalPadding += 1;
    }
  }

  /// Copies all sections only after validating every source range and final extent.
  public long emitCanonicalContainer(
    borrow byteview sections,
    long sectionBytes,
    long sectionCount,
    borrow mut words sectionTypes,
    borrow mut words sectionStarts,
    borrow mut words sectionLengths,
    borrow mut bytes output
  ) {
    validateSectionInputs(
      sections,
      sectionBytes,
      sectionCount,
      sectionTypes,
      sectionStarts,
      sectionLengths
    );
    long cursor = align8(40 + sectionCount * 32);
    long section = 0;
    while (section < sectionCount) limit MAX_SECTIONS {
      cursor = align8(cursor);
      assert(sectionLengths[section] < MAX_ARTIFACT_BYTES - cursor + 1);
      cursor += sectionLengths[section];
      section += 1;
    }

    long artifactLength = align8(cursor);
    assert(artifactLength < MAX_ARTIFACT_BYTES + 1);
    assert(artifactLength < bufferLength(output) + 1);

    long outputByte = 0;
    while (outputByte < artifactLength) limit MAX_ARTIFACT_BYTES {
      setByte(output, outputByte, 0);
      outputByte += 1;
    }

    setByte(output, 0, 87);
    setByte(output, 1, 72);
    setByte(output, 2, 69);
    setByte(output, 3, 69);
    setByte(output, 4, 76);
    setByte(output, 5, 66);
    setByte(output, 6, 67);
    setByte(output, 7, 0);
    writeUnsigned(output, 8, 2, 1);
    writeUnsigned(output, 10, 2, 0);
    writeUnsigned(output, 12, 4, 0);
    writeUnsigned(output, 16, 8, artifactLength);
    writeUnsigned(output, 24, 4, sectionCount);
    writeUnsigned(output, 28, 4, 32);
    writeUnsigned(output, 32, 8, 40);

    cursor = align8(40 + sectionCount * 32);
    section = 0;
    while (section < sectionCount) limit MAX_SECTIONS {
      cursor = align8(cursor);
      long directory = 40 + section * 32;
      writeUnsigned(output, directory, 4, sectionTypes[section]);
      writeUnsigned(output, directory + 4, 4, 1);
      writeUnsigned(output, directory + 8, 8, cursor);
      writeUnsigned(output, directory + 16, 8, sectionLengths[section]);
      writeUnsigned(output, directory + 24, 4, 8);
      writeUnsigned(output, directory + 28, 4, 0);
      long sectionByte = 0;
      while (sectionByte < sectionLengths[section]) limit MAX_ARTIFACT_BYTES {
        setByte(output, cursor + sectionByte, sections[sectionStarts[section] + sectionByte]);
        sectionByte += 1;
      }

      cursor += sectionLengths[section];
      section += 1;
    }

    verifyCanonicalContainer(
      output,
      artifactLength,
      sectionCount,
      sectionTypes,
      sectionLengths
    );
    return artifactLength;
  }
}
