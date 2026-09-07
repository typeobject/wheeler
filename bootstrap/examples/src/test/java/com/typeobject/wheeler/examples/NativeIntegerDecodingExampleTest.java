package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Signed decoding retains both endpoints and the independent digit and coordinate bounds. */
final class NativeIntegerDecodingExampleTest {
  private record Magnitude(String text, long negative, boolean positiveValid) {}

  @Test
  void decodesBothSignedDomainsWithoutAValueSentinelAndRewinds() throws Exception {
    Program positive = scannerProgram("0", "bufferLength(source)", false);
    Program negative = scannerProgram("0", "bufferLength(source)", true);
    for (Magnitude sample : List.of(
        new Magnitude("0", 0, true), new Magnitude("00_0", 0, true),
        new Magnitude("1", -1, true), new Magnitude("42", -42, true),
        new Magnitude("9223372036854775807", -Long.MAX_VALUE, true),
        new Magnitude("9_223_372_036_854_775_807", -Long.MAX_VALUE, true),
        new Magnitude("0x7fff_FFFF_ffff_FFFF", -Long.MAX_VALUE, true),
        new Magnitude("0b" + "1".repeat(63), -Long.MAX_VALUE, true),
        new Magnitude("9223372036854775808", Long.MIN_VALUE, false),
        new Magnitude("9_223_372_036_854_775_808", Long.MIN_VALUE, false),
        new Magnitude("0x8000_0000_0000_0000", Long.MIN_VALUE, false),
        new Magnitude("0b1" + "0".repeat(63), Long.MIN_VALUE, false))) {
      check(negative, sample.text(), true, sample.negative(),
          sample.positiveValid() ? -sample.negative() : -1);
      check(positive, sample.text(), sample.positiveValid(),
          sample.positiveValid() ? -sample.negative() : 91,
          sample.positiveValid() ? -sample.negative() : -1);
    }
  }

  @Test
  void rejectsInvalidDigitsAndFirstExcessMagnitudesWithoutPublication() throws Exception {
    for (boolean negative : List.of(false, true)) {
      Program program = scannerProgram("0", "bufferLength(source)", negative);
      for (String source : List.of("", "_", "0x", "0b", "0x_", "0b2", "0xG", "1a",
          "0X1", "0B1", "-1", "+1", "é", "𝄞", "1é", "1 2",
          "9223372036854775809", "9_223_372_036_854_775_809",
          "0x8000000000000001", "0b1" + "0".repeat(62) + "1")) {
        check(program, source, false, 91, -1);
      }
    }
  }

  @Test
  void checksExtentsBeforeReadingAndKeepsUtf8Coordinates() throws Exception {
    for (long[] window : List.of(
        new long[] {-1, 2}, new long[] {0, -1}, new long[] {2, 1}, new long[] {0, 0},
        new long[] {0, 3}, new long[] {3, 3}, new long[] {Long.MIN_VALUE, 2},
        new long[] {Long.MAX_VALUE, Long.MAX_VALUE}, new long[] {0, Long.MAX_VALUE},
        new long[] {0, Long.MIN_VALUE})) {
      check(scannerProgram(Long.toString(window[0]), Long.toString(window[1]), true),
          "42", false, 91, -1);
    }
    Program program = scannerProgram("3", "bufferLength(source) - 5", true);
    check(program, "é 9223372036854775808 𝄞", true, Long.MIN_VALUE, -1);
    check(program, "é 42 𝄞", true, -42, 42);
  }

  @Test
  void preservesTheSixtyFourDigitAndSeparatorIterations() throws Exception {
    Program program = scannerProgram("0", "bufferLength(source)", true);
    for (String prefix : List.of("", "0x", "0b")) {
      for (String digits : List.of("0".repeat(64), "0" + "_".repeat(63))) {
        check(program, prefix + digits, true, 0, 0);
        var machine = new VirtualMachine(program,
            (prefix + digits + "0").getBytes(StandardCharsets.UTF_8));
        var initial = machine.snapshot();
        assertThrows(VmTrap.class, machine::run);
        assertEquals(0, machine.global("published"));
        assertEquals(91, machine.global("decoded"));
        rewind(machine);
        assertEquals(initial, machine.snapshot());
      }
    }
  }

  @Test
  void decodesScannerColumnsWithoutChangingThemAndRejectsUncheckedOverflow() throws Exception {
    Program program = NativeSourceFrontFixture.program(List.of("wheeler.compiler.tokens"), 16,
        "state long decoded = 91; state long published = 0;", """
        assert(signedNumberWidth(source, kinds, starts, 0) == 2);
        if (signedNumberValid(source, starts, lengths, 0)) {
          decoded = parsedSignedNumber(source, starts, lengths, 0);
          published = 1;
        }
        """);
    NativeSourceFrontFixture.check(program, "// café 𝄞\n-9223372036854775808;", machine -> {
      assertEquals(Long.MIN_VALUE, machine.global("decoded"));
      assertEquals(1, machine.global("published"));
    });
    NativeSourceFrontFixture.check(program, "-9223372036854775809;", machine -> {
      assertEquals(91, machine.global("decoded"));
      assertEquals(0, machine.global("published"));
    });
    Program unchecked = NativeSourceFrontFixture.program(List.of("wheeler.compiler.tokens"), 16,
        "state long decoded = 91;", "decoded = parsedSignedNumber(source, starts, lengths, 0);");
    var machine = new VirtualMachine(unchecked, "9223372036854775808".getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();
    assertThrows(VmTrap.class, machine::run);
    assertEquals(91, machine.global("decoded"));
    rewind(machine);
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void rejectsMissingColumnsAndInvalidTokenExtentsBeforeReads() throws Exception {
    for (long token : new long[] {-1, 2, Long.MIN_VALUE, Long.MAX_VALUE}) {
      checkColumns(2, 2, token, 0, 1, false);
    }
    checkColumns(1, 2, 0, 0, 1, false);
    checkColumns(2, 1, 0, 0, 1, false);
    for (long[] extent : List.of(new long[] {-1, 1}, new long[] {0, 0},
        new long[] {0, -1}, new long[] {3, 1}, new long[] {0, 4},
        new long[] {Long.MAX_VALUE, 1}, new long[] {0, Long.MAX_VALUE},
        new long[] {Long.MIN_VALUE, 1}, new long[] {0, Long.MIN_VALUE})) {
      checkColumns(2, 2, 0, extent[0], extent[1], false);
    }
    checkColumns(2, 2, 0, 0, 2, false);
    checkColumns(2, 2, 0, 0, 1, true);
  }

  private static void checkColumns(int starts, int lengths, long token,
      long start, long length, boolean valid) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.tokens"));
    sources.put("Probe.w", """
        module example.number_columns;
        import wheeler.compiler.tokens;
        classical class Probe {
          state long valid = 0;
          entry void main(borrow utf8 source) {
            region arena = new region(32, 2);
            words starts = allocate(arena, %d);
            words lengths = allocate(arena, %d);
            set(starts, 0, %d);
            set(lengths, 0, %d);
            %s
            %s
            if (signedNumberValid(source, starts, lengths, %d)) {
              valid = 1;
            }
            assert(starts[0] == %d);
            assert(lengths[0] == %d);
            %s
            %s
            drop(lengths);
            drop(starts);
            drop(arena);
          }
        }
        """.formatted(starts, lengths, start, length,
            starts == 2 ? "set(starts, 1, 1);" : "",
            lengths == 2 ? "set(lengths, 1, 2);" : "", token, start, length,
            starts == 2 ? "assert(starts[1] == 1);" : "",
            lengths == 2 ? "assert(lengths[1] == 2);" : ""));
    Program program = new WheelerCompiler().compileModuleFiles(sources, "example.number_columns");
    var machine = new VirtualMachine(program, "-42".getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();
    machine.run();
    assertEquals(valid ? 1 : 0, machine.global("valid"));
    rewind(machine);
    assertEquals(initial, machine.snapshot());
  }

  private static Program scannerProgram(String start, String end, boolean negative) throws Exception {
    return new WheelerCompiler().compileModuleFiles(Map.of(
        "Scanner.w", CompilerSources.read("lexer/Scanner.w"), "Probe.w", """
        module example.number_probe;
        import wheeler.lexer.scanner;
        classical class Probe {
          state long decoded = 91;
          state long published = 0;
          state long nonnegative = 91;
          entry void main(borrow utf8 source) {
            NumberValue number = parseSignedNumber(source, %s, %s, %s);
            if (number.valid) {
              decoded = number.value;
              published = 1;
            }
            nonnegative = parseNumber(source, %s, %s);
          }
        }
        """.formatted(start, end, negative, start, end)), "example.number_probe");
  }

  private static void check(Program program, String source, boolean valid, long value, long nonnegative) {
    var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();
    machine.run();
    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(valid ? 1 : 0, machine.global("published"), source);
    assertEquals(value, machine.global("decoded"), source);
    assertEquals(nonnegative, machine.global("nonnegative"), source);
    assertEquals(1, machine.snapshot().buffers().size());
    rewind(machine);
    assertEquals(initial, machine.snapshot());
  }

  private static void rewind(VirtualMachine machine) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
  }
}
