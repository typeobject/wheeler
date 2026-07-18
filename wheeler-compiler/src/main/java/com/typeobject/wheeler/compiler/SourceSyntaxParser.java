package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Element;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Kind;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.NodeKind;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Recovery;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.SyntaxNode;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Bounded structural parser that gives source tools parser-owned concrete ranges. */
final class SourceSyntaxParser {
  private static final int MAX_NESTING = 256;
  private static final Set<String> MODIFIERS = Set.of(
      "public", "private", "protected", "static", "entry", "coherent", "rev", "unitary");
  private static final Set<String> DOMAINS = Set.of("classical", "quantum", "hybrid");

  private final List<Element> elements;
  private final List<Integer> tokens = new ArrayList<>();
  private final Map<Integer, Integer> mates = new HashMap<>();
  private final List<SyntaxNode> nodes = new ArrayList<>();
  private final List<Recovery> recoveries = new ArrayList<>();

  private SourceSyntaxParser(List<Element> elements) {
    this.elements = elements;
    for (int index = 0; index < elements.size(); index++) {
      if (elements.get(index).kind() == Kind.TOKEN) {
        tokens.add(index);
      }
    }
  }

  static Result parse(List<Element> elements) {
    return new SourceSyntaxParser(elements).parse();
  }

  private Result parse() {
    delimiters();
    if (tokens.isEmpty()) {
      return result();
    }
    nodes.add(new SyntaxNode(
        NodeKind.COMPILATION_UNIT,
        tokens.getFirst(),
        tokens.getLast(),
        "",
        List.of()));
    if (!recoveries.isEmpty()) {
      return result();
    }
    headers();
    typeAndMembers();
    blocks();
    nodes.sort(Comparator.comparingInt(SyntaxNode::startElement)
        .thenComparing(Comparator.comparingInt(SyntaxNode::endElement).reversed())
        .thenComparing(node -> node.kind().ordinal()));
    recoveries.sort(Comparator.comparingInt(Recovery::line)
        .thenComparingInt(Recovery::column));
    return result();
  }

  private Result result() {
    return new Result(List.copyOf(nodes), List.copyOf(recoveries));
  }

  private void delimiters() {
    ArrayDeque<Integer> stack = new ArrayDeque<>();
    for (int token = 0; token < tokens.size(); token++) {
      String text = text(token);
      if (isOpener(text)) {
        if (stack.size() >= MAX_NESTING) {
          recover(token, "source exceeds the 256-delimiter nesting limit");
          return;
        }
        stack.push(token);
      } else if (isCloser(text)) {
        if (stack.isEmpty() || !matches(text(stack.peek()), text)) {
          recover(token, "unmatched delimiter '" + text + "'");
          return;
        }
        int opener = stack.pop();
        mates.put(opener, token);
        mates.put(token, opener);
      }
    }
    if (!stack.isEmpty()) {
      int opener = stack.getLast();
      recover(opener, "unclosed delimiter '" + text(opener) + "'");
    }
  }

  private void headers() {
    int cursor = 0;
    while (cursor < tokens.size()) {
      NodeKind kind = switch (text(cursor)) {
        case "module" -> NodeKind.MODULE_DECLARATION;
        case "import" -> NodeKind.IMPORT_DECLARATION;
        default -> null;
      };
      if (kind == null) {
        return;
      }
      int end = find(cursor, ";");
      if (end < 0) {
        recover(cursor, "unclosed " + text(cursor) + " declaration");
        return;
      }
      nodes.add(new SyntaxNode(
          kind, tokens.get(cursor), tokens.get(end), qualifiedName(cursor + 1, end), List.of()));
      cursor = end + 1;
    }
  }

  private void typeAndMembers() {
    int domain = -1;
    for (int token = 0; token + 2 < tokens.size(); token++) {
      if (DOMAINS.contains(text(token)) && text(token + 1).equals("class")) {
        domain = token;
        break;
      }
    }
    if (domain < 0) {
      recover(0, "expected Wheeler class declaration");
      return;
    }
    int open = domain + 3;
    if (open >= tokens.size() || !text(open).equals("{") || !mates.containsKey(open)) {
      recover(domain, "class declaration requires a closed body");
      return;
    }
    int close = mates.get(open);
    nodes.add(new SyntaxNode(
        NodeKind.TYPE_DECLARATION,
        tokens.get(domain),
        tokens.get(close),
        text(domain + 2),
        List.of(text(domain))));
    members(open + 1, close);
  }

  private void members(int first, int close) {
    int cursor = first;
    while (cursor < close) {
      if (text(cursor).equals(";")) {
        cursor++;
        continue;
      }
      int end = memberEnd(cursor, close);
      if (end < cursor) {
        recover(cursor, "declaration has no closing ';' or body");
        return;
      }
      nodes.add(classify(cursor, end));
      cursor = end + 1;
    }
  }

  private int memberEnd(int start, int close) {
    for (int token = start; token < close; token++) {
      String text = text(token);
      if (text.equals(";")) {
        return token;
      }
      if (text.equals("{") && mates.containsKey(token)) {
        return mates.get(token);
      }
      if (isOpener(text) && mates.containsKey(token)) {
        token = mates.get(token);
      }
    }
    return -1;
  }

  private SyntaxNode classify(int start, int end) {
    int cursor = start;
    List<String> modifiers = new ArrayList<>();
    while (cursor <= end && MODIFIERS.contains(text(cursor))) {
      modifiers.add(text(cursor++));
    }
    String introducer = cursor <= end ? text(cursor) : "";
    NodeKind kind = switch (introducer) {
      case "state" -> NodeKind.STATE_DECLARATION;
      case "const" -> NodeKind.CONSTANT_DECLARATION;
      case "qreg" -> NodeKind.QUANTUM_REGISTER_DECLARATION;
      case "record" -> NodeKind.RECORD_DECLARATION;
      case "variant" -> NodeKind.VARIANT_DECLARATION;
      case "enum" -> NodeKind.ENUM_DECLARATION;
      case "theorem" -> NodeKind.THEOREM_DECLARATION;
      case "experiment" -> NodeKind.EXPERIMENT_DECLARATION;
      default -> NodeKind.METHOD_DECLARATION;
    };
    String name = switch (kind) {
      case STATE_DECLARATION, CONSTANT_DECLARATION, QUANTUM_REGISTER_DECLARATION ->
          assignmentName(cursor, end, introducer);
      case RECORD_DECLARATION, VARIANT_DECLARATION, ENUM_DECLARATION,
          THEOREM_DECLARATION, EXPERIMENT_DECLARATION ->
          cursor + 1 <= end ? text(cursor + 1) : introducer;
      case METHOD_DECLARATION -> methodName(cursor, end);
      default -> "";
    };
    return new SyntaxNode(kind, tokens.get(start), tokens.get(end), name, modifiers);
  }

  private String assignmentName(int start, int end, String fallback) {
    int assignment = start + 1;
    while (assignment <= end
        && !text(assignment).equals("=")
        && !text(assignment).equals(";")) {
      assignment++;
    }
    return assignment > start + 1 ? text(assignment - 1) : fallback;
  }

  private String methodName(int start, int end) {
    for (int token = start; token <= end; token++) {
      if (text(token).equals("(")) {
        return token > start ? text(token - 1) : "<method>";
      }
      if (text(token).equals("{") || text(token).equals("=") || text(token).equals(";")) {
        break;
      }
    }
    return "<declaration>";
  }

  private void blocks() {
    for (Map.Entry<Integer, Integer> pair : mates.entrySet()) {
      int opener = pair.getKey();
      int closer = pair.getValue();
      if (opener < closer && text(opener).equals("{") && text(closer).equals("}")) {
        nodes.add(new SyntaxNode(
            NodeKind.BLOCK, tokens.get(opener), tokens.get(closer), "", List.of()));
      }
    }
  }

  private int find(int start, String expected) {
    for (int token = start; token < tokens.size(); token++) {
      if (text(token).equals(expected)) {
        return token;
      }
    }
    return -1;
  }

  private String qualifiedName(int start, int end) {
    StringBuilder result = new StringBuilder();
    for (int token = start; token < end; token++) {
      String text = text(token);
      if (text.equals(".") || text.equals("::")) {
        result.append(text);
      } else if (!text.equals("public") && !text.equals("private")) {
        result.append(text);
      }
    }
    return result.toString();
  }

  private void recover(int token, String message) {
    int bounded = Math.max(0, Math.min(token, tokens.size() - 1));
    Element element = elements.get(tokens.get(bounded));
    recoveries.add(new Recovery(
        tokens.get(bounded), element.line(), element.column(), message));
  }

  private String text(int token) {
    return elements.get(tokens.get(token)).text();
  }

  private static boolean isOpener(String text) {
    return text.equals("(") || text.equals("[") || text.equals("{");
  }

  private static boolean isCloser(String text) {
    return text.equals(")") || text.equals("]") || text.equals("}");
  }

  private static boolean matches(String opener, String closer) {
    return opener.equals("(") && closer.equals(")")
        || opener.equals("[") && closer.equals("]")
        || opener.equals("{") && closer.equals("}");
  }

  record Result(List<SyntaxNode> nodes, List<Recovery> recoveries) {
    Result {
      nodes = List.copyOf(nodes);
      recoveries = List.copyOf(recoveries);
    }
  }
}
