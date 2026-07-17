package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class SourceProfileNegativeTest {
  @Test
  void rejectsUnsupportedJavaDeclaration() {
    CompilerException exception = assertThrows(
        CompilerException.class,
        () -> compile("state int value = 0;", ""));

    assertTrue(exception.getMessage().contains("expected 'long'"));
  }

  @Test
  void rejectsMalformedBlockWithSourceLocation() {
    CompilerException exception = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile("""
            classical class Broken {
              state long value = 0;
              entry void main() {
                value += 1;
            }
            """));

    assertTrue(exception.getMessage().contains("line 6"));
  }

  @Test
  void rejectsUnresolvedAndIllegalInverseCalls() {
    assertThrows(
        CompilerException.class,
        () -> compile("state long value = 0;", "missing();"));
    CompilerException inverse = assertThrows(
        CompilerException.class,
        () -> compile("state long value = 0; void update() { value = 1; }", "reverse update();"));

    assertTrue(inverse.getMessage().contains("not reversible"));
  }

  @Test
  void rejectsOutOfRangeQuantumReference() {
    String source = """
        quantum class BrokenQubit {
          state long measured = 0;
          qreg q = new qreg(1);
          unitary void invalid() { X(q[1]); }
          entry void main() {
            prepare(q, 0);
            invalid();
            measured = measure(q);
          }
        }
        """;

    CompilerException exception = assertThrows(
        CompilerException.class, () -> new WheelerCompiler().compile(source));
    assertTrue(exception.getMessage().contains("line 4"));
  }

  private static com.typeobject.wheeler.core.bytecode.Program compile(
      String declarations, String entry) {
    return new WheelerCompiler().compile("""
        classical class Fixture {
          %s
          entry void main() {
            %s
          }
        }
        """.formatted(declarations, entry));
  }
}
