package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.ConstantDefinition;
import java.util.List;

/** Owns resolved local and directly imported compile-time constant bindings. */
final class SourceConstantEnvironment {
  private final List<ConstantDefinition> imported;
  private List<ConstantDefinition> local = List.of();

  SourceConstantEnvironment(List<ConstantDefinition> imported) {
    this.imported = List.copyOf(imported);
  }

  void prepare(String source) {
    local = SourceConstantCollector.collect(source, imported);
  }

  ConstantDefinition resolve(
      String name, SourceToken source, boolean required) {
    ConstantDefinition localMatch = local.stream()
        .filter(constant -> constant.name().equals(name))
        .findFirst()
        .orElse(null);
    if (localMatch != null) {
      return localMatch;
    }
    List<ConstantDefinition> matches = imported.stream()
        .filter(constant -> constant.name().equals(name))
        .toList();
    if (1 < matches.size()) {
      SourceTokenCursor.fail(source, "ambiguous constant: " + name);
    }
    if (matches.isEmpty()) {
      if (required) {
        SourceTokenCursor.fail(source, "unknown constant: " + name);
      }
      return null;
    }
    return matches.getFirst();
  }
}
