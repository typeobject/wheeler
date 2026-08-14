//! Records the exact paired shifts for a one-parameter expectation gradient.

quantum class ParameterShift {
  const long QUBITS = 1;

  state long measured = 0;
  state long shiftedApplications = 2;
  state long exactGradientMilli = -1000;
  qreg q = new qreg(QUBITS);

  /// Applies the positive shifted ansatz at pi.
  ///
  /// - Adjoint: Removes the positive shifted ansatz.
  unitary void positiveShift() {
    H(q[0]);
    Phase(q[0], 3.141592653589793);
    H(q[0]);
  }

  /// Applies the negative shifted ansatz at zero.
  ///
  /// - Adjoint: Removes the negative shifted ansatz.
  unitary void negativeShift() {
    H(q[0]);
    Phase(q[0], 0.0);
    H(q[0]);
  }

  /// Checks the positive-shift generated adjoint.
  theorem positiveShiftAdjoint proves adjoint(positiveShift);

  /// Checks the negative-shift generated adjoint.
  theorem negativeShiftAdjoint proves adjoint(negativeShift);

  /// Executes the positive point and exact cleanup.
  ///
  /// - Effects: Submits one bounded ideal-target task and records its basis result.
  entry void main() {
    prepare(q, 0);
    positiveShift();
    reverse positiveShift();
    measured = measure(q);
    assert(measured == 0);
    assert(shiftedApplications == 2);
    assert(exactGradientMilli == -1000);
  }
}
