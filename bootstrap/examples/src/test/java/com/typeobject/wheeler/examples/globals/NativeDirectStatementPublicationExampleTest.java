package com.typeobject.wheeler.examples.globals;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Tests publication transport separately from the producer's statement/type/code validation. */
final class NativeDirectStatementPublicationExampleTest {
  private static final int STATEMENTS = 4096;
  private static final int COLUMNS = 7;
  private static final int TYPE_COLUMNS = 3;
  private static final int CALLS = 256;
  private static final int FUNCTIONS = 64;
  private static final int CODE_BYTES = 262144;
  private static final int INPUT_BUFFERS = 7;
  private static final int SENTINEL = 211;

  private record Counts(long products, long instructions, long bytes, long types,
                        long calls, long functions, long statements) {}
  private static final Counts SMALL = new Counts(2, 3, 3, 2, 2, 1, 2);

  @Test
  void publishesOnlySelectedColumnsAndReplaysEmptyAcceptedAndDiscardedBatches() throws Exception {
    check(SMALL, true, 0, 0, false);
    check(new Counts(0, 0, 0, 0, 0, 0, 0), true, 0, 0, false);
    check(SMALL, false, 0, 0, false);
  }

  @Test
  void copiesEveryTerminalRowAndByteWithoutRetainingCapacityHistory() throws Exception {
    check(new Counts(STATEMENTS, STATEMENTS, CODE_BYTES, STATEMENTS,
        CALLS, FUNCTIONS, STATEMENTS), true, 0, 0, true);
  }

  @Test
  void rejectsFirstExcessAndMalformedLateOutputBeforeChangingAnyCallerCell() throws Exception {
    for (Counts count : List.of(
        new Counts(STATEMENTS + 1, 3, 3, 2, 2, 1, 2),
        new Counts(2, -1, 3, 2, 2, 1, 2),
        new Counts(2, 3, CODE_BYTES + 1, 2, 2, 1, 2),
        new Counts(2, 3, 3, STATEMENTS + 1, 2, 1, 2),
        new Counts(2, 3, 3, 2, CALLS + 1, 1, 2),
        new Counts(2, 3, 3, 2, 2, FUNCTIONS + 1, 2),
        new Counts(2, 3, 3, 2, 2, 1, STATEMENTS + 1))) {
      check(count, true, 0, 0, false);
    }
    check(SMALL, true, 1, 0, false);
    check(SMALL, true, 0, 1, false);
  }

  private static void check(Counts count, boolean producerValid, int shortTypes, int shortCode, boolean capacity)
      throws Exception {
    boolean rejected = producerValid && (count.products() > STATEMENTS || count.instructions() < 0
        || count.bytes() > CODE_BYTES || count.types() > STATEMENTS || count.calls() > CALLS
        || count.functions() > FUNCTIONS || count.statements() > STATEMENTS || shortTypes != 0 || shortCode != 0);
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.closure.direct_statement_publication"));
    modules.put("Publication.w", """
        module example.statement_publication;
        import wheeler.compiler.closure.direct_statement_publication;
        classical class Publication {
          const long RESULT_ROWS = 7;
          const long CALLER_TYPE_ROWS = TYPE_ROWS - %d;
          const long CALLER_CODE_BYTES = MAX_CODE_BYTES - %d;
          const long CALL_ROWS = DIRECT_CALLS * 4;
          const long WORD_ROWS = DIRECT_ROWS * 2 + DIRECT_CALLS * 3 + CALL_ROWS
            + DIRECT_FUNCTIONS * 2 + TYPE_ROWS + CALLER_TYPE_ROWS + MAX_STATEMENTS * 2 + RESULT_ROWS;
          const long WORD_BYTES = %d;
          const long ARENA_BYTES = WORD_ROWS * WORD_BYTES + MAX_CODE_BYTES + CALLER_CODE_BYTES;
          const long INPUT_BUFFERS = 7;
          const long OUTPUT_BUFFERS = 7;
          const long ARENA_BUFFERS = INPUT_BUFFERS + OUTPUT_BUFFERS + 1;
          state long prepared = 0;
          state long completed = 0;
          void initialize(borrow mut words data) {
            long index = 0;
            while (index < bufferLength(data)) limit DIRECT_ROWS {
              set(data, index, index + 1); index += 1;
            }
          }
          void mark(borrow mut words data) {
            set(data, 0, %d); set(data, bufferLength(data) - 1, %d);
          }
          entry void main() {
            region arena = new region(ARENA_BYTES, ARENA_BUFFERS);
            words staged = allocate(arena, DIRECT_ROWS);
            words kinds = allocate(arena, DIRECT_CALLS);
            words conditions = allocate(arena, DIRECT_CALLS);
            words results = allocate(arena, DIRECT_FUNCTIONS);
            words types = allocate(arena, TYPE_ROWS);
            words widths = allocate(arena, MAX_STATEMENTS);
            bytes code = allocateBytes(arena, MAX_CODE_BYTES);
            words outputRows = allocate(arena, DIRECT_ROWS);
            words outputCalls = allocate(arena, CALL_ROWS);
            words outputConditions = allocate(arena, DIRECT_CALLS);
            words outputResults = allocate(arena, DIRECT_FUNCTIONS);
            words outputTypes = allocate(arena, CALLER_TYPE_ROWS);
            words outputWidths = allocate(arena, MAX_STATEMENTS);
            bytes output = allocateBytes(arena, CALLER_CODE_BYTES);
            words metadata = allocate(arena, RESULT_ROWS);
            initialize(staged); initialize(kinds); initialize(conditions); initialize(results);
            initialize(types); initialize(widths);
            long byte = 0;
            while (byte < MAX_CODE_BYTES) limit MAX_CODE_BYTES { setByte(code, byte, 49); byte += 1; }
            mark(outputRows); mark(outputCalls); mark(outputConditions); mark(outputResults);
            mark(outputTypes); mark(outputWidths); mark(metadata);
            setByte(output, 0, %d); setByte(output, CALLER_CODE_BYTES - 1, %d);
            prepared = 1;
            DirectStatementPlan plan = publishDirectStatements(%d, %d, %d, %d, %d, %d, %d,
              /* failureStatement= */ 7, /* failureCode= */ 11, %s,
              staged, kinds, conditions, results, types, widths, code,
              outputRows, outputCalls, outputConditions, outputResults, outputTypes, outputWidths, output);
            set(metadata, 0, 0); if (plan.valid) { set(metadata, 0, 1); }
            set(metadata, 1, plan.productCount); set(metadata, 2, plan.instructionCount);
            set(metadata, 3, plan.length); set(metadata, 4, plan.typeCount);
            set(metadata, 5, plan.failureStatement); set(metadata, 6, plan.failureCode);
            completed = 1;
            drop(metadata); drop(output); drop(outputWidths); drop(outputTypes); drop(outputResults);
            drop(outputConditions); drop(outputCalls); drop(outputRows);
            drop(code); drop(widths); drop(types); drop(results); drop(conditions); drop(kinds); drop(staged);
            drop(arena);
          }
        }
        """.formatted(shortTypes, shortCode, Long.BYTES, SENTINEL, SENTINEL, SENTINEL, SENTINEL,
            count.products(), count.instructions(), count.bytes(), count.types(), count.calls(),
            count.functions(), count.statements(), producerValid));
    var program = new WheelerCompiler().compileModuleFiles(modules, "example.statement_publication");
    var machine = new VirtualMachine(program);
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    var before = machine.snapshot();
    if (rejected) assertThrows(VmTrap.class, () -> finish(machine, false));
    else finish(machine, capacity);
    var after = machine.snapshot();
    assertEquals(before.regions(), after.regions());
    assertEquals(before.buffers().size(), after.buffers().size());
    for (int input = 0; input < INPUT_BUFFERS; input++) assertEquals(before.buffers().get(input), after.buffers().get(input));
    for (int output = 0; output < INPUT_BUFFERS; output++) {
      long[] expected = cells(before.buffers().get(INPUT_BUFFERS + output));
      if (!rejected && producerValid) {
        if (output == 0 || output == 4) {
          int columns = output == 0 ? COLUMNS : TYPE_COLUMNS;
          long active = output == 0 ? count.products() : count.types();
          for (int column = 0; column < columns; column++) {
            for (int row = 0; row < active; row++) {
              int cell = column * STATEMENTS + row; expected[cell] = cell + 1;
            }
          }
        } else if (output == 1) {
          for (int call = 0; call < count.calls(); call++) expected[CALLS + call] = call + 1;
        } else if (output == 6) {
          Arrays.fill(expected, 0, (int) count.bytes(), 49);
        } else {
          long active = output == 2 ? count.calls() : output == 3 ? count.functions() : count.statements();
          for (int row = 0; row < active; row++) expected[row] = row + 1;
        }
      }
      assertArrayEquals(expected, cells(after.buffers().get(INPUT_BUFFERS + output)));
    }
    long[] metadata = rejected ? cells(before.buffers().getLast()) : producerValid
        ? new long[] {1, count.products(), count.instructions(), count.bytes(), count.types(), -1, 0}
        : new long[] {0, 0, 0, 0, 0, 7, 11};
    assertArrayEquals(metadata, cells(after.buffers().getLast()));
    if (!capacity) {
      while (machine.historySize() > 0) machine.rewindOne();
      assertEquals(before, machine.snapshot());
      if (rejected) assertThrows(VmTrap.class, () -> finish(machine, false));
      else finish(machine, false);
      assertEquals(after, machine.snapshot());
    }
    if (!rejected) {
      while (machine.status() != MachineStatus.HALTED) {
        if (capacity) machine.stepWithoutRewindHistory(); else machine.step();
      }
      assertTrue(machine.snapshot().buffers().stream().allMatch(BufferValue::dropped));
      assertTrue(machine.snapshot().regions().stream().allMatch(region -> region.dropped()));
    }
    if (!capacity) {
      while (machine.historySize() > 0) machine.rewindOne();
      assertEquals(before, machine.snapshot());
    }
  }

  private static void finish(VirtualMachine machine, boolean historyFree) {
    while (machine.global("completed") == 0) {
      if (historyFree) machine.stepWithoutRewindHistory(); else machine.step();
    }
  }

  private static long[] cells(BufferValue value) {
    return value.elements().stream().mapToLong(Long::longValue).toArray();
  }
}
