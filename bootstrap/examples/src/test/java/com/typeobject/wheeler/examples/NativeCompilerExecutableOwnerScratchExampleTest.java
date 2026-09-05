package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferKind;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Checks reusable classifier scratch without spending four buffer IDs per source lease. */
final class NativeCompilerExecutableOwnerScratchExampleTest {
  private static final String COMMENT = "// café 𝄞\n";
  private static final int SOURCE_BYTES = 144;

  @Test
  void classifiesFiveHundredTwelveDistinctSourcesWithOneTokenArena() throws Exception {
    var machine = machine(512, -1);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertArrayEquals(expected(512), machine.hostOutput());
    assertEquals(1, machine.global("published"));
    // Two host buffers, five caller columns, five pass columns, and one lease per module.
    assertEquals(512 + 12, machine.snapshot().buffers().size());
  }

  @Test
  void preservesMixedClassificationAndRewindsEveryScratchMutation() throws Exception {
    var machine = machine(3, -1);
    var initial = machine.snapshot();
    machine.run();
    assertArrayEquals(expected(3), machine.hostOutput());
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void rejectsFirstAndLaterHeadersWithoutPublishingAnyOwnerAndRewinds() throws Exception {
    for (int rejected : new int[] {0, 2}) {
      Map<String, String> sources = sources(3, rejected);
      assertThrows(CompilerException.class, () -> new WheelerCompiler().compileLibraryModuleFiles(
          sources, "example.n002"));
      var machine = machine(3, rejected);
      var initial = machine.snapshot();
      assertThrows(VmTrap.class, machine::run);
      assertEquals(0, machine.global("published"));
      assertArrayEquals(new byte[11], machine.hostOutput());
      var owners = machine.snapshot().buffers().stream()
          .filter(buffer -> buffer.kind() == BufferKind.WORDS && buffer.length() == 11)
          .findFirst().orElseThrow();
      assertEquals(Collections.nCopies(11, 91L), owners.elements());
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    }
  }

  @Test
  void rejectsEveryShortScratchColumnBeforeChangingAnyCellAndRewinds() throws Exception {
    var machine = new VirtualMachine(shortScratchProgram(),
        sources(1, -1).values().iterator().next().getBytes(StandardCharsets.UTF_8));
    var initial = machine.snapshot();
    machine.run();
    assertEquals(1, machine.global("checked"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }

  private static VirtualMachine machine(int count, int rejected) throws Exception {
    ByteArrayOutputStream archive = new ByteArrayOutputStream();
    for (String source : sources(count, rejected).values()) {
      byte[] bytes = source.getBytes(StandardCharsets.UTF_8);
      byte[] row = new byte[SOURCE_BYTES];
      Arrays.fill(row, (byte) ' ');
      System.arraycopy(bytes, 0, row, 0, bytes.length);
      archive.writeBytes(row);
    }
    return VirtualMachine.withBinaryInput(program(count), archive.toByteArray(), count + 8);
  }

  private static Map<String, String> sources(int count, int rejected) {
    Map<String, String> sources = new LinkedHashMap<>();
    for (int owner = 0; owner < count; owner++) {
      String member = switch (owner % 3) {
        case 0 -> "public long value() { return 1; }";
        case 1 -> "";
        default -> "public const long VALUE = 1;";
      };
      String keyword = owner == rejected ? "modumF" : "module";
      sources.put("Module%03d.w".formatted(owner), COMMENT + keyword
          + " example.n%03d; classical class Owner { %s }".formatted(owner, member));
    }
    return sources;
  }

  private static byte[] expected(int count) {
    byte[] expected = new byte[count + 8];
    Arrays.fill(expected, (byte) 91);
    for (int owner = 0; owner < count; owner++) {
      expected[owner] = (byte) (owner % 3 == 0 ? 1 : 0);
    }
    return expected;
  }

  private static Program shortScratchProgram() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.graphs.executable_owner_kinds"));
    sources.put("ShortScratch.w", """
        module example.short_scratch;
        import wheeler.compiler.graphs.executable_owner_kinds;
        classical class ShortScratch {
          state long checked = 0;
          entry void main(borrow utf8 source) {
            region arena = new region(/* bytes= */ 98400, /* allocations= */ 5);
            words kinds = allocate(arena, 4096);
            words starts = allocate(arena, 4096);
            words lengths = allocate(arena, 4096);
            words name = allocate(arena, 2);
            words shortColumn = allocate(arena, 1);
            fillSentinels(kinds);
            fillSentinels(starts);
            fillSentinels(lengths);
            fillSentinels(name);
            fillSentinels(shortColumn);
            ExecutableOwnerKind shortKinds = classifyExecutableOwnerWithScratch(
              source, shortColumn, starts, lengths, name
            );
            assert(shortKinds.valid == false);
            ExecutableOwnerKind shortStarts = classifyExecutableOwnerWithScratch(
              source, kinds, shortColumn, lengths, name
            );
            assert(shortStarts.valid == false);
            ExecutableOwnerKind shortLengths = classifyExecutableOwnerWithScratch(
              source, kinds, starts, shortColumn, name
            );
            assert(shortLengths.valid == false);
            ExecutableOwnerKind shortName = classifyExecutableOwnerWithScratch(
              source, kinds, starts, lengths, shortColumn
            );
            assert(shortName.valid == false);
            requireSentinels(kinds);
            requireSentinels(starts);
            requireSentinels(lengths);
            requireSentinels(name);
            requireSentinels(shortColumn);
            checked = 1;
            drop(shortColumn);
            drop(name);
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(arena);
          }
          private void fillSentinels(borrow mut words rows) {
            long row = 0;
            while (row < bufferLength(rows)) limit 4096 {
              set(rows, row, 91);
              row += 1;
            }
          }
          private void requireSentinels(borrow mut words rows) {
            long row = 0;
            while (row < bufferLength(rows)) limit 4096 {
              assert(rows[row] == 91);
              row += 1;
            }
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.short_scratch");
  }

  private static Program program(int count) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.plan"));
    sources.put("OwnerScratch.w", """
        module example.owner_scratch;
        import wheeler.compiler.closure.plan;
        classical class OwnerScratch {
          state long published = 0;
          entry void main(borrow byteview input, borrow mut bytes output) {
            region columns = new region(/* bytes= */ COLUMN_BYTES, /* allocations= */ 5);
            words nameStarts = allocate(columns, COUNT);
            words nameLengths = allocate(columns, COUNT);
            words sourceStarts = allocate(columns, COUNT);
            words sourceLengths = allocate(columns, COUNT);
            words owners = allocate(columns, COUNT + 8);
            long owner = 0;
            while (owner < COUNT) limit 512 {
              long start = owner * SOURCE_BYTES;
              set(nameStarts, owner, start + NAME_OFFSET);
              set(nameLengths, owner, 12);
              set(sourceStarts, owner, start);
              set(sourceLengths, owner, SOURCE_BYTES);
              owner += 1;
            }
            owner = 0;
            while (owner < COUNT + 8) limit 520 {
              set(owners, owner, 91);
              owner += 1;
            }
            CountedClosurePlan plan = new CountedClosurePlan(COUNT, 0, 0, COUNT - 1);
            classifyClosureExecutableOwners(
              input, input, plan, nameStarts, nameLengths, sourceStarts, sourceLengths, owners
            );
            owner = 0;
            while (owner < COUNT + 8) limit 520 {
              setByte(output, owner, owners[owner]);
              owner += 1;
            }
            published = 1;
            drop(owners);
            drop(sourceLengths);
            drop(sourceStarts);
            drop(nameLengths);
            drop(nameStarts);
            drop(columns);
          }
        }
        """.replace("COLUMN_BYTES", Integer.toString((count * 5 + 8) * 8))
        .replace("COUNT", Integer.toString(count))
        .replace("SOURCE_BYTES", Integer.toString(SOURCE_BYTES))
        .replace("NAME_OFFSET", Integer.toString(COMMENT.getBytes(StandardCharsets.UTF_8).length + 7)));
    return new WheelerCompiler().compileModuleFiles(sources, "example.owner_scratch");
  }
}
