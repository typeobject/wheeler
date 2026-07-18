package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayList;
import java.util.List;

/** Parses the optional canonical module/import prefix of one source file. */
final class SourceModuleHeaderParser {
  record Header(String moduleName, List<String> imports) {
    Header {
      imports = List.copyOf(imports);
    }
  }

  private SourceModuleHeaderParser() {}

  static Header parse(SourceTokenCursor cursor) {
    String moduleName = null;
    if (cursor.matchText("module")) {
      moduleName = qualifiedName(cursor, "module name");
      cursor.expect(Type.SEMICOLON, "';' after module declaration");
    }
    List<String> imports = new ArrayList<>();
    while (cursor.matchText("import")) {
      String imported = qualifiedName(cursor, "import name");
      if (!imports.isEmpty() && imports.getLast().compareTo(imported) >= 0) {
        SourceTokenCursor.fail(cursor.previous(), "imports must be unique and sorted");
      }
      imports.add(imported);
      cursor.expect(Type.SEMICOLON, "';' after import declaration");
    }
    return new Header(moduleName, imports);
  }

  private static String qualifiedName(SourceTokenCursor cursor, String expectation) {
    StringBuilder name = new StringBuilder(
        cursor.expect(Type.IDENTIFIER, expectation).text());
    while (cursor.match(Type.DOT)) {
      name.append('.').append(cursor.expect(Type.IDENTIFIER, expectation).text());
    }
    return name.toString();
  }
}
