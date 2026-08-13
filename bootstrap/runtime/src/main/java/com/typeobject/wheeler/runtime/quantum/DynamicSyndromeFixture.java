package com.typeobject.wheeler.runtime.quantum;

/** One bounded target-resident syndrome extraction, correction, and reset request. */
public record DynamicSyndromeFixture(
    boolean logicalBit,
    boolean dataBitFlipped,
    int rounds) {
  public static final int MAX_ROUNDS = 1_024;

  public DynamicSyndromeFixture {
    if (rounds < 1 || rounds > MAX_ROUNDS) {
      throw new IllegalArgumentException(
          "Dynamic syndrome rounds must be between 1 and " + MAX_ROUNDS);
    }
  }
}
