//! Computes bounded call-assignment encoded widths.

module wheeler.compiler.assignment_call_code_widths;

import wheeler.compiler.assignment_call_arities;

classical class AssignmentCallCodeWidths {
  /// Returns the encoded instruction width for one call assignment.
  public long assignmentCallCodeLength(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    long argumentCodeLength = arity * 48;
    return argumentCodeLength + 64;
  }
}
