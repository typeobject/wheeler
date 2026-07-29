package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.ArrayDefinition;
import com.typeobject.wheeler.compiler.SourceModel.RecordDefinition;
import com.typeobject.wheeler.compiler.SourceModel.RecordField;
import com.typeobject.wheeler.compiler.SourceModel.SliceDefinition;
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
      Predicate<String> valueType,
      List<ArrayDefinition> arrays,
      List<SliceDefinition> slices) {
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
        SourceToken typeStart = parser.peek();
        String type = SourceValueTypeParser.parse(
            parser,
            "record field type",
            moduleName != null,
            valueType,
            arrays,
            slices);
        requireBoundedAggregateElement(typeStart, type, "record field");
        SourceToken field = parser.expect(Type.IDENTIFIER, "record field name");
        if (!fieldNames.add(field.text())) {
          SourceParser.fail(field, "duplicate record field: " + field.text());
        }
        fields.add(new RecordField(field.text(), type));
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
      Predicate<String> valueType,
      List<ArrayDefinition> arrays,
      List<SliceDefinition> slices) {
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
          SourceToken typeStart = parser.peek();
          String type = SourceValueTypeParser.parse(
              parser,
              "variant payload type",
              moduleName != null,
              valueType,
              arrays,
              slices);
          requireBoundedAggregateElement(typeStart, type, "variant payload");
          SourceToken field = parser.expect(Type.IDENTIFIER, "variant payload name");
          if (!fieldNames.add(field.text())) {
            SourceParser.fail(field, "duplicate variant payload field: " + field.text());
          }
          fields.add(new RecordField(field.text(), type));
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

  private static void requireBoundedAggregateElement(
      SourceToken token, String type, String description) {
    int bracket = type.indexOf('[');
    if (bracket >= 0) {
      if (type.endsWith("[]")) {
        SourceParser.fail(token, description + " cannot contain a nonescaping slice");
      }
      String element = type.substring(0, bracket);
      if (!element.equals("long") && !element.equals("boolean")
          && !element.equals("Done")) {
        SourceParser.fail(token, description + " arrays currently require scalar elements");
      }
    }
  }

  private static boolean nominalName(String name) {
    return !name.isEmpty() && name.charAt(0) >= 'A' && name.charAt(0) <= 'Z';
  }
}
