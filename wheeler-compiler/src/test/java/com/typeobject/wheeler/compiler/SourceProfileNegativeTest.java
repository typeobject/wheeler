package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeException;
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
  void rejectsUnboundedAndReversibleControlFlow() {
    String unbounded = """
        classical class Unbounded {
          state long value = 0;
          entry void main() {
            while (value < 1) { value += 1; }
          }
        }
        """;
    String unboundedFor = """
        classical class UnboundedFor {
          entry void main() {
            for (long i = 0; i < 2; i += 1) { }
          }
        }
        """;
    String reversible = """
        classical class ReversibleBranch {
          state long value = 0;
          rev void update() {
            if (value == 0) { value += 1; }
          }
          entry void main() { update(); }
        }
        """;

    CompilerException loop = assertThrows(
        CompilerException.class, () -> new WheelerCompiler().compile(unbounded));
    CompilerException forLoop = assertThrows(
        CompilerException.class, () -> new WheelerCompiler().compile(unboundedFor));
    CompilerException branch = assertThrows(
        CompilerException.class, () -> new WheelerCompiler().compile(reversible));
    CompilerException loopJump = assertThrows(
        CompilerException.class,
        () -> compile("state long value = 0;", "break;"));
    assertTrue(loop.getMessage().contains("expected 'limit'"));
    assertTrue(forLoop.getMessage().contains("expected 'limit'"));
    assertTrue(branch.getMessage().contains("local control flow is not available"));
    assertTrue(loopJump.getMessage().contains("only valid inside a bounded loop"));
  }

  @Test
  void rejectsIncompleteReturnAndWrongValueCallSignature() {
    String incomplete = """
        classical class Incomplete {
          long value(long input) {
            long copy = input;
          }
          entry void main() { }
        }
        """;
    String wrongArity = """
        classical class WrongArity {
          state long result = 0;
          long add(long left, long right) { return left + right; }
          entry void main() {
            long value = add(1);
            result = value;
          }
        }
        """;

    assertThrows(BytecodeException.class, () -> new WheelerCompiler().compile(incomplete));
    CompilerException call = assertThrows(
        CompilerException.class, () -> new WheelerCompiler().compile(wrongArity));
    assertTrue(call.getMessage().contains("value call signature mismatch"));
  }

  @Test
  void rejectsBooleanAndSignedTypeMismatches() {
    CompilerException booleanBinding = assertThrows(
        CompilerException.class,
        () -> compile("state long value = 0;", "boolean flag = 1; if (flag) { value = 1; }"));
    CompilerException signedBinding = assertThrows(
        CompilerException.class,
        () -> compile("state long value = 0;", "long number = true; value = number;"));
    CompilerException condition = assertThrows(
        CompilerException.class,
        () -> compile("state long value = 0;", "if (1) { value = 1; }"));
    CompilerException argument = assertThrows(
        CompilerException.class,
        () -> compile(
            "state long value = 0; boolean identity(boolean input) { return input; }",
            "boolean result = identity(1); if (result) { value = 1; }"));
    CompilerException result = assertThrows(
        CompilerException.class,
        () -> compile(
            "state long value = 0; boolean identity(boolean input) { return input; }",
            "long result = identity(true); value = result;"));

    assertTrue(booleanBinding.getMessage().contains("expected boolean expression"));
    assertTrue(signedBinding.getMessage().contains("expected signed expression"));
    assertTrue(condition.getMessage().contains("expected boolean expression"));
    assertTrue(argument.getMessage().contains("expected boolean expression"));
    assertTrue(result.getMessage().contains("expected signed expression"));
  }

  @Test
  void rejectsMalformedRecordDeclarationsConstructionAndAccess() {
    String duplicateField = """
        classical class DuplicateField {
          record Pair(long value, boolean value) {}
          entry void main() { }
        }
        """;
    String wrongConstruction = """
        classical class WrongRecord {
          record Pair(long value, boolean valid) {}
          entry void main() { Pair pair = new Pair(true, 1); }
        }
        """;
    String missingField = """
        classical class MissingField {
          record Pair(long value) {}
          entry void main() {
            Pair pair = new Pair(1);
            long value = pair.missing;
          }
        }
        """;

    CompilerException duplicate = assertThrows(
        CompilerException.class, () -> new WheelerCompiler().compile(duplicateField));
    CompilerException construction = assertThrows(
        CompilerException.class, () -> new WheelerCompiler().compile(wrongConstruction));
    CompilerException field = assertThrows(
        CompilerException.class, () -> new WheelerCompiler().compile(missingField));
    assertTrue(duplicate.getMessage().contains("duplicate record field"));
    assertTrue(construction.getMessage().contains("expected signed expression"));
    assertTrue(field.getMessage().contains("unknown field missing"));
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
