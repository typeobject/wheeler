package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Kind;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Conformance tests for lossless deterministic formatting and corpus stability. */
class SourceFormatterTest {
  @Test
  void formatsFixedWhitespacePreservesTokensAndIsIdempotent() {
    String compact = "//!Summary\r\n"
        + "classical   class Demo{\n"
        + "///Runs the entry.\n"
        + "///\n"
        + "///- Effects: Mutates `value`.\n"
        + "entry void main(){long value=-2;if(value<0){value+=1;}else{value=0;}"
        + "long done=value;}}";
    String expected = """
        //! Summary
        classical class Demo {
          /// Runs the entry.
          ///
          /// - Effects: Mutates `value`.
          entry void main() {
            long value = -2;
            if (value < 0) {
              value += 1;
            } else {
              value = 0;
            }

            long done = value;
          }
        }
        """;

    String formatted = SourceFormatter.format(compact);

    assertEquals(expected, formatted);
    assertEquals(formatted, SourceFormatter.format(formatted));
    assertEquals(tokens(compact), tokens(formatted));
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode(compact),
        new WheelerCompiler().compileToBytecode(formatted));
  }

  @Test
  void separatesModuleImportsAndCompoundStatements() {
    String source = "module demo;import values;import words;classical class Demo { "
        + "entry void main() { if (true) { assert(true); } assert(true); } }";

    String formatted = SourceFormatter.format(source);

    assertTrue(formatted.startsWith("""
        module demo;

        import values;
        import words;

        classical class Demo {
        """));
    assertTrue(formatted.contains("""
            if (true) {
              assert(true);
            }

            assert(true);
        """));
    assertEquals(formatted, SourceFormatter.format(formatted));
  }

  @Test
  void separatesLoopsMatchesMethodsAndAttachedComments() {
    String source = "classical class Spacing { void helper() { "
        + "while (false) limit 1 { assert(true); } // explain the following check\n"
        + "assert(true); } entry void main() { match (choice) { "
        + "case Choice.Left() { assert(true); } "
        + "case Choice.Right() { assert(true); } } assert(true); } }";

    String formatted = SourceFormatter.format(source);

    assertTrue(formatted.contains("""
            while (false) limit 1 {
              assert(true);
            }

            // explain the following check
            assert(true);
        """));
    assertTrue(formatted.contains("""
              case Choice.Left() {
                assert(true);
              }
              case Choice.Right() {
        """));
    assertTrue(formatted.contains("""
              }
            }

            assert(true);
        """));
    assertTrue(formatted.contains("""
            assert(true);
          }

          entry void main() {
        """));
    assertEquals(formatted, SourceFormatter.format(formatted));
  }

  @Test
  void breaksOnlyTheSmallestCommaGroupThatExceedsOneHundredScalars() {
    String compact = "classical class Wide { public long combine(long firstValue, "
        + "long secondValue, long thirdValue, long fourthValue, long fifthValue) { "
        + "return sum(firstValue, secondValue, thirdValue, fourthValue, fifthValue); } }";

    String formatted = SourceFormatter.format(compact);

    assertTrue(formatted.contains("""
          public long combine(
            long firstValue,
            long secondValue,
            long thirdValue,
            long fourthValue,
            long fifthValue
          ) {
        """));
    assertTrue(formatted.contains(
        "return sum(firstValue, secondValue, thirdValue, fourthValue, fifthValue);"));
    assertTrue(formatted.lines()
        .filter(line -> !line.stripLeading().startsWith("//"))
        .allMatch(line -> line.codePointCount(0, line.length()) <= 100));
    assertEquals(formatted, SourceFormatter.format(formatted));
  }

  @Test
  void breaksLongBinaryExpressionsWithLeadingContinuationOperators() {
    String source = "classical class Expression { entry void main() { boolean equal = "
        + "firstAggregateValueWithLongCanonicalName == "
        + "secondAggregateValueWithLongCanonicalName; } }";

    String formatted = SourceFormatter.format(source);

    assertTrue(formatted.contains("""
            boolean equal = firstAggregateValueWithLongCanonicalName
              == secondAggregateValueWithLongCanonicalName;
        """));
    assertEquals(formatted, SourceFormatter.format(formatted));
  }

  @Test
  void keepsUnaryOperatorsTightAfterReturnsAndVerticalCommas() {
    String source = "classical class Signed { public long choose(long firstArgument, "
        + "long secondArgument, long thirdArgument, long fourthArgument, "
        + "long fifthArgument) { call(firstArgument, secondArgument, thirdArgument, "
        + "fourthArgument, fifthArgument, firstArgument, secondArgument, "
        + "thirdArgument, fourthArgument, -1); assert(!!false); return -2; } }";

    String formatted = SourceFormatter.format(source);

    assertTrue(formatted.contains("\n      -1\n"));
    assertTrue(formatted.contains("return -2;"));
    assertTrue(formatted.contains("assert(!!false);"));
    assertFalse(formatted.contains("! !"));
    assertFalse(formatted.contains("- 1"));
    assertFalse(formatted.contains("- 2"));
  }

  @Test
  void preservesCommentPayloadAndNormalizesBlockLineEndings() {
    String source = "classical class C{/* first  payload */\r\n"
        + "entry void main(){// trailing  payload\r\n}}";

    String formatted = SourceFormatter.format(source);

    assertFalse(formatted.contains("\r"));
    assertTrue(formatted.contains("/* first  payload */"));
    assertTrue(formatted.contains("// trailing  payload"));
    assertEquals(formatted, SourceFormatter.format(formatted));
  }

  @Test
  void roundTripsEveryCanonicalSourceTokenAndCommentAttachment() throws Exception {
    for (Path root : List.of(
        Path.of("src/main/wheeler"),
        Path.of("../wheeler-core/src/main/wheeler"),
        Path.of("../wheeler-examples/src/main/wheeler"),
        Path.of("../wheeler-package/src/main/wheeler"),
        Path.of("../wheeler-runtime/src/main/wheeler"))) {
      try (var paths = Files.walk(root)) {
        for (Path source : paths.filter(path -> path.toString().endsWith(".w")).toList()) {
          String original = Files.readString(source);
          String formatted = SourceFormatter.format(original);
          assertEquals(original, formatted, source.toString());
          assertEquals(formatted, SourceFormatter.format(formatted), source.toString());
          assertEquals(tokens(original), tokens(formatted), source.toString());
          assertEquals(comments(original), comments(formatted), source.toString());
          assertEquals(attachments(original), attachments(formatted), source.toString());
          assertTrue(formatted.lines()
              .filter(line -> !line.stripLeading().startsWith("//"))
              .allMatch(line -> line.codePointCount(0, line.length()) <= 100),
              source.toString());
        }
      }
    }
  }

  @Test
  void rejectsMismatchedDelimitersBeforePrinting() {
    CompilerException failure = assertThrows(
        CompilerException.class,
        () -> SourceFormatter.format("classical class Broken { entry void main(] {} }"));
    assertEquals("line 1: unmatched delimiter ']'", failure.getMessage());
  }

  private static List<String> tokens(String source) {
    return SourceConcreteSyntax.scan(source).elements().stream()
        .filter(element -> element.kind() == Kind.TOKEN)
        .map(SourceConcreteSyntax.Element::text)
        .toList();
  }

  private static List<String> attachments(String source) {
    SourceConcreteSyntax.Document document = SourceConcreteSyntax.scan(source);
    int[] tokenOrdinals = new int[document.elements().size()];
    int token = 0;
    for (int index = 0; index < document.elements().size(); index++) {
      tokenOrdinals[index] = token;
      if (document.elements().get(index).kind() == Kind.TOKEN) {
        token++;
      }
    }
    return document.comments().stream()
        .map(comment -> {
          if (comment.targetNode() < 0) {
            return comment.placement() + ":-1";
          }
          SourceConcreteSyntax.SyntaxNode node = document.nodes().get(comment.targetNode());
          return comment.placement() + ":" + node.kind() + ":"
              + tokenOrdinals[node.startElement()] + ":" + tokenOrdinals[node.endElement()];
        })
        .toList();
  }

  private static List<String> comments(String source) {
    return SourceConcreteSyntax.scan(source).elements().stream()
        .filter(element -> element.kind() == Kind.LINE_COMMENT
            || element.kind() == Kind.BLOCK_COMMENT)
        .map(element -> element.kind() + ":" + commentPayload(element))
        .toList();
  }

  private static String commentPayload(SourceConcreteSyntax.Element element) {
    String text = element.text().replace("\r\n", "\n").replace('\r', '\n');
    if (element.kind() == Kind.LINE_COMMENT
        && (text.startsWith("///") || text.startsWith("//!"))) {
      String payload = text.substring(3);
      return payload.startsWith(" ") ? payload.substring(1) : payload;
    }
    return text;
  }
}
