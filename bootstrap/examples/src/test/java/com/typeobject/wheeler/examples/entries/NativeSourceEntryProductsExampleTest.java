package com.typeobject.wheeler.examples.entries;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.RegionValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Entry binding consumes complete counted windows without allocating owned storage. */
final class NativeSourceEntryProductsExampleTest {
  private static final int DEPLOYABLE = 1;
  private static final int LIBRARY = 2;
  private static final int TOOL = 3;
  private static final int CALLABLES = 4096;
  private static final int LOCAL_CALLABLES = 64;
  private static final int PARAMETERS = 16_384;
  private static final int UTF8 = ValueType.UTF8.code();
  private static final int BYTE_VIEW = ValueType.BYTE_VIEW.code();
  private static final int BYTES = ValueType.BYTES.code();

  @Test
  void bindsEveryEntryLoanShapeAndKeepsLibrarySelectionDistinct() throws Exception {
    for (int kind : new int[] {DEPLOYABLE, TOOL}) {
      for (int[] types : List.of(new int[0], new int[] {UTF8}, new int[] {BYTE_VIEW}, new int[] {BYTES},
          new int[] {UTF8, BYTES}, new int[] {BYTE_VIEW, BYTES})) {
        StringBuilder signature = new StringBuilder();
        for (int type : types) {
          if (!signature.isEmpty()) signature.append(", ");
          signature.append(type == UTF8 ? "borrow utf8 input"
              : type == BYTE_VIEW ? "borrow byteview input" : "borrow mut bytes output");
        }
        new WheelerCompiler().compileModuleFiles(java.util.Map.of("Entry.w",
            "module example.entry; classical class Entry { entry void main("
                + signature + ") {} }"), "example.entry");
        StringBuilder setup = new StringBuilder("set(counts, 7, " + types.length + ");\n");
        int first = PARAMETERS - types.length;
        setup.append("set(firstParameters, 7, ").append(first).append(");\n");
        for (int index = 0; index < types.length; index++) {
          setup.append("set(types, ").append(first + index).append(", ").append(types[index]).append(");\n");
          setup.append("set(modes, ").append(first + index).append(", ")
              .append(types[index] == BYTES ? 2 : 1).append(");\n");
        }
        check(kind, 7, 2, setup.toString(), 0, true);
      }
    }
    check(LIBRARY, 7, 2, "set(effects, 7, 0);", -1, true);
    check(LIBRARY, 4096, 0, "", -1, true);
    check(DEPLOYABLE, 7, 2,
        "set(effects, 7, 0); set(effects, 8, 1); set(starts, 7, 6); set(lengths, 7, 6);"
            + "set(starts, 8, 2); set(lengths, 8, 4);", 1, true);
  }

  @Test
  void rejectsWrongTargetsEffectsSignaturesAndMalformedLaterRows() throws Exception {
    for (long kind : new long[] {0, 4, Long.MAX_VALUE}) check(kind, 7, 2, "", -1, false);
    check(LIBRARY, 7, 2, "", -1, false);
    check(DEPLOYABLE, 4096, 0, "", -1, false);
    for (String setup : List.of(
        "set(effects, 7, 0);", "set(effects, 7, 3);", "set(effects, 8, 8);",
        "set(effects, 8, 1); set(starts, 8, 2); set(lengths, 8, 4);",
        "set(starts, 8, 2); set(lengths, 8, 4);",
        "set(starts, 7, 6); set(lengths, 7, 6);", "set(results, 7, 1);",
        "set(starts, 8, -1);", "set(lengths, 8, 7);", "set(starts, 8, 0);",
        "set(firstParameters, 8, -1);", "set(firstParameters, 8, 9223372036854775807);",
        "set(firstParameters, 8, 16384); set(counts, 8, 1);", "set(counts, 8, 65);",
        "set(firstParameters, 7, 0); set(counts, 7, 3);",
        "set(firstParameters, 7, 0); set(counts, 7, 1); set(types, 0, 1);",
        "set(firstParameters, 7, 0); set(counts, 7, 1); set(types, 0, 7); set(modes, 0, 2);",
        "set(firstParameters, 7, 0); set(counts, 7, 1); set(types, 0, 5); set(modes, 0, 1);",
        "set(firstParameters, 7, 0); set(counts, 7, 2); set(types, 0, 5); set(modes, 0, 2);"
            + "set(types, 1, 7); set(modes, 1, 1);")) {
      check(DEPLOYABLE, 7, 2, setup, -1, false);
    }
    for (long first : new long[] {-1, 4096, Long.MAX_VALUE}) check(DEPLOYABLE, first, 2, "", -1, false);
    for (long count : new long[] {-1, 65, Long.MAX_VALUE}) check(DEPLOYABLE, 7, count, "", -1, false);
  }

  @Test
  void validatesEveryBackingColumnEvenForAnEmptyLibrary() throws Exception {
    for (String column : List.of("starts", "lengths", "effects", "firstParameters", "counts",
        "results", "types", "modes")) {
      check(program(LIBRARY, CALLABLES, 0, "", column), LIBRARY, -1, false, "##mainhelper", true);
    }
  }

  @Test
  void bindsTheLastCallableInAFullTerminalWindow() throws Exception {
    int first = CALLABLES - LOCAL_CALLABLES;
    StringBuilder names = new StringBuilder("##");
    StringBuilder setup = new StringBuilder();
    for (int local = 0; local < LOCAL_CALLABLES; local++) {
      String name = local == LOCAL_CALLABLES - 1 ? "main" : "helper" + local;
      int row = first + local;
      setup.append("set(starts, ").append(row).append(", ").append(names.length()).append(");\n")
          .append("set(lengths, ").append(row).append(", ").append(name.length()).append(");\n")
          .append("set(firstParameters, ").append(row).append(", ").append(PARAMETERS).append(");\n");
      names.append(name);
    }
    setup.append("set(effects, ").append(CALLABLES - 1).append(", 1);\n");
    check(program(DEPLOYABLE, first, LOCAL_CALLABLES, setup.toString(), ""),
        DEPLOYABLE, LOCAL_CALLABLES - 1, true, names.toString(), false);
  }

  private static void check(long kind, long first, long count, String setup,
      long selected, boolean accepted) throws Exception {
    check(program(kind, first, count, setup, ""), kind, selected, accepted, "##mainhelper", true);
  }

  private static void check(Program program, long kind, long selected, boolean accepted,
      String names, boolean replay) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program,
        names.getBytes(StandardCharsets.US_ASCII));
    var borrowed = machine.snapshot().regions().stream().map(RegionValue::id).toList();
    while (machine.global("phase") != 1) machine.stepWithoutRewindHistory();
    var before = machine.snapshot();
    while (machine.global("phase") != 2) {
      if (replay) machine.step();
      else machine.stepWithoutRewindHistory();
    }
    var after = machine.snapshot();
    assertEquals(kind, machine.global("kind"));
    assertEquals(selected, machine.global("selected"));
    assertEquals(accepted ? 1 : 0, machine.global("accepted"));
    assertEquals(before.buffers(), after.buffers());
    assertEquals(before.regions(), after.regions());
    if (replay) {
      int transitions = machine.historySize();
      for (int step = 0; step < transitions; step++) machine.rewindOne();
      assertEquals(before, machine.snapshot());
      for (int step = 0; step < transitions; step++) machine.step();
      assertEquals(after, machine.snapshot());
    }
    while (machine.status() == MachineStatus.RUNNING) {
      if (replay) machine.step();
      else machine.stepWithoutRewindHistory();
    }
    assertEquals(MachineStatus.HALTED, machine.status());
    assertTrue(machine.snapshot().buffers().stream().filter(row -> !borrowed.contains(row.regionId()))
        .allMatch(row -> row.dropped()));
  }

  private static Program program(long kind, long first, long count, String setup, String shortColumn)
      throws Exception {
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_entry_products"));
    String source = """
        module example.entry_products;
        import wheeler.compiler.closure.source_entry_products;
        classical class EntryProducts {
          private const long CALLABLES = 4096;
          private const long PARAMETERS = 16384;
          private const long CALLABLE_COLUMNS = 6;
          private const long PARAMETER_COLUMNS = 2;
          private const long WORD_BYTES = 8;
          private const long ARENA_BYTES = (CALLABLES * CALLABLE_COLUMNS
            + PARAMETERS * PARAMETER_COLUMNS) * WORD_BYTES;
          private const long BUFFERS = CALLABLE_COLUMNS + PARAMETER_COLUMNS;
          state long phase = 0;
          state long kind = 0;
          state long selected = -1;
          state long accepted = 0;
          entry void main(borrow byteview input) {
            region arena = new region(/* bytes= */ ARENA_BYTES, /* allocations= */ BUFFERS);
            words starts = allocate(arena, CALLABLES);
            words lengths = allocate(arena, CALLABLES);
            words effects = allocate(arena, CALLABLES);
            words firstParameters = allocate(arena, CALLABLES);
            words counts = allocate(arena, CALLABLES);
            words results = allocate(arena, CALLABLES);
            words types = allocate(arena, PARAMETERS);
            words modes = allocate(arena, PARAMETERS);
            set(starts, 7, 2);
            set(lengths, 7, 4);
            set(effects, 7, 1);
            set(firstParameters, 7, PARAMETERS);
            set(starts, 8, 6);
            set(lengths, 8, 6);
            SETUP
            phase = 1;
            SourceEntryPlan result = bindSourceEntry(
              TARGET, FIRST, COUNT, input, starts, lengths, effects, firstParameters,
              counts, results, types, modes
            );
            kind = result.targetKind;
            selected = result.entryCallable;
            if (result.valid) { accepted = 1; }
            phase = 2;
            drop(modes);
            drop(types);
            drop(results);
            drop(counts);
            drop(firstParameters);
            drop(effects);
            drop(lengths);
            drop(starts);
            drop(arena);
          }
        }
        """.replace("SETUP", setup).replace("TARGET, FIRST, COUNT,",
            kind + ", " + first + ", " + count + ",");
    if (!shortColumn.isEmpty()) {
      String extent = shortColumn.equals("types") || shortColumn.equals("modes") ? "PARAMETERS" : "CALLABLES";
      String allocation = "words " + shortColumn + " = allocate(arena, " + extent;
      source = source.replace(allocation + ");", allocation + " - 1);");
    }
    modules.put("EntryProducts.w", source);
    return new WheelerCompiler().compileModuleFiles(modules, "example.entry_products");
  }
}
