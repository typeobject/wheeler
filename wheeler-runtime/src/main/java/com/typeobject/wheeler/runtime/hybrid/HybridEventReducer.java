package com.typeobject.wheeler.runtime.hybrid;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/** Deterministic integrity-checked reduction of unordered, at-least-once event delivery. */
public final class HybridEventReducer {
  private HybridEventReducer() {}

  public static HybridReduction reduce(Collection<HybridEvent> delivered) {
    if (delivered.isEmpty()) {
      throw new HybridRunException("Hybrid event stream is empty");
    }
    TreeMap<Long, HybridEvent> ordered = new TreeMap<>();
    for (HybridEvent event : delivered) {
      HybridEvent previous = ordered.putIfAbsent(event.sequence(), event);
      if (previous != null && !previous.equals(event)) {
        throw new HybridRunException("Conflicting hybrid events at sequence " + event.sequence());
      }
    }

    String runId = ordered.firstEntry().getValue().runId();
    String activeBranch = "";
    RunStatus status = RunStatus.ACTIVE;
    long commitHorizon = -1;
    Map<String, HybridEvent> submissions = new HashMap<>();
    Map<Integer, AppliedObservation> applied = new LinkedHashMap<>();
    List<HybridEvent> canonical = new ArrayList<>(ordered.size());
    long expected = 0;
    for (HybridEvent event : ordered.values()) {
      if (event.sequence() != expected++) {
        throw new HybridRunException("Hybrid event sequence has a gap before " + event.sequence());
      }
      if (!runId.equals(event.runId())) {
        throw new HybridRunException("Hybrid event stream mixes run identities");
      }
      if (event.sequence() == 0 && event.kind() != HybridEventKind.RUN_STARTED) {
        throw new HybridRunException("First hybrid event is not RUN_STARTED");
      }
      switch (event.kind()) {
        case RUN_STARTED -> activeBranch = event.branchId();
        case TARGET_SELECTED, TRANSACTION_STARTED -> requireActive(event, activeBranch);
        case TRANSACTION_ABORTED -> {
          activeBranch = event.branchId();
          status = RunStatus.ACTIVE;
        }
        case QUANTUM_SUBMITTED -> {
          requireActive(event, activeBranch);
          submissions.put(key(event.branchId(), event.workflowIndex()), event);
          status = RunStatus.WAITING;
        }
        case QUANTUM_APPLIED -> {
          requireActive(event, activeBranch);
          HybridEvent submission = submissions.get(key(event.branchId(), event.workflowIndex()));
          if (submission == null || !submission.jobId().equals(event.jobId())
              || !submission.target().equals(event.target())) {
            throw new HybridRunException("Applied result has no matching submission");
          }
          applied.put(event.workflowIndex(), new AppliedObservation(
              event.workflowIndex(), event.jobId(), event.target(), event.value(), event.branchId()));
          status = RunStatus.ACTIVE;
        }
        case CANCELLATION_REQUESTED -> requireActive(event, activeBranch);
        case BRANCH_RETRIED -> {
          activeBranch = event.branchId();
          status = RunStatus.ACTIVE;
        }
        case BRANCH_DISCARDED -> {
          requireActive(event, activeBranch);
          status = RunStatus.CANCELLED;
        }
        case COMMITTED -> {
          requireActive(event, activeBranch);
          commitHorizon = event.sequence();
        }
        case RUN_COMPLETED -> {
          requireActive(event, activeBranch);
          status = RunStatus.COMPLETED;
        }
        case RUN_TRAPPED -> {
          requireActive(event, activeBranch);
          status = RunStatus.TRAPPED;
        }
      }
      canonical.add(event);
    }
    return new HybridReduction(
        runId, activeBranch, status, commitHorizon, List.copyOf(canonical), Map.copyOf(applied));
  }

  private static void requireActive(HybridEvent event, String activeBranch) {
    if (!event.branchId().equals(activeBranch)) {
      throw new HybridRunException(
          "Event for inactive branch " + event.branchId() + " at sequence " + event.sequence());
    }
  }

  private static String key(String branch, int workflowIndex) {
    return branch + '\u0000' + workflowIndex;
  }

  public record AppliedObservation(
      int workflowIndex, String jobId, String target, long value, String branchId) {}

  public record HybridReduction(
      String runId,
      String activeBranch,
      RunStatus status,
      long commitHorizon,
      List<HybridEvent> events,
      Map<Integer, AppliedObservation> applied) {}
}
