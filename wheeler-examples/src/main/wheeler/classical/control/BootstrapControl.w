//! Typed locals, checked expressions, branches, and a source-bounded loop.
classical class BootstrapControl {
  const long LOOP_STEP = 1;
  const long LOOP_BOUND = LOOP_STEP * 5;
  const long EXPECTED_SUM = LOOP_BOUND * (LOOP_BOUND - LOOP_STEP) / 2;
  const long COMPLETE_BRANCH = LOOP_STEP;
  const long INCOMPLETE_BRANCH = COMPLETE_BRANCH + LOOP_STEP;
  const long INITIAL_SUM = LOOP_STEP - LOOP_STEP;
  const long INITIAL_BRANCH = INITIAL_SUM;
  state long sum = INITIAL_SUM;
  state long branch = INITIAL_BRANCH;

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
