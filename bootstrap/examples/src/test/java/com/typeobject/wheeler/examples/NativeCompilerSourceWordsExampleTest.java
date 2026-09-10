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
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Exact spelling precedes keyword, literal, type, and intrinsic classification. */
final class NativeCompilerSourceWordsExampleTest {
  private static final String UTF8_PREFIX = "// café 𝄞\n";
  private static final Map<String, Long> WORDS = wordCodes();

  @Test
  void matchesEveryWordAndRejectsChangesInBothLengthBearingLanes() throws Exception {
    assertEquals(72, WORDS.size());
    var input = new Ranges();
    for (String word : WORDS.keySet()) {
      input.add(word);
      input.add("" + (char) 0 + word);
      input.add(word + (char) 0);
      input.add(word + "x");
      input.add(word.substring(0, word.length() - 1));
      input.add("\"" + word + "\"");
      for (int position = 0; position < word.length(); position++) {
        input.add(word.substring(0, position) + (char) (word.charAt(position) + 1)
            + word.substring(position + 1));
        input.add(word.substring(0, position) + "é" + word.substring(position + 1));
      }
      String alias = hashAlias(word, word.length() - 2);
      assertEquals(oldHash(word), oldHash(alias));
      input.add(alias);
    }
    for (int position : new int[] {4, 9}) {
      String alias = hashAlias("rotateRight32", position);
      assertEquals(oldHash("rotate"), oldHash(alias.substring(0, 6)));
      assertEquals(oldHash("Right32"), oldHash(alias.substring(6)));
      input.add(alias);
    }
    input.add("x".repeat(14));
    input.add("x".repeat(256));
    input.add("x".repeat(257));
    input.add("" + (char) 127 + "x".repeat(12));
    input.add("𝄞module");
    input.check(false);
  }

  @Test
  void checksSignedExtremesAndRewindsAllWordsAndCallerRows() throws Exception {
    var input = new Ranges();
    WORDS.keySet().forEach(input::add);
    input.add("é");
    input.add("rotauFRight32");
    input.add("rotateRigiU32");
    for (long start : new long[] {-1, Long.MIN_VALUE, Long.MAX_VALUE}) {
      input.probes.add(new Probe(start, 4, 0, false, false));
    }
    for (long length : new long[] {-1, 0, Long.MIN_VALUE, Long.MAX_VALUE}) {
      input.probes.add(new Probe(0, length, 0, false, false));
    }
    input.probes.add(new Probe(input.byteLength(), 1, 0, false, false));
    input.probes.add(new Probe(input.byteLength() - 1, 2, 0, false, false));
    input.check(true);
  }

  @Test
  void rejectsTokenColumnWindowsBeforeReadingOrChangingThem() throws Exception {
    int start = UTF8_PREFIX.getBytes(StandardCharsets.UTF_8).length;
    var program = program("""
        region rows = new region(48, 2);
        words starts = allocate(rows, 4);
        words lengths = allocate(rows, 2);
        set(starts, 0, START); set(starts, 1, 91);
        set(starts, 2, 92); set(starts, 3, 93);
        set(lengths, 0, 13); set(lengths, 1, 94);
        assert(sourceTokenCode(source, starts, lengths, 0) == TOKEN_ROTATE_RIGHT_32);
        assert(rotateRight32Token(source, starts, lengths, 0));
        assert(sourceTokenCode(source, starts, lengths, 1) == 0);
        assert(sourceTokenCode(source, starts, lengths, 2) == 0);
        assert(sourceTokenCode(source, lengths, starts, 2) == 0);
        assert(sourceTokenCode(source, starts, lengths, 4) == 0);
        assert(sourceTokenCode(source, starts, lengths, -1) == 0);
        long minimum = -9223372036854775807 - 1;
        long maximum = 9223372036854775807;
        assert(sourceTokenCode(source, starts, lengths, minimum) == 0);
        assert(sourceTokenCode(source, starts, lengths, maximum) == 0);
        assert(rotateRight32Token(source, starts, lengths, maximum) == false);
        assert(starts[0] == START); assert(starts[1] == 91);
        assert(starts[2] == 92); assert(starts[3] == 93);
        assert(lengths[0] == 13); assert(lengths[1] == 94);
        setOutputLength(output, 0);
        drop(lengths); drop(starts); drop(rows);
        """.replace("START", Integer.toString(start)));
    assertResults(program, UTF8_PREFIX + "rotateRight32", new long[0], true);
    assertResults(program("""
        assert(sourceWordCode(source, 0, 1) == 0);
        setOutputLength(output, 0);
        """), "", new long[0], true);
  }

  @Test
  void mapsPrimitiveTypesOnlyAfterExactWordAdmission() throws Exception {
    var primitives = Map.of("long", 1, "boolean", 2, "region", 3, "words", 4,
        "bytes", 5, "longmap", 6, "utf8", 7, "byteview", 13, "Done", 14);
    var source = new StringBuilder(UTF8_PREFIX);
    var checks = new StringBuilder();
    for (String word : primitives.keySet().stream().sorted().toList()) {
      for (String candidate : List.of(word, hashAlias(word, word.length() - 2))) {
        int start = source.toString().getBytes(StandardCharsets.UTF_8).length;
        source.append(candidate).append(' ');
        checks.append("assert(primitiveType(sourceWordCode(source, ").append(start)
            .append(", ").append(candidate.length()).append(")) == ")
            .append(candidate.equals(word) ? primitives.get(word) : -1).append(");\n");
      }
    }
    checks.append("assert(primitiveType(0) == -1);\nsetOutputLength(output, 0);\n");
    assertResults(program(checks.toString()), source.toString(), new long[0], true);
  }

  private record Probe(long start, long length, long expected, boolean bool, boolean rotate) {}

  private static final class Ranges {
    final StringBuilder source = new StringBuilder(UTF8_PREFIX);
    final List<Probe> probes = new ArrayList<>();

    int byteLength() {
      return source.toString().getBytes(StandardCharsets.UTF_8).length;
    }

    void add(String text) {
      probes.add(new Probe(byteLength(), text.getBytes(StandardCharsets.UTF_8).length,
          WORDS.getOrDefault(text, 0L), text.equals("true") || text.equals("false"),
          text.equals("rotateRight32")));
      source.append(text).append('\n');
    }

    void check(boolean rewind) throws Exception {
      var rows = new StringBuilder();
      var unchanged = new StringBuilder();
      long[] expected = new long[probes.size() * 4];
      for (int row = 0; row < probes.size(); row++) {
        Probe probe = probes.get(row);
        rows.append("set(starts, ").append(row).append(", ").append(literal(probe.start()))
            .append("); set(lengths, ").append(row).append(", ").append(literal(probe.length()))
            .append(");\n");
        unchanged.append("assert(starts[").append(row).append("] == ")
            .append(literal(probe.start())).append("); assert(lengths[").append(row)
            .append("] == ").append(literal(probe.length())).append(");\n");
        expected[row * 4] = probe.expected();
        expected[row * 4 + 1] = probe.expected();
        expected[row * 4 + 2] = probe.bool() ? 1 : 0;
        expected[row * 4 + 3] = probe.rotate() ? 1 : 0;
      }
      var program = program("""
          region rows = new region(ROW_BYTES, 2);
          words starts = allocate(rows, COUNT);
          words lengths = allocate(rows, COUNT);
          SET_ROWS
          long row = 0;
          while (row < COUNT) limit COUNT {
            long word = sourceWordCode(source, starts[row], lengths[row]);
            long token = sourceTokenCode(source, starts, lengths, row);
            long bool = 0;
            if (booleanTokenCode(token)) { bool = 1; }
            long rotate = 0;
            if (rotateRight32Token(source, starts, lengths, row)) { rotate = 1; }
            long end = writeSignedLittleEndian(output, row * 32, word, 8);
            end = writeSignedLittleEndian(output, end, token, 8);
            end = writeSignedLittleEndian(output, end, bool, 8);
            end = writeSignedLittleEndian(output, end, rotate, 8);
            assert(end == (row + 1) * 32);
            row += 1;
          }
          CHECK_ROWS
          setOutputLength(output, COUNT * 32);
          drop(lengths); drop(starts); drop(rows);
          """.replace("ROW_BYTES", Integer.toString(probes.size() * 16))
          .replace("COUNT", Integer.toString(probes.size())).replace("SET_ROWS", rows)
          .replace("CHECK_ROWS", unchanged));
      assertResults(program, source.toString(), expected, rewind);
    }
  }

  private static String literal(long value) {
    return value == Long.MIN_VALUE ? "(-9223372036854775807 - 1)" : Long.toString(value);
  }

  private static String hashAlias(String word, int position) {
    char[] alias = word.toCharArray();
    alias[position]++;
    alias[position + 1] -= 31;
    return new String(alias);
  }

  private static long oldHash(String text) {
    long value = 0;
    for (int index = 0; index < text.length(); index++) {
      value = (value & 288230376151711743L) * 31 + text.charAt(index);
    }
    return value;
  }

  private static Program program(String body) throws Exception {
    var sources = new LinkedHashMap<String, String>();
    for (String module : List.of("boolean_tokens", "closure.source_aggregate_syntax",
        "encoding", "tokens")) {
      sources.putAll(CompilerSources.moduleClosure("wheeler.compiler." + module));
    }
    sources.put("SourceWords.w", """
        module example.source_words;
        import wheeler.compiler.boolean_tokens;
        import wheeler.compiler.closure.source_aggregate_syntax;
        import wheeler.compiler.encoding;
        import wheeler.compiler.keyword_tokens;
        import wheeler.compiler.source_words;
        import wheeler.compiler.tokens;
        classical class SourceWords {
          entry void main(borrow utf8 source, borrow mut bytes output) {
            BODY
          }
        }
        """.replace("BODY", body));
    return new WheelerCompiler().compileModuleFiles(sources, "example.source_words");
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

  private static Map<String, Long> wordCodes() {
    // Frozen identities from the source-word registry, not a runtime hash oracle.
    String codes = """
        module 3226183276
        import 3110171557
        public 3317543529
        private 102764717443
        classical 87497064671293
        class 94742904
        state 109757585
        entry 96667762
        void 3625364
        main 3343801
        rev 112803
        reverse 104179061474
        theorem 106024553916
        proves 3315169751
        inverse 96449190704
        assert 2886759238
        if 3357
        while 113101617
        limit 102976443
        long 3327612
        borrow 2911676917
        mut 108492
        utf8 3600241
        bytes 94224491
        allocateBytes 7757814110573215534
        drop 3092207
        freezeUtf8 2796943039232680
        byteview 2807042004909
        words 113318569
        region 3360171764
        longmap 99132996960
        boolean 90259024936
        bufferLength 2588713963992550214
        utf8Scalar 3195229610631869
        utf8Width 103071926799573
        set 113762
        setByte 105063682186
        put 111375
        mapGet 3213567066
        mapHas 3213567902
        return 3360570672
        true 3569038
        false 97196323
        const 94844771
        coherent 2825335909666
        test 3556498
        new 108960
        record 3360058449
        case 3046192
        variant 107610968197
        slice 109526418
        Done 2135970
        cases 94432067
        history 95416214676
        limits 3192269848
        steps 109761319
        tags 3552281
        rotateRight32 3360224995018391456
        enum 3118337
        qreg 3479171
        static 3402485358
        unitary 107087659620
        dynamic 92319080511
        protected 98762164431790
        Slot 2579998
        adjoint 89052076615
        equivalent 2770094160335466
        done 3089282
        nil 109073
        none 3387192
        null 3392903
        undefined 102906378281296
        """;
    var result = new LinkedHashMap<String, Long>();
    for (String row : codes.lines().toList()) {
      String[] fields = row.strip().split(" ");
      result.put(fields[0], Long.parseLong(fields[1]));
    }
    return result;
  }
}
