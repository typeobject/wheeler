package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Complete ordinary call statements retain qualifiers, results and independent frame widths. */
final class NativeCompilerCompleteCallStatementExampleTest {
  private static final String[] TYPES = {"long", "boolean", "borrow utf8", "borrow byteview",
      "borrow mut words", "borrow mut bytes", "borrow mut region", "borrow mut longmap"};
  private static final int[] CODES = {1, 2, 8, 13, 10, 11, 12, 9};

  @Test
  void comparesCompleteForwardedAndAssignedImportsAtZeroOneAnd64Arguments() throws Exception {
    for (int arity : new int[] {0, 1, 64}) {
      String parameters = IntStream.range(0, arity).mapToObj(index -> TYPES[index % TYPES.length]
          + " p" + index).collect(Collectors.joining(", "));
      String arguments = IntStream.range(0, arity).mapToObj(index -> "p" + index)
          .collect(Collectors.joining(", "));
      int[] codes = IntStream.range(0, arity).map(index -> CODES[index % CODES.length]).toArray();
      for (String target : List.of("remote", "dep.alpha::remote")) {
        NativeRetainedCallFixture.assertImported(NativeRetainedCallFixture.source(parameters,
            "void", target + "(" + arguments + ");"), target, codes, 0);
        for (String result : List.of("long", "boolean")) {
          for (String body : List.of("return CALL;", result + " answer = CALL; return answer;")) {
            String source = NativeRetainedCallFixture.source(parameters, result,
                body.replace("CALL", target + "(" + arguments + ")"));
            NativeRetainedCallFixture.assertImported(source, target, codes, result.equals("long") ? 1 : 2);
          }
        }
      }
    }
  }

  @Test
  void retainsCompleteReturnsAfterLoopsAndAcrossUtf8Trivia() throws Exception {
    for (String target : List.of("remote", "dep.alpha::remote")) {
      for (String prefix : List.of("", "long index = 0; while (index < 1) limit 1 { index += 1; }")) {
        String source = "//! Checks é before retained byte coordinates.\n"
            + NativeRetainedCallFixture.source("long number", "long", prefix
                + " return /* é */ " + target + "(/* é */ number /* é */) /* é */;");
        NativeRetainedCallFixture.assertImported(source, target, new int[] {1}, 1);
      }
    }
  }

  @Test
  void rejectsCallTailsInsteadOfDiscardingTheirValues() throws Exception {
    for (String target : List.of("recurse", "remote", "dep.alpha::remote")) {
      for (String body : List.of("return CALL + number;", "long answer = CALL + number; return answer;")) {
        String source = NativeRetainedCallFixture.source("long number", "long",
            body.replace("CALL", target + "(number)"));
        new WheelerCompiler().compileLibraryModuleFiles(Map.of("Call.w", source.replace(target + "(",
            "recurse(")), NativeRetainedCallFixture.MODULE);
        NativeRetainedCallFixture.assertRejected(source, !target.equals("recurse"),
            new int[] {1}, new int[] {1}, 1, 0);
      }
    }
  }

  @Test
  void rejectsDetachedQualifiersAndArityMismatchesBeforePublication() throws Exception {
    for (String body : List.of("return dep.beta::remote(number);", "return dep.alpha::missing(number);",
        "return dep.alpha::remote(number, number);", "return dep.alpha::remote(number) + 1;")) {
      NativeRetainedCallFixture.assertRejected(NativeRetainedCallFixture.source("long number", "long", body),
          true, new int[] {1}, new int[] {1}, 1, 0);
    }
  }
}
