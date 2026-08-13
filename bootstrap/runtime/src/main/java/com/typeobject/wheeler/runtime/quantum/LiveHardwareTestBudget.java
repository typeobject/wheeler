package com.typeobject.wheeler.runtime.quantum;

/** Invocation-local fail-closed admission ledger for nondeterministic hardware evidence. */
public final class LiveHardwareTestBudget {
  private final LiveHardwareTestPolicy policy;
  private int admittedSubmissions;
  private long admittedShots;

  public LiveHardwareTestBudget(LiveHardwareTestPolicy policy) {
    this.policy = java.util.Objects.requireNonNull(policy, "policy");
  }

  public synchronized void admit(QuantumSubmission submission) {
    java.util.Objects.requireNonNull(submission, "submission");
    if (!policy.enabled()) {
      throw new QuantumExecutionException("Live hardware tests require explicit opt-in");
    }
    int nextSubmissions = Math.addExact(admittedSubmissions, 1);
    long nextShots = Math.addExact(admittedShots, submission.shots());
    if (nextSubmissions > policy.maxSubmissions() || nextShots > policy.maxShots()) {
      throw new QuantumExecutionException("Live hardware test budget exhausted before submission");
    }
    admittedSubmissions = nextSubmissions;
    admittedShots = nextShots;
  }

  public synchronized int admittedSubmissions() {
    return admittedSubmissions;
  }

  public synchronized long admittedShots() {
    return admittedShots;
  }
}
