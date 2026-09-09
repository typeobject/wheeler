package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Checks scoped row selection, not carrier metadata certification or owner-event schemas. */
final class NativeCompilerFrameLocalProjectionExampleTest {
  @Test
  void selectsTheCompleteOwnerFunctionAndFrameLocalKey() throws Exception {
    String rows = """
        set(rows, 0, 1); set(rows, 16384, 2); set(rows, 32768, 3); set(rows, 49152, 99);
        set(rows, 1, 1); set(rows, 16385, 2); set(rows, 32769, 4); set(rows, 49153, 77);
        set(rows, 2, 1); set(rows, 16386, 3); set(rows, 32770, 3);
        set(rows, 3, 2); set(rows, 16387, 2); set(rows, 32771, 3);
        """;
    check(1, 2, 3, 4, 65536, rows, 0, false);
    check(1, 2, 4, 4, 65536, rows, 1, false);
    check(1, 3, 3, 4, 65536, rows, 2, false);
    check(2, 2, 3, 4, 65536, rows, 3, false);
    check(1, 2, -1, 4, 65536, rows, -1, false);
    check(1, 2, 5, 4, 65536, rows, -1, false);
  }

  @Test
  void distinguishesMissingAndDuplicateKeysWithoutChoosingATarget() throws Exception {
    check(0, 0, 0, 0, 1, "", -1, false);
    check(0, 0, 0, 1, 65536, "set(rows, 49152, 4095);", 0, false);
    check(0, 0, 0, 2, 65536,
        "set(rows, 49152, 4095); set(rows, 49153, 0);", -2, false);
  }

  @Test
  void reachesTheLastCountedRowWithoutReadingTheOpaqueTargetColumn() throws Exception {
    String rows = """
        set(rows, 16383, 511);
        set(rows, 32767, 63);
        set(rows, 49151, 255);
        set(rows, 65535, -9223372036854775808);
        """;
    check(511, 63, 255, 16384, 65536, rows, 16383, false);
  }

  @Test
  void checksOwnerCountsAndNonemptyBackingBeforeLookup() throws Exception {
    for (long owner : new long[] {-1, 512, Long.MAX_VALUE}) {
      check(owner, 0, 0, 0, 1, "", -1, true);
    }
    for (long count : new long[] {-1, 16385, Long.MAX_VALUE}) {
      check(0, 0, 0, count, 65536, "", -1, true);
    }
    for (int capacity : new int[] {1, 65535, 65537}) {
      check(0, 0, 0, 1, capacity, "", -1, true);
    }
  }

  private static void check(long owner, long function, long local, long count, int capacity,
      String setup, long expected, boolean trap) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.frame_local_projections"));
    sources.put("ScopedFrameProbe.w", """
        module example.scoped_frame_probe;
        import wheeler.compiler.closure.frame_local_projections;
        classical class ScopedFrameProbe {
          state long prepared = 0;
          state long finished = 0;
          state long selected = -9;
          entry void main() {
            region caller = new region(/* bytes= */ 524296, /* allocations= */ 1);
            words rows = allocate(caller, %d);
            // Sparse canary. The complete immutable snapshot is compared below.
            set(rows, bufferLength(rows) - 1, 97);
            %s
            prepared = 1;
            selected = scopedFrameLocalProjection(%d, %d, %d, %d, rows);
            finished = 1;
            drop(rows);
            drop(caller);
          }
        }
        """.formatted(capacity, setup, owner, function, local, count));
    var program = new WheelerCompiler().compileModuleFiles(sources, "example.scoped_frame_probe");
    var machine = new VirtualMachine(program);
    var initial = machine.snapshot();
    while (machine.global("prepared") == 0) { machine.step(); }
    var before = machine.snapshot();
    if (trap) {
      assertThrows(VmTrap.class, () -> {
        while (machine.global("finished") == 0) { machine.step(); }
      });
      assertEquals(-9, machine.global("selected"));
    } else {
      while (machine.global("finished") == 0) { machine.step(); }
      assertEquals(expected, machine.global("selected"));
    }
    var after = machine.snapshot();
    assertEquals(before.buffers(), after.buffers());
    assertEquals(before.regions(), after.regions());
    if (!trap) { machine.run(); }
    while (machine.historySize() > 0) { machine.rewindOne(); }
    assertEquals(initial, machine.snapshot());
  }
}
