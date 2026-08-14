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
    LogicalResourcePlan plan = LogicalResourcePlan.close(
        3,
        List.of(
            new LogicalResourcePlan.Layer(2, 0, 0),
            new LogicalResourcePlan.Layer(1, 3, 0),
            new LogicalResourcePlan.Layer(0, 2, 1),
            new LogicalResourcePlan.Layer(1, 0, 2)),
        factory,
        28);

    assertEquals(3, plan.logicalQubits());
    assertEquals(4, plan.layers());
    assertEquals(4, plan.cliffordGates());
    assertEquals(5, plan.tGates());
    assertEquals(3, plan.measurements());
    assertEquals(2, plan.tDepth());
    assertEquals(5, plan.magicStates());
    assertEquals(2, plan.factoryBatches());
    assertEquals(28, plan.targetCycles());
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
        () -> LogicalResourcePlan.close(1, layers, smallFactory, 100));
    assertThrows(
        QuantumExecutionException.class,
        () -> LogicalResourcePlan.close(1, layers, sufficientFactory, 3));
  }
}
