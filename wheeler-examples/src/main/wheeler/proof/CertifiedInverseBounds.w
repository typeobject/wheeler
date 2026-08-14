//! Checks inverse-law and static resource-bound certificates in one executable.
classical class CertifiedInverseBounds {
  const long SUCCESSOR_STEP_BOUND = 4;
  state long value = 0;
  state long observed = 0;
  state long successor = 0;

  /// Applies one reversible state increment.
  ///
  /// - Inverse: Applies the compiler-generated decrement.
  rev void increment() {
    value += 1;
  }

  /// Checks the generated inverse body.
  theorem incrementInverse proves inverse(increment);

  long next(long input) {
    return input + 1;
  }

  /// Checks the straight-line successor step bound.
  theorem nextBound proves steps(next, SUCCESSOR_STEP_BOUND);

  /// Executes both certified routines and restores reversible state.
  ///
  /// - Effects: Mutates only fixture state.
  entry void main() {
    increment();
    observed = value;
    reverse increment();
    successor = next(4);
    assert(observed == 1);
    assert(value == 0);
    assert(successor == 5);
  }
}
