package com.typeobject.wheeler.runtime.quantum;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicLong;

/** Provider-neutral ordered batch over ordinary asynchronous jobs. */
final class CompositeQuantumBatchJob implements QuantumBatchJob {
  private static final AtomicLong SEQUENCE = new AtomicLong();

  private final String id = "batch-" + SEQUENCE.incrementAndGet();
  private final QuantumBatch batch;
  private final List<QuantumJob> jobs;

  CompositeQuantumBatchJob(QuantumTarget target, QuantumBatch batch) {
    this.batch = batch;
    List<QuantumJob> submitted = new ArrayList<>(batch.tasks().size());
    for (QuantumTask task : batch.tasks()) {
      submitted.add(target.submit(task));
    }
    this.jobs = List.copyOf(submitted);
  }

  @Override
  public String id() {
    return id;
  }

  @Override
  public String batchIdentity() {
    return batch.identity();
  }

  @Override
  public List<QuantumJob> jobs() {
    return jobs;
  }

  @Override
  public JobState state() {
    List<JobState> states = jobs.stream().map(QuantumJob::state).toList();
    if (states.stream().allMatch(state -> state == JobState.SUCCEEDED)) {
      return JobState.SUCCEEDED;
    }
    if (states.stream().anyMatch(state -> state == JobState.FAILED)) {
      return JobState.FAILED;
    }
    if (states.stream().anyMatch(state -> state == JobState.RUNNING)) {
      return JobState.RUNNING;
    }
    if (states.stream().anyMatch(state -> state == JobState.CANCEL_REQUESTED)) {
      return JobState.CANCEL_REQUESTED;
    }
    if (states.stream().allMatch(state -> state == JobState.CANCELLED)) {
      return JobState.CANCELLED;
    }
    return JobState.QUEUED;
  }

  @Override
  public boolean cancel() {
    boolean requested = false;
    for (QuantumJob job : jobs) {
      requested |= job.cancel();
    }
    return requested;
  }

  @Override
  public QuantumBatchResult await(Duration timeout) {
    if (timeout.isNegative() || timeout.isZero()) {
      throw new IllegalArgumentException("Timeout must be positive");
    }
    long deadline = Math.addExact(System.nanoTime(), timeout.toNanos());
    List<QuantumResult> results = new ArrayList<>(jobs.size());
    for (int index = 0; index < jobs.size(); index++) {
      long remaining = deadline - System.nanoTime();
      if (remaining <= 0) {
        throw new QuantumExecutionException("Timed out waiting for quantum batch " + id);
      }
      QuantumResult result = jobs.get(index).await(Duration.ofNanos(remaining));
      QuantumTask task = batch.tasks().get(index);
      if (!result.jobId().equals(jobs.get(index).id())
          || !result.taskIdentity().equals(task.identity())) {
        throw new QuantumExecutionException("Quantum batch result identity mismatch at " + index);
      }
      results.add(result);
    }
    return new QuantumBatchResult(id, batch.identity(), results);
  }
}
