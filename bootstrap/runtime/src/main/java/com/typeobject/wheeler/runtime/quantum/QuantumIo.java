package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.runtime.io.IoProviderResult;
import com.typeobject.wheeler.runtime.io.IoRequest;
import java.time.Duration;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

/** Adapts one quantum target submission to the shared structured I/O lifecycle. */
public final class QuantumIo {
  private static final long MAX_TIMEOUT_MILLIS = 86_400_000L;

  private QuantumIo() {}

  /** Prepares target submission, wait, cancellation, and result delivery as one I/O request. */
  public static IoRequest<QuantumResult> request(
      QuantumTarget target, QuantumSubmission submission, Duration timeout) {
    Objects.requireNonNull(target, "target");
    Objects.requireNonNull(submission, "submission");
    Objects.requireNonNull(timeout, "timeout");
    long timeoutMillis;
    try {
      timeoutMillis = timeout.toMillis();
    } catch (ArithmeticException failure) {
      throw new IllegalArgumentException("quantum I/O timeout is out of bounds", failure);
    }
    if (timeoutMillis < 1 || timeoutMillis > MAX_TIMEOUT_MILLIS) {
      throw new IllegalArgumentException("quantum I/O timeout must be between 1 ms and 1 day");
    }
    long work = work(submission);
    AtomicBoolean cancellationRequested = new AtomicBoolean();
    AtomicBoolean cancellationAccepted = new AtomicBoolean();
    AtomicReference<QuantumJob> job = new AtomicReference<>();
    Runnable cancel = () -> {
      cancellationRequested.set(true);
      QuantumJob active = job.get();
      if (active != null) {
        try {
          cancellationAccepted.set(active.cancel());
        } catch (RuntimeException ignored) {
          cancellationAccepted.set(false);
        }
      }
    };
    return IoRequest.prepare(
        "quantum:" + submission.identity(),
        work,
        () -> execute(
            target,
            submission,
            timeout,
            cancellationRequested,
            cancellationAccepted,
            job,
            cancel,
            work),
        () -> {},
        cancel::run);
  }

  private static IoProviderResult<QuantumResult> execute(
      QuantumTarget target,
      QuantumSubmission submission,
      Duration timeout,
      AtomicBoolean cancellationRequested,
      AtomicBoolean cancellationAccepted,
      AtomicReference<QuantumJob> job,
      Runnable cancel,
      long work) {
    if (cancellationRequested.get()) {
      return IoProviderResult.canceledBeforeEffect("quantum-canceled-before-submission");
    }
    QuantumJob submitted;
    try {
      submitted = target.submit(submission);
    } catch (RuntimeException failure) {
      return IoProviderResult.failure(failureDetail("quantum-submit", failure), 0);
    }
    if (!job.compareAndSet(null, submitted)) {
      return IoProviderResult.uncertain("quantum-job-publication-race", 0);
    }
    if (cancellationRequested.get()) {
      cancel.run();
    }
    try {
      QuantumResult result = submitted.await(timeout);
      if (!result.submissionIdentity().equals(submission.identity())) {
        return IoProviderResult.failure("quantum-result-identity-mismatch", 0);
      }
      return IoProviderResult.success(result, work);
    } catch (RuntimeException failure) {
      if (cancellationRequested.get()) {
        String detail = bounded("quantum-cancel:" + submitted.id());
        return cancellationAccepted.get()
            ? IoProviderResult.canceledAfterPartial(detail, 1)
            : IoProviderResult.uncertain(detail, 0);
      }
      return IoProviderResult.failure(failureDetail("quantum-await", failure), 0);
    }
  }

  private static long work(QuantumSubmission submission) {
    long operations = 0;
    for (CircuitApplication application : submission.applications()) {
      QuantumCircuit circuit = submission.program().quantumCircuit(application.circuitId());
      operations = Math.addExact(operations, Math.max(1, circuit.operations().size()));
    }
    long work = Math.multiplyExact(operations, submission.shots());
    if (work < 1 || work > 1_000_000_000L) {
      throw new IllegalArgumentException("quantum I/O work is outside the request limit");
    }
    return work;
  }

  private static String failureDetail(String phase, RuntimeException failure) {
    return bounded(phase + ":" + failure.getClass().getSimpleName());
  }

  private static String bounded(String detail) {
    return detail.length() <= 256 ? detail : detail.substring(0, 256);
  }
}
