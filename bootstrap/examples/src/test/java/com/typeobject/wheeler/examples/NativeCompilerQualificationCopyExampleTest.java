package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferKind;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Private qualification copies retain exact windows without claiming atomic staging writes. */
final class NativeCompilerQualificationCopyExampleTest {
  private static final String SOURCE = "examples.constants BASE; "
      + "state long value = examples.constants::BASE; "
      + "entry void main() { writeAscii(out, 0, \"examples.constants::BASE\"); }";
  private static final String EXPECTED = "examples.constants BASE; "
      + "state long value = BASE; "
      + "entry void main() { writeAscii(out, 0, \"examples.constants::BASE\"); }";

  @Test
  void copiesWholeAndDisjointWindowsIntoNonzeroDestinationsAndRewinds() throws Exception {
    int state = SOURCE.indexOf("state long");
    int entry = SOURCE.indexOf("entry void");
    for (String operation : List.of(copy("0", "bufferLength(source)", "4", "count"),
        copy("0", Integer.toString(state), "4", "count")
            + copy(Integer.toString(state), Integer.toString(entry - state), "written", "count")
            + copy(Integer.toString(entry), "bufferLength(source) - " + entry, "written", "count"))) {
      VirtualMachine machine = machine(program(operation), SOURCE, 256);
      var initial = machine.snapshot();
      machine.run();
      assertEquals(MachineStatus.HALTED, machine.status());
      assertEquals(1, machine.global("published"));
      assertEquals(1, machine.global("matched"));
      assertEquals(4 + EXPECTED.length(), machine.global("cursor"));
      byte[] expected = sentinels(256);
      System.arraycopy(EXPECTED.getBytes(StandardCharsets.UTF_8), 0, expected, 4, EXPECTED.length());
      assertArrayEquals(expected, machine.hostOutput());
      assertEquals(initial.buffers().size() + 6, machine.snapshot().buffers().size());
      rewind(machine);
      assertEquals(initial, machine.snapshot());
    }
  }

  @Test
  void rejectsInvalidWindowsBeforeChangingPrivateStagingAndRewinds() throws Exception {
    String beyond = Integer.toString(SOURCE.length() + 1);
    for (String[] window : List.of(
        new String[] {"-1", "1", "0", "count"},
        new String[] {"-9223372036854775808", "1", "0", "count"},
        new String[] {"9223372036854775807", "1", "0", "count"},
        new String[] {"0", "-1", "0", "count"},
        new String[] {"0", "-9223372036854775808", "0", "count"},
        new String[] {"0", "9223372036854775807", "0", "count"},
        new String[] {"0", beyond, "0", "count"},
        new String[] {beyond, "0", "0", "count"},
        new String[] {"0", "1", "-1", "count"},
        new String[] {"0", "1", "9223372036854775807", "count"},
        new String[] {"0", "1", "257", "count"},
        new String[] {"0", "1", "0", "-1"},
        new String[] {"0", "1", "0", "4097"},
        new String[] {"0", "1", "0", "9223372036854775807"})) {
      VirtualMachine machine = machine(program(copy(window[0], window[1], window[2], window[3])),
          SOURCE, 256);
      var initial = machine.snapshot();
      machine.run();
      assertEquals(MachineStatus.HALTED, machine.status());
      assertEquals(-1, machine.global("cursor"));
      assertEquals(0, machine.global("published"));
      assertArrayEquals(sentinels(256), machine.hostOutput());
      assertEquals(initial.buffers().size() + 6, machine.snapshot().buffers().size());
      rewind(machine);
      assertEquals(initial, machine.snapshot());
    }
    VirtualMachine empty = machine(program(copy("bufferLength(source)", "0", "256", "count")), SOURCE, 256);
    var initial = empty.snapshot();
    empty.run();
    assertEquals(256, empty.global("cursor"));
    assertArrayEquals(sentinels(256), empty.hostOutput());
    rewind(empty);
    assertEquals(initial, empty.snapshot());
  }

  @Test
  void rewindsPartialPrivateCopiesAfterCapacityAndSplitQualificationRejection() throws Exception {
    VirtualMachine shortOutput = machine(program(copy("0", "bufferLength(source)", "0", "count")),
        SOURCE, EXPECTED.length() - 1);
    var initial = shortOutput.snapshot();
    assertThrows(VmTrap.class, shortOutput::run);
    assertEquals(0, shortOutput.global("published"));
    assertEquals(92, shortOutput.global("cursor"));
    assertArrayEquals(EXPECTED.substring(0, EXPECTED.length() - 1).getBytes(StandardCharsets.UTF_8),
        shortOutput.hostOutput());
    List<BufferValue> columns = shortOutput.snapshot().buffers().stream()
        .filter(buffer -> buffer.kind() == BufferKind.WORDS && !buffer.dropped())
        .sorted(Comparator.comparingInt(BufferValue::id)).toList();
    assertEquals(6, columns.size());
    for (int column = 0; column < 3; column++) {
      assertEquals(columns.get(column).elements(), columns.get(column + 3).elements());
    }
    rewind(shortOutput);
    assertEquals(initial, shortOutput.snapshot());

    int qualification = SOURCE.indexOf("examples.constants::BASE");
    VirtualMachine split = machine(program(copy("0", Integer.toString(qualification + 5), "0", "count")),
        SOURCE, 256);
    initial = split.snapshot();
    split.run();
    assertEquals(-1, split.global("cursor"));
    assertEquals(0, split.global("published"));
    byte[] expected = sentinels(256);
    System.arraycopy(SOURCE.getBytes(StandardCharsets.UTF_8), 0, expected, 0, qualification);
    assertArrayEquals(expected, split.hostOutput());
    rewind(split);
    assertEquals(initial, split.snapshot());
  }

  @Test
  void keepsTheCompleteLinkedByteWindowAndRejectsTheNextByte() throws Exception {
    Program program = program(copy("0", "bufferLength(source)", "0", "count"));
    for (int length : new int[] {36_864, 36_865}) {
      String prefix = "examples.constants BASE //";
      String source = prefix + "x".repeat(length - prefix.length());
      VirtualMachine machine = machine(program, source, 36_864);
      int buffers = machine.snapshot().buffers().size();
      for (int step = 0; step < 8_000_000 && machine.status() != MachineStatus.HALTED; step++) {
        machine.stepWithoutRewindHistory();
      }
      assertEquals(MachineStatus.HALTED, machine.status());
      assertEquals(buffers + 6, machine.snapshot().buffers().size());
      assertEquals(length == 36_864 ? 1 : 0, machine.global("published"));
      assertEquals(length == 36_864 ? 0 : -1, machine.global("matched"));
      assertEquals(length == 36_864 ? 36_864 : -1, machine.global("cursor"));
      assertArrayEquals(length == 36_864 ? source.getBytes(StandardCharsets.UTF_8) : sentinels(36_864),
          machine.hostOutput());
    }
  }

  private static String copy(String first, String length, String destination, String count) {
    return "written = copyLinkedRootAscii(source, moduleName, source, kinds, starts, lengths, "
        + "new QualifiedRootWindow(" + first + ", " + length + ", " + destination + ", " + count
        + "), output);\n";
  }

  private static Program program(String operation) throws Exception {
    return NativeSourceFrontFixture.program(List.of("wheeler.compiler.module_qualifications"), 4096,
        "state long matched = 91; state long cursor = 92; state long published = 0;", """
        long filled = 0;
        while (filled < bufferLength(output)) limit 36864 {
          setByte(output, filled, 73);
          filled += 1;
        }
        long found = qualificationCount(source, 0, 18, source, kinds, starts, lengths, count);
        matched = found;
        ImportedQualification moduleName = new ImportedQualification(0, 18, found);
        long written = 0;
        %s
        cursor = written;
        if (-1 < written) {
          published = 1;
        }
        """.formatted(operation), true);
  }

  private static VirtualMachine machine(Program program, String source, int capacity) {
    return new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8), capacity);
  }

  private static byte[] sentinels(int length) {
    byte[] result = new byte[length];
    Arrays.fill(result, (byte) 73);
    return result;
  }

  private static void rewind(VirtualMachine machine) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
  }
}
