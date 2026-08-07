//! Computes bounded call-assignment instruction widths.

module wheeler.compiler.assignment_call_instruction_widths;

import wheeler.compiler.assignment_call_arities;

classical class AssignmentCallInstructionWidths {
  /// Returns the instruction count for one call assignment.
  public long assignmentCallInstructionCount(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    long argumentInstructions = arity * 2;
    return argumentInstructions + 2;
  }
}
