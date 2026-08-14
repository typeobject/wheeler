//! Checks one exact diagonal entry of a bounded symmetric quantum kernel.

quantum class QuantumKernelClassifier {
  const long QUBITS = 1;

  state long measured = 0;
  state long trainingRows = 2;
  state long kernelEntries = 4;
  state long acceptedLabel = 1;
  qreg q = new qreg(QUBITS);

  /// Applies the fixed pi-over-three feature map.
  ///
  /// - Adjoint: Removes the exact feature map.
  unitary void feature() {
    H(q[0]);
    Phase(q[0], 1.0471975511965976);
  }

  /// Checks the feature-map generated adjoint.
  theorem featureAdjoint proves adjoint(feature);

  /// Executes one diagonal kernel-overlap check.
  ///
  /// - Effects: Submits one bounded ideal-target task and records its basis result.
  entry void main() {
    prepare(q, 0);
    feature();
    reverse feature();
    measured = measure(q);
    assert(measured == 0);
    assert(trainingRows == 2);
    assert(kernelEntries == 4);
    assert(acceptedLabel == 1);
  }
}
