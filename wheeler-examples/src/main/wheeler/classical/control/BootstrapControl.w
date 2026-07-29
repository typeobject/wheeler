//! Typed locals, checked expressions, branches, and a source-bounded loop.
classical class BootstrapControl {
  const long LOOP_BOUND = 5;
  const long LOOP_STEP = 1;
  const long EXPECTED_SUM = 10;
  const long COMPLETE_BRANCH = 1;
  const long INCOMPLETE_BRANCH = 2;
  state long sum = 0;
  state long branch = 0;

  /// Runs the bounded `BootstrapControl` fixture.
  ///
  /// - Effects: Mutates only the fixture's declared state.
  entry void main() {
    for (long i = 0; i < LOOP_BOUND; i += LOOP_STEP) limit LOOP_BOUND {
      sum += i;
    }

    boolean complete = sum == EXPECTED_SUM;
    if (complete) {
      branch = COMPLETE_BRANCH;
    } else {
      branch = INCOMPLETE_BRANCH;
    }

    assert(sum == EXPECTED_SUM);
    assert(branch == COMPLETE_BRANCH);
  }
}
