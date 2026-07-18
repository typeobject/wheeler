package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayList;
import java.util.List;

/** Parses ordinary, intrinsic, and full module-qualified value calls. */
final class SourceCallParser {
  private SourceCallParser() {}

  static boolean qualifiedCallAhead(SourceParser parser) {
    int distance = 0;
    while (parser.lookaheadType(distance) == Type.DOT
        && parser.lookaheadType(distance + 1) == Type.IDENTIFIER) {
      distance += 2;
    }
    return parser.lookaheadType(distance) == Type.DOUBLE_COLON
        && parser.lookaheadType(distance + 1) == Type.IDENTIFIER
        && parser.lookaheadType(distance + 2) == Type.LEFT_PAREN;
  }

  static String qualifiedReference(SourceParser parser, SourceToken start) {
    StringBuilder qualified = new StringBuilder(start.text());
    while (parser.match(Type.DOT)) {
      qualified.append('.').append(
          parser.expect(Type.IDENTIFIER, "qualified module component").text());
    }
    parser.expect(Type.DOUBLE_COLON, "'::' before qualified function");
    qualified.append("::").append(
        parser.expect(Type.IDENTIFIER, "qualified function name").text());
    parser.expect(Type.LEFT_PAREN, "'(' after qualified function");
    return qualified.toString();
  }

  static String parse(
      SourceParser parser,
      List<Statement> body,
      SourceToken start,
      String reference) {
    List<String> arguments = new ArrayList<>();
    if (!parser.check(Type.RIGHT_PAREN)) {
      do {
        arguments.add(parser.parseExpression(body));
      } while (parser.match(Type.COMMA));
    }
    parser.expect(Type.RIGHT_PAREN, "')' after call arguments");
    String result = parser.temporary();
    List<String> call = new ArrayList<>();
    call.add(result);
    call.add(reference);
    call.addAll(arguments);
    String operation = switch (reference) {
      case "slice" -> "slice_new";
      case "allocate" -> "words_alloc";
      case "allocateBytes" -> "bytes_alloc";
      case "allocateMap" -> "map_alloc";
      case "freezeUtf8" -> "utf8_freeze";
      case "utf8Valid" -> "utf8_valid";
      case "utf8Count" -> "utf8_count";
      case "bufferLength" -> "buffer_length";
      case "utf8Scalar" -> "utf8_scalar";
      case "utf8Width" -> "utf8_width";
      case "mapGet" -> "map_get";
      case "mapHas" -> "map_has";
      default -> "call_value";
    };
    body.add(new Statement(operation, call, start.line()));
    return parser.parsePostfix(body, result, start.line());
  }
}
