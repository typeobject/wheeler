//! Supplies fixed-array and slice helpers for module-linking fixtures.

module examples.collections;
classical class Collections {
    /// Returns the middle element of a three-word array.
    public long middle(long[3] values) {
        return values[1];
    }

    /// Sums a bounded prefix of a signed slice.
    public long total(long[] values, long count) {
        long result = 0;
        for (long index = 0; index < count; index += 1) limit 3 {
            result += values[index];
        }
        return result;
    }
}
