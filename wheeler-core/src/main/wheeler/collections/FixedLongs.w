//! Provides bounded reductions over fixed signed arrays and borrowed slices.

module wheeler.core.collections.fixed_longs;

classical class FixedLongs {
  /// Sums one four-element immutable signed array.
  public long total4(long[4] values) {
    long result = 0;
    for (long index = 0; index < 4; index += 1) limit 4 {
      result += values[index];
    }

    return result;
  }

  /// Sums the first two elements of an immutable borrowed signed slice.
  public long subtotal2(long[] values) {
    long result = 0;
    for (long index = 0; index < 2; index += 1) limit 2 {
      result += values[index];
    }

    return result;
  }
}
