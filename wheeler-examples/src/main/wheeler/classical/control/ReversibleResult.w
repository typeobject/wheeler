//! Demonstrates one history-independent reversible signed result.
classical class ReversibleResult {
  state long observed = 0;

  /// Exchanges a caller-owned vacant result slot with `Holding(-1)`.
  ///
  /// - Inverse: Preserves the signed argument, checks the held value, and restores vacancy.
  rev long minusOne(long witness) {
    return -1;
  }

  /// Checks the generated result-slot inverse.
  theorem minusOneInverse proves inverse(minusOne);

  /// Calls the reversible value relation through its implicit result slot.
  ///
  /// - Effects: Publishes the returned signed value in fixture state.
  entry void main() {
    long value = minusOne(7);
    observed = value;
    assert(observed == -1);
  }
}
