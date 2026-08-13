package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.runtime.ExecutionResult;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Checks that terminal, JSON, and JUnit XML adapt one semantic test report. */
final class TestReportRendererTest {
  private static final String CASE_A = "01".repeat(32);
  private static final String CASE_B = "02".repeat(32);
  private static final String SOURCE = "03".repeat(32);
  private static final String ARTIFACT = "04".repeat(32);
  private static final String COVERAGE = "05".repeat(32);

  @Test
  void allAdaptersCarryTheSameSortedOutcomesAndReportIdentity() throws Exception {
    TestReport report = report();

    String terminal = TestReportRenderer.render(
        report, "demo & laws", TestReportRenderer.Format.TERMINAL);
    String json = TestReportRenderer.render(
        report, "demo & laws", TestReportRenderer.Format.JSON);
    String xml = TestReportRenderer.render(
        report, "demo & laws", TestReportRenderer.Format.JUNIT_XML);

    assertTrue(terminal.indexOf(CASE_A) < terminal.indexOf(CASE_B));
    assertTrue(json.indexOf(CASE_A) < json.indexOf(CASE_B));
    assertTrue(xml.indexOf(CASE_A) < xml.indexOf(CASE_B));
    for (String rendered : List.of(terminal, json, xml)) {
      assertTrue(rendered.contains(report.identity()));
      assertTrue(rendered.contains(CASE_A));
      assertTrue(rendered.contains(CASE_B));
      assertTrue(rendered.contains("WTEST003"));
      assertTrue(rendered.contains("failed &lt;check&gt;")
          || rendered.contains("failed <check>"));
    }
    assertTrue(json.contains("\"selected\":2,\"passed\":1,\"failed\":1"));
    assertTrue(xml.contains("tests=\"2\" failures=\"1\""));
    assertTrue(xml.contains("name=\"demo &amp; laws\""));
    assertEquals(json, TestReportRenderer.render(
        report, "demo & laws", TestReportRenderer.Format.JSON));
  }

  @Test
  void formatNamesAreClosed() {
    assertEquals(TestReportRenderer.Format.TERMINAL,
        TestReportRenderer.Format.parse("terminal"));
    assertEquals(TestReportRenderer.Format.JSON, TestReportRenderer.Format.parse("json"));
    assertEquals(TestReportRenderer.Format.JUNIT_XML,
        TestReportRenderer.Format.parse("junit-xml"));
    assertThrows(IllegalArgumentException.class,
        () -> TestReportRenderer.Format.parse("xml"));
  }

  private static TestReport report() throws IOException {
    ExecutionResult execution = new ExecutionResult(
        "demo", ProgramKind.CLASSICAL, Map.of("value", 1L), List.of(), List.of(), 7);
    TestReport.CaseResult pass = TestReport.pass(
        "demo", "1.0.0", "laws::passes", CASE_B, SOURCE, ARTIFACT,
        execution, COVERAGE, 2);
    TestReport.CaseResult fail = TestReport.fail(
        "demo", "1.0.0", "laws::fails", CASE_A, SOURCE, ARTIFACT,
        "WTEST003", "failed <check>", 1);
    return new TestReport(List.of(pass, fail));
  }
}
