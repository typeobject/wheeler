package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.List;

/** Expands one bounded raw-ASCII output statement into ordinary checked byte writes. */
final class SourceAsciiWriteParser {
  private SourceAsciiWriteParser() {}

  static void parse(SourceParser parser, List<Statement> body) {
    parser.expect(Type.LEFT_PAREN, "'(' after writeAscii");
    String buffer = parser.parseExpression(body);
    parser.expect(Type.COMMA, "',' after output buffer");
    String offset = parser.parseExpression(body);
    parser.expect(Type.COMMA, "',' after output offset");
    SourceToken literal = parser.expect(Type.STRING, "bounded ASCII literal");
    parser.expect(Type.RIGHT_PAREN, "')' after writeAscii arguments");
    parser.expect(Type.SEMICOLON, "';' after writeAscii");
    for (int index = 0; index < literal.text().length(); index++) {
      String at = offset;
      if (index != 0) {
        SourceToken position = number(literal, index);
        at = parser.binary(
            body,
            position,
            "add",
            offset,
            parser.constant(body, position, position.text()));
      }
      SourceToken octet = number(literal, literal.text().charAt(index));
      String value = parser.constant(body, octet, octet.text());
      body.add(SourceStatementParser.statement(
          "bytes_set", literal.line(), buffer, at, value));
    }
  }

  private static SourceToken number(SourceToken literal, int value) {
    return new SourceToken(
        Type.NUMBER,
        Integer.toString(value),
        literal.line(),
        literal.column(),
        literal.offset());
  }
}
