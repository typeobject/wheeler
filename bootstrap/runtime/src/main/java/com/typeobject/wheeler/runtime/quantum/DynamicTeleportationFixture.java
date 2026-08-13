package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.quantum.ConditionalGateOperation;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.MeasureOperation;
import com.typeobject.wheeler.core.quantum.PrepareOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import java.util.List;

/** Canonical three-qubit target-resident teleportation fixture. */
public record DynamicTeleportationFixture(boolean input) {
  public static final int QUBITS = 3;
  public static final int CIRCUIT_ID = 0;
  public static final int REGISTER_ID = 0;
  private static final int SOURCE = 0;
  private static final int BELL = 1;
  private static final int TARGET = 2;
  private static final int PHASE_RESULT = 0;
  private static final int PARITY_RESULT = 1;

  /** Builds the complete semantic region without a host-side measurement split. */
  public QuantumCircuit circuit() {
    return new QuantumCircuit(
        CIRCUIT_ID,
        "dynamicTeleportation",
        REGISTER_ID,
        List.of(
            new PrepareOperation(input ? 1 : 0),
            GateOperation.of(Gate.H, BELL),
            GateOperation.of(Gate.CNOT, BELL, TARGET),
            GateOperation.of(Gate.CNOT, SOURCE, BELL),
            GateOperation.of(Gate.H, SOURCE),
            new MeasureOperation(SOURCE, PHASE_RESULT),
            new MeasureOperation(BELL, PARITY_RESULT),
            new ConditionalGateOperation(
                PARITY_RESULT, true, GateOperation.of(Gate.X, TARGET)),
            new ConditionalGateOperation(
                PHASE_RESULT, true, GateOperation.of(Gate.Z, TARGET))));
  }

  /** Reads the teleported target bit from the final little-endian basis state. */
  public boolean target(DynamicCircuitResult result) {
    return (result.basisState() & (1L << TARGET)) != 0;
  }
}
