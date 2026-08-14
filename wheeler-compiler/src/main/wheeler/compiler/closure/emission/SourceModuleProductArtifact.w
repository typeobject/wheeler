//! Emits one classical source module from composed callable products.

module wheeler.compiler.closure.source_module_product_artifact;

import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.type_codes;

classical class SourceModuleProductArtifact {
  private const long ARTIFACT_BYTES = 32768;
  private const long CALLABLE_ROWS = 320;
  private const long MAX_CALLABLES = 64;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_STRINGS = 256;
  private const long TYPE_ROWS = 12288;

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

  private long writeStringSection(
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < stringBytes);
    assert(stringBytes < bufferLength(strings) + 1);
    assert(0 < stringCount);
    assert(stringCount < MAX_STRINGS + 1);
    assert(bufferLength(stringStarts) == MAX_STRINGS);
    assert(bufferLength(stringLengths) == MAX_STRINGS);
    long cursor = outputStart;
    writeUnsigned(output, cursor, 4, stringCount);
    cursor += 4;
    long string = 0;
    while (string < stringCount) limit MAX_STRINGS {
      long start = stringStarts[string];
      long length = stringLengths[string];
      assert(-1 < start);
      assert(-1 < length);
      assert(start < stringBytes + 1);
      assert(length < stringBytes - start + 1);
      writeUnsigned(output, cursor, 4, length);
      cursor += 4;
      long stringByte = 0;
      while (stringByte < length) limit ARTIFACT_BYTES {
        setByte(output, cursor, strings[start + stringByte]);
        cursor += 1;
        stringByte += 1;
      }

      string += 1;
    }

    return cursor - outputStart;
  }

  /// Builds canonical sections, verifies the container, hashes it, and publishes atomically.
  public SourceProductArtifactPlan publishClassicalSourceModuleArtifact(
    long callableCount,
    borrow mut words callableRows,
    borrow mut words parameterCounts,
    borrow mut words functionNameIds,
    long localTypeCount,
    borrow mut words localTypes,
    borrow byteview code,
    long codeLength,
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut bytes output,
    borrow mut bytes identity
  ) {
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(callableRows) == CALLABLE_ROWS);
    assert(bufferLength(parameterCounts) == MAX_CALLABLES);
    assert(bufferLength(functionNameIds) == MAX_CALLABLES);
    assert(-1 < localTypeCount);
    assert(localTypeCount < 4097);
    assert(bufferLength(localTypes) == TYPE_ROWS);
    assert(-1 < codeLength);
    assert(codeLength < MAX_CODE_BYTES);
    assert(codeLength < bufferLength(code) + 1);
    assert(bufferLength(output) == ARTIFACT_BYTES);
    assert(bufferLength(identity) == 32);

    region sections = new region(/* bytes= */ 33792, /* allocations= */ 3);
    bytes sectionArchive = allocateBytes(sections, ARTIFACT_BYTES);
    words sectionStarts = allocate(sections, /* length= */ 64);
    words sectionLengths = allocate(sections, /* length= */ 64);
    long cursor = 0;

    set(sectionStarts, 0, cursor);
    writeUnsigned(sectionArchive, cursor, 4, 1);
    writeUnsigned(sectionArchive, cursor + 4, 4, callableCount);
    writeUnsigned(sectionArchive, cursor + 8, 8, 4000000);
    writeUnsigned(sectionArchive, cursor + 16, 8, 4000000);
    set(sectionLengths, 0, 24);
    cursor += 24;

    set(sectionStarts, 1, cursor);
    long stringSectionLength = writeStringSection(
      strings,
      stringBytes,
      stringCount,
      stringStarts,
      stringLengths,
      sectionArchive,
      cursor
    );
    set(sectionLengths, 1, stringSectionLength);
    cursor += stringSectionLength;

    set(sectionStarts, 2, cursor);
    long zeroByte = 0;
    while (zeroByte < 16) limit 16 {
      setByte(sectionArchive, cursor + zeroByte, 0);
      zeroByte += 1;
    }

    set(sectionLengths, 2, 16);
    cursor += 16;

    set(sectionStarts, 3, cursor);
    writeUnsigned(sectionArchive, cursor, 4, 0);
    set(sectionLengths, 3, 4);
    cursor += 4;

    set(sectionStarts, 4, cursor);
    long functionCount = callableCount + 1;
    writeUnsigned(sectionArchive, cursor, 4, functionCount);
    long descriptorStart = cursor + 4;
    long functionTypeStart = descriptorStart + functionCount * 40;
    long codeOffset = 0;
    long typeOffset = 0;
    long function = 0;
    while (function < callableCount) limit MAX_CALLABLES {
      long descriptor = descriptorStart + function * 40;
      long functionCodeStart = callableRows[function];
      long functionCodeLength = callableRows[64 + function];
      long functionLocalCount = callableRows[256 + function];
      long functionLocalTypeStart = callableRows[192 + function];
      assert(functionCodeStart == codeOffset);
      assert(0 < functionCodeLength);
      assert(functionCodeLength < codeLength - codeOffset + 1);
      assert(parameterCounts[function] < functionLocalCount + 1);
      assert(functionLocalTypeStart == typeOffset - function);
      assert(functionNameIds[function] < stringCount);
      writeUnsigned(sectionArchive, descriptor, 4, function);
      writeUnsigned(sectionArchive, descriptor + 4, 4, functionNameIds[function]);
      writeUnsigned(sectionArchive, descriptor + 8, 4, 4);
      writeUnsigned(sectionArchive, descriptor + 12, 4, codeOffset);
      writeUnsigned(sectionArchive, descriptor + 16, 4, functionCodeLength);
      writeUnsigned(sectionArchive, descriptor + 20, 4, 4294967295);
      writeUnsigned(sectionArchive, descriptor + 24, 4, 0);
      writeUnsigned(sectionArchive, descriptor + 28, 4, parameterCounts[function]);
      writeUnsigned(sectionArchive, descriptor + 32, 4, functionLocalCount);
      writeUnsigned(sectionArchive, descriptor + 36, 4, typeOffset);
      writeUnsigned(sectionArchive, functionTypeStart + typeOffset * 4, 4, TYPE_SIGNED);
      typeOffset += 1;
      long local = 0;
      while (local < functionLocalCount) limit 256 {
        long type = functionLocalTypeStart + local;
        assert(type < localTypeCount);
        assert(localTypes[type] == function);
        assert(localTypes[4096 + type] == local);
        writeUnsigned(
          sectionArchive,
          functionTypeStart + typeOffset * 4,
          4,
          localTypes[8192 + type]
        );
        typeOffset += 1;
        local += 1;
      }

      codeOffset += functionCodeLength;
      function += 1;
    }

    assert(codeOffset == codeLength);
    assert(typeOffset == localTypeCount + callableCount);
    long libraryDescriptor = descriptorStart + callableCount * 40;
    writeUnsigned(sectionArchive, libraryDescriptor, 4, callableCount);
    writeUnsigned(sectionArchive, libraryDescriptor + 4, 4, 0);
    writeUnsigned(sectionArchive, libraryDescriptor + 8, 4, 0);
    writeUnsigned(sectionArchive, libraryDescriptor + 12, 4, codeLength);
    writeUnsigned(sectionArchive, libraryDescriptor + 16, 4, 8);
    writeUnsigned(sectionArchive, libraryDescriptor + 20, 4, 4294967295);
    writeUnsigned(sectionArchive, libraryDescriptor + 24, 4, 0);
    writeUnsigned(sectionArchive, libraryDescriptor + 28, 4, 0);
    writeUnsigned(sectionArchive, libraryDescriptor + 32, 4, 0);
    writeUnsigned(sectionArchive, libraryDescriptor + 36, 4, typeOffset);
    long functionSectionLength = 4 + functionCount * 40 + typeOffset * 4;
    set(sectionLengths, 4, functionSectionLength);
    cursor += functionSectionLength;

    set(sectionStarts, 5, cursor);
    long codeByte = 0;
    while (codeByte < codeLength) limit MAX_CODE_BYTES {
      setByte(sectionArchive, cursor + codeByte, code[codeByte]);
      codeByte += 1;
    }

    setByte(sectionArchive, cursor + codeLength, 1);
    setByte(sectionArchive, cursor + codeLength + 1, 0);
    setByte(sectionArchive, cursor + codeLength + 2, 0);
    setByte(sectionArchive, cursor + codeLength + 3, 0);
    setByte(sectionArchive, cursor + codeLength + 4, 8);
    setByte(sectionArchive, cursor + codeLength + 5, 0);
    setByte(sectionArchive, cursor + codeLength + 6, 0);
    setByte(sectionArchive, cursor + codeLength + 7, 0);
    set(sectionLengths, 5, codeLength + 8);
    cursor += codeLength + 8;

    SourceProductArtifactPlan result = publishSourceProductArtifact(
      sectionArchive,
      cursor,
      /* sectionCount= */ 6,
      sectionStarts,
      sectionLengths,
      output,
      identity
    );
    drop(sectionLengths);
    drop(sectionStarts);
    drop(sectionArchive);
    drop(sections);
    return result;
  }
}
