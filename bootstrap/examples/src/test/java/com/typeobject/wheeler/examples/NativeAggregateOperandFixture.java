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
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Checks the type-operand accessor boundary, not whole-container verification. */
final class NativeAggregateOperandFixture {
  record Binding(long owner, long kind, long type, long target) {}
  record Operand(long opcode, long type) {}

  static final class Input {
    final boolean projected;
    final List<Binding> bindings = new ArrayList<>();
    final List<Operand> operands = new ArrayList<>();
    final Map<Integer, Long> starts = new LinkedHashMap<>();
    // Declared counts, owner, five capacities, and actual fixture counts.
    final long[] header;
    int truncate;
    boolean lastIdentityOnly;
    boolean discardPreparationHistory;

    Input(boolean projected) {
      this.projected = projected;
      header = new long[] {0, 0, 2, 24576, projected ? 65536 : 576,
          projected ? 524288 : 32, 12288, 131072, 0, 0};
    }

    Input binding(long owner, long kind, long type, long target) {
      bindings.add(new Binding(owner, kind, type, target));
      header[1] = bindings.size();
      return this;
    }

    Input operand(long opcode, long type) {
      operands.add(new Operand(opcode, type));
      header[0] = operands.size();
      return this;
    }

    byte[] bytes() {
      int codeStart = 80 + operands.size() * 16 + bindings.size() * 64;
      ByteBuffer bytes = ByteBuffer.allocate(codeStart + operands.size() * 24)
          .order(ByteOrder.LITTLE_ENDIAN);
      header[8] = operands.size();
      header[9] = bindings.size();
      for (long value : header) { bytes.putLong(value); }
      for (int row = 0; row < operands.size(); row++) {
        bytes.putLong(operands.get(row).opcode()).putLong(starts.getOrDefault(row, codeStart + row * 24L));
      }
      for (int row = 0; row < bindings.size(); row++) {
        Binding binding = bindings.get(row);
        bytes.putLong(binding.owner()).putLong(binding.kind()).putLong(binding.type()).putLong(binding.target());
        bytes.put(identity(row));
      }
      for (Operand operand : operands) {
        bytes.putLong(operand.opcode()).putLong(0).putLong(operand.type());
      }
      return java.util.Arrays.copyOf(bytes.array(), bytes.capacity() - truncate);
    }
  }

  private static final Map<Integer, Program> PROGRAMS = new LinkedHashMap<>();

  private NativeAggregateOperandFixture() {}

  static void accepts(Input input) throws Exception {
    check(input, true, false, false);
  }

  static void rejects(Input input, boolean trap, boolean preflight) throws Exception {
    check(input, false, trap, preflight);
  }

  private static void check(Input input, boolean accepted, boolean trap, boolean preflight)
      throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(input.projected, input.lastIdentityOnly), input.bytes());
    MachineSnapshot initial = machine.snapshot();
    while (machine.global("prepared") == 0) {
      if (input.discardPreparationHistory) { machine.stepWithoutRewindHistory(); }
      else { machine.step(); }
    }
    if (input.discardPreparationHistory) {
      assertEquals(0, machine.historySize());
      initial = machine.snapshot();
    }
    MachineSnapshot before = machine.snapshot();
    List<BufferValue> caller = caller(before);
    long[] expectedRows = caller.get(3).elements().stream().mapToLong(Long::longValue).toArray();
    byte[] expectedIds = bytes(caller.get(4));
    long expectedCount = 0;
    if (accepted) {
      for (int instruction = 0; instruction < input.operands.size(); instruction++) {
        Operand operand = input.operands.get(instruction);
        int kind = kind(operand.opcode());
        if (kind == 0) { continue; }
        for (int row = 0; row < input.bindings.size(); row++) {
          Binding binding = input.bindings.get(row);
          if (input.projected && binding.owner() != input.header[2]) { continue; }
          if (binding.kind() != kind || binding.type() != operand.type()) { continue; }
          int relocation = Math.toIntExact(expectedCount++);
          expectedRows[relocation] = instruction;
          expectedRows[4096 + relocation] = input.projected ? binding.target() : row;
          expectedRows[8192 + relocation] = kind;
          System.arraycopy(identity(input.projected ? row : 0), 0, expectedIds, relocation * 32, 32);
        }
      }
    }
    if (trap) {
      assertThrows(VmTrap.class, () -> {
        while (machine.global("finished") == 0) { machine.step(); }
      });
      assertEquals(0, machine.global("finished"));
      assertEquals(-1, machine.global("valid"));
    } else {
      while (machine.global("finished") == 0) { machine.step(); }
      assertEquals(accepted ? 1 : 0, machine.global("valid"));
      if (accepted) { assertEquals(expectedCount, machine.global("count")); }
    }
    MachineSnapshot after = machine.snapshot();
    List<BufferValue> current = caller(after);
    assertEquals(before.buffers().getFirst(), after.buffers().getFirst());
    assertEquals(caller.subList(0, 3), current.subList(0, 3));
    assertArrayEquals(expectedRows, current.get(3).elements().stream().mapToLong(Long::longValue).toArray());
    assertArrayEquals(expectedIds, bytes(current.get(4)));
    assertEquals(before.regions().getLast(), after.regions().get(before.regions().size() - 1));
    if (preflight) {
      assertEquals(before.buffers(), after.buffers());
      assertEquals(before.regions(), after.regions());
    }
    if (!trap) { machine.run(); }
    while (machine.historySize() > 0) { machine.rewindOne(); }
    assertEquals(initial, machine.snapshot());
  }

  private static int kind(long opcode) {
    if (opcode == 0x0500) { return 1; }
    if (opcode == 0x0520) { return 2; }
    if (opcode == 0x0530) { return 3; }
    if (opcode == 0x0510) { return 4; }
    return 0;
  }

  private static byte[] identity(int row) {
    byte[] bytes = new byte[32];
    for (int index = 0; index < bytes.length; index++) {
      bytes[index] = (byte) ((row * 17 + index * 7 + 3) % 251 + 1);
    }
    return bytes;
  }

  private static byte[] bytes(BufferValue buffer) {
    byte[] bytes = new byte[buffer.elements().size()];
    for (int index = 0; index < bytes.length; index++) {
      bytes[index] = buffer.elements().get(index).byteValue();
    }
    return bytes;
  }

  private static List<BufferValue> caller(MachineSnapshot snapshot) {
    int region = snapshot.regions().stream().filter(r -> r.maxBytes() == 1600000)
        .findFirst().orElseThrow().id();
    return snapshot.buffers().stream().filter(b -> b.regionId() == region).toList();
  }

  private static Program program(boolean projected, boolean lastIdentityOnly) throws Exception {
    int key = (projected ? 1 : 0) + (lastIdentityOnly ? 2 : 0);
    if (PROGRAMS.containsKey(key)) { return PROGRAMS.get(key); }
    String owner = "wheeler.compiler.closure.aggregate_operand_relocations";
    String binding = projected ? """
                set(bindings, row, readSigned(input, at));
                set(bindings, 16384 + row, readSigned(input, at + 8));
                set(bindings, 32768 + row, readSigned(input, at + 16));
                set(bindings, 49152 + row, readSigned(input, at + 24));
        """ : """
                set(bindings, row, readSigned(input, at + 8));
                set(bindings, 128 + row, readSigned(input, at + 16));
        """;
    String ids = projected ? "row * 32 + byte" : "byte";
    String guard = lastIdentityOnly ? "row + 1 == actualBindings" : projected ? "true" : "row == 0";
    String call = projected ? """
            AggregateOperandProjectionPlan plan = projectAggregateOperandRelocations(
              input, readSigned(input, 16), readSigned(input, 0), instructions,
              readSigned(input, 8), bindings, identities, relocations, relocatedIdentities
            );
            count = plan.relocationCount;
            if (plan.valid) { valid = 1; } else { valid = 0; }
        """ : """
            count = resolveAggregateOperandRelocations(
              input, readSigned(input, 0), instructions, readSigned(input, 8),
              bindings, identities, relocations, relocatedIdentities
            );
            valid = 1;
        """;
    Map<String, String> sources = new LinkedHashMap<>(CompilerSources.moduleClosure(owner));
    CoreSources.addBinaryClosure(sources);
    sources.put("Operand.w", """
        module example.operand;
        import %s;
        import wheeler.core.encoding.binary;
        classical class Operand {
          state long prepared = 0;
          state long finished = 0;
          state long valid = -1;
          state long count = -1;
          entry void main(borrow byteview input) {
            region caller = new region(/* bytes= */ 1600000, /* allocations= */ 5);
            words instructions = allocate(caller, readSigned(input, 24));
            words bindings = allocate(caller, readSigned(input, 32));
            bytes identities = allocateBytes(caller, readSigned(input, 40));
            words relocations = allocate(caller, readSigned(input, 48));
            bytes relocatedIdentities = allocateBytes(caller, readSigned(input, 56));
            set(instructions, bufferLength(instructions) - 1, 23);
            set(bindings, bufferLength(bindings) - 1, 29);
            setByte(identities, bufferLength(identities) - 1, 31);
            set(relocations, 0, 37);
            set(relocations, 4096, 41);
            set(relocations, 8192, 43);
            set(relocations, bufferLength(relocations) - 1, 47);
            setByte(relocatedIdentities, 0, 53);
            setByte(relocatedIdentities, 65536, 59);
            setByte(relocatedIdentities, bufferLength(relocatedIdentities) - 1, 61);
            long actualInstructions = readSigned(input, 64);
            long actualBindings = readSigned(input, 72);
            long instruction = 0;
            while (instruction < actualInstructions) limit 4096 {
              set(instructions, 8192 + instruction, readSigned(input, 88 + instruction * 16));
              set(instructions, 12288 + instruction, readSigned(input, 80 + instruction * 16));
              instruction += 1;
            }
            long row = 0;
            while (row < actualBindings) limit 16384 {
              long at = 80 + actualInstructions * 16 + row * 64;
        %s
              if (%s) {
                long byte = 0;
                while (byte < 32) limit 32 {
                  long destination = %s;
                  if (destination < bufferLength(identities)) {
                    setByte(identities, destination, input[at + 32 + byte]);
                  }
                  byte += 1;
                }
              }
              row += 1;
            }
            prepared = 1;
        %s
            finished = 1;
            drop(relocatedIdentities);
            drop(relocations);
            drop(identities);
            drop(bindings);
            drop(instructions);
            drop(caller);
          }
        }
        """.formatted(owner, binding, guard, ids, call));
    Program program = new WheelerCompiler().compileModuleFiles(sources, "example.operand");
    PROGRAMS.put(key, program);
    return program;
  }
}
