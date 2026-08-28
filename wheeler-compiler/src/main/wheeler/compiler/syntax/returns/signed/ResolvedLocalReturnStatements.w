//! Defines resolved scalar local-return statement columns.

module wheeler.compiler.resolved_local_return_statements;

classical class ResolvedLocalReturnStatements {
  /// Starts resolved signed-local return opcodes.
  public const long STATEMENT_RETURN_SIGNED_LOCAL_BASE = 14336;
  /// Starts resolved Boolean-local return opcodes.
  public const long STATEMENT_RETURN_BOOLEAN_LOCAL_BASE = 14592;
}
