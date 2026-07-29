//! Demonstrates one history-independent reversible signed result.
classical class ReversibleResult {
  state long observed = 0;

  /// Exchanges a caller-owned vacant result slot with one checked computed value.
  ///
  /// - Inverse: Checks the held result, preserves the source, and restores exact vacancy.
  rev long addEight(long ignored, long value) {
    return value + 8;
  }

  /// Checks the generated computed-result inverse.
  theorem addEightInverse proves inverse(addEight);

  /// Calls the reversible value relation through its implicit result slot.
  ///
  /// - Effects: Publishes the returned signed value in fixture state.
  entry void main() {
    long value = addEight(1, 34);
    observed = value;
    assert(observed == 42);
  }
}
