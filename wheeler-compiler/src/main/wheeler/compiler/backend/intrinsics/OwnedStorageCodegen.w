//! Encodes bounded owned byte allocation and explicit destruction.

module wheeler.compiler.owned_storage_codegen;

import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;
import wheeler.compiler.owned_storage_forms;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.storage_opcodes;

classical class OwnedStorageCodegen {
  /// Writes one owned-storage statement, or reports that another emitter owns it.
  public long writeOwnedStorageStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase
  ) {
    if (opcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* destination= */ localBase,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* region= */ operand,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* destination= */ localBase + 1,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* length= */ secondaryOperand,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_BYTES_ALLOC,
        INSTRUCTION_FORM_TERNARY
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* destination= */ localBase + 2,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* region= */ localBase,
        INSTRUCTION_OPERAND_WIDTH
      );
      return writeUnsignedLittleEndian(
        output,
        cursor,
        /* length= */ localBase + 1,
        INSTRUCTION_OPERAND_WIDTH
      );
    }

    if (opcode == STATEMENT_RETURN_FREEZE_UTF8_NAMED) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_OWNED_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* destination= */ localBase,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* source= */ operand,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_UTF8_FREEZE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* destination= */ localBase + 1,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* owner= */ localBase,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_RETURN_VALUE,
        INSTRUCTION_FORM_UNARY
      );
      return writeUnsignedLittleEndian(
        output,
        cursor,
        /* result= */ localBase + 1,
        INSTRUCTION_OPERAND_WIDTH
      );
    }

    if (opcode == STATEMENT_RETURN_FREEZE_MOVED_UTF8) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_UTF8_FREEZE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* destination= */ localBase,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* owner= */ operand,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_RETURN_VALUE,
        INSTRUCTION_FORM_UNARY
      );
      return writeUnsignedLittleEndian(
        output,
        cursor,
        /* result= */ localBase,
        INSTRUCTION_OPERAND_WIDTH
      );
    }

    if (opcode == STATEMENT_DROP_MOVED_OWNED) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_BUFFER_DROP,
        INSTRUCTION_FORM_UNARY
      );
      return writeUnsignedLittleEndian(
        output,
        cursor,
        /* owner= */ operand,
        INSTRUCTION_OPERAND_WIDTH
      );
    }

    if (opcode == STATEMENT_DROP_OWNED_NAMED) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_OWNED_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* destination= */ localBase,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        /* source= */ operand,
        INSTRUCTION_OPERAND_WIDTH
      );
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_BUFFER_DROP,
        INSTRUCTION_FORM_UNARY
      );
      return writeUnsignedLittleEndian(
        output,
        cursor,
        /* owner= */ localBase,
        INSTRUCTION_OPERAND_WIDTH
      );
    }

    return -1;
  }
}
