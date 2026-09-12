package com.typeobject.wheeler.examples.leases;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferKind;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.RegionValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Complete immutable-range, lease-state, and allocation evidence for source publication. */
final class NativeSourceLeaseRangeExampleTest {
  private static final int SOURCE_BYTES = 32_768;
  private static final int SLOT_COUNT = 8;
  private static final int STORAGE_BYTES = SOURCE_BYTES * SLOT_COUNT;
  private static final byte[] INPUT = {(byte) 255, 'a', 'b', 'c', 0, 127, 'x', 'y', 'z', (byte) 128};

  @Test
  void publishesOnlyTheSelectedAsciiRangeAndReplaysWithoutNewStorage() throws Exception {
    check(1, 5, 0, 1, 2, SLOT_COUNT, "", true);
    check(1, 5, SLOT_COUNT - 1, 1, 2, SLOT_COUNT, "", true);
  }

  @Test
  void rejectsCompleteRangeAndLeaseFailuresWithoutChangingAnyBuffer() throws Exception {
    for (long start : new long[] {-1, INPUT.length + 1, Long.MAX_VALUE}) {
      check(start, 5, 0, 1, 2, SLOT_COUNT, "", false);
    }
    for (long length : new long[] {-1, 0, INPUT.length, Long.MAX_VALUE}) {
      check(1, length, 0, 1, 2, SLOT_COUNT, "", false);
    }
    check(0, 5, 0, 1, 2, SLOT_COUNT, "", false);
    check(1, INPUT.length - 1, 0, 1, 2, SLOT_COUNT, "", false);
    for (long slot : new long[] {-1, SLOT_COUNT, Long.MAX_VALUE}) {
      check(1, 5, slot, 1, 2, SLOT_COUNT, "", false);
    }
    for (long generation : new long[] {0, 2, Long.MAX_VALUE}) {
      check(1, 5, 0, generation, 2, SLOT_COUNT, "", false);
    }
    for (long owner : new long[] {-1, 3, 512, Long.MAX_VALUE}) {
      check(1, 5, 0, 1, owner, SLOT_COUNT, "", false);
    }
    for (String mutation : List.of(
        "set(lengths, 0, -1);", "set(lengths, 0, 32769);",
        "set(live, 0, 0);", "set(live, 0, 2);")) {
      check(1, 5, 0, 1, 2, SLOT_COUNT, mutation, false);
    }
    check(1, 5, 0, 0, 2, SLOT_COUNT, "set(generations, 0, 0);", false);
    check(1, 5, 0, 1, -1, SLOT_COUNT, "set(owners, 0, -1);", false);
    check(1, 5, 0, 1, 2, SLOT_COUNT - 1, "", false);
  }

  private static void check(long start, long length, long slot, long generation, long owner,
      int columns, String mutation, boolean valid) throws Exception {
    Program program = program(start, length, slot, generation, owner, columns, mutation);
    VirtualMachine machine = VirtualMachine.withBinaryInput(program, INPUT);
    var borrowedRegions = machine.snapshot().regions().stream().map(RegionValue::id).toList();
    while (machine.global("phase") != 1) {
      machine.stepWithoutRewindHistory();
    }
    MachineSnapshot before = machine.snapshot();
    int lengthBuffer = before.buffers().stream()
        .filter(buffer -> buffer.kind() == BufferKind.WORDS && buffer.elements().contains(10L))
        .mapToInt(BufferValue::id).findFirst().orElse(-1);
    int history = machine.historySize();
    while (machine.global("phase") != 2) {
      machine.step();
    }
    MachineSnapshot after = machine.snapshot();
    assertEquals(valid ? 1 : 0, machine.global("accepted"));
    assertEquals(before.regions(), after.regions());
    assertEquals(before.buffers().size(), after.buffers().size());
    for (BufferValue previous : before.buffers()) {
      BufferValue actual = after.buffers().get(previous.id());
      List<Long> expected = new ArrayList<>(previous.elements());
      if (valid && previous.length() == STORAGE_BYTES) {
        int offset = Math.toIntExact(slot * SOURCE_BYTES);
        for (int index = 0; index < 10; index++) {
          expected.set(offset + index, index < length
              ? Byte.toUnsignedLong(INPUT[Math.toIntExact(start) + index]) : 0L);
        }
      } else if (valid && previous.id() == lengthBuffer) {
        expected.set(Math.toIntExact(slot), length);
      }
      assertEquals(new BufferValue(previous.id(), previous.regionId(), previous.kind(),
          previous.length(), expected, previous.dropped()), actual);
    }
    int transitions = machine.historySize() - history;
    for (int index = 0; index < transitions; index++) {
      machine.rewindOne();
    }
    assertEquals(before, machine.snapshot());
    for (int index = 0; index < transitions; index++) {
      machine.step();
    }
    assertEquals(after, machine.snapshot());
    while (machine.status() == MachineStatus.RUNNING) {
      machine.step();
    }
    assertEquals(MachineStatus.HALTED, machine.status());
    assertTrue(machine.snapshot().buffers().stream()
        .filter(buffer -> !borrowedRegions.contains(buffer.regionId()))
        .allMatch(BufferValue::dropped));
  }

  private static Program program(long start, long length, long slot, long generation, long owner,
      int columns, String mutation) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.active_source_slots"));
    sources.put("SourceLeaseRange.w", """
        module example.source_lease_range;
        import wheeler.compiler.closure.active_source_slots;
        classical class SourceLeaseRange {
          private const long SOURCE_BYTES = 32768;
          private const long METADATA_COLUMNS = 4;
          private const long METADATA_LENGTH = COLUMNS;
          private const long WORD_BYTES = 8;
          private const long ARENA_BYTES = ACTIVE_SOURCE_SLOT_BYTES
            + METADATA_COLUMNS * METADATA_LENGTH * WORD_BYTES;
          state long phase = 0;
          state long accepted = 0;
          entry void main(borrow byteview input) {
            region arena = new region(
              /* bytes= */ ARENA_BYTES, /* allocations= */ ACTIVE_SOURCE_SLOT_BUFFERS
            );
            bytes storage = allocateBytes(arena, ACTIVE_SOURCE_SLOT_BYTES);
            words owners = allocate(arena, METADATA_LENGTH);
            words generations = allocate(arena, METADATA_LENGTH);
            words lengths = allocate(arena, METADATA_LENGTH);
            words live = allocate(arena, METADATA_LENGTH);
            long initializedSlot = INITIALIZED_SLOT;
            set(owners, initializedSlot, 2);
            set(generations, initializedSlot, 1);
            set(lengths, initializedSlot, 10);
            set(live, initializedSlot, 1);
            long byteIndex = 0;
            while (byteIndex < 10) limit 10 {
              setByte(storage, initializedSlot * SOURCE_BYTES + byteIndex, 211);
              byteIndex += 1;
            }
            MUTATION
            ActiveSourceHandle handle = new ActiveSourceHandle(SLOT, GENERATION, OWNER);
            phase = 1;
            boolean result = publishActiveSource(
              handle, input, START, LENGTH, storage, owners, generations, lengths, live
            );
            if (result) { accepted = 1; }
            phase = 2;
            drop(live);
            drop(lengths);
            drop(generations);
            drop(owners);
            drop(storage);
            drop(arena);
          }
        }
        """.replace("METADATA_LENGTH = COLUMNS", "METADATA_LENGTH = " + columns)
        .replace("INITIALIZED_SLOT", Long.toString(slot == SLOT_COUNT - 1 ? slot : 0))
        .replace("MUTATION", mutation)
        .replace("new ActiveSourceHandle(SLOT, GENERATION, OWNER)",
            "new ActiveSourceHandle(" + slot + ", " + generation + ", " + owner + ")")
        .replace("input, START, LENGTH,", "input, " + start + ", " + length + ","));
    return new WheelerCompiler().compileModuleFiles(sources, "example.source_lease_range");
  }
}
