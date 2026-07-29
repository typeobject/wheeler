//! Demonstrates one history-independent reversible signed result.
classical class ReversibleResult {
  state long observed = 0;

  /// Exchanges a caller-owned vacant result slot with the preserved signed argument.
  ///
  /// - Inverse: Checks the held copy, preserves the source, and restores exact vacancy.
  rev long preserve(long witness) {
    return witness;
  }

  /// Checks the generated preserved-source inverse.
  theorem preserveInverse proves inverse(preserve);

  /// Calls the reversible value relation through its implicit result slot.
  ///
  /// - Effects: Publishes the returned signed value in fixture state.
  entry void main() {
    long value = preserve(7);
    observed = value;
    assert(observed == 7);
  }
}
