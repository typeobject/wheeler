//! Executes the bounded scalar result-slot primitives used by the native interpreter.
module wheeler.runtime.result_slots;

import wheeler.compiler.opcode_kinds;
import wheeler.compiler.opcodes;
import wheeler.core.encoding.binary;

classical class ResultSlots {
  private const long OPCODE_WIDTH = 2;
  private const long OPERAND_WIDTH = 8;
  private const long RESULT_SLOT_OFFSET = 8;
  private const long RELATION_VALUE_OFFSET = 16;
  private const long OPERATION_OFFSET = 24;
  private const long RIGHT_VALUE_OFFSET = 32;

  /// Carries one checked inverse-call expectation.
  public record ResultExpectation(long value, boolean valid) {}

  /// Checks the canonical two-register representation accepted at a return boundary.
  public boolean resultSlotCanonical(long tag, long payload) {
    if (tag == 0) {
      return payload == 0;
    }

    return tag == 1;
  }

  /// Evaluates the first relation in one inverse result body against caller arguments.
  public ResultExpectation inverseResultExpectation(
    borrow byteview artifact,
    long relation,
    borrow mut words locals,
    long localBase,
    long argumentBase,
    long argumentCount
  ) {
    long opcode = readUnsigned(artifact, relation, OPCODE_WIDTH);
    if (opcode == OPCODE_RESULT_FILL_CONSTANT) {
      return new ResultExpectation(readSigned(artifact, relation + RELATION_VALUE_OFFSET), true);
    }

    if (opcode == OPCODE_RESULT_FILL_SOURCE) {} else {
      if (opcode == OPCODE_RESULT_FILL_BINARY) {} else {
        if (opcode == OPCODE_RESULT_FILL_BINARY_SOURCES) {} else {
          return new ResultExpectation(0, false);
        }
      }
    }

    long source = readUnsigned(artifact, relation + RELATION_VALUE_OFFSET, OPERAND_WIDTH);
    if (source < argumentCount) {} else {
      return new ResultExpectation(0, false);
    }

    long value = locals[localBase + argumentBase + source];
    if (opcode == OPCODE_RESULT_FILL_BINARY) {
      long operation = readUnsigned(artifact, relation + OPERATION_OFFSET, OPERAND_WIDTH);
      if (isResultBinaryOperation(operation)) {} else {
        return new ResultExpectation(0, false);
      }

      value = resultBinaryValue(
        value,
        operation,
        readSigned(artifact, relation + RIGHT_VALUE_OFFSET)
      );
    }

    if (opcode == OPCODE_RESULT_FILL_BINARY_SOURCES) {
      long sourceOperation = readUnsigned(artifact, relation + OPERATION_OFFSET, OPERAND_WIDTH);
      if (isResultBinaryOperation(sourceOperation)) {} else {
        return new ResultExpectation(0, false);
      }

      long rightSource = readUnsigned(artifact, relation + RIGHT_VALUE_OFFSET, OPERAND_WIDTH);
      if (rightSource < argumentCount) {} else {
        return new ResultExpectation(0, false);
      }

      value = resultBinaryValue(
        value,
        sourceOperation,
        locals[localBase + argumentBase + rightSource]
      );
    }

    return new ResultExpectation(value, true);
  }

  /// Executes one verified result-fill instruction at the selected frame base.
  ///
  /// - Effects: Mutates the slot only after the complete relation evaluates.
  public boolean executeResultFill(
    borrow byteview artifact,
    long cursor,
    long opcode,
    borrow mut words locals,
    long localBase
  ) {
    long slot = localBase + readUnsigned(artifact, cursor + RESULT_SLOT_OFFSET, OPERAND_WIDTH);
    if (opcode == OPCODE_RESULT_FILL_CONSTANT) {
      return exchangeResultConstant(
        locals,
        slot,
        readSigned(artifact, cursor + RELATION_VALUE_OFFSET)
      );
    }

    long source = localBase + readUnsigned(
      artifact,
      cursor + RELATION_VALUE_OFFSET,
      OPERAND_WIDTH
    );
    if (opcode == OPCODE_RESULT_FILL_SOURCE) {
      return exchangeResultSource(locals, slot, source);
    }

    if (opcode == OPCODE_RESULT_FILL_BINARY_SOURCES) {
      long rightSource = localBase + readUnsigned(
        artifact,
        cursor + RIGHT_VALUE_OFFSET,
        OPERAND_WIDTH
      );
      return exchangeResultBinary(
        locals,
        slot,
        source,
        readUnsigned(artifact, cursor + OPERATION_OFFSET, OPERAND_WIDTH),
        locals[rightSource]
      );
    }

    return exchangeResultBinary(
      locals,
      slot,
      source,
      readUnsigned(artifact, cursor + OPERATION_OFFSET, OPERAND_WIDTH),
      readSigned(artifact, cursor + RIGHT_VALUE_OFFSET)
    );
  }

  /// Exchanges exact vacancy with one preserved signed source.
  ///
  /// - Effects: Mutates the slot only after reading the source value.
  private boolean exchangeResultSource(borrow mut words locals, long slot, long source) {
    long value = locals[source];
    return exchangeResultConstant(locals, slot, value);
  }

  /// Computes one checked signed result operation.
  private long resultBinaryValue(long left, long operation, long immediate) {
    long value = 0;
    if (operation == OPCODE_LOCAL_ADD) {
      value = left + immediate;
    }

    if (operation == OPCODE_LOCAL_SUB) {
      value = left - immediate;
    }

    if (operation == OPCODE_LOCAL_MUL) {
      value = left * immediate;
    }

    if (operation == OPCODE_LOCAL_DIV) {
      value = left / immediate;
    }

    if (operation == OPCODE_LOCAL_MOD) {
      value = left % immediate;
    }

    if (operation == OPCODE_LOCAL_XOR) {
      value = left ^ immediate;
    }

    if (operation == OPCODE_LOCAL_AND) {
      value = left & immediate;
    }

    return value;
  }

  /// Exchanges exact vacancy with one preserved signed binary result.
  ///
  /// - Effects: Computes before mutating either slot register.
  private boolean exchangeResultBinary(
    borrow mut words locals,
    long slot,
    long source,
    long operation,
    long immediate
  ) {
    if (isResultBinaryOperation(operation)) {} else {
      return false;
    }

    return exchangeResultConstant(
      locals,
      slot,
      resultBinaryValue(locals[source], operation, immediate)
    );
  }

  /// Exchanges exact vacancy with one held signed constant.
  ///
  /// - Effects: Mutates both adjacent slot registers only after complete validation.
  private boolean exchangeResultConstant(borrow mut words locals, long slot, long constant) {
    long tag = locals[slot];
    long payload = locals[slot + 1];
    if (tag == 0) {
      if (payload == 0) {
        set(locals, slot, 1);
        set(locals, slot + 1, constant);
        return true;
      }

      return false;
    }

    if (tag == 1) {
      if (payload == constant) {
        set(locals, slot, 0);
        set(locals, slot + 1, 0);
        return true;
      }
    }

    return false;
  }
}
