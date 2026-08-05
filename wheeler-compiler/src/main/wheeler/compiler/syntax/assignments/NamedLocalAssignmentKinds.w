//! Classifies unresolved scalar local assignments.

module wheeler.compiler.named_local_assignment_kinds;

import wheeler.compiler.statement_kinds;

classical class NamedLocalAssignmentKinds {
  /// Checks whether one statement is an unresolved scalar assignment.
  public boolean localAssignmentSourceStatement(long opcode) {
    if (opcode == STATEMENT_ASSIGN) {
      return true;
    }

    return opcode == STATEMENT_ASSIGN_LOCAL_NAMED;
  }
}
