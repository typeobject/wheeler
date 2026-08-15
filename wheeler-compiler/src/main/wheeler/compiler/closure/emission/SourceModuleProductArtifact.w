//! Emits one classical source module from composed callable products.

module wheeler.compiler.closure.source_module_product_artifact;

import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;
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

  private long stubCodeLength(long resultType) {
    if (resultType == 0) {
      return 8;
    }

    if (resultType == TYPE_SIGNED) {
      return 40;
    }

    assert(resultType == TYPE_BOOLEAN);
    return 96;
  }

  private long writeStubCode(
    borrow mut bytes output,
    long cursor,
    long parameterCount,
    long resultType
  ) {
    if (resultType == 0) {
      return writeInstructionHeader(output, cursor, OPCODE_RETURN, INSTRUCTION_FORM_NULLARY);
    }

    if (resultType == TYPE_SIGNED) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_CONST,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, parameterCount, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_RETURN_VALUE,
        INSTRUCTION_FORM_UNARY
      );
      return writeUnsignedLittleEndian(output, cursor, parameterCount, 8);
    }

    assert(resultType == TYPE_BOOLEAN);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, parameterCount, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, parameterCount + 1, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, /* width= */ 8);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_EQ, INSTRUCTION_FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, parameterCount + 2, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, parameterCount, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, parameterCount + 1, 8);
    cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, INSTRUCTION_FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, parameterCount + 2, 8);
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

  /// Builds one local-only canonical artifact.
  public SourceProductArtifactPlan publishClassicalSourceModuleArtifact(
    long callableCount,
    borrow mut words callableRows,
    borrow mut words parameterCounts,
    borrow mut words functionResultTypes,
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
    region emptyStubs = new region(/* bytes= */ 229376, /* allocations= */ 4);
    words stubParameterStarts = allocate(emptyStubs, /* length= */ 4096);
    words stubParameterCounts = allocate(emptyStubs, /* length= */ 4096);
    words stubParameterTypes = allocate(emptyStubs, /* length= */ 16384);
    words stubResultTypes = allocate(emptyStubs, /* length= */ 4096);
    SourceProductArtifactPlan result = publishClassicalSourceModuleArtifactWithStubs(
      callableCount,
      /* reversibleCallableCount= */ 0,
      /* stubCount= */ 0,
      stubParameterStarts,
      stubParameterCounts,
      stubParameterTypes,
      stubResultTypes,
      callableRows,
      parameterCounts,
      functionResultTypes,
      functionNameIds,
      localTypeCount,
      localTypes,
      code,
      codeLength,
      strings,
      stringBytes,
      stringCount,
      stringStarts,
      stringLengths,
      output,
      identity
    );
    drop(stubResultTypes);
    drop(stubParameterTypes);
    drop(stubParameterCounts);
    drop(stubParameterStarts);
    drop(emptyStubs);
    return result;
  }

  /// Builds canonical sections with verifier-only imported signature stubs.
  public SourceProductArtifactPlan publishClassicalSourceModuleArtifactWithStubs(
    long callableCount,
    long reversibleCallableCount,
    long stubCount,
    borrow mut words stubParameterStarts,
    borrow mut words stubParameterCounts,
    borrow mut words stubParameterTypes,
    borrow mut words stubResultTypes,
    borrow mut words callableRows,
    borrow mut words parameterCounts,
    borrow mut words functionResultTypes,
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
    assert(-1 < reversibleCallableCount);
    if (0 < reversibleCallableCount) {
      assert(reversibleCallableCount == callableCount);
    }

    assert(-1 < stubCount);
    assert(stubCount < MAX_CALLABLES - callableCount + 1);
    assert(bufferLength(stubParameterStarts) == 4096);
    assert(bufferLength(stubParameterCounts) == 4096);
    assert(bufferLength(stubParameterTypes) == 16384);
    assert(bufferLength(stubResultTypes) == 4096);
    assert(bufferLength(callableRows) == CALLABLE_ROWS);
    assert(bufferLength(parameterCounts) == MAX_CALLABLES);
    assert(bufferLength(functionResultTypes) == MAX_CALLABLES);
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
    writeUnsigned(sectionArchive, cursor + 4, 4, callableCount + stubCount);
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
    long functionCount = callableCount + stubCount + 1;
    writeUnsigned(sectionArchive, cursor, 4, functionCount);
    long descriptorStart = cursor + 4;
    long functionTypeStart = descriptorStart + functionCount * 40;
    long codeOffset = 0;
    long typeOffset = 0;
    long resultTypeCount = 0;
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
      assert(functionLocalTypeStart == typeOffset - resultTypeCount);
      assert(functionNameIds[function] < stringCount);
      long resultType = functionResultTypes[function];
      boolean resultTypeValid = resultType == 0;
      if (resultType == TYPE_SIGNED) {
        resultTypeValid = true;
      }

      if (resultType == TYPE_BOOLEAN) {
        resultTypeValid = true;
      }

      assert(resultTypeValid);
      writeUnsigned(sectionArchive, descriptor, 4, function);
      writeUnsigned(sectionArchive, descriptor + 4, 4, functionNameIds[function]);
      long functionFlags = 0;
      if (0 < resultType) {
        functionFlags = 4;
        if (0 < reversibleCallableCount) {
          functionFlags += 8;
        }
      }

      writeUnsigned(sectionArchive, descriptor + 8, 4, functionFlags);
      writeUnsigned(sectionArchive, descriptor + 12, 4, codeOffset);
      writeUnsigned(sectionArchive, descriptor + 16, 4, functionCodeLength);
      writeUnsigned(sectionArchive, descriptor + 20, 4, 4294967295);
      writeUnsigned(sectionArchive, descriptor + 24, 4, 0);
      writeUnsigned(sectionArchive, descriptor + 28, 4, parameterCounts[function]);
      writeUnsigned(sectionArchive, descriptor + 32, 4, functionLocalCount);
      writeUnsigned(sectionArchive, descriptor + 36, 4, typeOffset);
      if (0 < resultType) {
        writeUnsigned(sectionArchive, functionTypeStart + typeOffset * 4, 4, resultType);
        typeOffset += 1;
        resultTypeCount += 1;
      }

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
    long stubParameterTypeCount = 0;
    long stub = 0;
    while (stub < stubCount) limit MAX_CALLABLES {
      long stubDescriptor = descriptorStart + (callableCount + stub) * 40;
      long stubTarget = callableCount + stub;
      long stubFirstParameter = stubParameterStarts[stubTarget];
      long stubParameterCount = stubParameterCounts[stubTarget];
      long stubResultType = stubResultTypes[stubTarget];
      assert(-1 < stubFirstParameter);
      assert(-1 < stubParameterCount);
      assert(stubParameterCount < 8);
      assert(stubFirstParameter < 16384 - stubParameterCount + 1);
      boolean stubResultTypeValid = stubResultType == 0;
      if (stubResultType == TYPE_SIGNED) {
        stubResultTypeValid = true;
      }

      if (stubResultType == TYPE_BOOLEAN) {
        stubResultTypeValid = true;
      }

      assert(stubResultTypeValid);
      writeUnsigned(sectionArchive, stubDescriptor, 4, callableCount + stub);
      writeUnsigned(sectionArchive, stubDescriptor + 4, 4, 0);
      long stubFlags = 0;
      if (0 < stubResultType) {
        stubFlags = 4;
      }

      writeUnsigned(sectionArchive, stubDescriptor + 8, 4, stubFlags);
      long stubLength = stubCodeLength(stubResultType);
      writeUnsigned(sectionArchive, stubDescriptor + 12, 4, codeOffset);
      writeUnsigned(sectionArchive, stubDescriptor + 16, 4, stubLength);
      writeUnsigned(sectionArchive, stubDescriptor + 20, 4, 4294967295);
      writeUnsigned(sectionArchive, stubDescriptor + 24, 4, 0);
      writeUnsigned(sectionArchive, stubDescriptor + 28, 4, stubParameterCount);
      long stubGeneratedLocals = 0;
      if (stubResultType == TYPE_SIGNED) {
        stubGeneratedLocals = 1;
      }

      if (stubResultType == TYPE_BOOLEAN) {
        stubGeneratedLocals = 3;
      }

      writeUnsigned(
        sectionArchive,
        stubDescriptor + 32,
        4,
        stubParameterCount + stubGeneratedLocals
      );
      writeUnsigned(sectionArchive, stubDescriptor + 36, 4, typeOffset);
      if (0 < stubResultType) {
        writeUnsigned(sectionArchive, functionTypeStart + typeOffset * 4, 4, stubResultType);
        typeOffset += 1;
        resultTypeCount += 1;
      }

      long stubParameter = 0;
      while (stubParameter < stubParameterCount) limit 7 {
        writeUnsigned(
          sectionArchive,
          functionTypeStart + typeOffset * 4,
          4,
          stubParameterTypes[stubFirstParameter + stubParameter]
        );
        typeOffset += 1;
        stubParameterTypeCount += 1;
        stubParameter += 1;
      }

      long generatedStubLocal = 0;
      while (generatedStubLocal < stubGeneratedLocals) limit 3 {
        long generatedStubType = TYPE_SIGNED;
        if (generatedStubLocal == 2) {
          generatedStubType = TYPE_BOOLEAN;
        }

        writeUnsigned(sectionArchive, functionTypeStart + typeOffset * 4, 4, generatedStubType);
        typeOffset += 1;
        stubParameterTypeCount += 1;
        generatedStubLocal += 1;
      }

      codeOffset += stubLength;
      stub += 1;
    }

    assert(typeOffset == localTypeCount + resultTypeCount + stubParameterTypeCount);
    long libraryDescriptor = descriptorStart + (callableCount + stubCount) * 40;
    writeUnsigned(sectionArchive, libraryDescriptor, 4, callableCount + stubCount);
    writeUnsigned(sectionArchive, libraryDescriptor + 4, 4, 0);
    writeUnsigned(sectionArchive, libraryDescriptor + 8, 4, 0);
    writeUnsigned(sectionArchive, libraryDescriptor + 12, 4, codeOffset);
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

    long emittedCodeCursor = codeLength;
    long emittedStub = 0;
    while (emittedStub < stubCount) limit MAX_CALLABLES {
      long emittedTarget = callableCount + emittedStub;
      long emittedStubEnd = writeStubCode(
        sectionArchive,
        cursor + emittedCodeCursor,
        stubParameterCounts[emittedTarget],
        stubResultTypes[emittedTarget]
      );
      emittedCodeCursor = emittedStubEnd - cursor;
      emittedStub += 1;
    }

    assert(emittedCodeCursor == codeOffset);

    setByte(sectionArchive, cursor + codeOffset, 1);
    setByte(sectionArchive, cursor + codeOffset + 1, 0);
    setByte(sectionArchive, cursor + codeOffset + 2, 0);
    setByte(sectionArchive, cursor + codeOffset + 3, 0);
    setByte(sectionArchive, cursor + codeOffset + 4, 8);
    setByte(sectionArchive, cursor + codeOffset + 5, 0);
    setByte(sectionArchive, cursor + codeOffset + 6, 0);
    setByte(sectionArchive, cursor + codeOffset + 7, 0);
    set(sectionLengths, 5, codeOffset + 8);
    cursor += codeOffset + 8;

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
