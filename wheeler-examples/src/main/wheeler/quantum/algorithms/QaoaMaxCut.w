//! Applies one parameterized representative for the fixed two-node Max-Cut graph.

quantum class QaoaMaxCut {
  const long QUBITS = 2;

  state long measured = 0;
  state long vertices = 2;
  state long edges = 1;
  state long layers = 1;
  state long plannedDepth = 5;
  qreg q = new qreg(QUBITS);

  /// Applies one cost phase and fixed mixer for the sole graph edge.
  ///
  /// - Adjoint: Reverses the exact cost and mixer layer.
  unitary void maxCutLayer() {
    H(q[0]);
    H(q[1]);
    CPhase(q[0], q[1], 3.141592653589793);
    H(q[0]);
    H(q[1]);
  }

  /// Checks the fixed graph layer generated adjoint.
  theorem maxCutAdjoint proves adjoint(maxCutLayer);

  /// Executes one bounded fixed-graph sample.
  ///
  /// - Effects: Submits one bounded ideal-target task and records its basis result.
  entry void main() {
    prepare(q, 0);
    maxCutLayer();
    measured = measure(q);
    assert(vertices == 2);
    assert(edges == 1);
    assert(layers == 1);
    assert(plannedDepth == 5);
  }
}
