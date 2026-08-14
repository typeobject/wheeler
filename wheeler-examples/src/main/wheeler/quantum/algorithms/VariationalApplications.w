//! Exercises fixed representatives of the parameterized application portfolio.

quantum class VariationalApplications {
  const long QUBITS = 2;
  const long BATCH_APPLICATIONS = 8;

  state long measured = 0;
  state long batchApplications = BATCH_APPLICATIONS;
  qreg q = new qreg(QUBITS);

  /// Applies the selected one-parameter VQE ansatz at angle pi.
  ///
  /// - Adjoint: Restores the input basis state exactly.
  unitary void selectedVqeAnsatz() {
    H(q[0]);
    Phase(q[0], 3.141592653589793);
    H(q[0]);
  }

  /// Applies one fixed two-node QAOA cost and mixer layer.
  ///
  /// - Adjoint: Reverses the complete fixed layer.
  unitary void qaoaLayer() {
    H(q[0]);
    H(q[1]);
    CPhase(q[0], q[1], 3.141592653589793);
    H(q[0]);
    H(q[1]);
  }

  /// Applies one fixed single-qubit kernel feature map.
  ///
  /// - Adjoint: Removes the exact feature map.
  unitary void kernelFeature() {
    H(q[0]);
    Phase(q[0], 1.5707963267948966);
  }

  /// Applies the positive parameter-shift representative.
  ///
  /// - Adjoint: Removes the positive shift exactly.
  unitary void positiveShift() {
    H(q[0]);
    Phase(q[0], 3.141592653589793);
    H(q[0]);
  }

  /// Applies the negative parameter-shift representative.
  ///
  /// - Adjoint: Removes the negative shift exactly.
  unitary void negativeShift() {
    H(q[0]);
    Phase(q[0], 0.0);
    H(q[0]);
  }

  /// Checks the selected ansatz generated adjoint.
  theorem selectedVqeAdjoint proves adjoint(selectedVqeAnsatz);

  /// Checks the QAOA layer generated adjoint.
  theorem qaoaAdjoint proves adjoint(qaoaLayer);

  /// Checks the kernel feature generated adjoint.
  theorem kernelAdjoint proves adjoint(kernelFeature);

  /// Runs the exact selected VQE representative.
  ///
  /// - Effects: Submits one bounded ideal-target task and records its basis result.
  entry void main() {
    prepare(q, 0);
    selectedVqeAnsatz();
    measured = measure(q);
    assert(measured == 1);
  }
}
