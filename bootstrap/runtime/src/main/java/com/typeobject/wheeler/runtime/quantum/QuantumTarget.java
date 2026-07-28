package com.typeobject.wheeler.runtime.quantum;

/** Capability-based asynchronous quantum execution target. */
public interface QuantumTarget {
  TargetDescriptor descriptor();

  QuantumJob submit(QuantumSubmission submission);

  /** Submit an ordered batch without changing individual submission or result identity. */
  default QuantumBatchJob submitBatch(QuantumBatch batch) {
    descriptor().require(TargetCapability.BATCH_SUBMISSION);
    return new CompositeQuantumBatchJob(this, batch);
  }

  /** Recover an acknowledged job without creating another physical submission. */
  default QuantumJob recover(String jobId, QuantumSubmission submission) {
    throw new QuantumExecutionException(
        "Target does not support recovery of acknowledged job " + jobId);
  }
}
