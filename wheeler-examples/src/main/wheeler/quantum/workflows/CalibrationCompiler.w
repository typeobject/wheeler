//! Closes one semantic circuit against an exact immutable calibration epoch.
classical class CalibrationCompiler {
  state long requiredEpoch = 7;
  state long measuredEpoch = 7;
  state long staleMeasuredEpoch = 6;
  state long requestedGateKinds = 2;
  state long samplesPerGate = 128;
  state long compiled = 0;
  state long acceptedOlderEpoch = 0;
  state long durationCycles = 0;
  state long unionErrorBound = 0;

  /// Applies the exact-epoch calibration plan.
  ///
  /// - Inverse: Removes the plan and restores every derived resource field.
  rev void acceptExactEpoch() {
    compiled ^= 1;
    durationCycles += 7;
    unionErrorBound += 40;
  }

  /// Runs the bounded `CalibrationCompiler` fixture.
  ///
  /// - Effects: Commits the accepted exact-epoch plan.
  entry void main() {
    assert(requiredEpoch == measuredEpoch);
    assert(staleMeasuredEpoch < requiredEpoch);
    assert(requestedGateKinds == 2);
    assert(samplesPerGate == 128);
    assert(acceptedOlderEpoch == 0);
    acceptExactEpoch();
    assert(compiled == 1);
    assert(durationCycles == 7);
    assert(unionErrorBound == 40);
    commit();
  }
}
