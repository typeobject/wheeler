//! Classifies unresolved signed arithmetic helper returns.

module wheeler.compiler.named_return_arithmetic_kinds;

import wheeler.compiler.statement_kinds;

classical class NamedReturnArithmeticKinds {
  /// Checks for a signed helper return with a literal right operand.
  public boolean returnLocalBinaryStatement(long opcode) {
    if (opcode < STATEMENT_RETURN_LOCAL_ADD_NAMED) {
      return false;
    }

    if (opcode < STATEMENT_RETURN_LOCAL_MOD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_MOD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_XOR_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_LOCAL_AND_NAMED;
  }

  /// Checks for a signed helper return using two parameter locals.
  public boolean returnLocalPairStatement(long opcode) {
    if (opcode < STATEMENT_RETURN_LOCAL_ADD_LOCAL_NAMED) {
      return false;
    }

    if (opcode < STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_XOR_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_LOCAL_AND_LOCAL_NAMED;
  }
}
