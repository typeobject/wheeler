package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Proves the shared byte-oriented source-tooling API. */
final class SourceToolingTest {
  @Test
  void returnsCanonicalBytesAndTheirMinimalEdit() {
    byte[] input = """
        //! Documents the π tooling module.
        module demo.tooling; classical class Tooling { /// Returns `value` unchanged.
        public long identity(long value){return value;} }
        """.getBytes(StandardCharsets.UTF_8);

    SourceTooling.FormatResult result = SourceTooling.format(input);
    assertArrayEquals(result.source(), apply(input, result.edit()));
    assertEquals(SourceFormatter.format(new String(input, StandardCharsets.UTF_8)),
        new String(result.source(), StandardCharsets.UTF_8));

    SourceTooling.FormatResult repeated = SourceTooling.format(result.source());
    assertArrayEquals(result.source(), repeated.source());
    assertEquals(repeated.edit().startByte(), repeated.edit().endByte());
    assertArrayEquals(new byte[0], repeated.edit().replacement());
  }

  @Test
  void ownsReturnedByteArrays() {
    byte[] input = """
        //! Summary.

        module demo.owned;

        classical class Owned {}
        """.getBytes(StandardCharsets.UTF_8);
    SourceTooling.FormatResult result = SourceTooling.format(input);
    byte[] source = result.source();
    source[0] = 0;
    byte[] replacement = result.edit().replacement();
    if (replacement.length > 0) {
      replacement[0] = 0;
    }

    assertEquals('/', result.source()[0]);
    assertArrayEquals(SourceTooling.format(input).edit().replacement(), result.edit().replacement());
  }

  @Test
  void returnsParserOwnedDocumentationAndDiagnostics() {
    byte[] input = """
        //! Tooling summary.

        module demo.documentation;

        classical class Documentation {
          /// Returns `value` unchanged.
          public long identity(long value) {
            return value;
          }
        }
        """.getBytes(StandardCharsets.UTF_8);

    SourceDocumentation.Analysis result = SourceTooling.checkDocumentation(input);
    assertTrue(result.diagnostics().isEmpty());
    assertEquals("demo.documentation", result.documentation().module());
    assertEquals("Tooling summary.", result.documentation().summary());
    assertEquals("identity", result.documentation().declarations().getFirst().name());
  }

  @Test
  void rejectsMalformedUtf8BeforeTooling() {
    byte[] malformed = {(byte) 0xc3, 0x28};
    assertThrows(CompilerException.class, () -> SourceTooling.format(malformed));
    assertThrows(CompilerException.class, () -> SourceTooling.checkDocumentation(malformed));
  }

  private static byte[] apply(byte[] input, SourceTooling.TextEdit edit) {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    output.writeBytes(java.util.Arrays.copyOfRange(input, 0, edit.startByte()));
    output.writeBytes(edit.replacement());
    output.writeBytes(java.util.Arrays.copyOfRange(input, edit.endByte(), input.length));
    return output.toByteArray();
  }
}
