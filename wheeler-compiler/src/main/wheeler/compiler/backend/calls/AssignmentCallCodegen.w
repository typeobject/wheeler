//! Encodes typed helper calls assigned into existing signed locals.

module wheeler.compiler.assignment_call_codegen;

import wheeler.compiler.assignment_calls;
import wheeler.compiler.call_arguments;
import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;

classical class AssignmentCallCodegen {
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_QUATERNARY = INSTRUCTION_FORM_QUATERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  /// Writes one resolved call assignment, or reports no matching identity.
  public long writeAssignmentCallStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long function,
    long firstType,
    long secondType,
    long thirdType,
    long fourthType,
    long fifthType,
    long sixthType,
    long seventhType
  ) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    long argument = 0;
    while (argument < arity) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + argument, U64);
      cursor = writeUnsignedLittleEndian(
        output,
        cursor,
        assignmentCallSource(opcode, operand, secondaryOperand, argument),
        U64
      );
      argument += 1;
    }

    long argumentBase = localBase + arity;
    if (arity == 0) {
      argumentBase = 0;
    }

    argument = 0;
    while (argument < arity) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
      long type = callSourceType(
        argument,
        firstType,
        secondType,
        thirdType,
        fourthType,
        fifthType,
        sixthType,
        seventhType
      );
      cursor = writeInstructionHeader(output, cursor, callArgumentOpcode(type), FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, argumentBase + argument, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + argument, U64);
      argument += 1;
    }

    long result = localBase + arity * 2;
    cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, FORM_QUATERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, function, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, argumentBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, arity, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, result, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, assignmentCallTarget(opcode), U64);
    return writeUnsignedLittleEndian(output, cursor, result, U64);
  }
}
