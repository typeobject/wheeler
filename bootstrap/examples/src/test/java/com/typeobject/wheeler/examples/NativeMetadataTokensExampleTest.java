package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Checks exact package-metadata words and every caller-table admission window. */
final class NativeMetadataTokensExampleTest {
  private static final String MINIMUM = "(-9223372036854775807 - 1)";
  private static final String MAXIMUM = "9223372036854775807";

  @Test
  void checksEveryWordAndKeyWindowWithoutChangingCallerRows() throws Exception {
    String source = "// café 𝄞\nname: 1";
    int start = SourceRanges.utf8Offset(source, source.indexOf("name"));
    Fixture fixture = new Fixture();
    fixture.word("starts", "lengths", "0", "WORD_NAME", true);
    for (String code : new String[] {"WORD_ROOT", "0", "-10", MINIMUM, MAXIMUM}) {
      fixture.word("starts", "lengths", "0", code, false);
    }
    for (String token : new String[] {"-1", "3", MINIMUM, MAXIMUM}) {
      fixture.word("starts", "lengths", token, "WORD_NAME", false);
    }
    fixture.word("shortRows", "lengths", "1", "WORD_NAME", false);
    fixture.word("starts", "shortRows", "1", "WORD_NAME", false);
    for (String badStart : new String[] {"-1", MINIMUM, MAXIMUM, "1000"}) {
      fixture.line("set(starts, 0, " + badStart + ");");
      fixture.word("starts", "lengths", "0", "WORD_NAME", false);
    }
    fixture.line("set(starts, 0, " + start + ");");
    for (String badLength : new String[] {"0", "3", "5", "-1", MINIMUM, MAXIMUM}) {
      fixture.line("set(lengths, 0, " + badLength + ");");
      fixture.word("starts", "lengths", "0", "WORD_NAME", false);
    }
    fixture.line("set(lengths, 0, 4);");
    fixture.key("kinds", "starts", "lengths", "3", "0", true);
    for (String count : new String[] {"0", "1", "-1", MINIMUM, MAXIMUM}) {
      fixture.key("kinds", "starts", "lengths", count, "0", false);
    }
    for (String token : new String[] {"-1", "1", "2", "3", MINIMUM, MAXIMUM}) {
      fixture.key("kinds", "starts", "lengths", "3", token, false);
    }
    fixture.key("shortRows", "starts", "lengths", "3", "0", false);
    fixture.key("kinds", "shortRows", "lengths", "3", "0", false);
    fixture.key("kinds", "starts", "shortRows", "3", "0", false);
    fixture.line("set(kinds, 0, 6);");
    fixture.key("kinds", "starts", "lengths", "3", "0", false);
    fixture.line("set(kinds, 0, 1); set(kinds, 1, 1);");
    fixture.key("kinds", "starts", "lengths", "3", "0", false);
    fixture.line("set(kinds, 1, 3);");
    fixture.run(source, start, 4);
  }

  @Test
  void matchesEveryMetadataOnlyWordAndRejectsEveryCharacterMutation() throws Exception {
    List<Word> words = List.of(
        new Word("workspace", "WORKSPACE"), new Word("members", "MEMBERS"),
        new Word("packages", "PACKAGES"), new Word("repository", "REPOSITORY"),
        new Word("snapshot", "SNAPSHOT"), new Word("archive", "ARCHIVE"),
        new Word("manifest", "MANIFEST"), new Word("releases", "RELEASES"),
        new Word("3", "SCHEMA_THREE"));
    StringBuilder source = new StringBuilder("// café 𝄞\n");
    Fixture fixture = new Fixture();
    for (Word word : words) {
      fixture.text(source, word.text(), word.code(), true);
      for (int index = 0; index < word.text().length(); index++) {
        char[] changed = word.text().toCharArray();
        changed[index] ^= 1;
        fixture.text(source, new String(changed), word.code(), false);
      }
      fixture.text(source, "\0" + word.text(), word.code(), false);
      fixture.text(source, word.text() + "x", word.code(), false);
    }
    fixture.line("set(starts, 0, 0); set(lengths, 0, 4);");
    fixture.run(source.toString(), 0, 4);
  }

  @Test
  void rejectsNonAsciiWordsWithoutReadingContinuationBytesAsCharacters() throws Exception {
    Fixture common = new Fixture();
    common.word("starts", "lengths", "0", "WORD_NAME", false);
    common.run("éé", 0, 4);
    Fixture additional = new Fixture();
    additional.word("starts", "lengths", "0", "METADATA_WORD_ARCHIVE", false);
    additional.run("archié", 0, 7);
  }

  private record Word(String text, String suffix) {
    String code() {
      return "METADATA_WORD_" + suffix;
    }
  }

  private static final class Fixture {
    private final StringBuilder body = new StringBuilder();
    private int checks;

    void line(String statement) {
      body.append(statement).append('\n');
    }

    void text(StringBuilder source, String text, String code, boolean accepted) {
      int start = source.toString().getBytes(StandardCharsets.UTF_8).length;
      int length = text.getBytes(StandardCharsets.UTF_8).length;
      line("set(starts, 0, " + start + "); set(lengths, 0, " + length + ");");
      word("starts", "lengths", "0", code, accepted);
      source.append(text).append(' ');
    }

    void word(String starts, String lengths, String token, String expected, boolean accepted) {
      probe("metadataTokenEquals(source, " + starts + ", " + lengths + ", " + token
          + ", " + expected + ")", accepted);
    }

    void key(String kinds, String starts, String lengths, String count, String token,
        boolean accepted) {
      probe("metadataKeyAt(source, " + kinds + ", " + starts + ", " + lengths + ", "
          + count + ", " + token + ", WORD_NAME)", accepted);
    }

    private void probe(String call, boolean accepted) {
      line("boolean result" + checks + " = " + call + ";");
      line("assert(result" + checks + " == " + accepted + "); checks += 1;");
      checks++;
    }

    void run(String source, int start, int length) throws Exception {
      String fixture = """
          module example.metadata_tokens;
          import wheeler.compiler.packages.manifest_words;
          import wheeler.packages.metadata_tokens;
          classical class MetadataTokens {
            state long checks = 0;
            entry void main(borrow utf8 source, borrow mut bytes output) {
              region rows = new region(/* bytes= */ 80, /* objects= */ 4);
              words kinds = allocate(rows, /* length= */ 3);
              words starts = allocate(rows, /* length= */ 3);
              words lengths = allocate(rows, /* length= */ 3);
              words shortRows = allocate(rows, /* length= */ 1);
              set(kinds, 0, 1); set(kinds, 1, 3); set(kinds, 2, 2);
              set(starts, 0, START); set(starts, 1, START + LENGTH);
              set(starts, 2, START + LENGTH + 2);
              set(lengths, 0, LENGTH); set(lengths, 1, 1); set(lengths, 2, 1);
              set(shortRows, 0, 91);
              BODY
              assert(kinds[0] == 1); assert(kinds[1] == 3); assert(kinds[2] == 2);
              assert(starts[0] == START); assert(starts[1] == START + LENGTH);
              assert(starts[2] == START + LENGTH + 2);
              assert(lengths[0] == LENGTH); assert(lengths[1] == 1); assert(lengths[2] == 1);
              assert(shortRows[0] == 91);
              drop(shortRows); drop(lengths); drop(starts); drop(kinds); drop(rows);
            }
          }
          """.replace("START", Integer.toString(start)).replace("LENGTH", Integer.toString(length))
          .replace("BODY", body);
      var modules = PackageSources.withMetadataTokens(Map.of("MetadataFixture.w", fixture));
      var program = new WheelerCompiler().compileModuleFiles(modules, "example.metadata_tokens");
      var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8), 8);
      var initial = machine.snapshot();
      machine.run();
      assertEquals(checks, machine.global("checks"));
      assertArrayEquals(new byte[8], machine.hostOutput());
      while (machine.historySize() > 0) {
        machine.rewindOne();
      }
      assertEquals(initial, machine.snapshot());
    }
  }
}
