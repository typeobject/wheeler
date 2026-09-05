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

/** Complete target admission preserves source prefixes without committing rejected counts. */
final class NativeCompilerPackageManifestTargetAdmissionExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_target_admission";
  private static final Pattern SELECTOR = Pattern.compile("(?m)^\\s*- \"([^\"]*)\"\\s*$");

  @Test
  void admitsEveryTargetKindWithAbsentOrNonemptySources() throws Exception {
    Fixture fixture = fixture(7, 0, 1, "");
    for (String kind : new String[] {"deployable", "library", "tool"}) {
      fixture.assertRows(target(kind, false), 10, 0, 0);
      fixture.assertRows(target(kind, true, "src/App.w"), 17, 1, 1);
      fixture.assertRows(target(kind, true, "src/App.w", "src/Helper.w"), 19, 2, 2);
      long result = kind.equals("library") ? -1 : 10;
      fixture.assertRows(target(kind, false).replace("test: false", "test: true"), result, 0, 0);
    }
    fixture.assertRows("// café 𝄞\n" + target("tool", true, "src/App.w"), 18, 1, 1, true);
  }

  @Test
  void rejectsMalformedHeadsCollectionsAndTailsAtTheirExistingPublicationBoundary() throws Exception {
    Fixture fixture = fixture(7, 0, 1, "");
    String valid = target("tool", true, "src/App.w");
    for (String invalid : new String[] {
        valid.replace("kind:", "type:"),
        valid.replace("\"tool\"", "\"other\""),
        valid.replace("\"tool\"", "\"topM\""),
        valid.replace("\"tool\"", "\"" + "x".repeat(256) + "\""),
        valid.replace("\"main\"", "\"\""),
        valid.replace("root: \"src/App.w\"", "root: \"../App.w\""),
        valid.replace("\"demo.main\"", "\"bad..module\""),
        valid.replace("sources:", "files:"),
        target("tool", true),
        target("tool", true, "../App.w")
    }) {
      fixture.assertRows(invalid, -1, 0, 0);
    }
    for (String invalid : new String[] {
        target("tool", true, "src/Helper.w"),
        target("tool", true, "src/App.w", "src/App.w"),
        target("tool", true, "src/Helper.w", "src/App.w"),
        target("tool", true, "src/App.w", "../Helper.w"),
        valid.replace("test: false\n", ""),
        valid.replace("test: false", "test:"),
        valid.replace("test: false", "test: TRUE"),
        valid.replace("test: false", "test: faltF"),
        valid.replace("test: false", "tetU: false"),
        valid.replace("test: false", "test: " + "x".repeat(256)),
        valid.replace("test: false", "test: \"false\""),
        valid.replace("test: false", "run: false"),
        target("library", true, "src/App.w").replace("test: false", "test: true")
    }) {
      fixture.assertRows(invalid, -1, 0, 1);
    }
    fixture.assertRows(target("tool", false).replace("test: false", "test:"), -1, 0, 0);
  }

  @Test
  void preservesEarlierCollectionsAndChecksEveryInputWindowBeforeReadingRows() throws Exception {
    String two = target("tool", true, "src/App.w", "src/Helper.w");
    fixture(3, 0, 1, "").assertRows(two, -1, 0, 1);
    fixture(1, 0, 1, "").assertRows(two, -1, 0, 0);
    fixture(7, 2, 1, "").assertRows(two, -1, 2, 1);
    fixture(9, 2, 1, "").assertRows(two, 19, 4, 2);
    fixture(4, 2, 1, "").assertRows(target("tool", false), 10, 2, 0);
    for (long offset : new long[] {-1, Long.MIN_VALUE, Long.MAX_VALUE}) {
      fixture(7, offset, 1, "").assertRows(two, -1, offset, 0);
    }
    for (String mutation : new String[] {
        "cursor = -1;", "cursor = minimum;", "cursor = maximum;",
        "count = -1;", "count = minimum;", "count = maximum;", "count = 12;",
        "count = 4097;", "shortKinds", "shortStarts", "shortLengths"
    }) {
      fixture(7, 0, 1, mutation).assertRows(two, -1, 0, 0);
    }
    Fixture fixture = fixture(7, 0, 2, "");
    String first = target("tool", true, "src/App.w");
    fixture.assertRows(first + target("library", false), 30, 1, 1);
    fixture.assertRows(first + first, 37, 2, 2);
    fixture.assertRows(first + first.replace("test: false", "test: TRUE"), -1, 1, 2);
  }

  @Test
  void admitsOneThousandTwentyFourSourcesAndRejectsTheFirstExcess() throws Exception {
    String[] selectors = new String[1025];
    for (int row = 0; row < selectors.length; row++) {
      selectors[row] = "src/%04d.w".formatted(row);
    }
    Fixture fixture = fixture(2053, 0, 1, "");
    fixture.assertRows(target("tool", true, Arrays.copyOf(selectors, 1024))
        .replace("root: \"src/App.w\"", "root: \"src/0000.w\""), 2063, 1024, 1024);
    fixture.assertRows(target("tool", true, selectors)
        .replace("root: \"src/App.w\"", "root: \"src/0000.w\""), -1, 0, 1024);
  }

  private record Fixture(Program program, int slots, long offset) {
    void assertRows(String source, long tail, long committed, int published) {
      assertRows(source, tail, committed, published, false);
    }

    void assertRows(String source, long tail, long committed, int published, boolean rewind) {
      var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8), slots * 8);
      var initial = machine.snapshot();
      if (rewind) {
        machine.run();
      } else {
        CompilerMachineRunner.runWithoutRewindHistory(machine);
      }
      assertEquals(tail, machine.global("tail"), source);
      assertEquals(committed, machine.global("committed"), source);
      if (0 <= tail) {
        assertEquals(SourceRanges.utf8Offset(source, source.lastIndexOf("test:")),
            machine.global("tailOffset"), source);
        assertEquals(tail + 3, machine.global("next"), source);
      }
      long[] expected = new long[slots];
      Arrays.fill(expected, -7);
      var selectors = SELECTOR.matcher(source);
      for (int row = 0; row < published; row++) {
        if (!selectors.find()) {
          throw new AssertionError("missing admitted selector");
        }
        int base = Math.toIntExact((offset + row) * 2);
        expected[base] = SourceRanges.utf8Offset(source, selectors.start(1));
        expected[base + 1] = selectors.group(1).getBytes(StandardCharsets.UTF_8).length;
      }
      long[] actual = new long[slots];
      var bytes = ByteBuffer.wrap(machine.hostOutput()).order(ByteOrder.LITTLE_ENDIAN);
      for (int cell = 0; cell < slots; cell++) {
        actual[cell] = bytes.getLong();
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

  private static Fixture fixture(int slots, long offset, int targets, String mutation) throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.encoding"));
    sources.put("Scanner.w", CompilerSources.read("lexer/Scanner.w"));
    sources.put("TargetAdmission.w", """
        module example.target_admission;
        import wheeler.compiler.encoding;
        import wheeler.compiler.packages.manifest_target_admission;
        import wheeler.compiler.packages.manifest_target_coordinates;
        import wheeler.lexer.scanner;
        classical class TargetAdmission {
          state long tail = -9;
          state long tailOffset = -1;
          state long committed = 0;
          state long next = -1;
          entry void main(borrow utf8 source, borrow mut bytes output) {
            region arena = new region(ARENA_BYTES, 5);
            words kinds = allocate(arena, 4096);
            words starts = allocate(arena, 4096);
            words lengths = allocate(arena, 4096);
            words shortColumn = allocate(arena, 1);
            words rows = allocate(arena, SLOTS);
            long count = 0;
            ScanResult scanned = scan(source, kinds, starts, lengths);
            match (scanned) {
              case ScanResult.Value(long tokenCount) { count = tokenCount; }
              case ScanResult.Error(ScanDiagnostic diagnostic) { assert(false); }
            }
            long cell = 0;
            while (cell < SLOTS) limit SLOTS {
              set(rows, cell, -7);
              cell += 1;
            }
            long cursor = 0;
            if (kinds[0] == 4) { cursor = 1; }
            long minimum = -9223372036854775807 - 1;
            long maximum = 9223372036854775807;
            MUTATION
            committed = OFFSET;
            long target = 0;
            boolean reading = true;
            while (reading) limit 2 {
              tail = manifestTargetAdmissionProduct(
                source, KINDS, STARTS, LENGTHS, count, cursor, rows, committed
              );
              if (tail < 0) {
                reading = false;
              } else {
                committed += manifestTargetSourceCount(cursor, tail);
                tailOffset = starts[tail];
                next = manifestTargetNextToken(tail);
                cursor = next;
                target += 1;
                if (target == TARGETS) { reading = false; }
              }
            }
            cell = 0;
            while (cell < SLOTS) limit SLOTS {
              long end = writeSignedLittleEndian(output, cell * 8, rows[cell], 8);
              assert(end == (cell + 1) * 8);
              cell += 1;
            }
            setOutputLength(output, SLOTS * 8);
            drop(rows); drop(shortColumn); drop(lengths); drop(starts); drop(kinds); drop(arena);
          }
        }
        """.replace("ARENA_BYTES", Integer.toString((12289 + slots) * 8))
        .replace("SLOTS", Integer.toString(slots)).replace("TARGETS", Integer.toString(targets))
        .replace("OFFSET", offset == Long.MIN_VALUE ? "(-9223372036854775807 - 1)" : Long.toString(offset))
        .replace("KINDS", mutation.equals("shortKinds") ? "shortColumn" : "kinds")
        .replace("STARTS", mutation.equals("shortStarts") ? "shortColumn" : "starts")
        .replace("LENGTHS", mutation.equals("shortLengths") ? "shortColumn" : "lengths")
        .replace("MUTATION", mutation.startsWith("short") ? "" : mutation));
    return new Fixture(new WheelerCompiler().compileModuleFiles(sources, "example.target_admission"),
        slots, offset);
  }

  private static String target(String kind, boolean modular, String... selectors) {
    var source = new StringBuilder("- kind: \"" + kind + "\"\n  name: \"main\"\n"
        + "  root: \"src/App.w\"\n");
    if (modular) {
      source.append("  module: \"demo.main\"\n  sources:\n");
      for (String selector : selectors) {
        source.append("    - \"").append(selector).append("\"\n");
      }
    }
    return source.append("  test: false\n").toString();
  }
}
