package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler.TestCase;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Source and artifact validation for explicit test lifecycle fixtures. */
final class SourceTestFixtureTest {
  @Test
  void resolvesFourDistinctFixtureFunctions() {
    TestCase test = compile(baseSource("openSuite", "openCase", "closeCase", "closeSuite"));

    assertTrue(test.fixtures().present());
    assertEquals(4, java.util.stream.IntStream.of(
        test.fixtures().suiteAcquire(),
        test.fixtures().caseAcquire(),
        test.fixtures().caseRelease(),
        test.fixtures().suiteRelease()).distinct().count());
  }

  @Test
  void rejectsMalformedDuplicateMissingAndMistypedFixtures() {
    CompilerException duplicate = assertThrows(
        CompilerException.class,
        () -> compile(baseSource("openSuite", "openSuite", "closeCase", "closeSuite")));
    CompilerException missing = assertThrows(
        CompilerException.class,
        () -> compile(baseSource("missing", "openCase", "closeCase", "closeSuite")));
    CompilerException typed = assertThrows(
        CompilerException.class,
        () -> compile(baseSource("badSuite", "openCase", "closeCase", "closeSuite")));
    CompilerException parameterized = assertThrows(
        CompilerException.class,
        () -> compile(baseSource("openSuite", "openCase", "closeCase", "closeSuite")
            .replace("test void lifecycle()", "test void lifecycle(long row) cases(1)")));

    assertTrue(duplicate.getMessage().contains("four distinct functions"));
    assertTrue(missing.getMessage().contains("fixture function is missing"));
    assertTrue(typed.getMessage().contains("fixture function must have no parameters"));
    assertTrue(parameterized.getMessage().contains("unparameterized case"));
  }

  private static TestCase compile(String source) {
    List<TestCase> tests = new WheelerCompiler().compileTests(source);
    assertEquals(1, tests.size());
    return tests.getFirst();
  }

  private static String baseSource(
      String suiteAcquire, String caseAcquire, String caseRelease, String suiteRelease) {
    return """
        classical class FixtureSource {
          void openSuite() { }
          void openCase() { }
          void closeCase() { }
          void closeSuite() { }
          void badSuite(long value) { assert(value == value); }
          test void lifecycle()
              fixtures(suite_acquire = %s, case_acquire = %s,
                  case_release = %s, suite_release = %s) { }
          entry void main() { }
        }
        """.formatted(suiteAcquire, caseAcquire, caseRelease, suiteRelease);
  }
}
