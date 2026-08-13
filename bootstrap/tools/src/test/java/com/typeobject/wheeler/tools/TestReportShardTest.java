package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.runtime.ExecutionResult;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Verifies stable case partitioning and canonical shard reduction. */
final class TestReportShardTest {
  @Test
  void shardsAreDisjointCompleteAndMergeToTheSerialReport() throws Exception {
    List<TestReport.CaseResult> cases = new ArrayList<>();
    for (int index = 0; index < 32; index++) {
      String identity = "%064x".formatted(index);
      cases.add(TestReport.pass(
          "demo", "1.0.0", "case-" + index, identity,
          "a1".repeat(32), "b2".repeat(32), execution(index), "c3".repeat(32), index));
    }
    TestReport serial = new TestReport(cases);
    List<TestReport> shards = new ArrayList<>();
    boolean[] selected = new boolean[cases.size()];
    for (int shard = 0; shard < 7; shard++) {
      int selectedShard = shard;
      List<TestReport.CaseResult> shardCases = cases.stream()
          .filter(result -> TestReport.assignedToShard(result.caseIdentity(), selectedShard, 7))
          .toList();
      for (TestReport.CaseResult result : shardCases) {
        int index = Integer.parseInt(result.targetName().substring("case-".length()));
        assertTrue(!selected[index], "case selected by two shards");
        selected[index] = true;
      }
      shards.add(new TestReport(shardCases));
    }

    assertTrue(java.util.stream.IntStream.range(0, selected.length).allMatch(i -> selected[i]));
    TestReport merged = TestReport.combine(List.of(
        shards.get(6), shards.get(2), shards.get(4), shards.get(0),
        shards.get(5), shards.get(1), shards.get(3)));
    assertEquals(serial.cases(), merged.cases());
    assertEquals(serial.identity(), merged.identity());
  }

  @Test
  void rejectsInvalidShardCoordinatesAndDuplicateMergeRows() throws Exception {
    assertThrows(IllegalArgumentException.class,
        () -> TestReport.assignedToShard("00".repeat(32), -1, 2));
    assertThrows(IllegalArgumentException.class,
        () -> TestReport.assignedToShard("00".repeat(32), 2, 2));
    assertThrows(IllegalArgumentException.class,
        () -> TestReport.assignedToShard("bad", 0, 1));

    TestReport.CaseResult result = TestReport.pass(
        "demo", "1.0.0", "case", "00".repeat(32),
        "a1".repeat(32), "b2".repeat(32), execution(0), "c3".repeat(32), 0);
    TestReport report = new TestReport(List.of(result));
    assertThrows(IllegalArgumentException.class,
        () -> TestReport.combine(List.of(report, report)));

    List<TestReport.CaseResult> oversized = new ArrayList<>(65_536);
    for (int index = 0; index < 65_536; index++) {
      oversized.add(result);
    }
    IllegalArgumentException reportLimit = assertThrows(
        IllegalArgumentException.class, () -> new TestReport(oversized));
    assertEquals("Test report exceeds 65,535 cases", reportLimit.getMessage());
    assertThrows(IllegalArgumentException.class, () -> new TestReport(List.of(
        new TestReport.CaseResult(
            "demo", "1.0.0", "case", "bad", "a1".repeat(32), "",
            TestReport.Status.FAIL, "WTEST001", "malformed", 0, 0, "", ""))));
  }

  private static ExecutionResult execution(long value) {
    return new ExecutionResult(
        "demo", ProgramKind.CLASSICAL, Map.of("value", value), List.of(), List.of(), 1);
  }
}
