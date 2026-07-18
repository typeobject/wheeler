package com.typeobject.wheeler.runtime.quantum;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;

/** Asynchronous portable target over an application-supplied OpenQASM 3 executor. */
public final class OpenQasmTarget implements QuantumTarget {
  private static final AtomicLong JOB_SEQUENCE = new AtomicLong();

  private final OpenQasmExecutor executor;
  private final TargetDescriptor descriptor;
  private final ConcurrentMap<String, StoredJob> jobs = new ConcurrentHashMap<>();

  public OpenQasmTarget(
      String target, int maxQubits, int maxShots, OpenQasmExecutor executor) {
    this.executor = Objects.requireNonNull(executor, "executor");
    this.descriptor = new TargetDescriptor(
        "openqasm-3",
        target,
        Set.of(TargetCapability.STATIC_CIRCUIT, TargetCapability.PARAMETER_BINDING),
        maxQubits,
        maxShots);
  }

  @Override
  public TargetDescriptor descriptor() {
    return descriptor;
  }

  @Override
  public QuantumJob submit(QuantumTask task) {
    int qubits = task.program().quantumRegister(task.registerId()).qubits();
    if (qubits > descriptor.maxQubits() || task.shots() > descriptor.maxShots()) {
      throw new QuantumExecutionException("Task exceeds OpenQASM target limits");
    }
    String id = "openqasm-" + JOB_SEQUENCE.incrementAndGet();
    String qasm = new OpenQasm3Emitter().emit(task);
    QuantumJob job = new OpenQasmJob(id, task, qasm);
    jobs.put(id, new StoredJob(task.identity(), job));
    return job;
  }

  @Override
  public QuantumJob recover(String jobId, QuantumTask task) {
    StoredJob stored = jobs.get(jobId);
    if (stored == null || !stored.taskIdentity().equals(task.identity())) {
      throw new QuantumExecutionException("Unknown or mismatched OpenQASM job " + jobId);
    }
    return stored.job();
  }

  private record StoredJob(String taskIdentity, QuantumJob job) {}

  private final class OpenQasmJob implements QuantumJob {
    private final String id;
    private final AtomicReference<JobState> state = new AtomicReference<>(JobState.QUEUED);
    private final CompletableFuture<QuantumResult> future;

    private OpenQasmJob(String id, QuantumTask task, String qasm) {
      this.id = id;
      this.future = CompletableFuture.supplyAsync(() -> execute(task, qasm));
    }

    @Override
    public String id() {
      return id;
    }

    @Override
    public JobState state() {
      return state.get();
    }

    @Override
    public boolean cancel() {
      JobState current = state.get();
      if (current == JobState.SUCCEEDED || current == JobState.FAILED || current == JobState.CANCELLED) {
        return false;
      }
      state.set(JobState.CANCEL_REQUESTED);
      boolean cancelled = future.cancel(true);
      state.set(JobState.CANCELLED);
      return cancelled;
    }

    @Override
    public QuantumResult await(Duration timeout) {
      if (timeout.isNegative() || timeout.isZero()) {
        throw new IllegalArgumentException("Timeout must be positive");
      }
      try {
        return future.get(timeout.toMillis(), TimeUnit.MILLISECONDS);
      } catch (TimeoutException exception) {
        throw new QuantumExecutionException("Timed out waiting for OpenQASM job " + id);
      } catch (InterruptedException exception) {
        Thread.currentThread().interrupt();
        throw new QuantumExecutionException("Interrupted waiting for OpenQASM job " + id);
      } catch (ExecutionException exception) {
        Throwable cause = exception.getCause();
        throw new QuantumExecutionException(
            "OpenQASM executor failed: " + (cause == null ? exception.getMessage() : cause.getMessage()));
      }
    }

    private QuantumResult execute(QuantumTask task, String qasm) {
      state.set(JobState.RUNNING);
      try {
        List<Long> outcomes = List.copyOf(executor.execute(qasm, task.shots(), task.seed()));
        validateOutcomes(task, outcomes);
        Map<Long, Long> counts = new LinkedHashMap<>();
        outcomes.forEach(value -> counts.merge(value, 1L, Long::sum));
        state.set(JobState.SUCCEEDED);
        return new QuantumResult(id, task.identity(), outcomes, counts, descriptor.target());
      } catch (QuantumExecutionException exception) {
        state.set(JobState.FAILED);
        throw exception;
      } catch (Exception exception) {
        state.set(JobState.FAILED);
        throw new QuantumExecutionException(exception.getMessage());
      }
    }
  }

  private static void validateOutcomes(QuantumTask task, List<Long> outcomes) {
    if (outcomes.size() != task.shots()) {
      throw new QuantumExecutionException(
          "Executor returned %d outcomes for %d shots".formatted(outcomes.size(), task.shots()));
    }
    int qubits = task.program().quantumRegister(task.registerId()).qubits();
    for (long outcome : outcomes) {
      if (outcome < 0 || (qubits < 63 && outcome >= (1L << qubits))) {
        throw new QuantumExecutionException("Executor outcome exceeds register width");
      }
    }
  }
}
