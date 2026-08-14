//! The same finite modular permutation executes classically and coherently.
hybrid class CoherentOracle {
  state long value = 0;
  state long measured = 0;
  qreg q = new qreg(3);

  /// Adds three to the finite coherent basis.
  ///
  /// - Inverse: Subtracts three modulo the explicit coherent register width.
  /// - Coherent: Preserves amplitudes while permuting all eight basis states.
  coherent rev void addThree() {
    value += 3;
  }

  /// Applies modular addition and marks low-bit comparison state three.
  ///
  /// - Adjoint: Removes the comparison phase and modular addition exactly.
  unitary void oracle() {
    q.apply(addThree);
    CPhase(q[0], q[1], 3.141592653589793);
  }

  /// Checks the generated coherent oracle adjoint.
  theorem oracleAdjoint proves adjoint(oracle);

  /// Runs the bounded coherent finite-oracle fixture.
  ///
  /// - Effects: Mutates declared state and submits one bounded ideal-target task.
  entry void main() {
    addThree();
    assert(value == 3);
    reverse addThree();
    assert(value == 0);

    prepare(q, 5);
    oracle();
    measured = measure(q);
    assert(measured == 0);
  }
}
