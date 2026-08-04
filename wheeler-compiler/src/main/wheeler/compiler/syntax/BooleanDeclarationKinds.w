//! Classifies source statements that declare Boolean locals.

module wheeler.compiler.boolean_declaration_kinds;

import wheeler.compiler.statement_kinds;

classical class BooleanDeclarationKinds {
  /// Reports whether one parser opcode declares a nonnegated Boolean local.
  public boolean booleanDeclarationStatement(long statementKind) {
    if (statementKind == STATEMENT_LOCAL_BOOLEAN) {
      return true;
    }

    if (statementKind == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      return true;
    }

    if (statementKind == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      return true;
    }

    if (statementKind == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      return true;
    }

    if (statementKind == STATEMENT_LOCAL_LONG_LT_NAMED) {
      return true;
    }

    if (statementKind == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      return true;
    }

    if (statementKind == STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED) {
      return true;
    }

    return statementKind == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED;
  }
}
