package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeMap;

/** A complete portable prepare-unitary-measure target submission. */
public record QuantumTask(
    Program program,
    int registerId,
    long basisState,
    List<CircuitApplication> applications,
    Map<String, Double> bindings,
    int shots,
    long seed) {
  public QuantumTask {
    Objects.requireNonNull(program, "program");
    applications = List.copyOf(applications);
    TreeMap<String, Double> ordered = new TreeMap<>();
    bindings.forEach((name, value) -> {
      if (name == null || name.isBlank() || name.length() > 1024
          || value == null || !Double.isFinite(value)) {
        throw new IllegalArgumentException("Invalid quantum parameter binding");
      }
      ordered.put(name, value);
    });
    bindings = Map.copyOf(ordered);
    if (registerId < 0 || shots <= 0) {
      throw new IllegalArgumentException("Invalid quantum task");
    }
    Set<String> required = new HashSet<>();
    for (CircuitApplication application : applications) {
      program.quantumCircuit(application.circuitId()).operations().stream()
          .filter(ParameterizedGateOperation.class::isInstance)
          .map(ParameterizedGateOperation.class::cast)
          .map(ParameterizedGateOperation::parameterName)
          .forEach(required::add);
    }
    if (!required.equals(bindings.keySet())) {
      throw new IllegalArgumentException(
          "Quantum parameter bindings do not match task schema: expected " + required);
    }
  }

  /** Content identity covering artifact, region applications, request, and seed policy. */
  public String identity() {
    try {
      ByteArrayOutputStream bytes = new ByteArrayOutputStream();
      try (DataOutputStream out = new DataOutputStream(bytes)) {
        byte[] artifact = new BytecodeWriter().write(program);
        out.writeInt(artifact.length);
        out.write(artifact);
        out.writeInt(registerId);
        out.writeLong(basisState);
        out.writeInt(applications.size());
        for (CircuitApplication application : applications) {
          out.writeInt(application.circuitId());
          out.writeBoolean(application.inverse());
        }
        out.writeInt(bindings.size());
        for (Map.Entry<String, Double> binding : new TreeMap<>(bindings).entrySet()) {
          byte[] name = binding.getKey().getBytes(StandardCharsets.UTF_8);
          out.writeInt(name.length);
          out.write(name);
          out.writeDouble(binding.getValue());
        }
        out.writeInt(shots);
        out.writeLong(seed);
      }
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(bytes.toByteArray()));
    } catch (IOException exception) {
      throw new AssertionError(exception);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }
}
