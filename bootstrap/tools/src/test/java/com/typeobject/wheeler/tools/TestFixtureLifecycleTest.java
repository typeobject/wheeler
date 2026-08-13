package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** Executable ordering and cleanup evidence for source-declared test fixtures. */
final class TestFixtureLifecycleTest {
  @TempDir Path temporary;

  @Test
  void fixturePhasesWrapPassingCaseExactly() throws Exception {
    TestReport.CaseResult result = runCase("assert(value == 11);").cases().getFirst();

    assertEquals(TestReport.Status.PASS, result.status());
    assertEquals(4, result.assertions());
  }

  @Test
  void fixtureReleaseRunsAfterAssertionFailure() throws Exception {
    TestReport.CaseResult result = runCase("assert(value == 99);").cases().getFirst();

    assertEquals(TestReport.Status.FAIL, result.status());
    assertEquals("WTEST003", result.diagnosticCode(), result.diagnosticMessage());
    assertTrue(result.diagnosticMessage().contains("expected 99, got 11"));
    assertTrue(result.diagnosticMessage().contains("cleanup globals: value=1111"));
  }

  @Test
  void suiteReleaseRunsWhenCaseAcquireFails() throws Exception {
    TestReport.CaseResult result = runCase("assert(value == 11);", "case-acquire")
        .cases().getFirst();

    assertEquals(TestReport.Status.FAIL, result.status());
    assertEquals("WTEST003", result.diagnosticCode());
    assertTrue(result.diagnosticMessage().contains("expected 99, got 1"));
    assertTrue(result.diagnosticMessage().contains("cleanup globals: value=1001"));
  }

  @Test
  void bothReleasePhasesRunWhenCaseReleaseFails() throws Exception {
    TestReport.CaseResult result = runCase("assert(value == 11);", "case-release")
        .cases().getFirst();

    assertEquals(TestReport.Status.FAIL, result.status());
    assertEquals("WTEST002", result.diagnosticCode());
    assertTrue(result.diagnosticMessage().contains("case_release"));
    assertTrue(
        result.diagnosticMessage().contains("cleanup globals: value=1011"),
        result.diagnosticMessage());
  }

  @Test
  void fixtureReleaseRunsAfterRuntimeTrap() throws Exception {
    TestReport.CaseResult result = runCase("long zero = 0; long result = 1 / zero;")
        .cases().getFirst();

    assertEquals(TestReport.Status.FAIL, result.status());
    assertEquals("WTEST002", result.diagnosticCode(), result.diagnosticMessage());
    assertTrue(result.diagnosticMessage().contains("cleanup globals: value=1111"));
  }

  private TestReport runCase(String body) throws Exception {
    return runCase(body, "none");
  }

  private TestReport runCase(String body, String failurePhase) throws Exception {
    Path project = temporary.resolve(
        "fixture-" + Integer.toUnsignedString(body.hashCode()) + "-" + failurePhase);
    Files.createDirectories(project.resolve("src"));
    Files.writeString(project.resolve("wheeler.package.yaml"), """
        schema: 1
        package:
          name: "fixture.lifecycle"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "tests"
            root: "src/Main.w"
            test: true
        dependencies: []
        capabilities: []
        """);
    Files.writeString(project.resolve("src/Main.w"), """
        classical class Main {
          state long value = 0;
          void openSuite() { assert(value == 0); value += 1; }
          void openCase() { assert(value == %s); value += 10; }
          void closeCase() { assert(value == %s); value += 100; }
          void closeSuite() { value += 1000; }
          test void lifecycle()
              fixtures(suite_acquire = openSuite, case_acquire = openCase,
                  case_release = closeCase, suite_release = closeSuite) {
            %s
          }
          entry void main() { }
        }
        """.formatted(
            failurePhase.equals("case-acquire") ? "99" : "1",
            failurePhase.equals("case-release") ? "99" : "11",
            body));
    return PackageProject.load(project).test();
  }
}
