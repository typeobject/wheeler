//! Decodes bounded packed call-assignment source operands.

module wheeler.compiler.assignment_call_operands;

import wheeler.compiler.assignment_call_identities;
import wheeler.compiler.assignment_call_kinds;

classical class AssignmentCallOperands {
  private const long ASSIGNMENT_CALL_TRAILING_SOURCE = 4;

  private long packedSource(long packed, long source, long first) {
    long selected = first;
    while (selected < source) limit MAX_ASSIGNMENT_CALL_ARGUMENTS {
      packed = packed / ASSIGNMENT_CALL_SOURCE_RADIX;
      selected += 1;
    }

    return packed % ASSIGNMENT_CALL_SOURCE_RADIX;
  }

  /// Decodes one source from the two bounded packed operands.
  public long assignmentCallSource(
    long opcode,
    long operand,
    long secondaryOperand,
    long source
  ) {
    long arity = assignmentCallArity(opcode);
    if (source < 0) {
      return -1;
    }

    if (source < arity) {} else {
      return -1;
    }

    long firstSource = 0;
    if (source < ASSIGNMENT_CALL_TRAILING_SOURCE) {
      return packedSource(operand, source, firstSource);
    }

    long trailingSource = ASSIGNMENT_CALL_TRAILING_SOURCE;
    return packedSource(secondaryOperand, source, trailingSource);
  }
}
