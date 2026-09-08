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
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;

/** Complete caller-window and rewind assertions for checked nominal fragments. */
final class NativeNominalFragmentFixture {
  record Selection(int target, long bit, long kind) {}

  static final class Input {
    long mode;
    long owner = 511;
    long firstRecord = 7;
    long firstVariant = 9;
    long outputStart = 11;
    long nameTarget = 4095;
    int capacity = 256;
    int[] columns = {4096, 36864, 49152};
    List<Selection> selections = new ArrayList<>(List.of(
        new Selection(8, 1, 4), new Selection(3, 1, 1)));
  }

  private static Program program;

  private NativeNominalFragmentFixture() {}

  static byte[] accepts(Input input) throws Exception {
    VirtualMachine machine = machine(input);
    MachineSnapshot initial = machine.snapshot();
    prepare(machine);
    MachineSnapshot before = machine.snapshot();
    byte[] output = machine.hostOutput();
    long[] projections = values(before, 2);
    String expected;
    if (input.mode == 1) {
      expected = "WheelerNominal" + input.nameTarget;
    } else {
      StringBuilder text = new StringBuilder();
      long record = input.firstRecord;
      long variant = input.firstVariant;
      int row = 0;
      for (Selection selected : input.selections.stream()
          .filter(s -> s.bit == 1).sorted(Comparator.comparingInt(Selection::target)).toList()) {
        boolean isRecord = selected.kind == 1;
        text.append(isRecord ? " private record " : " private variant ")
            .append("WheelerNominal").append(selected.target)
            .append(isRecord ? "(long value) {}" : " { case Value(long value); }");
        projections[row] = input.owner;
        projections[16384 + row] = isRecord ? 0x10000000L + record++ : 0x20000000L + variant++;
        projections[32768 + row] = selected.target;
        row++;
      }
      expected = text.toString();
    }
    byte[] fragment = expected.getBytes(StandardCharsets.US_ASCII);
    System.arraycopy(fragment, 0, output, Math.toIntExact(input.outputStart), fragment.length);
    while (machine.global("published") == 0) { machine.step(); }
    assertEquals(fragment.length, machine.global("length"));
    assertEquals(input.mode == 1 ? 0 : input.selections.stream().filter(s -> s.bit == 1).count(),
        machine.global("projectionCount"));
    assertArrayEquals(output, machine.hostOutput());
    assertArrayEquals(projections, values(machine.snapshot(), 2));
    assertEquals(before.regions(), machine.snapshot().regions());
    assertEquals(before.buffers().size(), machine.snapshot().buffers().size());
    for (int column = 0; column < 2; column++) {
      assertArrayEquals(values(before, column), values(machine.snapshot(), column));
    }
    machine.run();
    rewind(machine, initial);
    return fragment;
  }

  static void rejects(Input input) throws Exception {
    VirtualMachine machine = machine(input);
    MachineSnapshot initial = machine.snapshot();
    prepare(machine);
    MachineSnapshot before = machine.snapshot();
    byte[] output = machine.hostOutput();
    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
    assertEquals(-1, machine.global("length"));
    assertEquals(-1, machine.global("projectionCount"));
    assertArrayEquals(output, machine.hostOutput());
    assertEquals(before.buffers(), machine.snapshot().buffers());
    assertEquals(before.regions(), machine.snapshot().regions());
    rewind(machine, initial);
  }

  private static void prepare(VirtualMachine machine) {
    while (machine.global("prepared") == 0) { machine.step(); }
  }

  private static void rewind(VirtualMachine machine, MachineSnapshot initial) {
    while (machine.historySize() > 0) { machine.rewindOne(); }
    assertEquals(initial, machine.snapshot());
  }

  private static long[] values(MachineSnapshot snapshot, int column) {
    int region = snapshot.regions().stream().filter(r -> r.maxBytes() == 720960)
        .findFirst().orElseThrow().id();
    BufferValue buffer = snapshot.buffers().stream().filter(b -> b.regionId() == region)
        .toList().get(column);
    return buffer.elements().stream().mapToLong(Long::longValue).toArray();
  }

  private static VirtualMachine machine(Input input) throws Exception {
    ByteBuffer data = ByteBuffer.allocate(80 + input.selections.size() * 24)
        .order(ByteOrder.LITTLE_ENDIAN);
    for (long value : new long[] {input.mode, input.owner, input.firstRecord, input.firstVariant,
        input.outputStart, input.columns[0], input.columns[1], input.columns[2],
        input.selections.size(), input.nameTarget}) {
      data.putLong(value);
    }
    for (Selection selection : input.selections) {
      data.putLong(selection.target).putLong(selection.bit).putLong(selection.kind);
    }
    return VirtualMachine.withBinaryInput(program(), data.array(), input.capacity);
  }

  private static synchronized Program program() throws Exception {
    if (program != null) { return program; }
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_nominal_stubs"));
    CoreSources.addBinaryClosure(sources);
    sources.put("NominalFragments.w", """
        module example.nominal_fragments;
        import wheeler.compiler.closure.imported_nominal_stubs;
        import wheeler.core.encoding.binary;

        classical class NominalFragments {
          state long prepared = 0;
          state long published = 0;
          state long length = -1;
          state long projectionCount = -1;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 720960, /* allocations= */ 3);
            words selected = allocate(rows, readSigned(input, 40));
            words aggregates = allocate(rows, readSigned(input, 48));
            words projections = allocate(rows, readSigned(input, 56));
            fill(aggregates, 5);
            fill(projections, 17);
            if (bufferLength(output) < 8193) {
              long byte = 0;
              while (byte < bufferLength(output) - 2) limit 2730 {
                long value = byte % 251 + 1;
                setByte(output, byte, value);
                setByte(output, byte + 1, value + 1);
                setByte(output, byte + 2, value + 2);
                byte += 3;
              }
              while (byte < bufferLength(output)) limit 2 {
                setByte(output, byte, byte % 251 + 1);
                byte += 1;
              }
            } else {
              setByte(output, 0, 23);
              setByte(output, bufferLength(output) / 2, 29);
              setByte(output, bufferLength(output) - 1, 31);
            }
            long entry = 0;
            long entryCount = readSigned(input, 64);
            while (entry < entryCount) limit 65 {
              long target = readSigned(input, 80 + entry * 24);
              if (target < bufferLength(selected)) {
                set(selected, target, readSigned(input, 88 + entry * 24));
              }
              set(aggregates, target, readSigned(input, 96 + entry * 24));
              entry += 1;
            }
            prepared = 1;
            if (readSigned(input, 0) == 1) {
              long end = writeImportedNominalName(readSigned(input, 72), output,
                readSigned(input, 32));
              length = end - readSigned(input, 32);
              projectionCount = 0;
            } else {
              ImportedNominalDeclarationFragment fragment = writeImportedNominalDeclarations(
                readSigned(input, 8), readSigned(input, 16), readSigned(input, 24),
                selected, aggregates, projections, output, readSigned(input, 32)
              );
              length = fragment.length;
              projectionCount = fragment.projectionCount;
            }
            published = 1;
            drop(projections);
            drop(aggregates);
            drop(selected);
            drop(rows);
          }

          private void fill(borrow mut words cells, long seed) {
            long index = 0;
            while (index < bufferLength(cells) - 2) limit 16384 {
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
    program = new WheelerCompiler().compileModuleFiles(sources, "example.nominal_fragments");
    return program;
  }
}
