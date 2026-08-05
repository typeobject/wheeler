//! Decodes resolved bounded local-loop operands.

module wheeler.compiler.resolved_local_loop_operands;

import wheeler.compiler.loop_kinds;
import wheeler.compiler.resolved_statements;

classical class ResolvedLocalLoopOperands {
  /// Returns the target local carried by one resolved while opcode.
  public long resolvedLocalWhileTarget(long opcode) {
    return(opcode - STATEMENT_LOCAL_WHILE_BASE) / STATEMENT_LOCAL_WHILE_FORM_COUNT;
  }

  /// Returns the form bits carried by one resolved while opcode.
  public long resolvedLocalWhileForm(long opcode) {
    return(opcode - STATEMENT_LOCAL_WHILE_BASE) % STATEMENT_LOCAL_WHILE_FORM_COUNT;
  }
}
