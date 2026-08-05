//! Decodes resolved Boolean-local conditional sources and update forms.

module wheeler.compiler.resolved_local_conditional_sources;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalConditionalSources {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long LOCAL_SUB_END = STATEMENT_IF_LOCAL_SUB_BASE + RESOLVED_SOURCE_COUNT;
  private const long LOCAL_XOR_END = STATEMENT_IF_LOCAL_XOR_BASE + RESOLVED_SOURCE_COUNT;
  private const long NOT_LOCAL_SUB_END = STATEMENT_IF_NOT_LOCAL_SUB_BASE + RESOLVED_SOURCE_COUNT;
  private const long NOT_LOCAL_XOR_END = STATEMENT_IF_NOT_LOCAL_XOR_BASE + RESOLVED_SOURCE_COUNT;
  private const long LOCAL_SUB_VALUE_END = STATEMENT_IF_LOCAL_SUB_VALUE_BASE
    + RESOLVED_SOURCE_COUNT;
  private const long LOCAL_XOR_VALUE_END = STATEMENT_IF_LOCAL_XOR_VALUE_BASE
    + RESOLVED_SOURCE_COUNT;
  private const long NOT_LOCAL_SUB_VALUE_END = STATEMENT_IF_NOT_LOCAL_SUB_VALUE_BASE
    + RESOLVED_SOURCE_COUNT;
  private const long NOT_LOCAL_XOR_VALUE_END = STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether a resolved condition reads a prior signed value.
  public boolean resolvedLocalConditionalValue(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE) {
      return false;
    }

    return opcode < NOT_LOCAL_XOR_VALUE_END;
  }

  /// Checks whether a resolved local condition guards subtraction.
  public boolean resolvedLocalConditionalSubtract(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_SUB_BASE) {
      return false;
    }

    if (opcode < LOCAL_SUB_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_SUB_BASE) {
      return false;
    }

    if (opcode < NOT_LOCAL_SUB_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_LOCAL_SUB_VALUE_BASE) {
      return false;
    }

    if (opcode < LOCAL_SUB_VALUE_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_SUB_VALUE_BASE) {
      return false;
    }

    return opcode < NOT_LOCAL_SUB_VALUE_END;
  }

  /// Checks whether a resolved local condition guards XOR.
  public boolean resolvedLocalConditionalXor(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_XOR_BASE) {
      return false;
    }

    if (opcode < LOCAL_XOR_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_XOR_BASE) {
      return false;
    }

    if (opcode < NOT_LOCAL_XOR_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_LOCAL_XOR_VALUE_BASE) {
      return false;
    }

    if (opcode < LOCAL_XOR_VALUE_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE) {
      return false;
    }

    return opcode < NOT_LOCAL_XOR_VALUE_END;
  }
}
