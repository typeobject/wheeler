package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.TestLimits;
import com.typeobject.wheeler.compiler.SourceToken.Type;

/** Parses explicit bounded machine limits attached to one test declaration. */
final class SourceTestLimits {
  private static final int MAX_HISTORY = 4_000_000;
  private static final long MAX_STEPS = 4_000_000L;

  private SourceTestLimits() {}

  static TestLimits parse(SourceParser parser, boolean test, SourceToken start) {
    if (!parser.matchText("limits")) {
      return defaults();
    }
    if (!test) {
      SourceParser.fail(start, "limits require a test method");
    }
    parser.expect(Type.LEFT_PAREN, "'(' after limits");
    long steps = parsePositive(parser, "steps", MAX_STEPS);
    parser.expect(Type.COMMA, "',' after test step limit");
    long history = parsePositive(parser, "history", MAX_HISTORY);
    parser.expect(Type.RIGHT_PAREN, "')' after test limits");
    return new TestLimits(steps, Math.toIntExact(history));
  }

  static TestLimits defaults() {
    return new TestLimits(MAX_STEPS, MAX_HISTORY);
  }

  private static long parsePositive(SourceParser parser, String name, long maximum) {
    parser.expectText(name);
    parser.expect(Type.ASSIGN, "'=' after " + name);
    SourceToken token = parser.expect(Type.NUMBER, name + " limit");
    long value;
    try {
      value = Long.parseLong(token.text());
    } catch (NumberFormatException exception) {
      SourceParser.fail(token, name + " limit is outside signed 64-bit range");
      throw new AssertionError(exception);
    }
    if (value < 1 || value > maximum) {
      SourceParser.fail(token, name + " limit must be between 1 and " + maximum);
    }
    return value;
  }
}
