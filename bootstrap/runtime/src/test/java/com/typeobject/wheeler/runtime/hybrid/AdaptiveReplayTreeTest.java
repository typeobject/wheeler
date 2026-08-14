package com.typeobject.wheeler.runtime.hybrid;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.runtime.hybrid.AdaptiveReplayTree.Node;
import com.typeobject.wheeler.runtime.hybrid.AdaptiveReplayTree.NodeKind;
import com.typeobject.wheeler.runtime.hybrid.AdaptiveReplayTree.Observation;
import com.typeobject.wheeler.runtime.hybrid.AdaptiveReplayTree.Plan;
import com.typeobject.wheeler.runtime.hybrid.AdaptiveReplayTree.RunSnapshot;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Tests bounded adaptive execution, target-free replay, and lineage separation. */
final class AdaptiveReplayTreeTest {
  private static final String EVIDENCE_A = "a".repeat(64);
  private static final String EVIDENCE_B = "b".repeat(64);
  private static final String LINEAGE = "1".repeat(64);

  @Test
  void replaysTheExactSelectedPathWithoutAnotherObservation() {
    Plan plan = plan();
    List<Long> liveValues = new ArrayList<>(List.of(5L, 4L));
    int[] calls = {0};

    RunSnapshot recorded = AdaptiveReplayTree.execute(plan, LINEAGE,
        (lineage, node, ordinal) -> {
          assertEquals(LINEAGE, lineage);
          calls[0]++;
          return new AdaptiveReplayTree.ObservedValue(
              liveValues.removeFirst(), ordinal == 0 ? EVIDENCE_A : EVIDENCE_B);
        });
    RunSnapshot replayed = AdaptiveReplayTree.replay(plan, recorded);

    assertEquals(2, calls[0]);
    assertEquals(4, recorded.terminalNode());
    assertEquals(1, recorded.result());
    assertEquals(recorded, replayed);
    assertEquals(2, recorded.observations().size());
    assertEquals(List.of(0, 1), recorded.observations().stream()
        .map(Observation::nodeId).toList());
  }

  @Test
  void rejectsMissingTrailingAndChangedBranchEvidence() {
    Plan plan = plan();
    RunSnapshot recorded = AdaptiveReplayTree.execute(plan, LINEAGE,
        (lineage, node, ordinal) -> new AdaptiveReplayTree.ObservedValue(
            ordinal == 0 ? 5 : 4, ordinal == 0 ? EVIDENCE_A : EVIDENCE_B));

    assertThrows(IllegalArgumentException.class, () -> AdaptiveReplayTree.replay(
        plan, snapshot(recorded, recorded.observations().subList(0, 1), recorded.identity())));

    List<Observation> trailing = new ArrayList<>(recorded.observations());
    trailing.add(new Observation(2, 4, 0, 4, EVIDENCE_A));
    assertThrows(IllegalArgumentException.class, () -> AdaptiveReplayTree.replay(
        plan, snapshot(recorded, trailing, recorded.identity())));

    List<Observation> changedBranch = new ArrayList<>(recorded.observations());
    Observation second = changedBranch.get(1);
    changedBranch.set(1, new Observation(
        second.ordinal(), second.nodeId(), second.value(), 3, second.evidenceIdentity()));
    assertThrows(IllegalArgumentException.class, () -> AdaptiveReplayTree.replay(
        plan, snapshot(recorded, changedBranch, recorded.identity())));

    List<Observation> changedEvidence = new ArrayList<>(recorded.observations());
    changedEvidence.set(1, new Observation(1, 1, 4, 4, EVIDENCE_A));
    assertThrows(IllegalArgumentException.class, () -> AdaptiveReplayTree.replay(
        plan, snapshot(recorded, changedEvidence, recorded.identity())));

    assertThrows(IllegalArgumentException.class, () -> AdaptiveReplayTree.replay(
        plan, snapshot(recorded, recorded.observations(), "f".repeat(64))));
  }

  @Test
  void selectsAnotherLeafAndCreatesDistinctRetryLineage() {
    Plan plan = plan();
    RunSnapshot upper = AdaptiveReplayTree.execute(plan, LINEAGE,
        (lineage, node, ordinal) -> new AdaptiveReplayTree.ObservedValue(10, EVIDENCE_A));
    String firstRetry = AdaptiveReplayTree.retryLineage(LINEAGE, 1);
    String secondRetry = AdaptiveReplayTree.retryLineage(LINEAGE, 2);

    assertEquals(2, upper.terminalNode());
    assertEquals(100, upper.result());
    assertEquals(1, upper.observations().size());
    assertEquals(firstRetry, AdaptiveReplayTree.retryLineage(LINEAGE, 1));
    assertNotEquals(LINEAGE, firstRetry);
    assertNotEquals(firstRetry, secondRetry);
  }

  @Test
  void rejectsNoncanonicalOrUnreachablePlansBeforeObservation() {
    assertThrows(IllegalArgumentException.class, () -> new Plan(List.of(
        new Node(0, NodeKind.DECISION, 0, 1, 2),
        new Node(2, NodeKind.TERMINAL, 0, -1, -1))));
    assertThrows(IllegalArgumentException.class, () -> new Plan(List.of(
        new Node(0, NodeKind.DECISION, 0, 2, 2),
        new Node(1, NodeKind.TERMINAL, 0, -1, -1),
        new Node(2, NodeKind.TERMINAL, 0, -1, -1))));
    assertThrows(IllegalArgumentException.class, () -> new Plan(List.of(
        new Node(0, NodeKind.TERMINAL, 0, -1, -1),
        new Node(1, NodeKind.TERMINAL, 1, -1, -1))));
    assertThrows(IllegalArgumentException.class, () -> new Plan(List.of(
        new Node(0, NodeKind.DECISION, 0, 1, 2),
        new Node(1, NodeKind.DECISION, 0, 3, 4),
        new Node(2, NodeKind.DECISION, 0, 4, 5),
        new Node(3, NodeKind.TERMINAL, 0, -1, -1),
        new Node(4, NodeKind.TERMINAL, 0, -1, -1),
        new Node(5, NodeKind.TERMINAL, 0, -1, -1))));
  }

  private static Plan plan() {
    return new Plan(List.of(
        new Node(0, NodeKind.DECISION, 10, 1, 2),
        new Node(1, NodeKind.DECISION, 3, 3, 4),
        new Node(2, NodeKind.TERMINAL, 100, -1, -1),
        new Node(3, NodeKind.TERMINAL, -1, -1, -1),
        new Node(4, NodeKind.TERMINAL, 1, -1, -1)));
  }

  private static RunSnapshot snapshot(
      RunSnapshot original, List<Observation> observations, String identity) {
    return new RunSnapshot(
        original.planIdentity(),
        original.lineageIdentity(),
        observations,
        original.terminalNode(),
        original.result(),
        identity);
  }
}
