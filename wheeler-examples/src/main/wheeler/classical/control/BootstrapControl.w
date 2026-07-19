//! Typed locals, checked expressions, branches, and a source-bounded loop.
classical class BootstrapControl {
  state long sum = 0;
  state long branch = 0;

  /// Runs the bounded `BootstrapControl` fixture.
  ///
  /// - Effects: Mutates only the fixture's declared state.
  entry void main() {
    for (long i = 0; i < 5; i += 1) limit 5 {
      sum += i;
    }

    boolean complete = sum == 10;
    if (complete) {
      branch = 1;
    } else {
      branch = 2;
    }

    assert(sum == 10);
    assert(branch == 1);
  }
}
