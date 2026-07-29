//! Classifies local-statement opcodes and their bounded register shapes.

module wheeler.compiler.local_opcodes;

import wheeler.compiler.conditionals;
import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class LocalOpcodes {
  /// Starts resolved signed-local return opcodes.
  public const long STATEMENT_RETURN_SIGNED_LOCAL_BASE = 14336;
  /// Starts resolved Boolean-local return opcodes.
  public const long STATEMENT_RETURN_BOOLEAN_LOCAL_BASE = 14592;

  /// Checks whether an opcode returns one resolved local.
  public boolean resolvedLocalReturn(long opcode) {
    if (opcode < STATEMENT_RETURN_SIGNED_LOCAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_RETURN_BOOLEAN_LOCAL_BASE + 256;
  }

  /// Reports whether a resolved local return carries a signed value.
  public boolean resolvedSignedLocalReturn(long opcode) {
    if (opcode < STATEMENT_RETURN_SIGNED_LOCAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_RETURN_BOOLEAN_LOCAL_BASE;
  }

  /// Returns the source local carried by a resolved return opcode.
  public long resolvedLocalReturnSource(long opcode) {
    if (resolvedSignedLocalReturn(opcode)) {
      return opcode - STATEMENT_RETURN_SIGNED_LOCAL_BASE;
    }

    return opcode - STATEMENT_RETURN_BOOLEAN_LOCAL_BASE;
  }

  /// Checks for a named signed-local and literal binary declaration.
  public boolean namedLongBinary(long opcode) {
    if (opcode == STATEMENT_LOCAL_LONG_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MUL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_DIV_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MOD_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_LONG_AND_NAMED;
  }

  /// Checks for a named binary declaration over two signed locals.
  public boolean namedLongPair(long opcode) {
    if (opcode == STATEMENT_LOCAL_LONG_ADD_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_SUB_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_XOR_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MUL_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_DIV_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MOD_LOCALS_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_LONG_AND_LOCALS_NAMED;
  }

  /// Checks whether a global update reads a prior signed local.
  public boolean namedGlobalUpdate(long opcode) {
    if (opcode == STATEMENT_UPDATE_ADD_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_UPDATE_SUB_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_UPDATE_XOR_LOCAL_NAMED;
  }

  /// Checks whether an opcode carries a resolved two-local equality assertion.
  public boolean resolvedLocalPairAssertion(long opcode) {
    if (opcode < STATEMENT_ASSERT_LONG_PAIR_BASE) {
      return false;
    }

    return opcode < STATEMENT_ASSERT_BOOLEAN_PAIR_BASE + 256;
  }

  /// Reports whether a resolved two-local assertion compares signed values.
  public boolean resolvedLocalPairAssertionSigned(long opcode) {
    if (opcode < STATEMENT_ASSERT_LONG_PAIR_BASE) {
      return false;
    }

    return opcode < STATEMENT_ASSERT_BOOLEAN_PAIR_BASE;
  }

  /// Returns the left source carried by a resolved two-local assertion.
  public long resolvedLocalPairAssertionSource(long opcode) {
    if (resolvedLocalPairAssertionSigned(opcode)) {
      return opcode - STATEMENT_ASSERT_LONG_PAIR_BASE;
    }

    return opcode - STATEMENT_ASSERT_BOOLEAN_PAIR_BASE;
  }

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

  /// Checks whether an opcode carries a resolved signed-local binary source.
  public boolean resolvedLocalLongBinary(long opcode) {
    if (STATEMENT_LOCAL_LONG_ADD_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_LONG_XOR_BASE + 256) {
        return true;
      }
    }

    if (STATEMENT_LOCAL_LONG_MUL_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_LONG_MOD_BASE + 256) {
        return true;
      }
    }

    if (opcode < STATEMENT_LOCAL_LONG_AND_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_AND_BASE + 256;
  }

  /// Returns the source local carried by a resolved signed binary opcode.
  public long resolvedLocalLongBinarySource(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_SUB_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_ADD_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_XOR_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_SUB_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_XOR_BASE + 256) {
      return opcode - STATEMENT_LOCAL_LONG_XOR_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_DIV_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_MUL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_MOD_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_DIV_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_MOD_BASE + 256) {
      return opcode - STATEMENT_LOCAL_LONG_MOD_BASE;
    }

    return opcode - STATEMENT_LOCAL_LONG_AND_BASE;
  }

  /// Checks whether an opcode carries the left source of a signed-local pair.
  public boolean resolvedLocalLongPair(long opcode) {
    if (STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE + 256) {
        return true;
      }
    }

    if (STATEMENT_LOCAL_LONG_MUL_LOCALS_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE + 256) {
        return true;
      }
    }

    if (opcode < STATEMENT_LOCAL_LONG_AND_LOCALS_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_AND_LOCALS_BASE + 256;
  }

  /// Returns the left source local carried by a resolved signed-local pair opcode.
  public long resolvedLocalLongPairSource(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE + 256) {
      return opcode - STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_DIV_LOCALS_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_MUL_LOCALS_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_DIV_LOCALS_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE + 256) {
      return opcode - STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE;
    }

    return opcode - STATEMENT_LOCAL_LONG_AND_LOCALS_BASE;
  }

  /// Returns the typed-local width required by one parsed statement.
  public long statementLocalCount(long opcode) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return 2;
    }

    if (oneArgumentCallStatement(opcode)) {
      return 4;
    }

    if (twoArgumentCallStatement(opcode)) {
      return 6;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      return 1;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      return 3;
    }

    if (returnBooleanEqualityStatement(opcode)) {
      return 3;
    }

    if (returnBooleanInequalityStatement(opcode)) {
      return 5;
    }

    if (opcode == STATEMENT_RETURN_LONG) {
      return 1;
    }

    if (resolvedLocalReturn(opcode)) {
      return 1;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_NAMED) {
      return 1;
    }

    if (returnLocalBinaryStatement(opcode)) {
      return 3;
    }

    if (returnLocalPairStatement(opcode)) {
      return 3;
    }

    if (namedLiteralComparisonConditional(opcode)) {
      if (literalComparisonConditionalAssignment(opcode)) {
        return 4;
      }

      return 5;
    }

    if (resolvedLiteralComparisonConditional(opcode)) {
      if (literalComparisonConditionalAssignment(opcode)) {
        return 4;
      }

      return 5;
    }

    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      return 3;
    }

    if (resolvedLocalLiteralComparison(opcode)) {
      if (resolvedLocalLiteralInequality(opcode)) {
        return 6;
      }

      return 4;
    }

    if (opcode == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED) {
      return 6;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED) {
      return 4;
    }

    if (resolvedLocalLessThanAssertion(opcode)) {
      return 3;
    }

    if (opcode == STATEMENT_ASSERT_LONG_LT_NAMED) {
      return 3;
    }

    if (resolvedLocalPairAssertion(opcode)) {
      return 3;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_PAIR_NAMED) {
      return 3;
    }

    if (resolvedLocalConditional(opcode)) {
      if (resolvedLocalConditionalAssignment(opcode)) {
        if (resolvedLocalConditionalNegated(opcode)) {
          return 4;
        }

        return 2;
      }

      if (resolvedLocalConditionalNegated(opcode)) {
        return 5;
      }

      return 3;
    }

    if (namedLocalConditional(opcode)) {
      return 3;
    }

    if (resolvedLocalBooleanCopy(opcode)) {
      return 2;
    }

    if (resolvedLocalBooleanNot(opcode)) {
      return 4;
    }

    if (resolvedLocalEquality(opcode)) {
      return 4;
    }

    if (resolvedLocalInequality(opcode)) {
      return 6;
    }

    if (resolvedLocalLongLessThan(opcode)) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      return 6;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      return 4;
    }

    if (resolvedLocalLongAssertion(opcode)) {
      return 3;
    }

    if (resolvedLocalLongCopy(opcode)) {
      return 2;
    }

    if (resolvedLocalLongBinary(opcode)) {
      return 4;
    }

    if (resolvedLocalLongPair(opcode)) {
      return 4;
    }

    if (namedLongBinary(opcode)) {
      return 4;
    }

    if (namedLongPair(opcode)) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      return 2;
    }

    if (opcode == STATEMENT_ASSERT_NAMED_LONG) {
      return 3;
    }

    if (opcode == STATEMENT_ASSERT_EQ) {
      return 0;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      return 1;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      return 3;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return 1;
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      return 4;
    }

    if (opcode == STATEMENT_ASSIGN) {
      return 1;
    }

    if (opcode == STATEMENT_ASSIGN_LOCAL_NAMED) {
      return 1;
    }

    if (opcode == STATEMENT_UPDATE_ADD) {
      return 2;
    }

    if (opcode == STATEMENT_UPDATE_SUB) {
      return 2;
    }

    if (opcode == STATEMENT_UPDATE_XOR) {
      return 2;
    }

    if (namedGlobalUpdate(opcode)) {
      return 2;
    }

    return 0;
  }

  /// Returns the initialized result local for a declaration statement.
  public long statementResultLocal(long opcode, long localBase) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return localBase + 1;
    }

    if (oneArgumentCallStatement(opcode)) {
      return localBase + 3;
    }

    if (twoArgumentCallStatement(opcode)) {
      return localBase + 5;
    }

    if (namedLongBinary(opcode)) {
      return localBase + 3;
    }

    if (namedLongPair(opcode)) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      return localBase + 5;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      return localBase + 3;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NE_LITERAL_NAMED) {
      return localBase + 5;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED) {
      return localBase + 3;
    }

    return -1;
  }

  /// Returns the encoded byte width of one parsed statement.
  public long statementCodeLength(long opcode) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      return 64;
    }

    if (opcode == STATEMENT_LOCAL_CALL_NAMED) {
      return 64;
    }

    if (oneArgumentCallStatement(opcode)) {
      return 112;
    }

    if (twoArgumentCallStatement(opcode)) {
      return 160;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      return 40;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      return 96;
    }

    if (returnBooleanEqualityStatement(opcode)) {
      return 96;
    }

    if (returnBooleanInequalityStatement(opcode)) {
      return 152;
    }

    if (opcode == STATEMENT_RETURN_LONG) {
      return 40;
    }

    if (resolvedLocalReturn(opcode)) {
      return 40;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_NAMED) {
      return 40;
    }

    if (returnLocalBinaryStatement(opcode)) {
      return 96;
    }

    if (returnLocalPairStatement(opcode)) {
      return 96;
    }

    if (opcode == STATEMENT_ASSERT_LITERAL_EQ) {
      return 96;
    }

    if (resolvedLocalLiteralComparison(opcode)) {
      if (resolvedLocalLiteralInequality(opcode)) {
        return 160;
      }

      return 104;
    }

    if (resolvedLocalLessThanAssertion(opcode)) {
      return 96;
    }

    if (resolvedLocalPairAssertion(opcode)) {
      return 96;
    }

    if (resolvedLiteralComparisonConditional(opcode)) {
      if (literalComparisonConditionalAssignment(opcode)) {
        return 168;
      }

      return 224;
    }

    if (resolvedLocalConditional(opcode)) {
      if (resolvedLocalConditionalAssignment(opcode)) {
        if (resolvedLocalConditionalNegated(opcode)) {
          return 168;
        }

        return 112;
      }

      if (resolvedLocalConditionalNegated(opcode)) {
        return 224;
      }

      return 168;
    }

    if (resolvedLocalLongLessThan(opcode)) {
      return 104;
    }

    if (resolvedLocalEquality(opcode)) {
      return 104;
    }

    if (resolvedLocalInequality(opcode)) {
      return 160;
    }

    if (resolvedLocalBooleanCopy(opcode)) {
      return 48;
    }

    if (resolvedLocalBooleanNot(opcode)) {
      return 104;
    }

    if (resolvedLocalLongPair(opcode)) {
      return 104;
    }

    if (resolvedLocalLongBinary(opcode)) {
      return 104;
    }

    if (resolvedLocalLongCopy(opcode)) {
      return 48;
    }

    if (resolvedLocalLongAssertion(opcode)) {
      return 96;
    }

    if (opcode == STATEMENT_ASSERT_EQ) {
      return 24;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      return 40;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      return 96;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return 40;
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      return 48;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return 48;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return 104;
    }

    if (opcode == STATEMENT_ASSIGN) {
      return 48;
    }

    if (opcode == STATEMENT_ASSIGN_LOCAL_NAMED) {
      return 48;
    }

    if (0 < opcode) {
      return 104;
    }

    return 0;
  }

  /// Returns the instruction count emitted by one parsed statement.
  public long statementInstructionCount(long opcode) {
    if (oneArgumentCallStatement(opcode)) {
      return 4;
    }

    if (twoArgumentCallStatement(opcode)) {
      return 6;
    }

    long length = statementCodeLength(opcode);
    if (length == 24) {
      return 1;
    }

    if (length == 40) {
      return 2;
    }

    if (length == 48) {
      return 2;
    }

    if (length == 64) {
      return 2;
    }

    if (length == 112) {
      return 5;
    }

    if (length == 152) {
      return 6;
    }

    if (length == 160) {
      return 6;
    }

    if (length == 168) {
      return 7;
    }

    if (length == 224) {
      return 9;
    }

    if (0 < length) {
      return 4;
    }

    return 0;
  }
}
