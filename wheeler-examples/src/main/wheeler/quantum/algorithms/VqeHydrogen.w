//! Selects the lower exact point of a pinned one-qubit hydrogen reduction.

quantum class VqeHydrogen {
  const long QUBITS = 1;
  const long PLANNED_SHOTS = 4096;

  state long measured = 0;
  state long selectedEnergyMilli = -1000;
  state long batchApplications = 2;
  state long plannedShots = PLANNED_SHOTS;
  qreg q = new qreg(QUBITS);

  /// Applies the selected pi point of the `Z` Hamiltonian ansatz.
  ///
  /// - Adjoint: Restores the exact input basis state.
  unitary void selectedAnsatz() {
    H(q[0]);
    Phase(q[0], 3.141592653589793);
    H(q[0]);
  }

  /// Checks the selected ansatz generated adjoint.
  theorem selectedAnsatzAdjoint proves adjoint(selectedAnsatz);

  /// Executes the selected exact parameter point.
  ///
  /// - Effects: Submits one bounded ideal-target task and records its basis result.
  entry void main() {
    prepare(q, 0);
    selectedAnsatz();
    measured = measure(q);
    assert(measured == 1);
    assert(selectedEnergyMilli == -1000);
  }
}
