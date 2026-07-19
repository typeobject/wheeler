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
      "=", "==", "+=", "-=", "^=", "+", "-", "*", "/", "%", "!", "&", "^", "<");
  private static final Set<String> CONTROL_HEADERS = Set.of(
      "if", "while", "for", "match", "switch", "catch", "reverse");
  private static final int LINE_TARGET = 100;
  private static final String INDENT = "  ";

  private SourceFormatter() {}

  /** Formats one bounded lexical document with the fixed stage-0 whitespace rules. */
  public static String format(String source) {
    SourceConcreteSyntax.Document document = SourceConcreteSyntax.scan(source);
    if (!document.recoveries().isEmpty()) {
      SourceConcreteSyntax.Recovery recovery = document.recoveries().getFirst();
      throw new CompilerException(recovery.line(), recovery.message());
    }
    return new Printer(document).print();
  }

  private static final class Printer {
    private final List<Element> elements;
    private final Map<Integer, CommentAttachment> comments = new HashMap<>();
    private final String[] followingTokens;
    private final int[] delimiterMates;
    private final ArrayDeque<Boolean> verticalParentheses = new ArrayDeque<>();
    private final ArrayDeque<Boolean> controlBraces = new ArrayDeque<>();
    private final StringBuilder result = new StringBuilder();
    private int indent;
    private int parenthesisDepth;
    private boolean lineStart = true;
    private boolean pendingBlank;
    private String previousToken;
    private String statementHead;

    private Printer(SourceConcreteSyntax.Document document) {
      elements = document.elements();
      followingTokens = new String[elements.size()];
      delimiterMates = delimiterMates(elements);
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
        if (result.length() > SourceLexer.MAX_SOURCE_CHARS) {
          throw new CompilerException(
              element.line(), "formatted source exceeds the 16 Mi-character limit");
        }
      }
      int end = result.length();
      while (end > 0 && Character.isWhitespace(result.charAt(end - 1))) {
        end--;
      }
      String formatted = wrapCodeLines(result.substring(0, end) + "\n");
      if (formatted.length() > SourceLexer.MAX_SOURCE_CHARS) {
        int line = elements.isEmpty() ? 1 : elements.getLast().line();
        throw new CompilerException(line, "formatted source exceeds the 16 Mi-character limit");
      }
      return formatted;
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
      if (statementHead == null && lineStart && isStatementWord(text)) {
        statementHead = text;
      }
      switch (text) {
        case "{" -> openBrace(index);
        case "}" -> closeBrace(index);
        case ";" -> semicolon(index);
        case "," -> comma();
        case "(" -> openParenthesis(index);
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
      boolean control = statementHead != null && CONTROL_HEADERS.contains(statementHead)
          || "else".equals(previousToken);
      controlBraces.push(control);
      statementHead = null;
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
      boolean control = controlBraces.pop();
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
        // Member and top-level declarations breathe too; case arms remain compact.
        if ((control || indent <= 1) && !next.equals("}") && !next.equals("case")) {
          blankLine();
        }
      }
      statementHead = null;
    }

    private void semicolon(int index) {
      trimSpaces();
      result.append(';');
      if (parenthesisDepth == 0 || currentParenthesisVertical()) {
        newline();
        String next = nextToken(index);
        if ("module".equals(statementHead)
            || "import".equals(statementHead) && !next.equals("import")) {
          blankLine();
        }
        statementHead = null;
      } else {
        result.append(' ');
      }
    }

    private void comma() {
      trimSpaces();
      result.append(',');
      if (currentParenthesisVertical()) {
        newline();
      } else {
        result.append(' ');
      }
    }

    private void openParenthesis(int index) {
      if (CONTROL_HEADERS.contains(previousToken)) {
        space();
      }
      // Keep room for the call separator and an empty control arm followed by `else`.
      int suffixHeadroom = previousToken != null && CONTROL_HEADERS.contains(previousToken)
          ? 10 : 1;
      boolean vertical = column() + flatGroupWidth(index) + suffixHeadroom > LINE_TARGET;
      appendRaw("(");
      parenthesisDepth++;
      verticalParentheses.push(vertical);
      if (vertical) {
        indent++;
        newline();
      }
    }

    private void closeParenthesis() {
      trimSpaces();
      boolean vertical = verticalParentheses.pop();
      if (vertical) {
        indent--;
        if (!lineStart) {
          newline();
        }
      }
      appendRaw(")");
      parenthesisDepth--;
    }

    private void operator(String operator) {
      if (operator.equals("!")
          || (operator.equals("-") || operator.equals("+")) && unaryOperator()) {
        if (previousToken != null
            && (previousToken.equals("return") || previousToken.equals("limit"))) {
          space();
        }
        appendRaw(operator);
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
          || previousToken.equals("return")
          || previousToken.equals("limit")
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
      result.append(INDENT.repeat(indent));
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

    private static boolean isStatementWord(String text) {
      return !text.equals("{") && !text.equals("}")
          && !text.equals(";") && !text.equals(",")
          && !text.equals("(") && !text.equals(")")
          && !text.equals("[") && !text.equals("]")
          && !OPERATORS.contains(text);
    }

    private boolean currentParenthesisVertical() {
      return !verticalParentheses.isEmpty() && verticalParentheses.peek();
    }

    private int flatGroupWidth(int opener) {
      int closer = delimiterMates[opener];
      if (closer < 0) {
        throw new IllegalStateException("Parser accepted an unmatched parenthesis");
      }
      int width = 2;
      String previous = null;
      for (int index = opener + 1; index < closer; index++) {
        Element element = elements.get(index);
        if (element.kind() == Kind.LINE_COMMENT || element.kind() == Kind.BLOCK_COMMENT) {
          return LINE_TARGET + 1;
        }
        if (element.kind() != Kind.TOKEN) {
          continue;
        }
        String text = element.text();
        if (text.equals(",")) {
          width += 2;
        } else if (OPERATORS.contains(text)) {
          boolean unary = (text.equals("-") || text.equals("+"))
              && (previous == null || previous.equals("(") || previous.equals("[")
                  || previous.equals(",") || previous.equals("return")
                  || previous.equals("limit") || OPERATORS.contains(previous));
          int prefix = unary && ("return".equals(previous) || "limit".equals(previous)) ? 1 : 0;
          width += text.length() + (unary ? prefix : 2);
        } else {
          boolean space = previous != null
              && !previous.equals("(")
              && !previous.equals("[")
              && !previous.equals(".")
              && !previous.equals("::")
              && !OPERATORS.contains(previous)
              && !text.equals(")")
              && !text.equals("]")
              && !text.equals(".")
              && !text.equals("::");
          width += text.codePointCount(0, text.length()) + (space ? 1 : 0);
        }
        previous = text;
        if (width > LINE_TARGET) {
          return width;
        }
      }
      return width;
    }

    private int column() {
      int lineStartOffset = result.lastIndexOf("\n") + 1;
      return result.codePointCount(lineStartOffset, result.length());
    }

    private String nextToken(int elementIndex) {
      return followingTokens[elementIndex];
    }
  }

  private static String wrapCodeLines(String source) {
    StringBuilder output = new StringBuilder(source.length());
    boolean blockComment = false;
    for (String line : source.split("\\n", -1)) {
      if (line.isEmpty() && output.length() == source.length()) {
        continue;
      }
      boolean commentLine = blockComment || hasLineComment(line);
      if (line.contains("/*")) {
        blockComment = true;
        commentLine = true;
      }
      if (line.contains("*/")) {
        blockComment = false;
      }
      if (commentLine || scalarWidth(line) <= LINE_TARGET) {
        output.append(line).append('\n');
        continue;
      }
      wrapCodeLine(line, output);
    }
    if (output.length() > 1 && output.charAt(output.length() - 1) == '\n'
        && output.charAt(output.length() - 2) == '\n') {
      output.setLength(output.length() - 1);
    }
    return output.toString();
  }

  private static boolean hasLineComment(String line) {
    boolean string = false;
    for (int index = 0; index + 1 < line.length(); index++) {
      if (line.charAt(index) == '"') {
        string = !string;
      } else if (!string && line.charAt(index) == '/' && line.charAt(index + 1) == '/') {
        return true;
      }
    }
    return false;
  }

  private static void wrapCodeLine(String line, StringBuilder output) {
    int indentation = 0;
    while (indentation < line.length() && line.charAt(indentation) == ' ') {
      indentation++;
    }
    String continuation = " ".repeat(indentation + INDENT.length());
    String remaining = line;
    boolean wrapped = false;
    while (scalarWidth(remaining) > LINE_TARGET) {
      int split = binarySplit(remaining, LINE_TARGET);
      if (split < 0) {
        break;
      }
      output.append(remaining, 0, split).append('\n');
      remaining = continuation + remaining.substring(split).stripLeading();
      wrapped = true;
    }
    output.append(remaining).append('\n');
    if (!wrapped) {
      return;
    }
  }

  private static int binarySplit(String line, int target) {
    int result = -1;
    boolean string = false;
    for (int index = 0; index < line.length(); index++) {
      char value = line.charAt(index);
      if (value == '"') {
        string = !string;
        continue;
      }
      if (string || index + 1 < line.length()
          && value == '/' && (line.charAt(index + 1) == '/' || line.charAt(index + 1) == '*')) {
        continue;
      }
      if (value != ' ' || !operatorAt(line, index)) {
        continue;
      }
      int width = line.codePointCount(0, index);
      if (width <= target && index > result) {
        result = index;
      }
    }
    return result;
  }

  private static boolean operatorAt(String line, int space) {
    String suffix = line.substring(space);
    return suffix.startsWith(" == ")
        || suffix.startsWith(" < ")
        || suffix.startsWith(" + ")
        || suffix.startsWith(" - ")
        || suffix.startsWith(" * ")
        || suffix.startsWith(" / ")
        || suffix.startsWith(" % ")
        || suffix.startsWith(" & ")
        || suffix.startsWith(" ^ ")
        || suffix.startsWith(" = ")
        || suffix.startsWith(" += ")
        || suffix.startsWith(" -= ")
        || suffix.startsWith(" ^= ");
  }

  private static int scalarWidth(String text) {
    return text.codePointCount(0, text.length());
  }

  private static int[] delimiterMates(List<Element> elements) {
    int[] result = new int[elements.size()];
    java.util.Arrays.fill(result, -1);
    ArrayDeque<Integer> openers = new ArrayDeque<>();
    for (int index = 0; index < elements.size(); index++) {
      Element element = elements.get(index);
      if (element.kind() != Kind.TOKEN) {
        continue;
      }
      if (element.text().equals("(")) {
        openers.push(index);
      } else if (element.text().equals(")")) {
        int opener = openers.pop();
        result[opener] = index;
        result[index] = opener;
      }
    }
    return result;
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
