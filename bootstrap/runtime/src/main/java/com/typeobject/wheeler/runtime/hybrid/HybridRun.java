package com.typeobject.wheeler.runtime.hybrid;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import com.typeobject.wheeler.runtime.ExecutionResult;
import com.typeobject.wheeler.runtime.quantum.JobState;
import com.typeobject.wheeler.runtime.quantum.QuantumJob;
import com.typeobject.wheeler.runtime.quantum.QuantumResult;
import com.typeobject.wheeler.runtime.quantum.QuantumTarget;
import com.typeobject.wheeler.runtime.quantum.QuantumTask;
import com.typeobject.wheeler.runtime.quantum.QuantumTaskBuilder;
import com.typeobject.wheeler.runtime.quantum.TargetCapability;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/** Suspendable, replayable execution of one verified quantum or hybrid workflow. */
public final class HybridRun {
  private final Program program;
  private final QuantumTarget target;
  private final RunMode mode;
  private final HybridRunLimits limits;
  private final String artifactId;
  private final String runId;
  private final VirtualMachine machine;
  private final Map<Integer, QuantumTaskBuilder> prepared = new HashMap<>();
  private final List<HybridEvent> events = new ArrayList<>();
  private final List<Long> measurements = new ArrayList<>();
  private final List<String> jobs = new ArrayList<>();

  private String activeBranch;
  private RunStatus status;
  private int workflowIndex;
  private int retries;
  private int branchSequence;
  private long commitHorizon = -1;
  private PendingSubmission pending;
  private TransactionPhase transactionPhase = TransactionPhase.NONE;
  private TransactionCheckpoint transactionCheckpoint;

  private HybridRun(
      Program program,
      QuantumTarget target,
      RunMode mode,
      HybridRunLimits limits,
      String artifactId,
      String runId,
      String activeBranch,
      boolean appendStartEvents) {
    this.program = requireHybrid(program);
    this.target = Objects.requireNonNull(target, "target");
    this.mode = Objects.requireNonNull(mode, "mode");
    this.limits = Objects.requireNonNull(limits, "limits");
    this.artifactId = artifactId;
    this.runId = runId;
    this.activeBranch = activeBranch;
    this.machine = new VirtualMachine(program);
    this.status = RunStatus.ACTIVE;
    target.descriptor().require(TargetCapability.STATIC_CIRCUIT);
    if (appendStartEvents) {
      append(HybridEventKind.RUN_STARTED, -1, "", "", 0, artifactId);
      append(
          HybridEventKind.TARGET_SELECTED,
          -1,
          "",
          target.descriptor().target(),
          0,
          target.descriptor().adapter());
    }
  }

  public static HybridRun start(Program program, QuantumTarget target) {
    return start(program, target, RunMode.RECORD, HybridRunLimits.DEFAULT);
  }

  public static HybridRun start(
      Program program, QuantumTarget target, RunMode mode, HybridRunLimits limits) {
    if (mode == RunMode.REPLAY) {
      throw new IllegalArgumentException("Use replay() with a recorded snapshot");
    }
    return new HybridRun(
        program,
        target,
        mode,
        limits,
        ArtifactIdentity.of(program),
        UUID.randomUUID().toString(),
        "main",
        true);
  }

  /** Execute deterministic edges until waiting for a target or completing. */
  public RunStatus advance() {
    requireStatus(RunStatus.ACTIVE);
    while (workflowIndex < program.workflow().size()) {
      if (workflowIndex >= program.maxSteps()) {
        return trap("Workflow step limit exceeded");
      }
      WorkflowStep step = program.workflow().get(workflowIndex);
      switch (step.opcode()) {
        case PREPARE -> {
          int register = Math.toIntExact(step.first());
          if (prepared.put(register, new QuantumTaskBuilder(program, register, step.second())) != null) {
            return trap("Quantum register prepared twice without measurement");
          }
          workflowIndex++;
        }
        case APPLY, UNAPPLY -> {
          int circuit = Math.toIntExact(step.first());
          int register = program.quantumCircuit(circuit).registerId();
          requirePrepared(register).apply(circuit, step.opcode() == WorkflowOpcode.UNAPPLY);
          workflowIndex++;
        }
        case MEASURE -> {
          int register = Math.toIntExact(step.first());
          QuantumTask task = requirePrepared(register).build(1, measurements.size());
          QuantumJob job = target.submit(task);
          pending = new PendingSubmission(task, job, register, Math.toIntExact(step.second()));
          if (transactionPhase == TransactionPhase.REVERSIBLE) {
            transactionPhase = TransactionPhase.PREPARED_EXTERNAL;
          }
          append(
              HybridEventKind.QUANTUM_SUBMITTED,
              workflowIndex,
              job.id(),
              target.descriptor().target(),
              task.shots(),
              task.identity());
          status = RunStatus.WAITING;
          return status;
        }
        case CLASSICAL_CALL, CLASSICAL_UNCALL -> {
          machine.invoke(
              Math.toIntExact(step.first()), step.opcode() == WorkflowOpcode.CLASSICAL_UNCALL);
          workflowIndex++;
        }
        case EXPECT -> {
          machine.expectGlobal(Math.toIntExact(step.first()), step.second());
          workflowIndex++;
        }
        case COMMIT -> {
          machine.commitHistory();
          HybridEvent event = append(HybridEventKind.COMMITTED, workflowIndex, "", "", 0, "");
          commitHorizon = event.sequence();
          if (transactionPhase != TransactionPhase.NONE) {
            transactionPhase = TransactionPhase.COMMITTED;
          }
          workflowIndex++;
        }
        case HALT -> {
          if (!prepared.isEmpty()) {
            return trap("Workflow halted with unmeasured prepared registers");
          }
          workflowIndex++;
          append(HybridEventKind.RUN_COMPLETED, workflowIndex - 1, "", "", 0, "");
          status = RunStatus.COMPLETED;
          return status;
        }
      }
    }
    return trap("Verified workflow did not halt");
  }

  /** Accept one awaited result atomically, then run to the next suspension. */
  public RunStatus resume(Duration timeout) {
    requireStatus(RunStatus.WAITING);
    QuantumResult result;
    try {
      result = pending.job().await(timeout);
    } catch (RuntimeException exception) {
      if (pending.job().state() == JobState.FAILED
          || pending.job().state() == JobState.CANCELLED) {
        trap("Quantum job " + pending.job().id() + " failed: " + exception.getMessage());
      }
      throw exception;
    }
    validateResult(pending, result);
    ensureEventCapacity();
    long value = result.firstOutcome();
    append(
        HybridEventKind.QUANTUM_APPLIED,
        workflowIndex,
        result.jobId(),
        result.target(),
        value,
        "little-endian");
    machine.setGlobalFromEffect(pending.globalId(), value);
    if (transactionPhase == TransactionPhase.PREPARED_EXTERNAL) {
      transactionPhase = TransactionPhase.OBSERVED;
    }
    measurements.add(value);
    jobs.add(result.jobId());
    prepared.remove(pending.registerId());
    pending = null;
    workflowIndex++;
    status = RunStatus.ACTIVE;
    return advance();
  }

  public ExecutionResult runToCompletion(Duration timeout) {
    if (status == RunStatus.ACTIVE) {
      advance();
    }
    while (status == RunStatus.WAITING) {
      resume(timeout);
    }
    if (status != RunStatus.COMPLETED) {
      throw new HybridRunException("Run did not complete: " + status);
    }
    return result();
  }

  /** Start a classical checkpoint whose later abort obeys the current external-effect phase. */
  public void beginTransaction() {
    if (status != RunStatus.ACTIVE || !prepared.isEmpty() || pending != null) {
      throw new HybridRunException("Transactions start only at an active clean workflow boundary");
    }
    if (transactionPhase != TransactionPhase.NONE
        && transactionPhase != TransactionPhase.COMMITTED) {
      throw new HybridRunException("A hybrid transaction is already active");
    }
    transactionCheckpoint = new TransactionCheckpoint(
        workflowIndex, machine.snapshot().globals(), measurements.size());
    transactionPhase = TransactionPhase.REVERSIBLE;
    append(HybridEventKind.TRANSACTION_STARTED, workflowIndex, "", "", 0, "");
  }

  /** Commit an active transaction and make its prior checkpoint unavailable for abort. */
  public void commitTransaction() {
    if (transactionPhase == TransactionPhase.NONE
        || transactionPhase == TransactionPhase.COMMITTED) {
      throw new HybridRunException("No uncommitted hybrid transaction exists");
    }
    machine.commitHistory();
    HybridEvent event = append(HybridEventKind.COMMITTED, workflowIndex, "", "", 0, "transaction");
    commitHorizon = event.sequence();
    transactionPhase = TransactionPhase.COMMITTED;
  }

  /** Restore classical state and quarantine any external lineage without claiming physical inverse. */
  public TransactionAbort abortTransaction() {
    if (transactionPhase == TransactionPhase.NONE) {
      throw new HybridRunException("No hybrid transaction exists");
    }
    if (transactionPhase == TransactionPhase.COMMITTED) {
      throw new HybridRunException("Committed hybrid transaction cannot abort");
    }
    if (status == RunStatus.TRAPPED || status == RunStatus.CANCELLED) {
      throw new HybridRunException("Cannot abort transaction while run is " + status);
    }
    TransactionPhase previous = transactionPhase;
    boolean cancellation = previous == TransactionPhase.PREPARED_EXTERNAL;
    boolean discarded = previous == TransactionPhase.OBSERVED;
    boolean external = cancellation || discarded;
    if (external && branchSequence + 2 > limits.maxBranches()) {
      throw new HybridRunException("Hybrid branch limit exceeded");
    }
    ensureAdditionalEvents(external ? (cancellation ? 3 : 2) : 1);

    if (cancellation) {
      append(
          HybridEventKind.CANCELLATION_REQUESTED,
          workflowIndex,
          pending.job().id(),
          target.descriptor().target(),
          0,
          "transaction-abort");
      pending.job().cancel();
    }
    if (external) {
      append(
          HybridEventKind.BRANCH_DISCARDED,
          workflowIndex,
          pending == null ? "" : pending.job().id(),
          target.descriptor().target(),
          discarded ? 1 : 0,
          "transaction-abort");
      branchSequence++;
      activeBranch = "abort-" + branchSequence;
    }
    append(
        HybridEventKind.TRANSACTION_ABORTED,
        workflowIndex,
        "",
        "",
        previous.ordinal(),
        external ? "external" : "reversible");

    machine.restoreEffectCheckpoint(transactionCheckpoint.globals());
    workflowIndex = transactionCheckpoint.workflowIndex();
    prepared.clear();
    pending = null;
    while (measurements.size() > transactionCheckpoint.observationCount()) {
      measurements.removeLast();
      jobs.removeLast();
    }
    transactionCheckpoint = null;
    transactionPhase = TransactionPhase.NONE;
    status = RunStatus.ACTIVE;
    return new TransactionAbort(previous, cancellation, discarded, activeBranch);
  }

  public TransactionPhase transactionPhase() {
    return transactionPhase;
  }

  /** Request cancellation and quarantine the active branch from future mutation. */
  public boolean cancel() {
    requireStatus(RunStatus.WAITING);
    append(
        HybridEventKind.CANCELLATION_REQUESTED,
        workflowIndex,
        pending.job().id(),
        target.descriptor().target(),
        0,
        "");
    boolean accepted = pending.job().cancel();
    append(
        HybridEventKind.BRANCH_DISCARDED,
        workflowIndex,
        pending.job().id(),
        target.descriptor().target(),
        accepted ? 1 : 0,
        "cancelled");
    pending = null;
    status = RunStatus.CANCELLED;
    return accepted;
  }

  /** Discard the pending lineage and create one fresh physical submission. */
  public String retry() {
    requireStatus(RunStatus.WAITING);
    if (retries >= limits.maxRetries()) {
      throw new HybridRunException("Hybrid retry limit exceeded");
    }
    if (branchSequence + 2 > limits.maxBranches()) {
      throw new HybridRunException("Hybrid branch limit exceeded");
    }
    ensureAdditionalEvents(4);
    String oldBranch = activeBranch;
    QuantumTask task = pending.task();
    append(
        HybridEventKind.CANCELLATION_REQUESTED,
        workflowIndex,
        pending.job().id(),
        target.descriptor().target(),
        0,
        "retry");
    pending.job().cancel();
    append(
        HybridEventKind.BRANCH_DISCARDED,
        workflowIndex,
        pending.job().id(),
        target.descriptor().target(),
        0,
        "retry");
    retries++;
    branchSequence++;
    activeBranch = "retry-" + branchSequence;
    append(HybridEventKind.BRANCH_RETRIED, workflowIndex, "", "", retries, oldBranch);
    QuantumJob job = target.submit(task);
    pending = new PendingSubmission(task, job, pending.registerId(), pending.globalId());
    append(
        HybridEventKind.QUANTUM_SUBMITTED,
        workflowIndex,
        job.id(),
        target.descriptor().target(),
        task.shots(),
        task.identity());
    status = RunStatus.WAITING;
    return job.id();
  }

  public HybridRunSnapshot snapshot() {
    String pendingJob = pending == null ? "" : pending.job().id();
    String pendingTarget = pending == null ? "" : target.descriptor().target();
    HybridContinuation continuation = new HybridContinuation(
        artifactId,
        runId,
        activeBranch,
        workflowIndex,
        machine.snapshot().globals(),
        pendingJob,
        pendingTarget,
        transactionPhase,
        transactionCheckpoint == null ? -1 : transactionCheckpoint.workflowIndex(),
        transactionCheckpoint == null ? 0 : transactionCheckpoint.observationCount(),
        transactionCheckpoint == null ? Map.of() : transactionCheckpoint.globals());
    return new HybridRunSnapshot(
        HybridRunSnapshot.SCHEMA_VERSION,
        artifactId,
        runId,
        mode,
        status,
        activeBranch,
        commitHorizon,
        limits,
        continuation,
        events);
  }

  /** Restore a checkpoint, recovering an acknowledged pending job without resubmission. */
  public static HybridRun restore(
      Program program, QuantumTarget target, HybridRunSnapshot snapshot) {
    Objects.requireNonNull(snapshot, "snapshot");
    String artifact = ArtifactIdentity.of(program);
    if (!artifact.equals(snapshot.artifactId())) {
      throw new HybridRunException("Snapshot artifact identity mismatch");
    }
    HybridEventReducer.HybridReduction reduction = HybridEventReducer.reduce(snapshot.events());
    HybridRun run = new HybridRun(
        program,
        target,
        snapshot.mode(),
        snapshot.limits(),
        artifact,
        snapshot.runId(),
        snapshot.activeBranch(),
        false);
    run.events.addAll(reduction.events());
    run.commitHorizon = reduction.commitHorizon();
    run.retries = (int) run.events.stream()
        .filter(event -> event.kind() == HybridEventKind.BRANCH_RETRIED)
        .count();
    run.branchSequence = (int) run.events.stream()
        .filter(event -> event.kind() == HybridEventKind.BRANCH_RETRIED
            || (event.kind() == HybridEventKind.TRANSACTION_ABORTED
                && !event.detail().equals("reversible")))
        .count();
    run.rebuild(snapshot, reduction);
    return run;
  }

  /** Reproduce a completed classical suffix entirely from accepted observations. */
  public static ExecutionResult replay(Program program, HybridRunSnapshot recorded) {
    if (!ArtifactIdentity.of(program).equals(recorded.artifactId())) {
      throw new HybridRunException("Replay artifact identity mismatch");
    }
    HybridEventReducer.HybridReduction reduction = HybridEventReducer.reduce(recorded.events());
    if (reduction.status() != RunStatus.COMPLETED) {
      throw new HybridRunException("Replay requires a completed event stream");
    }
    return HybridReplay.execute(program, reduction);
  }

  public RunStatus status() {
    return status;
  }

  public String runId() {
    return runId;
  }

  public String activeBranch() {
    return activeBranch;
  }

  public List<HybridEvent> events() {
    return List.copyOf(events);
  }

  public ExecutionResult result() {
    if (status != RunStatus.COMPLETED) {
      throw new HybridRunException("Result is unavailable while run is " + status);
    }
    return new ExecutionResult(
        program.name(),
        program.kind(),
        machine.snapshot().globals(),
        measurements,
        jobs,
        workflowIndex);
  }

  private void rebuild(
      HybridRunSnapshot snapshot, HybridEventReducer.HybridReduction reduction) {
    Map<Integer, HybridEventReducer.AppliedObservation> applied = reduction.applied();
    while (workflowIndex < snapshot.continuation().workflowIndex()) {
      WorkflowStep step = program.workflow().get(workflowIndex);
      if (step.opcode() == WorkflowOpcode.MEASURE) {
        HybridEventReducer.AppliedObservation observation = applied.get(workflowIndex);
        if (observation == null) {
          throw new HybridRunException("Missing applied observation before continuation");
        }
        applyRecorded(step, observation);
      } else {
        executeRebuildEdge(step);
      }
      workflowIndex++;
    }
    if (!machine.snapshot().globals().equals(snapshot.continuation().globals())) {
      throw new HybridRunException("Continuation globals do not match replayed events");
    }
    status = snapshot.status();
    transactionPhase = snapshot.continuation().transactionPhase();
    if (transactionPhase != TransactionPhase.NONE) {
      transactionCheckpoint = new TransactionCheckpoint(
          snapshot.continuation().transactionWorkflowIndex(),
          snapshot.continuation().transactionGlobals(),
          snapshot.continuation().transactionObservationCount());
    }
    if (status == RunStatus.WAITING) {
      WorkflowStep step = program.workflow().get(workflowIndex);
      if (step.opcode() != WorkflowOpcode.MEASURE) {
        throw new HybridRunException("Waiting continuation is not at a measurement edge");
      }
      int register = Math.toIntExact(step.first());
      QuantumTask task = requirePrepared(register).build(1, measurements.size());
      String jobId = snapshot.continuation().pendingJobId();
      if (!target.descriptor().target().equals(snapshot.continuation().pendingTarget())) {
        throw new HybridRunException("Recovered target identity mismatch");
      }
      HybridEvent submission = latestSubmission(workflowIndex, jobId);
      if (!submission.detail().equals(task.identity())) {
        throw new HybridRunException("Recovered quantum task identity mismatch");
      }
      QuantumJob job = target.recover(jobId, task);
      if (!job.id().equals(jobId)) {
        throw new HybridRunException("Recovered quantum job identity mismatch");
      }
      pending = new PendingSubmission(task, job, register, Math.toIntExact(step.second()));
    }
  }

  private void executeRebuildEdge(WorkflowStep step) {
    switch (step.opcode()) {
      case PREPARE -> {
        int register = Math.toIntExact(step.first());
        prepared.put(register, new QuantumTaskBuilder(program, register, step.second()));
      }
      case APPLY, UNAPPLY -> {
        int circuit = Math.toIntExact(step.first());
        int register = program.quantumCircuit(circuit).registerId();
        requirePrepared(register).apply(circuit, step.opcode() == WorkflowOpcode.UNAPPLY);
      }
      case CLASSICAL_CALL, CLASSICAL_UNCALL -> machine.invoke(
          Math.toIntExact(step.first()), step.opcode() == WorkflowOpcode.CLASSICAL_UNCALL);
      case EXPECT -> machine.expectGlobal(Math.toIntExact(step.first()), step.second());
      case COMMIT -> machine.commitHistory();
      case HALT -> {
        // Completion is represented by the durable event stream.
      }
      case MEASURE -> throw new AssertionError("Measurement rebuild requires an observation");
    }
  }

  private void applyRecorded(
      WorkflowStep step, HybridEventReducer.AppliedObservation observation) {
    int register = Math.toIntExact(step.first());
    requirePrepared(register);
    machine.setGlobalFromEffect(Math.toIntExact(step.second()), observation.value());
    prepared.remove(register);
    measurements.add(observation.value());
    jobs.add(observation.jobId());
  }

  private QuantumTaskBuilder requirePrepared(int register) {
    QuantumTaskBuilder builder = prepared.get(register);
    if (builder == null) {
      throw new HybridRunException("Quantum register is not prepared: " + register);
    }
    return builder;
  }

  private void validateResult(PendingSubmission submission, QuantumResult result) {
    if (!submission.job().id().equals(result.jobId())) {
      throw new HybridRunException("Quantum result job identity mismatch");
    }
    if (!target.descriptor().target().equals(result.target())) {
      throw new HybridRunException("Quantum result target identity mismatch");
    }
    if (!submission.task().identity().equals(result.taskIdentity())) {
      throw new HybridRunException("Quantum result task identity mismatch");
    }
    if (result.outcomes().size() != submission.task().shots()) {
      throw new HybridRunException("Quantum result shot count mismatch");
    }
    int qubits = program.quantumRegister(submission.registerId()).qubits();
    for (long outcome : result.outcomes()) {
      if (outcome < 0 || (qubits < 63 && outcome >= (1L << qubits))) {
        throw new HybridRunException("Quantum result exceeds register width");
      }
    }
  }

  private HybridEvent latestSubmission(int step, String jobId) {
    for (int index = events.size() - 1; index >= 0; index--) {
      HybridEvent event = events.get(index);
      if (event.kind() == HybridEventKind.QUANTUM_SUBMITTED
          && event.branchId().equals(activeBranch)
          && event.workflowIndex() == step
          && event.jobId().equals(jobId)) {
        return event;
      }
    }
    throw new HybridRunException("Continuation has no matching quantum submission event");
  }

  private HybridEvent append(
      HybridEventKind kind,
      int step,
      String jobId,
      String targetId,
      long value,
      String detail) {
    ensureEventCapacity();
    HybridEvent event = HybridEvent.create(
        runId, events.size(), kind, activeBranch, step, jobId, targetId, value, detail);
    events.add(event);
    return event;
  }

  private void ensureEventCapacity() {
    ensureAdditionalEvents(1);
  }

  private void ensureAdditionalEvents(int count) {
    if (count < 0 || events.size() > limits.maxEvents() - count) {
      throw new HybridRunException("Hybrid event limit exceeded");
    }
  }

  private RunStatus trap(String message) {
    append(HybridEventKind.RUN_TRAPPED, workflowIndex, "", "", 0, message);
    status = RunStatus.TRAPPED;
    return status;
  }

  private void requireStatus(RunStatus expected) {
    if (status != expected) {
      throw new HybridRunException("Expected run status " + expected + ", got " + status);
    }
  }

  private static Program requireHybrid(Program program) {
    Objects.requireNonNull(program, "program");
    if (program.kind() == ProgramKind.CLASSICAL) {
      throw new IllegalArgumentException("HybridRun requires a quantum or hybrid program");
    }
    return program;
  }

  private record PendingSubmission(
      QuantumTask task, QuantumJob job, int registerId, int globalId) {}

  private record TransactionCheckpoint(
      int workflowIndex, Map<String, Long> globals, int observationCount) {
    private TransactionCheckpoint {
      globals = Map.copyOf(globals);
    }
  }

}
