package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Constant name presence does not evaluate a value or replace prefix admission. */
final class NativeCompilerClassConstantNamesExampleTest {
  private static final String OWNER = "wheeler.compiler.class_constants";
  private static final String LOOKUP = """
      if (classConstantNameExists(source, starts, lengths, count - 1)) {
        present = 1;
      }
      """;

  @Test
  void separatesPresenceFromTypeInitializerAndDuplicateAdmissionAndRewinds() throws Exception {
    Program program = NativeSourceFrontFixture.program(
        List.of(OWNER, "wheeler.compiler.constant_declarations"), 128, """
        state long present = 0;
        state long typed = 0;
        state long prefixValid = 0;
        """, LOOKUP + """
        ConstantResolution signed = resolveClassConstant(source, starts, lengths, count - 1, true);
        ConstantResolution bool = resolveClassConstant(source, starts, lengths, count - 1, false);
        assert(signed.found == bool.found);
        if (signed.found) { assert(present == 1); } else { assert(present == 0); }
        if (signed.valid) { typed += 1; }
        if (bool.valid) { typed += 2; }
        long first = firstConstantDeclaration(source, starts, lengths);
        long end = classMemberStart(source, kinds, starts, lengths, first, count);
        if (-1 < end) { prefixValid = 1; }
        """);
    for (Probe probe : List.of(
        new Probe("", "VALUE", 0, 0, 1),
        new Probe("const long VALUE = 17;", "VALUE", 1, 1, 1),
        new Probe("const boolean READY = true;", "READY", 1, 2, 1),
        new Probe("public const long public = 17; private const boolean FLAG = false;",
            "public", 1, 1, 1),
        new Probe("const long VALUE = NEXT; const long NEXT = 17;", "VALUE", 1, 1, 1),
        new Probe("const long VALUE = MISSING;", "VALUE", 1, 0, 0),
        new Probe("const long VALUE = VALUE;", "VALUE", 1, 0, 0),
        new Probe("const long VALUE = true;", "VALUE", 1, 0, 0),
        new Probe("const long VALUE = 17; const boolean VALUE = true;", "VALUE", 1, 1, 0),
        new Probe("const long VALUE = 17; const utf8 BAD = 42;", "VALUE", 0, 0, 0),
        new Probe("const long VALUE = 17; const long BAD = ;", "VALUE", 0, 0, 0),
        new Probe("const long VALUE = 17; const long BAD = 1);", "VALUE", 0, 0, 0),
        new Probe("state long observed = -3; const long VALUE = 17;", "VALUE", 1, 1, 1),
        new Probe("const long VALUE = 17; state long observed = VALUE;", "VALUE", 1, 1, 1),
        new Probe("const long VALUE = 17;", "VALUF", 0, 0, 1),
        new Probe("const long " + "N".repeat(256) + " = 17;", "N".repeat(256), 1, 1, 1))) {
      NativeSourceFrontFixture.check(program, source(probe.declarations(), probe.name()), machine -> {
        assertEquals(probe.present(), machine.global("present"), probe.toString());
        assertEquals(probe.typed(), machine.global("typed"), probe.toString());
        assertEquals(probe.prefixValid(), machine.global("prefixValid"), probe.toString());
      });
    }
  }

  @Test
  void performsRepeatedPresentAndAbsentLookupsWithoutPrivateAllocations() throws Exception {
    Program program = lookupProgram(128, """
        long repetition = 0;
        while (repetition < 16) limit 16 {
          %s
          repetition += 1;
        }
        """.formatted(LOOKUP));
    String declarations = "const long VALUE = NEXT; const long NEXT = MISSING;";
    for (String name : List.of("VALUE", "NEXT", "ABSENT")) {
      NativeSourceFrontFixture.check(program, source(declarations, name), machine -> {
        assertEquals(name.equals("ABSENT") ? 0 : 1, machine.global("present"));
        assertEquals(7, machine.snapshot().buffers().size());
      });
    }
  }

  @Test
  void boundsNameOnlyWorkWithoutEvaluatingAForwardDependencyChain() throws Exception {
    Program program = lookupProgram(1024, """
        long repetition = 0;
        while (repetition < 16) limit 16 {
          %s
          repetition += 1;
        }
        """.formatted(LOOKUP));
    var declarations = new StringBuilder();
    for (int constant = 0; constant < 64; constant++) {
      declarations.append("const long N").append(constant).append(" = ")
          .append(constant == 63 ? "1" : "N" + (constant + 1)).append(';');
    }
    var machine = new VirtualMachine(program,
        source(declarations.toString(), "N0").getBytes(StandardCharsets.UTF_8));
    for (int transition = 0; transition < 4_000_000; transition++) {
      if (machine.status() == MachineStatus.HALTED) {
        break;
      }
      machine.stepWithoutRewindHistory();
    }
    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(1, machine.global("present"));
    assertEquals(7, machine.snapshot().buffers().size());
  }

  @Test
  void checksTheCompletePrefixBeforeAcceptingFirstOrLastNamesAtTheCountBoundary()
      throws Exception {
    Program program = lookupProgram(4096, LOOKUP);
    var declarations = new StringBuilder();
    for (int constant = 0; constant < 256; constant++) {
      declarations.append("const long N").append(constant).append(" = ").append(constant).append(';');
    }
    for (String name : List.of("N0", "N255", "ABSENT")) {
      checkWithoutHistory(program, declarations.toString(), name, name.equals("ABSENT") ? 0 : 1);
      checkWithoutHistory(program, declarations + "const long EXCESS = 256;", name, 0);
    }
    for (String suffix : List.of("const long BAD =", "const long BAD = (1;")) {
      checkWithoutHistory(program, "const long N0 = 1;" + suffix, "N0", 0);
    }
  }

  @Test
  void keepsTheNameComparisonLimitAndRewindsARejectedExcessName() throws Exception {
    Program program = lookupProgram(128, LOOKUP);
    String name = "N".repeat(257);
    var machine = new VirtualMachine(program,
        source("const long " + name + " = 17;", name).getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("present"));
    var buffers = machine.snapshot().buffers();
    assertEquals(7, buffers.size());
    for (int column = 1; column < 4; column++) {
      assertEquals(buffers.get(column + 3).elements(), buffers.get(column).elements());
    }
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private record Probe(String declarations, String name, int present, int typed, int prefixValid) {}

  private static Program lookupProgram(int capacity, String body) throws Exception {
    return NativeSourceFrontFixture.program(List.of(OWNER), capacity, "state long present = 0;", body);
  }

  private static String source(String declarations, String name) {
    return "// café 𝄞\nclassical class Subject { " + declarations
        + " entry void main() {} } " + name;
  }

  private static void checkWithoutHistory(Program program, String declarations, String name,
      int expected) {
    var machine = new VirtualMachine(program,
        source(declarations, name).getBytes(StandardCharsets.UTF_8));
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertEquals(expected, machine.global("present"), declarations + "\n" + name);
    assertEquals(7, machine.snapshot().buffers().size());
  }
}
