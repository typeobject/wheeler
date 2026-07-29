//! Signed and Boolean parameters/results, nested expressions, and typed static calls.
classical class FunctionValues {
  const long ADD_STEP_BOUND = 4;
  const long ADD_LEFT = 2;
  const long ADD_RIGHT = 3;
  const boolean EXPECTED_VALID = true;
  state long result = 0;

  long add(long left, long right) {
    return left + right;
  }

  /// Checks the declared `addBound` proof certificate.
  theorem addBound proves steps(add, ADD_STEP_BOUND);

  boolean same(boolean left, boolean right) {
    return left == right;
  }

  long triangular(long limit) {
    long i = 0;
    long sum = 0;
    while (i < limit) limit 8 {
      sum += i;
      i += 1;
    }

    return sum;
  }

  /// Runs the bounded `FunctionValues` fixture.
  ///
  /// - Effects: Mutates only the fixture's declared state.
  entry void main() {
    long base = add(ADD_LEFT, ADD_RIGHT);
    long total = triangular(base);
    boolean valid = same(total == 10, EXPECTED_VALID);
    boolean confirmed = valid == EXPECTED_VALID;
    if (confirmed) {
      result = total;
    } else {
      result = 0;
    }

    assert(result == 10);
  }
}
