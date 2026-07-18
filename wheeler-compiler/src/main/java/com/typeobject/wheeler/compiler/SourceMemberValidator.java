package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.ConstantDefinition;
import com.typeobject.wheeler.compiler.SourceModel.Function;
import com.typeobject.wheeler.compiler.SourceModel.RecordDefinition;
import com.typeobject.wheeler.compiler.SourceModel.State;
import com.typeobject.wheeler.compiler.SourceModel.VariantDefinition;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Checks class-member namespaces after declarations have been parsed. */
final class SourceMemberValidator {
  private SourceMemberValidator() {}

  static void validate(
      List<ConstantDefinition> constants,
      List<State> states,
      List<Function> functions,
      List<RecordDefinition> records,
      List<VariantDefinition> variants) {
    Set<String> occupied = new HashSet<>();
    for (ConstantDefinition constant : constants) {
      if (!occupied.add(constant.name())) {
        fail(constant.line(), "duplicate constant: " + constant.name());
      }
    }
    for (State state : states) {
      requireFree(occupied, state.name(), state.line());
    }
    for (RecordDefinition record : records) {
      requireFree(occupied, record.name(), record.line());
    }
    for (VariantDefinition variant : variants) {
      requireFree(occupied, variant.name(), variant.line());
    }
    for (Function function : functions) {
      if (constants.stream().anyMatch(
          constant -> constant.name().equals(function.name()))) {
        fail(function.line(), "constant and function share a name: " + function.name());
      }
    }
  }

  private static void requireFree(
      Set<String> occupied, String name, int line) {
    if (!occupied.add(name)) {
      fail(line, "duplicate class member: " + name);
    }
  }

  private static void fail(int line, String message) {
    throw new CompilerException(line, message);
  }
}
