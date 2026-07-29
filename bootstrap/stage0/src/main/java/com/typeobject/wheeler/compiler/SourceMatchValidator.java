package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Parameter;
import com.typeobject.wheeler.compiler.SourceModel.Statement;
import com.typeobject.wheeler.compiler.SourceModel.VariantCase;
import com.typeobject.wheeler.compiler.SourceModel.VariantDefinition;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Validates one exhaustive variant match after its case bodies parse. */
final class SourceMatchValidator {
  private SourceMatchValidator() {}

  static VariantDefinition validate(
      List<MatchCase> cases,
      SourceToken start,
      List<VariantDefinition> variants,
      List<VariantDefinition> importedVariants) {
    if (cases.isEmpty()) {
      SourceTokenCursor.fail(start, "match must contain every variant case");
    }
    VariantDefinition variant = variants.stream()
        .filter(candidate -> candidate.name().equals(cases.getFirst().type()))
        .findFirst()
        .orElseGet(() -> importedVariants.stream()
            .filter(candidate -> candidate.name().equals(cases.getFirst().type()))
            .findFirst()
            .orElse(null));
    if (variant == null) {
      SourceTokenCursor.fail(start, "match case names an unknown variant type");
    }
    Set<String> seen = new HashSet<>();
    for (MatchCase parsed : cases) {
      VariantCase descriptor = variant.cases().stream()
          .filter(candidate -> candidate.name().equals(parsed.caseName()))
          .findFirst()
          .orElse(null);
      if (!parsed.type().equals(variant.name()) || descriptor == null
          || !seen.add(parsed.caseName())
          || descriptor.fields().size() != parsed.bindings().size()) {
        SourceTokenCursor.fail(start, "match cases do not exhaust " + variant.name());
      }
      for (int field = 0; field < descriptor.fields().size(); field++) {
        if (!descriptor.fields().get(field).type().equals(parsed.bindings().get(field).type())) {
          SourceTokenCursor.fail(
              start, "variant payload binding type mismatch in " + parsed.caseName());
        }
      }
    }
    if (seen.size() != variant.cases().size()) {
      SourceTokenCursor.fail(start, "match cases do not exhaust " + variant.name());
    }
    return variant;
  }

  record MatchCase(
      String type, String caseName, List<Parameter> bindings, List<Statement> body, int line) {
    MatchCase {
      bindings = List.copyOf(bindings);
      body = List.copyOf(body);
    }
  }
}
