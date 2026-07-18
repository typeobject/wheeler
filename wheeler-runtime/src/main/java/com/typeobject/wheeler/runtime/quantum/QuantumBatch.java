package com.typeobject.wheeler.runtime.quantum;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;

/** Ordered content-identified set of independently bound quantum tasks. */
public record QuantumBatch(List<QuantumTask> tasks) {
  public QuantumBatch {
    tasks = List.copyOf(tasks);
    if (tasks.isEmpty() || tasks.size() > 100_000) {
      throw new IllegalArgumentException("Quantum batch size must be between 1 and 100000");
    }
  }

  public String identity() {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      for (QuantumTask task : tasks) {
        byte[] identity = task.identity().getBytes(StandardCharsets.US_ASCII);
        digest.update((byte) (identity.length >>> 8));
        digest.update((byte) identity.length);
        digest.update(identity);
      }
      return HexFormat.of().formatHex(digest.digest());
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }
}
