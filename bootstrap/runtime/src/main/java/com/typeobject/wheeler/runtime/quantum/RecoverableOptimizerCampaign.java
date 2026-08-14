package com.typeobject.wheeler.runtime.quantum;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeMap;

/** Bounded iterative optimizer with explicit batch recovery and durable checkpoints. */
public final class RecoverableOptimizerCampaign {
  private static final int MAX_ITERATIONS = 64;
  private static final int MAX_SUBMISSIONS = 64;
  private static final int MAX_DETAIL = 1024;

  private final QuantumTarget target;
  private final SnapshotStore store;
  private final List<Iteration> iterations;
  private final String campaignId;
  private Snapshot snapshot;
  private List<QuantumJob> activeJobs;

  private RecoverableOptimizerCampaign(
      QuantumTarget target,
      SnapshotStore store,
      List<Iteration> iterations,
      String campaignId,
      Snapshot snapshot,
      List<QuantumJob> activeJobs) {
    this.target = target;
    this.store = store;
    this.iterations = iterations;
    this.campaignId = campaignId;
    this.snapshot = snapshot;
    this.activeJobs = activeJobs;
  }

  /** Starts and persists one unsubmitted campaign. */
  public static RecoverableOptimizerCampaign create(
      QuantumTarget target, SnapshotStore store, List<Iteration> iterations) {
    Objects.requireNonNull(target, "target");
    Objects.requireNonNull(store, "store");
    List<Iteration> plans = validatedIterations(iterations);
    String identity = campaignIdentity(plans);
    Snapshot initial = new Snapshot(
        identity,
        CampaignState.READY,
        0,
        0,
        List.of(),
        Set.of(),
        List.of(),
        Double.POSITIVE_INFINITY,
        "");
    RecoverableOptimizerCampaign campaign = new RecoverableOptimizerCampaign(
        target, store, plans, identity, initial, List.of());
    campaign.persist(initial);
    return campaign;
  }

  /** Restores queued or running jobs without issuing another provider submission. */
  public static RecoverableOptimizerCampaign restore(
      QuantumTarget target,
      SnapshotStore store,
      List<Iteration> iterations,
      String campaignId) {
    Objects.requireNonNull(target, "target");
    Objects.requireNonNull(store, "store");
    List<Iteration> plans = validatedIterations(iterations);
    String expectedIdentity = campaignIdentity(plans);
    if (!expectedIdentity.equals(campaignId)) {
      throw new IllegalArgumentException("Optimizer campaign identity does not match its plan");
    }
    Snapshot loaded = Objects.requireNonNull(store.load(campaignId), "stored snapshot");
    if (!loaded.campaignId().equals(campaignId)
        || loaded.nextIteration() < 0
        || loaded.nextIteration() > plans.size()) {
      throw new IllegalArgumentException("Stored optimizer campaign is not compatible");
    }
    RecoverableOptimizerCampaign campaign = new RecoverableOptimizerCampaign(
        target, store, plans, campaignId, loaded, List.of());
    if (loaded.state() == CampaignState.QUEUED
        || loaded.state() == CampaignState.RUNNING) {
      campaign.recoverActiveJobs();
    } else if (!loaded.activeJobs().isEmpty()) {
      throw new IllegalArgumentException("Inactive optimizer snapshot retains provider jobs");
    }
    return campaign;
  }

  /** Submits the next parameterized iteration as one ordered provider batch. */
  public Snapshot submitNext() {
    requireState(CampaignState.READY);
    if (snapshot.nextIteration() == iterations.size()) {
      return persist(nextSnapshot(CampaignState.COMPLETED, List.of(), ""));
    }
    Iteration iteration = iterations.get(snapshot.nextIteration());
    target.descriptor().require(TargetCapability.BATCH_SUBMISSION);
    List<QuantumSubmission> submissions = iteration.boundSubmissions().stream()
        .map(BoundSubmission::submission)
        .toList();
    submissions.forEach(submission -> target.descriptor().require(submission.requiredCapabilities()));
    QuantumBatchJob batch = target.submitBatch(new QuantumBatch(submissions));
    List<QuantumJob> submittedJobs = new ArrayList<>(
        Objects.requireNonNull(batch.jobs(), "provider batch jobs"));
    List<JobCheckpoint> checkpoints = new ArrayList<>(submissions.size());
    try {
      if (submittedJobs.size() != submissions.size()) {
        throw new QuantumExecutionException("Provider batch returned the wrong job count");
      }
      for (int index = 0; index < submissions.size(); index++) {
        QuantumJob job = Objects.requireNonNull(
            submittedJobs.get(index), "provider batch job");
        if (job.id().isBlank()) {
          throw new QuantumExecutionException("Provider returned a job without an identity");
        }
        checkpoints.add(new JobCheckpoint(
            job.id(), submissions.get(index).identity(), job.state()));
      }
    } catch (RuntimeException failure) {
      Cleanup cleanup = cleanupJobs(submittedJobs);
      if (!cleanup.complete()) {
        failure.addSuppressed(new QuantumExecutionException(cleanup.detail()));
      }
      throw failure;
    }
    activeJobs = List.copyOf(submittedJobs);
    try {
      return persist(nextSnapshot(CampaignState.QUEUED, checkpoints, ""));
    } catch (RuntimeException failure) {
      Cleanup cleanup = cleanupJobs(activeJobs);
      activeJobs = List.of();
      if (!cleanup.complete()) {
        failure.addSuppressed(new QuantumExecutionException(cleanup.detail()));
      }
      throw failure;
    }
  }

  /** Polls provider state and persists an exact queued, running, or terminal checkpoint. */
  public Snapshot poll() {
    requireActive();
    CampaignState state = CampaignState.QUEUED;
    String detail = "";
    List<JobCheckpoint> checkpoints;
    try {
      checkpoints = currentCheckpoints();
    } catch (RuntimeException failure) {
      Cleanup cleanup = cleanupJobs(activeJobs);
      activeJobs = List.of();
      return persist(nextSnapshot(
          CampaignState.UNKNOWN, List.of(), cleanupDetail(failure, cleanup)));
    }
    for (JobCheckpoint checkpoint : checkpoints) {
      if (checkpoint.state() == JobState.FAILED) {
        state = CampaignState.FAILED;
        detail = "provider job failed: " + checkpoint.jobId();
        break;
      }
      if (checkpoint.state() == JobState.CANCELLED) {
        state = CampaignState.CANCELLED;
        detail = "provider job cancelled: " + checkpoint.jobId();
        break;
      }
      if (checkpoint.state() != JobState.QUEUED) {
        state = CampaignState.RUNNING;
      }
    }
    if (state == CampaignState.FAILED || state == CampaignState.CANCELLED) {
      Cleanup cleanup = cleanupJobs(activeJobs);
      activeJobs = List.of();
      checkpoints = List.of();
      if (!cleanup.complete()) {
        state = CampaignState.UNKNOWN;
        detail = cleanupDetail(detail, cleanup);
      }
    }
    return persist(nextSnapshot(state, checkpoints, detail));
  }

  /** Applies one terminal batch exactly once and checkpoints the next iteration. */
  public Snapshot completeCurrent(Duration timeout) {
    Objects.requireNonNull(timeout, "timeout");
    requireActive();
    if (timeout.isNegative() || timeout.isZero()) {
      throw new IllegalArgumentException("Optimizer completion timeout must be positive");
    }
    List<QuantumResult> results = new ArrayList<>(activeJobs.size());
    try {
      for (QuantumJob job : activeJobs) {
        results.add(job.await(timeout));
      }
    } catch (RuntimeException failure) {
      Cleanup cleanup = cleanupJobs(activeJobs);
      activeJobs = List.of();
      CampaignState failedState = cleanup.complete()
          ? CampaignState.FAILED : CampaignState.UNKNOWN;
      return persist(nextSnapshot(
          failedState, List.of(), cleanupDetail(failure, cleanup)));
    }

    Iteration iteration = iterations.get(snapshot.nextIteration());
    Set<String> applied = new LinkedHashSet<>(snapshot.appliedSubmissionIdentities());
    List<Double> objectives = new ArrayList<>(snapshot.objectives());
    double sum = 0;
    int accepted = 0;
    for (int index = 0; index < results.size(); index++) {
      QuantumResult result = results.get(index);
      QuantumSubmission submission = iteration.boundSubmissions().get(index).submission();
      QuantumJob job = activeJobs.get(index);
      if (!result.jobId().equals(job.id())
          || !result.submissionIdentity().equals(submission.identity())) {
        Cleanup cleanup = cleanupJobs(activeJobs);
        activeJobs = List.of();
        CampaignState failedState = cleanup.complete()
            ? CampaignState.FAILED : CampaignState.UNKNOWN;
        return persist(nextSnapshot(
            failedState,
            List.of(),
            cleanupDetail("provider result identity mismatch", cleanup)));
      }
      if (applied.add(result.submissionIdentity())) {
        sum += result.zExpectation(iteration.objectiveQubit()).value();
        accepted += 1;
      }
    }
    if (0 < accepted) {
      objectives.add(sum / accepted);
    }
    double best = objectives.stream().mapToDouble(Double::doubleValue)
        .min().orElse(snapshot.bestObjective());
    int nextIteration = snapshot.nextIteration() + 1;
    CampaignState nextState = nextIteration == iterations.size()
        ? CampaignState.COMPLETED : CampaignState.READY;
    activeJobs = List.of();
    Snapshot completed = new Snapshot(
        campaignId,
        nextState,
        nextIteration,
        snapshot.generation() + 1,
        List.of(),
        applied,
        objectives,
        best,
        "");
    return persist(completed);
  }

  /** Cancels every acknowledged member and persists a terminal campaign state. */
  public Snapshot cancel() {
    requireActive();
    Cleanup cleanup = cleanupJobs(activeJobs);
    activeJobs = List.of();
    CampaignState state = cleanup.complete()
        ? CampaignState.CANCELLED : CampaignState.UNKNOWN;
    return persist(nextSnapshot(
        state, List.of(), cleanupDetail("campaign cancelled", cleanup)));
  }

  public Snapshot snapshot() {
    return snapshot;
  }

  private void recoverActiveJobs() {
    if (snapshot.nextIteration() >= iterations.size()) {
      throw new IllegalArgumentException("Active optimizer snapshot has no iteration");
    }
    List<BoundSubmission> submissions = iterations.get(snapshot.nextIteration()).boundSubmissions();
    if (snapshot.activeJobs().size() != submissions.size()) {
      throw new IllegalArgumentException("Active optimizer snapshot has the wrong job count");
    }
    List<QuantumJob> recovered = new ArrayList<>(submissions.size());
    try {
      for (int index = 0; index < submissions.size(); index++) {
        JobCheckpoint checkpoint = snapshot.activeJobs().get(index);
        QuantumSubmission submission = submissions.get(index).submission();
        if (!checkpoint.submissionIdentity().equals(submission.identity())) {
          throw new IllegalArgumentException("Stored optimizer submission identity changed");
        }
        QuantumJob job = target.recover(checkpoint.jobId(), submission);
        if (!job.id().equals(checkpoint.jobId())) {
          throw new QuantumExecutionException("Provider recovered the wrong optimizer job");
        }
        recovered.add(job);
      }
      activeJobs = List.copyOf(recovered);
    } catch (RuntimeException failure) {
      Cleanup cleanup = cleanupJobs(recovered);
      activeJobs = List.of();
      persist(nextSnapshot(
          CampaignState.UNKNOWN, List.of(), cleanupDetail(failure, cleanup)));
    }
  }

  private List<JobCheckpoint> currentCheckpoints() {
    List<BoundSubmission> submissions = iterations.get(snapshot.nextIteration()).boundSubmissions();
    List<JobCheckpoint> checkpoints = new ArrayList<>(activeJobs.size());
    for (int index = 0; index < activeJobs.size(); index++) {
      QuantumJob job = activeJobs.get(index);
      checkpoints.add(new JobCheckpoint(
          job.id(), submissions.get(index).submission().identity(), job.state()));
    }
    return List.copyOf(checkpoints);
  }

  private Snapshot nextSnapshot(
      CampaignState state, List<JobCheckpoint> jobs, String detail) {
    return new Snapshot(
        campaignId,
        state,
        snapshot.nextIteration(),
        snapshot.generation() + 1,
        jobs,
        snapshot.appliedSubmissionIdentities(),
        snapshot.objectives(),
        snapshot.bestObjective(),
        detail);
  }

  private Snapshot persist(Snapshot value) {
    store.save(value);
    snapshot = value;
    return value;
  }

  private void requireActive() {
    if (snapshot.state() != CampaignState.QUEUED
        && snapshot.state() != CampaignState.RUNNING) {
      throw new IllegalStateException("Optimizer campaign has no active batch");
    }
  }

  private void requireState(CampaignState state) {
    if (snapshot.state() != state) {
      throw new IllegalStateException(
          "Optimizer campaign is " + snapshot.state() + ", expected " + state);
    }
  }

  private static List<Iteration> validatedIterations(List<Iteration> iterations) {
    List<Iteration> plans = List.copyOf(iterations);
    if (plans.isEmpty() || plans.size() > MAX_ITERATIONS) {
      throw new IllegalArgumentException("Optimizer campaign requires 1 to 64 iterations");
    }
    return plans;
  }

  private static String campaignIdentity(List<Iteration> iterations) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      updateLong(digest, iterations.size());
      for (Iteration iteration : iterations) {
        updateLong(digest, iteration.objectiveQubit());
        updateLong(digest, iteration.boundSubmissions().size());
        for (BoundSubmission bound : iteration.boundSubmissions()) {
          updateBytes(digest, bound.submission().identity().getBytes(StandardCharsets.US_ASCII));
          updateLong(digest, bound.parameters().size());
          for (Parameter parameter : bound.parameters()) {
            updateBytes(digest, parameter.name().getBytes(StandardCharsets.UTF_8));
            updateLong(digest, parameter.kind().ordinal());
            updateLong(digest, Double.doubleToLongBits(parameter.value()));
          }
        }
      }
      return HexFormat.of().formatHex(digest.digest());
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static void updateBytes(MessageDigest digest, byte[] value) {
    updateLong(digest, value.length);
    digest.update(value);
  }

  private static void updateLong(MessageDigest digest, long value) {
    for (int shift = 56; shift >= 0; shift -= Byte.SIZE) {
      digest.update((byte) (value >>> shift));
    }
  }

  private static Cleanup cleanupJobs(List<QuantumJob> jobs) {
    RuntimeException firstFailure = null;
    for (QuantumJob job : jobs) {
      try {
        job.cancel();
      } catch (RuntimeException failure) {
        if (firstFailure == null) {
          firstFailure = failure;
        } else {
          firstFailure.addSuppressed(failure);
        }
      }
    }
    if (firstFailure == null) {
      return new Cleanup(true, "");
    }
    return new Cleanup(false, "provider cleanup uncertain: " + boundedDetail(firstFailure));
  }

  private static String cleanupDetail(RuntimeException failure, Cleanup cleanup) {
    return cleanupDetail(boundedDetail(failure), cleanup);
  }

  private static String cleanupDetail(String detail, Cleanup cleanup) {
    if (cleanup.complete()) {
      return detail;
    }
    return boundedDetail(detail + ": " + cleanup.detail());
  }

  private static String boundedDetail(RuntimeException failure) {
    String detail = failure.getMessage();
    if (detail == null || detail.isBlank()) {
      detail = failure.getClass().getSimpleName();
    }
    return boundedDetail(detail);
  }

  private static String boundedDetail(String detail) {
    return detail.substring(0, Math.min(detail.length(), MAX_DETAIL));
  }

  private record Cleanup(boolean complete, String detail) {}

  public enum CampaignState {
    READY,
    QUEUED,
    RUNNING,
    COMPLETED,
    FAILED,
    CANCELLED,
    UNKNOWN
  }

  public enum ParameterKind {
    ANGLE,
    PROBABILITY,
    SCALAR
  }

  /** One typed finite parameter bound into a provider submission. */
  public record Parameter(String name, ParameterKind kind, double value) {
    public Parameter {
      Objects.requireNonNull(name, "name");
      Objects.requireNonNull(kind, "kind");
      if (name.isBlank() || name.length() > 1024 || !Double.isFinite(value)) {
        throw new IllegalArgumentException("Invalid optimizer parameter");
      }
      if (kind == ParameterKind.PROBABILITY && (value < 0 || 1 < value)) {
        throw new IllegalArgumentException("Optimizer probability is outside [0, 1]");
      }
    }
  }

  /** One submission plus the typed spelling of its exact parameter bindings. */
  public record BoundSubmission(QuantumSubmission submission, List<Parameter> parameters) {
    public BoundSubmission {
      Objects.requireNonNull(submission, "submission");
      parameters = List.copyOf(parameters);
      Map<String, Double> bindings = new TreeMap<>();
      for (Parameter parameter : parameters) {
        if (bindings.put(parameter.name(), parameter.value()) != null) {
          throw new IllegalArgumentException("Duplicate optimizer parameter " + parameter.name());
        }
      }
      if (!bindings.equals(submission.bindings())) {
        throw new IllegalArgumentException("Typed optimizer parameters do not match submission");
      }
    }
  }

  /** One bounded parameterized batch and the measured objective qubit. */
  public record Iteration(List<BoundSubmission> boundSubmissions, int objectiveQubit) {
    public Iteration {
      boundSubmissions = List.copyOf(boundSubmissions);
      if (boundSubmissions.isEmpty() || boundSubmissions.size() > MAX_SUBMISSIONS) {
        throw new IllegalArgumentException("Optimizer iteration requires 1 to 64 submissions");
      }
      if (objectiveQubit < 0 || objectiveQubit >= Long.SIZE - 1) {
        throw new IllegalArgumentException("Invalid optimizer objective qubit");
      }
      for (BoundSubmission bound : boundSubmissions) {
        int qubits = bound.submission().program()
            .quantumRegister(bound.submission().registerId()).qubits();
        if (objectiveQubit >= qubits) {
          throw new IllegalArgumentException("Optimizer objective qubit is outside its register");
        }
      }
    }
  }

  /** Provider identity and state retained in one recovery checkpoint. */
  public record JobCheckpoint(
      String jobId, String submissionIdentity, JobState state) {
    public JobCheckpoint {
      Objects.requireNonNull(jobId, "jobId");
      Objects.requireNonNull(submissionIdentity, "submissionIdentity");
      Objects.requireNonNull(state, "state");
      if (jobId.isBlank() || submissionIdentity.isBlank()) {
        throw new IllegalArgumentException("Optimizer job checkpoint requires identities");
      }
    }
  }

  /** Canonical logical optimizer checkpoint; adapters own its physical durability. */
  public record Snapshot(
      String campaignId,
      CampaignState state,
      int nextIteration,
      long generation,
      List<JobCheckpoint> activeJobs,
      Set<String> appliedSubmissionIdentities,
      List<Double> objectives,
      double bestObjective,
      String detail) {
    public Snapshot {
      Objects.requireNonNull(campaignId, "campaignId");
      Objects.requireNonNull(state, "state");
      activeJobs = List.copyOf(activeJobs);
      appliedSubmissionIdentities = Set.copyOf(new LinkedHashSet<>(
          appliedSubmissionIdentities));
      objectives = List.copyOf(objectives);
      Objects.requireNonNull(detail, "detail");
      if (campaignId.isBlank() || nextIteration < 0 || nextIteration > MAX_ITERATIONS
          || generation < 0 || detail.length() > MAX_DETAIL
          || activeJobs.size() > MAX_SUBMISSIONS
          || appliedSubmissionIdentities.size() > MAX_ITERATIONS * MAX_SUBMISSIONS
          || objectives.size() > MAX_ITERATIONS) {
        throw new IllegalArgumentException("Invalid optimizer snapshot");
      }
      if (appliedSubmissionIdentities.stream()
          .anyMatch(identity -> identity == null || identity.isBlank())) {
        throw new IllegalArgumentException("Applied optimizer results require identities");
      }
      if (objectives.stream().anyMatch(value -> value == null || !Double.isFinite(value))) {
        throw new IllegalArgumentException("Optimizer objectives must be finite");
      }
      if (!Double.isFinite(bestObjective) && bestObjective != Double.POSITIVE_INFINITY) {
        throw new IllegalArgumentException("Invalid optimizer best objective");
      }
    }
  }

  /** Atomic storage boundary for the latest checkpoint of each campaign. */
  public interface SnapshotStore {
    void save(Snapshot snapshot);

    Snapshot load(String campaignId);
  }
}
