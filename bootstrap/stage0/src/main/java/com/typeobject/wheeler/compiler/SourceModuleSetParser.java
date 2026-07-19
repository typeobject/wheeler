package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.ConstantDefinition;
import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.compiler.SourceModel.VariantDefinition;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/** Parses a closed module set dependency-first so imported variant schemas are available. */
final class SourceModuleSetParser {
  private SourceModuleSetParser() {}

  static Map<String, SourceProgram> parse(Map<String, String> sources) {
    Map<String, SourceModuleHeaderParser.Header> headers = new TreeMap<>();
    for (Map.Entry<String, String> entry : sources.entrySet()) {
      var header = SourceModuleHeaderParser.parseSource(entry.getValue());
      if (!entry.getKey().equals(header.moduleName())) {
        throw new CompilerException(
            1, "module key/declaration mismatch for " + entry.getKey());
      }
      headers.put(entry.getKey(), header);
    }

    Map<String, SourceProgram> parsed = new TreeMap<>();
    Set<String> active = new HashSet<>();
    for (String name : sources.keySet().stream().sorted().toList()) {
      parseOne(name, sources, headers, parsed, active);
    }
    return parsed;
  }

  private static void parseOne(
      String name,
      Map<String, String> sources,
      Map<String, SourceModuleHeaderParser.Header> headers,
      Map<String, SourceProgram> parsed,
      Set<String> active) {
    if (parsed.containsKey(name)) {
      return;
    }
    if (!active.add(name)) {
      throw new CompilerException(1, "module import cycle includes " + name);
    }
    var header = headers.get(name);
    if (header == null) {
      throw new CompilerException(1, "imported module is missing: " + name);
    }
    for (String dependency : header.imports()) {
      parseOne(dependency, sources, headers, parsed, active);
    }

    List<VariantDefinition> importedVariants = new ArrayList<>();
    List<ConstantDefinition> importedConstants = new ArrayList<>();
    for (String dependency : header.imports()) {
      parsed.get(dependency).variants().stream()
          .filter(VariantDefinition::exported)
          .forEach(variant -> {
            importedVariants.add(variant);
            importedVariants.add(new VariantDefinition(
                dependency + "::" + variant.name(),
                true,
                variant.cases(),
                variant.line()));
          });
      parsed.get(dependency).constants().stream()
          .filter(ConstantDefinition::exported)
          .forEach(constant -> {
            importedConstants.add(constant);
            importedConstants.add(new ConstantDefinition(
                dependency + "::" + constant.name(),
                constant.type(),
                constant.value(),
                true,
                constant.line()));
          });
    }
    SourceProgram module = new SourceParser(importedVariants, importedConstants)
        .parse(sources.get(name), false);
    parsed.put(name, module);
    active.remove(name);
  }
}
