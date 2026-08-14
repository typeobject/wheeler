package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.quantum.ConditionalGateOperation;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.MeasureOperation;
import com.typeobject.wheeler.core.quantum.PrepareOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.quantum.ResetOperation;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Bounded ideal simulator for target-resident measurement, reset, and conditional control. */
public final class DynamicStateVectorSimulator {
  private final TargetDescriptor descriptor = new TargetDescriptor(
      "wheeler-dynamic-state-vector",
      "ideal-dynamic-local",
      Set.of(
          TargetCapability.STATIC_CIRCUIT,
          TargetCapability.MID_CIRCUIT_MEASUREMENT,
          TargetCapability.RESET,
          TargetCapability.CLASSICAL_CONDITIONAL,
          TargetCapability.STATE_VECTOR_DIAGNOSTICS),
      3,
      DynamicSyndromeFixture.MAX_ROUNDS);

  public TargetDescriptor descriptor() {
    return descriptor;
  }

  /** Executes one canonical target-resident dynamic circuit without a host split. */
  public DynamicCircuitResult execute(Program program, QuantumCircuit circuit, long seed) {
    descriptor.require(Set.of(
        TargetCapability.MID_CIRCUIT_MEASUREMENT,
        TargetCapability.RESET,
        TargetCapability.CLASSICAL_CONDITIONAL));
    QuantumRegister register = program.quantumRegister(circuit.registerId());
    if (descriptor.maxQubits() < register.qubits()) {
      throw new QuantumExecutionException("Dynamic circuit exceeds target qubit limit");
    }
    StateVectorEngine engine = new StateVectorEngine(seed);
    Map<Integer, Boolean> resultSlots = new HashMap<>();
    Set<Integer> measuredQubits = new HashSet<>();
    boolean prepared = false;
    for (var operation : circuit.operations()) {
      if (operation instanceof PrepareOperation preparation) {
        if (prepared) {
          throw new QuantumExecutionException("Dynamic circuit prepares its register twice");
        }
        engine.prepare(register, preparation.basisState());
        prepared = true;
      } else {
        if (!prepared) {
          throw new QuantumExecutionException("Dynamic operation precedes register preparation");
        }
        if (operation instanceof GateOperation gate) {
          requireAvailable(gate.qubits(), measuredQubits);
          engine.applyGate(register, gate);
        } else if (operation instanceof MeasureOperation measurement) {
          if (!measuredQubits.add(measurement.qubit())) {
            throw new QuantumExecutionException(
                "Dynamic qubit is measured twice without reset");
          }
          resultSlots.put(
              measurement.resultSlot(), engine.measureQubit(register, measurement.qubit()));
        } else if (operation instanceof ResetOperation reset) {
          measuredQubits.remove(reset.qubit());
          engine.reset(register, reset.qubit());
        } else if (operation instanceof ConditionalGateOperation conditional) {
          Boolean result = resultSlots.get(conditional.resultSlot());
          if (result == null) {
            throw new QuantumExecutionException("Conditional gate reads an unassigned result slot");
          }
          requireAvailable(conditional.gate().qubits(), measuredQubits);
          if (result == conditional.expected()) {
            engine.applyGate(register, conditional.gate());
          }
        } else {
          throw new QuantumExecutionException(
              "Unsupported target-resident dynamic operation " + operation);
        }
      }
    }
    if (!prepared) {
      throw new QuantumExecutionException("Dynamic circuit does not prepare its register");
    }
    return new DynamicCircuitResult(engine.measure(register), resultSlots);
  }

  private static void requireAvailable(
      List<Integer> qubits, Set<Integer> measuredQubits) {
    if (qubits.stream().anyMatch(measuredQubits::contains)) {
      throw new QuantumExecutionException(
          "Dynamic qubit is used after measurement without reset");
    }
  }

  /** Executes all rounds within one target call and returns only final bounded evidence. */
  public DynamicSyndromeResult execute(DynamicSyndromeFixture fixture) {
    descriptor.require(Set.of(
        TargetCapability.MID_CIRCUIT_MEASUREMENT,
        TargetCapability.RESET,
        TargetCapability.CLASSICAL_CONDITIONAL));
    QuantumRegister register = new QuantumRegister(0, "syndrome", 2);
    StateVectorEngine engine = new StateVectorEngine(0);
    long basis = fixture.logicalBit() ? 1 : 0;
    if (fixture.dataBitFlipped()) {
      basis ^= 1;
    }
    engine.prepare(register, basis);
    List<Boolean> syndromes = new ArrayList<>(fixture.rounds());
    List<Boolean> resetAncillas = new ArrayList<>(fixture.rounds());
    int corrections = 0;
    for (int round = 0; round < fixture.rounds(); round++) {
      if (fixture.logicalBit()) {
        engine.applyX(register, 1);
      }
      engine.applyCnot(register, 0, 1);
      boolean syndrome = engine.measureQubit(register, 1);
      syndromes.add(syndrome);
      if (syndrome) {
        engine.applyX(register, 0);
        corrections++;
      }
      engine.reset(register, 1);
      resetAncillas.add(engine.measureQubit(register, 1));
    }
    long corrected = engine.measure(register);
    return new DynamicSyndromeResult(
        fixture.logicalBit(), (corrected & 1) != 0,
        syndromes, resetAncillas, corrections);
  }
}
