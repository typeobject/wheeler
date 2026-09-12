package com.typeobject.wheeler.examples.calls;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Checks exact call destinations, whole copied-name windows, input preservation, and replay. */
final class NativeDirectCallDestinationsExampleTest {
  private static final List<String> NAMES = List.of("Zulu", "Alpha", "Later", "g3", "g4", "g5", "g6", "g7");
  private static final int GLOBALS = 8;
  private static final int GLOBAL_COLUMNS = 4;
  private static final int TOKENS = 4096;
  private static final int STATEMENTS = 4096;
  private static final int STATEMENT_COLUMNS = 7;
  private static final int LOCAL_COLUMNS = 2;
  private static final int VALUES = 1024;
  private static final int VALUE_COLUMNS = 7;

  @Test
  void selectsOnlyJoinedDestinationsAndKeepsEveryInputCell() throws Exception {
    check("remote(value);", 0, 0, 0, "", true, false, 0, 0);
    check("return remote(value);", 3, 0, 0, "", true, false, 3, 0);
    check("return remote(value);", 4, 0, 0, "", true, false, 4, 0);
    check("long result = remote(value);", 1, 0, 0, "", true, false, 1, 0);
    check("boolean result = remote(value);", 2, 0, 0, "", true, false, 2, 0);
    check("Alpha = dep.alpha::remote(value);", 3, 0, 0, "", true, false, 9, 1);
    check("Zulu = remote(value);", 3, 0, 0, "", true, false, 9, 0);
    check("g7 = remote(value);", 3, 0, 0, "", true, false, 9, GLOBALS - 1);
  }

  @Test
  void rejectsUnjoinedResultsReversibleStoresAndAmbiguousDestinations() throws Exception {
    for (int kind : new int[] {0, 1, 2, 4, 5, 6, 7, 8, 9, 10}) {
      check("Alpha = remote(value);", kind, 0, 0, "", false, false, 0, 0);
    }
    check("Alpha = remote(value);", 3, 1, 0, "", false, false, 0, 0);
    check("Missing = remote(value);", 3, 0, 0, "", false, false, 0, 0);
    check("Alpha = remote(value);", 3, 0, 1, """
        set(values, 0, 0);
        set(values, VALUE_COUNT, starts[0]);
        set(values, VALUE_COUNT * 2, lengths[0]);
        """, false, false, 0, 0);
    check("remote(value);", 3, 0, 0, "", false, false, 0, 0);
    check("return remote(value);", 1, 0, 0, "", false, false, 0, 0);
    check("boolean result = remote(value);", 1, 0, 0, "", false, false, 0, 0);
    check("long result = remote(value);", 2, 0, 0, "", false, false, 0, 0);
    check("Alpha = remote(value) value;", 3, 0, 0, "", false, false, 0, 0);
  }

  @Test
  void rejectsMalformedLaterNamesAndValueWindowsBeforeReturningABinding() throws Exception {
    for (String mutation : List.of(
        "set(globals, 2, -1);",
        "set(globals, GLOBAL_COUNT + 2, 0);",
        "set(globals, GLOBAL_COUNT + 2, 9223372036854775807);",
        "setByte(names, 9, 0);",
        "set(globals, 2, 4); set(globals, GLOBAL_COUNT + 2, 5);")) {
      check("Alpha = remote(value);", 3, 0, 0, mutation, false, true, 0, 0);
    }
    check("Alpha = remote(value);", 3, 0, -1, "", false, true, 0, 0);
    check("Alpha = remote(value);", 3, 0, VALUES + 1, "", false, true, 0, 0);
  }

  private static void check(String statement, int kind, int reversible, int valueCount,
      String mutation, boolean valid, boolean trap, int expectedKind, int expectedOperand) throws Exception {
    String prefix = "// café 𝄞\n";
    String input = prefix + statement;
    int callStart = input.substring(0, input.indexOf("remote")).getBytes(StandardCharsets.UTF_8).length;
    String text = String.join("", NAMES);
    var namesSetup = new StringBuilder();
    int start = 0;
    for (int ordinal = 0; ordinal < NAMES.size(); ordinal++) {
      namesSetup.append("set(globals, ").append(ordinal).append(", ").append(start).append(");\n")
          .append("set(globals, GLOBAL_COUNT + ").append(ordinal).append(", ")
          .append(NAMES.get(ordinal).length()).append(");\n");
      start += NAMES.get(ordinal).length();
    }
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.closure.direct_call_destinations"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.module_linker"));
    sources.put("Driver.w", """
        module example.call_destinations;
        import wheeler.compiler.closure.direct_call_destinations;
        import wheeler.compiler.module_linker;
        classical class Driver {
          const long TOKEN_COUNT = %d;
          const long STATEMENT_COUNT = %d;
          const long STATEMENT_COLUMNS = %d;
          const long LOCAL_COLUMNS = %d;
          const long VALUE_COUNT = %d;
          const long VALUE_COLUMNS = %d;
          const long GLOBAL_COUNT = %d;
          const long GLOBAL_COLUMNS = %d;
          const long NAME_BYTES = %d;
          const long WORD_BYTES = %d;
          const long WORDS = TOKEN_COUNT * 3 + STATEMENT_COUNT * STATEMENT_COLUMNS
            + STATEMENT_COUNT * LOCAL_COLUMNS + STATEMENT_COUNT + VALUE_COUNT * VALUE_COLUMNS
            + GLOBAL_COUNT * GLOBAL_COLUMNS;
          const long ARENA_BYTES = WORDS * WORD_BYTES + NAME_BYTES;
          const long BUFFERS = 3 + 3 + 1 + 1 + 1;
          state long prepared = 0;
          state long completed = 0;
          state long valid = -1;
          state long kind = -1;
          state long operand = -1;
          entry void main(borrow utf8 source) {
            region arena = new region(ARENA_BYTES, BUFFERS);
            words kinds = allocate(arena, TOKEN_COUNT);
            words starts = allocate(arena, TOKEN_COUNT);
            words lengths = allocate(arena, TOKEN_COUNT);
            words statements = allocate(arena, STATEMENT_COUNT * STATEMENT_COLUMNS);
            words locals = allocate(arena, STATEMENT_COUNT * LOCAL_COLUMNS);
            words physical = allocate(arena, STATEMENT_COUNT);
            words values = allocate(arena, VALUE_COUNT * VALUE_COLUMNS);
            words globals = allocate(arena, GLOBAL_COUNT * GLOBAL_COLUMNS);
            bytes names = allocateBytes(arena, NAME_BYTES);
            writeAscii(names, 0, "%s");
            %s
            long count = scanSemanticTokens(source, kinds, starts, lengths);
            assert(-1 < count);
            %s
            prepared = 1;
            DirectCallDestination result = resolveDirectCallDestination(
              source, names, GLOBAL_COUNT, 0, globals, 0, count, kinds, starts, lengths,
              %d, %d, 1, %d, %d, 0, 0, 1, statements, locals, physical, %d, values);
            valid = 0; if (result.valid) { valid = 1; }
            kind = result.kind; operand = result.operand;
            completed = 1;
            drop(names); drop(globals); drop(values); drop(physical); drop(locals);
            drop(statements); drop(lengths); drop(starts); drop(kinds); drop(arena);
          }
        }
        """.formatted(TOKENS, STATEMENTS, STATEMENT_COLUMNS, LOCAL_COLUMNS, VALUES, VALUE_COLUMNS,
            GLOBALS, GLOBAL_COLUMNS, text.length(), Long.BYTES, text, namesSetup, mutation,
            statement.getBytes(StandardCharsets.UTF_8).length, callStart, kind, reversible, valueCount));
    var program = new WheelerCompiler().compileModuleFiles(sources, "example.call_destinations");
    var machine = new VirtualMachine(program, input.getBytes(StandardCharsets.UTF_8));
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    var before = machine.snapshot();
    run(machine, trap);
    var after = machine.snapshot();
    assertEquals(before.buffers(), after.buffers());
    assertEquals(before.regions(), after.regions());
    assertEquals(trap ? -1 : valid ? 1 : 0, machine.global("valid"));
    if (valid) {
      assertEquals(expectedKind, machine.global("kind"));
      assertEquals(expectedOperand, machine.global("operand"));
    }
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
    run(machine, trap);
    assertEquals(after, machine.snapshot());
    if (!trap) {
      while (machine.status() != MachineStatus.HALTED) machine.step();
      int borrowed = before.buffers().getFirst().regionId();
      assertTrue(machine.snapshot().buffers().stream().filter(b -> b.regionId() != borrowed).allMatch(b -> b.dropped()));
      assertTrue(machine.snapshot().regions().stream().filter(r -> r.id() != borrowed).allMatch(r -> r.dropped()));
    }
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
  }

  private static void run(VirtualMachine machine, boolean trap) {
    Runnable phase = () -> { while (machine.global("completed") == 0) machine.step(); };
    if (trap) assertThrows(VmTrap.class, phase::run);
    else phase.run();
  }
}
