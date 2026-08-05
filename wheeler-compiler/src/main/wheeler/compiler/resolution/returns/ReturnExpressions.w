//! Resolves typed scalar return expressions in the bootstrap source profile.

module wheeler.compiler.return_expressions;

import wheeler.compiler.class_constants;
import wheeler.compiler.local_resolution;
import wheeler.compiler.return_opcode_kinds;
import wheeler.compiler.statement_forms;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;

classical class ReturnExpressions {
  /// Carries one optional scalar return after exact typed-name resolution.
  public record ReturnExpressionResolution(
    long opcode,
    long rightOperand,
    boolean primaryOperand,
    boolean applies,
    boolean valid
  ) {}

  private ReturnExpressionResolution notApplicable() {
    return new ReturnExpressionResolution(0, 0, false, false, true);
  }

  private ReturnExpressionResolution invalid() {
    return new ReturnExpressionResolution(0, 0, false, true, false);
  }

  private long comparisonRightToken(long statementStart, long opcode) {
    if (returnSignedLessThanStatement(opcode)) {
      return statementStart + 3;
    }

    return statementStart + 4;
  }

  private ReturnExpressionResolution binaryRight(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long opcode
  ) {
    long rightToken = statementStart + 3;
    long right = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      rightToken,
      true
    );
    if (-1 < right) {
      return new ReturnExpressionResolution(opcode, right, true, true, true);
    }

    ConstantResolution constant = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      rightToken,
      true
    );
    if (constant.valid == false) {
      return invalid();
    }

    return new ReturnExpressionResolution(
      literalReturnOpcode(opcode),
      constant.value,
      true,
      true,
      true
    );
  }

  private ReturnExpressionResolution literalRight(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long rightToken,
    long opcode
  ) {
    if (returnComparisonSigned(opcode)) {
      return new ReturnExpressionResolution(
        opcode,
        parsedSignedNumber(source, tokenStarts, tokenLengths, rightToken),
        false,
        true,
        true
      );
    }

    long literal = tokenHash(source, tokenStarts, tokenLengths, rightToken);
    if (literal == TOKEN_TRUE) {
      return new ReturnExpressionResolution(opcode, 1, false, true, true);
    }

    return new ReturnExpressionResolution(opcode, 0, false, true, literal == TOKEN_FALSE);
  }

  /// Resolves one signed arithmetic or typed scalar comparison return.
  public ReturnExpressionResolution resolveReturnExpression(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long sourceOpcode
  ) {
    if (returnLocalPairStatement(sourceOpcode)) {
      return binaryRight(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount,
        sourceOpcode
      );
    }

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
      return new ReturnExpressionResolution(opcode, right, false, true, true);
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

    return new ReturnExpressionResolution(
      literalComparisonOpcode(opcode),
      constant.value,
      false,
      true,
      true
    );
  }
}
