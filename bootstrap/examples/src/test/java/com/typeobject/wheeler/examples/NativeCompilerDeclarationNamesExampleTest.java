package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Exact declaration-name publication before source leases disappear. */
final class NativeCompilerDeclarationNamesExampleTest {
  private static final String LEFT = """
      // module pretend.left; classical class Ghost {}
      module example.left;
      classical /* header */ class
      ActualLeft {
        public const long VALUE = 1;
      }
      """;
  private static final String RIGHT = """
      /* classical class Fake {} */
      module
      example.right;
      import example.left;
      classical class ActualRight {
        public const long VALUE = 2;
      }
      // classical class Last {}
      """;
  private static final String PREFIX = "outside source windows\n";
  private static final String GAP = "\nbetween source windows\n";

  @Test
  void publishesBothHeaderNamesAndLeavesEveryInactiveCellUntouched() throws Exception {
    Fixture fixture = fixture(RIGHT, 512, 512);
    VirtualMachine machine = fixture.machine();
    var initial = machine.snapshot();
    machine.run();
    assertEquals(1, machine.global("published"));
    assertEquals(2, machine.global("generation"));
    long[] expected = new long[2048];
    Arrays.fill(expected, -7);
    expected[0] = fixture.input().indexOf("example.left;");
    expected[1] = fixture.input().indexOf("example.right;");
    expected[512] = "example.left".length();
    expected[513] = "example.right".length();
    expected[1024] = fixture.input().indexOf("ActualLeft");
    expected[1025] = fixture.input().indexOf("ActualRight");
    expected[1536] = "ActualLeft".length();
    expected[1537] = "ActualRight".length();
    var output = ByteBuffer.wrap(machine.hostOutput()).order(ByteOrder.LITTLE_ENDIAN);
    long[] actual = new long[expected.length];
    for (int row = 0; row < actual.length; row++) {
      actual[row] = output.getLong();
    }
    assertArrayEquals(expected, actual);
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void rejectsTheSecondDeclarationWithoutPublishingTheFirstNames() throws Exception {
    for (String rejected : new String[] {
        RIGHT.replace("class ActualRight", "class 123"),
        RIGHT.replace("class ActualRight", "class \"ActualRight\""),
        RIGHT.replace("public const long VALUE = 2;", "public const long VALUE;"),
        RIGHT.substring(0, RIGHT.indexOf("ActualRight"))}) {
      assertUnpublished(fixture(rejected, 512, 512));
    }
  }

  @Test
  void rejectsNoncanonicalClassColumnCapacitiesBeforePublication() throws Exception {
    for (int[] capacities : new int[][] {{511, 512}, {513, 512}, {512, 511}, {512, 513}}) {
      assertUnpublished(fixture(RIGHT, capacities[0], capacities[1]));
    }
  }

  private static void assertUnpublished(Fixture fixture) {
    VirtualMachine machine = fixture.machine();
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
    var snapshot = machine.snapshot();
    int region = snapshot.regions().stream()
        .filter(row -> row.maxObjects() == 4 && row.maxBytes() == fixture.outputBytes())
        .findFirst().orElseThrow().id();
    var names = snapshot.buffers().stream().filter(row -> row.regionId() == region).toList();
    assertEquals(4, names.size());
    for (var column : names) {
      assertFalse(column.dropped());
      for (long cell : column.elements()) {
        assertEquals(-7, cell, "unpublished declaration name");
      }
    }
    assertArrayEquals(new byte[fixture.outputBytes()], machine.hostOutput());
  }

  private record Fixture(Program program, String input, int outputBytes) {
    VirtualMachine machine() {
      return VirtualMachine.withBinaryInput(
          program, input.getBytes(StandardCharsets.UTF_8), outputBytes);
    }
  }

  private static Fixture fixture(String right, int classStarts, int classLengths) throws Exception {
    String input = PREFIX + LEFT + GAP + right + "\noutside tail\n";
    int words = 1024 + classStarts + classLengths;
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.module_symbols"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.encoding"));
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("DeclarationNames.w", """
        module example.declaration_names;
        import wheeler.compiler.closure.module_symbols;
        import wheeler.compiler.closure.plan;
        import wheeler.compiler.encoding;
        classical class DeclarationNames {
          state long published = 0;
          state long generation = 0;

          private void initialize(borrow mut words column) {
            long row = 0;
            while (row < bufferLength(column)) limit 513 {
              set(column, row, -7);
              row += 1;
            }
          }

          private long emit(borrow mut words column, borrow mut bytes output, long cursor) {
            long row = 0;
            while (row < bufferLength(column)) limit 513 {
              cursor = writeSignedLittleEndian(output, cursor, column[row], 8);
              row += 1;
            }
            return cursor;
          }

          entry void main(borrow byteview archive, borrow mut bytes output) {
            region names = new region(NAME_BYTES, 4);
            words moduleStarts = allocate(names, 512);
            words moduleLengths = allocate(names, 512);
            words classStarts = allocate(names, CLASS_STARTS);
            words classLengths = allocate(names, CLASS_LENGTHS);
            initialize(moduleStarts);
            initialize(moduleLengths);
            initialize(classStarts);
            initialize(classLengths);
            region tables = new region(1300000, 20);
            words edgeTargets = allocate(tables, 3072);
            words firstImports = allocate(tables, 512);
            words importCounts = allocate(tables, 512);
            words importRanks = allocate(tables, 3072);
            words order = allocate(tables, 512);
            words sourceStarts = allocate(tables, 512);
            words sourceLengths = allocate(tables, 512);
            words firstSymbols = allocate(tables, 512);
            words symbolCounts = allocate(tables, 512);
            words importedCounts = allocate(tables, 512);
            words edgeCounts = allocate(tables, 3072);
            words owners = allocate(tables, 16384);
            words starts = allocate(tables, 16384);
            words lengths = allocate(tables, 16384);
            words kinds = allocate(tables, 16384);
            words visibilities = allocate(tables, 16384);
            words types = allocate(tables, 16384);
            words values = allocate(tables, 16384);
            words resolved = allocate(tables, 16384);
            set(order, 0, 0);
            set(order, 1, 1);
            set(edgeTargets, 0, 0);
            set(firstImports, 1, 0);
            set(importCounts, 1, 1);
            set(importRanks, 0, 0);
            set(sourceStarts, 0, LEFT_START);
            set(sourceLengths, 0, LEFT_LENGTH);
            set(sourceStarts, 1, RIGHT_START);
            set(sourceLengths, 1, RIGHT_LENGTH);
            CountedClosurePlan plan = new CountedClosurePlan(2, 0, 1, 1);
            CountedModuleSymbolPlan indexed = indexCountedModuleSymbols(
              archive, archive, plan, edgeTargets, firstImports, importCounts,
              importRanks, order, sourceStarts, sourceLengths, firstSymbols,
              symbolCounts, moduleStarts, moduleLengths, classStarts, classLengths,
              importedCounts, edgeCounts, owners, starts, lengths, kinds,
              visibilities, types, values, resolved
            );
            assert(indexed.moduleCount == 2);
            assert(indexed.peakActiveSources == 1);
            generation = indexed.finalGeneration;
            long cursor = emit(moduleStarts, output, 0);
            cursor = emit(moduleLengths, output, cursor);
            cursor = emit(classStarts, output, cursor);
            cursor = emit(classLengths, output, cursor);
            setOutputLength(output, cursor);
            published = 1;
            drop(resolved); drop(values); drop(types); drop(visibilities);
            drop(kinds); drop(lengths); drop(starts); drop(owners);
            drop(edgeCounts); drop(importedCounts); drop(symbolCounts); drop(firstSymbols);
            drop(sourceLengths); drop(sourceStarts); drop(order); drop(importRanks);
            drop(importCounts); drop(firstImports); drop(edgeTargets); drop(tables);
            drop(classLengths); drop(classStarts); drop(moduleLengths); drop(moduleStarts);
            drop(names);
          }
        }
        """.replace("NAME_BYTES", Integer.toString(words * 8))
        .replace("CLASS_STARTS", Integer.toString(classStarts))
        .replace("CLASS_LENGTHS", Integer.toString(classLengths))
        .replace("LEFT_START", Integer.toString(PREFIX.length()))
        .replace("LEFT_LENGTH", Integer.toString(LEFT.length()))
        .replace("RIGHT_START", Integer.toString(PREFIX.length() + LEFT.length() + GAP.length()))
        .replace("RIGHT_LENGTH", Integer.toString(right.length())));
    return new Fixture(new WheelerCompiler().compileModuleFiles(sources, "example.declaration_names"),
        input, words * 8);
  }
}
