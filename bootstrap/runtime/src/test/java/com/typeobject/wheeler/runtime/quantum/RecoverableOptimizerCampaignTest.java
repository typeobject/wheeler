package com.typeobject.wheeler.runtime.quantum;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.quantum.Gate;
import com.typeobject.wheeler.core.quantum.GateOperation;
import com.typeobject.wheeler.core.quantum.ParameterizedGateOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.runtime.quantum.RecoverableOptimizerCampaign.BoundSubmission;
import com.typeobject.wheeler.runtime.quantum.RecoverableOptimizerCampaign.CampaignState;
import com.typeobject.wheeler.runtime.quantum.RecoverableOptimizerCampaign.Iteration;
import com.typeobject.wheeler.runtime.quantum.RecoverableOptimizerCampaign.Parameter;
import com.typeobject.wheeler.runtime.quantum.RecoverableOptimizerCampaign.ParameterKind;
import com.typeobject.wheeler.runtime.quantum.RecoverableOptimizerCampaign.Snapshot;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Optimizer checkpoints recover provider work and apply each result identity once. */
final class RecoverableOptimizerCampaignTest {
  @Test
  void restoresQueuedAndRunningBatchesAndSuppressesDuplicateResults() {
    QuantumSubmission zero = submission(0.0, 41);
    QuantumSubmission pi = submission(Math.PI, 43);
    List<Iteration> iterations = List.of(
        new Iteration(List.of(bound(zero, 0.0), bound(pi, Math.PI)), 0),
        new Iteration(List.of(bound(pi, Math.PI)), 0));
    StateVectorTarget target = new StateVectorTarget();
    MemoryStore store = new MemoryStore();
    RecoverableOptimizerCampaign campaign = RecoverableOptimizerCampaign.create(
        target, store, iterations);

    Snapshot queued = campaign.submitNext();
    assertEquals(CampaignState.QUEUED, queued.state());
    assertEquals(2, queued.activeJobs().size());
    RecoverableOptimizerCampaign queuedRestore = RecoverableOptimizerCampaign.restore(
        target, store, iterations, queued.campaignId());
    Snapshot running = queuedRestore.poll();
    assertEquals(CampaignState.RUNNING, running.state());
    RecoverableOptimizerCampaign runningRestore = RecoverableOptimizerCampaign.restore(
        target, store, iterations, running.campaignId());
    Snapshot first = runningRestore.completeCurrent(Duration.ofSeconds(1));
    assertEquals(CampaignState.READY, first.state());
    assertEquals(1, first.nextIteration());
    assertEquals(2, first.appliedSubmissionIdentities().size());
    assertEquals(List.of(0.0), first.objectives());

    runningRestore.submitNext();
    runningRestore.poll();
    Snapshot completed = runningRestore.completeCurrent(Duration.ofSeconds(1));
    assertEquals(CampaignState.COMPLETED, completed.state());
    assertEquals(2, completed.nextIteration());
    assertEquals(2, completed.appliedSubmissionIdentities().size());
    assertEquals(List.of(0.0), completed.objectives());
    assertEquals(0.0, completed.bestObjective());
    assertEquals(completed, store.load(completed.campaignId()));
    assertEquals(List.of(0L, 1L, 2L, 3L, 4L, 5L, 6L), store.generations());
  }

  @Test
  void recordsFailedCancelledAndUnknownProviderStates() {
    List<Iteration> iterations = List.of(
        new Iteration(List.of(bound(submission(0.0, 47), 0.0)), 0));

    MemoryStore failedStore = new MemoryStore();
    RecoverableOptimizerCampaign failed = RecoverableOptimizerCampaign.create(
        new ControlledTarget(JobState.FAILED), failedStore, iterations);
    failed.submitNext();
    Snapshot failedSnapshot = failed.poll();
    assertEquals(CampaignState.FAILED, failedSnapshot.state());
    assertTrue(failedSnapshot.detail().contains("failed"));

    MemoryStore cancelledStore = new MemoryStore();
    RecoverableOptimizerCampaign cancelled = RecoverableOptimizerCampaign.create(
        new ControlledTarget(JobState.QUEUED), cancelledStore, iterations);
    cancelled.submitNext();
    Snapshot cancelledSnapshot = cancelled.cancel();
    assertEquals(CampaignState.CANCELLED, cancelledSnapshot.state());
    assertTrue(cancelledSnapshot.activeJobs().isEmpty());

    StateVectorTarget original = new StateVectorTarget();
    MemoryStore unknownStore = new MemoryStore();
    RecoverableOptimizerCampaign unknown = RecoverableOptimizerCampaign.create(
        original, unknownStore, iterations);
    Snapshot queued = unknown.submitNext();
    RecoverableOptimizerCampaign missing = RecoverableOptimizerCampaign.restore(
        new StateVectorTarget(), unknownStore, iterations, queued.campaignId());
    assertEquals(CampaignState.UNKNOWN, missing.snapshot().state());
    assertTrue(missing.snapshot().detail().contains("Unknown"));
  }

  @Test
  void completesTheSixtyFourIterationBoundWithoutRetainingProviderJobs() {
    List<Iteration> iterations = new ArrayList<>();
    for (int iteration = 0; iteration < 64; iteration++) {
      double theta = iteration / 64.0;
      iterations.add(new Iteration(
          List.of(bound(submission(theta, 100 + iteration), theta)), 0));
    }
    MemoryStore store = new MemoryStore();
    RecoverableOptimizerCampaign campaign = RecoverableOptimizerCampaign.create(
        new StateVectorTarget(), store, iterations);

    Snapshot current = campaign.snapshot();
    for (int iteration = 0; iteration < 64; iteration++) {
      campaign.submitNext();
      current = campaign.completeCurrent(Duration.ofSeconds(1));
    }

    assertEquals(CampaignState.COMPLETED, current.state());
    assertEquals(64, current.nextIteration());
    assertEquals(64, current.objectives().size());
    assertEquals(64, current.appliedSubmissionIdentities().size());
    assertTrue(current.activeJobs().isEmpty());
    assertEquals(129, store.generations().size());
  }

  @Test
  void cleanupAttemptsEveryAcknowledgedJobAcrossFailureAndCancellation() {
    List<Iteration> iterations = List.of(new Iteration(List.of(
        bound(submission(0.0, 71), 0.0),
        bound(submission(0.5, 73), 0.5),
        bound(submission(1.0, 79), 1.0)), 0));
    CleanupTarget failedTarget = new CleanupTarget(1, -1);
    RecoverableOptimizerCampaign failed = RecoverableOptimizerCampaign.create(
        failedTarget, new MemoryStore(), iterations);
    failed.submitNext();
    Snapshot failedSnapshot = failed.completeCurrent(Duration.ofSeconds(1));

    assertEquals(CampaignState.FAILED, failedSnapshot.state());
    assertEquals(List.of(1, 1, 1), failedTarget.jobs.stream()
        .map(job -> job.cancelCalls).toList());

    CleanupTarget uncertainTarget = new CleanupTarget(-1, 0);
    RecoverableOptimizerCampaign uncertain = RecoverableOptimizerCampaign.create(
        uncertainTarget, new MemoryStore(), iterations);
    uncertain.submitNext();
    Snapshot uncertainSnapshot = uncertain.cancel();

    assertEquals(CampaignState.UNKNOWN, uncertainSnapshot.state());
    assertTrue(uncertainSnapshot.detail().contains("cleanup uncertain"));
    assertEquals(List.of(1, 1, 1), uncertainTarget.jobs.stream()
        .map(job -> job.cancelCalls).toList());

    CleanupTarget batchTarget = new CleanupTarget(-1, 1);
    QuantumBatchJob batch = batchTarget.submitBatch(new QuantumBatch(
        iterations.getFirst().boundSubmissions().stream()
            .map(BoundSubmission::submission)
            .toList()));
    assertThrows(QuantumExecutionException.class, batch::cancel);
    assertEquals(List.of(1, 1, 1), batchTarget.jobs.stream()
        .map(job -> job.cancelCalls).toList());
  }

  @Test
  void failedQueuedCheckpointCleansAcknowledgedJobsBeforeReturning() {
    List<Iteration> iterations = List.of(new Iteration(
        List.of(bound(submission(0.0, 81), 0.0)), 0));
    CleanupTarget target = new CleanupTarget(-1, -1);
    RejectingStore store = new RejectingStore();
    RecoverableOptimizerCampaign campaign = RecoverableOptimizerCampaign.create(
        target, store, iterations);
    store.reject = true;

    assertThrows(IllegalStateException.class, campaign::submitNext);
    assertEquals(1, target.jobs.getFirst().cancelCalls);
    assertEquals(CampaignState.READY, campaign.snapshot().state());
    assertTrue(campaign.snapshot().activeJobs().isEmpty());
  }

  @Test
  void partialBatchSubmissionCancelsEveryAcknowledgedPrefixJob() {
    List<Iteration> iterations = List.of(new Iteration(List.of(
        bound(submission(0.0, 83), 0.0),
        bound(submission(1.0, 89), 1.0)), 0));
    PartialSubmissionTarget target = new PartialSubmissionTarget();
    RecoverableOptimizerCampaign campaign = RecoverableOptimizerCampaign.create(
        target, new MemoryStore(), iterations);

    assertThrows(QuantumExecutionException.class, campaign::submitNext);
    assertEquals(1, target.first.cancelCalls);
    assertEquals(CampaignState.READY, campaign.snapshot().state());
    assertTrue(campaign.snapshot().activeJobs().isEmpty());
  }

  @Test
  void rejectsMismatchedTypedParametersAndCampaignPlans() {
    QuantumSubmission submission = submission(0.0, 53);
    assertThrows(IllegalArgumentException.class, () -> new BoundSubmission(
        submission, List.of(new Parameter("theta", ParameterKind.ANGLE, 1.0))));
    assertThrows(IllegalArgumentException.class, () ->
        new Parameter("probability", ParameterKind.PROBABILITY, 2.0));

    List<Iteration> original = List.of(
        new Iteration(List.of(bound(submission, 0.0)), 0));
    List<Iteration> changed = List.of(
        new Iteration(List.of(bound(RecoverableOptimizerCampaignTest.submission(0.0, 59), 0.0)), 0));
    MemoryStore store = new MemoryStore();
    RecoverableOptimizerCampaign campaign = RecoverableOptimizerCampaign.create(
        new StateVectorTarget(), store, original);
    assertThrows(IllegalArgumentException.class, () -> RecoverableOptimizerCampaign.restore(
        new StateVectorTarget(), store, changed, campaign.snapshot().campaignId()));
  }

  private static BoundSubmission bound(QuantumSubmission submission, double theta) {
    return new BoundSubmission(
        submission, List.of(new Parameter("theta", ParameterKind.ANGLE, theta)));
  }

  private static QuantumSubmission submission(double theta, long seed) {
    QuantumRegister register = new QuantumRegister(0, "optimizer", 1);
    QuantumCircuit circuit = new QuantumCircuit(
        0,
        "ansatz",
        0,
        List.of(
            GateOperation.of(Gate.H, 0),
            new ParameterizedGateOperation(Gate.PHASE, List.of(0), "theta", 1),
            GateOperation.of(Gate.H, 0)));
    Program program = StateVectorTargetTest.program(register, circuit, List.<FunctionBody>of());
    return new QuantumSubmission(
        program,
        0,
        0,
        List.of(new CircuitApplication(0, false)),
        Map.of("theta", theta),
        64,
        seed);
  }

  private static final class MemoryStore
      implements RecoverableOptimizerCampaign.SnapshotStore {
    private final Map<String, Snapshot> snapshots = new HashMap<>();
    private final List<Long> generations = new ArrayList<>();

    @Override
    public void save(Snapshot snapshot) {
      snapshots.put(snapshot.campaignId(), snapshot);
      generations.add(snapshot.generation());
    }

    @Override
    public Snapshot load(String campaignId) {
      return snapshots.get(campaignId);
    }

    List<Long> generations() {
      return List.copyOf(generations);
    }
  }

  private static final class ControlledTarget implements QuantumTarget {
    private final StateVectorTarget descriptorSource = new StateVectorTarget();
    private final JobState initialState;
    private int sequence;

    private ControlledTarget(JobState initialState) {
      this.initialState = initialState;
    }

    @Override
    public TargetDescriptor descriptor() {
      return descriptorSource.descriptor();
    }

    @Override
    public QuantumJob submit(QuantumSubmission submission) {
      sequence += 1;
      return new ControlledJob("controlled-" + sequence, submission, initialState);
    }
  }

  private static final class RejectingStore
      implements RecoverableOptimizerCampaign.SnapshotStore {
    private Snapshot snapshot;
    private boolean reject;

    @Override
    public void save(Snapshot value) {
      if (reject) {
        throw new IllegalStateException("checkpoint rejected");
      }
      snapshot = value;
    }

    @Override
    public Snapshot load(String campaignId) {
      return snapshot;
    }
  }

  private static final class CleanupTarget implements QuantumTarget {
    private final StateVectorTarget descriptorSource = new StateVectorTarget();
    private final int awaitFailure;
    private final int cancelFailure;
    private final List<CleanupJob> jobs = new ArrayList<>();

    private CleanupTarget(int awaitFailure, int cancelFailure) {
      this.awaitFailure = awaitFailure;
      this.cancelFailure = cancelFailure;
    }

    @Override
    public TargetDescriptor descriptor() {
      return descriptorSource.descriptor();
    }

    @Override
    public QuantumJob submit(QuantumSubmission submission) {
      int index = jobs.size();
      CleanupJob job = new CleanupJob(
          "cleanup-" + index,
          submission,
          index == awaitFailure,
          index == cancelFailure);
      jobs.add(job);
      return job;
    }
  }

  private static final class PartialSubmissionTarget implements QuantumTarget {
    private final StateVectorTarget descriptorSource = new StateVectorTarget();
    private CleanupJob first;
    private int submissions;

    @Override
    public TargetDescriptor descriptor() {
      return descriptorSource.descriptor();
    }

    @Override
    public QuantumJob submit(QuantumSubmission submission) {
      submissions++;
      if (submissions == 2) {
        throw new QuantumExecutionException("second batch submission failed");
      }
      first = new CleanupJob("partial-0", submission, false, false);
      return first;
    }
  }

  private static final class CleanupJob implements QuantumJob {
    private final String id;
    private final QuantumSubmission submission;
    private final boolean awaitFailure;
    private final boolean cancelFailure;
    private int cancelCalls;

    private CleanupJob(
        String id,
        QuantumSubmission submission,
        boolean awaitFailure,
        boolean cancelFailure) {
      this.id = id;
      this.submission = submission;
      this.awaitFailure = awaitFailure;
      this.cancelFailure = cancelFailure;
    }

    @Override
    public String id() {
      return id;
    }

    @Override
    public JobState state() {
      return JobState.RUNNING;
    }

    @Override
    public boolean cancel() {
      cancelCalls++;
      if (cancelFailure) {
        throw new QuantumExecutionException("cleanup cancellation failed");
      }
      return true;
    }

    @Override
    public QuantumResult await(Duration timeout) {
      if (awaitFailure) {
        throw new QuantumExecutionException("cleanup await failed");
      }
      return new QuantumResult(
          id, submission.identity(), List.of(0L), Map.of(0L, 1L), "cleanup");
    }
  }

  private static final class ControlledJob implements QuantumJob {
    private final String id;
    private final QuantumSubmission submission;
    private JobState state;

    private ControlledJob(String id, QuantumSubmission submission, JobState state) {
      this.id = id;
      this.submission = submission;
      this.state = state;
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
      if (state == JobState.FAILED) {
        throw new QuantumExecutionException("controlled provider failure");
      }
      return new QuantumResult(
          id, submission.identity(), List.of(0L), Map.of(0L, 1L), "controlled");
    }
  }
}
