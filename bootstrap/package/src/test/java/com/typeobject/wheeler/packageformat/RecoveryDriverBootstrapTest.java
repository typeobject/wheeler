package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

/** First-current-driver production from one previous-recovery boundary. */
final class RecoveryDriverBootstrapTest {
  @Test
  void previousRecoveryProducesTheFirstCurrentDriverFromPinnedInputs() throws Exception {
    byte[] source = "driver source".getBytes(StandardCharsets.UTF_8);
    byte[] vendor = "pinned vendor".getBytes(StandardCharsets.UTF_8);
    byte[] driver = "first current wheeler driver".getBytes(StandardCharsets.UTF_8);
    RecoveryDriverBootstrap.Plan plan = plan(source, driver);
    List<RecoveryDriverBootstrap.Input> inputs = List.of(
        input("driver.w", source), input("vendor.wpk", vendor));
    AtomicInteger previousCalls = new AtomicInteger();

    RecoveryDriverBootstrap.Result result = new RecoveryDriverBootstrap().execute(
        plan,
        inputs,
        (acceptedPlan, acceptedInputs) -> {
          previousCalls.incrementAndGet();
          assertEquals(plan, acceptedPlan);
          assertEquals(inputs, acceptedInputs);
          return driver;
        });

    assertEquals(1, previousCalls.get());
    assertEquals(identity(driver), result.identity());
    assertArrayEquals(driver, result.bytes());
  }

  @Test
  void staleOutputMissingSourceAndCurrentDriverDependencyFailClosed() throws Exception {
    byte[] source = "driver source".getBytes(StandardCharsets.UTF_8);
    byte[] driver = "first driver".getBytes(StandardCharsets.UTF_8);
    RecoveryDriverBootstrap.Plan plan = plan(source, driver);
    RecoveryDriverBootstrap bootstrap = new RecoveryDriverBootstrap();
    AtomicInteger calls = new AtomicInteger();

    assertThrows(
        PackageFormatException.class,
        () -> bootstrap.execute(
            plan,
            List.of(input("other", "other".getBytes(StandardCharsets.UTF_8))),
            (ignoredPlan, ignoredInputs) -> {
              calls.incrementAndGet();
              return driver;
            }));
    assertEquals(0, calls.get());
    assertThrows(
        PackageFormatException.class,
        () -> bootstrap.execute(
            plan,
            List.of(input("driver.w", source)),
            (ignoredPlan, ignoredInputs) -> "wrong".getBytes(StandardCharsets.UTF_8)));
    assertThrows(
        PackageFormatException.class,
        () -> new RecoveryDriverBootstrap.Plan(
            identity("previous".getBytes(StandardCharsets.UTF_8)),
            identity(source),
            "current-wheeler build",
            identity("environment".getBytes(StandardCharsets.UTF_8)),
            identity(driver),
            driver.length,
            BuildPlan.ExecutionLimits.DEFAULT));
  }

  private static RecoveryDriverBootstrap.Plan plan(byte[] source, byte[] driver) throws Exception {
    return new RecoveryDriverBootstrap.Plan(
        identity("previous".getBytes(StandardCharsets.UTF_8)),
        identity(source),
        "./recovery-wheeler execute sealed-plan.yaml",
        identity("environment".getBytes(StandardCharsets.UTF_8)),
        identity(driver),
        driver.length,
        BuildPlan.ExecutionLimits.DEFAULT);
  }

  private static RecoveryDriverBootstrap.Input input(String name, byte[] bytes) throws Exception {
    return new RecoveryDriverBootstrap.Input(name, identity(bytes), bytes);
  }

  private static String identity(byte[] bytes) throws Exception {
    return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
  }
}
