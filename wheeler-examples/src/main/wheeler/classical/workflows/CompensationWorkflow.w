//! Records compensation as a second effect without claiming inverse execution.

module examples.compensation.workflow;

classical class CompensationWorkflow {
  state long balance = 0;
  state long originalVisible = 0;
  state long compensationPrepared = 0;
  state long compensationVisible = 0;
  state long rejectedCompensations = 0;
  state long inverseClaim = 0;

  private void applyOriginal(long amount) {
    assert(0 < amount);
    assert(originalVisible == 0);
    balance += amount;
    originalVisible = 1;
  }

  private void prepareCompensation() {
    assert(originalVisible == 1);
    assert(compensationPrepared == 0);
    compensationPrepared = 1;
  }

  private void rejectCompensation() {
    assert(compensationPrepared == 1);
    assert(compensationVisible == 0);
    rejectedCompensations += 1;
  }

  private void acceptCompensation(long amount) {
    assert(compensationPrepared == 1);
    assert(compensationVisible == 0);
    assert(balance == amount);
    balance -= amount;
    compensationVisible = 1;
  }

  /// Executes one original effect, one rejected remedy, and one accepted remedy.
  ///
  /// - Effects: Mutates declared state while retaining separate original and compensation facts.
  entry void main() {
    applyOriginal(7);
    prepareCompensation();
    rejectCompensation();
    assert(balance == 7);
    acceptCompensation(7);
    assert(balance == 0);
    assert(inverseClaim == 0);
  }
}
