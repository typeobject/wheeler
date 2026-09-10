//! Publishes classical artifacts with optional generated inverses and bound proof products.

module wheeler.compiler.closure.classical_source_product_artifact;

import wheeler.compiler.closure.classical_proof_products;
import wheeler.compiler.closure.source_classical_proofs;
import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.closure.source_proof_strings;
import wheeler.compiler.verifier;
import wheeler.core.encoding.binary;

classical class ClassicalSourceProductArtifact {
  private const long ARTIFACT_BYTES = 32768;
  private const long CALLABLE_CODE_LENGTH_ROW = 64;
  private const long CALLABLE_CODE_START_ROW = 0;
  private const long CALLABLE_ROWS = 320;
  private const long INVERSE_CODE_LENGTH_ROW = 64;
  private const long INVERSE_ROWS = 192;
  private const long MAX_CALLABLES = 64;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_PROOFS = MAX_SOURCE_PROOFS;
  private const long MAX_SECTIONS = 7;
  private const long MAX_STRINGS = MAX_SOURCE_PROOF_STRINGS;
  private const long DIRECTORY_ROWS = 64;
  private const long STRING_COLUMNS = 3;
  private const long NATIVE_WORD_BYTES = 8;
  private const long STAGING_WORDS = DIRECTORY_ROWS * 2 + MAX_STRINGS * STRING_COLUMNS
    + SOURCE_PROOF_STRING_ROWS;
  private const long STAGING_BYTES = ARTIFACT_BYTES + STAGING_WORDS * NATIVE_WORD_BYTES;
  private const long STAGING_ALLOCATIONS = 1 + 2 + STRING_COLUMNS + 1;
  private const long BYTE_RADIX = 256;
  private const long WORD_RADIX = BYTE_RADIX * BYTE_RADIX * BYTE_RADIX * BYTE_RADIX;
  private const long WORD_MAX = WORD_RADIX - 1;

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

  private long remappedStringId(long oldId, long oldStringCount, borrow mut words oldIds) {
    assert(-1 < oldId);
    assert(oldId < oldStringCount);
    return oldIds[oldId];
  }

  private void remapTypeStrings(
    borrow mut bytes sectionArchive,
    long start,
    long length,
    long oldStringCount,
    borrow mut words oldIds
  ) {
    long cursor = start;
    long globalCount = readUnsigned(sectionArchive, cursor, 4);
    cursor += 4;
    long global = 0;
    while (global < globalCount) limit 4096 {
      long globalNameId = readUnsigned(sectionArchive, cursor, 4);
      writeUnsigned(
        remappedStringId(globalNameId, oldStringCount, oldIds),
        4,
        sectionArchive,
        cursor
      );
      cursor += 16;
      global += 1;
    }

    long recordCount = readUnsigned(sectionArchive, cursor, 4);
    cursor += 4;
    long record = 0;
    while (record < recordCount) limit 4096 {
      long recordNameId = readUnsigned(sectionArchive, cursor + 4, 4);
      writeUnsigned(
        remappedStringId(recordNameId, oldStringCount, oldIds),
        4,
        sectionArchive,
        cursor + 4
      );
      long fieldCount = readUnsigned(sectionArchive, cursor + 8, 4);
      cursor += 12;
      long field = 0;
      while (field < fieldCount) limit 4096 {
        long fieldNameId = readUnsigned(sectionArchive, cursor, 4);
        writeUnsigned(
          remappedStringId(fieldNameId, oldStringCount, oldIds),
          4,
          sectionArchive,
          cursor
        );
        cursor += 8;
        field += 1;
      }

      record += 1;
    }

    long arrayCount = readUnsigned(sectionArchive, cursor, 4);
    cursor += 4 + arrayCount * 12;
    long sliceCount = readUnsigned(sectionArchive, cursor, 4);
    cursor += 4 + sliceCount * 8;
    assert(cursor == start + length);
  }

  private void remapVariantStrings(
    borrow mut bytes sectionArchive,
    long start,
    long length,
    long oldStringCount,
    borrow mut words oldIds
  ) {
    long cursor = start;
    long variantCount = readUnsigned(sectionArchive, cursor, 4);
    cursor += 4;
    long variant = 0;
    while (variant < variantCount) limit 4096 {
      long nameId = readUnsigned(sectionArchive, cursor + 4, 4);
      writeUnsigned(
        remappedStringId(nameId, oldStringCount, oldIds),
        4,
        sectionArchive,
        cursor + 4
      );
      long caseCount = readUnsigned(sectionArchive, cursor + 8, 4);
      cursor += 12;
      long variantCase = 0;
      while (variantCase < caseCount) limit 4096 {
        long caseNameId = readUnsigned(sectionArchive, cursor, 4);
        writeUnsigned(
          remappedStringId(caseNameId, oldStringCount, oldIds),
          4,
          sectionArchive,
          cursor
        );
        long fieldCount = readUnsigned(sectionArchive, cursor + 4, 4);
        cursor += 8;
        long field = 0;
        while (field < fieldCount) limit 4096 {
          long fieldNameId = readUnsigned(sectionArchive, cursor, 4);
          writeUnsigned(
            remappedStringId(fieldNameId, oldStringCount, oldIds),
            4,
            sectionArchive,
            cursor
          );
          cursor += 8;
          field += 1;
        }

        variantCase += 1;
      }

      variant += 1;
    }

    assert(cursor == start + length);
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

  /// Rebuilds canonical sections with retained claims and optional generated inverse windows.
  /// Caller artifacts, claim rows, code, and output storage remain unchanged on rejection.
  public SourceProductArtifactPlan publishClassicalSourceProductArtifact(
    borrow byteview forwardArtifact,
    long forwardArtifactLength,
    long callableCount,
    long reversibleCallableCount,
    borrow mut words callableRows,
    borrow mut words inverseRows,
    borrow byteview inverseCode,
    borrow byteview proofNames,
    long proofCount,
    borrow mut words proofs,
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
    assert(-1 < reversibleCallableCount);
    if (0 < reversibleCallableCount) {
      assert(reversibleCallableCount == callableCount);
      assert(bufferLength(callableRows) == CALLABLE_ROWS);
      assert(bufferLength(inverseRows) == INVERSE_ROWS);
      assert(bufferLength(inverseCode) == MAX_CODE_BYTES);
    }

    assert(-1 < proofCount);
    assert(proofCount < MAX_PROOFS + 1);
    assert(bufferLength(proofs) == SOURCE_PROOF_ROWS);
    assert(bufferLength(output) == ARTIFACT_BYTES);
    assert(bufferLength(identity) == 32);
    long sectionCount = readUnsigned(forwardArtifact, 24, 4);
    assert(sectionCount == 6);
    assert(verifyArtifact(forwardArtifact, forwardArtifactLength) == 1);

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

    region staging = new region(
      /* bytes= */ STAGING_BYTES,
      /* allocations= */ STAGING_ALLOCATIONS
    );
    bytes sectionArchive = allocateBytes(staging, ARTIFACT_BYTES);
    words sectionStarts = allocate(staging, /* length= */ 64);
    words sectionLengths = allocate(staging, /* length= */ 64);
    words oldStringStarts = allocate(staging, /* length= */ MAX_STRINGS);
    words oldStringLengths = allocate(staging, /* length= */ MAX_STRINGS);
    words oldStringIds = allocate(staging, /* length= */ MAX_STRINGS);
    words proofNameIds = allocate(staging, /* length= */ SOURCE_PROOF_STRING_ROWS);
    long forwardStringCount = readUnsigned(forwardArtifact, strings.start, 4);
    long mergedStringCount = indexSourceProofStrings(
      forwardArtifact,
      strings.start,
      strings.length,
      proofNames,
      proofCount,
      proofs,
      oldStringStarts,
      oldStringLengths,
      oldStringIds,
      proofNameIds
    );
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
      long selectedLength = selected.length;
      if (section == 1) {
        selectedLength = writeSourceProofStrings(
          forwardArtifact,
          forwardStringCount,
          oldStringStarts,
          oldStringLengths,
          oldStringIds,
          proofNames,
          proofCount,
          proofs,
          proofNameIds,
          mergedStringCount,
          sectionArchive,
          cursor
        );
      } else {
        copyBytes(forwardArtifact, selected.start, selected.length, sectionArchive, cursor);
        if (section == 0) {
          long programNameId = readUnsigned(sectionArchive, cursor, 4);
          writeUnsigned(
            remappedStringId(programNameId, forwardStringCount, oldStringIds),
            4,
            sectionArchive,
            cursor
          );
        }

        if (section == 2) {
          remapTypeStrings(
            sectionArchive,
            cursor,
            selected.length,
            forwardStringCount,
            oldStringIds
          );
        }

        if (section == 3) {
          remapVariantStrings(
            sectionArchive,
            cursor,
            selected.length,
            forwardStringCount,
            oldStringIds
          );
        }
      }

      set(sectionLengths, section, selectedLength);
      cursor += selectedLength;
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
      long functionNameId = readUnsigned(forwardArtifact, descriptor + 4, 4);
      writeUnsigned(
        remappedStringId(functionNameId, forwardStringCount, oldStringIds),
        4,
        sectionArchive,
        outputDescriptor + 4
      );
      long flags = readUnsigned(forwardArtifact, descriptor + 8, 4);
      long forwardOffset = readUnsigned(forwardArtifact, descriptor + 12, 4);
      long forwardLength = readUnsigned(forwardArtifact, descriptor + 16, 4);
      long forwardInverseOffset = readUnsigned(forwardArtifact, descriptor + 20, 4);
      long inverseLength = readUnsigned(forwardArtifact, descriptor + 24, 4);
      assert(functionId == function);
      writeUnsigned(codeCursor, 4, sectionArchive, outputDescriptor + 12);
      copyBytes(
        forwardArtifact,
        code.start + forwardOffset,
        forwardLength,
        sectionArchive,
        codeOutputStart + codeCursor
      );
      codeCursor += forwardLength;
      if (function < reversibleCallableCount) {
        assert(inverseLength == 0);
        boolean flagsValid = flags == 0;
        if (flags == 12) {
          flagsValid = true;
        }

        assert(flagsValid);
        assert(forwardOffset == callableRows[CALLABLE_CODE_START_ROW + function]);
        assert(forwardLength == callableRows[CALLABLE_CODE_LENGTH_ROW + function]);
        assert(inverseRows[function] == inverseCursor);
        long generatedLength = inverseRows[INVERSE_CODE_LENGTH_ROW + function];
        assert(generatedLength == forwardLength);
        writeUnsigned(flags + 1, 4, sectionArchive, outputDescriptor + 8);
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
        boolean reversibleStub = (flags & 1) == 1;
        if (reversibleStub) {
          assert(inverseLength == forwardLength);
          assert(forwardInverseOffset == forwardOffset + forwardLength);
          writeUnsigned(codeCursor, 4, sectionArchive, outputDescriptor + 20);
          copyBytes(
            forwardArtifact,
            code.start + forwardInverseOffset,
            inverseLength,
            sectionArchive,
            codeOutputStart + codeCursor
          );
          codeCursor += inverseLength;
        } else {
          assert(inverseLength == 0);
          writeUnsigned(4294967295, 4, sectionArchive, outputDescriptor + 20);
        }
      }

      function += 1;
    }

    assert(codeCursor < ARTIFACT_BYTES - codeOutputStart + 1);
    set(sectionLengths, 5, codeCursor);
    cursor += codeCursor;
    long outputSectionCount = 6;
    if (0 < proofCount) {
      assert(sectionCount == 6);
      set(sectionStarts, 6, cursor);
      long proofSectionLength = PROOF_WORD_BYTES + proofCount * CLASSICAL_PROOF_DESCRIPTOR_BYTES;
      set(sectionLengths, 6, proofSectionLength);
      writeUnsigned(proofCount, 4, sectionArchive, cursor);
      long proofRowIndex = 0;
      while (proofRowIndex < proofCount) limit MAX_PROOFS {
        long proofRow = cursor + PROOF_WORD_BYTES + proofRowIndex
          * CLASSICAL_PROOF_DESCRIPTOR_BYTES;
        long subject = proofs[SOURCE_PROOF_SUBJECT_ROW + proofRowIndex];
        long rule = proofs[SOURCE_PROOF_RULE_ROW + proofRowIndex];
        long argument = proofs[SOURCE_PROOF_ARGUMENT_ROW + proofRowIndex];
        long low = argument % WORD_RADIX;
        long high = argument / WORD_RADIX;
        if (argument == -1) {
          low = WORD_MAX;
          high = WORD_MAX;
        }

        assert(-1 < subject);
        assert(subject < callableCount);
        assert(classicalProofArgumentValid(rule, low, high));
        writeUnsigned(proofRowIndex, PROOF_WORD_BYTES, sectionArchive, proofRow);
        writeUnsigned(
          proofNameIds[proofRowIndex],
          PROOF_WORD_BYTES,
          sectionArchive,
          proofRow + PROOF_WORD_BYTES
        );
        writeUnsigned(rule, PROOF_WORD_BYTES, sectionArchive, proofRow + PROOF_WORD_BYTES * 2);
        writeUnsigned(
          subject,
          PROOF_WORD_BYTES,
          sectionArchive,
          proofRow + PROOF_WORD_BYTES * 3
        );
        writeUnsigned(low, PROOF_WORD_BYTES, sectionArchive, proofRow + PROOF_WORD_BYTES * 4);
        writeUnsigned(high, PROOF_WORD_BYTES, sectionArchive, proofRow + PROOF_WORD_BYTES * 5);

        proofRowIndex += 1;
      }

      cursor += proofSectionLength;
      outputSectionCount = 7;
    } else {
      assert(sectionCount == 6);
    }

    SourceProductArtifactPlan result = publishSourceProductArtifact(
      sectionArchive,
      cursor,
      outputSectionCount,
      sectionStarts,
      sectionLengths,
      output,
      identity
    );
    drop(proofNameIds);
    drop(oldStringIds);
    drop(oldStringLengths);
    drop(oldStringStarts);
    drop(sectionLengths);
    drop(sectionStarts);
    drop(sectionArchive);
    drop(staging);
    return result;
  }
}
