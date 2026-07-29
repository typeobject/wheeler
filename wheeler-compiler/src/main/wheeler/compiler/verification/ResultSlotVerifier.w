//! Verifies bounded scalar result-slot transition operands.
module wheeler.compiler.result_slot_verifier;

import wheeler.compiler.opcodes;
import wheeler.compiler.type_codes;
import wheeler.core.encoding.binary;

classical class ResultSlotVerifier {
  private const long RESULT_SLOT_OFFSET = 8;
  private const long SOURCE_OFFSET = 16;
  private const long OPERATION_OFFSET = 24;
  private const long RIGHT_SOURCE_OFFSET = 32;
  private const long OPERAND_WIDTH = 8;

  private long localType(borrow byteview artifact, long activeTypes, long local) {
    return readUnsigned(artifact, activeTypes + local * 4, 4);
  }

  private boolean slotValid(
    borrow byteview artifact,
    long activeTypes,
    long localCount,
    long resultSlot,
    long resultType
  ) {
    if (1 < localCount) {} else {
      return false;
    }

    if (resultSlot == localCount - 2) {} else {
      return false;
    }

    if (localType(artifact, activeTypes, resultSlot) == TYPE_BOOLEAN) {} else {
      return false;
    }

    if (localType(artifact, activeTypes, resultSlot + 1) == TYPE_SIGNED) {} else {
      return false;
    }

    return resultType == TYPE_SIGNED;
  }

  private boolean sourceValid(
    borrow byteview artifact,
    long activeTypes,
    long resultSlot,
    long source
  ) {
    if (source < resultSlot) {} else {
      return false;
    }

    return localType(artifact, activeTypes, source) == TYPE_SIGNED;
  }

  /// Verifies one result-slot instruction, or returns minus one when not applicable.
  public long verifyResultSlotInstruction(
    borrow byteview artifact,
    long cursor,
    long opcode,
    long localCount,
    long activeTypes,
    long resultType,
    long resultSlotBody
  ) {
    boolean resultReturn = opcode == OPCODE_RETURN_RESULT_SLOT;
    if (isResultFillOpcode(opcode)) {} else {
      if (resultReturn) {} else {
        return -1;
      }
    }

    if (resultSlotBody == 1) {} else {
      return 0;
    }

    long resultSlot = readUnsigned(artifact, cursor + RESULT_SLOT_OFFSET, OPERAND_WIDTH);
    if (slotValid(artifact, activeTypes, localCount, resultSlot, resultType)) {} else {
      return 0;
    }

    if (resultReturn) {
      return 1;
    }

    if (opcode == OPCODE_RESULT_FILL_CONSTANT) {
      return 1;
    }

    long source = readUnsigned(artifact, cursor + SOURCE_OFFSET, OPERAND_WIDTH);
    if (sourceValid(artifact, activeTypes, resultSlot, source)) {} else {
      return 0;
    }

    if (opcode == OPCODE_RESULT_FILL_SOURCE) {
      return 1;
    }

    long operation = readUnsigned(artifact, cursor + OPERATION_OFFSET, OPERAND_WIDTH);
    if (isResultBinaryOperation(operation)) {} else {
      return 0;
    }

    if (opcode == OPCODE_RESULT_FILL_BINARY) {
      return 1;
    }

    long rightSource = readUnsigned(artifact, cursor + RIGHT_SOURCE_OFFSET, OPERAND_WIDTH);
    if (sourceValid(artifact, activeTypes, resultSlot, rightSource)) {
      return 1;
    }

    return 0;
  }
}
