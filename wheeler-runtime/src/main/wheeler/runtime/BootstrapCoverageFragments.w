//! Encodes bounded native bootstrap transitions for canonical coverage reduction.

module wheeler.runtime.bootstrap_coverage_fragments;

import wheeler.compiler.opcodes;

classical class BootstrapCoverageFragments {
  private const long MAX_TRANSITIONS = 128;
  private const long KEY_FIXED_BYTES = 21;
  private const long PREFIX_BYTES = 16;
  private const long SUFFIX_FIXED_BYTES = 62;

  private long opcodeNameLength(long opcode) {
    if (opcode == OPCODE_LOCAL_CONST) {
      return 11;
    }

    if (opcode == OPCODE_LOCAL_MOVE) {
      return 10;
    }

    if (opcode == OPCODE_LOCAL_EQ) {
      return 8;
    }

    if (opcode == OPCODE_LOCAL_ADD) {
      return 9;
    }

    if (opcode == OPCODE_LOCAL_SUB) {
      return 9;
    }

    if (opcode == OPCODE_LOCAL_MUL) {
      return 9;
    }

    if (opcode == OPCODE_LOCAL_DIV) {
      return 9;
    }

    if (opcode == OPCODE_LOCAL_MOD) {
      return 9;
    }

    if (opcode == OPCODE_LOCAL_XOR) {
      return 9;
    }

    if (opcode == OPCODE_LOCAL_AND) {
      return 9;
    }

    if (opcode == OPCODE_LOCAL_LT) {
      return 8;
    }

    if (opcode == OPCODE_CALL) {
      return 4;
    }

    if (opcode == OPCODE_CALL_VALUE) {
      return 10;
    }

    if (opcode == OPCODE_CALL_VOID) {
      return 9;
    }

    if (opcode == OPCODE_RETURN) {
      return 6;
    }

    if (opcode == OPCODE_RETURN_VALUE) {
      return 12;
    }

    if (opcode == OPCODE_JUMP_IF_ZERO) {
      return 12;
    }

    if (opcode == OPCODE_EXPECT_TRUE) {
      return 11;
    }

    if (opcode == OPCODE_HALT) {
      return 4;
    }

    assert(false);
    return 0;
  }

  private long decimalDigits(long value) {
    assert(-1 < value);
    long digits = 1;
    long remaining = value;
    while (9 < remaining) limit 20 {
      remaining = remaining / 10;
      digits += 1;
    }

    return digits;
  }

  private long writeUnsigned16(borrow mut bytes output, long cursor, long value) {
    assert(-1 < value);
    assert(value < 65536);
    setByte(output, cursor, value % 256);
    setByte(output, cursor + 1, value / 256);
    return cursor + 2;
  }

  private long writeUnsigned32BigEndian(borrow mut bytes output, long cursor, long value) {
    assert(-1 < value);
    assert(value < 4294967296);
    setByte(output, cursor, value / 16777216 % 256);
    setByte(output, cursor + 1, value / 65536 % 256);
    setByte(output, cursor + 2, value / 256 % 256);
    setByte(output, cursor + 3, value % 256);
    return cursor + 4;
  }

  private long writeDecimal(borrow mut bytes output, long cursor, long value) {
    long digits = decimalDigits(value);
    long divisor = 1;
    long position = 1;
    while (position < digits) limit 20 {
      divisor = divisor * 10;
      position += 1;
    }

    position = 0;
    while (position < digits) limit 20 {
      setByte(output, cursor, value / divisor % 10 + 48);
      divisor = divisor / 10;
      cursor += 1;
      position += 1;
    }

    return cursor;
  }

  private long writeOpcodeName(borrow mut bytes output, long cursor, long opcode) {
    if (opcode == OPCODE_LOCAL_CONST) {
      writeAscii(output, cursor, "LOCAL_CONST");
      return cursor + 11;
    }

    if (opcode == OPCODE_LOCAL_MOVE) {
      writeAscii(output, cursor, "LOCAL_MOVE");
      return cursor + 10;
    }

    if (opcode == OPCODE_LOCAL_EQ) {
      writeAscii(output, cursor, "LOCAL_EQ");
      return cursor + 8;
    }

    if (opcode == OPCODE_LOCAL_ADD) {
      writeAscii(output, cursor, "LOCAL_ADD");
      return cursor + 9;
    }

    if (opcode == OPCODE_LOCAL_SUB) {
      writeAscii(output, cursor, "LOCAL_SUB");
      return cursor + 9;
    }

    if (opcode == OPCODE_LOCAL_MUL) {
      writeAscii(output, cursor, "LOCAL_MUL");
      return cursor + 9;
    }

    if (opcode == OPCODE_LOCAL_DIV) {
      writeAscii(output, cursor, "LOCAL_DIV");
      return cursor + 9;
    }

    if (opcode == OPCODE_LOCAL_MOD) {
      writeAscii(output, cursor, "LOCAL_MOD");
      return cursor + 9;
    }

    if (opcode == OPCODE_LOCAL_XOR) {
      writeAscii(output, cursor, "LOCAL_XOR");
      return cursor + 9;
    }

    if (opcode == OPCODE_LOCAL_AND) {
      writeAscii(output, cursor, "LOCAL_AND");
      return cursor + 9;
    }

    if (opcode == OPCODE_LOCAL_LT) {
      writeAscii(output, cursor, "LOCAL_LT");
      return cursor + 8;
    }

    if (opcode == OPCODE_CALL) {
      writeAscii(output, cursor, "CALL");
      return cursor + 4;
    }

    if (opcode == OPCODE_CALL_VALUE) {
      writeAscii(output, cursor, "CALL_VALUE");
      return cursor + 10;
    }

    if (opcode == OPCODE_CALL_VOID) {
      writeAscii(output, cursor, "CALL_VOID");
      return cursor + 9;
    }

    if (opcode == OPCODE_RETURN) {
      writeAscii(output, cursor, "RETURN");
      return cursor + 6;
    }

    if (opcode == OPCODE_RETURN_VALUE) {
      writeAscii(output, cursor, "RETURN_VALUE");
      return cursor + 12;
    }

    if (opcode == OPCODE_JUMP_IF_ZERO) {
      writeAscii(output, cursor, "JUMP_IF_ZERO");
      return cursor + 12;
    }

    if (opcode == OPCODE_EXPECT_TRUE) {
      writeAscii(output, cursor, "EXPECT_TRUE");
      return cursor + 11;
    }

    if (opcode == OPCODE_HALT) {
      writeAscii(output, cursor, "HALT");
      return cursor + 4;
    }

    assert(false);
    return cursor;
  }

  private long writeKey(
    borrow mut bytes output,
    long cursor,
    long function,
    long instruction,
    long opcode
  ) {
    writeAscii(output, cursor, "forward");
    cursor += 7;
    setByte(output, cursor, 0);
    cursor += 1;
    cursor = writeUnsigned32BigEndian(output, cursor, function);
    cursor = writeUnsigned32BigEndian(output, cursor, instruction);
    cursor = writeOpcodeName(output, cursor, opcode);
    setByte(output, cursor, 0);
    cursor += 1;
    writeAscii(output, cursor, "none");
    return cursor + 4;
  }

  private long writePrefix(borrow mut bytes output, long cursor) {
    setByte(output, cursor, 123);
    setByte(output, cursor + 1, 34);
    writeAscii(output, cursor + 2, "branch");
    setByte(output, cursor + 8, 34);
    setByte(output, cursor + 9, 58);
    setByte(output, cursor + 10, 34);
    writeAscii(output, cursor + 11, "none");
    setByte(output, cursor + 15, 34);
    return cursor + PREFIX_BYTES;
  }

  private long writeDirectionAndFunctionLabel(borrow mut bytes output, long cursor) {
    setByte(output, cursor, 44);
    setByte(output, cursor + 1, 34);
    writeAscii(output, cursor + 2, "direction");
    setByte(output, cursor + 11, 34);
    setByte(output, cursor + 12, 58);
    setByte(output, cursor + 13, 34);
    writeAscii(output, cursor + 14, "forward");
    setByte(output, cursor + 21, 34);
    setByte(output, cursor + 22, 44);
    setByte(output, cursor + 23, 34);
    writeAscii(output, cursor + 24, "function");
    setByte(output, cursor + 32, 34);
    setByte(output, cursor + 33, 58);
    return cursor + 34;
  }

  private long writeInstructionLabel(borrow mut bytes output, long cursor) {
    setByte(output, cursor, 44);
    setByte(output, cursor + 1, 34);
    writeAscii(output, cursor + 2, "instruction");
    setByte(output, cursor + 13, 34);
    setByte(output, cursor + 14, 58);
    return cursor + 15;
  }

  private long writeOpcodeLabel(borrow mut bytes output, long cursor) {
    setByte(output, cursor, 44);
    setByte(output, cursor + 1, 34);
    writeAscii(output, cursor + 2, "opcode");
    setByte(output, cursor + 8, 34);
    setByte(output, cursor + 9, 58);
    setByte(output, cursor + 10, 34);
    return cursor + 11;
  }

  private long writeSuffix(
    borrow mut bytes output,
    long cursor,
    long function,
    long instruction,
    long opcode
  ) {
    cursor = writeDirectionAndFunctionLabel(output, cursor);
    cursor = writeDecimal(output, cursor, function);
    cursor = writeInstructionLabel(output, cursor);
    cursor = writeDecimal(output, cursor, instruction);
    cursor = writeOpcodeLabel(output, cursor);
    cursor = writeOpcodeName(output, cursor, opcode);
    setByte(output, cursor, 34);
    setByte(output, cursor + 1, 125);
    return cursor + 2;
  }

  private long tracedOpcode(borrow byteview traceOpcodes, long transition) {
    return traceOpcodes[transition * 2] + traceOpcodes[transition * 2 + 1] * 256;
  }

  /// Measures the exact profile-1 fragment stream for one linear native trace.
  public long measuredTransitionFragments(
    borrow byteview traceOpcodes,
    long transitionCount,
    long function
  ) {
    assert(0 < transitionCount);
    assert(transitionCount < MAX_TRANSITIONS + 1);
    assert(bufferLength(traceOpcodes) == MAX_INTERPRETED_STEPS * 2);
    assert(-1 < function);
    long length = 1;
    long transition = 0;
    while (transition < transitionCount) limit MAX_TRANSITIONS {
      long nameLength = opcodeNameLength(tracedOpcode(traceOpcodes, transition));
      long keyLength = KEY_FIXED_BYTES + nameLength;
      long suffixLength = SUFFIX_FIXED_BYTES + decimalDigits(function) + decimalDigits(transition)
        + nameLength;
      length += 6 + keyLength + PREFIX_BYTES + suffixLength;
      transition += 1;
    }

    return length;
  }

  /// Writes one exact profile-1 fragment stream from a complete linear native trace.
  public void writeTransitionFragments(
    borrow byteview traceOpcodes,
    long transitionCount,
    long function,
    borrow mut bytes output
  ) {
    long measured = measuredTransitionFragments(traceOpcodes, transitionCount, function);
    assert(measured < bufferLength(output) + 1);
    setByte(output, 0, transitionCount);
    long cursor = 1;
    long transition = 0;
    while (transition < transitionCount) limit MAX_TRANSITIONS {
      long opcode = tracedOpcode(traceOpcodes, transition);
      long nameLength = opcodeNameLength(opcode);
      long keyLength = KEY_FIXED_BYTES + nameLength;
      long suffixLength = SUFFIX_FIXED_BYTES + decimalDigits(function) + decimalDigits(transition)
        + nameLength;
      cursor = writeUnsigned16(output, cursor, keyLength);
      cursor = writeKey(output, cursor, function, transition, opcode);
      cursor = writeUnsigned16(output, cursor, PREFIX_BYTES);
      cursor = writePrefix(output, cursor);
      cursor = writeUnsigned16(output, cursor, suffixLength);
      cursor = writeSuffix(output, cursor, function, transition, opcode);
      transition += 1;
    }

    assert(cursor == measured);
  }
}
