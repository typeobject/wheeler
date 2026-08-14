//! Resolves one phase bit and applies its correction inside a dynamic target region.
quantum class AdaptivePhaseEstimation {
  state long measured = 0;
  qreg phase = new qreg(2);

  /// Measures one exact phase bit, applies its correction, and resets the ancilla.
  dynamic void estimateAndCorrect() {
    prepare(phase, 2);
    H(phase[0]);
    CPhase(phase[1], phase[0], 3.141592653589793);
    H(phase[0]);
    measure(phase[0], 0);
    applyIf(0, true, X, phase[1]);
    reset(phase[0]);
  }

  /// Executes one target-resident adaptive phase estimate.
  ///
  /// - Effects: Submits one bounded target-resident dynamic region.
  entry void main() {
    estimateAndCorrect();
    measured = measure(phase);
    assert(measured == 0);
  }
}
