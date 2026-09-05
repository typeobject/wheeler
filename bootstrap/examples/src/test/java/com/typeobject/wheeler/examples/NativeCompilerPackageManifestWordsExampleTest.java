package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Exact spellings, not polynomial hashes, own canonical manifest words. */
final class NativeCompilerPackageManifestWordsExampleTest {
  private static final List<String> WORDS = List.of(
      "schema", "package", "name", "version", "profile", "targets", "kind", "root", "module",
      "sources", "test", "dependencies", "capabilities", "path", "true", "false", "deployable",
      "library", "tool", "normal", "development", "build", "1");

  @Test
  void matchesEveryWordAndRejectsAliasesAtEveryCharacter() throws Exception {
    var input = new Ranges();
    for (String word : WORDS) {
      input.add(word);
      input.add("" + (char) 0 + word);
      input.add(word + (char) 0);
      input.add(word + "x");
      input.add(word.substring(0, word.length() - 1));
      input.add(word.substring(0, word.length() - 1) + "é");
      for (int position = 0; position < word.length(); position++) {
        input.add(word.substring(0, position) + (char) (word.charAt(position) + 1)
            + word.substring(position + 1));
      }
      if (1 < word.length()) {
        String alias = hashAlias(word);
        assertEquals(oldHash(word), oldHash(alias));
        input.add(alias);
      }
    }
    input.add("" + (char) 127 + "x".repeat(11));
    input.add("x".repeat(13));
    input.add("x".repeat(256));
    input.add("𝄞name");
    input.check(false);
  }

  @Test
  void rejectsInvalidExtentsAndRewindsTheCompleteWordPass() throws Exception {
    var input = new Ranges();
    for (String word : WORDS) {
      input.add(word);
    }
    input.add("trvF");
    input.add("étest");
    input.probes.add(new Probe(-1, 4, 0));
    input.probes.add(new Probe(Long.MIN_VALUE, 4, 0));
    input.probes.add(new Probe(Long.MAX_VALUE, 4, 0));
    input.probes.add(new Probe(0, -1, 0));
    input.probes.add(new Probe(0, Long.MIN_VALUE, 0));
    input.probes.add(new Probe(0, Long.MAX_VALUE, 0));
    input.probes.add(new Probe(input.byteLength(), 1, 0));
    input.probes.add(new Probe(input.byteLength() - 1, 2, 0));
    input.check(true);
  }

  @Test
  void decodesOnlyExactQuotedKindsAndPlainBooleans() throws Exception {
    var text = new ArrayList<String>();
    var expected = new ArrayList<Long>();
    for (String word : WORDS) {
      for (boolean quoted : new boolean[] {false, true}) {
        text.add(quoted ? "\"" + word + "\"" : word);
        expected.add(!quoted && word.equals("true") ? 1L
            : !quoted && word.equals("false") ? 0L : -1L);
        expected.add(quotedKind(word, quoted, "deployable", "library", "tool"));
        expected.add(quotedKind(word, quoted, "normal", "development", "build"));
        if (1 < word.length()) {
          String alias = hashAlias(word);
          text.add(quoted ? "\"" + alias + "\"" : alias);
          expected.addAll(List.of(-1L, 0L, 0L));
        }
      }
    }
    text.add("\"" + "x".repeat(256) + "\"");
    expected.addAll(List.of(-1L, 0L, 0L));
    int count = text.size();
    var program = program("""
        region rows = new region(ROW_BYTES, 3);
        words kinds = allocate(rows, COUNT);
        words starts = allocate(rows, COUNT);
        words lengths = allocate(rows, COUNT);
        long count = 0;
        ScanResult scanned = scan(source, kinds, starts, lengths);
        match (scanned) {
          case ScanResult.Value(long value) { count = value; }
          case ScanResult.Error(ScanDiagnostic diagnostic) { assert(false); }
        }
        assert(count == COUNT);
        long token = 0;
        while (token < count) limit COUNT {
          long booleanValue = manifestBooleanToken(source, starts, lengths, token);
          long target = manifestTargetKind(source, kinds, starts, lengths, token);
          long dependency = manifestDependencyKind(source, kinds, starts, lengths, token);
          long base = token * 24;
          long first = writeSignedLittleEndian(output, base, booleanValue, 8);
          long second = writeSignedLittleEndian(output, first, target, 8);
          long third = writeSignedLittleEndian(output, second, dependency, 8);
          assert(third == base + 24);
          token += 1;
        }
        setOutputLength(output, COUNT * 24);
        drop(lengths); drop(starts); drop(kinds); drop(rows);
        """.replace("ROW_BYTES", Integer.toString(count * 24))
        .replace("COUNT", Integer.toString(count)));
    assertResults(program, String.join(" ", text),
        expected.stream().mapToLong(Long::longValue).toArray(), true);
  }

  @Test
  void checksExactKeyCodesKindsAndTokenWindows() throws Exception {
    var program = program("""
        region tokens = new region(128, 4);
        words kinds = allocate(tokens, 5);
        words starts = allocate(tokens, 5);
        words lengths = allocate(tokens, 5);
        words shortColumn = allocate(tokens, 1);
        set(kinds, 0, 1); set(kinds, 1, 3); set(kinds, 2, 1); set(kinds, 3, 1); set(kinds, 4, 3);
        set(starts, 1, 4); set(starts, 2, 6); set(starts, 3, 12); set(starts, 4, 16);
        set(lengths, 0, 4); set(lengths, 1, 1); set(lengths, 2, 5); set(lengths, 3, 4); set(lengths, 4, 1);
        assert(manifestKeyAt(source, kinds, starts, lengths, 5, 0, WORD_NAME));
        assert(manifestKeyAt(source, kinds, starts, lengths, 5, 0, WORD_KIND) == false);
        assert(manifestKeyAt(source, kinds, starts, lengths, 5, 2, WORD_NAME) == false);
        assert(manifestKeyAt(source, kinds, starts, lengths, 5, 3, WORD_TEST));
        assert(manifestKeyAt(source, kinds, starts, lengths, 5, 4, WORD_TEST) == false);
        assert(manifestKeyAt(source, kinds, starts, lengths, 5, 0, 0) == false);
        assert(manifestKeyAt(source, kinds, starts, lengths, 5, 0, 3373707) == false);
        assert(manifestKeyAt(source, kinds, starts, lengths, 5, -1, WORD_NAME) == false);
        long minimum = -9223372036854775807 - 1;
        long maximum = 9223372036854775807;
        assert(manifestKeyAt(source, kinds, starts, lengths, 5, minimum, WORD_NAME) == false);
        assert(manifestKeyAt(source, kinds, starts, lengths, 5, maximum, WORD_NAME) == false);
        assert(manifestKeyAt(source, kinds, starts, lengths, minimum, 0, WORD_NAME) == false);
        assert(manifestKeyAt(source, kinds, starts, lengths, maximum, 0, WORD_NAME) == false);
        assert(manifestKeyAt(source, kinds, starts, lengths, 1, 0, WORD_NAME) == false);
        assert(manifestKeyAt(source, kinds, starts, lengths, 6, 0, WORD_NAME) == false);
        assert(manifestKeyAt(source, shortColumn, starts, lengths, 5, 0, WORD_NAME) == false);
        assert(manifestKeyAt(source, kinds, shortColumn, lengths, 5, 0, WORD_NAME) == false);
        assert(manifestKeyAt(source, kinds, starts, shortColumn, 5, 0, WORD_NAME) == false);
        set(kinds, 0, 6);
        assert(manifestKeyAt(source, kinds, starts, lengths, 5, 0, WORD_NAME) == false);
        set(kinds, 0, 1);
        assert(starts[0] == 0); assert(starts[1] == 4); assert(starts[2] == 6);
        assert(starts[3] == 12); assert(starts[4] == 16);
        assert(lengths[0] == 4); assert(lengths[1] == 1); assert(lengths[2] == 5);
        assert(lengths[3] == 4); assert(lengths[4] == 1);
        assert(kinds[0] == 1); assert(kinds[1] == 3); assert(kinds[2] == 1);
        assert(kinds[3] == 1); assert(kinds[4] == 3);
        setOutputLength(output, 0);
        drop(shortColumn); drop(lengths); drop(starts); drop(kinds); drop(tokens);
        """);
    assertResults(program, "name: wrong test:", new long[0], true);
  }

  @Test
  void usesExactWordCodesForHeaderAndCanonicalLayoutState() throws Exception {
    var program = program("""
        assert(manifestHeaderTokenCount(34) == false);
        assert(manifestHeaderTokenCount(35));
        assert(manifestFormatVersion(0) == false);
        assert(manifestFormatVersion(49) == false);
        assert(manifestFormatVersion(WORD_SCHEMA_VERSION));
        assert(canonicalManifestSection(0, 0, 0) == 0);
        assert(canonicalManifestSection(5, 0, 0) == 1);
        assert(canonicalManifestSection(6, WORD_DEPENDENCIES, 1) == 2);
        assert(canonicalManifestSection(7, WORD_CAPABILITIES, 2) == 3);
        assert(canonicalManifestSection(8, 0, 2) == 2);
        assert(canonicalManifestIndent(0, 0, 0, 0) == 0);
        assert(canonicalManifestIndent(2, 0, 0, 0) == 2);
        assert(canonicalManifestIndent(5, 0, 0, 0) == 0);
        assert(canonicalManifestIndent(6, WORD_DEPENDENCIES, 0, 0) == 0);
        assert(canonicalManifestIndent(7, WORD_CAPABILITIES, 0, 0) == 0);
        assert(canonicalManifestIndent(8, 0, 3, 2) == 6);
        assert(canonicalManifestIndent(8, 0, 3, 4) == 2);
        assert(canonicalManifestIndent(8, 0, 1, 2) == 4);
        setOutputLength(output, 0);
        """);
    assertResults(program, "", new long[0], true);
  }

  private static long quotedKind(String word, boolean quoted, String... kinds) {
    return quoted ? List.of(kinds).indexOf(word) + 1L : 0;
  }

  private record Probe(long start, long length, long expected) {}

  private static final class Ranges {
    final StringBuilder source = new StringBuilder("// café 𝄞\n");
    final List<Probe> probes = new ArrayList<>();

    int byteLength() {
      return source.toString().getBytes(StandardCharsets.UTF_8).length;
    }

    void add(String text) {
      probes.add(new Probe(byteLength(), text.getBytes(StandardCharsets.UTF_8).length,
          WORDS.indexOf(text) + 1));
      source.append(text).append('\n');
    }

    void check(boolean rewind) throws Exception {
      var rows = new StringBuilder();
      for (int row = 0; row < probes.size(); row++) {
        rows.append("set(starts, ").append(row).append(", ")
            .append(literal(probes.get(row).start())).append(");\n");
        rows.append("set(lengths, ").append(row).append(", ")
            .append(literal(probes.get(row).length())).append(");\n");
      }
      var program = program("""
          region rows = new region(ROW_BYTES, 2);
          words starts = allocate(rows, COUNT);
          words lengths = allocate(rows, COUNT);
          SET_ROWS
          long row = 0;
          while (row < COUNT) limit COUNT {
            long start = starts[row];
            long length = lengths[row];
            long word = manifestRangeWord(source, start, length);
            long end = writeSignedLittleEndian(output, row * 8, word, 8);
            assert(end == (row + 1) * 8);
            row += 1;
          }
          setOutputLength(output, COUNT * 8);
          drop(lengths); drop(starts); drop(rows);
          """.replace("ROW_BYTES", Integer.toString(probes.size() * 16))
          .replace("COUNT", Integer.toString(probes.size())).replace("SET_ROWS", rows));
      assertResults(program, source.toString(), probes.stream().mapToLong(Probe::expected).toArray(), rewind);
    }
  }

  private static String literal(long value) {
    return value == Long.MIN_VALUE ? "(-9223372036854775807 - 1)" : Long.toString(value);
  }

  private static String hashAlias(String word) {
    int last = word.length() - 1;
    return word.substring(0, last - 1) + (char) (word.charAt(last - 1) + 1)
        + (char) (word.charAt(last) - 31);
  }

  private static long oldHash(String text) {
    long value = 0;
    for (int index = 0; index < text.length(); index++) {
      value = value * 31 + text.charAt(index);
    }
    return value;
  }

  private static Program program(String body) throws Exception {
    var sources = new LinkedHashMap<String, String>();
    for (String module : List.of(
        "canonical_indent", "manifest_header_state", "manifest_keys", "manifest_kinds")) {
      sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.packages." + module));
    }
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.encoding"));
    sources.put("Scanner.w", CompilerSources.read("lexer/Scanner.w"));
    sources.put("ManifestWords.w", """
        module example.manifest_words;
        import wheeler.compiler.encoding;
        import wheeler.compiler.packages.canonical_indent;
        import wheeler.compiler.packages.manifest_header_state;
        import wheeler.compiler.packages.manifest_keys;
        import wheeler.compiler.packages.manifest_kinds;
        import wheeler.compiler.packages.manifest_tokens;
        import wheeler.compiler.packages.manifest_words;
        import wheeler.lexer.scanner;
        classical class ManifestWords {
          entry void main(borrow utf8 source, borrow mut bytes output) {
            BODY
          }
        }
        """.replace("BODY", body));
    return new WheelerCompiler().compileModuleFiles(sources, "example.manifest_words");
  }

  private static void assertResults(Program program, String source, long[] expected, boolean rewind) {
    var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8),
        Math.max(8, expected.length * 8));
    var initial = machine.snapshot();
    if (rewind) {
      machine.run();
    } else {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    }
    var output = ByteBuffer.wrap(machine.hostOutput()).order(ByteOrder.LITTLE_ENDIAN);
    long[] actual = new long[expected.length];
    assertEquals(expected.length * 8, output.remaining());
    for (int cell = 0; cell < actual.length; cell++) {
      actual[cell] = output.getLong();
    }
    assertArrayEquals(expected, actual);
    if (rewind) {
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    }
  }
}
