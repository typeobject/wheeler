package com.typeobject.wheeler.runtime.quantum;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Content identity for one target-lowered executable cache entry. */
final class TargetExecutableIdentity {
  private static final int MAX_POLICY_LENGTH = 1_024;

  private TargetExecutableIdentity() {}

  static String of(
      TargetDescriptor descriptor, String policyIdentity, QuantumSubmission submission) {
    Objects.requireNonNull(descriptor, "descriptor");
    Objects.requireNonNull(submission, "submission");
    if (policyIdentity == null
        || policyIdentity.isBlank()
        || policyIdentity.length() > MAX_POLICY_LENGTH) {
      throw new IllegalArgumentException("Target executable policy identity is invalid");
    }
    try {
      ByteArrayOutputStream bytes = new ByteArrayOutputStream();
      try (DataOutputStream output = new DataOutputStream(bytes)) {
        write(output, "wheeler-target-executable-1");
        write(output, descriptor.identity());
        write(output, policyIdentity);
        write(output, submission.identity());
        output.writeInt(submission.bindings().size());
        for (String name : new java.util.TreeSet<>(submission.bindings().keySet())) {
          write(output, name);
        }
      }
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(bytes.toByteArray()));
    } catch (IOException exception) {
      throw new AssertionError(exception);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static void write(DataOutputStream output, String value) throws IOException {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    output.writeInt(bytes.length);
    output.write(bytes);
  }
}
