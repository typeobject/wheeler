package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.Program;
import org.junit.jupiter.api.Test;

/** Static unitary calls flatten into one canonical circuit without ambient control state. */
final class SourceUnitaryCallTest {
  @Test
  void repeatedUnitaryCallsFlattenInSourceOrder() {
    Program program = new WheelerCompiler().compile("""
        quantum class CalledUnitary {
          state long measured = 0;
          qreg q = new qreg(2);

          /// Applies one controlled half-turn.
          unitary void halfPower() {
            CPhase(q[1], q[0], 1.5707963267948966);
          }

          /// Calls the controlled power twice.
          unitary void fullPower() {
            H(q[0]);
            halfPower();
            halfPower();
            H(q[0]);
          }

          /// Runs the called unitary.
          entry void main() {
            prepare(q, 2);
            fullPower();
            measured = measure(q);
          }
        }
        """);

    assertEquals(
        4,
        program.quantumCircuits().stream()
            .filter(circuit -> circuit.name().equals("fullPower"))
            .findFirst()
            .orElseThrow()
            .operations()
            .size());
  }

  @Test
  void recursiveUnknownAndCrossRegisterCallsFailClosed() {
    CompilerException recursive = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile("""
            quantum class RecursiveUnitary {
              state long measured = 0;
              qreg q = new qreg(1);
              unitary void cycle() { H(q[0]); cycle(); }
              entry void main() { prepare(q, 0); cycle(); measured = measure(q); }
            }
            """));
    CompilerException unknown = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile("""
            quantum class UnknownUnitary {
              state long measured = 0;
              qreg q = new qreg(1);
              unitary void caller() { H(q[0]); missing(); }
              entry void main() { prepare(q, 0); caller(); measured = measure(q); }
            }
            """));
    CompilerException crossRegister = assertThrows(
        CompilerException.class,
        () -> new WheelerCompiler().compile("""
            quantum class CrossRegisterUnitary {
              state long measured = 0;
              qreg left = new qreg(1);
              qreg right = new qreg(1);
              unitary void target() { H(right[0]); }
              unitary void caller() { H(left[0]); target(); }
              entry void main() { prepare(left, 0); caller(); measured = measure(left); }
            }
            """));

    assertTrue(recursive.getMessage().contains("recursive unitary call"), recursive.getMessage());
    assertTrue(unknown.getMessage().contains("unknown unitary method"), unknown.getMessage());
    assertTrue(
        crossRegister.getMessage().contains("call must use the caller's qreg"),
        crossRegister.getMessage());
  }
}
