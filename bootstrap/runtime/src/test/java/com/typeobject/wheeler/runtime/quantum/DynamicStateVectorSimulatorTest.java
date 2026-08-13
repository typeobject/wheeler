package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Conformance evidence for bounded target-resident dynamic control. */
final class DynamicStateVectorSimulatorTest {
  @Test
  void syndromeMeasurementConditionallyCorrectsAndResetsWithoutHostSplit() {
    DynamicStateVectorSimulator simulator = new DynamicStateVectorSimulator();
    DynamicSyndromeResult result = simulator.execute(
        new DynamicSyndromeFixture(true, true, 3));

    assertTrue(result.logicalBit());
    assertTrue(result.correctedDataBit());
    assertEquals(List.of(true, false, false), result.syndromes());
    assertEquals(List.of(false, false, false), result.resetAncillas());
    assertEquals(1, result.conditionalCorrections());
    assertTrue(simulator.descriptor().capabilities().containsAll(Set.of(
        TargetCapability.MID_CIRCUIT_MEASUREMENT,
        TargetCapability.RESET,
        TargetCapability.CLASSICAL_CONDITIONAL)));
  }

  @Test
  void cleanStateProducesNoCorrectionAndBoundsRejectBeforeExecution() {
    DynamicStateVectorSimulator simulator = new DynamicStateVectorSimulator();
    DynamicSyndromeResult result = simulator.execute(
        new DynamicSyndromeFixture(false, false, 2));

    assertFalse(result.correctedDataBit());
    assertEquals(List.of(false, false), result.syndromes());
    assertEquals(0, result.conditionalCorrections());
    assertThrows(
        IllegalArgumentException.class,
        () -> new DynamicSyndromeFixture(false, false, 0));
    assertThrows(
        IllegalArgumentException.class,
        () -> new DynamicSyndromeFixture(
            false, false, DynamicSyndromeFixture.MAX_ROUNDS + 1));
  }
}
