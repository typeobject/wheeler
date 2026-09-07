package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Qualification products consume complete scanner names rather than source substrings. */
final class NativeCompilerModuleQualificationsExampleTest {
  private record Use(String text, long matches, long privateUses) {}

  @Test
  void matchesCompleteNamesWithoutReadingTriviaOrChangingColumnsAndRewinds() throws Exception {
    Program program = program(18, 19, 4, "");
    for (Use use : List.of(
        new Use("examples.constants::BASE", 1, 1),
        new Use("examples.constants::OTHER", 1, 0),
        new Use("examples.constants::BASEmore", 1, 0),
        new Use("examples.constants::public", 1, 0),
        new Use("myexamples.constants::BASE", 0, 0),
        new Use("other.examples.constants::BASE", 0, 0),
        new Use("examples.constants.more::BASE", 0, 0),
        new Use("examples.constants::", 0, 0),
        new Use("// examples.constants::BASE\n", 0, 0),
        new Use("writeAscii(out, 0, \"examples.constants::BASE\");", 0, 0),
        new Use("examples.constants:: /* gap */ BASE", 1, 1))) {
      NativeSourceFrontFixture.check(program, "examples.constants BASE " + use.text(), machine -> {
        assertEquals(MachineStatus.HALTED, machine.status());
        assertEquals(use.matches(), machine.global("matched"), use.text());
        assertEquals(use.privateUses(), machine.global("privateUses"), use.text());
        assertEquals(7, machine.snapshot().buffers().size());
      });
    }
  }

  @Test
  void keepsNameAndQualificationLimitsIndependentOfTriviaAndRewinds() throws Exception {
    String module = "M".repeat(256);
    String name = "N".repeat(256);
    NativeSourceFrontFixture.check(program(256, 257, 256, ""),
        module + " " + name + " " + module + "::" + name, machine -> {
          assertEquals(1, machine.global("matched"));
          assertEquals(1, machine.global("privateUses"));
          assertEquals(7, machine.snapshot().buffers().size());
        });
    String segmented = "a.".repeat(31) + "a";
    NativeSourceFrontFixture.check(program(segmented.length(), segmented.length() + 1, 4, ""),
        segmented + " BASE " + segmented + "::BASE", machine -> {
          assertEquals(1, machine.global("matched"));
          assertEquals(1, machine.global("privateUses"));
        });
    Program program = program(18, 19, 4, "");
    String trivia = "// examples.constants::BASE\n".repeat(70);
    for (int references : new int[] {64, 65}) {
      NativeSourceFrontFixture.check(program,
          "examples.constants BASE " + trivia + "examples.constants::BASE;".repeat(references), machine -> {
            assertEquals(references == 64 ? 64 : -1, machine.global("matched"));
            assertEquals(references == 64 ? 1 : 92, machine.global("privateUses"));
            assertEquals(7, machine.snapshot().buffers().size());
          });
    }
  }

  @Test
  void rejectsInvalidCoordinatesCountsAndShortColumnsBeforeReads() throws Exception {
    Program program = program(18, 19, 4, """
        assert(qualificationCount(source, 0, 18, source, kinds, starts, lengths, 0) == 0);
        assert(qualificationCount(source, 0, 18, source, kinds, starts, lengths, -1) == -1);
        assert(qualificationCount(source, 0, 18, source, kinds, starts, lengths, -9223372036854775808) == -1);
        assert(qualificationCount(source, 0, 18, source, kinds, starts, lengths, 4097) == -1);
        assert(qualificationCount(source, 0, 18, source, kinds, starts, lengths, 9223372036854775807) == -1);
        assert(qualificationCount(source, -1, 18, source, kinds, starts, lengths, count) == -1);
        assert(qualificationCount(source, -9223372036854775808, 18, source, kinds, starts, lengths, count) == -1);
        assert(qualificationCount(source, 9223372036854775807, 18, source, kinds, starts, lengths, count) == -1);
        assert(qualificationCount(source, 0, 0, source, kinds, starts, lengths, count) == -1);
        assert(qualificationCount(source, 0, -1, source, kinds, starts, lengths, count) == -1);
        assert(qualificationCount(source, 0, 257, source, kinds, starts, lengths, count) == -1);
        assert(qualificationCount(source, 0, 9223372036854775807, source, kinds, starts, lengths, count) == -1);
        ImportedQualification moduleName = new ImportedQualification(0, 18, 0);
        QualifiedNameSpan excess = new QualifiedNameSpan(24, 257);
        assert(qualifiedPrivateNameUsed(source, moduleName, excess, source, kinds, starts, lengths, count));
        QualifiedNameSpan missing = new QualifiedNameSpan(9223372036854775807, 4);
        assert(qualifiedPrivateNameUsed(source, moduleName, missing, source, kinds, starts, lengths, count));
        QualifiedNameSpan negative = new QualifiedNameSpan(-9223372036854775808, 4);
        assert(qualifiedPrivateNameUsed(source, moduleName, negative, source, kinds, starts, lengths, count));
        region shortArena = new region(8, 1);
        words shortRows = allocate(shortArena, 1);
        set(shortRows, 0, 73);
        assert(qualificationCount(source, 0, 18, source, shortRows, starts, lengths, count) == -1);
        assert(qualificationCount(source, 0, 18, source, kinds, shortRows, lengths, count) == -1);
        assert(qualificationCount(source, 0, 18, source, kinds, starts, shortRows, count) == -1);
        assert(shortRows[0] == 73);
        drop(shortRows);
        drop(shortArena);
        """);
    NativeSourceFrontFixture.check(program, "examples.constants BASE " + "Z".repeat(257), machine -> {
      assertEquals(MachineStatus.HALTED, machine.status());
      assertEquals(0, machine.global("matched"));
      assertEquals(0, machine.global("privateUses"));
      assertEquals(8, machine.snapshot().buffers().size());
    });
  }

  private static Program program(int moduleLength, int nameStart, int nameLength, String extra)
      throws Exception {
    return NativeSourceFrontFixture.program(List.of("wheeler.compiler.module_qualifications"), 4097,
        "state long matched = 91; state long privateUses = 92;", """
        long found = qualificationCount(source, 0, %d, source, kinds, starts, lengths, count);
        matched = found;
        if (-1 < found) {
          ImportedQualification admitted = new ImportedQualification(0, %d, found);
          QualifiedNameSpan nameSpan = new QualifiedNameSpan(%d, %d);
          boolean used = qualifiedPrivateNameUsed(source, admitted, nameSpan,
              source, kinds, starts, lengths, count);
          privateUses = 0;
          if (used) {
            privateUses = 1;
          }
        }
        %s
        """.formatted(moduleLength, moduleLength, nameStart, nameLength, extra));
  }
}
