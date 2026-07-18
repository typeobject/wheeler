package com.typeobject.wheeler.runtime.quantum;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

/** Immutable capability snapshot used for planning one submission. */
public record TargetDescriptor(
    String adapter,
    String target,
    Set<TargetCapability> capabilities,
    int maxQubits,
    int maxShots) {
  public TargetDescriptor {
    Objects.requireNonNull(adapter, "adapter");
    Objects.requireNonNull(target, "target");
    capabilities = Set.copyOf(capabilities);
    if (adapter.isBlank() || target.isBlank() || adapter.length() > 1024 || target.length() > 1024) {
      throw new IllegalArgumentException("Target identity is blank or oversized");
    }
    if (maxQubits <= 0 || maxShots <= 0) {
      throw new IllegalArgumentException("Target limits must be positive");
    }
  }

  public void require(TargetCapability capability) {
    require(Set.of(capability));
  }

  public void require(Set<TargetCapability> required) {
    String missing = required.stream()
        .filter(capability -> !capabilities.contains(capability))
        .sorted()
        .map(Enum::name)
        .collect(Collectors.joining(", "));
    if (!missing.isEmpty()) {
      throw new QuantumExecutionException(
          "Target " + target + " lacks capabilities: " + missing);
    }
  }

  /** Stable identity independent of set construction or host hash order. */
  public String identity() {
    String canonical = adapter + "\n" + target + "\n"
        + capabilities.stream().sorted().map(Enum::name).collect(Collectors.joining(","))
        + "\n" + maxQubits + "\n" + maxShots;
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
          .digest(canonical.getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }
}
