package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.TestFixtures;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.HashSet;
import java.util.Set;

/** Parses one explicit four-phase lifecycle fixture declaration. */
final class SourceTestFixtures {
  private SourceTestFixtures() {}

  static TestFixtures parse(SourceParser parser, boolean test, SourceToken declaration) {
    if (!parser.matchText("fixtures")) {
      return TestFixtures.NONE;
    }
    if (!test) {
      SourceTokenCursor.fail(declaration, "fixtures metadata requires a test declaration");
    }
    parser.expect(Type.LEFT_PAREN, "'(' after fixtures");
    String suiteAcquire = phase(parser, "suite_acquire");
    parser.expect(Type.COMMA, "',' after suite_acquire fixture");
    String caseAcquire = phase(parser, "case_acquire");
    parser.expect(Type.COMMA, "',' after case_acquire fixture");
    String caseRelease = phase(parser, "case_release");
    parser.expect(Type.COMMA, "',' after case_release fixture");
    String suiteRelease = phase(parser, "suite_release");
    parser.expect(Type.RIGHT_PAREN, "')' after fixtures");

    Set<String> functions = new HashSet<>();
    functions.add(suiteAcquire);
    functions.add(caseAcquire);
    functions.add(caseRelease);
    functions.add(suiteRelease);
    if (functions.size() != 4) {
      SourceTokenCursor.fail(declaration, "fixture phases require four distinct functions");
    }
    return new TestFixtures(suiteAcquire, caseAcquire, caseRelease, suiteRelease);
  }

  private static String phase(SourceParser parser, String name) {
    parser.expectText(name);
    parser.expect(Type.ASSIGN, "'=' after " + name);
    return SourceNames.binding(parser.expect(Type.IDENTIFIER, name + " fixture function"));
  }
}
