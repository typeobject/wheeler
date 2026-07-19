package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.ConstantDefinition;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.List;

/** Parses and checks the bounded scalar constant-expression profile. */
final class SourceConstantParser {
  private SourceConstantParser() {}

  static ConstantDefinition parseDeclaration(
      SourceParser parser, SourceToken start, boolean exported) {
    SourceToken type = parser.expect(Type.IDENTIFIER, "constant type");
    if (!type.text().equals("long") && !type.text().equals("boolean")) {
      SourceTokenCursor.fail(type, "constant type must be long or boolean");
    }
    SourceToken name = parser.expect(Type.IDENTIFIER, "constant name");
    parser.expect(Type.ASSIGN, "'=' in constant declaration");
    ConstantValue value = parseExpression(parser, parser::resolveRequiredConstant);
    parser.expect(Type.SEMICOLON, "';' after constant declaration");
    if (!value.type().equals(type.text())) {
      SourceTokenCursor.fail(
          name, "constant initializer type does not match " + type.text());
    }
    return new ConstantDefinition(
        name.text(), type.text(), value.value(), exported, start.line());
  }

  static ConstantValue parseValue(
      SourceTokenCursor parser, ConstantResolver resolver) {
    return parseExpression(parser, resolver);
  }

  static ConstantValue evaluate(
      List<SourceToken> tokens, ConstantResolver resolver) {
    ExpressionCursor cursor = new ExpressionCursor();
    cursor.resetTokens(tokens);
    ConstantValue value = parseExpression(cursor, resolver);
    cursor.expect(Type.END, "end of constant expression");
    return value;
  }

  static boolean qualifiedReferenceAhead(SourceTokenCursor parser) {
    int distance = 0;
    while (parser.lookaheadType(distance) == Type.DOT
        && parser.lookaheadType(distance + 1) == Type.IDENTIFIER) {
      distance += 2;
    }
    return parser.lookaheadType(distance) == Type.DOUBLE_COLON
        && parser.lookaheadType(distance + 1) == Type.IDENTIFIER
        && parser.lookaheadType(distance + 2) != Type.LEFT_PAREN;
  }

  static String qualifiedReference(
      SourceTokenCursor parser, SourceToken start) {
    StringBuilder qualified = new StringBuilder(start.text());
    while (parser.match(Type.DOT)) {
      qualified.append('.').append(
          parser.expect(Type.IDENTIFIER, "qualified module component").text());
    }
    parser.expect(Type.DOUBLE_COLON, "'::' before qualified constant");
    qualified.append("::").append(
        parser.expect(Type.IDENTIFIER, "qualified constant name").text());
    return qualified.toString();
  }

  private static ConstantValue parseExpression(
      SourceTokenCursor parser, ConstantResolver resolver) {
    return parseEquality(parser, resolver);
  }

  private static ConstantValue parseEquality(
      SourceTokenCursor parser, ConstantResolver resolver) {
    ConstantValue left = parseComparison(parser, resolver);
    while (parser.match(Type.EQUAL)) {
      SourceToken operator = parser.previous();
      ConstantValue right = parseComparison(parser, resolver);
      requireSameType(left, right, operator);
      left = new ConstantValue("boolean", left.value() == right.value() ? 1 : 0);
    }
    return left;
  }

  private static ConstantValue parseComparison(
      SourceTokenCursor parser, ConstantResolver resolver) {
    ConstantValue left = parseXor(parser, resolver);
    while (parser.match(Type.LESS)) {
      SourceToken operator = parser.previous();
      ConstantValue right = parseXor(parser, resolver);
      requireLong(left, operator);
      requireLong(right, operator);
      left = new ConstantValue("boolean", left.value() < right.value() ? 1 : 0);
    }
    return left;
  }

  private static ConstantValue parseXor(
      SourceTokenCursor parser, ConstantResolver resolver) {
    ConstantValue left = parseAnd(parser, resolver);
    while (parser.match(Type.XOR)) {
      SourceToken operator = parser.previous();
      ConstantValue right = parseAnd(parser, resolver);
      requireLong(left, operator);
      requireLong(right, operator);
      left = new ConstantValue("long", left.value() ^ right.value());
    }
    return left;
  }

  private static ConstantValue parseAnd(
      SourceTokenCursor parser, ConstantResolver resolver) {
    ConstantValue left = parseAdditive(parser, resolver);
    while (parser.match(Type.AND)) {
      SourceToken operator = parser.previous();
      ConstantValue right = parseAdditive(parser, resolver);
      requireLong(left, operator);
      requireLong(right, operator);
      left = new ConstantValue("long", left.value() & right.value());
    }
    return left;
  }

  private static ConstantValue parseAdditive(
      SourceTokenCursor parser, ConstantResolver resolver) {
    ConstantValue left = parseMultiplicative(parser, resolver);
    while (parser.match(Type.PLUS, Type.MINUS)) {
      SourceToken operator = parser.previous();
      ConstantValue right = parseMultiplicative(parser, resolver);
      requireLong(left, operator);
      requireLong(right, operator);
      try {
        left = new ConstantValue(
            "long",
            operator.type() == Type.PLUS
                ? Math.addExact(left.value(), right.value())
                : Math.subtractExact(left.value(), right.value()));
      } catch (ArithmeticException exception) {
        SourceTokenCursor.fail(operator, "constant arithmetic overflow");
      }
    }
    return left;
  }

  private static ConstantValue parseMultiplicative(
      SourceTokenCursor parser, ConstantResolver resolver) {
    ConstantValue left = parsePrimary(parser, resolver);
    while (parser.match(Type.STAR, Type.SLASH, Type.PERCENT)) {
      SourceToken operator = parser.previous();
      ConstantValue right = parsePrimary(parser, resolver);
      requireLong(left, operator);
      requireLong(right, operator);
      try {
        long value = switch (operator.type()) {
          case STAR -> Math.multiplyExact(left.value(), right.value());
          case SLASH -> divide(left.value(), right.value());
          case PERCENT -> remainder(left.value(), right.value());
          default -> throw new AssertionError("unhandled constant operator");
        };
        left = new ConstantValue("long", value);
      } catch (ArithmeticException exception) {
        SourceTokenCursor.fail(operator, "constant arithmetic trap");
      }
    }
    return left;
  }

  private static ConstantValue parsePrimary(
      SourceTokenCursor parser, ConstantResolver resolver) {
    if (parser.match(Type.LEFT_PAREN)) {
      ConstantValue value = parseExpression(parser, resolver);
      parser.expect(Type.RIGHT_PAREN, "')' after constant expression");
      return value;
    }
    SourceToken start = parser.peek();
    if (parser.match(Type.MINUS)) {
      SourceToken number = parser.expect(Type.NUMBER, "numeric constant");
      long value = SourceStatementParser.parseInteger("-" + number.text(), number.line());
      return new ConstantValue("long", value);
    }
    if (parser.match(Type.NUMBER)) {
      SourceToken number = parser.previous();
      return new ConstantValue(
          "long", SourceStatementParser.parseInteger(number.text(), number.line()));
    }
    if (parser.checkText("true") || parser.checkText("false")) {
      return new ConstantValue(
          "boolean", parser.advance().text().equals("true") ? 1 : 0);
    }
    SourceToken reference = parser.expect(Type.IDENTIFIER, "constant expression");
    if (reference.text().equals("rotateRight32") && parser.match(Type.LEFT_PAREN)) {
      ConstantValue value = parseExpression(parser, resolver);
      parser.expect(Type.COMMA, "',' after rotate value");
      ConstantValue amount = parseExpression(parser, resolver);
      parser.expect(Type.RIGHT_PAREN, "')' after rotate amount");
      requireLong(value, reference);
      requireLong(amount, reference);
      if (amount.value() < 0 || amount.value() > 31) {
        SourceTokenCursor.fail(reference, "constant rotate amount must be between 0 and 31");
      }
      long rotated = Integer.toUnsignedLong(
          Integer.rotateRight((int) value.value(), Math.toIntExact(amount.value())));
      return new ConstantValue("long", rotated);
    }
    String name = reference.text();
    if (qualifiedReferenceAhead(parser)) {
      name = qualifiedReference(parser, reference);
    }
    ConstantDefinition constant = resolver.resolve(name, reference);
    return new ConstantValue(constant.type(), constant.value());
  }

  private static long divide(long left, long right) {
    if (right == 0 || (left == Long.MIN_VALUE && right == -1)) {
      throw new ArithmeticException("constant division trap");
    }
    return left / right;
  }

  private static long remainder(long left, long right) {
    if (right == 0) {
      throw new ArithmeticException("constant remainder trap");
    }
    return left % right;
  }

  private static void requireLong(ConstantValue value, SourceToken source) {
    if (!value.type().equals("long")) {
      SourceTokenCursor.fail(source, "constant operator requires long operands");
    }
  }

  private static void requireSameType(
      ConstantValue left, ConstantValue right, SourceToken source) {
    if (!left.type().equals(right.type())) {
      SourceTokenCursor.fail(source, "constant equality requires matching types");
    }
  }

  @FunctionalInterface
  interface ConstantResolver {
    ConstantDefinition resolve(String name, SourceToken source);
  }

  record ConstantValue(String type, long value) {}

  private static final class ExpressionCursor extends SourceTokenCursor {}
}
