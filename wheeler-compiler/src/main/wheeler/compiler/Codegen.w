//! Encodes the bounded bootstrap IR as canonical Wheeler bytecode.

module wheeler.compiler.codegen;

import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class Codegen {
  /// Maps a parsed global update to its canonical bytecode opcode.
  public long globalOpcode(long opcode) {
    if (opcode == STATEMENT_UPDATE_ADD) {
      return OPCODE_ADD_CONST;
    }

    if (opcode == STATEMENT_UPDATE_SUB) {
      return OPCODE_SUB_CONST;
    }

    return OPCODE_XOR_CONST;
  }

  /// Maps a forward global opcode to its exact inverse opcode.
  public long inverseGlobalOpcode(long opcode) {
    if (opcode == OPCODE_ADD_CONST) {
      return OPCODE_SUB_CONST;
    }

    if (opcode == OPCODE_SUB_CONST) {
      return OPCODE_ADD_CONST;
    }

    return OPCODE_XOR_CONST;
  }

  /// Returns the typed-local width required by one parsed statement.
  public long statementLocalCount(long opcode) {
    if (opcode == STATEMENT_ASSERT_EQ) {
      return 0;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      return 1;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      return 3;
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return 4;
    }

    if (opcode == STATEMENT_ASSIGN) {
      return 1;
    }

    if (0 < opcode) {
      return 2;
    }

    return 0;
  }

  /// Writes canonical local type codes for one parsed statement.
  public long writeStatementLocalTypes(borrow mut bytes output, long cursor, long opcode) {
    long count = statementLocalCount(opcode);
    long typeCode = TYPE_SIGNED;
    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      typeCode = TYPE_BOOLEAN;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      typeCode = TYPE_BOOLEAN;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      typeCode = TYPE_BOOLEAN;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      typeCode = TYPE_BOOLEAN;
    }

    long local = 0;
    while (local < count) limit 4 {
      cursor = writeUnsignedLittleEndian(output, cursor, typeCode, 4);
      local += 1;
    }

    return cursor;
  }

  /// Returns the encoded byte width of one parsed statement.
  public long statementCodeLength(long opcode) {
    if (opcode == STATEMENT_ASSERT_EQ) {
      return 24;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      return 40;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      return 96;
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      return 48;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return 48;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return 104;
    }

    if (opcode == STATEMENT_ASSIGN) {
      return 48;
    }

    if (0 < opcode) {
      return 104;
    }

    return 0;
  }

  /// Writes `globalUpdate` into caller-owned bounded output.
  public long writeGlobalUpdate(borrow mut bytes output, long cursor, long opcode, long operand) {
    cursor = writeInstructionHeader(output, cursor, globalOpcode(opcode), 2);
    cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
    return writeSignedLittleEndian(output, cursor, operand, 8);
  }

  /// Writes `inverseGlobalUpdate` into caller-owned bounded output.
  public long writeInverseGlobalUpdate(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand
  ) {
    cursor = writeInstructionHeader(
      output,
      cursor,
      inverseGlobalOpcode(globalOpcode(opcode)),
      2
    );
    cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
    return writeSignedLittleEndian(output, cursor, operand, 8);
  }

  /// Writes `statement` into caller-owned bounded output.
  public long writeStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long localBase
  ) {
    if (opcode == STATEMENT_ASSERT_EQ) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_EQ, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
      return writeSignedLittleEndian(output, cursor, operand, 8);
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
    cursor = writeSignedLittleEndian(output, cursor, operand, 8);
    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, 1);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, 1);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, 3);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, 8);
    }

    if (opcode == STATEMENT_ASSIGN) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, 2);
      cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
      return writeUnsignedLittleEndian(output, cursor, localBase, 8);
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LOAD_GLOBAL, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
    cursor = writeInstructionHeader(output, cursor, opcode, 3);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, 8);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_STORE_GLOBAL, 2);
    cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);
    return writeUnsignedLittleEndian(output, cursor, localBase + 1, 8);
  }

  /// Writes `functionDescriptor` into caller-owned bounded output.
  public long writeFunctionDescriptor(
    borrow mut bytes output,
    long cursor,
    long id,
    long name,
    long forwardOffset,
    long forwardLength,
    long flags,
    long inverseOffset,
    long inverseLength,
    long localCount,
    long typeOffset
  ) {
    cursor = writeUnsignedLittleEndian(output, cursor, id, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, name, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, flags, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, forwardOffset, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, forwardLength, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, inverseOffset, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, inverseLength, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, 0, 4);
    cursor = writeUnsignedLittleEndian(output, cursor, localCount, 4);
    return writeUnsignedLittleEndian(output, cursor, typeOffset, 4);
  }
}
