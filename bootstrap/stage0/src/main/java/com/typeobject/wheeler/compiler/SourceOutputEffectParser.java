package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.List;

/** Parses the entry-only host output prefix selection statement. */
final class SourceOutputEffectParser {
  private SourceOutputEffectParser() {}

  static void parse(SourceParser parser, List<Statement> body, SourceToken start) {
    parser.expect(Type.LEFT_PAREN, "'(' after setOutputLength");
    String output = parser.parseExpression(body);
    parser.expect(Type.COMMA, "',' after output buffer");
    String length = parser.parseExpression(body);
    parser.expect(Type.RIGHT_PAREN, "')' after output length");
    parser.expect(Type.SEMICOLON, "';' after setOutputLength");
    body.add(SourceStatementParser.statement(
        "output_length", start.line(), output, length));
  }
}
