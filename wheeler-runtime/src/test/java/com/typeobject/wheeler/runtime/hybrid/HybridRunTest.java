package com.typeobject.wheeler.runtime.hybrid;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import com.typeobject.wheeler.runtime.ExecutionResult;
import com.typeobject.wheeler.runtime.quantum.JobState;
import com.typeobject.wheeler.runtime.quantum.QuantumJob;
import com.typeobject.wheeler.runtime.quantum.QuantumResult;
import com.typeobject.wheeler.runtime.quantum.QuantumTarget;
import com.typeobject.wheeler.runtime.quantum.QuantumTask;
import com.typeobject.wheeler.runtime.quantum.TargetCapability;
import com.typeobject.wheeler.runtime.quantum.TargetDescriptor;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;

class HybridRunTest {
  private static final Duration TIMEOUT = Duration.ofSeconds(1);

  @Test
  void suspendsAppliesExactlyOnceAndReplaysWithoutTarget() {
    RecoverableTarget target = new RecoverableTarget(1);
    HybridRun run = HybridRun.start(program(), target);

    assertEquals(RunStatus.WAITING, run.advance());
    assertEquals(1, target.submissions);
    assertEquals(RunStatus.COMPLETED, run.resume(TIMEOUT));
    ExecutionResult recorded = run.result();
    ExecutionResult replayed = HybridRun.replay(program(), run.snapshot());

    assertEquals(Map.of("measured", 0L), recorded.globals());
    assertEquals(recorded.globals(), replayed.globals());
    assertEquals(recorded.measurements(), replayed.measurements());
    assertEquals(1, target.submissions, "replay must not call the target");
    assertThrows(HybridRunException.class, () -> run.resume(TIMEOUT));
  }

  @Test
  void reductionIsStableUnderReorderingAndDuplicateDelivery() {
    HybridRun run = HybridRun.start(program(), new RecoverableTarget(1));
    run.runToCompletion(TIMEOUT);
    List<HybridEvent> delivery = new ArrayList<>(run.events());
    delivery.add(run.events().get(2));
    Collections.reverse(delivery);

    var reduced = HybridEventReducer.reduce(delivery);

    assertEquals(RunStatus.COMPLETED, reduced.status());
    assertEquals(run.events(), reduced.events());
    assertEquals(1, reduced.applied().get(2).value());
  }

  @Test
  void waitingSnapshotRecoversAcknowledgedJobWithoutResubmission() {
    RecoverableTarget target = new RecoverableTarget(1);
    HybridRun original = HybridRun.start(program(), target);
    original.beginTransaction();
    original.advance();
    HybridRunStore store = new HybridRunStore();

    byte[] firstEncoding = store.encode(original.snapshot());
    HybridRunSnapshot decoded = store.decode(firstEncoding);
    assertArrayEquals(firstEncoding, store.encode(decoded));
    HybridRun restored = HybridRun.restore(program(), target, decoded);

    assertEquals(1, target.submissions);
    assertEquals(1, target.recoveries);
    assertEquals(TransactionPhase.PREPARED_EXTERNAL, restored.transactionPhase());
    assertEquals(RunStatus.COMPLETED, restored.resume(TIMEOUT));
    assertEquals(Map.of("measured", 0L), restored.result().globals());
  }

  @Test
  void retryCreatesNewBranchAndSubmissionLineage() {
    RecoverableTarget target = new RecoverableTarget(1);
    HybridRun run = HybridRun.start(program(), target);
    run.advance();
    String firstJob = target.lastJobId;

    String retryJob = run.retry();

    assertNotEquals(firstJob, retryJob);
    assertEquals("retry-1", run.activeBranch());
    assertEquals(2, target.submissions);
    assertEquals(RunStatus.COMPLETED, run.resume(TIMEOUT));
    assertTrue(run.events().stream().anyMatch(
        event -> event.kind() == HybridEventKind.BRANCH_DISCARDED));
  }

  @Test
  void abortBeforeObservationCancelsAndRestartsFromClassicalCheckpoint() {
    RecoverableTarget target = new RecoverableTarget(1);
    HybridRun run = HybridRun.start(transactionProgram(), target);
    run.beginTransaction();
    assertEquals(RunStatus.WAITING, run.advance());
    assertEquals(TransactionPhase.PREPARED_EXTERNAL, run.transactionPhase());

    TransactionAbort abort = run.abortTransaction();

    assertTrue(abort.cancellationRequested());
    assertFalse(abort.observationDiscarded());
    assertEquals("abort-1", abort.activeBranch());
    assertEquals(TransactionPhase.NONE, run.transactionPhase());
    assertEquals(RunStatus.WAITING, run.advance());
    assertEquals(RunStatus.COMPLETED, run.resume(TIMEOUT));
    assertEquals(2, target.submissions);
  }

  @Test
  void abortAfterObservationRestoresClassicalStateButNotQuantumState() {
    RecoverableTarget target = new RecoverableTarget(1);
    HybridRun run = HybridRun.start(transactionProgram(), target);
    run.beginTransaction();
    run.runToCompletion(TIMEOUT);
    assertEquals(TransactionPhase.OBSERVED, run.transactionPhase());

    TransactionAbort abort = run.abortTransaction();

    assertFalse(abort.cancellationRequested());
    assertTrue(abort.observationDiscarded());
    assertEquals(RunStatus.ACTIVE, run.status());
    assertEquals(RunStatus.WAITING, run.advance());
    assertEquals(RunStatus.COMPLETED, run.resume(TIMEOUT));
    assertEquals(2, target.submissions, "abort after observation requires fresh preparation");
    assertEquals(1, run.result().measurements().size());
  }

  @Test
  void commitMakesTransactionAbortUnavailable() {
    HybridRun run = HybridRun.start(program(), new RecoverableTarget(1));
    run.beginTransaction();
    run.runToCompletion(TIMEOUT);

    assertEquals(TransactionPhase.COMMITTED, run.transactionPhase());
    assertThrows(HybridRunException.class, run::abortTransaction);
  }

  @Test
  void malformedResultCannotMutateContinuation() {
    RecoverableTarget target = new RecoverableTarget(1);
    target.wrongTaskIdentity = true;
    HybridRun run = HybridRun.start(program(), target);
    run.advance();
    HybridRunSnapshot before = run.snapshot();

    assertThrows(HybridRunException.class, () -> run.resume(TIMEOUT));

    assertEquals(RunStatus.WAITING, run.status());
    assertEquals(before.continuation().globals(), run.snapshot().continuation().globals());
    assertEquals(before.events(), run.events());
  }

  @Test
  void cancelQuarantinesLateCompletion() {
    RecoverableTarget target = new RecoverableTarget(1);
    HybridRun run = HybridRun.start(program(), target);
    run.advance();

    assertTrue(run.cancel());

    assertEquals(RunStatus.CANCELLED, run.status());
    assertFalse(run.snapshot().continuation().waiting());
    assertThrows(HybridRunException.class, () -> run.resume(TIMEOUT));
  }

  @Test
  void persistenceRejectsCorruptionAndArtifactMismatch() {
    HybridRun run = HybridRun.start(program(), new RecoverableTarget(1));
    run.advance();
    HybridRunStore store = new HybridRunStore();
    byte[] encoded = store.encode(run.snapshot());
    encoded[12] ^= 0x40;

    assertThrows(HybridRunException.class, () -> store.decode(encoded));

    Program wrong = new Program(
        "Different",
        ProgramKind.QUANTUM,
        0,
        program().globals(),
        program().functions(),
        program().quantumRegisters(),
        program().quantumCircuits(),
        program().workflow(),
        100,
        100);
    assertThrows(
        HybridRunException.class,
        () -> HybridRun.restore(wrong, new RecoverableTarget(1), run.snapshot()));
  }

  private static Program transactionProgram() {
    Program base = program();
    return new Program(
        "TransactionFixture",
        ProgramKind.HYBRID,
        base.entryFunctionId(),
        base.globals(),
        base.functions(),
        base.quantumRegisters(),
        base.quantumCircuits(),
        List.of(
            WorkflowStep.prepare(0, 0),
            WorkflowStep.apply(0, false),
            WorkflowStep.measure(0, 0),
            WorkflowStep.classicalCall(1, false),
            WorkflowStep.halt()),
        100,
        100);
  }

  private static Program program() {
    FunctionBody entry = new FunctionBody(
        0, "main", false, 0, 0, false, List.of(Instruction.of(Opcode.HALT)), List.of());
    FunctionBody consume = new FunctionBody(
        1,
        "consume",
        false,
        0,
        0,
        false,
        List.of(Instruction.of(Opcode.XOR_CONST, 0, 1), Instruction.of(Opcode.RETURN)),
        List.of());
    List<WorkflowStep> workflow = List.of(
        WorkflowStep.prepare(0, 0),
        WorkflowStep.apply(0, false),
        WorkflowStep.measure(0, 0),
        WorkflowStep.classicalCall(1, false),
        new WorkflowStep(WorkflowOpcode.COMMIT, 0, 0, 0),
        WorkflowStep.expect(0, 0),
        WorkflowStep.halt());
    return new Program(
        "HybridFixture",
        ProgramKind.HYBRID,
        0,
        List.of(new Global("measured", 0)),
        List.of(entry, consume),
        List.of(new QuantumRegister(0, "q", 1)),
        List.of(new QuantumCircuit(
            0, "flip", 0, List.of(GateOperation.of(Gate.X, 0)))),
        workflow,
        100,
        100);
  }

  private static final class RecoverableTarget implements QuantumTarget {
    private final TargetDescriptor descriptor = new TargetDescriptor(
        "test", "recoverable", Set.of(TargetCapability.STATIC_CIRCUIT), 8, 100);
    private final long outcome;
    private final Map<String, TestJob> jobs = new LinkedHashMap<>();
    private int submissions;
    private int recoveries;
    private String lastJobId = "";
    private boolean wrongJobIdentity;
    private boolean wrongTaskIdentity;

    private RecoverableTarget(long outcome) {
      this.outcome = outcome;
    }

    @Override
    public TargetDescriptor descriptor() {
      return descriptor;
    }

    @Override
    public QuantumJob submit(QuantumTask task) {
      submissions++;
      String id = "job-" + submissions;
      lastJobId = id;
      TestJob job = new TestJob(
          id, task.identity(), outcome, wrongJobIdentity, wrongTaskIdentity);
      jobs.put(id, job);
      return job;
    }

    @Override
    public QuantumJob recover(String jobId, QuantumTask task) {
      recoveries++;
      QuantumJob job = jobs.get(jobId);
      if (job == null) {
        throw new HybridRunException("Unknown test job " + jobId);
      }
      return job;
    }

    private final class TestJob implements QuantumJob {
      private final String id;
      private final String taskIdentity;
      private final long value;
      private final boolean wrongIdentity;
      private final boolean wrongTaskIdentity;
      private JobState state = JobState.SUCCEEDED;

      private TestJob(
          String id,
          String taskIdentity,
          long value,
          boolean wrongIdentity,
          boolean wrongTaskIdentity) {
        this.id = id;
        this.taskIdentity = taskIdentity;
        this.value = value;
        this.wrongIdentity = wrongIdentity;
        this.wrongTaskIdentity = wrongTaskIdentity;
      }

      @Override
      public String id() {
        return id;
      }

      @Override
      public JobState state() {
        return state;
      }

      @Override
      public boolean cancel() {
        state = JobState.CANCELLED;
        return true;
      }

      @Override
      public QuantumResult await(Duration timeout) {
        return new QuantumResult(
            wrongIdentity ? id + "-wrong" : id,
            wrongTaskIdentity ? taskIdentity + "-wrong" : taskIdentity,
            List.of(value),
            Map.of(value, 1L),
            descriptor.target());
      }
    }
  }
}
