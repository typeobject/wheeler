//! Decodes resolved scalar helper returns that forward one call result.

module wheeler.compiler.resolved_return_call_kinds;

import wheeler.compiler.forwarded_helper_result_statements;

classical class ResolvedReturnCallKinds {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long RESOLVED_SOURCE_SQUARE = 65536;
  private const long RESOLVED_SOURCE_CUBE = 16777216;
  private const long RETURN_HELPER_CALL_END = STATEMENT_RETURN_HELPER_CALL_BASE
    + RESOLVED_SOURCE_COUNT;
  private const long RETURN_HELPER_CALL_TWO_END = STATEMENT_RETURN_HELPER_CALL_TWO_BASE
    + RESOLVED_SOURCE_COUNT * RESOLVED_SOURCE_COUNT;
  private const long RETURN_HELPER_CALL_THREE_END = STATEMENT_RETURN_HELPER_CALL_THREE_BASE
    + RESOLVED_SOURCE_CUBE;
  private const long RETURN_HELPER_CALL_FOUR_END = STATEMENT_RETURN_HELPER_CALL_FOUR_BASE
    + RESOLVED_SOURCE_CUBE * RESOLVED_SOURCE_COUNT;
  /// Removes the aligned two-argument opcode column from its first source.
  public const long RETURN_HELPER_CALL_TWO_SOURCE_OFFSET = 256;
  /// Caps final scalar-result forwarding without coupling it to helper parameter capacity.
  public const long MAX_FORWARDED_SCALAR_ARGUMENTS = 7;

  /// Returns the call arity, or minus one when the opcode is not this family.
  public long returnHelperCallArity(long opcode) {
    if (opcode < STATEMENT_RETURN_HELPER_CALL_BASE) {
      return -1;
    }

    if (opcode < RETURN_HELPER_CALL_END) {
      return 1;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_ZERO) {
      return 0;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_FIVE) {
      return 5;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_SIX) {
      return 6;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_SEVEN) {
      return 7;
    }

    if (opcode < STATEMENT_RETURN_HELPER_CALL_TWO_BASE) {
      return -1;
    }

    if (opcode < RETURN_HELPER_CALL_TWO_END) {
      return 2;
    }

    if (opcode < STATEMENT_RETURN_HELPER_CALL_THREE_BASE) {
      return -1;
    }

    if (opcode < RETURN_HELPER_CALL_THREE_END) {
      return 3;
    }

    if (opcode < STATEMENT_RETURN_HELPER_CALL_FOUR_BASE) {
      return -1;
    }

    if (opcode < RETURN_HELPER_CALL_FOUR_END) {
      return 4;
    }

    return -1;
  }

  /// Returns the first or sole encoded source of one forwarding helper call.
  public long returnHelperCallFirstSource(long opcode) {
    if (opcode < STATEMENT_RETURN_HELPER_CALL_TWO_BASE) {
      return opcode - STATEMENT_RETURN_HELPER_CALL_BASE;
    }

    if (opcode < RETURN_HELPER_CALL_TWO_END) {
      return opcode / RESOLVED_SOURCE_COUNT;
    }

    long packedThree = opcode - STATEMENT_RETURN_HELPER_CALL_THREE_BASE;
    if (packedThree < RESOLVED_SOURCE_CUBE) {
      return packedThree / RESOLVED_SOURCE_SQUARE;
    }

    long packedFour = opcode - STATEMENT_RETURN_HELPER_CALL_FOUR_BASE;
    return packedFour / RESOLVED_SOURCE_CUBE;
  }

  /// Returns the second source local of one resolved multi-argument helper call.
  public long returnHelperCallSecondSource(long opcode) {
    if (opcode < RETURN_HELPER_CALL_TWO_END) {
      return opcode % RESOLVED_SOURCE_COUNT;
    }

    long packedThree = opcode - STATEMENT_RETURN_HELPER_CALL_THREE_BASE;
    long quotientThree = packedThree / RESOLVED_SOURCE_COUNT;
    if (quotientThree < RESOLVED_SOURCE_SQUARE) {
      return quotientThree % RESOLVED_SOURCE_COUNT;
    }

    long packedFour = opcode - STATEMENT_RETURN_HELPER_CALL_FOUR_BASE;
    long quotientFour = packedFour / RESOLVED_SOURCE_SQUARE;
    return quotientFour % RESOLVED_SOURCE_COUNT;
  }

  /// Returns the third source local of one resolved wide helper call.
  public long returnHelperCallThirdSource(long opcode) {
    long packedThree = opcode - STATEMENT_RETURN_HELPER_CALL_THREE_BASE;
    if (packedThree < RESOLVED_SOURCE_CUBE) {
      return packedThree % RESOLVED_SOURCE_COUNT;
    }

    long packedFour = opcode - STATEMENT_RETURN_HELPER_CALL_FOUR_BASE;
    long quotientFour = packedFour / RESOLVED_SOURCE_COUNT;
    return quotientFour % RESOLVED_SOURCE_COUNT;
  }

  /// Returns the fourth source local of one resolved four-argument helper call.
  public long returnHelperCallFourthSource(long opcode) {
    long packed = opcode - STATEMENT_RETURN_HELPER_CALL_FOUR_BASE;
    return packed % RESOLVED_SOURCE_COUNT;
  }
}
