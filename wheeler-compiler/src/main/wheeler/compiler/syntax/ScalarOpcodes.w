//! Classifies resolved scalar copy and comparison opcodes.

module wheeler.compiler.scalar_opcodes;

import wheeler.compiler.tokens;

classical class ScalarOpcodes {
  /// Checks whether an opcode carries a resolved signed less-than assertion source.
  public boolean resolvedLocalLessThanAssertion(long opcode) {
    if (opcode < STATEMENT_ASSERT_LONG_LT_BASE) {
      return false;
    }

    return opcode < STATEMENT_ASSERT_LONG_LT_BASE + 256;
  }

  /// Checks whether an opcode carries signed equality with a literal.
  public boolean resolvedLocalLiteralEquality(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_EQ_LITERAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_EQ_LITERAL_BASE + 256;
  }

  /// Checks whether an opcode carries signed inequality with a literal.
  public boolean resolvedLocalLiteralInequality(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_NE_LITERAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_NE_LITERAL_BASE + 256;
  }

  /// Checks whether an opcode carries signed less-than with a literal.
  public boolean resolvedLocalLiteralLessThan(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_LT_LITERAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_LT_LITERAL_BASE + 256;
  }

  /// Checks whether an opcode carries a signed comparison with a literal.
  public boolean resolvedLocalLiteralComparison(long opcode) {
    if (resolvedLocalLiteralEquality(opcode)) {
      return true;
    }

    if (resolvedLocalLiteralInequality(opcode)) {
      return true;
    }

    return resolvedLocalLiteralLessThan(opcode);
  }

  /// Returns the source local carried by a literal comparison.
  public long resolvedLocalLiteralComparisonSource(long opcode) {
    if (resolvedLocalLiteralEquality(opcode)) {
      return opcode - STATEMENT_LOCAL_LONG_EQ_LITERAL_BASE;
    }

    if (resolvedLocalLiteralInequality(opcode)) {
      return opcode - STATEMENT_LOCAL_LONG_NE_LITERAL_BASE;
    }

    return opcode - STATEMENT_LOCAL_LONG_LT_LITERAL_BASE;
  }

  /// Checks whether an opcode carries one resolved signed-local identity.
  public boolean resolvedLocalLongAssertion(long opcode) {
    if (opcode < STATEMENT_ASSERT_LOCAL_LONG_BASE) {
      return false;
    }

    return opcode < STATEMENT_ASSERT_LOCAL_LONG_BASE + 256;
  }

  /// Checks whether an opcode carries one resolved signed-local copy source.
  public boolean resolvedLocalLongCopy(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_COPY_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_COPY_BASE + 256;
  }

  /// Checks whether an opcode carries one resolved Boolean-local copy source.
  public boolean resolvedLocalBooleanCopy(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_COPY_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_BOOLEAN_COPY_BASE + 256;
  }

  /// Checks whether an opcode carries one resolved negated Boolean-local source.
  public boolean resolvedLocalBooleanNot(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_NOT_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_BOOLEAN_NOT_BASE + 256;
  }

  /// Checks whether an opcode carries a resolved local-equality left source.
  public boolean resolvedLocalEquality(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_EQ_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_EQ_BASE + 256;
  }

  /// Reports whether a resolved local equality compares signed values.
  public boolean resolvedLocalEqualitySigned(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_EQ_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_EQ_BASE + 256;
  }

  /// Returns the left source local carried by a resolved equality opcode.
  public long resolvedLocalEqualitySource(long opcode) {
    if (resolvedLocalEqualitySigned(opcode)) {
      return opcode - STATEMENT_LOCAL_LONG_EQ_BASE;
    }

    return opcode - STATEMENT_LOCAL_BOOLEAN_EQ_BASE;
  }

  /// Checks whether an opcode carries a resolved local-inequality left source.
  public boolean resolvedLocalInequality(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_NE_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_NE_BASE + 256;
  }

  /// Reports whether a resolved local inequality compares signed values.
  public boolean resolvedLocalInequalitySigned(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_NE_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_NE_BASE + 256;
  }

  /// Returns the left source local carried by a resolved inequality opcode.
  public long resolvedLocalInequalitySource(long opcode) {
    if (resolvedLocalInequalitySigned(opcode)) {
      return opcode - STATEMENT_LOCAL_LONG_NE_BASE;
    }

    return opcode - STATEMENT_LOCAL_BOOLEAN_NE_BASE;
  }

  /// Checks whether an opcode carries a resolved signed less-than left source.
  public boolean resolvedLocalLongLessThan(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_LT_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_LT_BASE + 256;
  }

  /// Checks for one unresolved checked scalar update statement.
  public boolean localUpdateSourceStatement(long opcode) {
    if (opcode == STATEMENT_UPDATE_ADD) {
      return true;
    }

    if (opcode == STATEMENT_UPDATE_ADD_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_UPDATE_SUB) {
      return true;
    }

    if (opcode == STATEMENT_UPDATE_SUB_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_UPDATE_XOR) {
      return true;
    }

    return opcode == STATEMENT_UPDATE_XOR_LOCAL_NAMED;
  }

  /// Checks whether an opcode carries one resolved local-update target.
  public boolean resolvedLocalUpdate(long opcode) {
    if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE + 256;
  }

  /// Checks whether a resolved local update reads a prior local.
  public boolean resolvedLocalUpdateNamed(long opcode) {
    if (STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE + 256) {
        return true;
      }
    }

    if (STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE + 256) {
        return true;
      }
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE + 256;
  }

  /// Returns the target local carried by one resolved update opcode.
  public long resolvedLocalUpdateTarget(long opcode) {
    if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE) {
      return opcode - STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE) {
      return opcode - STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE) {
      return opcode - STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE) {
      return opcode - STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE) {
      return opcode - STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE;
    }

    return opcode - STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE;
  }

}
