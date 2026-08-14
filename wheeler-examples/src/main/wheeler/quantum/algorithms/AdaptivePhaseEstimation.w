//! Resolves two phase rounds and applies corrections inside a dynamic target region.
quantum class AdaptivePhaseEstimation {
  state long measured = 0;
  qreg phase = new qreg(3);

  /// Measures two target-resident phase rounds with result-fed corrections.
  dynamic void estimateAndCorrect() {
    prepare(phase, 4);
    H(phase[0]);
    CPhase(phase[2], phase[0], 3.141592653589793);
    H(phase[0]);
    measure(phase[0], 0);
    applyIf(0, true, Z, phase[2]);
    reset(phase[0]);
    H(phase[1]);
    CPhase(phase[2], phase[1], 6.283185307179586);
    H(phase[1]);
    measure(phase[1], 1);
    applyIf(1, false, X, phase[2]);
    reset(phase[1]);
  }

  /// Executes two target-resident adaptive phase rounds.
  ///
  /// - Effects: Submits one bounded dynamic region and observes only final state.
  entry void main() {
    estimateAndCorrect();
    measured = measure(phase);
    assert(measured == 0);
  }
}
