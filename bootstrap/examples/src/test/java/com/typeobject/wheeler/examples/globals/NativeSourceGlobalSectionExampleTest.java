package com.typeobject.wheeler.examples.globals;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Checks complete signed global sections and fail-closed publication without source parsing. */
final class NativeSourceGlobalSectionExampleTest {
  private static final int GLOBALS = 8;
  private static final int DECLARATION_COLUMNS = 3;
  private static final int NAME_ID_ROW = DECLARATION_COLUMNS * GLOBALS;
  private static final int PUBLICATION_ROWS = NAME_ID_ROW + GLOBALS;
  private static final int PREFIX = 2;
  private static final int TAIL = 3;
  private static final int PRODUCT_ROWS = PREFIX + PUBLICATION_ROWS + TAIL;
  private static final int TYPE_COUNT_WORDS = 4;
  private static final int DESCRIPTOR_BYTES = Integer.BYTES * 2 + Long.BYTES;
  private static final int OUTPUT_BYTES = PREFIX + TYPE_COUNT_WORDS * Integer.BYTES
      + GLOBALS * DESCRIPTOR_BYTES + TAIL;
  private static final int SENTINEL = 211;

  @Test
  void emitsImplicitOrdinalsAndBothInitialValueWordsWithReplay() throws Exception {
    for (int count : new int[] {0, 1, GLOBALS}) {
      check(count, "PREFIX", "PREFIX", "", true);
    }
  }

  @Test
  void rejectsEveryInvalidWindowAndLaterNameBeforeWritingTheTypePrefix() throws Exception {
    check(-1, "PREFIX", "PREFIX", "", false);
    check(GLOBALS + 1, "PREFIX", "PREFIX", "", false);
    for (String start : List.of("-1", "9223372036854775807", "PRODUCT_ROWS")) {
      check(GLOBALS, start, "PREFIX", "", false);
      check(GLOBALS, "PREFIX", start, "", false);
    }
    check(GLOBALS, "PREFIX", "OUTPUT_BYTES - 1", "", false);
    for (String value : List.of("-1", "STRING_COUNT", "2")) {
      check(GLOBALS, "PREFIX", "PREFIX",
          "set(products, PREFIX + SOURCE_GLOBAL_NAME_ID_ROW + MAX_SOURCE_GLOBALS - 1, "
              + value + ");", false);
    }
  }

  private static void check(int count, String productStart, String outputStart,
      String mutation, boolean accepted) throws Exception {
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_global_section"));
    modules.put("Driver.w", """
        module example.global_section;
        import wheeler.compiler.closure.source_global_schema;
        import wheeler.compiler.closure.source_global_section;
        classical class Driver {
          const long PREFIX = 2;
          const long TAIL = 3;
          const long WORD_BYTES = 8;
          const long ENCODED_WORD_BYTES = 4;
          const long TYPE_COUNT_WORDS = 4;
          const long DESCRIPTOR_BYTES = ENCODED_WORD_BYTES * 2 + WORD_BYTES;
          const long PRODUCT_ROWS = PREFIX + SOURCE_GLOBAL_PUBLICATION_ROWS + TAIL;
          const long OUTPUT_BYTES = PREFIX + TYPE_COUNT_WORDS * ENCODED_WORD_BYTES
            + MAX_SOURCE_GLOBALS * DESCRIPTOR_BYTES + TAIL;
          const long ARENA_BYTES = PRODUCT_ROWS * WORD_BYTES + OUTPUT_BYTES;
          const long STRING_COUNT = MAX_SOURCE_GLOBALS + 2;
          const long SENTINEL = 211;
          state long observed = -1;
          state long completed = 0;
          entry void main() {
            region arena = new region(ARENA_BYTES, /* buffers= */ 2);
            words products = allocate(arena, PRODUCT_ROWS);
            bytes output = allocateBytes(arena, OUTPUT_BYTES);
            long product = 0;
            while (product < PRODUCT_ROWS) limit PRODUCT_ROWS {
              set(products, product, SENTINEL); product += 1;
            }
            long cell = 0;
            while (cell < OUTPUT_BYTES) limit OUTPUT_BYTES {
              setByte(output, cell, SENTINEL); cell += 1;
            }
            long global = 0;
            while (global < MAX_SOURCE_GLOBALS) limit MAX_SOURCE_GLOBALS {
              set(products, PREFIX + SOURCE_GLOBAL_NAME_ID_ROW + global, global + 2);
              set(products, PREFIX + SOURCE_GLOBAL_VALUE_ROW + global,
                -9223372036854775808 + global);
              global += 1;
            }
            set(products, PREFIX + SOURCE_GLOBAL_VALUE_ROW + MAX_SOURCE_GLOBALS - 1,
              9223372036854775807);
            %s
            observed = writeSourceGlobalTypeSection(
              %d, %s, products, STRING_COUNT, output, %s);
            completed = 1;
            drop(output); drop(products); drop(arena);
          }
        }
        """.formatted(mutation, count, productStart, outputStart));
    var program = new WheelerCompiler().compileModuleFiles(modules, "example.global_section");
    VirtualMachine machine = new VirtualMachine(program);
    var initial = machine.snapshot();
    Runnable run = () -> {
      while (machine.global("completed") == 0) machine.step();
    };
    if (accepted) run.run();
    else assertThrows(VmTrap.class, run::run);
    var published = machine.snapshot();
    long[] expectedProducts = new long[PRODUCT_ROWS];
    Arrays.fill(expectedProducts, SENTINEL);
    for (int global = 0; global < GLOBALS; global++) {
      expectedProducts[PREFIX + NAME_ID_ROW + global] = global + 2;
      expectedProducts[PREFIX + GLOBALS * 2 + global] = initialValue(global);
    }
    if (!mutation.isEmpty()) {
      long badName = mutation.contains("STRING_COUNT") ? GLOBALS + 2
          : mutation.contains(", -1)") ? -1 : 2;
      expectedProducts[PREFIX + NAME_ID_ROW + GLOBALS - 1] = badName;
    }
    byte[] expected = new byte[OUTPUT_BYTES];
    Arrays.fill(expected, (byte) SENTINEL);
    int length = TYPE_COUNT_WORDS * Integer.BYTES + count * DESCRIPTOR_BYTES;
    if (accepted) {
      ByteBuffer wire = ByteBuffer.wrap(expected).order(ByteOrder.LITTLE_ENDIAN);
      wire.position(PREFIX);
      wire.putInt(count);
      for (int global = 0; global < count; global++) {
        wire.putInt(global + 2).putInt(ValueType.SIGNED.code()).putLong(initialValue(global));
      }
      for (int empty = 1; empty < TYPE_COUNT_WORDS; empty++) wire.putInt(0);
      assertEquals(length, wire.position() - PREFIX);
    }
    assertEquals(accepted ? length : -1, machine.global("observed"));
    assertArrayEquals(expectedProducts, published.buffers().get(0).elements().stream()
        .mapToLong(Long::longValue).toArray());
    byte[] actual = new byte[OUTPUT_BYTES];
    for (int i = 0; i < actual.length; i++) {
      actual[i] = published.buffers().get(1).elements().get(i).byteValue();
    }
    assertArrayEquals(expected, actual);
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(initial, machine.snapshot());
    if (accepted) run.run();
    else assertThrows(VmTrap.class, run::run);
    assertEquals(published, machine.snapshot());
    if (accepted) {
      while (machine.status() != MachineStatus.HALTED) machine.step();
      for (var region : machine.snapshot().regions()) assertTrue(region.dropped());
    }
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(initial, machine.snapshot());
  }

  private static long initialValue(int global) {
    return global == GLOBALS - 1 ? Long.MAX_VALUE : Long.MIN_VALUE + global;
  }
}
