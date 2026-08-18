package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.examples.NativeCompilerArchiveClosureProgram.PhysicalModule;
import java.util.List;

/** Resolves the selected physical compiler products and their manifest owners. */
final class NativeCompilerPhysicalSelection {
  private static final List<String> MODULE_NAMES = CompilerSources.sortedModuleNames();

  private NativeCompilerPhysicalSelection() {}

  static PhysicalModule comparable(String name) {
    return NativeCompilerArchiveClosureProgram.PHYSICAL_MODULES.stream()
        .filter(module -> module.name().equals(name))
        .findFirst()
        .orElseThrow();
  }

  static PhysicalModule callable(String name) {
    return NativeCompilerArchiveClosureProgram.PHYSICAL_CALLABLE_MODULES.stream()
        .filter(module -> module.name().equals(name))
        .findFirst()
        .orElseThrow();
  }

  static PhysicalModule selected(String name) {
    return NativeCompilerArchiveClosureProgram.PHYSICAL_MODULES.stream()
        .filter(module -> module.name().equals(name))
        .findFirst()
        .orElseGet(() -> callable(name));
  }

  static int owner(PhysicalModule module) {
    int owner = MODULE_NAMES.indexOf(module.name());
    if (owner < 0) {
      throw new IllegalStateException(
          "Physical module is outside compiler target: " + module.name());
    }
    return owner;
  }

  static String ownerRows(
      List<PhysicalModule> comparableModules,
      List<PhysicalModule> callableModules) {
    StringBuilder rows = new StringBuilder();
    for (int index = 0; index < comparableModules.size(); index++) {
      rows.append("set(physicalOwners, ").append(index).append(", ")
          .append(owner(comparableModules.get(index))).append(");\n");
    }
    for (int index = 0; index < callableModules.size(); index++) {
      rows.append("set(physicalOwners, ").append(comparableModules.size() + index)
          .append(", ").append(owner(callableModules.get(index)))
          .append(");\n");
    }
    return rows.toString();
  }
}
