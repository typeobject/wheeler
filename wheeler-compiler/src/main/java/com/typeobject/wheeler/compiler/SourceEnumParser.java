package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.RecordDefinition;
import com.typeobject.wheeler.compiler.SourceModel.VariantCase;
import com.typeobject.wheeler.compiler.SourceModel.VariantDefinition;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Elaborates finite enum declarations to payload-free variant definitions. */
final class SourceEnumParser {
  private static final int MAX_ENUM_CASES = 65_535;

  private SourceEnumParser() {}

  static VariantDefinition parse(
      SourceParser parser,
      SourceToken start,
      boolean exported,
      List<RecordDefinition> records,
      List<VariantDefinition> variants) {
    SourceToken name = parser.expect(Type.IDENTIFIER, "enum name");
    boolean duplicateRecord = records.stream()
        .anyMatch(record -> record.name().equals(name.text()));
    boolean duplicateVariant = variants.stream()
        .anyMatch(variant -> variant.name().equals(name.text()));
    if (duplicateRecord || duplicateVariant) {
      SourceTokenCursor.fail(name, "duplicate enum type: " + name.text());
    }
    parser.expect(Type.LEFT_BRACE, "'{' in enum declaration");
    List<VariantCase> cases = new ArrayList<>();
    Set<String> names = new HashSet<>();
    while (!parser.check(Type.RIGHT_BRACE) && !parser.check(Type.END)) {
      if (cases.size() >= MAX_ENUM_CASES) {
        SourceTokenCursor.fail(start, "enum exceeds the 65,535-case limit");
      }
      parser.expectText("case");
      SourceToken enumCase = parser.expect(Type.IDENTIFIER, "enum case name");
      if (!names.add(enumCase.text())) {
        SourceTokenCursor.fail(enumCase, "duplicate enum case: " + enumCase.text());
      }
      parser.expect(Type.SEMICOLON, "';' after enum case");
      cases.add(new VariantCase(enumCase.text(), List.of()));
    }
    if (cases.isEmpty()) {
      SourceTokenCursor.fail(start, "enum must declare at least one case");
    }
    parser.expect(Type.RIGHT_BRACE, "'}' after enum declaration");
    cases.sort(Comparator.comparing(VariantCase::name));
    return new VariantDefinition(name.text(), exported, cases, start.line());
  }
}
