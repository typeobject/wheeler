//! Finds one marked basis state with a single exact Grover iteration.
quantum class GroverSearch {
  state long measured = 0;
  qreg search = new qreg(2);

  /// Marks basis state three and reflects the uniform state about its mean.
  ///
  /// - Adjoint: Applies the exact reversed gate sequence.
  unitary void groverIteration() {
    H(search[0]);
    H(search[1]);
    CPhase(search[0], search[1], 3.141592653589793);
    H(search[0]);
    H(search[1]);
    X(search[0]);
    X(search[1]);
    CPhase(search[0], search[1], 3.141592653589793);
    X(search[0]);
    X(search[1]);
    H(search[0]);
    H(search[1]);
  }

  /// Checks the generated adjoint search iteration.
  theorem groverAdjoint proves adjoint(groverIteration);

  /// Executes one four-element exact search.
  ///
  /// - Effects: Submits one bounded ideal-target task and records its measurement.
  entry void main() {
    prepare(search, 0);
    groverIteration();
    measured = measure(search);
    assert(measured == 3);
  }
}
