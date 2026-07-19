package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceConstantParser.ConstantValue;
import com.typeobject.wheeler.compiler.SourceModel.ConstantDefinition;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/** Collects and dependency-orders class constants before method parsing. */
final class SourceConstantCollector {
  private static final int MAX_EXPRESSION_TOKENS = 4_096;
  private static final int MAX_EXPRESSION_DEPTH = 256;
  private static final Set<String> VISIBILITY =
      Set.of("public", "private", "protected");

  private final List<ConstantDefinition> importedConstants;
  private final String moduleName;
  private final Map<String, PendingConstant> pending = new LinkedHashMap<>();
  private final Map<String, ConstantDefinition> evaluated = new HashMap<>();
  private final List<String> active = new ArrayList<>();

  private SourceConstantCollector(
      String moduleName, List<ConstantDefinition> importedConstants) {
    this.moduleName = moduleName;
    this.importedConstants = importedConstants;
  }

  static List<ConstantDefinition> collect(
      String source, List<ConstantDefinition> importedConstants) {
    String moduleName = SourceModuleHeaderParser.parseSource(source).moduleName();
    SourceConstantCollector collector =
        new SourceConstantCollector(moduleName, importedConstants);
    collector.scan(new SourceLexer(source).lex());
    for (String name : new TreeMap<>(collector.pending).keySet()) {
      collector.evaluate(name);
    }
    return collector.pending.keySet().stream()
        .map(collector.evaluated::get)
        .toList();
  }

  private void scan(List<SourceToken> tokens) {
    boolean classSeen = false;
    int depth = 0;
    int cursor = 0;
    while (cursor < tokens.size() && tokens.get(cursor).type() != Type.END) {
      SourceToken token = tokens.get(cursor);
      if (!classSeen) {
        if (token.type() == Type.IDENTIFIER && token.text().equals("class")) {
          classSeen = true;
        }
        cursor += 1;
        continue;
      }
      if (token.type() == Type.LEFT_BRACE) {
        depth += 1;
        cursor += 1;
        continue;
      }
      if (token.type() == Type.RIGHT_BRACE) {
        depth -= 1;
        cursor += 1;
        continue;
      }
      if (depth != 1) {
        cursor += 1;
        continue;
      }

      int declaration = cursor;
      boolean exported = false;
      while (isVisibility(tokens.get(declaration))) {
        exported |= tokens.get(declaration).text().equals("public");
        declaration += 1;
      }
      if (!hasText(tokens, declaration, "const")) {
        cursor += 1;
        continue;
      }
      cursor = collectDeclaration(tokens, declaration, exported);
    }
  }

  private int collectDeclaration(
      List<SourceToken> tokens, int declaration, boolean exported) {
    SourceToken start = tokens.get(declaration);
    SourceToken type = token(tokens, declaration + 1, "constant type");
    if (!type.text().equals("long") && !type.text().equals("boolean")) {
      fail(type, "constant type must be long or boolean");
    }
    SourceToken name = token(tokens, declaration + 2, "constant name");
    if (name.type() != Type.IDENTIFIER) {
      fail(name, "expected constant name");
    }
    SourceToken assign = token(tokens, declaration + 3, "constant assignment");
    if (assign.type() != Type.ASSIGN) {
      fail(assign, "expected '=' in constant declaration");
    }
    int end = declaration + 4;
    while (token(tokens, end, "constant terminator").type() != Type.SEMICOLON) {
      end += 1;
    }
    if (end == declaration + 4) {
      fail(name, "constant initializer cannot be empty");
    }
    List<SourceToken> expression = List.copyOf(
        tokens.subList(declaration + 4, end));
    validateExpression(expression, name);
    PendingConstant value = new PendingConstant(
        name.text(),
        type.text(),
        expression,
        exported,
        start.line(),
        name);
    if (pending.putIfAbsent(name.text(), value) != null) {
      fail(name, "duplicate constant: " + name.text());
    }
    return end + 1;
  }

  private ConstantDefinition evaluate(String name) {
    ConstantDefinition complete = evaluated.get(name);
    if (complete != null) {
      return complete;
    }
    PendingConstant declaration = pending.get(name);
    if (declaration == null) {
      throw new AssertionError("missing pending constant " + name);
    }
    int cycleStart = active.indexOf(name);
    if (cycleStart >= 0) {
      List<String> cycle = new ArrayList<>(active.subList(cycleStart, active.size()));
      cycle.add(name);
      throw new CompilerException(
          declaration.line(), "constant dependency cycle: " + String.join(" -> ", cycle));
    }
    if (active.size() >= MAX_EXPRESSION_DEPTH) {
      fail(declaration.source(), "constant dependency depth exceeds 256");
    }
    active.add(name);
    ConstantValue value = SourceConstantParser.evaluate(
        declaration.expression(), this::resolve);
    active.removeLast();
    if (!declaration.type().equals(value.type())) {
      fail(
          declaration.source(),
          "constant initializer type does not match " + declaration.type());
    }
    ConstantDefinition result = new ConstantDefinition(
        declaration.name(),
        declaration.type(),
        value.value(),
        declaration.exported(),
        declaration.line());
    evaluated.put(name, result);
    return result;
  }

  private ConstantDefinition resolve(String reference, SourceToken source) {
    String local = reference;
    if (moduleName != null && reference.startsWith(moduleName + "::")) {
      local = reference.substring(moduleName.length() + 2);
    }
    if (pending.containsKey(local)) {
      return evaluate(local);
    }
    List<ConstantDefinition> matches = importedConstants.stream()
        .filter(constant -> constant.name().equals(reference))
        .toList();
    if (1 < matches.size()) {
      fail(source, "ambiguous constant: " + reference);
    }
    if (matches.isEmpty()) {
      fail(source, "unknown constant: " + reference);
    }
    return matches.getFirst();
  }

  private static void validateExpression(
      List<SourceToken> expression, SourceToken source) {
    if (expression.size() > MAX_EXPRESSION_TOKENS) {
      fail(source, "constant expression exceeds 4,096 tokens");
    }
    int depth = 0;
    for (SourceToken token : expression) {
      if (token.type() == Type.LEFT_PAREN) {
        depth += 1;
        if (depth > MAX_EXPRESSION_DEPTH) {
          fail(source, "constant expression depth exceeds 256");
        }
      } else if (token.type() == Type.RIGHT_PAREN) {
        depth -= 1;
      }
    }
  }

  private static boolean isVisibility(SourceToken token) {
    return token.type() == Type.IDENTIFIER && VISIBILITY.contains(token.text());
  }

  private static boolean hasText(
      List<SourceToken> tokens, int index, String text) {
    return index < tokens.size()
        && tokens.get(index).type() == Type.IDENTIFIER
        && tokens.get(index).text().equals(text);
  }

  private static SourceToken token(
      List<SourceToken> tokens, int index, String description) {
    if (index >= tokens.size() || tokens.get(index).type() == Type.END) {
      SourceToken end = tokens.getLast();
      fail(end, "expected " + description);
    }
    return tokens.get(index);
  }

  private static void fail(SourceToken token, String message) {
    throw new CompilerException(
        token.line(), message + " at column " + token.column());
  }

  private record PendingConstant(
      String name,
      String type,
      List<SourceToken> expression,
      boolean exported,
      int line,
      SourceToken source) {}
}
