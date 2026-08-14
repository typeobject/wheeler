package com.typeobject.wheeler.runtime.quantum;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;

/** Exact bounded logical-operation and magic-state factory plan. */
public record LogicalResourcePlan(
    int logicalQubits,
    int layers,
    long cliffordGates,
    long tGates,
    long measurements,
    int tDepth,
    long magicStates,
    long factoryBatches,
    long targetCycles,
    String factoryIdentity,
    String identity) {
  private static final int MAX_LAYERS = 65_536;
  private static final long MAX_OPERATIONS = 1_000_000_000L;

  /** One parallel logical layer with explicit operation dimensions. */
  public record Layer(long cliffordGates, long tGates, long measurements) {
    public Layer {
      if (cliffordGates < 0 || tGates < 0 || measurements < 0
          || MAX_OPERATIONS < cliffordGates
          || MAX_OPERATIONS < tGates
          || MAX_OPERATIONS < measurements
          || cliffordGates + tGates + measurements == 0) {
        throw new IllegalArgumentException("logical layer dimensions are invalid");
      }
    }
  }

  /** Named bounded magic-state factory capability. */
  public record Factory(
      String identity,
      int statesPerBatch,
      int cyclesPerBatch,
      int maximumBatches,
      long outputErrorPartsPerTrillion) {
    public Factory {
      if (!lowerHex(identity)
          || statesPerBatch < 1
          || cyclesPerBatch < 1
          || maximumBatches < 1
          || outputErrorPartsPerTrillion < 0
          || 1_000_000_000_000L < outputErrorPartsPerTrillion) {
        throw new IllegalArgumentException("magic-state factory capability is invalid");
      }
    }
  }

  public LogicalResourcePlan {
    if (logicalQubits < 1 || layers < 1 || cliffordGates < 0 || tGates < 0
        || measurements < 0 || tDepth < 0 || magicStates != tGates
        || factoryBatches < 0 || targetCycles < layers || !lowerHex(factoryIdentity)) {
      throw new IllegalArgumentException("logical resource plan is invalid");
    }
    String expected = planIdentity(
        logicalQubits,
        layers,
        cliffordGates,
        tGates,
        measurements,
        tDepth,
        magicStates,
        factoryBatches,
        targetCycles,
        factoryIdentity);
    if (!expected.equals(identity)) {
      throw new IllegalArgumentException("logical resource plan identity mismatch");
    }
  }

  /** Closes one exact layered program against a named factory and target ceiling. */
  public static LogicalResourcePlan close(
      int logicalQubits,
      List<Layer> layers,
      Factory factory,
      long maximumTargetCycles) {
    if (logicalQubits < 1 || logicalQubits > 1_000_000
        || layers.isEmpty() || MAX_LAYERS < layers.size()
        || maximumTargetCycles < 1) {
      throw new IllegalArgumentException("logical planning bounds are invalid");
    }
    Objects.requireNonNull(factory, "factory");
    List<Layer> closedLayers = List.copyOf(layers);
    long clifford = 0;
    long t = 0;
    long measurements = 0;
    int tDepth = 0;
    for (Layer layer : closedLayers) {
      clifford = Math.addExact(clifford, layer.cliffordGates());
      t = Math.addExact(t, layer.tGates());
      measurements = Math.addExact(measurements, layer.measurements());
      if (layer.tGates() != 0) {
        tDepth += 1;
      }
    }
    long batches = t == 0 ? 0 : Math.addExact(t, factory.statesPerBatch() - 1)
        / factory.statesPerBatch();
    if (factory.maximumBatches() < batches) {
      throw new QuantumExecutionException("Magic-state factory capacity is insufficient");
    }
    long cycles = Math.addExact(
        closedLayers.size(), Math.multiplyExact(batches, factory.cyclesPerBatch()));
    if (maximumTargetCycles < cycles) {
      throw new QuantumExecutionException("Logical plan exceeds target-cycle capacity");
    }
    String identity = planIdentity(
        logicalQubits,
        closedLayers.size(),
        clifford,
        t,
        measurements,
        tDepth,
        t,
        batches,
        cycles,
        factory.identity());
    return new LogicalResourcePlan(
        logicalQubits,
        closedLayers.size(),
        clifford,
        t,
        measurements,
        tDepth,
        t,
        batches,
        cycles,
        factory.identity(),
        identity);
  }

  private static String planIdentity(
      int logicalQubits,
      int layers,
      long clifford,
      long t,
      long measurements,
      int tDepth,
      long magicStates,
      long batches,
      long cycles,
      String factoryIdentity) {
    String canonical = "wheeler-logical-resource-plan-1\n"
        + logicalQubits + '\n' + layers + '\n' + clifford + '\n' + t + '\n'
        + measurements + '\n' + tDepth + '\n' + magicStates + '\n' + batches + '\n'
        + cycles + '\n' + factoryIdentity + '\n';
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(
          canonical.getBytes(StandardCharsets.US_ASCII)));
    } catch (NoSuchAlgorithmException impossible) {
      throw new IllegalStateException("SHA-256 is unavailable", impossible);
    }
  }

  private static boolean lowerHex(String value) {
    return value != null && value.length() == 64
        && value.chars().allMatch(character -> character >= '0' && character <= '9'
            || character >= 'a' && character <= 'f');
  }
}
