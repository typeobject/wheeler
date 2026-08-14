package com.typeobject.wheeler.runtime.io;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Executor;
import java.util.concurrent.ThreadFactory;
import java.util.Timer;
import org.junit.jupiter.api.Test;

/** Exercises bounded dormant connection storage and independent active-work credit. */
final class ConnectionRegistryTest {
  @Test
  void oneHundredThousandDormantConnectionsAllocateNoExecutionResource() {
    ConnectionRegistry registry = new ConnectionRegistry(100_000, 32);
    List<ConnectionRegistry.Connection> connections = new ArrayList<>(100_000);
    for (int index = 0; index < 100_000; index++) {
      connections.add(registry.open());
    }
    assertEquals(100_000, registry.openCount());
    assertEquals(0, registry.activeCount());
    assertTrue(connections.stream().allMatch(registry::isDormant));

    for (Field field : ConnectionRegistry.class.getDeclaredFields()) {
      Class<?> type = field.getType();
      assertTrue(!Thread.class.isAssignableFrom(type));
      assertTrue(!ThreadFactory.class.isAssignableFrom(type));
      assertTrue(!Executor.class.isAssignableFrom(type));
      assertTrue(!Timer.class.isAssignableFrom(type));
    }
  }

  @Test
  void activeCreditFailsWithoutChangingDormantAuthorities() {
    ConnectionRegistry registry = new ConnectionRegistry(3, 1);
    ConnectionRegistry.Connection first = registry.open();
    ConnectionRegistry.Connection second = registry.open();
    registry.activate(first);
    assertThrows(IllegalStateException.class, () -> registry.activate(second));
    assertTrue(registry.isDormant(second));
    assertEquals(1, registry.activeCount());
    registry.park(first);
    registry.activate(second);
    assertEquals(1, registry.activeCount());
  }

  @Test
  void closeRequiresDormancyAndInvalidatesThePriorGeneration() {
    ConnectionRegistry registry = new ConnectionRegistry(1, 1);
    ConnectionRegistry.Connection stale = registry.open();
    registry.activate(stale);
    assertThrows(IllegalStateException.class, () -> registry.close(stale));
    registry.park(stale);
    registry.close(stale);
    assertThrows(IllegalStateException.class, () -> registry.isDormant(stale));

    ConnectionRegistry.Connection current = registry.open();
    assertEquals(stale.slot(), current.slot());
    assertEquals(stale.generation() + 1, current.generation());
    assertThrows(IllegalStateException.class, () -> registry.activate(stale));
  }

  @Test
  void registryAndActiveBoundsFailAtTheirAdmissionEdges() {
    assertThrows(IllegalArgumentException.class, () -> new ConnectionRegistry(0, 1));
    assertThrows(IllegalArgumentException.class, () -> new ConnectionRegistry(1, 2));
    ConnectionRegistry registry = new ConnectionRegistry(1, 1);
    registry.open();
    assertThrows(IllegalStateException.class, registry::open);
  }
}
