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
        + "long finished=value;}}";
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

            long finished = value;
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
  void keepsClosedSlotArgumentsTightAndComparisonsSpaced() {
    String compact = "classical class Presence{Slot<Slot<long>> wrap(){"
        + "return new Slot<Slot<long>>.Holding(new Slot<long>.Vacant());}"
        + "entry void main(){assert(1<2);}}";

    String formatted = SourceFormatter.format(compact);

    assertTrue(formatted.contains("Slot<Slot<long>> wrap()"));
    assertTrue(formatted.contains("new Slot<Slot<long>>.Holding("));
    assertTrue(formatted.contains("assert(1 < 2);"));
    assertEquals(formatted, SourceFormatter.format(formatted));
    assertArrayEquals(
        new WheelerCompiler().compileToBytecode(compact),
        new WheelerCompiler().compileToBytecode(formatted));
  }

  @Test
  void keepsCanonicalArgumentLabelsBesideTheirValues() {
    String compact = "//! Labeled arguments.\nclassical class Labels { "
        + "long shortCall() { return f(/* value= */0,/* width= */8); } "
        + "long longCall() { return writeUnsignedLittleEndian(output, cursor, "
        + "/* value= */0, /* width= */8); } }";

    String formatted = SourceFormatter.format(compact);

    assertTrue(formatted.contains(
        "return f(/* value= */ 0, /* width= */ 8);"));
    assertTrue(formatted.contains(
        "return writeUnsignedLittleEndian("
            + "output, cursor, /* value= */ 0, /* width= */ 8);"));
    assertEquals(formatted, SourceFormatter.format(formatted));
    assertEquals(tokens(compact), tokens(formatted));
    assertEquals(comments(compact), comments(formatted));
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
  void breaksBoundedLoopHeadersAtTheSmallestConditionGroup() {
    String source = "classical class Loops { entry void main() { while ("
        + "currentInstructionCoordinateWithLongName < finalInstructionCoordinateWithLongName"
        + ") limit 4096 { assert(true); } } }";

    String formatted = SourceFormatter.format(source);

    assertTrue(formatted.contains("""
            while (
              currentInstructionCoordinateWithLongName < finalInstructionCoordinateWithLongName
            ) limit 4096 {
        """));
    assertEquals(formatted, SourceFormatter.format(formatted));
  }

  @Test
  void breaksArrayInitializersWithoutMovingTheirEnclosingDeclaration() {
    String source = "classical class Arrays { public long[5] values() { return new long[5]("
        + "firstCanonicalValue, secondCanonicalValue, thirdCanonicalValue, "
        + "fourthCanonicalValue, fifthCanonicalValue); } }";

    String formatted = SourceFormatter.format(source);

    assertTrue(formatted.contains("""
            return new long[5](
              firstCanonicalValue,
              secondCanonicalValue,
              thirdCanonicalValue,
              fourthCanonicalValue,
              fifthCanonicalValue
            );
        """));
    assertEquals(formatted, SourceFormatter.format(formatted));
  }

  @Test
  void preservesDeeplyIndentedIndivisibleTokens() {
    String name = "canonicalIdentifier".repeat(7);
    String source = "classical class Deep { entry void main() { if (true) { if (true) { "
        + "long " + name + " = 1; assert(" + name + " == 1); } } } }";

    String formatted = SourceFormatter.format(source);

    assertTrue(formatted.contains("        long " + name + " = 1;"));
    assertTrue(formatted.lines().anyMatch(line -> line.length() > 100));
    assertEquals(tokens(source), tokens(formatted));
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
        + "thirdArgument, fourthArgument, -1); assert(!!false); assert(firstArgument != -3); "
        + "return -2; } }";

    String formatted = SourceFormatter.format(source);

    assertTrue(formatted.contains("\n      -1\n"));
    assertTrue(formatted.contains("return -2;"));
    assertTrue(formatted.contains("assert(!!false);"));
    assertTrue(formatted.contains("firstArgument != -3"));
    assertFalse(formatted.contains("! !"));
    assertFalse(formatted.contains("- 1"));
    assertFalse(formatted.contains("- 2"));
    assertFalse(formatted.contains("- 3"));
  }

  @Test
  void normalizesLineEndingsFinalNewlinesAndIndentation() {
    String lf = "classical class Lines{entry void main(){long value=1;}}";
    String crlf = lf.replace("{", "{\r\n").replace(";", ";\r\n");
    String cr = lf.replace("{", "{\r").replace(";", ";\r");

    String canonical = SourceFormatter.format(lf);

    assertEquals(canonical, SourceFormatter.format(crlf));
    assertEquals(canonical, SourceFormatter.format(cr));
    assertTrue(canonical.endsWith("\n"));
    assertFalse(canonical.contains("\r"));
    assertTrue(canonical.contains("\n  entry void main() {\n    long value = 1;\n"));
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
  void preservesDocumentationListsLinksFencesAndSemanticLineBreaks() {
    String source = "classical class Docs{"
        + "///Summary line.\n"
        + "///\n"
        + "///- Inputs: [`value`](reference.md) stays exact.\n"
        + "///\n"
        + "///```wheeler\n"
        + "///assert(value == 1);\n"
        + "///```\n"
        + "public long identity(long value){return value;}}";

    String formatted = SourceFormatter.format(source);

    assertEquals(comments(source), comments(formatted));
    assertTrue(formatted.contains("/// - Inputs: [`value`](reference.md) stays exact."));
    assertTrue(formatted.contains("/// ```wheeler\n"));
    assertTrue(formatted.contains("/// assert(value == 1);\n"));
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
  void listEditsChangeOnlyTheirSmallestVerticalLayoutGroup() {
    List<String> items = List.of(
        "alphaArgumentWithEnoughWidthToRequireVerticalLayout",
        "bravoArgumentWithEnoughWidthToRequireVerticalLayout",
        "charlieArgumentWithEnoughWidthToRequireVerticalLayout");
    String added = "deltaArgumentWithEnoughWidthToRequireVerticalLayout";
    String three = SourceFormatter.format(listSource(items));
    int firstStart = three.indexOf(items.getFirst());
    String indent = three.substring(three.lastIndexOf('\n', firstStart) + 1, firstStart);

    for (int index = 0; index < items.size(); index++) {
      String renamed = "renamed" + index + "ArgumentWithEnoughWidthToRequireVerticalLayout";
      var edited = new java.util.ArrayList<>(items);
      edited.set(index, renamed);
      assertEquals(three.replace(items.get(index), renamed),
          SourceFormatter.format(listSource(edited)));
    }

    for (int index = 0; index <= items.size(); index++) {
      var edited = new java.util.ArrayList<>(items);
      edited.add(index, added);
      String four = SourceFormatter.format(listSource(edited));
      String addedLine = indent + added + (index < items.size() ? "," : "") + "\n";
      String restored = four.replace(addedLine, "");
      if (index == items.size()) {
        restored = restored.replace(items.getLast() + ",\n", items.getLast() + "\n");
      }
      assertEquals(three, restored, "insertion " + index);
      edited.remove(index);
      assertEquals(three, SourceFormatter.format(listSource(edited)), "removal " + index);
    }
  }

  @Test
  void generatedBreakCorpusChangesOnlyTheOwningSyntaxGroup() {
    String loopName = "currentInstructionCoordinateWithLongStableName";
    String renamedLoop = "renamedInstructionCoordinateWithLongStableName";
    String loop = "classical class Loops { entry void main() { while ("
        + loopName + " < finalInstructionCoordinateWithLongStableName) limit 4096 { "
        + "assert(true); } } }";
    String formattedLoop = SourceFormatter.format(loop);
    assertEquals(
        formattedLoop.replace(loopName, renamedLoop),
        SourceFormatter.format(loop.replace(loopName, renamedLoop)));

    List<String> values = List.of(
        "alphaCanonicalArrayInitializerValue",
        "bravoCanonicalArrayInitializerValue",
        "charlieCanonicalArrayInitializerValue");
    String three = SourceFormatter.format(arraySource(values));
    String added = "deltaCanonicalArrayInitializerValue";
    for (int index = 0; index <= values.size(); index++) {
      var edited = new java.util.ArrayList<>(values);
      edited.add(index, added);
      String four = SourceFormatter.format(arraySource(edited));
      String restored = four.replace(
          "      " + added + (index < values.size() ? "," : "") + "\n", "");
      if (index == values.size()) {
        restored = restored.replace(values.getLast() + ",\n", values.getLast() + "\n");
      }
      restored = restored.replace("long[4]", "long[3]");
      assertEquals(three, restored, "array insertion " + index);
      assertEquals(tokens(arraySource(edited)), tokens(four));
      assertEquals(four, SourceFormatter.format(four));
    }

    String left = "firstAggregateValueWithLongCanonicalStableName";
    String renamedLeft = "otherAggregateValueWithLongCanonicalStableName";
    String expression = "classical class Expressions { entry void main() { boolean equal = "
        + left + " == secondAggregateValueWithLongCanonicalStableName; } }";
    String formattedExpression = SourceFormatter.format(expression);
    assertEquals(
        formattedExpression.replace(left, renamedLeft),
        SourceFormatter.format(expression.replace(left, renamedLeft)));

    for (int depth = 1; depth < 9; depth++) {
      StringBuilder source = new StringBuilder("classical class Deep { entry void main() {");
      source.append(" if (true) {".repeat(depth));
      source.append(" long ").append("indivisibleIdentifier".repeat(8)).append(" = 1;");
      source.append(" }".repeat(depth)).append(" } }");
      String formatted = SourceFormatter.format(source.toString());
      assertEquals(tokens(source.toString()), tokens(formatted));
      assertEquals(formatted, SourceFormatter.format(formatted));
    }
  }

  @Test
  void rejectsMismatchedDelimitersBeforePrinting() {
    CompilerException failure = assertThrows(
        CompilerException.class,
        () -> SourceFormatter.format("classical class Broken { entry void main(] {} }"));
    assertEquals("line 1: unmatched delimiter ']'", failure.getMessage());
  }

  private static String listSource(List<String> items) {
    return "classical class Lists { entry void main() { invoke("
        + String.join(",", items) + "); } }";
  }

  private static String arraySource(List<String> items) {
    return "classical class Arrays { public long[" + items.size()
        + "] values() { return new long[" + items.size() + "] ("
        + String.join(",", items) + "); } }";
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
