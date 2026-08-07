//! Packs five prior-local sources outside the resolved opcode identity.

module wheeler.compiler.five_argument_returns;

classical class FiveArgumentReturns {
  private const long SOURCE_RADIX = 256;
  private const long SOURCE_SQUARE = 65536;

  /// Packs the first three source locals into the primary operand.
  public long packFiveReturnFirstSources(long first, long second, long third) {
    long firstPart = first * SOURCE_SQUARE;
    long secondPart = second * SOURCE_RADIX;
    long prefix = firstPart + secondPart;
    return prefix + third;
  }

  /// Packs the fourth and fifth source locals into the secondary operand.
  public long packFiveReturnLastSources(long fourth, long fifth) {
    long prefix = fourth * SOURCE_RADIX;
    return prefix + fifth;
  }

  /// Returns the first source from a five-argument primary operand.
  public long fiveReturnFirstSource(long operand) {
    return operand / SOURCE_SQUARE;
  }

  /// Returns the second source from a five-argument primary operand.
  public long fiveReturnSecondSource(long operand) {
    long quotient = operand / SOURCE_RADIX;
    return quotient % SOURCE_RADIX;
  }

  /// Returns the third source from a five-argument primary operand.
  public long fiveReturnThirdSource(long operand) {
    return operand % SOURCE_RADIX;
  }

  /// Returns the fourth source from a five-argument secondary operand.
  public long fiveReturnFourthSource(long operand) {
    return operand / SOURCE_RADIX;
  }

  /// Returns the fifth source from a five-argument secondary operand.
  public long fiveReturnFifthSource(long operand) {
    return operand % SOURCE_RADIX;
  }
}
