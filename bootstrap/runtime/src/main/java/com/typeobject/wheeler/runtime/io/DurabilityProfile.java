package com.typeobject.wheeler.runtime.io;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/** Closed failure, atomicity, replication, and backend assumptions for one receipt chain. */
public record DurabilityProfile(
    FailureModel failureModel,
    Atomicity atomicity,
    int replicas,
    int quorum,
    String backendProfileIdentity,
    List<String> assumptions) {
  /** Failure event against which evidence is interpreted. */
  public enum FailureModel {
    PROCESS_CRASH,
    KERNEL_CRASH,
    POWER_LOSS,
    FAILURE_DOMAINS
  }

  /** Protected atomic unit; this is independent of visibility and persistence strength. */
  public enum Atomicity {
    RANGE,
    FILE_GENERATION,
    NAMESPACE_ENTRY,
    QUORUM_GENERATION
  }

  public DurabilityProfile {
    Objects.requireNonNull(failureModel, "failureModel");
    Objects.requireNonNull(atomicity, "atomicity");
    if (replicas < 1 || replicas > 1024 || quorum < 1 || quorum > replicas) {
      throw new IllegalArgumentException("replication and quorum are outside closed bounds");
    }
    backendProfileIdentity = DurabilitySubject.sha256(
        "backendProfileIdentity", backendProfileIdentity);
    Objects.requireNonNull(assumptions, "assumptions");
    if (assumptions.size() > 32) {
      throw new IllegalArgumentException("durability profile has too many assumptions");
    }
    List<String> checked = new ArrayList<>(assumptions.size());
    String previous = null;
    for (String assumption : assumptions) {
      String value = DurabilitySubject.visibleAscii("assumption", assumption, 128, false);
      if (previous != null && previous.compareTo(value) >= 0) {
        throw new IllegalArgumentException("durability assumptions must be unique and sorted");
      }
      checked.add(value);
      previous = value;
    }
    assumptions = List.copyOf(checked);
  }
}
