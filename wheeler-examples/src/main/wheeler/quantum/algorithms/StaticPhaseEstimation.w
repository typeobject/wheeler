//! Resolves one exact binary eigenphase without sampled host control.
quantum class StaticPhaseEstimation {
  state long measured = 0;
  qreg phase = new qreg(2);

  /// Writes the phase bit of the negative unitary eigenvalue into the ancilla.
  ///
  /// - Adjoint: Reverses the controlled phase and both basis changes exactly.
  unitary void estimate() {
    H(phase[0]);
    CPhase(phase[1], phase[0], 3.141592653589793);
    H(phase[0]);
  }

  /// Checks the generated adjoint static estimator.
  theorem estimateAdjoint proves adjoint(estimate);

  /// Executes one exact one-bit static phase estimate.
  ///
  /// - Effects: Submits one bounded ideal-target task and records its measurement.
  entry void main() {
    prepare(phase, 2);
    estimate();
    measured = measure(phase);
    assert(measured == 3);
  }
}
