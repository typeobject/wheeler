package com.typeobject.wheeler.runtime.quantum;

/** Capability-based asynchronous quantum execution target. */
public interface QuantumTarget {
  TargetDescriptor descriptor();

  QuantumJob submit(QuantumTask task);

  /** Submit an ordered batch without changing individual task or result identity. */
  default QuantumBatchJob submitBatch(QuantumBatch batch) {
    descriptor().require(TargetCapability.BATCH_SUBMISSION);
    return new CompositeQuantumBatchJob(this, batch);
  }

  /** Recover an acknowledged job without creating another physical submission. */
  default QuantumJob recover(String jobId, QuantumTask task) {
    throw new QuantumExecutionException(
        "Target does not support recovery of acknowledged job " + jobId);
  }
}
