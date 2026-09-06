package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Scalar assembly must retain the signed minimum admitted by the source parser. */
final class SourceIntegerLiteralTest {
  @Test
  void assemblesSignedMinimumLiteralsAndRewinds() {
    for (String literal : List.of(
        "-9223372036854775808", "-9_223_372_036_854_775_808",
        "-0x8000000000000000", "-0b1" + "0".repeat(63))) {
      var program = new WheelerCompiler().compile("""
          classical class Minimum {
            state long selected = 0;
            entry void main() {
              long value = %s;
              selected = value;
            }
          }
          """.formatted(literal));
      var machine = new VirtualMachine(program);
      var initial = machine.snapshot();
      machine.run();
      assertEquals(Long.MIN_VALUE, machine.global("selected"), literal);
      while (machine.historySize() > 0) { machine.rewindOne(); }
      assertEquals(initial, machine.snapshot());
    }
  }

  @Test
  void rejectsBothFirstExcessSignedMagnitudes() {
    for (String literal : List.of(
        "9223372036854775808", "-9223372036854775809",
        "0x8000000000000000", "-0x8000000000000001")) {
      assertThrows(CompilerException.class, () -> new WheelerCompiler().compile(
          "classical class Excess { entry void main() { long value = " + literal + "; } }"), literal);
    }
  }
}
