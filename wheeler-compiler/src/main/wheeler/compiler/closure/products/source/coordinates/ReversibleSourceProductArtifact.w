//! Publishes reversible void artifacts from forward products and generated inverses.

module wheeler.compiler.closure.reversible_source_product_artifact;

import wheeler.compiler.closure.source_product_artifact;
import wheeler.core.encoding.binary;

classical class ReversibleSourceProductArtifact {
  private const long ARTIFACT_BYTES = 32768;
  private const long CALLABLE_CODE_LENGTH_ROW = 192;
  private const long CALLABLE_CODE_START_ROW = 128;
  private const long CALLABLE_ROWS = 320;
  private const long INVERSE_CODE_LENGTH_ROW = 64;
  private const long INVERSE_ROWS = 192;
  private const long MAX_CALLABLES = 64;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_SECTIONS = 7;

  private record SectionRange(long start, long length) {}

  private void writeUnsigned(long value, long width, borrow mut bytes output, long start) {
    assert(-1 < value);
    long remaining = value;
    long outputByte = 0;
    while (outputByte < width) limit 8 {
      setByte(output, start + outputByte, remaining % 256);
      remaining = remaining / 256;
      outputByte += 1;
    }

    assert(remaining == 0);
  }

  private void copyBytes(
    borrow byteview source,
    long sourceStart,
    long length,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < sourceStart);
    assert(-1 < outputStart);
    assert(-1 < length);
    assert(sourceStart < bufferLength(source) + 1);
    assert(length < bufferLength(source) - sourceStart + 1);
    assert(outputStart < bufferLength(output) + 1);
    assert(length < bufferLength(output) - outputStart + 1);
    long copied = 0;
    while (copied < length) limit MAX_CODE_BYTES {
      setByte(output, outputStart + copied, source[sourceStart + copied]);
      copied += 1;
    }
  }

  private SectionRange sectionRange(
    borrow byteview artifact,
    long artifactLength,
    long wantedType
  ) {
    long sectionCount = readUnsigned(artifact, 24, 4);
    long foundStart = -1;
    long foundLength = 0;
    long section = 0;
    while (section < sectionCount) limit MAX_SECTIONS {
      long directory = 40 + section * 32;
      long type = readUnsigned(artifact, directory, 4);
      if (type == wantedType) {
        assert(foundStart == -1);
        foundStart = readUnsigned(artifact, directory + 8, 8);
        foundLength = readUnsigned(artifact, directory + 16, 8);
      }

      section += 1;
    }

    assert(-1 < foundStart);
    assert(foundStart < artifactLength + 1);
    assert(foundLength < artifactLength - foundStart + 1);
    return new SectionRange(foundStart, foundLength);
  }

  /// Rebuilds canonical sections with generated inverse windows before publication.
  public SourceProductArtifactPlan publishReversibleVoidSourceProductArtifact(
    borrow byteview forwardArtifact,
    long forwardArtifactLength,
    long callableCount,
    borrow mut words callableRows,
    borrow mut words inverseRows,
    borrow byteview inverseCode,
    borrow mut bytes output,
    borrow mut bytes identity
  ) {
    assert(0 < forwardArtifactLength);
    assert(forwardArtifactLength < ARTIFACT_BYTES + 1);
    assert(forwardArtifactLength < bufferLength(forwardArtifact) + 1);
    assert(forwardArtifact[0] == 87);
    assert(forwardArtifact[1] == 72);
    assert(forwardArtifact[2] == 69);
    assert(forwardArtifact[3] == 69);
    assert(forwardArtifact[4] == 76);
    assert(forwardArtifact[5] == 66);
    assert(forwardArtifact[6] == 67);
    assert(forwardArtifact[7] == 0);
    assert(readUnsigned(forwardArtifact, 8, 2) == 1);
    assert(readUnsigned(forwardArtifact, 10, 2) == 0);
    assert(readUnsigned(forwardArtifact, 16, 8) == forwardArtifactLength);
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(callableRows) == CALLABLE_ROWS);
    assert(bufferLength(inverseRows) == INVERSE_ROWS);
    assert(bufferLength(inverseCode) == MAX_CODE_BYTES);
    assert(bufferLength(output) == ARTIFACT_BYTES);
    assert(bufferLength(identity) == 32);
    long sectionCount = readUnsigned(forwardArtifact, 24, 4);
    assert(5 < sectionCount);
    assert(sectionCount < MAX_SECTIONS + 1);

    SectionRange manifest = sectionRange(forwardArtifact, forwardArtifactLength, 1);
    SectionRange strings = sectionRange(forwardArtifact, forwardArtifactLength, 2);
    SectionRange types = sectionRange(forwardArtifact, forwardArtifactLength, 3);
    SectionRange variants = sectionRange(forwardArtifact, forwardArtifactLength, 4);
    SectionRange functions = sectionRange(forwardArtifact, forwardArtifactLength, 5);
    SectionRange code = sectionRange(forwardArtifact, forwardArtifactLength, 6);
    long functionCount = readUnsigned(forwardArtifact, functions.start, 4);
    assert(functionCount < 66);
    assert(callableCount < functionCount + 1);
    assert(3 < functions.length);
    assert(4 + functionCount * 40 < functions.length + 1);

    region staging = new region(/* bytes= */ 33792, /* allocations= */ 3);
    bytes sectionArchive = allocateBytes(staging, ARTIFACT_BYTES);
    words sectionStarts = allocate(staging, /* length= */ 64);
    words sectionLengths = allocate(staging, /* length= */ 64);
    SectionRange selected = manifest;
    long cursor = 0;
    long section = 0;
    while (section < 4) limit 4 {
      if (section == 1) {
        selected = strings;
      }

      if (section == 2) {
        selected = types;
      }

      if (section == 3) {
        selected = variants;
      }

      set(sectionStarts, section, cursor);
      set(sectionLengths, section, selected.length);
      copyBytes(forwardArtifact, selected.start, selected.length, sectionArchive, cursor);
      cursor += selected.length;
      section += 1;
    }

    set(sectionStarts, 4, cursor);
    set(sectionLengths, 4, functions.length);
    long functionOutputStart = cursor;
    writeUnsigned(functionCount, 4, sectionArchive, functionOutputStart);
    long typeBytesStart = functions.start + 4 + functionCount * 40;
    long typeBytesLength = functions.length - 4 - functionCount * 40;
    copyBytes(
      forwardArtifact,
      typeBytesStart,
      typeBytesLength,
      sectionArchive,
      functionOutputStart + 4 + functionCount * 40
    );
    cursor += functions.length;
    set(sectionStarts, 5, cursor);
    long codeOutputStart = cursor;
    long codeCursor = 0;
    long inverseCursor = 0;
    long function = 0;
    while (function < functionCount) limit 65 {
      long descriptor = functions.start + 4 + function * 40;
      long outputDescriptor = functionOutputStart + 4 + function * 40;
      copyBytes(forwardArtifact, descriptor, 40, sectionArchive, outputDescriptor);
      long functionId = readUnsigned(forwardArtifact, descriptor, 4);
      long flags = readUnsigned(forwardArtifact, descriptor + 8, 4);
      long forwardOffset = readUnsigned(forwardArtifact, descriptor + 12, 4);
      long forwardLength = readUnsigned(forwardArtifact, descriptor + 16, 4);
      long inverseLength = readUnsigned(forwardArtifact, descriptor + 24, 4);
      assert(functionId == function);
      assert(inverseLength == 0);
      writeUnsigned(codeCursor, 4, sectionArchive, outputDescriptor + 12);
      copyBytes(
        forwardArtifact,
        code.start + forwardOffset,
        forwardLength,
        sectionArchive,
        codeOutputStart + codeCursor
      );
      codeCursor += forwardLength;
      if (function < callableCount) {
        assert(flags == 0);
        assert(forwardOffset == callableRows[CALLABLE_CODE_START_ROW + function]);
        assert(forwardLength == callableRows[CALLABLE_CODE_LENGTH_ROW + function]);
        assert(inverseRows[function] == inverseCursor);
        long generatedLength = inverseRows[INVERSE_CODE_LENGTH_ROW + function];
        assert(generatedLength == forwardLength);
        writeUnsigned(1, 4, sectionArchive, outputDescriptor + 8);
        writeUnsigned(codeCursor, 4, sectionArchive, outputDescriptor + 20);
        writeUnsigned(generatedLength, 4, sectionArchive, outputDescriptor + 24);
        copyBytes(
          inverseCode,
          inverseCursor,
          generatedLength,
          sectionArchive,
          codeOutputStart + codeCursor
        );
        codeCursor += generatedLength;
        inverseCursor += generatedLength;
      } else {
        writeUnsigned(4294967295, 4, sectionArchive, outputDescriptor + 20);
      }

      function += 1;
    }

    assert(codeCursor < ARTIFACT_BYTES - codeOutputStart + 1);
    set(sectionLengths, 5, codeCursor);
    cursor += codeCursor;
    if (sectionCount == 7) {
      SectionRange proofs = sectionRange(forwardArtifact, forwardArtifactLength, 10);
      set(sectionStarts, 6, cursor);
      set(sectionLengths, 6, proofs.length);
      copyBytes(forwardArtifact, proofs.start, proofs.length, sectionArchive, cursor);
      cursor += proofs.length;
    }

    SourceProductArtifactPlan result = publishSourceProductArtifact(
      sectionArchive,
      cursor,
      sectionCount,
      sectionStarts,
      sectionLengths,
      output,
      identity
    );
    drop(sectionLengths);
    drop(sectionStarts);
    drop(sectionArchive);
    drop(staging);
    return result;
  }
}
