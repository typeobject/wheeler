//! Packs five through seven prior-local sources outside resolved opcode identities.

module wheeler.compiler.wide_return_sources;

classical class WideReturnSources {
  private const long SOURCE_RADIX = 256;
  private const long SOURCE_SQUARE = 65536;
  private const long SOURCE_CUBE = 16777216;

  /// Packs the first four source locals into the primary operand.
  public long packWideReturnFirstSources(long first, long second, long third, long fourth) {
    long firstPart = first * SOURCE_CUBE;
    long secondPart = second * SOURCE_SQUARE;
    long thirdPart = third * SOURCE_RADIX;
    long firstPair = firstPart + secondPart;
    long secondPair = thirdPart + fourth;
    return firstPair + secondPair;
  }

  /// Packs the final one through three source locals into the secondary operand.
  public long packWideReturnLastSources(long fifth, long sixth, long seventh) {
    long fifthPart = fifth * SOURCE_SQUARE;
    long sixthPart = sixth * SOURCE_RADIX;
    long prefix = fifthPart + sixthPart;
    return prefix + seventh;
  }

  /// Returns the first source from a wide primary operand.
  public long wideReturnFirstSource(long operand) {
    return operand / SOURCE_CUBE;
  }

  /// Returns the second source from a wide primary operand.
  public long wideReturnSecondSource(long operand) {
    long quotient = operand / SOURCE_SQUARE;
    return quotient % SOURCE_RADIX;
  }

  /// Returns the third source from a wide primary operand.
  public long wideReturnThirdSource(long operand) {
    long quotient = operand / SOURCE_RADIX;
    return quotient % SOURCE_RADIX;
  }

  /// Returns the fourth source from a wide primary operand.
  public long wideReturnFourthSource(long operand) {
    return operand % SOURCE_RADIX;
  }

  /// Returns the fifth source from a wide secondary operand.
  public long wideReturnFifthSource(long operand) {
    return operand / SOURCE_SQUARE;
  }

  /// Returns the sixth source from a wide secondary operand.
  public long wideReturnSixthSource(long operand) {
    long quotient = operand / SOURCE_RADIX;
    return quotient % SOURCE_RADIX;
  }

  /// Returns the seventh source from a wide secondary operand.
  public long wideReturnSeventhSource(long operand) {
    return operand % SOURCE_RADIX;
  }
}
