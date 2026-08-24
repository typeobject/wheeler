package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Editor adapter evidence for scalar-safe edits and parser-owned diagnostics. */
final class SourceEditorToolingTest {
  @Test
  void formattingReturnsOneApplicableScalarAlignedEdit() {
    List<String> inputs = List.of(
        """
        //! Unicode 😀 edit fixture.
        classical class UnicodeEdit {
          entry void main() {
            long value = utf8Length("value") ;
          }
        }
        """,
        "//! CRLF fixture.\r\nclassical class CrLf{entry void main(){}}\r\n",
        """
        //! Canonical fixture.
        classical class Canonical {}
        """);

    for (String input : inputs) {
      byte[] bytes = input.getBytes(StandardCharsets.UTF_8);
      SourceEditorTooling.TextEdit edit = SourceEditorTooling.format(bytes);
      String applied = apply(input, edit);
      String expected = new String(SourceTooling.format(bytes).source(), StandardCharsets.UTF_8);
      assertEquals(expected, applied);
      assertScalarBoundary(input, offsetAt(input, edit.range().start()));
      assertScalarBoundary(input, offsetAt(input, edit.range().end()));
    }
  }

  @Test
  void documentationDiagnosticsUseZeroBasedUtf16Coordinates() {
    String source = "//! 😀 source.\r\n"
        + "classical class MissingDeclarationDocs {\r\n"
        + "  /* 😀 */ public long value() { return 1; }\r\n"
        + "}\r\n";

    List<SourceEditorTooling.Diagnostic> diagnostics =
        SourceEditorTooling.checkDocumentation(source.getBytes(StandardCharsets.UTF_8));

    assertEquals(1, diagnostics.size());
    SourceEditorTooling.Diagnostic diagnostic = diagnostics.getFirst();
    assertEquals("WDOC002", diagnostic.code());
    assertEquals(new SourceEditorTooling.Position(2, 11), diagnostic.range().start());
    assertEquals(diagnostic.range().start(), diagnostic.range().end());
    assertEquals(
        "declaration 'value' requires /// documentation", diagnostic.message());
  }

  @Test
  void malformedUtf8ProducesNoEditorResult() {
    byte[] malformed = {(byte) 0xc0};
    assertThrows(CompilerException.class, () -> SourceEditorTooling.format(malformed));
    assertThrows(
        CompilerException.class,
        () -> SourceEditorTooling.checkDocumentation(malformed));
  }

  private static String apply(String input, SourceEditorTooling.TextEdit edit) {
    int start = offsetAt(input, edit.range().start());
    int end = offsetAt(input, edit.range().end());
    return input.substring(0, start) + edit.replacement() + input.substring(end);
  }

  private static int offsetAt(String source, SourceEditorTooling.Position target) {
    int line = 0;
    int character = 0;
    for (int index = 0; index <= source.length(); index++) {
      if (line == target.line() && character == target.character()) {
        return index;
      }
      if (index == source.length()) {
        break;
      }
      char value = source.charAt(index);
      if (value == '\r') {
        if (index + 1 < source.length() && source.charAt(index + 1) == '\n') {
          index++;
        }
        line++;
        character = 0;
      } else if (value == '\n') {
        line++;
        character = 0;
      } else {
        character++;
      }
    }
    throw new IllegalArgumentException("Editor position exceeds source");
  }

  private static void assertScalarBoundary(String source, int offset) {
    if (0 < offset && offset < source.length()) {
      boolean splitsSurrogate = Character.isHighSurrogate(source.charAt(offset - 1))
          && Character.isLowSurrogate(source.charAt(offset));
      assertFalse(splitsSurrogate);
    }
  }
}
