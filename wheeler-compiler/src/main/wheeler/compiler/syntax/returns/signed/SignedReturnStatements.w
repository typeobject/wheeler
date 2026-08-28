//! Defines unresolved signed helper-return statement identities.

module wheeler.compiler.signed_return_statements;

classical class SignedReturnStatements {
  /// Returns one signed literal.
  public const long STATEMENT_RETURN_LONG = 827;
  /// Returns one signed parameter or prior local.
  public const long STATEMENT_RETURN_LOCAL_NAMED = 828;
  /// Returns checked addition with a literal right operand.
  public const long STATEMENT_RETURN_LOCAL_ADD_NAMED = 830;
  /// Returns checked subtraction with a literal right operand.
  public const long STATEMENT_RETURN_LOCAL_SUB_NAMED = 831;
  /// Returns checked multiplication with a literal right operand.
  public const long STATEMENT_RETURN_LOCAL_MUL_NAMED = 832;
  /// Returns checked division with a literal right operand.
  public const long STATEMENT_RETURN_LOCAL_DIV_NAMED = 833;
  /// Returns checked remainder with a literal right operand.
  public const long STATEMENT_RETURN_LOCAL_MOD_NAMED = 834;
  /// Returns checked addition over two locals.
  public const long STATEMENT_RETURN_LOCAL_ADD_LOCAL_NAMED = 836;
  /// Returns checked subtraction over two locals.
  public const long STATEMENT_RETURN_LOCAL_SUB_LOCAL_NAMED = 837;
  /// Returns checked multiplication over two locals.
  public const long STATEMENT_RETURN_LOCAL_MUL_LOCAL_NAMED = 838;
  /// Returns checked division over two locals.
  public const long STATEMENT_RETURN_LOCAL_DIV_LOCAL_NAMED = 839;
  /// Returns checked remainder over two locals.
  public const long STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED = 840;
  /// Returns bitwise XOR with a literal right operand.
  public const long STATEMENT_RETURN_LOCAL_XOR_NAMED = 853;
  /// Returns bitwise XOR over two locals.
  public const long STATEMENT_RETURN_LOCAL_XOR_LOCAL_NAMED = 854;
  /// Returns bitwise AND with a literal right operand.
  public const long STATEMENT_RETURN_LOCAL_AND_NAMED = 860;
  /// Returns bitwise AND over two locals.
  public const long STATEMENT_RETURN_LOCAL_AND_LOCAL_NAMED = 861;
}
