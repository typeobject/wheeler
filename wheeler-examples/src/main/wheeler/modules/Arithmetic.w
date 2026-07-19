//! Supplies nominal arithmetic helpers for module-linking fixtures.

module examples.arithmetic;

classical class Arithmetic {
  /// Defines immutable `Pair` values for this module.
  public record Pair(long left, long right) {}

  private long add(long left, long right) {
    return left + right;
  }

  /// Adds a bounded signed value to itself.
  public long twice(long value) {
    return add(value, value);
  }

  /// Constructs a pair containing adjacent signed values.
  public Pair pair(long value) {
    return new Pair(value, twice(value));
  }

  /// Returns the right field of the final pair in a fixed array.
  public long lastRight(Pair[2] values) {
    return values[1].right;
  }

  /// Sums right fields across a bounded pair slice.
  public long rightTotal(Pair[] values, long count) {
    long result = 0;
    for (long index = 0; index < count; index += 1) limit 2 {
      result += values[index].right;
    }

    return result;
  }
}
