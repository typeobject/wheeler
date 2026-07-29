package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.List;

/** Parses typed local bindings and ordinary value returns. */
final class SourceResultParser {
  private SourceResultParser() {}

  static void parseReturn(
      SourceParser parser,
      List<Statement> body,
      SourceToken start,
      boolean valueReturnsAllowed) {
    if (!valueReturnsAllowed) {
      SourceTokenCursor.fail(start, "return value is not available in a void method");
    }
    String value = parser.parseExpression(body);
    parser.expect(Type.SEMICOLON, "';' after return value");
    body.add(SourceParser.statement("return_value", start.line(), value));
  }

  static void parseLocalDeclaration(SourceParser parser, List<Statement> body) {
    SourceToken start = parser.peek();
    String type = parser.parseValueType("local type");
    String name = SourceNames.binding(parser.expect(Type.IDENTIFIER, "local name"));
    parser.expect(Type.ASSIGN, "'=' in local declaration");
    String value = parser.parseExpression(body);
    parser.expect(Type.SEMICOLON, "';' after local declaration");
    body.add(SourceParser.statement("local_bind", start.line(), name, value, type));
  }
}
