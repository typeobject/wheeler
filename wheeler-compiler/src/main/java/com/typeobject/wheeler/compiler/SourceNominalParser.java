package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.RecordDefinition;
import com.typeobject.wheeler.compiler.SourceModel.RecordField;
import com.typeobject.wheeler.compiler.SourceModel.VariantCase;
import com.typeobject.wheeler.compiler.SourceModel.VariantDefinition;
import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.function.Predicate;

/** Parses bounded nominal record and payload-variant declarations for the source parser. */
final class SourceNominalParser {
  private SourceNominalParser() {}

  static RecordDefinition parseRecord(
      SourceParser parser,
      SourceToken start,
      boolean exported,
      String moduleName,
      List<RecordDefinition> records,
      Predicate<String> valueType) {
    String name = parser.expect(Type.IDENTIFIER, "record name").text();
    if (!nominalName(name) || valueType.test(name)
        || records.stream().anyMatch(record -> record.name().equals(name))) {
      SourceParser.fail(start, "duplicate or reserved record type: " + name);
    }
    parser.expect(Type.LEFT_PAREN, "'(' after record name");
    List<RecordField> fields = new ArrayList<>();
    Set<String> fieldNames = new HashSet<>();
    if (!parser.check(Type.RIGHT_PAREN)) {
      do {
        SourceToken type = parser.expect(Type.IDENTIFIER, "record field type");
        if (moduleName == null
            && !type.text().equals("long") && !type.text().equals("boolean")
            && records.stream().noneMatch(record -> record.name().equals(type.text()))) {
          SourceParser.fail(
              type, "record field type must be scalar or previously declared record");
        }
        SourceToken field = parser.expect(Type.IDENTIFIER, "record field name");
        if (!fieldNames.add(field.text())) {
          SourceParser.fail(field, "duplicate record field: " + field.text());
        }
        fields.add(new RecordField(field.text(), type.text()));
      } while (parser.match(Type.COMMA));
    }
    if (fields.isEmpty()) {
      SourceParser.fail(start, "record must declare at least one field");
    }
    parser.expect(Type.RIGHT_PAREN, "')' after record fields");
    parser.expect(Type.LEFT_BRACE, "'{' in record declaration");
    parser.expect(Type.RIGHT_BRACE, "'}' in record declaration");
    return new RecordDefinition(name, exported, fields, start.line());
  }

  static VariantDefinition parseVariant(
      SourceParser parser,
      SourceToken start,
      boolean exported,
      String moduleName,
      Predicate<String> valueType) {
    String name = parser.expect(Type.IDENTIFIER, "variant name").text();
    if (valueType.test(name)) {
      SourceParser.fail(start, "duplicate or reserved variant type: " + name);
    }
    parser.expect(Type.LEFT_BRACE, "'{' in variant declaration");
    List<VariantCase> cases = new ArrayList<>();
    Set<String> caseNames = new HashSet<>();
    while (!parser.check(Type.RIGHT_BRACE) && !parser.check(Type.END)) {
      parser.expectText("case");
      SourceToken variantCase = parser.expect(Type.IDENTIFIER, "variant case name");
      if (!caseNames.add(variantCase.text())) {
        SourceParser.fail(variantCase, "duplicate variant case: " + variantCase.text());
      }
      parser.expect(Type.LEFT_PAREN, "'(' after variant case");
      List<RecordField> fields = new ArrayList<>();
      Set<String> fieldNames = new HashSet<>();
      if (!parser.check(Type.RIGHT_PAREN)) {
        do {
          SourceToken type = parser.expect(Type.IDENTIFIER, "variant payload type");
          if (!valueType.test(type.text())
              && (moduleName == null || !nominalName(type.text()))) {
            SourceParser.fail(type, "variant payload type must be previously declared");
          }
          SourceToken field = parser.expect(Type.IDENTIFIER, "variant payload name");
          if (!fieldNames.add(field.text())) {
            SourceParser.fail(field, "duplicate variant payload field: " + field.text());
          }
          fields.add(new RecordField(field.text(), type.text()));
        } while (parser.match(Type.COMMA));
      }
      parser.expect(Type.RIGHT_PAREN, "')' after variant payload");
      parser.expect(Type.SEMICOLON, "';' after variant case");
      cases.add(new VariantCase(variantCase.text(), fields));
    }
    if (cases.isEmpty()) {
      SourceParser.fail(start, "variant must declare at least one case");
    }
    parser.expect(Type.RIGHT_BRACE, "'}' after variant declaration");
    return new VariantDefinition(name, exported, cases, start.line());
  }

  private static boolean nominalName(String name) {
    return !name.isEmpty() && name.charAt(0) >= 'A' && name.charAt(0) <= 'Z';
  }
}
