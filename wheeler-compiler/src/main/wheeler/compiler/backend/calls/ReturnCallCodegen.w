//! Emits bounded final scalar-result forwarding without an arity staircase.

module wheeler.compiler.return_call_codegen;

import wheeler.compiler.call_arguments;
import wheeler.compiler.encoding;
import wheeler.compiler.five_argument_returns;
import wheeler.compiler.opcodes;
import wheeler.compiler.resolved_return_call_kinds;
import wheeler.compiler.resolved_statements;

classical class ReturnCallCodegen {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_QUATERNARY = INSTRUCTION_FORM_QUATERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  private long callSource(long opcode, long operand, long secondaryOperand, long index) {
    if (opcode == STATEMENT_RETURN_HELPER_CALL_FIVE) {
      if (index == 0) {
        return fiveReturnFirstSource(operand);
      }

      if (index == 1) {
        return fiveReturnSecondSource(operand);
      }

      if (index == 2) {
        return fiveReturnThirdSource(operand);
      }

      if (index == 3) {
        return fiveReturnFourthSource(secondaryOperand);
      }

      return fiveReturnFifthSource(secondaryOperand);
    }

    if (index == 0) {
      long source = returnHelperCallFirstSource(opcode);
      if (returnHelperCallArity(opcode) == 2) {
        source -= RETURN_HELPER_CALL_TWO_SOURCE_OFFSET;
      }

      return source;
    }

    if (index == 1) {
      return returnHelperCallSecondSource(opcode);
    }

    if (index == 2) {
      return returnHelperCallThirdSource(opcode);
    }

    return returnHelperCallFourthSource(opcode);
  }

  private long callSourceType(
    long index,
    long firstSourceType,
    long secondSourceType,
    long thirdSourceType,
    long fourthSourceType,
    long fifthSourceType
  ) {
    if (index == 0) {
      return firstSourceType;
    }

    if (index == 1) {
      return secondSourceType;
    }

    if (index == 2) {
      return thirdSourceType;
    }

    if (index == 3) {
      return fourthSourceType;
    }

    return fifthSourceType;
  }

  /// Writes one zero- through five-argument final helper call, or reports another owner.
  public long writeReturnCall(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long callFunction,
    long firstSourceType,
    long secondSourceType,
    long thirdSourceType,
    long fourthSourceType,
    long fifthSourceType
  ) {
    long arity = returnHelperCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    assert(-1 < callFunction);
    long argument = 0;
    while (argument < arity) limit MAX_FORWARDED_SCALAR_ARGUMENTS {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + argument, U64);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        callSource(opcode, operand, secondaryOperand, argument),
        U64
      );
      argument += 1;
    }

    argument = 0;
    while (argument < arity) limit MAX_FORWARDED_SCALAR_ARGUMENTS {
      long sourceType = callSourceType(
        argument,
        firstSourceType,
        secondSourceType,
        thirdSourceType,
        fourthSourceType,
        fifthSourceType
      );
      cursor = writeInstructionHeader(
        output,
        cursor,
        callArgumentOpcode(sourceType),
        FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + arity + argument, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + argument, U64);
      argument += 1;
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, callFunction, U64);
    long argumentBase = 0;
    if (0 < arity) {
      argumentBase = localBase + arity;
    }

    cursor = writeUnsignedLittleEndian(output, cursor, argumentBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, arity, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + arity * 2, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, localBase + arity * 2, U64);
  }
}
