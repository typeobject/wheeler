//! Records one bounded delayed-heralding branch without claiming remote rollback.

classical class DistributedBell {
  state long requestedCycle = 10;
  state long deadlineCycle = 20;
  state long heraldCycle = 19;
  state long sessionState = 0;
  state long localDiscarded = 0;
  state long remoteDestroyed = 0;

  /// Accepts the fixture's exact delayed herald.
  ///
  /// - Inverse: Returns the session to its requested state.
  rev void acceptHerald() {
    sessionState += 1;
  }

  /// Discards only the local terminal branch.
  ///
  /// - Inverse: Restores local access to the recorded heralded branch.
  rev void discardLocalBranch() {
    localDiscarded += 1;
  }

  /// Runs the bounded distributed-session fixture.
  ///
  /// - Effects: Mutates only the fixture's declared session state.
  entry void main() {
    assert(requestedCycle < heraldCycle);
    assert(heraldCycle < deadlineCycle + 1);
    acceptHerald();
    discardLocalBranch();
    assert(sessionState == 1);
    assert(localDiscarded == 1);
    assert(remoteDestroyed == 0);
  }
}
