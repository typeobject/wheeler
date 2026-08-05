//! Decodes resolved bounded local-loop operands.

module wheeler.compiler.resolved_local_loop_operands;

import wheeler.compiler.loop_kinds;
import wheeler.compiler.resolved_statements;

classical class ResolvedLocalLoopOperands {
  /// Returns the target local carried by one resolved while opcode.
  public long resolvedLocalWhileTarget(long opcode) {
    long relative = opcode - STATEMENT_LOCAL_WHILE_BASE;
    long target = relative / STATEMENT_LOCAL_WHILE_FORM_COUNT;
    return target;
  }

  /// Returns the form bits carried by one resolved while opcode.
  public long resolvedLocalWhileForm(long opcode) {
    long relative = opcode - STATEMENT_LOCAL_WHILE_BASE;
    long form = relative % STATEMENT_LOCAL_WHILE_FORM_COUNT;
    return form;
  }
}
