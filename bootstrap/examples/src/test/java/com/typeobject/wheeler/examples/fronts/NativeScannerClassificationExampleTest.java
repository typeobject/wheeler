package com.typeobject.wheeler.examples.fronts;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerMachineRunner;
import com.typeobject.wheeler.examples.CompilerSources;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Exhaustive native classification and complete ASCII-path rewind evidence. */
final class NativeScannerClassificationExampleTest {
  private static final int ASCII_VALUES = 128;
  private static final int UNICODE_VALUES = Character.MAX_CODE_POINT + 1;
  private static final int OUTSIDE_DOMAIN_CASES = 4;

  @Test
  void classifiesTheCodePointDomainAndOutOfRangeValuesWithoutHistory()
      throws Exception {
    Program driver = driver(UNICODE_VALUES, true);
    var machine = VirtualMachine.withBinaryInput(driver, new byte[0],
        UNICODE_VALUES + OUTSIDE_DOMAIN_CASES);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    byte[] expected = new byte[UNICODE_VALUES + OUTSIDE_DOMAIN_CASES];
    for (int scalar = 0; scalar < UNICODE_VALUES; scalar++) expected[scalar] = kind(scalar);
    for (int index = UNICODE_VALUES; index < expected.length; index++) expected[index] = 3;
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(0, machine.historySize());
  }

  @Test
  void keepsAsciiOffTheUnicodePathAndReplaysCompleteMachineState() throws Exception {
    Program driver = driver(ASCII_VALUES, false);
    var machine = VirtualMachine.withBinaryInput(driver, new byte[0], ASCII_VALUES);
    var initial = machine.snapshot();
    while (machine.status() != MachineStatus.HALTED) {
      for (var frame : machine.snapshot().selectedFrames()) {
        assertNotEquals("wheeler.lexer.scanner::unicodeWhitespace",
            driver.functions().get(frame.functionId()).name());
      }
      machine.step();
    }
    byte[] expected = new byte[ASCII_VALUES];
    for (int scalar = 0; scalar < ASCII_VALUES; scalar++) expected[scalar] = kind(scalar);
    assertArrayEquals(expected, machine.hostOutput());
    var completed = machine.snapshot();
    assertEquals(initial.buffers().size(), completed.buffers().size());
    assertEquals(initial.regions(), completed.regions());
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(initial, machine.snapshot());
    machine.run();
    assertEquals(completed, machine.snapshot());
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(initial, machine.snapshot());
  }

  private static byte kind(int scalar) {
    if (Character.isWhitespace(scalar)) return 0;
    if (scalar >= '0' && scalar <= '9') return 2;
    if ((scalar >= 'A' && scalar <= 'Z') || (scalar >= 'a' && scalar <= 'z') || scalar == '_') return 1;
    return 3;
  }

  private static Program driver(int count, boolean outsideDomain) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.lexer.scanner"));
    sources.put("Classification.w", """
        module example.scanner_classification;
        import wheeler.lexer.scanner;
        classical class Classification {
          private const long VALUES = %d;
          entry void main(borrow byteview input, borrow mut bytes output) {
            long scalar = 0;
            while (scalar < VALUES) limit VALUES {
              setByte(output, scalar, tokenKind(scalar));
              scalar += 1;
            }
            %s
          }
        }
        """.formatted(count, outsideDomain ? """
            setByte(output, VALUES, tokenKind(-1));
            setByte(output, VALUES + 1, tokenKind(VALUES));
            setByte(output, VALUES + 2, tokenKind(-9223372036854775808));
            setByte(output, VALUES + 3, tokenKind(9223372036854775807));
            """ : ""));
    return new WheelerCompiler().compileModuleFiles(sources, "example.scanner_classification");
  }
}
