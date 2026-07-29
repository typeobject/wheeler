//! Encodes bounded typed helper return statements.

module wheeler.compiler.return_codegen;

import wheeler.compiler.encoding;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class ReturnCodegen {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_TERNARY = INSTRUCTION_FORM_TERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  private long writeReturnScalarOperand(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand
  ) {
    if (opcode == OPCODE_LOCAL_CONST) {
      return writeSignedLittleEndian(output, cursor, operand, U64);
    }

    return writeUnsignedLittleEndian(output, cursor, operand, U64);
  }

  /// Writes a typed helper return, or reports that the opcode is not a return.
  public long writeReturnStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase
  ) {
    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, /* value= */ 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_XOR, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (returnBooleanEqualityStatement(opcode)) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      long rightOpcode = OPCODE_LOCAL_CONST;
      if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED) {
        rightOpcode = OPCODE_LOCAL_MOVE;
      }

      cursor = writeInstructionHeader(output, cursor, rightOpcode, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeReturnScalarOperand(output, cursor, rightOpcode, secondaryOperand);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_EQ, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (returnLocalPairStatement(opcode)) {
      long returnPairOpcode = OPCODE_LOCAL_ADD;
      if (opcode == STATEMENT_RETURN_LOCAL_SUB_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_SUB;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_MUL_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_MUL;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_DIV_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_DIV;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_MOD;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_XOR_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_XOR;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_AND_LOCAL_NAMED) {
        returnPairOpcode = OPCODE_LOCAL_AND;
      }

      long rightParameter = 0;
      if (localBase == 2) {
        rightParameter = 1;
      }

      long leftCopy = localBase;
      long rightCopy = localBase + 1;
      long result = localBase + 2;

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, leftCopy, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, rightCopy, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, rightParameter, U64);
      cursor = writeInstructionHeader(output, cursor, returnPairOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, result, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, leftCopy, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, rightCopy, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, result, U64);
    }

    if (returnLocalBinaryStatement(opcode)) {
      long returnOpcode = OPCODE_LOCAL_ADD;
      if (opcode == STATEMENT_RETURN_LOCAL_SUB_NAMED) {
        returnOpcode = OPCODE_LOCAL_SUB;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_MUL_NAMED) {
        returnOpcode = OPCODE_LOCAL_MUL;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_DIV_NAMED) {
        returnOpcode = OPCODE_LOCAL_DIV;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_MOD_NAMED) {
        returnOpcode = OPCODE_LOCAL_MOD;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_XOR_NAMED) {
        returnOpcode = OPCODE_LOCAL_XOR;
      }

      if (opcode == STATEMENT_RETURN_LOCAL_AND_NAMED) {
        returnOpcode = OPCODE_LOCAL_AND;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, /* value= */ 0, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, returnOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (resolvedLocalReturn(opcode)) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        resolvedLocalReturnSource(opcode),
        U64
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    boolean literalReturn = opcode == STATEMENT_RETURN_LONG;
    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      literalReturn = true;
    }

    if (literalReturn) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    return -1;
  }
}
