package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

/** Checks stable source locations and reversible-operation diagnostics. */
final class SourceDiagnosticTest {
  @Test
  void reportsSourceErrorsWithLines() {
    String source = """
        classical class Counter {
          state long count = 0;
          rev void increment() {
            count += 1;
          }
          entry void main() {}
        }
        """;
    CompilerException unknown = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile(source.replace("count += 1", "missing += 1")));
    CompilerException irreversible = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile(source.replace("count += 1", "count = 1")));

    assertTrue(unknown.getMessage().contains("line 4"));
    assertTrue(irreversible.getMessage().contains("no generated inverse"));
  }
}
