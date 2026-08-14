//! Estimates one known half-amplitude with a bounded phase-kickback round.
quantum class AmplitudeEstimation {
  const long QUBITS = 2;
  const long PLANNED_SHOTS = 4096;

  state long measured = 0;
  state long circuitApplications = 4;
  state long plannedShots = PLANNED_SHOTS;
  qreg estimate = new qreg(QUBITS);

  /// Prepares an exact one-half good-state probability.
  ///
  /// - Adjoint: Restores basis zero exactly.
  unitary void prepareAmplitude() {
    H(estimate[1]);
  }

  /// Applies one controlled coherent amplitude-operator power.
  ///
  /// - Adjoint: Removes one half-turn phase contribution.
  unitary void controlledAmplitudePower() {
    CPhase(estimate[1], estimate[0], 1.5707963267948966);
  }

  /// Correlates one phase bit through two amplitude-operator powers.
  ///
  /// - Adjoint: Removes both called powers and restores the prepared amplitude.
  unitary void estimateRound() {
    H(estimate[0]);
    controlledAmplitudePower();
    controlledAmplitudePower();
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
