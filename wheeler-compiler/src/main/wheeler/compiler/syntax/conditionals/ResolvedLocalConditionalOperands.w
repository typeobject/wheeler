//! Decodes the signed local carried by one resolved Boolean condition.

module wheeler.compiler.resolved_local_conditional_operands;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalConditionalOperands {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long LOCAL_CONDITIONAL_END = STATEMENT_IF_LOCAL_XOR_BASE + RESOLVED_SOURCE_COUNT;
  private const long RESOLVED_LOCAL_CONDITIONAL_END = STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Returns the condition local carried by a resolved conditional opcode.
  public long resolvedLocalConditionalSource(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ADD_BASE) {
      return opcode - STATEMENT_IF_LOCAL_ADD_BASE;
    }

    if (opcode < LOCAL_CONDITIONAL_END) {
      return opcode % RESOLVED_SOURCE_COUNT;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_BASE) {
      return opcode - STATEMENT_IF_LOCAL_XOR_BASE;
    }

    if (opcode < RESOLVED_LOCAL_CONDITIONAL_END) {
      return opcode % RESOLVED_SOURCE_COUNT;
    }

    return opcode - STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE;
  }
}
