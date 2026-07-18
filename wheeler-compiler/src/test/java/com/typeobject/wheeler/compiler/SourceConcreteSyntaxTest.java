package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;
import org.junit.jupiter.api.Test;

class SourceConcreteSyntaxTest {
  @Test
  void reconstructsEveryTokenCommentAndWhitespaceByteForByte() {
    String source = "//! File summary.\r\n"
        + "module demo.main;\n\n"
        + "/// Entry summary.\n"
        + "classical class Demo { /* keep  two spaces */\n"
        + "\tentry void main() { // trailing\n"
        + "        long value = -2;\n"
        + "    }\n"
        + "}\n";

    SourceConcreteSyntax.Document document = SourceConcreteSyntax.scan(source);

    assertEquals(source, document.reconstruct());
    assertEquals(source.length(), document.elements().stream()
        .mapToInt(element -> element.text().length())
        .sum());
    int cursor = 0;
    for (SourceConcreteSyntax.Element element : document.elements()) {
      assertEquals(cursor, element.offset());
      cursor += element.text().length();
    }
    assertEquals(source.length(), cursor);
    assertEquals(
        List.of(
            SourceConcreteSyntax.Kind.LINE_COMMENT,
            SourceConcreteSyntax.Kind.WHITESPACE,
            SourceConcreteSyntax.Kind.TOKEN),
        document.elements().subList(0, 3).stream()
            .map(SourceConcreteSyntax.Element::kind)
            .toList());
    SourceConcreteSyntax.Element block = document.elements().stream()
        .filter(element -> element.kind() == SourceConcreteSyntax.Kind.BLOCK_COMMENT)
        .findFirst()
        .orElseThrow();
    assertEquals("/* keep  two spaces */", block.text());
    assertEquals(source.indexOf(block.text()), block.offset());
    assertEquals(5, block.line());
  }

  @Test
  void reportsMalformedCommentsThroughTheCompilerBoundary() {
    CompilerException failure = assertThrows(
        CompilerException.class,
        () -> SourceConcreteSyntax.scan("classical class Broken { /* nope"));

    assertEquals("line 1: unclosed block comment", failure.getMessage());
  }
}
