package com.typeobject.wheeler.runtime.quantum;

/** Opt-in budget gate around an application-supplied hardware target. */
public final class LiveHardwareTestTarget implements QuantumTarget {
  private final QuantumTarget target;
  private final LiveHardwareTestBudget budget;

  public LiveHardwareTestTarget(QuantumTarget target, LiveHardwareTestPolicy policy) {
    this.target = java.util.Objects.requireNonNull(target, "target");
    this.budget = new LiveHardwareTestBudget(policy);
  }

  @Override
  public TargetDescriptor descriptor() {
    return target.descriptor();
  }

  @Override
  public QuantumJob submit(QuantumSubmission submission) {
    budget.admit(submission);
    return target.submit(submission);
  }

  @Override
  public QuantumJob recover(String jobId, QuantumSubmission submission) {
    return target.recover(jobId, submission);
  }

  public LiveHardwareTestBudget budget() {
    return budget;
  }
}
