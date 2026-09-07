package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Private name coordinates replace repeated declaration walks during admission. */
final class NativeCompilerConstantAdmissionExampleTest {
  @Test
  void admitsDistinctNamesAndRejectsDuplicatesAcrossTypesAndVisibilityAndRewinds() throws Exception {
    Program program = program();
    for (String declarations : List.of("",
        "const long VALUE = 7;",
        "public const long public = 7; private const boolean READY = true;",
        "const long VALUE = 7; const long VALUF = 8; const long value = 9;",
        "const long VALUE = NEXT; const boolean READY = VALUE == 7; const long NEXT = 7;",
        "const long " + "N".repeat(256) + " = 7;")) {
      String source = source(declarations);
      assertDoesNotThrow(() -> new WheelerCompiler().compileToBytecode(source));
      NativeSourceFrontFixture.check(program, source, machine -> {
        assertEquals(1, machine.global("published"));
        if (declarations.isEmpty()) {
          assertEquals(7, machine.snapshot().buffers().size());
        }
        if (declarations.equals("const long VALUE = 7;")) {
          assertTrue(machine.snapshot().buffers().size() <= 11);
        }
      });
    }
    for (String declarations : List.of(
        "const long VALUE = 7; const long VALUE = 8;",
        "const long VALUE = 7; const boolean VALUE = true;",
        "private const long VALUE = 7; const long OTHER = 8; public const long VALUE = 9;",
        "public const long public = 7; private const long public = 8;",
        "const long VALUE = 7; const utf8 BAD = 8;",
        "const long VALUE = 7; const long BAD = ;",
        "const long VALUE = 7; const long BAD = MISSING;",
        "const long VALUE = NEXT; const long NEXT = VALUE;",
        "const long VALUE = true;")) {
      String source = source(declarations);
      assertThrows(CompilerException.class,
          () -> new WheelerCompiler().compileToBytecode(source), source);
      NativeSourceFrontFixture.check(program, source, machine -> {
        assertEquals(0, machine.global("published"));
        assertEquals(91, machine.global("member"));
      });
    }
  }

  @Test
  void keepsTheLastNameAndRejectsExcessAndLateDuplicatesWithoutPublication() throws Exception {
    Program program = program();
    String declarations = declarations(256);
    String admitted = source(declarations);
    assertDoesNotThrow(() -> new WheelerCompiler().compileToBytecode(admitted));
    VirtualMachine accepted = run(program, admitted);
    assertEquals(1, accepted.global("published"));
    assertTrue(accepted.snapshot().buffers().size() <= 8 + 3 * 256);

    String excessName = source("const long " + "N".repeat(257) + " = 7;");
    assertDoesNotThrow(() -> new WheelerCompiler().compileToBytecode(excessName));
    NativeSourceFrontFixture.check(program, excessName, machine -> {
      assertEquals(0, machine.global("published"));
      assertEquals(91, machine.global("member"));
    });

    String excess = source(declarations + "const long EXCESS = 256;");
    assertDoesNotThrow(() -> new WheelerCompiler().compileToBytecode(excess));
    for (String rejected : List.of(excess,
        source(declarations(255) + "const long N0 = 255;"),
        source(declarations(255) + "private const boolean N254 = true;"))) {
      VirtualMachine machine = run(program, rejected);
      assertEquals(0, machine.global("published"));
      assertEquals(91, machine.global("member"));
      assertTrue(machine.snapshot().buffers().size() <= 8);
    }
  }

  private static Program program() throws Exception {
    return NativeSourceFrontFixture.program(List.of("wheeler.compiler.class_constants",
        "wheeler.compiler.compiler_token_limits"), 4096, """
        state long member = 91;
        state long published = 0;
        """, """
        assert(bufferLength(starts) == MAX_COMPILER_TOKENS);
        assert(bufferLength(lengths) == MAX_COMPILER_TOKENS);
        long result = classMemberStart(source, kinds, starts, lengths, 4, count);
        if (-1 < result) {
          assert(result == count - 8);
          member = result;
          published = 1;
        }
        """);
  }

  private static String source(String declarations) {
    return "// café 𝄞\nclassical class Subject { " + declarations + " entry void main() {} }";
  }

  private static String declarations(int count) {
    var source = new StringBuilder();
    for (int index = 0; index < count; index++) {
      source.append("const long N").append(index).append(" = ").append(index).append(';');
    }
    return source.toString();
  }

  private static VirtualMachine run(Program program, String source) {
    var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
    for (int transition = 0; transition < 140_000_000; transition++) {
      if (machine.status() == MachineStatus.HALTED) {
        break;
      }
      machine.stepWithoutRewindHistory();
    }
    assertEquals(MachineStatus.HALTED, machine.status());
    return machine;
  }
}
