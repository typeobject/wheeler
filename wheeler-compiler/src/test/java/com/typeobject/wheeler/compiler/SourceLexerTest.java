package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.List;
import org.junit.jupiter.api.Test;

class SourceLexerTest {
  @Test
  void recordsLocationsAndUsesLongestOperatorMatch() {
    List<SourceToken> tokens = new SourceLexer("// heading\ncount += 0x1f;").lex();

    assertEquals("count", tokens.get(0).text());
    assertEquals(2, tokens.get(0).line());
    assertEquals(1, tokens.get(0).column());
    assertEquals(Type.PLUS_ASSIGN, tokens.get(1).type());
    assertEquals("0x1f", tokens.get(2).text());
  }

  @Test
  void ignoresFormattingAndBothCommentForms() {
    List<SourceToken> tokens = new SourceLexer("a/* middle\ncomment */^=\n1;").lex();

    assertEquals(List.of(Type.IDENTIFIER, Type.XOR_ASSIGN, Type.NUMBER, Type.SEMICOLON, Type.END),
        tokens.stream().map(SourceToken::type).toList());
    assertEquals(2, tokens.get(1).line());
    assertTrue(tokens.get(1).offset() > tokens.get(0).offset());
  }
}
