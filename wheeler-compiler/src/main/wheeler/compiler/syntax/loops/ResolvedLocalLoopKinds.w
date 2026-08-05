//! Classifies resolved bounded local loops.

module wheeler.compiler.resolved_local_loop_kinds;

import wheeler.compiler.loop_kinds;
import wheeler.compiler.resolved_statements;

classical class ResolvedLocalLoopKinds {
  private const long RESOLVED_TARGET_COUNT = 256;
  private const long LOCAL_WHILE_END = STATEMENT_LOCAL_WHILE_BASE + RESOLVED_TARGET_COUNT
    * STATEMENT_LOCAL_WHILE_FORM_COUNT;

  /// Checks whether an opcode carries one resolved bounded while loop.
  public boolean resolvedLocalWhile(long opcode) {
    if (opcode < STATEMENT_LOCAL_WHILE_BASE) {
      return false;
    }

    return opcode < LOCAL_WHILE_END;
  }
}
