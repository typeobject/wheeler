//! Classifies local-statement opcodes and their bounded register shapes.

module wheeler.compiler.local_opcodes;

import wheeler.compiler.tokens;

classical class LocalOpcodes {
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

    return opcode == STATEMENT_LOCAL_LONG_MOD_NAMED;
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

    return opcode == STATEMENT_LOCAL_LONG_MOD_LOCALS_NAMED;
  }

  /// Checks for a named one-arm Boolean condition guarding a global update.
  public boolean namedLocalConditional(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED;
  }

  /// Checks whether a named local condition negates its Boolean source.
  public boolean namedLocalConditionalNegated(long opcode) {
    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED;
  }

  /// Checks whether a named local condition guards assignment.
  public boolean namedLocalConditionalAssignment(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED;
  }

  /// Checks whether a named local condition assigns another local.
  public boolean namedLocalConditionalAssignmentValue(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED;
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

  /// Checks whether an opcode carries a resolved signed less-than left source.
  public boolean resolvedLocalLongLessThan(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_LT_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_LT_BASE + 256;
  }

  /// Checks whether an opcode carries a resolved local conditional source.
  public boolean resolvedLocalConditional(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ADD_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_LOCAL_XOR_BASE + 256) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE + 256;
  }

  /// Checks whether a resolved local condition negates its Boolean source.
  public boolean resolvedLocalConditionalNegated(long opcode) {
    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_XOR_BASE + 256) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE + 256) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE + 256;
  }

  /// Checks whether a resolved local condition guards assignment.
  public boolean resolvedLocalConditionalAssignment(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE + 256;
  }

  /// Checks whether a resolved condition assigns a prior signed local.
  public boolean resolvedLocalConditionalAssignmentValue(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE + 256;
  }

  /// Checks whether a resolved local condition guards subtraction.
  public boolean resolvedLocalConditionalSubtract(long opcode) {
    if (STATEMENT_IF_LOCAL_SUB_BASE - 1 < opcode) {
      if (opcode < STATEMENT_IF_LOCAL_SUB_BASE + 256) {
        return true;
      }
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_SUB_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_SUB_BASE + 256;
  }

  /// Checks whether a resolved local condition guards XOR.
  public boolean resolvedLocalConditionalXor(long opcode) {
    if (STATEMENT_IF_LOCAL_XOR_BASE - 1 < opcode) {
      if (opcode < STATEMENT_IF_LOCAL_XOR_BASE + 256) {
        return true;
      }
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_XOR_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_NOT_LOCAL_XOR_BASE + 256;
  }

  /// Returns the condition local carried by a resolved conditional opcode.
  public long resolvedLocalConditionalSource(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_SUB_BASE) {
      return opcode - STATEMENT_IF_LOCAL_ADD_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_XOR_BASE) {
      return opcode - STATEMENT_IF_LOCAL_SUB_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_BASE) {
      return opcode - STATEMENT_IF_LOCAL_XOR_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_SUB_BASE) {
      return opcode - STATEMENT_IF_NOT_LOCAL_ADD_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_XOR_BASE) {
      return opcode - STATEMENT_IF_NOT_LOCAL_SUB_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_BASE) {
      return opcode - STATEMENT_IF_NOT_LOCAL_XOR_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE) {
      return opcode - STATEMENT_IF_LOCAL_ASSIGN_BASE;
    }

    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE) {
      return opcode - STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE) {
      return opcode - STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE;
    }

    return opcode - STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE;
  }

  /// Checks whether an opcode carries a resolved signed-local binary source.
  public boolean resolvedLocalLongBinary(long opcode) {
    if (STATEMENT_LOCAL_LONG_ADD_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_LONG_XOR_BASE + 256) {
        return true;
      }
    }

    if (opcode < STATEMENT_LOCAL_LONG_MUL_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_MOD_BASE + 256;
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

    return opcode - STATEMENT_LOCAL_LONG_MOD_BASE;
  }

  /// Checks whether an opcode carries the left source of a signed-local pair.
  public boolean resolvedLocalLongPair(long opcode) {
    if (STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE + 256) {
        return true;
      }
    }

    if (opcode < STATEMENT_LOCAL_LONG_MUL_LOCALS_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE + 256;
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

    return opcode - STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE;
  }

  /// Returns the typed-local width required by one parsed statement.
  public long statementLocalCount(long opcode) {
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

    if (resolvedLocalLongLessThan(opcode)) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      return 4;
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

    if (opcode == STATEMENT_UPDATE_ADD) {
      return 2;
    }

    if (opcode == STATEMENT_UPDATE_SUB) {
      return 2;
    }

    if (opcode == STATEMENT_UPDATE_XOR) {
      return 2;
    }

    return 0;
  }

  /// Returns the initialized result local for a declaration statement.
  public long statementResultLocal(long opcode, long localBase) {
    if (opcode == STATEMENT_LOCAL_LONG) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      return localBase + 1;
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

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      return localBase + 3;
    }

    return -1;
  }

}
