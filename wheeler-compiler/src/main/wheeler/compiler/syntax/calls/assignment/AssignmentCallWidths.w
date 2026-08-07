//! Computes bounded call-assignment register and encoded widths.

module wheeler.compiler.assignment_call_widths;

import wheeler.compiler.assignment_call_arities;

classical class AssignmentCallWidths {
  private const long ASSIGNMENT_CALL_ARGUMENT_CODE_LENGTH = 48;
  private const long ASSIGNMENT_CALL_RESULT_CODE_LENGTH = 64;

  /// Returns the temporary local width for one call assignment.
  public long assignmentCallLocalCount(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    return arity * 2 + 1;
  }

  /// Returns the instruction count for one call assignment.
  public long assignmentCallInstructionCount(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    return arity * 2 + 2;
  }

  /// Returns the encoded instruction width for one call assignment.
  public long assignmentCallCodeLength(long opcode) {
    long instructions = assignmentCallInstructionCount(opcode);
    if (instructions < 0) {
      return -1;
    }

    long arity = assignmentCallArity(opcode);
    return arity * ASSIGNMENT_CALL_ARGUMENT_CODE_LENGTH + ASSIGNMENT_CALL_RESULT_CODE_LENGTH;
  }
}
