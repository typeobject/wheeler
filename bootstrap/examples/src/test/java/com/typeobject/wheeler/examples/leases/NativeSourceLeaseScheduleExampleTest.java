package com.typeobject.wheeler.examples.leases;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferKind;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.RegionValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Counts complete schedule allocations and rejects late inputs before public row changes. */
final class NativeSourceLeaseScheduleExampleTest {
  private static final int MAX_MODULES = 512;
  private static final int TAIL_ROWS = 3;
  private static final int SLOT_BUFFERS = 1 + 4;
  private static final int SCHEDULE_BUFFERS = 2;
  private static final long SLOT_SENTINEL = 211;
  private static final long GENERATION_SENTINEL = 223;

  @Test
  void stagesTwoAndEveryCapacityOwnerWithTheSameSevenBuffers() throws Exception {
    check(2, MAX_MODULES + TAIL_ROWS, "", true, true);
    check(MAX_MODULES, MAX_MODULES + TAIL_ROWS, "", true, false);
  }

  @Test
  void rejectsCountsLateRangesPermutationsAndOutputExtentsBeforePublication() throws Exception {
    check(0, MAX_MODULES + TAIL_ROWS, "", false, false);
    check(MAX_MODULES + 1, MAX_MODULES + TAIL_ROWS, "", false, false);
    check(2, 1, "", false, false);
    for (String mutation : List.of(
        "set(order, 1, 1);", "set(order, 1, 2);", "set(order, 1, -1);",
        "set(starts, 0, -1);", "set(starts, 0, 9223372036854775807);",
        "set(lengths, 0, 0);", "set(lengths, 0, 32769);",
        "set(starts, 0, 1);")) {
      check(2, MAX_MODULES + TAIL_ROWS, mutation, false, false);
    }
  }

  private static void check(int count, int outputRows, String mutation,
      boolean accepted, boolean replay) throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(count, outputRows, mutation), new byte[] {'a', (byte) 128});
    var borrowedRegions = machine.snapshot().regions().stream().map(RegionValue::id).toList();
    while (machine.global("phase") != 1) {
      machine.stepWithoutRewindHistory();
    }
    MachineSnapshot before = machine.snapshot();
    try {
      while (machine.global("phase") != 2) {
        if (replay) {
          machine.step();
        } else {
          machine.stepWithoutRewindHistory();
        }
      }
      if (!accepted) {
        fail("invalid complete schedule published");
      }
    } catch (VmTrap trap) {
      if (accepted) {
        throw trap;
      }
      assertEquals(VmTrap.Code.ASSERTION, trap.code());
      assertEquals(1, machine.global("phase"));
    }
    MachineSnapshot after = machine.snapshot();
    for (BufferValue previous : before.buffers()) {
      List<Long> expected = new ArrayList<>(previous.elements());
      if (accepted && previous.kind() == BufferKind.WORDS) {
        if (previous.elements().getFirst() == SLOT_SENTINEL) {
          for (int module = 0; module < count; module++) {
            expected.set(module, 0L);
          }
        } else if (previous.elements().getFirst() == GENERATION_SENTINEL) {
          for (int module = 0; module < count; module++) {
            expected.set(module, (long) count - module);
          }
        }
      }
      assertEquals(new BufferValue(previous.id(), previous.regionId(), previous.kind(),
          previous.length(), expected, previous.dropped()), after.buffers().get(previous.id()));
    }
    if (!accepted) {
      return;
    }
    assertEquals(SLOT_BUFFERS + SCHEDULE_BUFFERS, after.buffers().size() - before.buffers().size());
    assertEquals(2, after.regions().size() - before.regions().size());
    assertEquals(count, machine.global("finalGeneration"));
    assertEquals(1, machine.global("peak"));
    if (replay) {
      int transitions = machine.historySize();
      for (int step = 0; step < transitions; step++) {
        machine.rewindOne();
      }
      assertEquals(before, machine.snapshot());
      for (int step = 0; step < transitions; step++) {
        machine.step();
      }
      assertEquals(after, machine.snapshot());
    }
    while (machine.status() == MachineStatus.RUNNING) {
      machine.step();
    }
    assertEquals(MachineStatus.HALTED, machine.status());
    assertTrue(machine.snapshot().buffers().stream()
        .filter(buffer -> !borrowedRegions.contains(buffer.regionId()))
        .allMatch(BufferValue::dropped));
  }

  private static Program program(int count, int outputRows, String mutation) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.schedule"));
    sources.put("SourceLeaseSchedule.w", """
        module example.source_lease_schedule;
        import wheeler.compiler.closure.plan;
        import wheeler.compiler.closure.schedule;
        classical class SourceLeaseSchedule {
          private const long CAPACITY = 512;
          private const long TAIL_ROWS = 3;
          private const long SLOT_ROWS = CAPACITY + TAIL_ROWS;
          private const long GENERATION_ROWS = ROWS;
          private const long INPUT_COLUMNS = 3;
          private const long OUTPUT_COLUMNS = 2;
          private const long WORD_BYTES = 8;
          private const long ARENA_BYTES = (CAPACITY * INPUT_COLUMNS
            + SLOT_ROWS + GENERATION_ROWS) * WORD_BYTES;
          private const long BUFFERS = INPUT_COLUMNS + OUTPUT_COLUMNS;
          state long phase = 0;
          state long finalGeneration = 0;
          state long peak = 0;
          entry void main(borrow byteview input) {
            region arena = new region(/* bytes= */ ARENA_BYTES, /* allocations= */ BUFFERS);
            words order = allocate(arena, CAPACITY);
            words starts = allocate(arena, CAPACITY);
            words lengths = allocate(arena, CAPACITY);
            words slots = allocate(arena, SLOT_ROWS);
            words generations = allocate(arena, GENERATION_ROWS);
            long module = 0;
            while (module < CAPACITY) limit CAPACITY {
              set(order, module, COUNT - 1 - module);
              set(lengths, module, 1);
              module += 1;
            }
            long slotRow = 0;
            while (slotRow < SLOT_ROWS) limit SLOT_ROWS {
              set(slots, slotRow, 211);
              slotRow += 1;
            }
            long generationRow = 0;
            while (generationRow < GENERATION_ROWS) limit GENERATION_ROWS {
              set(generations, generationRow, 223);
              generationRow += 1;
            }
            MUTATION
            CountedClosurePlan plan = new CountedClosurePlan(COUNT, 0, 0, 0);
            phase = 1;
            ClosureSourceSchedule schedule = stageClosureSources(
              input, plan, order, starts, lengths, slots, generations
            );
            finalGeneration = schedule.finalGeneration;
            peak = schedule.peakActiveSources;
            phase = 2;
            drop(generations);
            drop(slots);
            drop(lengths);
            drop(starts);
            drop(order);
            drop(arena);
          }
        }
        """.replace("GENERATION_ROWS = ROWS", "GENERATION_ROWS = " + outputRows)
        .replace("COUNT", Integer.toString(count)).replace("MUTATION", mutation));
    return new WheelerCompiler().compileModuleFiles(sources, "example.source_lease_schedule");
  }
}
