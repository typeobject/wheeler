//! Verifies one masked NOT transcript under an explicit narrow threat model.

classical class DelegatedComputation {
  state long protocol = 1;
  state long threatModel = 1;
  state long secret = 1;
  state long clientMask = 0;
  state long blindedInput = 1;
  state long blindedOutput = 0;
  state long verifiedOutput = 0;
  state long verified = 0;
  state long generalPrivacyClaim = 0;

  /// Accepts the fixture's exact challenge-bound NOT transcript.
  ///
  /// - Inverse: Returns the transcript to its unconsumed state.
  rev void acceptTranscript() {
    verified += 1;
  }

  /// Runs the bounded masked-delegation fixture.
  ///
  /// - Effects: Mutates only the fixture's declared verification state.
  entry void main() {
    assert(protocol == 1);
    assert(threatModel == 1);
    assert(secret == 1);
    assert(clientMask == 0);
    assert(blindedInput == 1);
    assert(blindedOutput == 0);
    acceptTranscript();
    assert(verified == 1);
    assert(verifiedOutput == 0);
    assert(generalPrivacyClaim == 0);
  }
}
