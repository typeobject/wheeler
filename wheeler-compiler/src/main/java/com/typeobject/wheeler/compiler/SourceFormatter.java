package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceConcreteSyntax.CommentAttachment;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Element;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Kind;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Placement;
import java.util.ArrayDeque;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Initial deterministic Wheeler source layout engine over lossless lexical ranges. */
public final class SourceFormatter {
  private static final Set<String> OPERATORS = Set.of(
      "=", "==", "+=", "-=", "^=", "+", "-", "*", "/", "%", "&", "^", "<");
  private static final Set<String> CONTROL_HEADERS = Set.of(
      "if", "while", "for", "match", "switch", "catch");

  private SourceFormatter() {}

  /** Formats one bounded lexical document with the fixed stage-0 whitespace rules. */
  public static String format(String source) {
    SourceConcreteSyntax.Document document = SourceConcreteSyntax.scan(source);
    validateDelimiters(document.elements());
    return new Printer(document).print();
  }

  private static void validateDelimiters(List<Element> elements) {
    ArrayDeque<Element> delimiters = new ArrayDeque<>();
    for (Element element : elements) {
      if (element.kind() != Kind.TOKEN) {
        continue;
      }
      if (element.text().equals("(")
          || element.text().equals("[")
          || element.text().equals("{")) {
        delimiters.push(element);
      } else if (element.text().equals(")")
          || element.text().equals("]")
          || element.text().equals("}")) {
        if (delimiters.isEmpty() || !matches(delimiters.peek().text(), element.text())) {
          throw new CompilerException(element.line(), "unmatched delimiter '" + element.text() + "'");
        }
        delimiters.pop();
      }
    }
    if (!delimiters.isEmpty()) {
      Element delimiter = delimiters.getLast();
      throw new CompilerException(delimiter.line(), "unclosed delimiter '" + delimiter.text() + "'");
    }
  }

  private static boolean matches(String opener, String closer) {
    return opener.equals("(") && closer.equals(")")
        || opener.equals("[") && closer.equals("]")
        || opener.equals("{") && closer.equals("}");
  }

  private static final class Printer {
    private final List<Element> elements;
    private final Map<Integer, CommentAttachment> comments = new HashMap<>();
    private final String[] followingTokens;
    private final StringBuilder result = new StringBuilder();
    private int indent;
    private int parenthesisDepth;
    private boolean lineStart = true;
    private boolean pendingBlank;
    private String previousToken;

    private Printer(SourceConcreteSyntax.Document document) {
      elements = document.elements();
      followingTokens = new String[elements.size()];
      String following = "";
      for (int index = elements.size() - 1; index >= 0; index--) {
        followingTokens[index] = following;
        if (elements.get(index).kind() == Kind.TOKEN) {
          following = elements.get(index).text();
        }
      }
      document.comments().forEach(comment -> comments.put(comment.commentElement(), comment));
    }

    private String print() {
      for (int index = 0; index < elements.size(); index++) {
        Element element = elements.get(index);
        switch (element.kind()) {
          case WHITESPACE -> pendingBlank |= lineBreaks(element.text()) > 1;
          case LINE_COMMENT, BLOCK_COMMENT -> comment(index, element);
          case TOKEN -> token(index, element.text());
        }
      }
      int end = result.length();
      while (end > 0 && Character.isWhitespace(result.charAt(end - 1))) {
        end--;
      }
      return result.substring(0, end) + "\n";
    }

    private void comment(int index, Element element) {
      if (pendingBlank && lineStart && result.length() > 0) {
        blankLine();
      }
      pendingBlank = false;
      CommentAttachment attachment = comments.get(index);
      Placement placement = attachment == null ? Placement.DETACHED : attachment.placement();
      if (placement == Placement.TRAILING) {
        space();
      } else {
        if (!lineStart) {
          newline();
        }
        if (placement == Placement.DETACHED && result.length() > 0) {
          blankLine();
        }
        indentation();
      }
      result.append(normalizeComment(element));
      newline();
      if (placement == Placement.DETACHED) {
        pendingBlank = true;
      }
      previousToken = null;
    }

    private void token(int index, String text) {
      if (pendingBlank && lineStart && result.length() > 0) {
        blankLine();
      }
      pendingBlank = false;
      switch (text) {
        case "{" -> openBrace(index);
        case "}" -> closeBrace(index);
        case ";" -> semicolon();
        case "," -> comma();
        case "(" -> openParenthesis();
        case ")" -> closeParenthesis();
        case "[" -> appendTight(text);
        case "]" -> appendTight(text);
        case ".", "::" -> appendTight(text);
        default -> {
          if (OPERATORS.contains(text)) {
            operator(text);
          } else {
            word(text);
          }
        }
      }
      previousToken = text;
    }

    private void openBrace(int index) {
      if (!lineStart) {
        space();
      } else {
        indentation();
      }
      result.append('{');
      indent++;
      if (!nextToken(index).equals("}")) {
        newline();
      }
    }

    private void closeBrace(int index) {
      indent--;
      if (indent < 0) {
        throw new IllegalStateException("Negative source indentation");
      }
      if (previousToken != null && previousToken.equals("{")) {
        result.append('}');
      } else {
        if (!lineStart) {
          newline();
        }
        indentation();
        result.append('}');
      }
      String next = nextToken(index);
      if (next.equals("else")) {
        result.append(' ');
      } else if (!next.equals(";") && !next.equals(",") && !next.equals(")")) {
        newline();
      }
    }

    private void semicolon() {
      trimSpaces();
      result.append(';');
      if (parenthesisDepth == 0) {
        newline();
      } else {
        result.append(' ');
      }
    }

    private void comma() {
      trimSpaces();
      result.append(',').append(' ');
    }

    private void openParenthesis() {
      if (CONTROL_HEADERS.contains(previousToken)) {
        space();
      }
      appendRaw("(");
      parenthesisDepth++;
    }

    private void closeParenthesis() {
      trimSpaces();
      appendRaw(")");
      parenthesisDepth--;
    }

    private void operator(String operator) {
      if ((operator.equals("-") || operator.equals("+")) && unaryOperator()) {
        result.append(operator);
        return;
      }
      space();
      result.append(operator);
      result.append(' ');
    }

    private boolean unaryOperator() {
      return previousToken == null
          || previousToken.equals("(")
          || previousToken.equals("[")
          || previousToken.equals(",")
          || OPERATORS.contains(previousToken);
    }

    private void word(String text) {
      if (needsWordSpace()) {
        space();
      }
      appendRaw(text);
    }

    private boolean needsWordSpace() {
      if (previousToken == null) {
        return false;
      }
      return !previousToken.equals("(")
          && !previousToken.equals("[")
          && !previousToken.equals(".")
          && !previousToken.equals("::")
          && !OPERATORS.contains(previousToken);
    }

    private void appendTight(String text) {
      trimSpaces();
      appendRaw(text);
    }

    private void appendRaw(String text) {
      indentation();
      result.append(text);
      lineStart = false;
    }

    private void indentation() {
      if (!lineStart) {
        return;
      }
      result.append("    ".repeat(indent));
      lineStart = false;
    }

    private void space() {
      if (lineStart) {
        indentation();
      } else if (!result.isEmpty() && result.charAt(result.length() - 1) != ' ') {
        result.append(' ');
      }
    }

    private void trimSpaces() {
      while (!result.isEmpty() && result.charAt(result.length() - 1) == ' ') {
        result.setLength(result.length() - 1);
      }
    }

    private void newline() {
      trimSpaces();
      if (result.isEmpty() || result.charAt(result.length() - 1) != '\n') {
        result.append('\n');
      }
      lineStart = true;
    }

    private void blankLine() {
      newline();
      if (result.length() < 2 || result.charAt(result.length() - 2) != '\n') {
        result.append('\n');
      }
      lineStart = true;
    }

    private String nextToken(int elementIndex) {
      return followingTokens[elementIndex];
    }
  }

  private static String normalizeComment(Element element) {
    String text = element.text().replace("\r\n", "\n").replace('\r', '\n');
    if (element.kind() != Kind.LINE_COMMENT
        || !text.startsWith("///") && !text.startsWith("//!")) {
      return text;
    }
    String marker = text.substring(0, 3);
    String payload = text.substring(3);
    if (payload.startsWith(" ")) {
      payload = payload.substring(1);
    }
    return payload.isEmpty() ? marker : marker + " " + payload;
  }

  private static int lineBreaks(String text) {
    int result = 0;
    for (int index = 0; index < text.length(); index++) {
      if (text.charAt(index) == '\n') {
        result++;
      }
    }
    return result;
  }
}
