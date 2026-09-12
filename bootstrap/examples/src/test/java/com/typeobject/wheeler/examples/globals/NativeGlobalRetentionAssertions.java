package com.typeobject.wheeler.examples.globals;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import com.typeobject.wheeler.examples.CoreSources;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.TreeSet;

/** Checks native retention of a source-compiled artifact against independently named globals. */
public final class NativeGlobalRetentionAssertions {
  private static final int CAPACITY = 4096;
  private static final int COLUMNS = 5;
  private static final int ROWS = CAPACITY * COLUMNS;
  private static final int PREFIX = 2;
  private static final int OWNER = 7;
  private static final int STRING_BASE = 11;
  private static final int SENTINEL = 211;
  private static final long LOW_MASK = (1L << Integer.SIZE) - 1;

  private NativeGlobalRetentionAssertions() {}

  /** Retains complete rows, preserves all inactive cells, and replays the intake phase. */
  public static void assertRetained(byte[] artifact, Program oracle) throws Exception {
    assertTrue(oracle.recordTypes().isEmpty());
    assertTrue(oracle.variantTypes().isEmpty());
    var names = new TreeSet<String>();
    names.add(oracle.name());
    oracle.functions().forEach(function -> names.add(function.name()));
    oracle.globals().forEach(global -> names.add(global.name()));
    oracle.proofCertificates().forEach(proof -> names.add(proof.name()));
    var ordered = new ArrayList<>(names);
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_global_products"));
    CoreSources.addBinaryClosure(modules);
    modules.put("Driver.w", """
        module example.global_retention;
        import wheeler.compiler.closure.compiled_global_products;
        classical class Driver {
          const long CAPACITY = %d;
          const long COLUMNS = %d;
          const long ROWS = CAPACITY * COLUMNS;
          const long WORD_BYTES = %d;
          const long ARENA_BYTES = ROWS * WORD_BYTES;
          state long prepared = 0;
          state long count = -1;
          state long completed = 0;
          entry void main(borrow byteview artifact) {
            region arena = new region(ARENA_BYTES, /* buffers= */ 1);
            words globals = allocate(arena, ROWS);
            long row = 0;
            while (row < ROWS) limit ROWS {
              set(globals, row, %d); row += 1;
            }
            prepared = 1;
            count = appendCompiledGlobalProducts(
              artifact, bufferLength(artifact), %d, %d, %d, %d, globals);
            completed = 1;
            drop(globals); drop(arena);
          }
        }
        """.formatted(CAPACITY, COLUMNS, Long.BYTES, SENTINEL, OWNER, STRING_BASE,
            ordered.size(), PREFIX));
    Program program = new WheelerCompiler().compileModuleFiles(modules, "example.global_retention");
    VirtualMachine machine = VirtualMachine.withBinaryInput(program, artifact);
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    var before = machine.snapshot();
    while (machine.global("completed") == 0) machine.step();
    var after = machine.snapshot();
    assertEquals(PREFIX + oracle.globals().size(), machine.global("count"));
    long[] expected = new long[ROWS];
    Arrays.fill(expected, SENTINEL);
    for (int global = 0; global < oracle.globals().size(); global++) {
      var value = oracle.globals().get(global);
      int target = PREFIX + global;
      expected[target] = STRING_BASE + ordered.indexOf(value.name());
      expected[CAPACITY + target] = ValueType.SIGNED.code();
      expected[CAPACITY * 2 + target] = value.initialValue() & LOW_MASK;
      expected[CAPACITY * 3 + target] = value.initialValue() >>> Integer.SIZE;
      expected[CAPACITY * 4 + target] = OWNER;
    }
    var retained = after.buffers().stream().filter(buffer -> buffer.length() == ROWS)
        .findFirst().orElseThrow();
    assertArrayEquals(expected, retained.elements().stream().mapToLong(Long::longValue).toArray());
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
    while (machine.global("completed") == 0) machine.step();
    assertEquals(after, machine.snapshot());
    while (machine.status() != MachineStatus.HALTED) machine.step();
    assertTrue(machine.snapshot().buffers().get(retained.id()).dropped());
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
  }
}
