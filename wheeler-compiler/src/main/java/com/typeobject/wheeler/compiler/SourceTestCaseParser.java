package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Parameter;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Parses bounded canonical scalar rows attached to one parameterized test declaration. */
final class SourceTestCaseParser {
  private static final int MAX_CASES = 1_024;

  private SourceTestCaseParser() {}

  static List<List<String>> parse(
      SourceParser parser,
      boolean test,
      List<Parameter> parameters,
      SourceToken start) {
    if (!parser.matchText("cases")) {
      return List.of();
    }
    if (!test || parameters.size() != 1) {
      SourceParser.fail(start, "cases require a test method with one scalar parameter");
    }
    parser.expect(Type.LEFT_PAREN, "'(' after cases");
    List<List<String>> rows = new ArrayList<>();
    Set<String> unique = new HashSet<>();
    if (!parser.check(Type.RIGHT_PAREN)) {
      do {
        String value = parameters.getFirst().type().equals("boolean")
            ? parseBoolean(parser) : parseLong(parser);
        if (!unique.add(value)) {
          SourceParser.fail(parser.previous(), "duplicate parameterized test case: " + value);
        }
        if (rows.size() == MAX_CASES) {
          SourceParser.fail(parser.previous(), "parameterized test exceeds 1,024 cases");
        }
        rows.add(List.of(value));
      } while (parser.match(Type.COMMA));
    }
    parser.expect(Type.RIGHT_PAREN, "')' after test cases");
    return List.copyOf(rows);
  }

  static void validateShape(
      boolean test,
      String domain,
      boolean returnsValue,
      List<Parameter> parameters,
      List<List<String>> cases,
      SourceToken start) {
    if (test && (!domain.equals("classical") || returnsValue
        || parameters.size() > 1
        || !parameters.isEmpty()
            && !Set.of("long", "boolean").contains(parameters.getFirst().type()))) {
      SourceParser.fail(
          start, "test methods accept at most one long or boolean parameter and return void");
    }
    if (test && !parameters.isEmpty() && cases.isEmpty()) {
      SourceParser.fail(start, "parameterized test methods require at least one case");
    }
  }

  private static String parseBoolean(SourceParser parser) {
    SourceToken token = parser.expect(Type.IDENTIFIER, "boolean test case");
    if (!Set.of("true", "false").contains(token.text())) {
      SourceParser.fail(token, "boolean test cases must be true or false");
    }
    return token.text();
  }

  private static String parseLong(SourceParser parser) {
    boolean negative = parser.match(Type.MINUS);
    SourceToken token = parser.expect(Type.NUMBER, "integer test case");
    String value = (negative ? "-" : "") + token.text();
    try {
      Long.parseLong(value);
    } catch (NumberFormatException exception) {
      SourceParser.fail(token, "integer test case is outside signed 64-bit range");
    }
    return value;
  }
}
