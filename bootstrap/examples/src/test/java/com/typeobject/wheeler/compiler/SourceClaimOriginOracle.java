package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/** Derives byte spans from the stage-0 lexer for already bound test claims, not proof truth. */
public final class SourceClaimOriginOracle {
  private static final Set<String> VISIBILITY = Set.of("public", "private", "protected");

  /** A modifier-inclusive declaration span in the original UTF-8 source. */
  public record Origin(String name, long start, long length) {}

  private SourceClaimOriginOracle() {}

  /** Selects class-level theorem spans without interpreting their subjects or expressions. */
  public static List<Origin> origins(String source) {
    List<SourceToken> tokens = new SourceLexer(source).lex();
    List<Origin> origins = new ArrayList<>();
    int depth = 0;
    for (int token = 0; token < tokens.size(); token++) {
      SourceToken current = tokens.get(token);
      if (current.type() == Type.LEFT_BRACE) depth++;
      if (current.type() == Type.RIGHT_BRACE) depth--;
      if (depth != 1 || !current.text().equals("theorem") || token + 2 >= tokens.size()
          || !tokens.get(token + 2).text().equals("proves")) continue;
      int first = token;
      while (first > 0 && VISIBILITY.contains(tokens.get(first - 1).text())) first--;
      int end = token + 3;
      while (end < tokens.size() && tokens.get(end).type() != Type.SEMICOLON) end++;
      if (end == tokens.size()) throw new IllegalArgumentException("unclosed fixture claim");
      int startByte = bytes(source.substring(0, tokens.get(first).offset()));
      int endByte = bytes(source.substring(0, tokens.get(end).offset() + tokens.get(end).text().length()));
      origins.add(new Origin(tokens.get(token + 1).text(), startByte, endByte - startByte));
      token = end;
    }
    return List.copyOf(origins);
  }

  private static int bytes(String text) {
    return text.getBytes(StandardCharsets.UTF_8).length;
  }
}
