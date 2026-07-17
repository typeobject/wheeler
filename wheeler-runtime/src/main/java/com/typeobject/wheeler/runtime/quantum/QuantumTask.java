package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;

/** A complete portable prepare-unitary-measure target submission. */
public record QuantumTask(
    Program program,
    int registerId,
    long basisState,
    List<CircuitApplication> applications,
    int shots,
    long seed) {
  public QuantumTask {
    Objects.requireNonNull(program, "program");
    applications = List.copyOf(applications);
    if (registerId < 0 || shots <= 0) {
      throw new IllegalArgumentException("Invalid quantum task");
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
