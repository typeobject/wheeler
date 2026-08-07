//! Encodes resolved scalar local assignments and checked updates.

module wheeler.compiler.mutation_codegen;

import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;
import wheeler.compiler.resolved_local_assignments;
import wheeler.compiler.resolved_local_updates;
import wheeler.compiler.resolved_statements;

classical class MutationCodegen {
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_TERNARY = INSTRUCTION_FORM_TERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  private long writeScalarOperand(
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

  /// Writes one resolved local mutation, or reports no matching identity.
  public long writeMutationStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long localBase
  ) {
    if (resolvedLocalAssignment(opcode)) {
      long rightOpcode = OPCODE_LOCAL_CONST;
      if (resolvedLocalAssignmentNamed(opcode)) {
        rightOpcode = OPCODE_LOCAL_MOVE;
      }

      cursor = writeInstructionHeader(output, cursor, rightOpcode, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeScalarOperand(output, cursor, rightOpcode, operand);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        resolvedLocalAssignmentTarget(opcode),
        U64
      );
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    if (resolvedLocalUpdate(opcode)) {
      long target = resolvedLocalUpdateTarget(opcode);
      long updateRightOpcode = OPCODE_LOCAL_CONST;
      if (resolvedLocalUpdateNamed(opcode)) {
        updateRightOpcode = OPCODE_LOCAL_MOVE;
      }

      cursor = writeInstructionHeader(output, cursor, updateRightOpcode, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeScalarOperand(output, cursor, updateRightOpcode, operand);
      long updateOpcode = OPCODE_LOCAL_ADD;
      if (STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE - 1 < opcode) {
        if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE) {
          updateOpcode = OPCODE_LOCAL_SUB;
        }
      }

      if (STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE - 1 < opcode) {
        updateOpcode = OPCODE_LOCAL_XOR;
      }

      cursor = writeInstructionHeader(output, cursor, updateOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    return -1;
  }
}
