//! Encodes bounded ordinary void calls with typed argument reborrows.

module wheeler.compiler.void_call_codegen;

import wheeler.compiler.call_arguments;
import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;
import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_widths;

classical class VoidCallCodegen {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_TERNARY = INSTRUCTION_FORM_TERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  private long writeEvaluatedArgument(
    borrow mut bytes output,
    long cursor,
    long target,
    long source
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
    return writeUnsignedLittleEndian(output, cursor, source, U64);
  }

  private long writeCallArgument(
    borrow mut bytes output,
    long cursor,
    long target,
    long source,
    long type
  ) {
    cursor = writeInstructionHeader(output, cursor, callArgumentOpcode(type), FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
    return writeUnsignedLittleEndian(output, cursor, source, U64);
  }

  /// Writes one resolved void call, or reports that it owns no opcode.
  public long writeVoidCallStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long firstSource,
    long secondSource,
    long localBase,
    long function,
    long firstType,
    long secondType,
    long thirdType
  ) {
    long arity = voidCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    assert(-1 < function);
    if (arity == 0) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, function, U64);
    }

    cursor = writeEvaluatedArgument(output, cursor, localBase, firstSource);
    if (1 < arity) {
      cursor = writeEvaluatedArgument(output, cursor, localBase + 1, secondSource);
    }

    if (arity == 3) {
      cursor = writeEvaluatedArgument(
        output,
        cursor,
        localBase + 2,
        voidCallThirdSource(opcode)
      );
    }

    long argumentBase = localBase + arity;
    cursor = writeCallArgument(output, cursor, argumentBase, localBase, firstType);
    if (1 < arity) {
      cursor = writeCallArgument(output, cursor, argumentBase + 1, localBase + 1, secondType);
    }

    if (arity == 3) {
      cursor = writeCallArgument(output, cursor, argumentBase + 2, localBase + 2, thirdType);
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VOID, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, function, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, argumentBase, U64);
    return writeUnsignedLittleEndian(output, cursor, arity, U64);
  }
}
