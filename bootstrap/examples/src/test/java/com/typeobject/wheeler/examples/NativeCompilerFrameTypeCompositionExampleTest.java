package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Keeps complete frame admission separate from argument and signature capacities. */
final class NativeCompilerFrameTypeCompositionExampleTest {
  private static final int CODE_BYTES = 262_144;

  @Test
  void composesAll256TypeSlotsWithoutAnExtraSentinelIteration() throws Exception {
    assertComposition(64, "", 64, true, false);
  }

  @Test
  void rejectsUnconsumedExcessGapsAndDuplicateOriginsWithoutPublication() throws Exception {
    assertComposition(64, "set(loopTypes, 4096 + 64, 256); set(loopTypes, 8192 + 64, 1);",
        65, false, false);
    assertComposition(64, "set(loopTypes, 4096 + 63, 256);", 64, false, false);
    assertComposition(64, "set(directTypes, 4096, 0);", 64, false, false);
  }

  @Test
  void rewindsSmallCompleteAndRejectedTypeCompositions() throws Exception {
    assertComposition(1, "", 1, true, true);
    assertComposition(1, "set(directTypes, 4096, 0);", 1, false, true);
  }

  private static void assertComposition(int width, String mutation, int loopCount,
      boolean accepted, boolean rewind) throws Exception {
    VirtualMachine machine = new VirtualMachine(program(width, mutation, loopCount), new byte[0], CODE_BYTES);
    MachineSnapshot initial = machine.snapshot();
    if (rewind) {
      machine.run();
    } else {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    }
    assertEquals(accepted ? 1L : 0L, machine.global("valid"), mutation);
    assertEquals(accepted ? width * 4L : 0L, machine.global("publishedTypes"), mutation);
    byte[] expected = new byte[CODE_BYTES];
    if (accepted) {
      expected = Arrays.copyOf(NativeInstructionBytes.encode(List.of(Instruction.of(Opcode.RETURN))), CODE_BYTES);
    }
    assertArrayEquals(expected, machine.hostOutput(), mutation);
    if (rewind) {
      while (machine.historySize() > 0) { machine.rewindOne(); }
      assertEquals(initial, machine.snapshot(), mutation);
    }
  }

  private static Program program(int width, String mutation, int loopCount) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_source_composition"));
    sources.put("FrameTypes.w", """
        module example.frame_types;

        import wheeler.compiler.closure.callable_source_composition;

        classical class FrameTypes {
          private const long CODE_BYTES = 262144;
          private const long ROW_WORDS = 123456;
          private const long ROW_BYTES = ROW_WORDS * 8 + CODE_BYTES;
          private const long WIDTH = SELECTED_WIDTH;
          state long valid = 0;
          state long publishedTypes = 0;

          private void fillTypes(borrow mut words rows, long first) {
            long row = 0;
            while (row < WIDTH) limit 64 {
              long local = first + row;
              set(rows, 4096 + row, local);
              set(rows, 8192 + row, local % 2 + 1);
              row += 1;
            }
          }

          entry void main(borrow utf8 input, borrow mut bytes output) {
            assert(bufferLength(input) == 0);
            region arena = new region(/* bytes= */ ROW_BYTES, /* allocations= */ 15);
            words statements = allocate(arena, /* length= */ 28672);
            words directRows = allocate(arena, /* length= */ 28672);
            words callStatements = allocate(arena, /* length= */ 256);
            words callWindows = allocate(arena, /* length= */ 768);
            words loopRows = allocate(arena, /* length= */ 2304);
            words loopWindows = allocate(arena, /* length= */ 768);
            words signatureTypes = allocate(arena, /* length= */ 12288);
            words directTypes = allocate(arena, /* length= */ 12288);
            words callTypes = allocate(arena, /* length= */ 12288);
            words loopTypes = allocate(arena, /* length= */ 12288);
            words results = allocate(arena, /* length= */ 64);
            words returns = allocate(arena, /* length= */ 192);
            words callables = allocate(arena, /* length= */ 320);
            words types = allocate(arena, /* length= */ 12288);
            bytes emptyCode = allocateBytes(arena, CODE_BYTES);
            fillTypes(signatureTypes, 0);
            fillTypes(directTypes, WIDTH);
            fillTypes(callTypes, WIDTH * 2);
            fillTypes(loopTypes, WIDTH * 3);
            set(returns, 0, 1);
            long row = 0;
            while (row < 12288) limit 12288 {
              set(types, row, -7);
              if (row < 320) { set(callables, row, -9); }
              row += 1;
            }
            MUTATION
            CallableSourceCompositionPlan plan = composeCallableSourceProducts(
              1, 0, statements,
              0, directRows, emptyCode,
              0, callStatements, callWindows, emptyCode,
              0, loopRows, loopWindows, emptyCode,
              WIDTH, signatureTypes,
              WIDTH, directTypes,
              WIDTH, callTypes,
              LOOP_TYPE_COUNT, loopTypes,
              results, returns, callables, types, output
            );
            if (plan.valid) { valid = 1; }
            publishedTypes = plan.typeCount;
            row = 0;
            while (row < 12288) limit 12288 {
              long expected = -7;
              if (plan.valid) {
                long column = row / 4096;
                long local = row % 4096;
                if (local < WIDTH * 4) {
                  expected = 0;
                  if (column == 1) { expected = local; }
                  if (column == 2) { expected = local % 2 + 1; }
                }
              }
              assert(types[row] == expected);
              if (row < 320) {
                long expectedCallable = -9;
                if (plan.valid) {
                  if (row == 0) { expectedCallable = 0; }
                  if (row == 64) { expectedCallable = 8; }
                  if (row == 128) { expectedCallable = 1; }
                  if (row == 192) { expectedCallable = 0; }
                  if (row == 256) { expectedCallable = WIDTH * 4; }
                }
                assert(callables[row] == expectedCallable);
              }
              row += 1;
            }
            drop(emptyCode);
            drop(types);
            drop(callables);
            drop(returns);
            drop(results);
            drop(loopTypes);
            drop(callTypes);
            drop(directTypes);
            drop(signatureTypes);
            drop(loopWindows);
            drop(loopRows);
            drop(callWindows);
            drop(callStatements);
            drop(directRows);
            drop(statements);
            drop(arena);
          }
        }
        """.replace("SELECTED_WIDTH", Integer.toString(width))
            .replace("MUTATION", mutation).replace("LOOP_TYPE_COUNT", Integer.toString(loopCount)));
    return new WheelerCompiler().compileModuleFiles(sources, "example.frame_types");
  }
}
