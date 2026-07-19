//! Bounded recursive value calls over signed frame parameters and results.
classical class RecursiveValue {
  state long result = 0;

  long depth(long remaining) {
    long value = 0;
    if (0 < remaining) {
      value = depth(remaining - 1) + 1;
    }

    return value;
  }

  /// Runs the bounded `RecursiveValue` fixture.
  ///
  /// - Effects: Mutates only the fixture's declared state.
  entry void main() {
    long measuredDepth = depth(6);
    result = measuredDepth;
    assert(result == 6);
  }
}
