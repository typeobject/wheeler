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

    SourceConcreteSyntax.CommentAttachment fileDocumentation = document.comments().stream()
        .filter(comment -> document.elements().get(comment.commentElement()).text()
            .equals("//! File summary."))
        .findFirst()
        .orElseThrow();
    assertEquals(SourceConcreteSyntax.Placement.LEADING, fileDocumentation.placement());
    assertEquals("module", document.elements().get(fileDocumentation.targetElement()).text());
    SourceConcreteSyntax.CommentAttachment trailing = document.comments().stream()
        .filter(comment -> document.elements().get(comment.commentElement()).text()
            .equals("// trailing"))
        .findFirst()
        .orElseThrow();
    assertEquals(SourceConcreteSyntax.Placement.TRAILING, trailing.placement());
  }

  @Test
  void distinguishesInnerAndDetachedComments() {
    SourceConcreteSyntax.Document inner = SourceConcreteSyntax.scan(
        "classical class Empty { /* retained */ }\n");
    assertEquals(SourceConcreteSyntax.Placement.INNER, inner.comments().getFirst().placement());
    assertEquals("{", inner.elements().get(inner.comments().getFirst().targetElement()).text());

    SourceConcreteSyntax.Document detached = SourceConcreteSyntax.scan(
        "// detached\n\nclassical class Later {}\n");
    assertEquals(
        SourceConcreteSyntax.Placement.DETACHED,
        detached.comments().getFirst().placement());
    assertEquals(-1, detached.comments().getFirst().targetElement());
  }

  @Test
  void reportsMalformedCommentsThroughTheCompilerBoundary() {
    CompilerException failure = assertThrows(
        CompilerException.class,
        () -> SourceConcreteSyntax.scan("classical class Broken { /* nope"));

    assertEquals("line 1: unclosed block comment", failure.getMessage());
  }
}
