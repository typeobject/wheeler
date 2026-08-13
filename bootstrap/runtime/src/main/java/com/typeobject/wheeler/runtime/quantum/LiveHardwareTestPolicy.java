package com.typeobject.wheeler.runtime.quantum;

/** Explicit opt-in and hard admission ceilings for one live hardware test invocation. */
public record LiveHardwareTestPolicy(
    boolean enabled,
    int maxSubmissions,
    long maxShots) {
  public LiveHardwareTestPolicy {
    if (maxSubmissions < 0 || maxShots < 0
        || enabled && (maxSubmissions == 0 || maxShots == 0)) {
      throw new IllegalArgumentException("Invalid live hardware test budget");
    }
  }

  public static LiveHardwareTestPolicy disabled() {
    return new LiveHardwareTestPolicy(false, 0, 0);
  }

  public static LiveHardwareTestPolicy enabled(int maxSubmissions, long maxShots) {
    return new LiveHardwareTestPolicy(true, maxSubmissions, maxShots);
  }
}
