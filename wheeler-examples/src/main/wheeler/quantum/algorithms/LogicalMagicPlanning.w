//! Closes one exact logical-operation schedule against a bounded magic-state factory.

classical class LogicalMagicPlanning {
  const long FACTORY_STATES_PER_BATCH = 4;
  const long FACTORY_CYCLES_PER_BATCH = 12;
  const long TARGET_CYCLE_LIMIT = 28;

  state long logicalQubits = 3;
  state long layers = 4;
  state long cliffordGates = 4;
  state long tGates = 5;
  state long measurements = 3;
  state long tDepth = 2;
  state long magicStates = 0;
  state long factoryBatches = 0;
  state long targetCycles = 0;
  state long codeDistance = 7;
  state long failureBudgetPartsPerTrillion = 800;
  state long plannedFailurePartsPerTrillion = 780;

  /// Closes exact state demand and factory cycles without treating either as a gate count.
  ///
  /// - Inverse: Clears the exact target cycles, factory batches, and state demand.
  rev void closePlan() {
    magicStates += 5;
    factoryBatches += 2;
    targetCycles += 28;
  }

  /// Runs the bounded logical-resource planning fixture.
  ///
  /// - Effects: Mutates only the fixture's declared planning state.
  entry void main() {
    closePlan();
    assert(logicalQubits == 3);
    assert(cliffordGates == 4);
    assert(tGates == 5);
    assert(measurements == 3);
    assert(tDepth == 2);
    assert(magicStates == 5);
    assert(factoryBatches == 2);
    assert(targetCycles == TARGET_CYCLE_LIMIT);
    assert(codeDistance == 7);
    assert(failureBudgetPartsPerTrillion == 800);
    assert(plannedFailurePartsPerTrillion == 780);
  }
}
