package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.quantum.QuantumRegister;
import java.util.ArrayList;
import java.util.List;
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
