package com.typeobject.wheeler.examples.globals;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Validates the whole global name window before selecting a declaration ordinal. */
final class NativeSourceGlobalReferencesExampleTest {
  private static final int CAPACITY = 8;
  private static final int COLUMNS = 3;
  private static final int NAME_BYTES = 256;
  private static final int PREFIX = 2;
  private static final int TAIL = 3;
  private static final int ROWS = PREFIX + CAPACITY * COLUMNS + TAIL;
  private static final int NAMES = PREFIX + CAPACITY * NAME_BYTES + TAIL;
  private static final int SENTINEL = 211;

  @Test
  void selectsDeclarationOrderAndPreservesEveryCallerCell() throws Exception {
    check(List.of("Zulu", "Alpha"), "Alpha", "", 2, false);
    check(List.of("Zulu", "Alpha"), "Missing", "", 2, false);
    check(List.of(), "Missing", "", 0, false);
    check(List.of("_zero", "alpha9"), "alpha9", "", 2, false);
    check(List.of("A".repeat(NAME_BYTES)), "A".repeat(NAME_BYTES), "", 1, false);
    check(List.of("h", "g", "f", "e", "d", "c", "b", "a"), "a", "", CAPACITY, false);
  }

  @Test
  void rejectsLaterInvalidNamesAndRowsBeforeSelectingAPredecessor() throws Exception {
    for (String mutation : List.of(
        "set(rows, PREFIX + 1, -1);",
        "set(rows, PREFIX + 1, 9223372036854775807);",
        "set(rows, PREFIX + CAPACITY + 1, 0);",
        "set(rows, PREFIX + CAPACITY + 1, 9223372036854775807);",
        "setByte(names, PREFIX + 5, 0);")) {
      check(List.of("Alpha", "Later"), "Alpha", mutation, 2, true);
    }
    check(List.of("Alpha", "Alpha"), "Alpha", "", 2, true);
    check(List.of("Alpha", "9bad"), "Alpha", "", 2, true);
    check(List.of("Alpha", "bad.name"), "Alpha", "", 2, true);
    check(List.of("Alpha", "A".repeat(NAME_BYTES + 1)), "Alpha", "", 2, true);
    check(List.of("Alpha"), "Alpha", "", CAPACITY + 1, true);
  }

  private static void check(List<String> names, String query, String mutation, int count, boolean rejected)
      throws Exception {
    long[] expectedRows = new long[ROWS];
    long[] expectedNames = new long[NAMES];
    Arrays.fill(expectedRows, SENTINEL);
    Arrays.fill(expectedNames, SENTINEL);
    StringBuilder setup = new StringBuilder();
    int offset = PREFIX;
    for (int row = 0; row < names.size(); row++) {
      String name = names.get(row);
      expectedRows[PREFIX + row] = offset;
      expectedRows[PREFIX + CAPACITY + row] = name.length();
      expectedRows[PREFIX + CAPACITY * 2 + row] = row;
      setup.append("set(rows, ").append(PREFIX + row).append(", ").append(offset).append(");\n")
          .append("set(rows, ").append(PREFIX + CAPACITY + row).append(", ").append(name.length()).append(");\n")
          .append("set(rows, ").append(PREFIX + CAPACITY * 2 + row).append(", ").append(row).append(");\n")
          .append("writeAscii(names, ").append(offset).append(", \"").append(name).append("\");\n");
      for (byte value : name.getBytes(StandardCharsets.US_ASCII)) expectedNames[offset++] = Byte.toUnsignedInt(value);
    }
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.closure.source_global_references"));
    sources.put("Driver.w", """
        module example.global_references;
        import wheeler.compiler.closure.source_global_references;
        classical class Driver {
          const long PREFIX = %d;
          const long CAPACITY = %d;
          const long ROWS = %d;
          const long NAMES = %d;
          const long WORD_BYTES = %d;
          const long ARENA_BYTES = ROWS * WORD_BYTES + NAMES;
          state long prepared = 0;
          state long completed = 0;
          state long observed = -2;
          entry void main(borrow utf8 input) {
            region arena = new region(ARENA_BYTES, /* buffers= */ 2);
            words rows = allocate(arena, ROWS);
            bytes names = allocateBytes(arena, NAMES);
            long row = 0;
            while (row < ROWS) limit ROWS { set(rows, row, %d); row += 1; }
            long byte = 0;
            while (byte < NAMES) limit NAMES { setByte(names, byte, %d); byte += 1; }
            %s
            %s
            prepared = 1;
            observed = sourceGlobalOrdinal(input, %d, %d, names, %d, PREFIX, rows);
            completed = 1;
            drop(names); drop(rows); drop(arena);
          }
        }
        """.formatted(PREFIX, CAPACITY, ROWS, NAMES, Long.BYTES, SENTINEL, SENTINEL,
            setup, mutation, "// café 𝄞\n".getBytes(StandardCharsets.UTF_8).length, query.length(), count));
    var program = new WheelerCompiler().compileModuleFiles(sources, "example.global_references");
    var machine = new VirtualMachine(program, ("// café 𝄞\n" + query).getBytes(StandardCharsets.UTF_8));
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    var before = machine.snapshot();
    if (rejected) assertThrows(VmTrap.class, () -> runLookup(machine));
    else runLookup(machine);
    var after = machine.snapshot();
    assertEquals(before.buffers(), after.buffers());
    assertEquals(before.regions(), after.regions());
    if (!rejected) {
      assertEquals(names.indexOf(query), machine.global("observed"));
      assertArrayEquals(expectedRows, after.buffers().stream().filter(b -> b.length() == ROWS)
          .findFirst().orElseThrow().elements().stream().mapToLong(Long::longValue).toArray());
      assertArrayEquals(expectedNames, after.buffers().stream().filter(b -> b.length() == NAMES)
          .findFirst().orElseThrow().elements().stream().mapToLong(Long::longValue).toArray());
    }
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
    if (rejected) assertThrows(VmTrap.class, () -> runLookup(machine));
    else runLookup(machine);
    assertEquals(after, machine.snapshot());
    if (!rejected) {
      while (machine.status() != MachineStatus.HALTED) machine.step();
      assertTrue(machine.snapshot().buffers().stream().skip(1).allMatch(buffer -> buffer.dropped()));
      assertTrue(machine.snapshot().regions().stream().skip(1).allMatch(region -> region.dropped()));
    }
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
  }

  private static void runLookup(VirtualMachine machine) {
    while (machine.global("completed") == 0) machine.step();
  }
}
