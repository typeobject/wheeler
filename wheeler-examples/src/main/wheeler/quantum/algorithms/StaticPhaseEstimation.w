//! Resolves one exact two-bit eigenphase without sampled host control.
quantum class StaticPhaseEstimation {
  state long measured = 0;
  qreg phase = new qreg(3);

  /// Applies two controlled powers and the exact two-bit inverse transform.
  ///
  /// The low register bits estimate phase three quarters while bit two holds
  /// the unitary eigenstate.
  ///
  /// - Adjoint: Reverses both controlled powers and the inverse transform.
  unitary void estimate() {
    H(phase[0]);
    H(phase[1]);
    CPhase(phase[2], phase[0], 9.42477796076938);
    CPhase(phase[2], phase[1], 4.71238898038469);
    Swap(phase[0], phase[1]);
    H(phase[1]);
    CPhase(phase[1], phase[0], -1.5707963267948966);
    H(phase[0]);
  }

  /// Checks the generated adjoint static estimator.
  theorem estimateAdjoint proves adjoint(estimate);

  /// Executes one exact two-bit static phase estimate.
  ///
  /// - Effects: Submits one bounded ideal-target task and records its measurement.
  entry void main() {
    prepare(phase, 4);
    estimate();
    measured = measure(phase);
    assert(measured == 7);
  }
}
