package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.quantum.ConditionalGateOperation;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.QuantumOperation;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/** Closes one semantic static circuit against measured target calibration data. */
public final class CalibrationAwareCompiler {
  private static final int MAX_GATES = 64;
  private static final int MAX_SHOTS_PER_GATE = 100_000;
  private static final long PARTS_PER_TRILLION = 1_000_000_000_000L;

  /** Runs a bounded calibration request without exposing provider state to the compiler. */
  @FunctionalInterface
  public interface CalibrationProvider {
    CalibrationResult calibrate(CalibrationRequest request);
  }

  /** Policy for an explicitly older provider calibration epoch. */
  public record StalePolicy(boolean acceptOlder, long maximumLag) {
    public StalePolicy {
      if (maximumLag < 0 || (!acceptOlder && maximumLag != 0)) {
        throw new IllegalArgumentException("Invalid stale calibration policy");
      }
    }

    public static StalePolicy reject() {
      return new StalePolicy(false, 0);
    }

    public static StalePolicy acceptWithin(long maximumLag) {
      return new StalePolicy(true, maximumLag);
    }
  }

  /** Exact semantic gates and sampling policy sent to a calibration provider. */
  public record CalibrationRequest(
      String targetIdentity,
      long requiredEpoch,
      List<Gate> gates,
      int shotsPerGate,
      long seed) {
    public CalibrationRequest {
      Objects.requireNonNull(targetIdentity, "targetIdentity");
      gates = gates.stream().distinct().sorted(Comparator.comparingInt(Gate::code)).toList();
      if (!validIdentity(targetIdentity) || requiredEpoch < 0 || gates.isEmpty()
          || gates.size() > MAX_GATES || shotsPerGate <= 0
          || shotsPerGate > MAX_SHOTS_PER_GATE) {
        throw new IllegalArgumentException("Invalid calibration request");
      }
    }

    public String identity() {
      return digest(out -> {
        writeString(out, targetIdentity);
        out.writeLong(requiredEpoch);
        out.writeInt(gates.size());
        for (Gate gate : gates) {
          out.writeInt(gate.code());
        }
        out.writeInt(shotsPerGate);
        out.writeLong(seed);
      });
    }
  }

  /** One bounded provider estimate for a semantic gate. */
  public record GateMetric(
      Gate gate, long errorPartsPerTrillion, long durationCycles, int samples) {
    public GateMetric {
      Objects.requireNonNull(gate, "gate");
      if (errorPartsPerTrillion < 0 || PARTS_PER_TRILLION < errorPartsPerTrillion
          || durationCycles <= 0 || samples <= 0 || samples > MAX_SHOTS_PER_GATE) {
        throw new IllegalArgumentException("Invalid gate calibration metric");
      }
    }
  }

  /** Provider result tied to the exact request, target, and measured epoch. */
  public record CalibrationResult(
      String requestIdentity,
      String targetIdentity,
      long measuredEpoch,
      List<GateMetric> metrics) {
    public CalibrationResult {
      Objects.requireNonNull(requestIdentity, "requestIdentity");
      Objects.requireNonNull(targetIdentity, "targetIdentity");
      metrics = metrics.stream()
          .sorted(Comparator.comparingInt(metric -> metric.gate().code()))
          .toList();
      if (!validIdentity(requestIdentity) || !validIdentity(targetIdentity) || measuredEpoch < 0
          || metrics.isEmpty() || metrics.size() > MAX_GATES) {
        throw new IllegalArgumentException("Invalid calibration result");
      }
      Set<Gate> unique = new HashSet<>();
      if (metrics.stream().anyMatch(metric -> !unique.add(metric.gate()))) {
        throw new IllegalArgumentException("Duplicate gate calibration metric");
      }
    }

    public String identity() {
      return digest(out -> {
        writeString(out, requestIdentity);
        writeString(out, targetIdentity);
        out.writeLong(measuredEpoch);
        out.writeInt(metrics.size());
        for (GateMetric metric : metrics) {
          out.writeInt(metric.gate().code());
          out.writeLong(metric.errorPartsPerTrillion());
          out.writeLong(metric.durationCycles());
          out.writeInt(metric.samples());
        }
      });
    }
  }

  /** Immutable compilation decision bound to program, target, epoch, and metrics. */
  public record CalibrationPlan(
      String programIdentity,
      int circuitId,
      String targetIdentity,
      long requiredEpoch,
      long measuredEpoch,
      boolean acceptedOlderEpoch,
      StalePolicy stalePolicy,
      List<GateMetric> metrics,
      long estimatedDurationCycles,
      long unionErrorBoundPartsPerTrillion,
      String identity) {
    public CalibrationPlan {
      Objects.requireNonNull(programIdentity, "programIdentity");
      Objects.requireNonNull(targetIdentity, "targetIdentity");
      Objects.requireNonNull(stalePolicy, "stalePolicy");
      Objects.requireNonNull(identity, "identity");
      metrics = List.copyOf(metrics);
      if (programIdentity.isBlank() || circuitId < 0 || targetIdentity.isBlank()
          || requiredEpoch < 0 || measuredEpoch < 0 || estimatedDurationCycles <= 0
          || unionErrorBoundPartsPerTrillion < 0
          || PARTS_PER_TRILLION < unionErrorBoundPartsPerTrillion
          || identity.isBlank()) {
        throw new IllegalArgumentException("Invalid calibration plan");
      }
    }
  }

  /** Measures and closes one circuit before any target execution is admitted. */
  public CalibrationPlan compile(
      Program program,
      int circuitId,
      TargetDescriptor target,
      long requiredEpoch,
      int shotsPerGate,
      long seed,
      StalePolicy stalePolicy,
      CalibrationProvider provider) {
    Objects.requireNonNull(program, "program");
    Objects.requireNonNull(target, "target");
    Objects.requireNonNull(stalePolicy, "stalePolicy");
    Objects.requireNonNull(provider, "provider");
    if (requiredEpoch < 0) {
      throw new IllegalArgumentException("Calibration epoch must be nonnegative");
    }
    target.require(TargetCapability.STATIC_CIRCUIT);
    if (shotsPerGate > target.maxShots()) {
      throw new QuantumExecutionException("Calibration exceeds target shot limit");
    }
    var circuit = program.quantumCircuit(circuitId);
    var register = program.quantumRegister(circuit.registerId());
    if (register.qubits() > target.maxQubits()) {
      throw new QuantumExecutionException("Calibrated circuit exceeds target qubit limit");
    }

    List<Gate> operations = new ArrayList<>();
    Set<Gate> requested = new HashSet<>();
    for (QuantumOperation operation : circuit.operations()) {
      Gate gate = semanticGate(operation);
      operations.add(gate);
      requested.add(gate);
      if (operation instanceof ParameterizedGateOperation) {
        target.require(TargetCapability.PARAMETER_BINDING);
      }
      if (operation instanceof ConditionalGateOperation) {
        target.require(TargetCapability.CLASSICAL_CONDITIONAL);
      }
    }
    if (operations.isEmpty() || operations.size() > MAX_GATES) {
      throw new QuantumExecutionException("Calibration requires 1 to 64 semantic gates");
    }

    CalibrationRequest request = new CalibrationRequest(
        target.identity(), requiredEpoch, List.copyOf(requested), shotsPerGate, seed);
    CalibrationResult result = Objects.requireNonNull(
        provider.calibrate(request), "calibration provider result");
    validateResult(request, result, stalePolicy);

    long duration = 0;
    long error = 0;
    for (Gate gate : operations) {
      GateMetric metric = result.metrics().stream()
          .filter(candidate -> candidate.gate() == gate)
          .findFirst()
          .orElseThrow(() -> new QuantumExecutionException(
              "Calibration result omits gate " + gate));
      duration = Math.addExact(duration, metric.durationCycles());
      error = Math.min(
          PARTS_PER_TRILLION,
          Math.addExact(error, metric.errorPartsPerTrillion()));
    }
    long estimatedDuration = duration;
    long estimatedError = error;
    String programIdentity = digest(out -> {
      byte[] artifact = new BytecodeWriter().write(program);
      out.writeInt(artifact.length);
      out.write(artifact);
    });
    boolean acceptedOlder = result.measuredEpoch() < requiredEpoch;
    List<GateMetric> metrics = List.copyOf(result.metrics());
    String planIdentity = digest(out -> {
      writeString(out, programIdentity);
      out.writeInt(circuitId);
      writeString(out, target.identity());
      out.writeLong(requiredEpoch);
      writeString(out, result.identity());
      out.writeBoolean(acceptedOlder);
      out.writeBoolean(stalePolicy.acceptOlder());
      out.writeLong(stalePolicy.maximumLag());
      out.writeLong(estimatedDuration);
      out.writeLong(estimatedError);
    });
    return new CalibrationPlan(
        programIdentity,
        circuitId,
        target.identity(),
        requiredEpoch,
        result.measuredEpoch(),
        acceptedOlder,
        stalePolicy,
        metrics,
        estimatedDuration,
        estimatedError,
        planIdentity);
  }

  private static Gate semanticGate(QuantumOperation operation) {
    if (operation instanceof GateOperation gate) {
      return gate.gate();
    }
    if (operation instanceof ParameterizedGateOperation gate) {
      return gate.gate();
    }
    if (operation instanceof ConditionalGateOperation gate) {
      return gate.gate().gate();
    }
    throw new QuantumExecutionException(
        "Calibration compiler requires lowered semantic gate operations");
  }

  private static void validateResult(
      CalibrationRequest request,
      CalibrationResult result,
      StalePolicy stalePolicy) {
    if (!result.requestIdentity().equals(request.identity())
        || !result.targetIdentity().equals(request.targetIdentity())) {
      throw new QuantumExecutionException("Calibration result provenance mismatch");
    }
    if (result.measuredEpoch() > request.requiredEpoch()) {
      throw new QuantumExecutionException("Calibration result is from a future epoch");
    }
    long lag = request.requiredEpoch() - result.measuredEpoch();
    if (0 < lag && (!stalePolicy.acceptOlder() || stalePolicy.maximumLag() < lag)) {
      throw new QuantumExecutionException("Calibration result is stale by " + lag + " epochs");
    }
    List<Gate> measured = result.metrics().stream().map(GateMetric::gate).toList();
    if (!measured.equals(request.gates())) {
      throw new QuantumExecutionException("Calibration result gate set mismatch");
    }
    if (result.metrics().stream().anyMatch(metric -> metric.samples() != request.shotsPerGate())) {
      throw new QuantumExecutionException("Calibration result sample count mismatch");
    }
  }

  private static boolean validIdentity(String identity) {
    if (identity.length() != 64) {
      return false;
    }
    for (int index = 0; index < identity.length(); index++) {
      char value = identity.charAt(index);
      if (!((value >= '0' && value <= '9') || (value >= 'a' && value <= 'f'))) {
        return false;
      }
    }
    return true;
  }

  private static String digest(IoWriter writer) {
    try {
      ByteArrayOutputStream bytes = new ByteArrayOutputStream();
      try (DataOutputStream out = new DataOutputStream(bytes)) {
        writer.write(out);
      }
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(bytes.toByteArray()));
    } catch (IOException exception) {
      throw new AssertionError(exception);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static void writeString(DataOutputStream out, String value) throws IOException {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    out.writeInt(bytes.length);
    out.write(bytes);
  }

  @FunctionalInterface
  private interface IoWriter {
    void write(DataOutputStream output) throws IOException;
  }
}
