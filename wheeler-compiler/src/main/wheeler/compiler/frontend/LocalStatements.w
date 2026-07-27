//! Resolves and sizes bounded local declarations and assertions.

module wheeler.compiler.local_statements;

import wheeler.compiler.ir;
import wheeler.compiler.tokens;

classical class LocalStatements {
  /// Checks for a named signed-local and literal binary declaration.
  public boolean namedLongBinary(long opcode) {
    if (opcode == STATEMENT_LOCAL_LONG_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_SUB_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_LONG_XOR_NAMED;
  }

  /// Checks for a named binary declaration over two signed locals.
  public boolean namedLongPair(long opcode) {
    if (opcode == STATEMENT_LOCAL_LONG_ADD_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_SUB_LOCALS_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_LONG_XOR_LOCALS_NAMED;
  }

  private boolean declarationMatches(long opcode, boolean signed) {
    if (signed) {
      if (opcode == STATEMENT_LOCAL_LONG) {
        return true;
      }

      if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
        return true;
      }

      if (namedLongBinary(opcode)) {
        return true;
      }

      return namedLongPair(opcode);
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_LONG_LT_NAMED;
  }

  private long resolvePriorDeclaration(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long assertedName,
    boolean signed
  ) {
    if (previousCount < 0) {
      return -1;
    }

    if (MAX_MINIMAL_STATEMENTS < previousCount) {
      return -1;
    }

    long localBase = 0;
    long matchedLocal = -1;
    long matchCount = 0;
    long previous = 0;
    while (previous < previousCount) limit MAX_MINIMAL_STATEMENTS {
      long previousStart = previousStarts[previous];
      if (0 < previousStart) {
        long previousOpcode = statementOpcode(source, tokenStarts, tokenLengths, previousStart);
        if (declarationMatches(previousOpcode, signed)) {
          if (
            sameTokenText(source, tokenStarts, tokenLengths, previousStart + 1, assertedName)
          ) {
            matchedLocal = statementResultLocal(previousOpcode, localBase);
            matchCount += 1;
          }
        }

        localBase += statementLocalCount(previousOpcode);
      }

      previous += 1;
    }

    if (matchCount == 1) {
      return matchedLocal;
    }

    return -1;
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

  /// Checks whether an opcode carries a resolved signed-local binary source.
  public boolean resolvedLocalLongBinary(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_ADD_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_XOR_BASE + 256;
  }

  /// Returns the source local carried by a resolved signed binary opcode.
  public long resolvedLocalLongBinarySource(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_SUB_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_ADD_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_XOR_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_SUB_BASE;
    }

    return opcode - STATEMENT_LOCAL_LONG_XOR_BASE;
  }

  /// Checks whether an opcode carries the left source of a signed-local pair.
  public boolean resolvedLocalLongPair(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE + 256;
  }

  /// Returns the left source local carried by a resolved signed-local pair opcode.
  public long resolvedLocalLongPairSource(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE;
    }

    return opcode - STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE;
  }

  /// Resolves named signed operations into opcodes carrying local indices.
  public long sequenceStatementOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (opcode == STATEMENT_ASSERT_NAMED_LONG) {
      long local = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        true
      );
      if (-1 < local) {
        return STATEMENT_ASSERT_LOCAL_LONG_BASE + local;
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      long sourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < sourceLocal) {
        return STATEMENT_LOCAL_LONG_COPY_BASE + sourceLocal;
      }

      return -1;
    }

    if (namedLongBinary(opcode)) {
      long binarySourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < binarySourceLocal) {
        long base = STATEMENT_LOCAL_LONG_ADD_BASE;
        if (opcode == STATEMENT_LOCAL_LONG_SUB_NAMED) {
          base = STATEMENT_LOCAL_LONG_SUB_BASE;
        }

        if (opcode == STATEMENT_LOCAL_LONG_XOR_NAMED) {
          base = STATEMENT_LOCAL_LONG_XOR_BASE;
        }

        return base + binarySourceLocal;
      }

      return -1;
    }

    if (namedLongPair(opcode)) {
      long pairSourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < pairSourceLocal) {
        long pairBase = STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE;
        if (opcode == STATEMENT_LOCAL_LONG_SUB_LOCALS_NAMED) {
          pairBase = STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE;
        }

        if (opcode == STATEMENT_LOCAL_LONG_XOR_LOCALS_NAMED) {
          pairBase = STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE;
        }

        return pairBase + pairSourceLocal;
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      long lessThanSourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < lessThanSourceLocal) {
        return STATEMENT_LOCAL_LONG_LT_BASE + lessThanSourceLocal;
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      long equalitySignedLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      long equalityBooleanLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        false
      );
      if (-1 < equalitySignedLeft) {
        if (equalityBooleanLeft < 0) {
          return STATEMENT_LOCAL_LONG_EQ_BASE + equalitySignedLeft;
        }
      }

      if (-1 < equalityBooleanLeft) {
        if (equalitySignedLeft < 0) {
          return STATEMENT_LOCAL_BOOLEAN_EQ_BASE + equalityBooleanLeft;
        }
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      long booleanSourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        false
      );
      if (-1 < booleanSourceLocal) {
        return STATEMENT_LOCAL_BOOLEAN_COPY_BASE + booleanSourceLocal;
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      long negatedSourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 4,
        false
      );
      if (-1 < negatedSourceLocal) {
        return STATEMENT_LOCAL_BOOLEAN_NOT_BASE + negatedSourceLocal;
      }

      return -1;
    }

    return opcode;
  }

  /// Checks whether a resolved statement operand names a valid prior local.
  public boolean sequenceOperandValid(long opcode, long operand) {
    if (opcode < 0) {
      return false;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return -1 < operand;
    }

    if (resolvedLocalLongPair(opcode)) {
      return -1 < operand;
    }

    if (resolvedLocalEquality(opcode)) {
      return -1 < operand;
    }

    if (resolvedLocalLongLessThan(opcode)) {
      return -1 < operand;
    }

    return true;
  }

  /// Resolves one statement operand against a bounded prior-declaration table.
  public long sequenceStatementOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (opcode == STATEMENT_LOCAL_LONG_LT_NAMED) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      long operandSignedLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      long operandSignedRight = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 6,
        true
      );
      if (-1 < operandSignedLeft) {
        if (-1 < operandSignedRight) {
          return operandSignedRight;
        }
      }

      long operandBooleanLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        false
      );
      long operandBooleanRight = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 6,
        false
      );
      if (-1 < operandBooleanLeft) {
        if (-1 < operandBooleanRight) {
          return operandBooleanRight;
        }
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      return 0;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      return 0;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      return 0;
    }

    if (namedLongPair(opcode)) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        false
      );
    }

    return statementOperand(source, tokenStarts, tokenLengths, statementStart);
  }

  /// Returns the typed-local width required by one parsed statement.
  public long statementLocalCount(long opcode) {
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

  /// Decodes the canonical operand carried by one validated statement.
  public long statementOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    long operandToken = statementOperandToken(source, tokenStarts, tokenLengths, statementStart);
    boolean booleanLiteral = opcode == STATEMENT_LOCAL_BOOLEAN;
    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      booleanLiteral = true;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      booleanLiteral = true;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      booleanLiteral = true;
    }

    if (booleanLiteral) {
      long literal = tokenHash(source, tokenStarts, tokenLengths, operandToken);
      if (literal == TOKEN_TRUE) {
        return 1;
      }

      return 0;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return -1;
    }

    return parsedSignedNumber(source, tokenStarts, tokenLengths, operandToken);
  }

  /// Returns the operand-token offset for one bounded statement.
  public long statementOperandToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (opcode == STATEMENT_ASSIGN) {
      return statementStart + 2;
    }

    if (opcode == STATEMENT_ASSERT_EQ) {
      return statementStart + 5;
    }

    if (opcode == STATEMENT_ASSERT_NAMED_LONG) {
      return statementStart + 5;
    }

    if (namedLongBinary(opcode)) {
      return statementStart + 5;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return statementStart + 4;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      return statementStart + 2;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      return statementStart + 3;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return statementStart + 2;
    }

    return statementStart + 3;
  }
}
