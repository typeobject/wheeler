package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import com.typeobject.wheeler.runtime.io.DeterministicIo;
import com.typeobject.wheeler.runtime.io.IoCompletion;
import com.typeobject.wheeler.runtime.io.IoLimits;
import com.typeobject.wheeler.runtime.io.IoOperation;
import com.typeobject.wheeler.runtime.io.IoRequest;
import com.typeobject.wheeler.runtime.io.IoScope;
import com.typeobject.wheeler.runtime.io.ThreadedIo;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

/** Conformance evidence for quantum submissions under the common I/O lifecycle. */
final class QuantumIoTest {
  private static final IoLimits LIMITS = new IoLimits(8, 8, 4, 4, 8, 64);

  @Test
  void requestConstructionIsPureAndQueuedCancellationAllocatesNoTargetJob() {
    AtomicInteger submissions = new AtomicInteger();
    StateVectorTarget delegate = new StateVectorTarget();
    QuantumTarget target = countingTarget(delegate, submissions);
    IoRequest<QuantumResult> request =
        QuantumIo.request(target, submission(), Duration.ofSeconds(1));
    assertEquals(0, submissions.get());
    IoScope scope = new DeterministicIo(DeterministicIo.Delivery.DELAYED).scope(LIMITS);
    IoOperation<QuantumResult> operation = scope.submit(request);

    operation.cancel();
    IoCompletion<QuantumResult> completion = operation.await();

    assertEquals(0, submissions.get());
    assertEquals(IoCompletion.TerminalKind.CANCELED, completion.terminalKind());
    assertEquals(
        IoCompletion.CancellationRelation.CANCELED_BEFORE_EFFECT,
        completion.cancellationRelation());
    scope.close();
  }

  @Test
  void successfulTargetResultUsesTheOrdinaryTerminalAndReapContract() {
    QuantumSubmission submission = submission();
    try (IoScope scope = new DeterministicIo(
        DeterministicIo.Delivery.INLINE).scope(LIMITS)) {
      IoCompletion<QuantumResult> completion = scope.await(
          QuantumIo.request(new StateVectorTarget(), submission, Duration.ofSeconds(1)));
      assertEquals(IoCompletion.TerminalKind.SUCCESS, completion.terminalKind());
      assertEquals(submission.identity(), completion.value().submissionIdentity());
      assertEquals(1, completion.value().firstOutcome());
      assertEquals(0, scope.activeOperationCount());
    }
    assertThrows(
        IllegalArgumentException.class,
        () -> QuantumIo.request(new StateVectorTarget(), submission, Duration.ZERO));
  }

  @Test
  void startedCancellationPropagatesToTheTargetAndRemainsExplicitlyPartial() throws Exception {
    BlockingJob job = new BlockingJob();
    QuantumTarget target = new QuantumTarget() {
      @Override
      public TargetDescriptor descriptor() {
        return new StateVectorTarget().descriptor();
      }

      @Override
      public QuantumJob submit(QuantumSubmission ignored) {
        return job;
      }
    };
    ThreadedIo backend = new ThreadedIo(1, 1);
    IoScope scope = backend.scope(LIMITS);
    IoOperation<QuantumResult> operation = scope.submit(
        QuantumIo.request(target, submission(), Duration.ofSeconds(1)));
    if (!job.awaiting.await(1, TimeUnit.SECONDS)) {
      throw new AssertionError("quantum job did not start");
    }

    assertFalse(operation.cancel());
    IoCompletion<QuantumResult> completion = operation.await();

    assertEquals(1, job.cancellations.get());
    assertEquals(IoCompletion.TerminalKind.CANCELED, completion.terminalKind());
    assertEquals(
        IoCompletion.CancellationRelation.CANCELED_AFTER_PARTIAL_EFFECT,
        completion.cancellationRelation());
    scope.close();
    backend.close();
  }

  private static QuantumTarget countingTarget(
      QuantumTarget delegate, AtomicInteger submissions) {
    return new QuantumTarget() {
      @Override
      public TargetDescriptor descriptor() {
        return delegate.descriptor();
      }

      @Override
      public QuantumJob submit(QuantumSubmission submission) {
        submissions.incrementAndGet();
        return delegate.submit(submission);
      }
    };
  }

  private static QuantumSubmission submission() {
    QuantumRegister register = new QuantumRegister(0, "q", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0, "flip", 0, List.of(GateOperation.of(Gate.X, 0)));
    FunctionBody entry = new FunctionBody(
        0,
        "main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());
    Program program = new Program(
        "quantum-io",
        ProgramKind.QUANTUM,
        0,
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        List.of(),
        List.of(entry),
        List.of(),
        List.of(register),
        List.of(circuit),
        List.of(WorkflowStep.halt()),
        Program.DEFAULT_MAX_HISTORY,
        Program.DEFAULT_MAX_STEPS);
    return new QuantumSubmission(
        program,
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        Map.of(),
        1,
        0);
  }

  private static final class BlockingJob implements QuantumJob {
    private final CountDownLatch awaiting = new CountDownLatch(1);
    private final CountDownLatch canceled = new CountDownLatch(1);
    private final CountDownLatch cancellationObserved = new CountDownLatch(1);
    private final AtomicInteger cancellations = new AtomicInteger();

    @Override
    public String id() {
      return "blocking-quantum-job";
    }

    @Override
    public JobState state() {
      return canceled.getCount() == 0 ? JobState.CANCELLED : JobState.RUNNING;
    }

    @Override
    public boolean cancel() {
      cancellations.incrementAndGet();
      canceled.countDown();
      try {
        if (!cancellationObserved.await(1, TimeUnit.SECONDS)) {
          throw new QuantumExecutionException("cancellation was not observed");
        }
      } catch (InterruptedException interrupted) {
        Thread.currentThread().interrupt();
        throw new QuantumExecutionException("cancellation was interrupted");
      }
      return true;
    }

    @Override
    public QuantumResult await(Duration timeout) {
      awaiting.countDown();
      try {
        if (!canceled.await(timeout.toMillis(), TimeUnit.MILLISECONDS)) {
          throw new QuantumExecutionException("blocking job timed out");
        }
      } catch (InterruptedException interrupted) {
        Thread.currentThread().interrupt();
        throw new QuantumExecutionException("blocking job interrupted");
      }
      cancellationObserved.countDown();
      throw new QuantumExecutionException("blocking job canceled");
    }
  }
}
