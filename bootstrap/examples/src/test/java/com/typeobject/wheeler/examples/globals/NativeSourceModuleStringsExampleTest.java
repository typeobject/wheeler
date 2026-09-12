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
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Compares canonical source-name directories, mappings, tails, rejection, and replay. */
final class NativeSourceModuleStringsExampleTest {
  private static final int STRINGS = 256;
  private static final int DIRECTORY_COLUMNS = 2;
  private static final int SCRATCH_COLUMNS = DIRECTORY_COLUMNS + 2;
  private static final int TAIL = 3;
  private static final int SCRATCH_ROWS = STRINGS * SCRATCH_COLUMNS + TAIL;
  private static final int BUFFERS = DIRECTORY_COLUMNS + 1;
  private static final int ARENA_BYTES = (STRINGS * DIRECTORY_COLUMNS + SCRATCH_ROWS) * Long.BYTES;
  private static final int SENTINEL = 211;
  private static final int STRING_BYTES = 32768;

  @Test
  void ordersAllNameKindsAndSharesEqualSpellings() throws Exception {
    for (List<String> names : List.of(
        List.of("$library", "Class", "module::f", "Alpha", "Zulu"),
        List.of("z", "a::f", "$library", "A", "z", "A"),
        List.of("prefixA", "prefix", "prefixAA", "prefixA"),
        List.of("é", "𝄞", "z", "é"))) {
      check(names, "", true, true);
    }
  }

  @Test
  void rejectsInvalidLaterRangesBeforeChangingEitherDirectory() throws Exception {
    for (String mutation : List.of("set(starts, 1, -1);", "set(lengths, 1, 0);",
        "set(lengths, 1, 9223372036854775807);", "set(starts, 1, 9223372036854775807);")) {
      check(List.of("first", "second"), mutation, false, true);
    }
    check(List.of(), "", false, true);
  }

  @Test
  void admitsTheCompleteStringDirectoryWithoutRetainingHistory() throws Exception {
    check(IntStream.range(0, STRINGS).mapToObj(i -> "name" + (STRINGS - i)).toList(),
        "", true, false);
    check(java.util.Collections.nCopies(STRINGS, "same"), "", true, false);
    check(java.util.Collections.nCopies(STRINGS, "same"), "count += 1;", false, false);
  }

  @Test
  void checksTheExactNameByteWindowAndItsFirstExcess() throws Exception {
    check(List.of("A".repeat(STRING_BYTES)), "", true, false);
    check(List.of("A".repeat(STRING_BYTES + 1)), "", false, false);
  }

  private static void check(List<String> names, String mutation, boolean accepted, boolean history)
      throws Exception {
    var input = new ByteArrayOutputStream();
    var setup = new StringBuilder();
    long[] starts = filled(STRINGS);
    long[] lengths = filled(STRINGS);
    for (int row = 0; row < names.size(); row++) {
      byte[] bytes = names.get(row).getBytes(StandardCharsets.UTF_8);
      starts[row] = input.size();
      lengths[row] = bytes.length;
      setup.append("set(starts, ").append(row).append(", ").append(input.size()).append(");\n")
          .append("set(lengths, ").append(row).append(", ").append(bytes.length).append(");\n");
      input.writeBytes(bytes);
    }
    long[] preparedStarts = starts.clone();
    long[] preparedLengths = lengths.clone();
    if (mutation.contains("starts, 1, -1")) preparedStarts[1] = -1;
    if (mutation.contains("lengths, 1, 0")) preparedLengths[1] = 0;
    if (mutation.contains("lengths, 1, 922")) preparedLengths[1] = Long.MAX_VALUE;
    if (mutation.contains("starts, 1, 922")) preparedStarts[1] = Long.MAX_VALUE;
    long[] scratch = filled(SCRATCH_ROWS);
    var canonical = new ArrayList<>(names.stream().distinct().toList());
    canonical.sort((a, b) -> Arrays.compareUnsigned(a.getBytes(StandardCharsets.UTF_8),
        b.getBytes(StandardCharsets.UTF_8)));
    if (accepted) {
      for (int row = 0; row < names.size(); row++) scratch[row] = canonical.indexOf(names.get(row));
      for (int row = 0; row < canonical.size(); row++) {
        int original = names.indexOf(canonical.get(row));
        starts[row] = preparedStarts[original];
        lengths[row] = preparedLengths[original];

      }
      var order = IntStream.range(0, names.size()).boxed().sorted((a, b) -> Arrays.compareUnsigned(
          names.get(a).getBytes(StandardCharsets.UTF_8),
          names.get(b).getBytes(StandardCharsets.UTF_8))).toList();
      for (int row = 0; row < order.size(); row++) {
        int original = order.get(row);
        scratch[STRINGS + row] = preparedStarts[original];
        scratch[STRINGS * 2 + row] = preparedLengths[original];
        scratch[STRINGS * 3 + row] = original;
      }
    } else {
      starts = preparedStarts;
      lengths = preparedLengths;
    }
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_module_strings"));
    modules.put("Driver.w", """
        module example.source_strings;
        import wheeler.compiler.closure.source_module_strings;
        classical class Driver {
          const long TAIL = 3;
          const long DIRECTORY_COLUMNS = 2;
          const long BUFFERS = DIRECTORY_COLUMNS + 1;
          const long WORD_BYTES = 8;
          const long WORDS = MAX_SOURCE_MODULE_STRINGS * DIRECTORY_COLUMNS
            + SOURCE_MODULE_STRING_ROWS + TAIL;
          const long ARENA_BYTES = WORDS * WORD_BYTES;
          const long SENTINEL = 211;
          state long observed = -1;
          state long completed = 0;
          entry void main(borrow byteview input) {
            region arena = new region(ARENA_BYTES, BUFFERS);
            words starts = allocate(arena, MAX_SOURCE_MODULE_STRINGS);
            words lengths = allocate(arena, MAX_SOURCE_MODULE_STRINGS);
            words scratch = allocate(arena, SOURCE_MODULE_STRING_ROWS + TAIL);
            long directory = 0;
            while (directory < MAX_SOURCE_MODULE_STRINGS) limit MAX_SOURCE_MODULE_STRINGS {
              set(starts, directory, SENTINEL); set(lengths, directory, SENTINEL);
              directory += 1;
            }
            long cell = 0;
            while (cell < SOURCE_MODULE_STRING_ROWS + TAIL) limit WORDS {
              set(scratch, cell, SENTINEL);
              cell += 1;
            }
            long count = %d;
            %s
            %s
            observed = materializeSourceModuleStringOrder(
              input, bufferLength(input), count, starts, lengths, scratch);
            completed = 1;
            drop(scratch); drop(lengths); drop(starts); drop(arena);
          }
        }
        """.formatted(names.size(), setup, mutation));
    var program = new WheelerCompiler().compileModuleFiles(modules, "example.source_strings");
    VirtualMachine machine = VirtualMachine.withBinaryInput(program, input.toByteArray());
    var initial = machine.snapshot();
    Runnable execute = () -> {
      while (machine.global("completed") == 0) {
        if (history) machine.step();
        else machine.stepWithoutRewindHistory();
      }
    };
    if (accepted) execute.run();
    else assertThrows(VmTrap.class, execute::run);
    var published = machine.snapshot();
    assertEquals(accepted ? canonical.size() : -1, machine.global("observed"));
    int owner = published.regions().stream()
        .filter(r -> r.maxBytes() == ARENA_BYTES && r.maxObjects() == BUFFERS)
        .findFirst().orElseThrow().id();
    var buffers = published.buffers().stream().filter(b -> b.regionId() == owner).toList();
    assertEquals(BUFFERS, buffers.size());
    assertArrayEquals(starts, buffers.get(0).elements().stream().mapToLong(Long::longValue).toArray());
    assertArrayEquals(lengths, buffers.get(1).elements().stream().mapToLong(Long::longValue).toArray());
    assertArrayEquals(scratch, buffers.get(2).elements().stream().mapToLong(Long::longValue).toArray());
    byte[] preserved = new byte[input.size()];
    for (int i = 0; i < preserved.length; i++) {
      preserved[i] = published.buffers().getFirst().elements().get(i).byteValue();
    }
    assertArrayEquals(input.toByteArray(), preserved);
    if (history) {
      while (machine.historySize() > 0) machine.rewindOne();
      assertEquals(initial, machine.snapshot());
      if (accepted) execute.run();
      else assertThrows(VmTrap.class, execute::run);
      assertEquals(published, machine.snapshot());
    } else assertEquals(0, machine.historySize());
    if (accepted) {
      while (machine.status() != MachineStatus.HALTED) {
        if (history) machine.step();
        else machine.stepWithoutRewindHistory();
      }
      assertTrue(machine.snapshot().regions().get(owner).dropped());
    }
    if (history) {
      while (machine.historySize() > 0) machine.rewindOne();
      assertEquals(initial, machine.snapshot());
    }
  }

  private static long[] filled(int length) {
    long[] cells = new long[length];
    Arrays.fill(cells, SENTINEL);
    return cells;
  }
}
