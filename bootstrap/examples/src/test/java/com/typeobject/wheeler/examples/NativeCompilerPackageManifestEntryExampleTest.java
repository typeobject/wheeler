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

/** Exact table-publication evidence for retained manifest entries. */
final class NativeCompilerPackageManifestEntryExampleTest {
  private static final long SENTINEL = -7;
  private static final long NOT_CALLED = -9;
  private static final Pattern QUOTED = Pattern.compile("\"([^\"]*)\"");
  private static final Entry DEPENDENCY = new Entry(
      "manifest_dependency", "manifestDependencyEntryProduct", 5, 10);
  private static final Entry CAPABILITY = new Entry(
      "manifest_capability", "manifestCapabilityEntryProduct", 4, 7);

  private record Entry(String module, String function, int width, int tokens) {}

  @Test
  void dependencyEntriesPublishOnlyCompleteAdmittedRows() throws Exception {
    Fixture full = fixture(DEPENDENCY, 11);
    String first = dependency("normal", "demo.a", "^1.0.0");
    String second = dependency("development", "demo.b", "~2.1.0");
    full.assertRows(first + second, 1, 2, 2);
    full.assertRows(dependency("build", "demo.a", "1.0.0") + second, 1, 2, 2);
    full.assertRows(first + dependency("normal", "demo.a", "1.0.0"), 1, 0, 1);
    full.assertRows(first + dependency("normal", "aaaa.base", "1.0.0"), 1, 0, 1);
    full.assertRows(first + dependency("normal", "aaaa.base", "bad"), 1, -1, 1);
    full.assertRows(first + dependency("normal", "", "1.0.0"), 1, -1, 1);
    full.assertRows(first + dependency("invalid", "demo.a", "1.0.0"), 1, -1, 1);
    full.assertRows(first + "- kind: \"normal\"\n", 1, -1, 1);
    full.assertRows("- kind:\n", -1, NOT_CALLED, 0);
    full.assertRows(dependency("normal", "demo.a", "bad") + second, -1, NOT_CALLED, 0);
    full.assertRows(dependency("invalid", "demo.a", "1.0.0") + second, -1, NOT_CALLED, 0);

    fixture(DEPENDENCY, 9).assertRows(first + second, 1, -1, 1);
    fixture(DEPENDENCY, 5).assertRows(first + first, 1, -1, 1);
    fixture(DEPENDENCY, 4).assertRows(first + second, -1, NOT_CALLED, 0);
  }

  @Test
  void capabilityEntriesPublishOnlyCompleteOrderedPairs() throws Exception {
    Fixture full = fixture(CAPABILITY, 9);
    String first = capability("fixture", "data");
    String second = capability("logs", "logs");
    full.assertRows(first + second, 1, 2, 2);
    full.assertRows(first + capability("fixture", "z-data"), 1, 2, 2);
    full.assertRows("// café\n" + first + second, 1, 2, 2);
    full.assertRows("// 𝄞\n" + first + capability("fixture", "z-data"), 1, 2, 2);
    full.assertRows(first + first, 1, 0, 1);
    full.assertRows(first + capability("fixture", "a-data"), 1, 0, 1);
    full.assertRows(first + capability("earlier", "logs"), 1, 0, 1);
    full.assertRows(first + capability("earlier", "../logs"), 1, -1, 1);
    full.assertRows(first + capability("", "logs"), 1, -1, 1);
    full.assertRows(first + second.replace("name:", "namx:"), 1, -1, 1);
    full.assertRows(first + "- name:\n", 1, -1, 1);
    full.assertRows("- name:\n", -1, NOT_CALLED, 0);
    full.assertRows(capability("fixture", "../data") + second, -1, NOT_CALLED, 0);
    full.assertRows(first.replace("name:", "namx:") + second, -1, NOT_CALLED, 0);

    fixture(CAPABILITY, 7).assertRows(first + second, 1, -1, 1);
    fixture(CAPABILITY, 4).assertRows(first + first, 1, -1, 1);
    fixture(CAPABILITY, 3).assertRows(first + second, -1, NOT_CALLED, 0);
  }

  private record Fixture(Entry entry, Program program, int slots) {
    void assertRows(String source, long first, long next, int published) {
      var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8), slots * 8);
      machine.run();
      assertEquals(first, machine.global("first"), source);
      assertEquals(next, machine.global("next"), source);
      long[] actual = new long[slots];
      ByteBuffer bytes = ByteBuffer.wrap(machine.hostOutput()).order(ByteOrder.LITTLE_ENDIAN);
      for (int index = 0; index < slots; index++) {
        actual[index] = bytes.getLong();
      }
      long[] expected = new long[slots];
      Arrays.fill(expected, SENTINEL);
      var values = QUOTED.matcher(source);
      for (int row = 0; row < published; row++) {
        int cell = row * entry.width();
        if (entry.equals(DEPENDENCY)) {
          if (!values.find()) {
            throw new AssertionError("missing dependency kind");
          }
          expected[cell++] = switch (values.group(1)) {
            case "normal" -> 1;
            case "development" -> 2;
            case "build" -> 3;
            default -> throw new AssertionError("invalid admitted dependency kind");
          };
        }
        for (int field = 0; field < 2; field++) {
          if (!values.find()) {
            throw new AssertionError("missing admitted field");
          }
          expected[cell++] = source.substring(0, values.start(1)).getBytes(StandardCharsets.UTF_8).length;
          expected[cell++] = values.group(1).getBytes(StandardCharsets.UTF_8).length;
        }
      }
      assertArrayEquals(expected, actual, source);
    }
  }

  private static Fixture fixture(Entry entry, int slots) throws Exception {
    String module = "wheeler.compiler.packages." + entry.module();
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(module));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.encoding"));
    sources.put("Scanner.w", CompilerSources.read("lexer/Scanner.w"));
    sources.put("ManifestEntry.w", """
        module example.manifest_entry;
        import wheeler.compiler.encoding;
        import MODULE;
        import wheeler.lexer.scanner;
        classical class ManifestEntry {
          state long first = -9;
          state long next = -9;
          entry void main(borrow utf8 source, borrow mut bytes output) {
            region arena = new region(ARENA_BYTES, 4);
            words kinds = allocate(arena, 32);
            words starts = allocate(arena, 32);
            words lengths = allocate(arena, 32);
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
            first = FUNCTION(source, kinds, starts, lengths, count, cursor, rows, 0);
            if (0 < first) {
              long following = cursor + TOKENS;
              next = FUNCTION(source, kinds, starts, lengths, count, following, rows, first);
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
        """.replace("MODULE", module)
        .replace("ARENA_BYTES", Integer.toString((96 + slots) * 8))
        .replace("SLOTS", Integer.toString(slots))
        .replace("TOKENS", Integer.toString(entry.tokens()))
        .replace("FUNCTION", entry.function()));
    Program program = new WheelerCompiler().compileModuleFiles(sources, "example.manifest_entry");
    return new Fixture(entry, program, slots);
  }

  private static String dependency(String kind, String name, String version) {
    return "- kind: \"" + kind + "\"\n  name: \"" + name + "\"\n  version: \"" + version + "\"\n";
  }

  private static String capability(String name, String path) {
    return "- name: \"" + name + "\"\n  path: \"" + path + "\"\n";
  }
}
