package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;
import org.junit.jupiter.api.Test;

/** Exact logical layers and magic-state capacity remain separate resource dimensions. */
final class LogicalResourcePlanTest {
  private static final String FACTORY_IDENTITY =
      "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

  @Test
  void closesExactLayerCountsAgainstFactoryAndTargetCapacity() {
    LogicalResourcePlan.Factory factory = new LogicalResourcePlan.Factory(
        FACTORY_IDENTITY, 4, 12, 3, 100);
    LogicalResourcePlan.LogicalTarget target = logicalTarget(3, 7, 28, 10);
    LogicalResourcePlan plan = LogicalResourcePlan.close(
        3,
        List.of(
            new LogicalResourcePlan.Layer(2, 0, 0),
            new LogicalResourcePlan.Layer(1, 3, 0),
            new LogicalResourcePlan.Layer(0, 2, 1),
            new LogicalResourcePlan.Layer(1, 0, 2)),
        factory,
        target,
        800);

    assertEquals(3, plan.logicalQubits());
    assertEquals(4, plan.layers());
    assertEquals(4, plan.cliffordGates());
    assertEquals(5, plan.tGates());
    assertEquals(3, plan.measurements());
    assertEquals(2, plan.tDepth());
    assertEquals(5, plan.magicStates());
    assertEquals(2, plan.factoryBatches());
    assertEquals(28, plan.targetCycles());
    assertEquals(7, plan.codeDistance());
    assertEquals(800, plan.failureBudgetPartsPerTrillion());
    assertEquals(780, plan.plannedFailurePartsPerTrillion());
    assertEquals(target.identity(), plan.targetIdentity());
    assertNotEquals(FACTORY_IDENTITY, plan.identity());
  }

  @Test
  void insufficientFactoryAndTargetCapacityRejectBeforePlanPublication() {
    List<LogicalResourcePlan.Layer> layers = List.of(
        new LogicalResourcePlan.Layer(0, 5, 0));
    LogicalResourcePlan.Factory smallFactory = new LogicalResourcePlan.Factory(
        FACTORY_IDENTITY, 2, 3, 2, 100);
    LogicalResourcePlan.Factory sufficientFactory = new LogicalResourcePlan.Factory(
        FACTORY_IDENTITY, 5, 3, 1, 100);

    assertThrows(
        QuantumExecutionException.class,
        () -> LogicalResourcePlan.close(
            1, layers, smallFactory, logicalTarget(1, 3, 100, 1), 1_000));
    assertThrows(
        QuantumExecutionException.class,
        () -> LogicalResourcePlan.close(
            1, layers, sufficientFactory, logicalTarget(1, 3, 3, 1), 1_000));
    assertThrows(
        QuantumExecutionException.class,
        () -> LogicalResourcePlan.close(
            1, layers, sufficientFactory, logicalTarget(1, 3, 100, 100), 100));

    TargetDescriptor physical = new TargetDescriptor(
        "physical", "static-only", java.util.Set.of(TargetCapability.STATIC_CIRCUIT), 8, 8);
    assertThrows(
        QuantumExecutionException.class,
        () -> new LogicalResourcePlan.LogicalTarget(physical, 3, 100, 1));
  }

  private static LogicalResourcePlan.LogicalTarget logicalTarget(
      int qubits, int distance, long cycles, long errorPerCycle) {
    TargetDescriptor descriptor = new TargetDescriptor(
        "logical-planner",
        "mock-logical",
        java.util.Set.of(TargetCapability.LOGICAL_QUBITS),
        qubits,
        1);
    return new LogicalResourcePlan.LogicalTarget(
        descriptor, distance, cycles, errorPerCycle);
  }
}
