package com.typeobject.wheeler.core;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

/** Guards the global fail-closed JUnit execution policy. */
final class TestExecutionPolicyTest {
  @Test
  void everyJUnitMethodReceivesThePreemptiveBound() {
    assertEquals(
        "2 m",
        System.getProperty("junit.jupiter.execution.timeout.default"));
    assertEquals(
        "separate_thread",
        System.getProperty("junit.jupiter.execution.timeout.thread.mode.default"));
  }
}
