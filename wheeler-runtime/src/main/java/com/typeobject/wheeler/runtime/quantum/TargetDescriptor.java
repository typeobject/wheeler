package com.typeobject.wheeler.runtime.quantum;

import java.util.Objects;
import java.util.Set;

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
    if (maxQubits <= 0 || maxShots <= 0) {
      throw new IllegalArgumentException("Target limits must be positive");
    }
  }

  public void require(TargetCapability capability) {
    if (!capabilities.contains(capability)) {
      throw new QuantumExecutionException(
          "Target " + target + " lacks capability " + capability);
    }
  }
}
