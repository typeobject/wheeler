//! Demonstrates one history-independent reversible signed result.
classical class ReversibleResult {
  state long observed = 0;

  /// Exchanges a caller-owned vacant result slot with one checked computed value.
  ///
  /// - Inverse: Checks the held result, preserves the source, and restores exact vacancy.
  rev long add(long left, long right) {
    return left + right;
  }

  /// Checks the generated computed-result inverse.
  theorem addInverse proves inverse(add);

  /// Calls the reversible value relation through its implicit result slot.
  ///
  /// - Effects: Publishes the returned signed value in fixture state.
  entry void main() {
    long value = add(34, 8);
    observed = value;
    assert(observed == 42);
  }
}
