package com.typeobject.wheeler.examples;

import java.util.List;
import org.junit.jupiter.api.Test;

/** Keeps the former eight-argument boundary as an admitted retained-call regression. */
final class NativeCompilerEightArgumentSourceProductExampleTest {
  private static final String PARAMETERS = "long first, boolean flag, borrow utf8 text, "
      + "borrow byteview view, borrow mut words cells, borrow mut bytes data, "
      + "long count, boolean last";
  private static final String ARGUMENTS = "first, flag, text, view, cells, data, count, last";
  private static final int[] TYPES = {1, 2, 8, 13, 10, 11, 1, 2};

  @Test
  void emitsEightArgumentRootValueAndForwardCalls() throws Exception {
    assertLocal("long", "long result = recurse(" + ARGUMENTS + ");\nreturn result;");
    assertLocal("long", "return recurse(" + ARGUMENTS + ");");
  }

  @Test
  void emitsEightArgumentLoopAndGuardedCalls() throws Exception {
    assertLocal("long", """
        long index = 0;
        while (index < 1) limit 1 {
          long result = recurse(ARGUMENTS);
          index += 1;
        }
        return first;
        """.replace("ARGUMENTS", ARGUMENTS));
    assertLocal("boolean", """
        if (recurse(ARGUMENTS)) {
          return false;
        }
        return true;
        """.replace("ARGUMENTS", ARGUMENTS));
  }

  @Test
  void emitsEightArgumentVoidCallsAtRootAndInLoops() throws Exception {
    assertLocal("void", "recurse(" + ARGUMENTS + ");");
    assertLocal("void", """
        long index = 0;
        while (index < 1) limit 1 {
          recurse(ARGUMENTS);
          index += 1;
        }
        """.replace("ARGUMENTS", ARGUMENTS));
  }

  @Test
  void preservesTheExistingArgumentBearingInverseRejection() throws Exception {
    for (int arity : new int[] {1, 8}) {
      String arguments = arity == 1 ? "first" : ARGUMENTS;
      String source = source("rev void", "recurse(" + arguments + ");")
          .replace("\n}\n}\n", "\n}\ntheorem recurseInverse proves inverse(recurse);\n}\n");
      if (arity == 1) {
        source = source.replace(PARAMETERS, "long first");
      }
      int[] types = arity == 1 ? new int[] {1} : TYPES;
      NativeRetainedCallFixture.assertRejected(source, false, types, types, 0, 2);
    }
  }

  @Test
  void resolvesEightImportedArgumentsWithoutDependencySource() throws Exception {
    for (String target : List.of("remote", "dep.alpha::remote")) {
      assertImported(target, "long", "long result = CALL;\nreturn result;");
      assertImported(target, "boolean", "boolean result = CALL;\nreturn result;");
      assertImported(target, "long", """
          long index = 0;
          while (index < 1) limit 1 {
            long result = CALL;
            index += 1;
          }
          return first;
          """);
      assertImported(target, "void", "CALL;");
      assertImported(target, "void", """
          long index = 0;
          while (index < 1) limit 1 {
            CALL;
            index += 1;
          }
          """);
    }
  }

  @Test
  void rejectsWrongEighthTypesMissingValuesAndArityMismatchesBeforePublication() throws Exception {
    int[] wrongTypes = TYPES.clone();
    wrongTypes[7] = 1;
    NativeRetainedCallFixture.assertRejected(
        source("long", "return remote(" + ARGUMENTS + ");"), true, TYPES, wrongTypes, 1, 0);
    NativeRetainedCallFixture.assertRejected(
        source("long", "return recurse(" + ARGUMENTS + ", first);"), false, TYPES, TYPES, 1, 0);
    NativeRetainedCallFixture.assertRejected(
        source("long", "return recurse(" + ARGUMENTS.replace("last", "missing") + ");"),
        false, TYPES, TYPES, 1, 0);
  }

  private static void assertLocal(String result, String body) throws Exception {
    NativeRetainedCallFixture.assertLocal(source(result, body), TYPES);
  }

  private static void assertImported(String target, String result, String body) throws Exception {
    int resultType = switch (result) {
      case "void" -> 0;
      case "boolean" -> 2;
      default -> 1;
    };
    NativeRetainedCallFixture.assertImported(
        source(result, body.replace("CALL", target + "(" + ARGUMENTS + ")")),
        target, TYPES, resultType);
  }

  private static String source(String result, String body) {
    return NativeRetainedCallFixture.source(PARAMETERS, result, body);
  }
}
