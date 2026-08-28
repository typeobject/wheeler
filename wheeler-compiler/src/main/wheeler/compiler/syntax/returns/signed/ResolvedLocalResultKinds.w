//! Classifies resolved signed-local helper returns.

module wheeler.compiler.resolved_local_result_kinds;

import wheeler.compiler.resolved_local_return_statements;

classical class ResolvedLocalResultKinds {
  /// Reports whether one resolved local return carries a signed value.
  public boolean resolvedSignedLocalReturn(long opcode) {
    if (opcode < STATEMENT_RETURN_SIGNED_LOCAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_RETURN_BOOLEAN_LOCAL_BASE;
  }
}
