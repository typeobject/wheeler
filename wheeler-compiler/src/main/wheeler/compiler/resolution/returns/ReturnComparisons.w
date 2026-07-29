//! Resolves typed scalar comparison returns in the bootstrap source profile.

module wheeler.compiler.return_comparisons;

import wheeler.compiler.class_constants;
import wheeler.compiler.local_resolution;
import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class ReturnComparisons {
  /// Carries one optional comparison return after exact typed-name resolution.
  public record ReturnComparisonResolution(
    long opcode,
    long rightOperand,
    boolean applies,
    boolean valid
  ) {}

  private ReturnComparisonResolution notApplicable() {
    return new ReturnComparisonResolution(0, 0, false, true);
  }

  private ReturnComparisonResolution invalid() {
    return new ReturnComparisonResolution(0, 0, true, false);
  }

  private long comparisonRightToken(long statementStart, long opcode) {
    if (returnSignedLessThanStatement(opcode)) {
      return statementStart + 3;
    }

    return statementStart + 4;
  }

  private long signedAmbiguousOpcode(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED) {
      return STATEMENT_RETURN_SIGNED_EQ_LOCAL_NAMED;
    }

    return STATEMENT_RETURN_SIGNED_NE_LOCAL_NAMED;
  }

  private long literalComparisonOpcode(long opcode) {
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

  private ReturnComparisonResolution literalRight(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long rightToken,
    long opcode
  ) {
    if (returnComparisonSigned(opcode)) {
      return new ReturnComparisonResolution(
        opcode,
        parsedSignedNumber(source, tokenStarts, tokenLengths, rightToken),
        true,
        true
      );
    }

    long literal = tokenHash(source, tokenStarts, tokenLengths, rightToken);
    if (literal == TOKEN_TRUE) {
      return new ReturnComparisonResolution(opcode, 1, true, true);
    }

    return new ReturnComparisonResolution(opcode, 0, true, literal == TOKEN_FALSE);
  }

  /// Resolves one scalar comparison return and its right operand.
  public ReturnComparisonResolution resolveReturnComparison(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long sourceOpcode
  ) {
    if (returnComparisonStatement(sourceOpcode) == false) {
      return notApplicable();
    }

    long opcode = sourceOpcode;
    boolean signed = returnComparisonSigned(opcode);
    boolean ambiguous = opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED;
    if (opcode == STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED) {
      ambiguous = true;
    }

    long signedLeft = -1;
    long booleanLeft = -1;
    if (ambiguous) {
      signedLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        true
      );
      booleanLeft = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        false
      );
      if (-1 < signedLeft) {
        if (booleanLeft < 0) {
          signed = true;
          opcode = signedAmbiguousOpcode(opcode);
        } else {
          return invalid();
        }
      } else {
        if (-1 < booleanLeft) {
          signed = false;
        } else {
          return invalid();
        }
      }
    } else {
      long left = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        signed
      );
      if (left < 0) {
        return invalid();
      }
    }

    long rightToken = comparisonRightToken(statementStart, opcode);
    if (returnComparisonLocalRight(opcode) == false) {
      return literalRight(source, tokenStarts, tokenLengths, rightToken, opcode);
    }

    long right = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      rightToken,
      signed
    );
    if (-1 < right) {
      return new ReturnComparisonResolution(opcode, right, true, true);
    }

    ConstantResolution constant = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      rightToken,
      signed
    );
    if (constant.valid == false) {
      return invalid();
    }

    return new ReturnComparisonResolution(
      literalComparisonOpcode(opcode),
      constant.value,
      true,
      true
    );
  }
}
