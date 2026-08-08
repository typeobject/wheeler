//! Emits canonical function descriptors and final local-type rows.

module wheeler.compiler.closure.linked_function_section;

classical class LinkedFunctionSection {
  private const long CLOSURE_FUNCTION_ROWS = 49152;
  private const long FUNCTION_SECTION_BYTES = 4358152;
  private const long MAX_CLOSURE_FUNCTIONS = 4096;
  private const long MAX_CLOSURE_LOCAL_TYPES = 1048576;
  private const long MAX_LINKED_CODE_BYTES = 4194304;

  private void writeUnsigned(long value, long width, borrow mut bytes output, long cursor) {
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

  /// Emits a complete function section at a caller-selected section offset.
  public long emitLinkedFunctionSectionAt(
    long functionCount,
    borrow mut words closureFunctionRows,
    long stringCount,
    borrow mut words functionNameIds,
    long linkedTypeCount,
    borrow mut words linkedTypes,
    long linkedCodeBytes,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < outputStart);
    assert(0 < functionCount);
    assert(functionCount < MAX_CLOSURE_FUNCTIONS + 1);
    assert(bufferLength(closureFunctionRows) == CLOSURE_FUNCTION_ROWS);
    assert(0 < stringCount);
    assert(bufferLength(functionNameIds) == MAX_CLOSURE_FUNCTIONS);
    assert(-1 < linkedTypeCount);
    assert(linkedTypeCount < MAX_CLOSURE_LOCAL_TYPES + 1);
    assert(bufferLength(linkedTypes) == MAX_CLOSURE_LOCAL_TYPES);
    assert(-1 < linkedCodeBytes);
    assert(linkedCodeBytes < MAX_LINKED_CODE_BYTES + 1);
    assert(outputStart < bufferLength(output) + 1);

    long expectedTypes = 0;
    long expectedCode = 0;
    long function = 0;
    while (function < functionCount) limit MAX_CLOSURE_FUNCTIONS {
      long nameId = functionNameIds[function];
      long flags = closureFunctionRows[8192 + function];
      long forwardLength = closureFunctionRows[20480 + function];
      long inverseLength = closureFunctionRows[28672 + function];
      long parameterCount = closureFunctionRows[32768 + function];
      long localCount = closureFunctionRows[36864 + function];
      long typeCount = closureFunctionRows[45056 + function];
      assert(-1 < nameId);
      assert(nameId < stringCount);
      assert(-1 < flags);
      assert(flags < 16);
      assert(-1 < forwardLength);
      assert(-1 < inverseLength);
      assert(-1 < parameterCount);
      assert(parameterCount < localCount + 1);
      assert(-1 < localCount);
      assert(localCount < 257);
      assert(typeCount == localCount + flags / 4 % 2);
      assert(typeCount < MAX_CLOSURE_LOCAL_TYPES - expectedTypes + 1);
      assert(forwardLength < MAX_LINKED_CODE_BYTES - expectedCode + 1);
      expectedTypes += typeCount;
      expectedCode += forwardLength;
      if (0 < inverseLength) {
        assert(inverseLength < MAX_LINKED_CODE_BYTES - expectedCode + 1);
        expectedCode += inverseLength;
      }

      function += 1;
    }

    assert(expectedTypes == linkedTypeCount);
    assert(expectedCode == linkedCodeBytes);
    long sectionBytes = 4 + functionCount * 40 + linkedTypeCount * 4;
    assert(sectionBytes < bufferLength(output) - outputStart + 1);

    writeUnsigned(functionCount, 4, output, outputStart);
    long codeOffset = 0;
    long typeOffset = 0;
    function = 0;
    while (function < functionCount) limit MAX_CLOSURE_FUNCTIONS {
      long descriptor = outputStart + 4 + function * 40;
      long selectedFlags = closureFunctionRows[8192 + function];
      long selectedForwardLength = closureFunctionRows[20480 + function];
      long selectedInverseLength = closureFunctionRows[28672 + function];
      writeUnsigned(function, 4, output, descriptor);
      writeUnsigned(functionNameIds[function], 4, output, descriptor + 4);
      writeUnsigned(selectedFlags, 4, output, descriptor + 8);
      writeUnsigned(codeOffset, 4, output, descriptor + 12);
      writeUnsigned(selectedForwardLength, 4, output, descriptor + 16);
      codeOffset += selectedForwardLength;
      if (0 < selectedInverseLength) {
        writeUnsigned(codeOffset, 4, output, descriptor + 20);
        writeUnsigned(selectedInverseLength, 4, output, descriptor + 24);
        codeOffset += selectedInverseLength;
      } else {
        writeUnsigned(4294967295, 4, output, descriptor + 20);
        writeUnsigned(0, 4, output, descriptor + 24);
      }

      writeUnsigned(closureFunctionRows[32768 + function], 4, output, descriptor + 28);
      writeUnsigned(closureFunctionRows[36864 + function], 4, output, descriptor + 32);
      writeUnsigned(typeOffset, 4, output, descriptor + 36);
      typeOffset += closureFunctionRows[45056 + function];
      function += 1;
    }

    long type = 0;
    long typeStart = outputStart + 4 + functionCount * 40;
    while (type < linkedTypeCount) limit MAX_CLOSURE_LOCAL_TYPES {
      writeUnsigned(linkedTypes[type], 4, output, typeStart + type * 4);
      type += 1;
    }

    assert(codeOffset == linkedCodeBytes);
    assert(typeOffset == linkedTypeCount);
    return sectionBytes;
  }

  /// Emits into the historical fixed-width section buffer.
  public long emitLinkedFunctionSection(
    long functionCount,
    borrow mut words closureFunctionRows,
    long stringCount,
    borrow mut words functionNameIds,
    long linkedTypeCount,
    borrow mut words linkedTypes,
    long linkedCodeBytes,
    borrow mut bytes output
  ) {
    assert(bufferLength(output) == FUNCTION_SECTION_BYTES);
    return emitLinkedFunctionSectionAt(
      functionCount,
      closureFunctionRows,
      stringCount,
      functionNameIds,
      linkedTypeCount,
      linkedTypes,
      linkedCodeBytes,
      output,
      /* outputStart= */ 0
    );
  }
}
