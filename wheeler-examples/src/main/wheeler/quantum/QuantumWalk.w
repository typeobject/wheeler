//! Applies and uncomputes one coherent coined-walk step.
quantum class QuantumWalk {
  state long measured = 0;
  qreg walker = new qreg(2);

  /// Mixes the coin qubit and shifts the position when that coin is set.
  ///
  /// - Adjoint: Reverses the conditional shift and coin mixing exactly.
  unitary void walkStep() {
    H(walker[0]);
    CNOT(walker[0], walker[1]);
  }

  /// Checks the generated adjoint walk step.
  theorem walkAdjoint proves adjoint(walkStep);

  /// Executes one walk step and its adjoint before observation.
  ///
  /// - Effects: Submits one bounded ideal-target task and records its measurement.
  entry void main() {
    prepare(walker, 0);
    walkStep();
    reverse walkStep();
    measured = measure(walker);
    assert(measured == 0);
  }
}
