package com.typeobject.wheeler.runtime.hybrid;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;

/** Immutable content-identified transition in a hybrid run. */
public record HybridEvent(
    String identity,
    String runId,
    long sequence,
    HybridEventKind kind,
    String branchId,
    int workflowIndex,
    String jobId,
    String target,
    long value,
    String detail) {
  private static final int MAX_TEXT = 4096;

  public HybridEvent {
    identity = bounded(identity, "identity");
    runId = bounded(runId, "runId");
    kind = Objects.requireNonNull(kind, "kind");
    branchId = bounded(branchId, "branchId");
    jobId = bounded(jobId, "jobId");
    target = bounded(target, "target");
    detail = bounded(detail, "detail");
    if (sequence < 0 || workflowIndex < -1) {
      throw new IllegalArgumentException("Invalid hybrid event position");
    }
    String expected = identityOf(
        runId, sequence, kind, branchId, workflowIndex, jobId, target, value, detail);
    if (!identity.equals(expected)) {
      throw new IllegalArgumentException("Hybrid event identity does not match content");
    }
  }

  public static HybridEvent create(
      String runId,
      long sequence,
      HybridEventKind kind,
      String branchId,
      int workflowIndex,
      String jobId,
      String target,
      long value,
      String detail) {
    String identity = identityOf(
        runId, sequence, kind, branchId, workflowIndex, jobId, target, value, detail);
    return new HybridEvent(
        identity, runId, sequence, kind, branchId, workflowIndex, jobId, target, value, detail);
  }

  private static String identityOf(
      String runId,
      long sequence,
      HybridEventKind kind,
      String branchId,
      int workflowIndex,
      String jobId,
      String target,
      long value,
      String detail) {
    try {
      ByteArrayOutputStream bytes = new ByteArrayOutputStream();
      try (DataOutputStream out = new DataOutputStream(bytes)) {
        writeText(out, runId);
        out.writeLong(sequence);
        out.writeInt(kind.ordinal());
        writeText(out, branchId);
        out.writeInt(workflowIndex);
        writeText(out, jobId);
        writeText(out, target);
        out.writeLong(value);
        writeText(out, detail);
      }
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes.toByteArray()));
    } catch (IOException exception) {
      throw new AssertionError(exception);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static void writeText(DataOutputStream out, String text) throws IOException {
    byte[] bytes = bounded(text, "event field").getBytes(StandardCharsets.UTF_8);
    out.writeInt(bytes.length);
    out.write(bytes);
  }

  private static String bounded(String value, String name) {
    Objects.requireNonNull(value, name);
    if (value.length() > MAX_TEXT) {
      throw new IllegalArgumentException(name + " exceeds " + MAX_TEXT + " characters");
    }
    return value;
  }
}
