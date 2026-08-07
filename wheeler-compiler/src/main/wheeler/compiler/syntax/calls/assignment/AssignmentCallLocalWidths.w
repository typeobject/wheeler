//! Computes bounded call-assignment temporary-local widths.

module wheeler.compiler.assignment_call_local_widths;

import wheeler.compiler.assignment_call_arities;

classical class AssignmentCallLocalWidths {
  /// Returns the temporary local width for one call assignment.
  public long assignmentCallLocalCount(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    long argumentLocals = arity * 2;
    return argumentLocals + 1;
  }
}
