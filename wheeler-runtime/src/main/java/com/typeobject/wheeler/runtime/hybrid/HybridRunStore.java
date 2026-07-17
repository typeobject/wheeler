package com.typeobject.wheeler.runtime.hybrid;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.EOFException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/** Canonical integrity-protected version-1 persistence for hybrid snapshots. */
public final class HybridRunStore {
  private static final int MAGIC = 0x57485231; // WHR1
  private static final int DIGEST_BYTES = 32;
  private static final int MAX_BYTES = 16 * 1024 * 1024;
  private static final int MAX_TEXT_BYTES = 16 * 1024;

  public byte[] encode(HybridRunSnapshot snapshot) {
    Objects.requireNonNull(snapshot, "snapshot");
    try {
      ByteArrayOutputStream bytes = new ByteArrayOutputStream();
      try (DataOutputStream out = new DataOutputStream(bytes)) {
        out.writeInt(MAGIC);
        out.writeInt(snapshot.schemaVersion());
        writeText(out, snapshot.artifactId());
        writeText(out, snapshot.runId());
        out.writeInt(snapshot.mode().ordinal());
        out.writeInt(snapshot.status().ordinal());
        writeText(out, snapshot.activeBranch());
        out.writeLong(snapshot.commitHorizon());
        out.writeInt(snapshot.limits().maxEvents());
        out.writeInt(snapshot.limits().maxBranches());
        out.writeInt(snapshot.limits().maxRetries());
        writeContinuation(out, snapshot.continuation());
        out.writeInt(snapshot.events().size());
        for (HybridEvent event : snapshot.events()) {
          writeEvent(out, event);
        }
      }
      byte[] payload = bytes.toByteArray();
      if (payload.length > MAX_BYTES - DIGEST_BYTES) {
        throw new HybridRunException("Hybrid snapshot exceeds persistence limit");
      }
      byte[] digest = digest(payload);
      byte[] encoded = Arrays.copyOf(payload, payload.length + digest.length);
      System.arraycopy(digest, 0, encoded, payload.length, digest.length);
      return encoded;
    } catch (IOException exception) {
      throw new AssertionError(exception);
    }
  }

  public HybridRunSnapshot decode(byte[] encoded) {
    Objects.requireNonNull(encoded, "encoded");
    if (encoded.length <= DIGEST_BYTES || encoded.length > MAX_BYTES) {
      throw new HybridRunException("Invalid hybrid snapshot length");
    }
    byte[] payload = Arrays.copyOf(encoded, encoded.length - DIGEST_BYTES);
    byte[] actual = Arrays.copyOfRange(encoded, payload.length, encoded.length);
    if (!MessageDigest.isEqual(digest(payload), actual)) {
      throw new HybridRunException("Hybrid snapshot integrity check failed");
    }
    try (DataInputStream in = new DataInputStream(new ByteArrayInputStream(payload))) {
      if (in.readInt() != MAGIC) {
        throw new HybridRunException("Invalid hybrid snapshot magic");
      }
      int schema = in.readInt();
      String artifact = readText(in);
      String runId = readText(in);
      RunMode mode = enumValue(RunMode.values(), in.readInt(), "run mode");
      RunStatus status = enumValue(RunStatus.values(), in.readInt(), "run status");
      String branch = readText(in);
      long horizon = in.readLong();
      HybridRunLimits limits = new HybridRunLimits(in.readInt(), in.readInt(), in.readInt());
      HybridContinuation continuation = readContinuation(in);
      int count = boundedCount(in.readInt(), limits.maxEvents(), "event");
      List<HybridEvent> events = new ArrayList<>(count);
      for (int i = 0; i < count; i++) {
        events.add(readEvent(in));
      }
      if (in.available() != 0) {
        throw new HybridRunException("Trailing hybrid snapshot payload");
      }
      HybridRunSnapshot snapshot = new HybridRunSnapshot(
          schema, artifact, runId, mode, status, branch, horizon, limits, continuation, events);
      validateReduction(snapshot);
      return snapshot;
    } catch (EOFException exception) {
      throw new HybridRunException("Truncated hybrid snapshot", exception);
    } catch (IOException | IllegalArgumentException exception) {
      throw new HybridRunException("Malformed hybrid snapshot: " + exception.getMessage(), exception);
    }
  }

  public void write(Path path, HybridRunSnapshot snapshot) throws IOException {
    Objects.requireNonNull(path, "path");
    Path absolute = path.toAbsolutePath();
    Path parent = absolute.getParent();
    if (parent != null) {
      Files.createDirectories(parent);
    }
    Path temporary = absolute.resolveSibling(absolute.getFileName() + "." + UUID.randomUUID() + ".tmp");
    try {
      Files.write(temporary, encode(snapshot));
      try {
        Files.move(temporary, absolute, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
      } catch (java.nio.file.AtomicMoveNotSupportedException exception) {
        Files.move(temporary, absolute, StandardCopyOption.REPLACE_EXISTING);
      }
    } finally {
      Files.deleteIfExists(temporary);
    }
  }

  public HybridRunSnapshot read(Path path) throws IOException {
    return decode(Files.readAllBytes(path));
  }

  private static void validateReduction(HybridRunSnapshot snapshot) {
    HybridEventReducer.HybridReduction reduction = HybridEventReducer.reduce(snapshot.events());
    if (!reduction.runId().equals(snapshot.runId())
        || !reduction.activeBranch().equals(snapshot.activeBranch())
        || reduction.status() != snapshot.status()
        || reduction.commitHorizon() != snapshot.commitHorizon()) {
      throw new HybridRunException("Snapshot header disagrees with reduced events");
    }
  }

  private static void writeContinuation(DataOutputStream out, HybridContinuation value)
      throws IOException {
    writeText(out, value.artifactId());
    writeText(out, value.runId());
    writeText(out, value.branchId());
    out.writeInt(value.workflowIndex());
    out.writeInt(value.globals().size());
    for (Map.Entry<String, Long> entry : new java.util.TreeMap<>(value.globals()).entrySet()) {
      writeText(out, entry.getKey());
      out.writeLong(entry.getValue());
    }
    writeText(out, value.pendingJobId());
    writeText(out, value.pendingTarget());
    out.writeInt(value.transactionPhase().ordinal());
    out.writeInt(value.transactionWorkflowIndex());
    out.writeInt(value.transactionObservationCount());
    writeGlobals(out, value.transactionGlobals());
  }

  private static HybridContinuation readContinuation(DataInputStream in) throws IOException {
    String artifact = readText(in);
    String run = readText(in);
    String branch = readText(in);
    int index = in.readInt();
    Map<String, Long> globals = readGlobals(in);
    String pendingJob = readText(in);
    String pendingTarget = readText(in);
    TransactionPhase phase = enumValue(
        TransactionPhase.values(), in.readInt(), "transaction phase");
    int transactionIndex = in.readInt();
    int transactionObservations = in.readInt();
    Map<String, Long> transactionGlobals = readGlobals(in);
    return new HybridContinuation(
        artifact,
        run,
        branch,
        index,
        globals,
        pendingJob,
        pendingTarget,
        phase,
        transactionIndex,
        transactionObservations,
        transactionGlobals);
  }

  private static void writeGlobals(DataOutputStream out, Map<String, Long> globals)
      throws IOException {
    out.writeInt(globals.size());
    for (Map.Entry<String, Long> entry : new java.util.TreeMap<>(globals).entrySet()) {
      writeText(out, entry.getKey());
      out.writeLong(entry.getValue());
    }
  }

  private static Map<String, Long> readGlobals(DataInputStream in) throws IOException {
    int count = boundedCount(in.readInt(), 65_535, "global");
    Map<String, Long> globals = new HashMap<>();
    for (int i = 0; i < count; i++) {
      if (globals.put(readText(in), in.readLong()) != null) {
        throw new HybridRunException("Duplicate continuation global");
      }
    }
    return globals;
  }

  private static void writeEvent(DataOutputStream out, HybridEvent event) throws IOException {
    writeText(out, event.identity());
    writeText(out, event.runId());
    out.writeLong(event.sequence());
    out.writeInt(event.kind().ordinal());
    writeText(out, event.branchId());
    out.writeInt(event.workflowIndex());
    writeText(out, event.jobId());
    writeText(out, event.target());
    out.writeLong(event.value());
    writeText(out, event.detail());
  }

  private static HybridEvent readEvent(DataInputStream in) throws IOException {
    return new HybridEvent(
        readText(in),
        readText(in),
        in.readLong(),
        enumValue(HybridEventKind.values(), in.readInt(), "event kind"),
        readText(in),
        in.readInt(),
        readText(in),
        readText(in),
        in.readLong(),
        readText(in));
  }

  private static void writeText(DataOutputStream out, String value) throws IOException {
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    if (bytes.length > MAX_TEXT_BYTES) {
      throw new HybridRunException("Persisted text exceeds limit");
    }
    out.writeInt(bytes.length);
    out.write(bytes);
  }

  private static String readText(DataInputStream in) throws IOException {
    int length = boundedCount(in.readInt(), MAX_TEXT_BYTES, "text byte");
    byte[] bytes = in.readNBytes(length);
    if (bytes.length != length) {
      throw new EOFException("Truncated persisted text");
    }
    return new String(bytes, StandardCharsets.UTF_8);
  }

  private static int boundedCount(int count, int maximum, String name) {
    if (count < 0 || count > maximum) {
      throw new HybridRunException("Invalid " + name + " count " + count);
    }
    return count;
  }

  private static <T> T enumValue(T[] values, int ordinal, String name) {
    if (ordinal < 0 || ordinal >= values.length) {
      throw new HybridRunException("Unknown " + name + " " + ordinal);
    }
    return values[ordinal];
  }

  private static byte[] digest(byte[] payload) {
    try {
      return MessageDigest.getInstance("SHA-256").digest(payload);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

}
