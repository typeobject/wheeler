package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Prelude coordinates separate syntax location from constant and state value admission. */
final class NativeCompilerClassPreludeExampleTest {
  private record Envelope(String source, long constantStart, long constantEnd,
      long memberStart, long stateStart, long stateEnd) {}

  @Test
  void locatesBothOrdersWithoutBindingValuesOrChangingColumnsAndRewinds() throws Exception {
    for (int header : new int[] {0, 10}) {
      Program program = preludeProgram(Integer.toString(4 + header), "count", "");
      for (Envelope envelope : List.of(
          new Envelope("", 4, 4, 4, -1, -1),
          new Envelope("const long BASE = 7;", 4, 10, 10, -1, -1),
          new Envelope("state long value = 0;", 10, 10, 10, 4, 10),
          new Envelope("state long value = -9223372036854775808;", 11, 11, 11, 4, 11),
          new Envelope("const long BASE = 7; state long value = BASE;", 4, 10, 16, 10, 16),
          new Envelope("state long value = BASE; const long BASE = 7;", 10, 16, 16, 4, 10),
          new Envelope("public const boolean READY = true; state long value = imported.value::BASE;",
              4, 11, 22, 11, 22),
          new Envelope("state long value = imported.value::BASE; private const long BASE = 7;",
              15, 22, 22, 4, 15),
          new Envelope("const long VALUE = MISSING;", 4, 10, 10, -1, -1),
          new Envelope("const long SAME = 1; const boolean SAME = true;", 4, 16, 16, -1, -1),
          new Envelope("state long public = MISSING;", 10, 10, 10, 4, 10),
          new Envelope("state long value = 1 + 2;", 12, 12, 12, 4, 12),
          new Envelope("state long value = (BASE); const long BASE = 7;", 12, 18, 18, 4, 12))) {
        String source = source(envelope.source(), header);
        NativeSourceFrontFixture.check(program, source, machine -> assertEnvelope(machine,
            shifted(envelope.constantStart(), header), shifted(envelope.constantEnd(), header),
            shifted(envelope.memberStart(), header), shifted(envelope.stateStart(), header),
            shifted(envelope.stateEnd(), header)));
      }
    }
  }

  @Test
  void rejectsMalformedAndSplitEnvelopesWithoutPublishingCoordinatesAndRewinds() throws Exception {
    Program program = preludeProgram("4", "count", "");
    for (String prefix : List.of("state boolean value = true;", "state long 0 = 1;",
        "state long value 0;", "state long value = ;", "state long value = (0;",
        "state long value = 0);", "state long value = {0};", "state long value = 0",
        "state long value = 0; state long other = 1;",
        "state long value = 0; const long BASE = 1; state long other = 1;",
        "const long FIRST = 1; state long value = FIRST; const long SECOND = 2;",
        "const long FIRST = 1; state long value = FIRST; state long other = 2;",
        "const utf8 BAD = 1;", "const long BAD = ;", "const long BAD = {1};",
        "const long BASE = 7; const long BAD = (1;")) {
      NativeSourceFrontFixture.check(program, source(prefix, 0),
          NativeCompilerClassPreludeExampleTest::assertUnpublished);
    }
  }

  @Test
  void preservesNameParenthesisAndConstantCountLimits() throws Exception {
    Program program = preludeProgram("4", "count", "");
    NativeSourceFrontFixture.check(program, source("state long " + "N".repeat(256) + " = 0;", 0),
        machine -> assertEnvelope(machine, 10, 10, 10, 4, 10));
    NativeSourceFrontFixture.check(program, source("state long " + "N".repeat(257) + " = 0;", 0),
        NativeCompilerClassPreludeExampleTest::assertUnpublished);
    NativeSourceFrontFixture.check(program,
        source("state long value = " + "(".repeat(32) + "0" + ")".repeat(32) + ";", 0),
        machine -> assertEnvelope(machine, 74, 74, 74, 4, 74));
    NativeSourceFrontFixture.check(program,
        source("state long value = " + "(".repeat(33) + "0" + ")".repeat(33) + ";", 0),
        NativeCompilerClassPreludeExampleTest::assertUnpublished);

    String constants = constants(256);
    assertEnvelope(run(program, source(constants, 0)), 4, 1540, 1540, -1, -1);
    assertEnvelope(run(program, source("state long value = 0;" + constants, 0)),
        10, 1546, 1546, 4, 10);
    assertEnvelope(run(program, source(constants + "state long value = 0;", 0)),
        4, 1540, 1546, 1540, 1546);
    for (String prefix : List.of(constants(257), "state long value = 0;" + constants(257),
        constants(257) + "state long value = 0;")) {
      assertUnpublished(run(program, source(prefix, 0)));
    }
  }

  @Test
  void checksAllPreludeWindowsAndShortColumnsBeforeReads() throws Exception {
    Program program = preludeProgram("4", "count", """
        assert(resolveClassPrelude(source, kinds, starts, lengths, -1, count).valid == false);
        assert(resolveClassPrelude(source, kinds, starts, lengths, -9223372036854775808, count).valid == false);
        assert(resolveClassPrelude(source, kinds, starts, lengths, 9223372036854775807, count).valid == false);
        assert(resolveClassPrelude(source, kinds, starts, lengths, count, count).valid == false);
        assert(resolveClassPrelude(source, kinds, starts, lengths, 4, -9223372036854775808).valid == false);
        assert(resolveClassPrelude(source, kinds, starts, lengths, 4, -1).valid == false);
        assert(resolveClassPrelude(source, kinds, starts, lengths, 4, 0).valid == false);
        assert(resolveClassPrelude(source, kinds, starts, lengths, 4, 4).valid == false);
        assert(resolveClassPrelude(source, kinds, starts, lengths, 4, 4097).valid == false);
        assert(resolveClassPrelude(source, kinds, starts, lengths, 4, 9223372036854775807).valid == false);
        region shortArena = new region(32760, 1);
        words shortRows = allocate(shortArena, 4095);
        set(shortRows, 0, 71);
        set(shortRows, 4094, 73);
        assert(resolveClassPrelude(source, shortRows, starts, lengths, 4, count).valid == false);
        assert(resolveClassPrelude(source, kinds, shortRows, lengths, 4, count).valid == false);
        assert(resolveClassPrelude(source, kinds, starts, shortRows, 4, count).valid == false);
        assert(shortRows[0] == 71);
        assert(shortRows[4094] == 73);
        drop(shortRows);
        drop(shortArena);
        """);
    NativeSourceFrontFixture.check(program, source("state long value = 0;", 0), machine -> {
      assertEquals(MachineStatus.HALTED, machine.status());
      assertEquals(1, machine.global("published"));
      assertEquals(8, machine.snapshot().buffers().size());
    });
  }

  @Test
  void admitsTheFullTokenWindowAndRejectsExcessWithSpareColumnStorage() throws Exception {
    String source = "classical class Subject { state long value = 0; entry void main() { "
        + "assert(true);".repeat(812) + "assert(!false);".repeat(3) + " } }";
    new WheelerCompiler().compileToBytecode(source);
    Program program = NativeSourceFrontFixture.program(List.of("wheeler.compiler.class_layouts"),
        4097, "state long checked = 0;", """
        assert(count == 4096);
        ClassPrelude prelude = resolveClassPrelude(source, kinds, starts, lengths, 4, count);
        assert(prelude.valid);
        assert(prelude.constantStart == 10);
        assert(prelude.constantEnd == 10);
        assert(prelude.memberStart == 10);
        assert(prelude.stateStart == 4);
        assert(prelude.stateEnd == 10);
        assert(resolveClassPrelude(source, kinds, starts, lengths, 4, count + 1).valid == false);
        checked = 1;
        """);
    VirtualMachine machine = run(program, source);
    assertEquals(1, machine.global("checked"));
    assertEquals(7, machine.snapshot().buffers().size());
  }

  @Test
  void keepsTheCountedPrefixApiIndependentOfFullPreludeColumns() throws Exception {
    Program program = NativeSourceFrontFixture.program(List.of("wheeler.compiler.constant_declarations"),
        16, "state long checked = 0;", """
        assert(constantPrefixEnd(source, starts, lengths, 0, 0) == 0);
        assert(constantPrefixEnd(source, starts, lengths, 0, 1) == 0);
        assert(constantPrefixEnd(source, starts, lengths, 0, 2) == -1);
        assert(constantPrefixEnd(source, starts, lengths, 0, 7) == 7);
        assert(constantPrefixEnd(source, starts, lengths, 0, count) == 7);
        assert(constantPrefixEnd(source, starts, lengths, count, count) == count);
        assert(constantPrefixEnd(source, starts, lengths, -1, count) == -1);
        assert(constantPrefixEnd(source, starts, lengths, -9223372036854775808, count) == -1);
        assert(constantPrefixEnd(source, starts, lengths, 9223372036854775807, count) == -1);
        assert(constantPrefixEnd(source, starts, lengths, 0, -9223372036854775808) == -1);
        assert(constantPrefixEnd(source, starts, lengths, 0, 9223372036854775807) == -1);
        assert(constantPrefixEnd(source, starts, lengths, 0, 4097) == -1);
        assert(constantPrefixEnd(source, starts, lengths, 0, 17) == -1);
        region shortArena = new region(48, 1);
        words shortRows = allocate(shortArena, 6);
        assert(constantPrefixEnd(source, shortRows, lengths, 0, 7) == -1);
        assert(constantPrefixEnd(source, starts, shortRows, 0, 7) == -1);
        drop(shortRows);
        drop(shortArena);
        checked = 1;
        """);
    NativeSourceFrontFixture.check(program, "public const long VALUE = 7; entry", machine -> {
      assertEquals(MachineStatus.HALTED, machine.status());
      assertEquals(1, machine.global("checked"));
      assertEquals(8, machine.snapshot().buffers().size());
    });
  }

  private static Program preludeProgram(String first, String count, String extra) throws Exception {
    return NativeSourceFrontFixture.program(List.of("wheeler.compiler.class_layouts"), 4096, """
        state long constantStart = 91;
        state long constantEnd = 92;
        state long memberStart = 93;
        state long stateStart = 94;
        state long stateEnd = 95;
        state long published = 0;
        """, """
        ClassPrelude prelude = resolveClassPrelude(source, kinds, starts, lengths, %s, %s);
        if (prelude.valid) {
          constantStart = prelude.constantStart;
          constantEnd = prelude.constantEnd;
          memberStart = prelude.memberStart;
          stateStart = prelude.stateStart;
          stateEnd = prelude.stateEnd;
          published = 1;
        }
        %s
        """.formatted(first, count, extra));
  }

  private static long shifted(long coordinate, int header) {
    return coordinate < 0 ? coordinate : coordinate + header;
  }

  private static String source(String prefix, int header) {
    return "// café 𝄞\n" + (header == 0 ? "" : "module demo.root; import demo.dep; ")
        + "classical class Subject { " + prefix + " entry void main() {} }";
  }

  private static String constants(int count) {
    var text = new StringBuilder();
    for (int index = 0; index < count; index++) {
      text.append("const long N").append(index).append(" = ").append(index).append(';');
    }
    return text.toString();
  }

  private static VirtualMachine run(Program program, String source) {
    var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
    for (int step = 0; step < 20_000_000 && machine.status() != MachineStatus.HALTED; step++) {
      machine.stepWithoutRewindHistory();
    }
    assertEquals(MachineStatus.HALTED, machine.status());
    return machine;
  }

  private static void assertEnvelope(VirtualMachine machine, long constantStart, long constantEnd,
      long memberStart, long stateStart, long stateEnd) {
    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(1, machine.global("published"));
    assertEquals(constantStart, machine.global("constantStart"));
    assertEquals(constantEnd, machine.global("constantEnd"));
    assertEquals(memberStart, machine.global("memberStart"));
    assertEquals(stateStart, machine.global("stateStart"));
    assertEquals(stateEnd, machine.global("stateEnd"));
    assertEquals(7, machine.snapshot().buffers().size());
  }

  private static void assertUnpublished(VirtualMachine machine) {
    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(0, machine.global("published"));
    assertEquals(91, machine.global("constantStart"));
    assertEquals(92, machine.global("constantEnd"));
    assertEquals(93, machine.global("memberStart"));
    assertEquals(94, machine.global("stateStart"));
    assertEquals(95, machine.global("stateEnd"));
    assertEquals(7, machine.snapshot().buffers().size());
  }
}
