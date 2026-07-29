//! Resolves typed scalar assertions in the bootstrap source profile.

module wheeler.compiler.assertion_resolution;

import wheeler.compiler.class_constants;
import wheeler.compiler.local_resolution;
import wheeler.compiler.tokens;

classical class AssertionResolution {
  /// Carries one optional assertion after exact typed-name resolution.
  public record ResolvedAssertion(long opcode, long operand, boolean applies, boolean valid) {}

  private ResolvedAssertion notApplicable() {
    return new ResolvedAssertion(0, 0, false, true);
  }

  private ResolvedAssertion invalid() {
    return new ResolvedAssertion(0, 0, true, false);
  }

  private ResolvedAssertion signedEquality(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long left,
    long rightToken
  ) {
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
      return new ResolvedAssertion(STATEMENT_ASSERT_LONG_PAIR_BASE + left, right, true, true);
    }

    ConstantResolution constant = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      rightToken,
      true
    );
    if (constant.valid) {
      return new ResolvedAssertion(
        STATEMENT_ASSERT_LOCAL_LONG_BASE + left,
        constant.value,
        true,
        true
      );
    }

    return invalid();
  }

  private ResolvedAssertion booleanEquality(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long left,
    long rightToken
  ) {
    long right = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      rightToken,
      false
    );
    if (-1 < right) {
      return new ResolvedAssertion(STATEMENT_ASSERT_BOOLEAN_PAIR_BASE + left, right, true, true);
    }

    ConstantResolution constant = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      rightToken,
      false
    );
    if (constant.valid) {
      return new ResolvedAssertion(
        STATEMENT_ASSERT_BOOLEAN_LITERAL_BASE + left,
        constant.value,
        true,
        true
      );
    }

    return invalid();
  }

  private ResolvedAssertion equality(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long signedLeft = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 2,
      true
    );
    long booleanLeft = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 2,
      false
    );
    if (-1 < signedLeft) {
      if (booleanLeft < 0) {
        return signedEquality(
          source,
          tokenStarts,
          tokenLengths,
          previousStarts,
          previousCount,
          signedLeft,
          statementStart + 5
        );
      }

      return invalid();
    }

    if (-1 < booleanLeft) {
      return booleanEquality(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        booleanLeft,
        statementStart + 5
      );
    }

    return invalid();
  }

  private ResolvedAssertion ordering(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long left = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 2,
      true
    );
    if (left < 0) {
      return invalid();
    }

    long right = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 4,
      true
    );
    if (-1 < right) {
      return new ResolvedAssertion(STATEMENT_ASSERT_LONG_LT_BASE + left, right, true, true);
    }

    ConstantResolution constant = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      statementStart + 4,
      true
    );
    if (constant.valid) {
      return new ResolvedAssertion(
        STATEMENT_ASSERT_LONG_LT_LITERAL_BASE + left,
        constant.value,
        true,
        true
      );
    }

    return invalid();
  }

  /// Resolves one named scalar equality or ordering assertion.
  public ResolvedAssertion resolveAssertion(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long sourceOpcode
  ) {
    if (sourceOpcode == STATEMENT_ASSERT_LOCAL_PAIR_NAMED) {
      return equality(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount
      );
    }

    if (sourceOpcode == STATEMENT_ASSERT_LONG_LT_NAMED) {
      return ordering(
        source,
        tokenStarts,
        tokenLengths,
        statementStart,
        previousStarts,
        previousCount
      );
    }

    return notApplicable();
  }
}
