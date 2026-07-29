package com.typeobject.wheeler.compiler;

import java.util.Set;

/** Enforces compiler-owned value spellings before symbols enter a scope. */
final class SourceNames {
  private static final Set<String> RESERVED_VALUES =
      Set.of("done", "null", "nil", "none", "undefined");

  private SourceNames() {}

  static String binding(SourceToken token) {
    if (RESERVED_VALUES.contains(token.text())) {
      SourceTokenCursor.fail(token, "reserved value name: " + token.text());
    }
    return token.text();
  }
}
