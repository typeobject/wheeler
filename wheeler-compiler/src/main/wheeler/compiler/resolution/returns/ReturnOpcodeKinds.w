//! Selects bounded scalar return opcodes after typed operand resolution.

module wheeler.compiler.return_opcode_kinds;

import wheeler.compiler.statement_kinds;

classical class ReturnOpcodeKinds {
  /// Selects a signed opcode for one syntactically ambiguous comparison.
  public long signedAmbiguousOpcode(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED) {
      return STATEMENT_RETURN_SIGNED_EQ_LOCAL_NAMED;
    }

    return STATEMENT_RETURN_SIGNED_NE_LOCAL_NAMED;
  }

  /// Selects the literal-right form of one scalar comparison return.
  public long literalComparisonOpcode(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED) {
      return STATEMENT_RETURN_BOOLEAN_EQ_LITERAL_NAMED;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED) {
      return STATEMENT_RETURN_BOOLEAN_NE_LITERAL_NAMED;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_EQ_LOCAL_NAMED) {
      return STATEMENT_RETURN_SIGNED_EQ_LITERAL_NAMED;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_NE_LOCAL_NAMED) {
      return STATEMENT_RETURN_SIGNED_NE_LITERAL_NAMED;
    }

    return STATEMENT_RETURN_SIGNED_LT_LITERAL_NAMED;
  }

  /// Selects the literal-right form of one signed arithmetic return.
  public long literalReturnOpcode(long opcode) {
    if (opcode == STATEMENT_RETURN_LOCAL_ADD_LOCAL_NAMED) {
      return STATEMENT_RETURN_LOCAL_ADD_NAMED;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_SUB_LOCAL_NAMED) {
      return STATEMENT_RETURN_LOCAL_SUB_NAMED;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_MUL_LOCAL_NAMED) {
      return STATEMENT_RETURN_LOCAL_MUL_NAMED;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_DIV_LOCAL_NAMED) {
      return STATEMENT_RETURN_LOCAL_DIV_NAMED;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED) {
      return STATEMENT_RETURN_LOCAL_MOD_NAMED;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_XOR_LOCAL_NAMED) {
      return STATEMENT_RETURN_LOCAL_XOR_NAMED;
    }

    return STATEMENT_RETURN_LOCAL_AND_NAMED;
  }
}
