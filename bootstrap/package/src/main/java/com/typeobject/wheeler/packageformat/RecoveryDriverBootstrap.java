package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;

/** Bounded first-current-driver derivation from a prior recovery executor. */
public final class RecoveryDriverBootstrap {
  public static final int MAX_INPUTS = 4_096;
  public static final int MAX_COMMAND_BYTES = 4_096;

  /** Prior-release boundary used to execute the immutable bootstrap plan. */
  @FunctionalInterface
  public interface PreviousDriver {
    byte[] execute(Plan plan, List<Input> inputs);
  }

  public record Input(String name, String identity, byte[] bytes) {
    public Input {
      if (name == null || name.isBlank() || name.length() > 1_024
          || identity == null || !identity.matches("[0-9a-f]{64}")
          || bytes == null || !identity.equals(sha256(bytes))) {
        throw new PackageFormatException("Invalid recovery-driver bootstrap input");
      }
      bytes = bytes.clone();
    }

    @Override
    public byte[] bytes() {
      return bytes.clone();
    }
  }

  public record Plan(
      String previousRecovery,
      String sourceIdentity,
      String command,
      String environmentIdentity,
      String expectedOutput,
      int expectedLength,
      BuildPlan.ExecutionLimits limits) {
    public Plan {
      requireIdentity(previousRecovery, "previous recovery release");
      requireIdentity(sourceIdentity, "driver source");
      requireIdentity(environmentIdentity, "driver environment");
      requireIdentity(expectedOutput, "driver output");
      Objects.requireNonNull(command, "command");
      if (command.isBlank()
          || command.getBytes(StandardCharsets.UTF_8).length > MAX_COMMAND_BYTES
          || command.contains("current-wheeler")
          || command.contains("http://")
          || command.contains("https://")
          || expectedLength < 1
          || limits == null) {
        throw new PackageFormatException("Invalid recovery-driver bootstrap plan");
      }
    }
  }

  public record Result(String identity, byte[] bytes) {
    public Result {
      requireIdentity(identity, "first current driver");
      bytes = bytes.clone();
      if (!identity.equals(sha256(bytes))) {
        throw new PackageFormatException("First current driver identity mismatch");
      }
    }

    @Override
    public byte[] bytes() {
      return bytes.clone();
    }
  }

  public Result execute(Plan plan, List<Input> inputs, PreviousDriver previousDriver) {
    Objects.requireNonNull(plan, "plan");
    Objects.requireNonNull(previousDriver, "previousDriver");
    List<Input> checked = List.copyOf(inputs);
    if (checked.isEmpty() || checked.size() > MAX_INPUTS
        || checked.stream().map(Input::name).distinct().count() != checked.size()) {
      throw new PackageFormatException("Invalid recovery-driver input closure");
    }
    long inputBytes = 0;
    boolean sourcePresent = false;
    for (Input input : checked) {
      inputBytes = Math.addExact(inputBytes, input.bytes().length);
      sourcePresent |= input.identity().equals(plan.sourceIdentity());
    }
    if (!sourcePresent || inputBytes > plan.limits().maxInputBytes()) {
      throw new PackageFormatException("Recovery-driver input closure exceeds its plan");
    }
    byte[] output = Objects.requireNonNull(
        previousDriver.execute(plan, checked), "previous driver output").clone();
    if (output.length != plan.expectedLength()
        || output.length > plan.limits().maxOutputBytes()
        || !sha256(output).equals(plan.expectedOutput())) {
      throw new PackageFormatException("Previous recovery release produced the wrong driver");
    }
    return new Result(plan.expectedOutput(), output);
  }

  private static void requireIdentity(String value, String description) {
    if (value == null || !value.matches("[0-9a-f]{64}")) {
      throw new PackageFormatException("Invalid SHA-256 identity for " + description);
    }
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }
}
