package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Executable bootstrap option and limit schema tests. */
final class BootstrapConfigurationTest {
  @Test
  void compilerOptionsRoundTripCanonically() {
    BootstrapCompilerOptions options = new BootstrapCompilerOptions("bootstrap-1", false);

    assertEquals(options, new BootstrapCompilerOptionsParser().parse(options.canonicalBytes()));
    assertEquals(64, options.identity().length());
  }

  @Test
  void allCompilerLimitsRoundTripCanonically() {
    BootstrapCompilerLimits limits = limits();

    assertEquals(limits, new BootstrapCompilerLimitsParser().parse(limits.canonicalBytes()));
    assertEquals(64, limits.identity().length());
  }

  @Test
  void toolchainProvenanceRoundTripsCanonically() {
    BootstrapToolchain toolchain = new BootstrapToolchain(
        BootstrapToolchain.Kind.RECOVERY_SEED,
        "00".repeat(32),
        "11".repeat(32),
        "22".repeat(32),
        "33".repeat(32));

    assertEquals(toolchain, new BootstrapToolchainParser().parse(toolchain.canonicalBytes()));
    assertEquals(64, toolchain.identity().length());
  }

  @Test
  void unknownOrUnsafeConfigurationFailsClosed() {
    String unknown = new BootstrapCompilerOptions("bootstrap-1", false).canonicalText()
        .replace("  source-maps: false\n", "  source-maps: false\n  surprise: true\n");
    assertThrows(PackageFormatException.class, () ->
        new BootstrapCompilerOptionsParser().parse(unknown.getBytes(StandardCharsets.UTF_8)));
    assertThrows(PackageFormatException.class, () ->
        new BootstrapCompilerLimits(
            0, 1, 1, 1, 1, 1, 1, 1, 1, 1));
    assertThrows(PackageFormatException.class, () ->
        new BootstrapCompilerLimitsParser().parse(
            limits().canonicalText().replace("steps: 10000000", "steps: 01")
                .getBytes(StandardCharsets.UTF_8)));
  }

  private static BootstrapCompilerLimits limits() {
    return new BootstrapCompilerLimits(
        16_777_216,
        100_000,
        256,
        10_000,
        10_000,
        1_000_000,
        1_000,
        268_435_456,
        1_024,
        10_000_000);
  }
}
