package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/** Exact selector publication and count-commit evidence for retained source collections. */
final class NativeCompilerPackageManifestSourceCollectionExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_target_source_collection";
  private static final Pattern SELECTOR = Pattern.compile("(?m)^\\s*- \"([^\"]*)\"\\s*$");

  @Test
  void commitsOnlyNonemptyOrderedRootCoveringCollections() throws Exception {
    Fixture fixture = fixture(7, 0, 1);
    fixture.assertRows(target("src/App.w", "src/App.w", "src/Helper.w"), 2, 2, 2, true);
    fixture.assertRows(target("src/App.w", "src/Aardvark.w", "src/App.w"), 2, 2, 2);
    fixture.assertRows(target("src/App.w", "src"), 1, 1, 1);
    fixture.assertRows("// café 𝄞\n" + target("src/App.w", "src/App.w"), 1, 1, 1);
    fixture.assertRows(target("src/App.w"), -1, 0, 0);
    fixture.assertRows(target("src/App.w", "src/Helper.w"), -1, 0, 1);
    fixture.assertRows(target("src/App.w", "src/App.w", "src/App.w"), -1, 0, 1);
    fixture.assertRows(target("src/App.w", "src/Helper.w", "src/App.w"), -1, 0, 1);
    fixture.assertRows(target("src/App.w", "../App.w"), -1, 0, 0);
    fixture.assertRows(target("src/App.w", "src/App.w", "../Helper.w"), -1, 0, 1);
    fixture.assertRows(target("src/App.w", "src/App.w")
        .replace("  test: false", "    -\n  test: false"), -1, 0, 1);
    fixture.assertRows(target("src/App.w", "src/App.w")
        .replace("    - \"src/App.w\"", "    - App"), -1, 0, 0);
    // List completion does not admit the target's required test field.
    fixture.assertRows(target("src/App.w", "src/App.w")
        .replace("  test: false\n", ""), 1, 1, 1);
  }

  @Test
  void respectsCompleteRowsAndPreservesEarlierStorage() throws Exception {
    String two = target("src/App.w", "src/App.w", "src/Helper.w");
    fixture(4, 0, 1).assertRows(two, 2, 2, 2);
    fixture(3, 0, 1).assertRows(two, -1, 0, 1);
    fixture(1, 0, 1).assertRows(two, -1, 0, 0);
    fixture(9, 2, 1).assertRows(two, 4, 4, 2);
    fixture(7, 2, 1).assertRows(two, -1, 2, 1);
    for (long offset : new long[] {-1, Long.MIN_VALUE, Long.MAX_VALUE}) {
      fixture(7, offset, 1).assertRows(two, -1, offset, 0);
    }
  }

  @Test
  void resetsOrderingAndCoverageBetweenTargets() throws Exception {
    Fixture fixture = fixture(7, 0, 2);
    String first = target("z/Z.w", "z/Z.w");
    fixture.assertRows(first + target("a/A.w", "a/A.w"), 2, 2, 2);
    fixture.assertRows(first + target("a/A.w", "a/B.w"), -1, 1, 2);
    fixture.assertRows(first + target("a/A.w"), -1, 1, 1);
  }

  @Test
  void admitsTheLastBoundedRowAndRejectsTheFirstExcessWithoutTrapping() throws Exception {
    String[] selectors = new String[1025];
    for (int row = 0; row < selectors.length; row++) {
      selectors[row] = "src/%04d.w".formatted(row);
    }
    Fixture fixture = fixture(2053, 0, 1);
    fixture.assertRows(target(selectors[0], Arrays.copyOf(selectors, 1024)), 1024, 1024, 1024);
    fixture.assertRows(target(selectors[0], selectors), -1, 0, 1024);
  }

  private record Fixture(Program program, int slots, long offset) {
    void assertRows(String source, long result, long committed, int published) {
      assertRows(source, result, committed, published, false);
    }

    void assertRows(String source, long result, long committed, int published, boolean rewind) {
      VirtualMachine machine = new VirtualMachine(
          program, source.getBytes(StandardCharsets.UTF_8), slots * 8);
      var initial = machine.snapshot();
      if (rewind) {
        machine.run();
      } else {
        CompilerMachineRunner.runWithoutRewindHistory(machine);
      }
      assertEquals(result, machine.global("result"), source);
      assertEquals(committed, machine.global("committed"), source);
      long[] expected = new long[slots];
      Arrays.fill(expected, -7);
      var selectors = SELECTOR.matcher(source);
      for (int row = 0; row < published; row++) {
        if (!selectors.find()) {
          throw new AssertionError("missing admitted selector");
        }
        int base = Math.toIntExact((offset + row) * 2);
        expected[base] = source.substring(0, selectors.start(1)).getBytes(StandardCharsets.UTF_8).length;
        expected[base + 1] = selectors.group(1).getBytes(StandardCharsets.UTF_8).length;
      }
      long[] actual = new long[slots];
      ByteBuffer bytes = ByteBuffer.wrap(machine.hostOutput()).order(ByteOrder.LITTLE_ENDIAN);
      for (int index = 0; index < slots; index++) {
        actual[index] = bytes.getLong();
      }
      assertArrayEquals(expected, actual, source);
      if (rewind) {
        while (machine.historySize() > 0) {
          machine.rewindOne();
        }
        assertEquals(initial, machine.snapshot());
      }
    }
  }

  private static Fixture fixture(int slots, long offset, int collections) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.encoding"));
    sources.put("Scanner.w", CompilerSources.read("lexer/Scanner.w"));
    sources.put("SourceCollection.w", """
        module example.source_collection;
        import wheeler.compiler.encoding;
        import wheeler.compiler.packages.manifest_target_coordinates;
        import wheeler.compiler.packages.manifest_target_source_collection;
        import wheeler.lexer.scanner;
        classical class SourceCollection {
          state long result = -9;
          state long committed = 0;
          entry void main(borrow utf8 source, borrow mut bytes output) {
            region arena = new region(ARENA_BYTES, 4);
            words kinds = allocate(arena, 4096);
            words starts = allocate(arena, 4096);
            words lengths = allocate(arena, 4096);
            words rows = allocate(arena, SLOTS);
            long count = 0;
            ScanResult scanned = scan(source, kinds, starts, lengths);
            match (scanned) {
              case ScanResult.Value(long tokenCount) {
                count = tokenCount;
              }
              case ScanResult.Error(ScanDiagnostic diagnostic) {
                assert(false);
              }
            }
            long cell = 0;
            while (cell < SLOTS) limit SLOTS {
              set(rows, cell, -7);
              cell += 1;
            }
            long cursor = 0;
            if (kinds[0] == 4) {
              cursor = 1;
            }
            committed = OFFSET;
            long collection = 0;
            boolean reading = true;
            while (reading) limit 2 {
              result = manifestTargetSourceCollectionProduct(
                source, kinds, starts, lengths, count, cursor, rows, committed
              );
              if (result < 0) {
                reading = false;
              } else {
                long sourceCount = result - committed;
                long tail = manifestTargetSourceTailToken(cursor, sourceCount);
                cursor = manifestTargetNextToken(tail);
                committed = result;
                collection += 1;
                if (collection == COLLECTIONS) {
                  reading = false;
                }
              }
            }
            cell = 0;
            while (cell < SLOTS) limit SLOTS {
              long nextByte = writeSignedLittleEndian(output, cell * 8, rows[cell], 8);
              assert(nextByte == (cell + 1) * 8);
              cell += 1;
            }
            setOutputLength(output, SLOTS * 8);
            drop(rows);
            drop(lengths);
            drop(starts);
            drop(kinds);
            drop(arena);
          }
        }
        """.replace("ARENA_BYTES", Integer.toString((12288 + slots) * 8))
        .replace("SLOTS", Integer.toString(slots))
        .replace("OFFSET", offset == Long.MIN_VALUE ? "(-9223372036854775807 - 1)" : Long.toString(offset))
        .replace("COLLECTIONS", Integer.toString(collections)));
    return new Fixture(new WheelerCompiler().compileModuleFiles(sources, "example.source_collection"),
        slots, offset);
  }

  private static String target(String root, String... selectors) {
    StringBuilder source = new StringBuilder("""
        - kind: "tool"
          name: "main"
          root: "ROOT"
          module: "demo.main"
          sources:
        """.replace("ROOT", root));
    for (String selector : selectors) {
      source.append("    - \"").append(selector).append("\"\n");
    }
    return source.append("  test: false\n").toString();
  }
}
