//! Estimates one known half-amplitude with a bounded phase-kickback round.
quantum class AmplitudeEstimation {
  const long QUBITS = 2;
  const long PLANNED_SHOTS = 4096;

  state long measured = 0;
  state long circuitApplications = 2;
  state long plannedShots = PLANNED_SHOTS;
  qreg estimate = new qreg(QUBITS);

  /// Prepares an exact one-half good-state probability.
  ///
  /// - Adjoint: Restores basis zero exactly.
  unitary void prepareAmplitude() {
    H(estimate[1]);
  }

  /// Correlates one phase bit with the prepared good-state component.
  ///
  /// - Adjoint: Removes phase kickback and restores the prepared amplitude.
  unitary void estimateRound() {
    H(estimate[0]);
    CPhase(estimate[1], estimate[0], 3.141592653589793);
    H(estimate[0]);
  }

  /// Checks preparation cleanup.
  theorem preparationAdjoint proves adjoint(prepareAmplitude);

  /// Checks estimation-round cleanup.
  theorem estimationAdjoint proves adjoint(estimateRound);

  /// Executes one exact ideal-target estimator sample.
  ///
  /// - Effects: Submits one bounded static task and records its joint outcome.
  entry void main() {
    prepare(estimate, 0);
    prepareAmplitude();
    estimateRound();
    measured = measure(estimate);
  }
}
