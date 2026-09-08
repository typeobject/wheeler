package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.TreeSet;

/** Complete caller-storage and rewind checks for the counted string-section writer. */
final class NativeLinkedStringFixture {
  private static Program program;

  record Window(int row, long start, long length) {}

  static final class Input {
    byte[] archive;
    final List<Window> windows = new ArrayList<>();
    long count;
    long outputStart = 11;
    Long archiveBytes;
    int outputCapacity = 512;
    final int[] columns = {16384, 16384, 16384};
    int repeatCount;
    int repeatLength;

    Input(String... names) {
      count = names.length;
      int start = 72 + 24 * names.length;
      ByteArrayOutputStream bytes = new ByteArrayOutputStream();
      for (int row = 0; row < names.length; row++) {
        byte[] name = names[row].getBytes(StandardCharsets.ISO_8859_1);
        windows.add(new Window(row, start + bytes.size(), name.length));
        bytes.writeBytes(name);
      }
      archive = bytes.toByteArray();
    }

    Input repeated(int rows) {
      windows.clear();
      archive = new byte[] {'A'};
      count = rows;
      repeatCount = rows;
      repeatLength = 1;
      return this;
    }

    byte[] bytes() {
      int payload = 72 + 24 * windows.size();
      ByteBuffer out = ByteBuffer.allocate(payload + archive.length).order(ByteOrder.LITTLE_ENDIAN);
      out.putLong(count).putLong(outputStart)
          .putLong(archiveBytes == null ? out.capacity() : archiveBytes)
          .putLong(columns[0]).putLong(columns[1]).putLong(columns[2])
          .putLong(windows.size()).putLong(repeatCount).putLong(repeatLength);
      for (Window row : windows) {
        out.putLong(row.row()).putLong(row.start()).putLong(row.length());
      }
      return out.put(archive).array();
    }
  }

  private NativeLinkedStringFixture() {}

  static long accepts(Input input) throws Exception {
    return accepts(input, true);
  }

  static long acceptsWithoutRewind(Input input) throws Exception {
    return accepts(input, false);
  }

  private static long accepts(Input input, boolean retainHistory) throws Exception {
    VirtualMachine machine = machine(input);
    MachineSnapshot initial = machine.snapshot();
    while (machine.global("prepared") == 0) {
      step(machine, retainHistory);
    }
    MachineSnapshot before = machine.snapshot();
    List<BufferValue> rows = callerRows(before);
    byte[] source = input.bytes();
    List<String> names = new ArrayList<>();
    for (int row = 0; row < input.count; row++) {
      int start = Math.toIntExact(rows.get(0).elements().get(row));
      int length = Math.toIntExact(rows.get(1).elements().get(row));
      names.add(new String(source, start, length, StandardCharsets.ISO_8859_1));
    }
    List<String> sorted = List.copyOf(new TreeSet<>(names));
    int size = 4;
    for (String name : sorted) {
      size += 4 + name.length();
    }
    ByteBuffer section = ByteBuffer.allocate(size).order(ByteOrder.LITTLE_ENDIAN);
    section.putInt(sorted.size());
    for (String name : sorted) {
      section.putInt(name.length()).put(name.getBytes(StandardCharsets.ISO_8859_1));
    }
    byte[] expected = machine.hostOutput();
    System.arraycopy(section.array(), 0, expected, Math.toIntExact(input.outputStart), size);
    List<Long> mapping = new ArrayList<>(rows.get(2).elements());
    for (int row = 0; row < input.count; row++) {
      mapping.set(row, (long) sorted.indexOf(names.get(row)));
    }
    while (machine.global("published") == 0) {
      step(machine, retainHistory);
    }
    assertEquals(size, machine.global("sectionBytes"));
    assertArrayEquals(expected, machine.hostOutput());
    List<BufferValue> after = callerRows(machine.snapshot());
    assertEquals(rows.subList(0, 2), after.subList(0, 2));
    assertArrayEquals(mapping.stream().mapToLong(Long::longValue).toArray(),
        after.get(2).elements().stream().mapToLong(Long::longValue).toArray());
    run(machine, retainHistory);
    long steps = machine.snapshot().sequence();
    assertArrayEquals(expected, machine.hostOutput());
    checkHistory(machine, initial, retainHistory);
    return steps;
  }

  static void rejects(Input input) throws Exception {
    rejects(input, true);
  }

  static void rejectsWithoutRewind(Input input) throws Exception {
    rejects(input, false);
  }

  private static void rejects(Input input, boolean retainHistory) throws Exception {
    VirtualMachine machine = machine(input);
    MachineSnapshot initial = machine.snapshot();
    while (machine.global("prepared") == 0) {
      step(machine, retainHistory);
    }
    MachineSnapshot before = machine.snapshot();
    byte[] expected = machine.hostOutput();
    assertThrows(VmTrap.class, () -> run(machine, retainHistory));
    assertEquals(0, machine.global("published"));
    assertEquals(-1, machine.global("sectionBytes"));
    assertEquals(callerRows(before), callerRows(machine.snapshot()));
    assertEquals(before.regions().stream().filter(r -> r.maxBytes() == 400000).toList(),
        machine.snapshot().regions().stream().filter(r -> r.maxBytes() == 400000).toList());
    assertArrayEquals(expected, machine.hostOutput());
    checkHistory(machine, initial, retainHistory);
  }

  private static List<BufferValue> callerRows(MachineSnapshot snapshot) {
    int id = snapshot.regions().stream().filter(r -> r.maxBytes() == 400000)
        .findFirst().orElseThrow().id();
    return snapshot.buffers().stream().filter(b -> b.regionId() == id).toList();
  }

  private static void step(VirtualMachine machine, boolean retainHistory) {
    if (retainHistory) {
      machine.step();
    } else {
      machine.stepWithoutRewindHistory();
    }
  }

  private static void run(VirtualMachine machine, boolean retainHistory) {
    if (retainHistory) {
      machine.run();
    } else {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    }
  }

  private static void checkHistory(
      VirtualMachine machine, MachineSnapshot initial, boolean retainHistory) {
    if (retainHistory) {
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    } else {
      assertEquals(0, machine.historySize());
    }
  }

  private static VirtualMachine machine(Input input) throws Exception {
    return VirtualMachine.withBinaryInput(program(), input.bytes(), input.outputCapacity);
  }

  private static synchronized Program program() throws Exception {
    if (program != null) {
      return program;
    }
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_string_section"));
    CoreSources.addBinaryClosure(sources);
    sources.put("LinkedStrings.w", """
        module example.linked_strings;
        import wheeler.compiler.closure.linked_string_section;
        import wheeler.core.encoding.binary;
        classical class LinkedStrings {
          state long prepared = 0;
          state long published = 0;
          state long sectionBytes = -1;
          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 400000, /* allocations= */ 3);
            words starts = allocate(rows, readSigned(input, 24));
            words lengths = allocate(rows, readSigned(input, 32));
            words finalRows = allocate(rows, readSigned(input, 40));
            fill(starts, 17);
            fill(lengths, 19);
            fill(finalRows, 23);
            long entries = readSigned(input, 48);
            long archiveStart = 72 + entries * 24;
            long repeat = 0;
            long repeated = readSigned(input, 56);
            long repeatLength = readSigned(input, 64);
            while (repeat < repeated) limit 16384 {
              set(starts, repeat, archiveStart);
              set(lengths, repeat, repeatLength);
              repeat += 1;
            }
            long entry = 0;
            while (entry < entries) limit 16384 {
              long at = 72 + entry * 24;
              long row = readSigned(input, at);
              set(starts, row, readSigned(input, at + 8));
              set(lengths, row, readSigned(input, at + 16));
              entry += 1;
            }
            if (bufferLength(output) < 8193) {
              long byte = 0;
              while (byte < bufferLength(output)) limit 8192 {
                setByte(output, byte, byte % 251 + 1);
                byte += 1;
              }
            } else {
              setByte(output, 0, 29);
              setByte(output, bufferLength(output) / 2, 31);
              setByte(output, bufferLength(output) - 1, 37);
            }
            prepared = 1;
            long length = emitLinkedStringSectionAt(
              input, readSigned(input, 16), readSigned(input, 0),
              starts, lengths, finalRows, output, readSigned(input, 8)
            );
            sectionBytes = length;
            published = 1;
            drop(finalRows);
            drop(lengths);
            drop(starts);
            drop(rows);
          }
          private void fill(borrow mut words cells, long seed) {
            long index = 0;
            while (index < bufferLength(cells) - 2) limit 5462 {
              long value = index % 23 + seed;
              set(cells, index, value);
              set(cells, index + 1, value + 1);
              set(cells, index + 2, value + 2);
              index += 3;
            }
            while (index < bufferLength(cells)) limit 2 {
              set(cells, index, index % 23 + seed);
              index += 1;
            }
          }
        }
        """);
    program = new WheelerCompiler().compileModuleFiles(sources, "example.linked_strings");
    return program;
  }
}
